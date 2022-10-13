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

    void enterScope(FILE *fp);
    void exitScope(FILE *fp);
    bool Insert(const string &name, string type = "default", string dataType = "default");
    bool Insert(SymbolInfo * symbolInfo);
    void ChangeDataType(const string &name, const string &dataType, bool isArray = false);
    bool Delete(const string &name, string type = "default");
    SymbolInfo * lookUp(const string &name, string type = "default");
    SymbolInfo * lookUpAllScope(const string &name, string type = "default");
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

void SymbolTable::ChangeDataType(const string &name, const string &dataType, bool isArray) {
    ScopeTable *currentScope = curScopeTable;
    SymbolInfo *temp = new SymbolInfo(name);
    while (currentScope != nullptr) {
        if (currentScope->lookUp(temp) != nullptr) {
            currentScope->ChangeDataType(name, dataType, isArray);
            return;
        }
        return;
        currentScope = currentScope->getParentScope();
    }
}

void SymbolTable::enterScope(FILE *fp) {
    ScopeTable * temp = curScopeTable;
    curScopeTable = new ScopeTable(bucketSize);
    curScopeTable->setParentScope(temp);
    //fprintf(fp, " New ScopeTable with id %s created\n", curScopeTable->getTableId().c_str());
}

void SymbolTable::exitScope(FILE *fp) {
    if (curScopeTable != nullptr) {

        printAllScope(fp);
        //fprintf(fp, " ScopeTable with id %s removed\n", curScopeTable->getTableId().c_str());

        ScopeTable *temp = curScopeTable;
        curScopeTable = curScopeTable->getParentScope();

        delete temp;
    }
}

bool SymbolTable::Insert(SymbolInfo * symbolInfo) {
    return curScopeTable->Insert(symbolInfo);
}

bool SymbolTable::Insert(const string &name, string type, string dataType) {
    if (curScopeTable->Insert(new SymbolInfo(name, type, dataType))) {
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
            //lookUpPosition(curSymbol, current);
            return curSymbol;
        }
        //current = current->getParentScope();
        break;
    }
    return nullptr;
}

SymbolInfo* SymbolTable::lookUpAllScope(const string &name, string type) {
    ScopeTable * current = curScopeTable;
    SymbolInfo * searchSymbol = new SymbolInfo(name, type);

    while (current != nullptr) {
        SymbolInfo * curSymbol = current->lookUp(searchSymbol);
        if (curSymbol != nullptr) {
            //lookUpPosition(curSymbol, current);
            return curSymbol;
        }
        current = current->getParentScope();
    }
    return nullptr;
}

void SymbolTable::printCurrentScope(FILE *fp) {
    curScopeTable->Print(fp);
    fprintf(fp, "\n");
}

void SymbolTable::printAllScope(FILE *fp) {
    ScopeTable * current = curScopeTable;

    while (current != nullptr) {
        current->Print(fp);
        fprintf(fp, "\n");
        current = current->getParentScope();
    }
}