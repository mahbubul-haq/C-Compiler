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
    void ChangeDataType(const string &name, const string &dataType, bool isArray = false);
    bool Insert(SymbolInfo * newSymbol);
    SymbolInfo * lookUp(SymbolInfo * symbol);
    int hashValue(const string &symbolName);
    bool Delete(SymbolInfo * symbol);
    void Print(FILE *fp);
    void setTableId(ScopeTable * parent)
    {
        if (parent)
        {
            if (parent->getTableId() == "")
            {
                tableId = to_string(parent->getNumOfInnerScopes() + 1);
                parent->IncInnerScope();
            }
            else
            {
                tableId = to_string(parent->getNumOfInnerScopes() + 1);
                parent->IncInnerScope();
            }
        }
        else
        {
            tableId = "1";
            IncInnerScope();
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

void ScopeTable:: ChangeDataType(const string &name, const string &dataType, bool isArray) {
    int hashVal = hashValue(name);
    SymbolInfo * current = scopeTable[hashVal];
    SymbolInfo * previous = nullptr;

    if (scopeTable[hashVal]->getSymbolName() == name)
    {
        scopeTable[hashVal]->setDataType(dataType);
        scopeTable[hashVal]->setIsArray(isArray);
    }
    else
    {
        while (current->getSymbolName() != name) {
            previous = current;
            current = current->getSymbolInfoNext();
        }
        current->setDataType(dataType);
        current->setIsArray(isArray);
        previous->setSymbolInfoNext(current);
    }
}

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
        return true;
    }
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

        if (previous == nullptr) {
            scopeTable[hashVal] = current->getSymbolInfoNext();
        }
        else previous->setSymbolInfoNext(current->getSymbolInfoNext());

        delete current;

        return true;
    }
    return false;
}

void ScopeTable :: Print(FILE *fp) {

    fprintf(fp, " ScopeTable # %s\n", tableId.c_str());
    for (int i = 0; i < bucketSize; i++) {

        if (scopeTable[i] == nullptr) continue;

        fprintf(fp, " %d --> ", i);

        SymbolInfo *current = scopeTable[i];
        while (current != nullptr) {

            fprintf(fp, "< %s : %s >%s", current->getSymbolName().c_str(), current->getSymbolType().c_str(),
            (current->getSymbolInfoNext() != nullptr ? " " : ""));

            current = current->getSymbolInfoNext();
        }
        fprintf(fp, "\n");
    }

}

