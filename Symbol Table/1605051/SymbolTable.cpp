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
    bool Insert(const string &name, string type = "default");
    bool Delete(const string &name, string type = "default");
    SymbolInfo * lookUp(const string &name, string type = "default");
    void printCurrentScope();
    void printAllScope();
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
    cout << "New ScopeTable with id " << curScopeTable->getTableId() << " created"<< endl << endl;
}

void SymbolTable::exitScope() {
    if (curScopeTable != nullptr) {
        ScopeTable *temp = curScopeTable;
        curScopeTable = curScopeTable->getParentScope();
        cout << "ScopeTable with id " << temp->getTableId() << " removed" << endl << endl;
        delete temp;
    }
}

bool SymbolTable::Insert(const string &name, string type) {
    return curScopeTable->Insert(new SymbolInfo(name, type));
}

bool SymbolTable::Delete(const string &name, string type) {
    return curScopeTable->Delete(new SymbolInfo(name, type));
}

void SymbolTable::lookUpPosition(SymbolInfo *symbol, ScopeTable * curScope) {
    int hashVal = curScope->hashValue(symbol->getSymbolName()), pos = 0;

    SymbolInfo *cur = curScope->getScopeTable()[hashVal];

    while (cur != nullptr) {
        if (cur->getSymbolName() == symbol->getSymbolName()) {
            cout << "Found in ScopeTable# " << curScope->getTableId() << " at position " << hashVal << ", " << pos << endl << endl;
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
    cout << "Not found" << endl << endl;
    return nullptr;
}

void SymbolTable::printCurrentScope() {
    curScopeTable->Print();
    cout << endl;
}

void SymbolTable::printAllScope() {
    ScopeTable * current = curScopeTable;

    while (current != nullptr) {
        current->Print();
        cout << endl;
        current = current->getParentScope();
    }
}

int main() {

    char fout;
    cout << "Do you want to have the output in file? Y/N ";
    cin >> fout;

    if (fout == 'Y'|| fout == 'y' ) freopen("output.txt", "w", stdout);
    freopen("input.txt", "r", stdin);

    int bucketNumber;
    cin >> bucketNumber;

    SymbolTable symbolTable(bucketNumber);
    char operationType;
    string name, type;

    while (cin >> operationType) {
        if (operationType == 'q') break;

        switch (operationType) {
            case 'I':
                cin >> name >> type;

                cout << operationType << " " << name << " " << type << endl << endl;

                symbolTable.Insert(name, type);
                break;
            case 'L':
                cin >> name;
                cout << operationType << " " << name << endl << endl;

                symbolTable.lookUp(name);
                break;
            case 'S':
                cout << operationType << endl << endl;

                symbolTable.enterScope();
                break;
            case 'E':
                cout << operationType << endl << endl;

                symbolTable.exitScope();
                break;
            case 'P':
                cout << operationType << " ";
                cin >> operationType;
                cout << operationType << endl << endl;

                if (operationType == 'A') symbolTable.printAllScope();
                else if (operationType == 'C') symbolTable.printCurrentScope();
                else cout << "Line " << __LINE__ << ": Invalid command!" << endl << endl;
                break;
            case 'D':
                cin >> name;
                cout << operationType << " " << name << endl << endl;
                if (!symbolTable.Delete(name))
                    cout << name << " not found" << endl << endl;
                break;
            default:
                cout << operationType << endl << endl;
                cout << "Line " << __LINE__ << ": Invalid command!" << endl << endl;
                break;
        }
    }



    return 0;
}