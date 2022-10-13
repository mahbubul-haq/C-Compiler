#include<iostream>
#include<string>

#include "SymbolInfo.cpp"

using namespace std;

class ScopeTable {
    SymbolInfo ** scopeTable;
    ScopeTable *parentScope;
    int bucketSize;
    string tableId;
    int numOfInnerScopes;

public:
    ScopeTable() {
        scopeTable = nullptr;
        parentScope = nullptr;
        bucketSize = 0;
        tableId = "";
        numOfInnerScopes = 0;
    }
    ScopeTable(int n) {
        parentScope = nullptr;
        bucketSize = n;
        tableId = "";
        numOfInnerScopes = 0;
        scopeTable = new SymbolInfo*[n];
        for (int i = 0; i < n; i++) {
            scopeTable[i] = nullptr;
        }

    }

    bool Insert(SymbolInfo * newSymbol);
    SymbolInfo * lookUp(SymbolInfo * symbol);
    int hashValue(const string &symbolName);
    bool Delete(SymbolInfo * symbol);
    void Print();
    void setTableId(ScopeTable * parent) {
        if (parent) {
            tableId = parent->getTableId()+ "." + to_string(parent->getNumOfInnerScopes() + 1);
            parent->IncInnerScope();
        }
        else {
            tableId = "1";
        }
    }
    string getTableId(){return tableId;}

    SymbolInfo ** getScopeTable () {
        return scopeTable;
    }

    int getNumOfInnerScopes(){
        return numOfInnerScopes;
    }
    void IncInnerScope() {
        numOfInnerScopes++;
    }
    void setParentScope(ScopeTable * parent) {
        parentScope = parent;
        setTableId(parent);
    }
    ScopeTable * getParentScope() {
        return parentScope;
    }

    ~ScopeTable() {
        for (int i = 0; i < bucketSize; i++) {
            SymbolInfo * current = scopeTable[i];
            while (current != nullptr) {
                SymbolInfo * temp = current;
                current = current->getSymbolInfoNext();
                delete temp;
            }
        }
        if (scopeTable) delete [] scopeTable;
    }
};

bool ScopeTable :: Insert(SymbolInfo * newSymbol) {
    if (lookUp(newSymbol) == nullptr) {
        int hashVal = hashValue(newSymbol->getSymbolName()), pos = -1;

        SymbolInfo * current = scopeTable[hashVal];


        if (current == nullptr) {
            scopeTable[hashVal] = newSymbol;
            pos = 0;
        }
        else {
            SymbolInfo * previous = current;
            while (current != nullptr) {
                pos++;
                previous = current;
                current = current->getSymbolInfoNext();
            }
            pos++;
            current = newSymbol;
            previous->setSymbolInfoNext(current);
        }
        cout << "Inserted in ScopeTable# " << tableId << " at position " << hashVal << ", " << pos << endl << endl;
        return true;
    }
    cout << "<" << newSymbol->getSymbolName() << "," << newSymbol->getSymbolType() << "> already exists in current ScopeTable" << endl << endl;
    return false;
}

SymbolInfo * ScopeTable :: lookUp(SymbolInfo * symbol) {
    int hashVal = hashValue(symbol->getSymbolName()), pos=0;

    SymbolInfo * current = scopeTable[hashVal];

    while (current != nullptr) {
        if (current->getSymbolName() == symbol->getSymbolName()) {
            return current;
        }
        current = current->getSymbolInfoNext();
        pos++;
    }
    return nullptr;
}

int ScopeTable :: hashValue(const string &symbolName)  {
    int asciiSum = 0;
    for (int i = 0; i < symbolName.size(); i++) {
        asciiSum += (int) symbolName[i];
    }
    return asciiSum % bucketSize;
}

bool ScopeTable :: Delete(SymbolInfo * symbol) {
    if (lookUp(symbol)) {

        int hashVal = hashValue(symbol->getSymbolName()), pos=0;
        SymbolInfo * current = scopeTable[hashVal];
        SymbolInfo * previous = nullptr;

        while (current->getSymbolName() != symbol->getSymbolName()) {
            previous = current;
            current = current->getSymbolInfoNext();
            pos++;
        }

        cout << "Found in ScopeTable# " << tableId << " at position " << hashVal << ", " << pos << endl << endl;


        if (previous == nullptr) {
            scopeTable[hashVal] = current->getSymbolInfoNext();
        }
        else previous->setSymbolInfoNext(current->getSymbolInfoNext());

        delete current;

        cout << "Deleted Entry " << hashVal << ", " << pos << " from current ScopeTable" << endl << endl;

        return true;
    }
    cout << "Not found" << endl << endl;
    return false;
}

void ScopeTable :: Print() {
    cout << endl;
    cout << "ScopeTable # " << tableId << endl;
    for (int i = 0; i < bucketSize; i++) {
        cout << i << " -->  ";
        SymbolInfo *current = scopeTable[i];
        while (current != nullptr) {
            cout << "< " << current->getSymbolName() << " : " << current->getSymbolType() << "> ";
            current = current->getSymbolInfoNext();
        }
        cout << endl;
    }

}

