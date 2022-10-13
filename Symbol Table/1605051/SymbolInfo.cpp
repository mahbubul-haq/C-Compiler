#include<iostream>
#include<string>
using namespace std;


class SymbolInfo {
    string symbolName;
    string symbolType;
    SymbolInfo *next;

public:
    SymbolInfo(){
        symbolName = "";
        symbolType = "";
        next = nullptr;
    }
    SymbolInfo(const string &name, const string &type) {
        symbolName = name;
        symbolType = type;
        next = nullptr;
    }

    string getSymbolName() {
        return symbolName;
    }
    void setSymbolName(const string &symbolName) {
        this->symbolName = symbolName;
    }
    string getSymbolType() {
        return symbolType;
    }

    void setSymbolType(const string &symbolType) {
        this->symbolType = symbolType;
    }

    SymbolInfo * getSymbolInfoNext() {
        return this->next;
    }
    void setSymbolInfoNext(SymbolInfo * next) {
        this->next = next;
    }
};