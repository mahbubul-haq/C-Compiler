#include<iostream>
#include<string>

#include "ScopeTable.cpp"

using namespace std;


class SymbolTable {
    ScopeTable * curScopeTable;
    int bucketSize;

public:
    SymbolTable(){
        bucketSize = 0;
        curScopeTable = nullptr;
    }

    SymbolTable(int n){
        if (n <= 0) {
            cout << "Bucket size must be positive." << endl;
            cout << "SymbolTable creation failed!" << endl << endl;
            exit(0);

        }
        else if (n >= 10000000) {
            cout << "Bucket Size too big." << endl;
            cout << "SymbolTable creation failed!" << endl << endl;
            exit(0);
        }
        else {
                bucketSize = n;
                curScopeTable = new ScopeTable(bucketSize);
                curScopeTable->setParentScope(nullptr);
        }

    }

    void enterScope();
    void exitScope();
    bool Insert(FILE *fp, const string &name, string type = "default");
    bool Delete(const string &name, string type = "default");
    SymbolInfo * lookUp(const string &name, string type = "default");
    void printCurrentScope(FILE *fp);
    void printAllScope(FILE *fp);
    void lookUpPosition(SymbolInfo * symbol, ScopeTable * curScope);

    ~SymbolTable() {
        while (curScopeTable != nullptr) {
            ScopeTable * temp = curScopeTable;
            curScopeTable = curScopeTable->getParentScope();
            delete temp;
        }
    }

};

void SymbolTable::enterScope() {
    ScopeTable * temp = curScopeTable;
    curScopeTable = new ScopeTable(bucketSize);
    curScopeTable->setParentScope(temp);
}

void SymbolTable::exitScope() {
    if (curScopeTable != nullptr) {
        ScopeTable *temp = curScopeTable;
        curScopeTable = curScopeTable->getParentScope();
        delete temp;
    }
}

bool SymbolTable::Insert(FILE *fp, const string &name, string type) {
    if (curScopeTable->Insert(new SymbolInfo(name, type))) {
        return true;
    };
    //fprintf(fp, "\n%s already exists in current ScopeTable\n", name.c_str());

    return false;
}

bool SymbolTable::Delete(const string &name, string type) {
    return curScopeTable->Delete(new SymbolInfo(name, type));
}

void SymbolTable::lookUpPosition(SymbolInfo *symbol, ScopeTable * curScope) {
    int hashVal = curScope->hashValue(symbol->getSymbolName()), pos = 0;

    SymbolInfo *cur = curScope->getScopeTable()[hashVal];

    while (cur != nullptr) {
        if (cur->getSymbolName() == symbol->getSymbolName()) {
            return;
        }
        cur = cur->getSymbolInfoNext();
        pos++;
    }
}


SymbolInfo* SymbolTable::lookUp(const string &name, string type) {
    ScopeTable * current = curScopeTable;
    SymbolInfo * searchSymbol = new SymbolInfo(name, type);

    while (current != nullptr) {
        SymbolInfo * curSymbol = current->lookUp(searchSymbol);
        if (curSymbol != nullptr) {
            lookUpPosition(curSymbol, current);
            return curSymbol;
        }
        current = current->getParentScope();
    }
    return nullptr;
}

void SymbolTable::printCurrentScope(FILE *fp) {
    curScopeTable->Print(fp);
    cout << endl;
}

void SymbolTable::printAllScope(FILE *fp) {
    ScopeTable * current = curScopeTable;

    while (current != nullptr) {
        current->Print(fp);
        current = current->getParentScope();
    }
}