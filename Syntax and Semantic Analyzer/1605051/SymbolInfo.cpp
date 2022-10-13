#include<iostream>
#include<string>
#include<vector>

using namespace std;

class FunctionSpecs {
    string returnType;
    vector<pair<string, string> > paramList;
    int numOfParam;
    public:
    FunctionSpecs(){}
    FunctionSpecs(string returnType, int numOfParam, vector<pair<string, string> > paramList) {
        this->returnType = returnType;
        this->numOfParam = numOfParam;
        this->paramList = paramList;
    }
    string getReturnType() {return returnType;}
    void setReturnType(const string &retType)
    {
        this->returnType = retType;
    }
    vector<pair<string, string> > getParamList() {return paramList;}

    void setParamList(vector<pair<string, string> > paramList)
    {
        this->paramList = paramList;
    }

    int getNumOfParam() {return numOfParam;}
    void setNumOfParam(int numOfParam)
    {
        this->numOfParam = numOfParam;
    }

};

class SymbolInfo {
    string symbolName;
    string symbolType;
    string dataType;
    bool isArray;
    SymbolInfo *next;
    FunctionSpecs *functionSpecs;

public:
    SymbolInfo(){
        symbolName = "";
        symbolType = "";
        next = nullptr;
        functionSpecs = nullptr;
        dataType = "";
        isArray = false;
    }
    SymbolInfo(const string &name, const string &type = "default", string dataType = "default", bool isArray = false) {
        symbolName = name;
        symbolType = type;
        this->dataType = dataType;
        next = nullptr;
        functionSpecs = nullptr;
        this->isArray = isArray;
    }

    SymbolInfo(const string &name, const string &type, FunctionSpecs *functionSpecs, string dataType = "default", bool isArray = false) {
        symbolName = name;
        symbolType = type;
        this->functionSpecs = functionSpecs;
        this->dataType = dataType;
        next = nullptr;
        this->isArray = isArray;
    }

    bool getIsArray() {return isArray;}
    bool setIsArray(bool isArray)
    {
        this->isArray = isArray;
    }

    FunctionSpecs * getFunctionSpecs() { return functionSpecs;}

    string getSymbolName() {return symbolName;}

    string getDataType() {return dataType; }
    void setDataType(const string &dataType) {
        this->dataType = dataType;
        //cout << symbolName << " dataTYpe -> " << dataType << endl;
    }

    void setSymbolName(const string &symbolName) {
        this->symbolName = symbolName;
    }

    string getSymbolType() {return symbolType;}

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