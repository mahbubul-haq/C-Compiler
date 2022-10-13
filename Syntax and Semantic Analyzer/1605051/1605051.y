%{
#include <stdlib.h>
#include <stdio.h>
#include<iostream>
#include<string>
#include<cstring>
#include<vector>

#include "SymbolTable.cpp"

using namespace std;

int yyparse(void);
int yylex(void);

extern int error_count;
extern int line_count;
extern FILE *logfile;
extern FILE *errorfile;
extern FILE *yyin;
extern char * yytext;

SymbolTable *symbolTable;

string temp, retType, stmts, stmt, compound_stmt, func_def;
vector<pair<string, string> > paramList, argList, declarationList;

void yyerror(char *s)
{
    temp = yytext;

    printf("%s\n", s);
}

%}

%union {SymbolInfo *symbolinfo;}

%token <symbolinfo> CONST_INT CONST_FLOAT IF ELSE FOR WHILE FLOAT ID COMMA SEMICOLON ADDOP MULOP RELOP ASSIGNOP LOGICOP DECOP INCOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD RETURN VOID PRINTLN INT

%type <symbolinfo> type_specifier variable declaration_list var_declaration unit program start func_declaration parameter_list expression_statement statement compound_statement unary_expression term factor simple_expression rel_expression logic_expression statements expression func_definition argument_list arguments

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%


start :
        program
        {

            fprintf(logfile, "Line %d: start : program\n\n\n", line_count);
            symbolTable->printAllScope(logfile);
            fprintf(logfile, "Total Lines: %d\n\nTotal Errors: %d\n", line_count, error_count);
        }
    ;

program :
        program unit
        {

            temp = $1->getSymbolName();
            temp += $2->getSymbolName();

            fprintf(logfile, "Line %d: program : program unit\n\n%s\n\n", line_count, temp.c_str());
            $$ = new SymbolInfo(temp, "program");
        }
    |   unit
        {

            fprintf(logfile, "Line %d: program : unit\n\n%s\n\n", line_count, $1->getSymbolName().c_str());
            $$ = new SymbolInfo($1->getSymbolName(), "program");
        }
    ;

unit :
        var_declaration
        {

            fprintf(logfile, "Line %d: unit : var_declaration\n\n%s\n\n", line_count, $1->getSymbolName().c_str());
            $$ = new SymbolInfo($1->getSymbolName(), "unit");
        }
    |   func_declaration
        {

            fprintf(logfile, "Line %d: unit : func_declaration\n\n%s\n\n", line_count, $1->getSymbolName().c_str());
            $$ = new SymbolInfo($1->getSymbolName(), "unit");
        }
    |   func_definition
        {

            fprintf(logfile, "Line %d: unit : func_definition\n\n%s\n\n", line_count, $1->getSymbolName().c_str());
            $$ = new SymbolInfo(func_def, "unit");
        }
    ;

func_declaration :
        type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
        {

            FunctionSpecs * funcSpecs = new FunctionSpecs($1->getSymbolName(), paramList.size(), paramList);

            temp = $1->getSymbolName();
            temp += " ";
            temp += $2->getSymbolName();
            temp += "(";
            for (int i = 0; i < paramList.size(); i++)
            {
                temp += paramList[i].second;
                if (paramList[i].first != "")
                {
                    temp += " ";
                    temp += paramList[i].first;
                }
                if (i != (int) paramList.size() - 1)
                {
                    temp += ",";
                }
            }
            temp += ");\n";

            fprintf(logfile, "Line %d: func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n\n%s\n\n", line_count, temp.c_str());

            SymbolInfo *newSymbol = symbolTable->lookUp($2->getSymbolName());

            if (newSymbol == nullptr)
            {
                symbolTable->Insert(new SymbolInfo($2->getSymbolName(), $2->getSymbolType(), funcSpecs, "function_dec"));
            }
            else
            {
                error_count++;
                fprintf(errorfile, "Error at line %d : Multiple Declaration of %s\n\n", line_count, $2->getSymbolName().c_str());
                fprintf(logfile, "Error at line %d : Multiple Declaration of %s\n\n", line_count, $2->getSymbolName().c_str());
            }

            paramList.clear();
            $$ = new SymbolInfo(temp, "func_declaration");

        }
    |   type_specifier ID LPAREN RPAREN SEMICOLON
        {

            paramList.clear();
            FunctionSpecs * funcSpecs = new FunctionSpecs($1->getSymbolName(), paramList.size(), paramList);

            temp = $1->getSymbolName();
            temp += " ";
            temp += $2->getSymbolName();
            temp += "();\n";

            fprintf(logfile, "Line %d: func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n\n%s\n\n", line_count, temp.c_str());

            SymbolInfo *newSymbol = symbolTable->lookUp($2->getSymbolName());

            if (newSymbol == nullptr)
            {
                symbolTable->Insert(new SymbolInfo($2->getSymbolName(), $2->getSymbolType(), funcSpecs, "function_dec"));
            }
            else
            {
                error_count++;
                fprintf(errorfile, "Error at line %d : Multiple Declaration of %s\n\n", line_count, $2->getSymbolName().c_str());
                fprintf(logfile, "Error at line %d : Multiple Declaration of %s\n\n", line_count, $2->getSymbolName().c_str());
            }

            $$ = new SymbolInfo(temp, "func_declaration");
        }
    ;

func_definition :
        type_specifier ID LPAREN parameter_list RPAREN
        {
            FunctionSpecs * funcSpecs = new FunctionSpecs($1->getSymbolName(), paramList.size(), paramList);
            SymbolInfo * newSymbol = symbolTable->lookUp($2->getSymbolName());
            bool flag = true, flag1 = true;

            for (int i = 0; i < paramList.size(); i++) {
                if (paramList[i].first == "") flag = false;
            }

            if (!flag)
            {
                error_count++;
                fprintf(errorfile, "Error at line %d : Invalid Definition of %s\n\n", line_count, $2->getSymbolName().c_str());
                fprintf(logfile, "Error at line %d : Invalid Definition of %s\n\n", line_count, $2->getSymbolName().c_str());
            }
            else if (newSymbol == nullptr)
            {
                symbolTable->Insert(new SymbolInfo($2->getSymbolName(), $2->getSymbolType(), funcSpecs, "function_def"));
            }
            else
            {
                if (newSymbol->getDataType() == "function_dec")
                {
                    if (newSymbol->getFunctionSpecs()->getParamList().size() != paramList.size()) flag1 = false;


                    for (int i = 0;flag1 && i < paramList.size(); i++)
                    {
                        if (paramList[i].second != newSymbol->getFunctionSpecs()->getParamList()[i].second) flag1 = false;
                    }
                    if (newSymbol->getFunctionSpecs()->getParamList().size() != paramList.size())
                    {
                        error_count++;
                        fprintf(errorfile, "Error at line %d: Total number of arguments mismatch with declaration in function %s\n\n", line_count, $2->getSymbolName().c_str());
                        fprintf(logfile, "Error at line %d: Total number of arguments mismatch with declaration in function %s\n\n", line_count, $2->getSymbolName().c_str());
                    }
                    else if (funcSpecs->getReturnType() != newSymbol->getFunctionSpecs()->getReturnType())
                    {
                        error_count++;
                        fprintf(errorfile, "Error at line %d: Return type mismatch with function declaration in function %s\n\n", line_count, $2->getSymbolName().c_str());
                        fprintf(logfile, "Error at line %d: Return type mismatch with function declaration in function %s\n\n", line_count, $2->getSymbolName().c_str());
                    }
                    else if (flag1)
                    {
                        symbolTable->ChangeDataType($2->getSymbolName(), "function_def");
                    }
                    else
                    {
                        error_count++;
                        fprintf(errorfile, "Error at line %d : Multiple Definition of %s\n\n", line_count, $2->getSymbolName().c_str());
                        fprintf(logfile, "Error at line %d : Multiple Definition of %s\n\n", line_count, $2->getSymbolName().c_str());
                    }
                }
                else if (newSymbol->getDataType() == "function_def")
                {
                    error_count++;
                    fprintf(errorfile, "Error at line %d : Multiple Definition of %s\n\n", line_count, $2->getSymbolName().c_str());
                    fprintf(logfile, "Error at line %d : Multiple Definition of %s\n\n", line_count, $2->getSymbolName().c_str());
                }
                else
                {
                    error_count++;
                    fprintf(errorfile, "Error at line %d : Multiple Declaration of %s\n\n", line_count, $2->getSymbolName().c_str());
                    fprintf(logfile, "Error at line %d : Multiple Declaration of %s\n\n", line_count, $2->getSymbolName().c_str());
                }
            }

            func_def = $1->getSymbolName();
            func_def += " ";
            func_def += $2->getSymbolName();
            func_def += "(";
            for (int i = 0; i < paramList.size(); i++) {
                func_def += paramList[i].second;
                func_def += " ";
                func_def += paramList[i].first;
                if (i != paramList.size() - 1) {
                    func_def += ",";
                }
            }
            func_def += ")";
        }
        compound_statement
        {

            func_def += compound_stmt;
            fprintf(logfile, "Line %d: func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n%s\n\n\n", line_count, func_def.c_str());
            $$ = new SymbolInfo(func_def, "func_definition");

        }
    |   type_specifier ID LPAREN RPAREN
        {
            paramList.clear();
            FunctionSpecs * funcSpecs = new FunctionSpecs($1->getSymbolName(), paramList.size(), paramList);
            SymbolInfo * newSymbol = symbolTable->lookUp($2->getSymbolName());
            bool flag = true, flag1 = true;

            if (newSymbol == nullptr)
            {
                symbolTable->Insert(new SymbolInfo($2->getSymbolName(), $2->getSymbolType(), funcSpecs, "function_def"));
            }
            else
            {
                if (newSymbol->getDataType() == "function_dec")
                {
                    if (newSymbol->getFunctionSpecs()->getParamList().size() != paramList.size()) flag1 = false;

                    if (funcSpecs->getReturnType() != newSymbol->getFunctionSpecs()->getReturnType())
                    {
                        error_count++;
                        fprintf(errorfile, "Error at line %d: Return type mismatch with function declaration in function %s\n\n", line_count, $2->getSymbolName().c_str());
                        fprintf(logfile, "Error at line %d: Return type mismatch with function declaration in function %s\n\n", line_count, $2->getSymbolName().c_str());
                    }
                    else if (flag1)
                    {
                        symbolTable->ChangeDataType($2->getSymbolName(), "function_def");
                    }
                    else
                    {
                        error_count++;
                        fprintf(errorfile, "Error at line %d: Total number of arguments mismatch with declaration in function %s\n\n", line_count, $2->getSymbolName().c_str());
                        fprintf(logfile, "Error at line %d: Total number of arguments mismatch with declaration in function %s\n\n", line_count, $2->getSymbolName().c_str());
                    }
                }
                else if (newSymbol->getDataType() == "function_def")
                {
                    error_count++;
                    fprintf(errorfile, "Error at line %d : Multiple Definition of %s\n\n", line_count, $2->getSymbolName().c_str());
                    fprintf(logfile, "Error at line %d : Multiple Definition of %s\n\n", line_count, $2->getSymbolName().c_str());
                }
                else
                {
                    error_count++;
                    fprintf(errorfile, "Error at line %d : Multiple Declaration of %s\n\n", line_count, $2->getSymbolName().c_str());
                    fprintf(logfile, "Error at line %d : Multiple Declaration of %s\n\n", line_count, $2->getSymbolName().c_str());
                }
            }

            func_def = $1->getSymbolName();
            func_def += " ";
            func_def += $2->getSymbolName();
            func_def += "(";
            func_def += ")";
        }
        compound_statement
        {

            func_def += compound_stmt;
            fprintf(logfile, "Line %d: func_definition : type_specifier ID LPAREN RPAREN compound_statement\n\n%s\n\n\n", line_count, func_def.c_str());
            $$ = new SymbolInfo(func_def, "func_definition");
        }
    ;

parameter_list :
        parameter_list COMMA type_specifier ID
        {

            temp = $1->getSymbolName();
            temp += ",";
            temp += $3->getSymbolName();
            temp += " ";
            temp += $4->getSymbolName();

            paramList.push_back({$4->getSymbolName(), $3->getSymbolName()});

            fprintf(logfile, "Line %d: parameter_list : parameter_list COMMA type_specifier ID\n\n%s\n\n\n", line_count, temp.c_str());
            $$ = new SymbolInfo(temp, "parameter_list");

            if ($3->getDataType() == "void")
            {
                error_count++;
                fprintf(errorfile, "Error at line %d : Invalid type specifier\n\n", line_count);
                fprintf(logfile, "Error at line %d : Invalid type specifier\n\n", line_count);
            }
        }
    |   parameter_list COMMA type_specifier
        {

            paramList.push_back({"", $3->getSymbolName()});
            temp = $1->getSymbolName();
            temp += ",";
            temp += $3->getSymbolName();

            fprintf(logfile, "Line %d: parameter_list : parameter_list COMMA type_specifier\n\n%s\n\n", line_count, temp.c_str());
            $$ = new SymbolInfo(temp, "parameter_list");

            if ($3->getDataType() == "void")
            {
                error_count++;
                fprintf(errorfile, "Error at line %d : Invalid type specifier\n\n", line_count);
                fprintf(logfile, "Error at line %d : Invalid type specifier\n\n", line_count);
            }
        }
    |   type_specifier ID
        {

            temp = $1->getSymbolName();
            temp += " ";
            temp += $2->getSymbolName();

            paramList.push_back({$2->getSymbolName(), $1->getSymbolName()});

            fprintf(logfile, "Line %d: parameter_list : type_specifier ID\n\n%s\n\n", line_count, temp.c_str());
            $$ = new SymbolInfo(temp, "parameter_list", $1->getDataType());

            if ($1->getDataType() == "void")
            {
                error_count++;
                fprintf(errorfile, "Error at line %d : Invalid type specifier\n\n", line_count);
                fprintf(logfile, "Error at line %d : Invalid type specifier\n\n", line_count);
            }
        }
    |   type_specifier
        {

            paramList.push_back({"", $1->getSymbolName()});//symbolname - int, float -- here type

            fprintf(logfile, "Line %d: parameter_list : type_specifier\n\n%s\n\n", line_count, paramList.back().second.c_str());
            $$ = new SymbolInfo(paramList.back().second, "parameter_list", $1->getDataType());
            if ($1->getDataType() == "void")
            {
                error_count++;
                fprintf(errorfile, "Error at line %d : Invalid type specifier\n\n", line_count);
                fprintf(logfile, "Error at line %d : Invalid type specifier\n\n", line_count);
            }
        }
    ;

compound_statement :
        LCURL
        {
            symbolTable->enterScope(logfile);
            for (auto &param : paramList) {
                if (param.first != "") {
                    SymbolInfo * newSymbol = symbolTable->lookUp(param.first);

                    if (newSymbol != nullptr)
                    {
                        error_count++;
                        fprintf(logfile, "Error at line %d: Multiple declaration of %s in parameter\n\n", line_count, param.first.c_str());
                        fprintf(errorfile, "Error at line %d: Multiple declaration of %s in parameter\n\n", line_count, param.first.c_str());
                    }

                    symbolTable->Insert(param.first, "ID", param.second);
                }
            }
            paramList.clear();
        }
        statements RCURL
        {
            temp = "{\n";
            temp += stmts;
            temp += "}\n";

            fprintf(logfile, "Line %d: compound_statement : LCURL statements RCURL\n\n%s\n\n\n", line_count, temp.c_str());
            $$ = new SymbolInfo(temp, "compound_statement");

            symbolTable->exitScope(logfile);
            compound_stmt = temp;
        }
    |   LCURL
        {
            symbolTable->enterScope(logfile);
            for (auto &param : paramList) {
                if (param.first != "") {
                    SymbolInfo * newSymbol = symbolTable->lookUp(param.first);

                    if (newSymbol != nullptr)
                    {
                        error_count++;
                        fprintf(logfile, "Error at line %d: Multiple declaration of %s in parameter\n\n", line_count, param.first.c_str());
                        fprintf(errorfile, "Error at line %d: Multiple declaration of %s in parameter\n\n", line_count, param.first.c_str());
                    }
                    symbolTable->Insert(param.first, "ID", param.second);
                }
            }
            paramList.clear();
        }
        RCURL
        {

            temp = "{";
            temp += "}\n";

            fprintf(logfile, "Line %d: compound_statement : LCURL RCURL\n\n%s\n\n\n", line_count, temp.c_str());
            $$ = new SymbolInfo(temp, "compound_statement");

            symbolTable->exitScope(logfile);
            compound_stmt = temp;
        }
    ;

var_declaration :
        type_specifier declaration_list SEMICOLON
        {

            temp = $1->getSymbolName();
            temp += " ";
            temp += $2->getSymbolName();
            temp += ";\n";

            fprintf(logfile, "Line %d: var_declaration : type_specifier declaration_list SEMICOLON\n\n%s\n\n", line_count, temp.c_str());
            $$ = new SymbolInfo(temp, "var_declaration", $1->getDataType());

            if ($1->getSymbolName() == "void")
            {
                error_count++;
                fprintf(errorfile, "Error at line %d: variable type cannot be void\n\n", line_count);
                fprintf(logfile, "Error at line %d: variable type cannot be void\n\n", line_count);
            }

            for (int i = 0; i < declarationList.size(); i++)
            {
                if (declarationList[i].second == "array")
                {
                    symbolTable->ChangeDataType(declarationList[i].first, $1->getSymbolName(), true);
                }
                else
                {
                    symbolTable->ChangeDataType(declarationList[i].first, $1->getSymbolName());
                }
                if ($1->getSymbolName() == "void")
                {
                    symbolTable->Delete(declarationList[i].first);
                }
            }
            declarationList.clear();

        }
    ;

type_specifier :
        INT
        {

            fprintf(logfile, "Line %d: type_specifier : INT\n\nint\n\n", line_count);
            $$ = new SymbolInfo("int", "CONST_INT", "int");
        }
    |   FLOAT
        {

            fprintf(logfile, "Line %d: type_specifier : FLOAT\n\nfloat\n\n", line_count);
            $$ = new SymbolInfo("float", "CONST_FLOAT", "float");
        }
    |   VOID
        {

            fprintf(logfile, "Line %d: type_specifier : VOID\n\nvoid\n\n", line_count);
            $$ = new SymbolInfo("void", "VOID", "void");
        }
    ;

declaration_list :
        declaration_list COMMA ID
        {

            temp = $1->getSymbolName();
            temp += ",";
            temp += $3->getSymbolName();
            fprintf(logfile, "Line %d: declaration_list : declaration_list COMMA ID\n\n%s\n\n", line_count, temp.c_str());

            if (symbolTable->lookUp($3->getSymbolName()) == nullptr)
            {

                if ($3->getSymbolType() != "VOID")
                {

                    declarationList.push_back({$3->getSymbolName(), "ID"});
                    symbolTable->Insert($3);
                }
                else
                {
                    error_count++;
                    fprintf(errorfile, "Error at line %d : variable declared with void type\n\n", line_count);
                    fprintf(logfile, "Error at line %d : variable declared with void type\n\n", line_count);
                }
            }
            else
            {

                error_count++;
                fprintf(errorfile, "Error at line %d : Multiple Declaration of %s\n\n", line_count, $3->getSymbolName().c_str());
                fprintf(logfile, "Error at line %d : Multiple Declaration of %s\n\n", line_count, $3->getSymbolName().c_str());

            }
            $$ = new SymbolInfo(temp, "declaration_list", $1->getDataType());
        }
    |   declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
        {

            temp = $1->getSymbolName();
            temp += ",";
            temp += $3->getSymbolName();
            temp += "[";
            temp += $5->getSymbolName();
            temp += "]";

            fprintf(logfile, "Line %d: declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n\n%s\n\n", line_count, temp.c_str());

            if (symbolTable->lookUp($3->getSymbolName()) == nullptr)
            {

                if ($3->getSymbolType() != "VOID")
                {

                    declarationList.push_back({$3->getSymbolName(), "array"});
                    symbolTable->Insert(new SymbolInfo($3->getSymbolName(), $3->getSymbolType(), "array"));
                }
                else
                {
                    error_count++;
                    fprintf(errorfile, "Error at line %d : variable declared with void type\n\n", line_count);
                    fprintf(logfile, "Error at line %d : variable declared with void type\n\n", line_count);
                }
            }
            else
            {

                error_count++;
                fprintf(errorfile, "Error at line %d : Multiple Declaration of %s\n\n", line_count, $3->getSymbolName().c_str());
                fprintf(logfile, "Error at line %d : Multiple Declaration of %s\n\n", line_count, $3->getSymbolName().c_str());

            }
            $$ = new SymbolInfo(temp, "declaration_list", $1->getDataType());
        }
    |   ID
        {


            fprintf(logfile, "Line %d: declaration_list : ID\n\n%s\n\n", line_count, $1->getSymbolName().c_str());


            if (symbolTable->lookUp($1->getSymbolName()) == nullptr)
            {

                if ($1->getSymbolType() != "VOID")
                {
                    declarationList.push_back({$1->getSymbolName(), "ID"});
                    symbolTable->Insert($1->getSymbolName(), $1->getSymbolType());
                }
                else
                {
                    error_count++;
                    fprintf(errorfile, "Error at line %d : variable declared with void type\n\n", line_count);
                    fprintf(logfile, "Error at line %d : variable declared with void type\n\n", line_count);
                }
            }
            else
            {

                error_count++;
                fprintf(errorfile, "Error at line %d : Multiple Declaration of %s\n\n", line_count, $1->getSymbolName().c_str());
                fprintf(logfile, "Error at line %d : Multiple Declaration of %s\n\n", line_count, $1->getSymbolName().c_str());

            }
            $$ = $1;
        }
    |   ID LTHIRD CONST_INT RTHIRD
        {

            temp = $1->getSymbolName();
            temp += "[";
            temp += $3->getSymbolName();
            temp += "]";

            fprintf(logfile, "Line %d: declaration_list : ID LTHIRD CONST_INT RTHIRD\n%s\n\n%s\n\n", line_count, $3->getSymbolName().c_str(), temp.c_str());


            if (symbolTable->lookUp($1->getSymbolName()) == nullptr)
            {

                if ($1->getSymbolType() != "VOID")
                {
                    declarationList.push_back({$1->getSymbolName(), "array"});
                    symbolTable->Insert(new SymbolInfo($1->getSymbolName(), $1->getSymbolType(), "array"));
                }
                else
                {
                    error_count++;
                    fprintf(errorfile, "Error at line %d : variable declared with void type\n\n", line_count);
                    fprintf(logfile, "Error at line %d : variable declared with void type\n\n", line_count);
                }
            }
            else
            {

                error_count++;
                fprintf(errorfile, "Error at line %d : Multiple Declaration of %s\n\n", line_count, $1->getSymbolName().c_str());
                fprintf(logfile, "Error at line %d : Multiple Declaration of %s\n\n", line_count, $1->getSymbolName().c_str());

            }
            $$ = new SymbolInfo(temp, "declaration_list", $1->getDataType());
        }
    ;

statements :
        statement
        {

            fprintf(logfile, "Line %d: statements : statement\n\n%s\n\n", line_count, $1->getSymbolName().c_str());
            $$ = $1;
            stmts = $1->getSymbolName();
        }
    |   statements statement
        {

            temp = $1->getSymbolName();
            temp += $2->getSymbolName();
            fprintf(logfile, "Line %d: statements : statements statement\n\n%s\n\n", line_count, temp.c_str());
            $$ = new SymbolInfo(temp, "statements", $1->getDataType());
            stmts = temp;
        }
    ;

statement :
        var_declaration
        {

            temp = $1->getSymbolName();

            fprintf(logfile, "Line %d: statement : var_declaration\n\n%s\n\n", line_count, temp.c_str());
            $$ = new SymbolInfo(temp, "statement", $1->getDataType());
        }
    |   expression_statement
        {

            temp = $1->getSymbolName();

            fprintf(logfile, "Line %d: statement : expression_statement\n\n%s\n\n", line_count, temp.c_str());
            $$ = new SymbolInfo(temp, "statement", $1->getDataType());
        }
    |   compound_statement
        {

            temp = $1->getSymbolName();

            fprintf(logfile, "Line %d: statement : compound_statement\n\n%s\n\n", line_count, temp.c_str());
            $$ = new SymbolInfo(temp, "statement", $1->getDataType());
        }
    |   FOR LPAREN expression_statement expression_statement expression RPAREN statement
        {

            temp = "for";
            temp += "(";
            string removedNewline = $3->getSymbolName();
            removedNewline = removedNewline.substr(0, removedNewline.size() - 1);
            temp += removedNewline;
            removedNewline = $4->getSymbolName();
            removedNewline = removedNewline.substr(0, removedNewline.size() - 1);
            temp += removedNewline;
            temp += $5->getSymbolName();

            temp += ")";
            temp += $7->getSymbolName();

            fprintf(logfile, "Line %d: statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n%s\n\n", line_count, temp.c_str());
            $$ = new SymbolInfo(temp, "statement", "for");
        }
    |   IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
        {

            temp = "if ";
            temp += "(";
            temp += $3->getSymbolName();
            temp += ")";
            temp += $5->getSymbolName();

            fprintf(logfile, "Line %d: statement : IF LPAREN expression RPAREN statement\n\n%s\n\n", line_count, temp.c_str());
            $$ = new SymbolInfo(temp, "statement", "if");
        }
    |   IF LPAREN expression RPAREN statement ELSE statement
        {

            temp = "if ";
            temp += "(";
            temp += $3->getSymbolName();
            temp += ")";
            temp += $5->getSymbolName();
            temp += "else\n";
            temp += $7->getSymbolName();

            fprintf(logfile, "Line %d: statement : IF LPAREN expression RPAREN statement ELSE statement\n\n%s\n\n", line_count, temp.c_str());
            $$ = new SymbolInfo(temp, "statement", "if");
        }
    |   WHILE LPAREN expression RPAREN statement
        {

            temp = "while";
            temp += "(";
            temp += $3->getSymbolName();
            temp += ")";
            temp += $5->getSymbolName();

            fprintf(logfile, "Line %d: statement : WHILE LPAREN expression RPAREN statement\n\n%s\n\n", line_count, temp.c_str());
            $$ = new SymbolInfo(temp, "statement", "while");
        }
    |   PRINTLN LPAREN ID RPAREN SEMICOLON
        {

            temp = "println";
            temp += "(";
            temp += $3->getSymbolName();
            temp += ");\n";

            fprintf(logfile, "Line %d: statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n%s\n\n", line_count, temp.c_str());

            SymbolInfo *newSymbol = symbolTable->lookUpAllScope($3->getSymbolName());

            if (newSymbol == nullptr)
            {
                error_count++;
                fprintf(errorfile, "Error at line %d: Undeclared variable %s\n\n", line_count, $3->getSymbolName().c_str());
                fprintf(logfile, "Error at line %d: Undeclared variable %s\n\n", line_count, $3->getSymbolName().c_str());
            }

            $$ = new SymbolInfo(temp, "statement", "println");
        }
    |   RETURN expression SEMICOLON
        {

            temp = "return ";
            temp += $2->getSymbolName();
            temp += ";\n";
            fprintf(logfile, "Line %d: statement : RETURN expression SEMICOLON\n\n%s\n\n", line_count, temp.c_str());
            $$ = new SymbolInfo(temp, "statement", $2->getDataType());
        }
    ;

expression_statement :
        SEMICOLON
        {

            fprintf(logfile, "Line %d: expression_statement : SEMICOLON\n\n%s\n\n", line_count, ";");
            $$ = new SymbolInfo(";\n", "expression_statement");
        }
    |   expression SEMICOLON
        {

            temp = $1->getSymbolName();
            temp += ";\n";

            fprintf(logfile, "Line %d: expression_statement : expression SEMICOLON\n\n%s\n\n", line_count, temp.c_str());
            $$ = new SymbolInfo(temp, "expression_statement", $1->getDataType());
        }
    ;

variable :
        ID
        {

            fprintf(logfile, "Line %d: variable : ID\n\n%s\n\n", line_count, $1->getSymbolName().c_str());

            SymbolInfo * newSymbol = symbolTable->lookUpAllScope($1->getSymbolName());
            if (newSymbol == nullptr)
            {
                error_count++;
                fprintf(errorfile, "Error at line %d : Undeclared Variable: %s\n\n", line_count, $1->getSymbolName().c_str());
                fprintf(logfile, "Error at line %d : Undeclared Variable: %s\n\n", line_count, $1->getSymbolName().c_str());
                $$ = new SymbolInfo($1->getSymbolName(), "ID", "null");
            }
            else
            {
                $$ = new SymbolInfo($1->getSymbolName(), "ID", newSymbol->getDataType(), newSymbol->getIsArray());
                if (newSymbol->getIsArray())
                {
                    $$->setDataType($$->getDataType() + "_array");
                }
            }
        }
    |   ID LTHIRD expression RTHIRD
        {

            temp = $1->getSymbolName();
            temp += "[";
            temp += $3->getSymbolName();
            temp += "]";


            fprintf(logfile, "Line %d: variable : ID LTHIRD expression RTHIRD\n\n%s\n\n", line_count, temp.c_str());

            if ($3->getDataType() != "int") {
                error_count++;
                fprintf(errorfile, "Error at line %d: Expression inside third brackets not an integer\n\n", line_count);
                fprintf(logfile, "Error at line %d: Expression inside third brackets not an integer\n\n", line_count);
            }

            if (!symbolTable->lookUpAllScope($1->getSymbolName())->getIsArray())
            {
                error_count++;
                fprintf(errorfile, "Error at line %d : %s not an array\n\n", line_count, $1->getSymbolName().c_str());
                fprintf(logfile, "Error at line %d : %s not an array\n\n", line_count, $1->getSymbolName().c_str());
            }

            $$ = new SymbolInfo(temp, "ID", symbolTable->lookUpAllScope($1->getSymbolName())->getDataType());
        }
    ;

expression :
        logic_expression
        {

            fprintf(logfile, "Line %d: expression : logic_expression\n\n%s\n\n", line_count, $1->getSymbolName().c_str());
            $$ = $1;
        }
    |   variable ASSIGNOP logic_expression
        {

            temp = $1->getSymbolName();
            temp += "=";
            temp += $3->getSymbolName();

            fprintf(logfile, "Line %d: expression : variable ASSIGNOP logic_expression\n\n%s\n\n", line_count, temp.c_str());
            $$ = new SymbolInfo(temp, "expression", $1->getDataType());
            if ($3->getDataType() == "void")
            {
                error_count++;
                fprintf(errorfile, "Error at line %d: Void function used in expression\n\n", line_count);
                fprintf(logfile, "Error at line %d: Void function used in expression\n\n", line_count);
            }
            else if ($1->getDataType() == "int" && $3->getDataType() == "int")
            {

            }
            else if ($1->getDataType() == "float" && ($3->getDataType() == "int" || $3->getDataType() == "float"))
            {

            }
            else if ($1->getDataType() == "null" || $3->getDataType() == "null")
            {

            }
            else if ($3->getDataType() == "Undeclared")
            {

            }
            else
            {
                error_count++;
                fprintf(errorfile, "Error at line %d : Type Mismatch\n\n", line_count);
                fprintf(logfile, "Error at line %d : Type Mismatch\n\n", line_count);
            }
        }
    ;

logic_expression :
        rel_expression
        {

            fprintf(logfile, "Line %d: logic_expression : rel_expression\n\n%s\n\n", line_count, $1->getSymbolName().c_str());
            $$ = $1;
        }
    |   rel_expression LOGICOP rel_expression
        {

            temp = $1->getSymbolName();
            temp += $2->getSymbolName();
            temp += $3->getSymbolName();

            fprintf(logfile, "Line %d: logic_expression : rel_expression LOGICOP rel_expression\n\n%s\n\n", line_count, temp.c_str());
            $$ = new SymbolInfo(temp, "logic_expression", "int");

            if ($1->getDataType() == "void" || $3->getDataType() == "void")
            {
                error_count++;
                fprintf(errorfile, "Error at line %d : Invalid operand on LOGICOP\n\n", line_count);
                fprintf(logfile, "Error at line %d : Invalid operand on LOGICOP\n\n", line_count);
            }
        }
    ;

rel_expression :
        simple_expression
        {

            fprintf(logfile, "Line %d: rel_expression : simple_expression\n\n%s\n\n", line_count, $1->getSymbolName().c_str());
            $$ = $1;
        }
    |   simple_expression RELOP simple_expression
        {

            temp = $1->getSymbolName();
            temp += $2->getSymbolName();
            temp += $3->getSymbolName();

            fprintf(logfile, "Line %d: rel_expression : simple_expression RELOP simple_expression\n\n%s\n\n", line_count, temp.c_str());

            if ($1->getDataType() == "void" || $3->getDataType() == "void")
            {
                error_count++;
                fprintf(errorfile, "Error at line %d : Invalid operand on RELOP\n\n", line_count);
                fprintf(logfile, "Error at line %d : Invalid operand on RELOP\n\n", line_count);
            }

            $$ = new SymbolInfo(temp, "rel_expression", "int");
        }
    ;

simple_expression :
        term
        {

            fprintf(logfile, "Line %d: simple_expression : term\n\n%s\n\n", line_count, $1->getSymbolName().c_str());
            $$ = $1;
        }
    |   simple_expression ADDOP term
        {

            temp = $1->getSymbolName();
            temp += $2->getSymbolName();
            temp += $3->getSymbolName();
            fprintf(logfile, "Line %d: simple_expression : simple_expression ADDOP term\n\n%s\n\n", line_count, temp.c_str());

            string tempDataType = "default";

            if ($1->getDataType() == "int" || $3->getDataType() == "int") tempDataType = "int";
            if ($1->getDataType() == "float" || $3->getDataType() == "float") tempDataType = "float";
            if (!($1->getDataType() == "int" || $1->getDataType() == "float")) tempDataType = "wrong";
            if (!($3->getDataType() == "int" || $3->getDataType() == "float")) tempDataType = "wrong";

            if ($1->getDataType() == "void" || $3->getDataType() == "void")
            {
                tempDataType = "void";
            }

            if (tempDataType == "wrong")
            {
                error_count++;
                fprintf(logfile, "Error at line %d : Invalid Operands on ADDOP\n\n", line_count);
                fprintf(errorfile, "Error at line %d : Invalid Operands on ADDOP\n\n", line_count);
            }

            $$ = new SymbolInfo(temp, "simple_expression", tempDataType);
        }
    ;

term :
        unary_expression
        {

            fprintf(logfile, "Line %d: term : unary_expression\n\n%s\n\n", line_count, $1->getSymbolName().c_str());
            $$ = $1;
        }
    |   term MULOP unary_expression
        {

            temp = $1->getSymbolName();
            temp += $2->getSymbolName();
            temp += $3->getSymbolName();
            fprintf(logfile, "Line %d: term : term MULOP unary_expression\n\n%s\n\n", line_count, temp.c_str());

            string tempDataType = "default";

            if ($1->getDataType() == "int" || $3->getDataType() == "int") tempDataType = "int";
            if ($1->getDataType() == "float" || $3->getDataType() == "float") tempDataType = "float";
            if (!($1->getDataType() == "int" || $1->getDataType() == "float")) tempDataType = "wrong";
            if (!($3->getDataType() == "int" || $3->getDataType() == "float")) tempDataType = "wrong";

            if ($1->getDataType() == "void" || $3->getDataType() == "void")
            {
                tempDataType = "void";
            }

            if (tempDataType == "wrong")
            {
                error_count++;
                fprintf(errorfile, "Error at line %d : Invalid Operands on MULOP\n\n", line_count);
                fprintf(logfile, "Error at line %d : Invalid Operands on MULOP\n\n", line_count);
            }

            if ($2->getSymbolName() == "%" && ($1->getDataType() == "float" || $3->getDataType() == "float"))
            {
                error_count++;
                fprintf(errorfile, "Error at line %d : Non-Integer operand on modulus operator\n\n", line_count);
                fprintf(logfile, "Error at line %d : Integer operand on modulus operator\n\n", line_count);
            }
            else if ($2->getSymbolName() == "%" && $3->getSymbolName() == "0")
            {
                error_count++;
                fprintf(errorfile, "Error at line %d: Modulus by zero\n\n", line_count);
                fprintf(logfile, "Error at line %d: Modulus by zero\n\n", line_count);
            }
            else if ($2->getSymbolName() == "/" && $3->getSymbolName() == "0")
            {
                error_count++;
                fprintf(errorfile, "Error at line %d: Divide by zero\n\n", line_count);
                fprintf(logfile, "Error at line %d: Divide by zero\n\n", line_count);
            }

            if ($2->getSymbolName() == "%" && tempDataType != "void")
            {
                tempDataType = "int";
            }

            $$ = new SymbolInfo(temp, "term", tempDataType);
        }
    ;

unary_expression :
        ADDOP unary_expression
        {

            temp = $1->getSymbolName();
            temp += $2->getSymbolName();
            fprintf(logfile, "Line %d: unary_expression : ADDOP unary_expression\n\n%s\n\n", line_count, temp.c_str());
            $$ = new SymbolInfo(temp, "unary_expression", $2->getDataType());
        }
    |   NOT unary_expression
        {

            temp = "!";
            temp += $2->getSymbolName();

            fprintf(logfile, "Line %d: unary_expression : NOT unary_expression\n\n%s\n\n", line_count, temp.c_str());
            $$ = new SymbolInfo(temp, "unary_expression", $2->getDataType());
        }
    |   factor
        {

            fprintf(logfile, "Line %d: unary_expression : factor\n\n%s\n\n", line_count, $1->getSymbolName().c_str());
            $$ = $1;
        }
    ;

factor :
        variable
        {


            fprintf(logfile, "Line %d: factor : variable\n\n%s\n\n", line_count, $1->getSymbolName().c_str());
            $$ = $1;
        }
    |   ID LPAREN argument_list RPAREN
        {

            SymbolInfo *newSymbol = symbolTable->lookUpAllScope($1->getSymbolName());
            string tempReturnType = "void";

            if (newSymbol == nullptr)
            {
                error_count++;
                fprintf(errorfile, "Error at line %d : Undeclared function %s\n\n",line_count,  $1->getSymbolName().c_str());
                fprintf(logfile, "Error at line %d : Undeclared function %s\n\n",line_count,  $1->getSymbolName().c_str());
                tempReturnType = "Undeclared";
            }
            else
            {
                if (newSymbol->getDataType() == "function_def" || newSymbol->getDataType() == "function_dec")
                {
                    vector<pair<string, string> > tempParamList = newSymbol->getFunctionSpecs()->getParamList();
                    tempReturnType = newSymbol->getFunctionSpecs()->getReturnType();
                    bool isCallOk = true,argNumMisMatch = false;

                    if (argList.size() != tempParamList.size()) argNumMisMatch = true;

                    for (int i = 0; i < min(tempParamList.size(), argList.size()); i++)
                    {
                        if (argList[i].second == "int" && tempParamList[i].second == "float")
                        {

                        }
                        else if (argList[i].second != tempParamList[i].second)
                        {
                            error_count++;
                            if (argList[i].second == "int_array" || argList[i].second == "float_array")
                            {
                                fprintf(errorfile, "Error at line %d: Type mismatch, %s in an array\n\n", line_count, argList[i].first.c_str());
                                fprintf(logfile, "Error at line %d: Type mismatch, %s in an array\n\n", line_count, argList[i].first.c_str());
                            }
                            else
                            {
                                fprintf(errorfile, "Error at line %d: %dth argument mismatch in function %s\n\n", line_count, i + 1, $1->getSymbolName().c_str());
                                fprintf(logfile, "Error at line %d: %dth argument mismatch in function %s\n\n", line_count, i + 1, $1->getSymbolName().c_str());
                            }

                            isCallOk = false;
                            break;
                        }
                    }

                    if (isCallOk && argNumMisMatch)
                    {
                        error_count++;
                        fprintf(errorfile, "Error at line %d: Total number of arguments mismatch in function %s\n\n", line_count, $1->getSymbolName().c_str());
                        fprintf(logfile, "Error at line %d: Total number of arguments mismatch in function %s\n\n", line_count, $1->getSymbolName().c_str());

                    }
                }
                else
                {
                    error_count++;
                    fprintf(errorfile, "Error at line %d : %s is not a function\n\n", line_count, $1->getSymbolName().c_str());
                    fprintf(logfile, "Error at line %d : %s is not a function\n\n", line_count, $1->getSymbolName().c_str());
                }
            }

            temp = $1->getSymbolName();
            temp += "(";
            for (int i = 0; i < argList.size(); i++)
            {
                //temp += " ";
                temp += argList[i].first;
                //temp += " ";
                if (i != argList.size() - 1) temp += ",";
            }
            temp += ")";

            fprintf(logfile, "Line %d: factor : ID LPAREN argument_list RPAREN\n\n%s\n\n", line_count, temp.c_str());

            $$ = new SymbolInfo(temp, "factor", tempReturnType);
            argList.clear();

        }
    |   LPAREN expression RPAREN
        {

            temp = "(";
            temp += $2->getSymbolName();
            temp += ")";

            fprintf(logfile, "Line %d: factor : LPAREN expression RPAREN\n\n%s\n\n", line_count, temp.c_str());
            $$ = new SymbolInfo(temp, "factor", $2->getDataType());
        }
    |   CONST_INT
        {

            fprintf(logfile, "Line %d: factor : CONST_INT\n\n%s\n\n", line_count, $1->getSymbolName().c_str());
            $$ = $1;
        }
    |   CONST_FLOAT
        {

            fprintf(logfile, "Line %d: factor : CONST_FLOAT\n\n%s\n\n", line_count, $1->getSymbolName().c_str());
            $$ = $1;
        }
    |   variable INCOP
        {


            temp = $1->getSymbolName();
            temp += "++";
            fprintf(logfile, "Line %d: factor : variable INCOP\n\n%s\n\n", line_count, temp.c_str());
            $$ = new SymbolInfo(temp, "factor", $1->getDataType());

            if (!($1->getDataType() == "int" || $1->getDataType() == "float"))
            {
                fprintf(errorfile, "Error at line %d : Invalid operand on INCOP\n\n", line_count);
                fprintf(logfile, "Error at line %d : Invalid operand on INCOP\n\n", line_count);
            }
        }
    |   variable DECOP
        {

            temp = $1->getSymbolName();
            temp += "--";
            fprintf(logfile, "Line %d: factor : variable DECOP\n\n%s\n\n", line_count, temp.c_str());
            $$ = new SymbolInfo(temp, "factor", $1->getDataType());

            if (!($1->getDataType() == "int" || $1->getDataType() == "float"))
            {
                fprintf(errorfile, "Error at line %d : Invalid operand on DECOP\n\n", line_count);
                fprintf(logfile, "Error at line %d : Invalid operand on DECOP\n\n", line_count);
            }
        }
    ;

argument_list :
        arguments
        {

            fprintf(logfile, "Line %d: argument_list : arguments\n\n%s\n\n", line_count, $1->getSymbolName().c_str());
            $$ = $1;
        }
    |   {

            argList.clear();
        }
    ;

arguments :
        arguments COMMA logic_expression
        {

            temp = $1->getSymbolName();
            temp += ",";
            temp += $3->getSymbolName();

            argList.push_back({$3->getSymbolName(), $3->getDataType()});

            fprintf(logfile, "Line %d: arguments : arguments COMMA logic_expression\n\n%s\n\n", line_count, temp.c_str());
            $$ = new SymbolInfo(temp, "arguments");
        }
    |   logic_expression
        {

            argList.push_back({$1->getSymbolName(), $1->getDataType()});
            fprintf(logfile, "Line %d: arguments : logic_expression\n\n%s\n\n", line_count, $1->getSymbolName().c_str());
            $$ = $1;
        }
    ;

%%

int main(int argc, char *argv[]){
    FILE *fp;

    if (argc < 2) {
        printf("Please provide filename\n");
        return 0;
    }

    if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

    symbolTable = new SymbolTable(30);

	yyin=fp;


	yyparse();

    fclose(fp);
    fclose(logfile);
    fclose(errorfile);

	return 0;
}
