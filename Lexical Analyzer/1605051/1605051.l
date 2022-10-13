%option noyywrap

%{
#include<iostream>
#include<cstdio>
#include<stdlib.h>
#include<string>
#include<cstring>

#include "SymbolTable/SymbolTable.cpp"

using namespace std;


int line_count=1;
int error_count = 0;

FILE *logout;
FILE *tokenout;
SymbolTable *symbolTable;

%}

WHITESPACE		 	[ \t\f\r\v]+

ALPHABET 			[a-zA-Z]

ALPHANUMERIC 		[a-zA-Z0-9]

IDENTIFIER			("_"|{ALPHABET})("_"|{ALPHANUMERIC})*

DIGIT 				[0-9]

DIGITS 				{DIGIT}+

NEWLINE 			\r?\n

KEYWORDS 			(if|for|do|int|float|void|switch|default|else|while|break|char|double|return|case|continue)

FRACTION			\.{DIGITS}

FLOAT_VALUE			({FRACTION}|{DIGITS}{FRACTION}?)((E|e)(\+|\-)?{DIGITS})?

ADDOP				(\+|\-)

MULOP				(\*|\/|\%)

INCOP				(\+\+|\-\-)

RELOP				("<"|"<="|">"|">="|"=="|"!=")

ASSIGNOP			"="

LOGICOP				("&&"|"||")

NOT 				"!"

LPAREN				"("

RPAREN				")"

LCURL				"{"

RCURL				"}"

LTHIRD				"["

RTHIRD				"]"

COMMA				","

SEMICOLON			";"

ESCAPE_CHARS		(n|t|\\|\'|a|f|r|b|v|0|\")

STRING				\"([^\r\n\"]|(\\\")|(\\\r?\n))*\"

UTSTRING			\"([^\r\n\"]|(\\\")|(\\\r?\n))*

SLCOMMENT			\/\/([^\r\n]|\\\r?\n)*

MLCOMMENT			\/\*([^*]|\*[^\/])*\*\/

COMMENT				({SLCOMMENT}|{MLCOMMENT})

UTCOMMENT			\/\*([^*]|\*[^\/])*

%%

{NEWLINE} {line_count++;}

{KEYWORDS}		{
	string token = yytext;
	for (int i = 0; i < token.size(); i++) token[i] -= 32;

	fprintf(tokenout, "<%s> ", token.c_str());

	fprintf(logout, "\nLine no %d: Token <%s> Lexeme %s found\n", line_count, token.c_str(), yytext);
}

{IDENTIFIER}	{
	fprintf(tokenout, "<ID, %s> ", yytext);
	fprintf(logout, "\nLine no %d: Token <ID> Lexeme %s found\n", line_count, yytext);

	if (symbolTable->Insert(logout, yytext, "ID"))
		symbolTable->printAllScope(logout);
}

{DIGITS}		{
	fprintf(tokenout, "<CONST_INT, %s> ", yytext);
	fprintf(logout, "\nLine no %d: Token <CONST_INT> Lexeme %s found\n", line_count, yytext);

	if (symbolTable->Insert(logout, yytext, "CONST_INT"))
		symbolTable->printAllScope(logout);
}

{FLOAT_VALUE}	{
	fprintf(tokenout, "<CONST_FLOAT, %s> ", yytext);
	fprintf(logout, "\nLine no %d: Token <CONST_FLOAT> Lexeme %s found\n", line_count, yytext);

	if (symbolTable->Insert(logout, yytext, "CONST_FLOAT"))
		symbolTable->printAllScope(logout);
}

{ADDOP}			{
	fprintf(tokenout, "<ADDOP, %s> ", yytext);
	fprintf(logout, "\nLine no %d: Token <ADDOP> Lexeme %s found\n", line_count, yytext);
}

{MULOP}			{
	fprintf(tokenout, "<MULOP, %s> ", yytext);
	fprintf(logout, "\nLine no %d: Token <MULOP> Lexeme %s found\n", line_count, yytext);
}

{INCOP}			{
	fprintf(tokenout, "<INCOP, %s> ", yytext);
	fprintf(logout, "\nLine no %d: Token <INCOP> Lexeme %s found\n", line_count, yytext);
}

{RELOP}			{
	fprintf(tokenout, "<RELOP, %s> ", yytext);
	fprintf(logout, "\nLine no %d: Token <RELOP> Lexeme %s found\n", line_count, yytext);
}

{ASSIGNOP}		{
	fprintf(tokenout, "<ASSIGNOP, %s> ", yytext);
	fprintf(logout, "\nLine no %d: Token <ASSIGNOP> Lexeme %s found\n", line_count, yytext);
}

{LOGICOP}		{
	fprintf(tokenout, "<LOGICOP, %s> ", yytext);
	fprintf(logout, "\nLine no %d: Token <LOGICOP> Lexeme %s found\n", line_count, yytext);
}

{NOT}			{
	fprintf(tokenout, "<NOT, %s> ", yytext);
	fprintf(logout, "\nLine no %d: Token <NOT> Lexeme %s found\n", line_count, yytext);
}

{LPAREN}		{
	fprintf(tokenout, "<LPAREN, %s> ", yytext);
	fprintf(logout, "\nLine no %d: Token <LPAREN> Lexeme %s found\n", line_count, yytext);
}

{RPAREN}		{
	fprintf(tokenout, "<RPAREN, %s> ", yytext);
	fprintf(logout, "\nLine no %d: Token <RPAREN> Lexeme %s found\n", line_count, yytext);
}

{LCURL}			{
	fprintf(tokenout, "<LCURL, %s> ", yytext);
	fprintf(logout, "\nLine no %d: Token <LCURL> Lexeme %s found\n", line_count, yytext);
	symbolTable->enterScope();
}

{RCURL}			{
	fprintf(tokenout, "<RCURL, %s> ", yytext);
	fprintf(logout, "\nLine no %d: Token <RCURL> Lexeme %s found\n", line_count, yytext);
	symbolTable->exitScope();
}

{LTHIRD}		{
	fprintf(tokenout, "<LTHIRD, %s> ", yytext);
	fprintf(logout, "\nLine no %d: Token <LTHIRD> Lexeme %s found\n", line_count, yytext);
}

{RTHIRD}		{
	fprintf(tokenout, "<RTHIRD, %s> ", yytext);
	fprintf(logout, "\nLine no %d: Token <RTHIRD> Lexeme %s found\n", line_count, yytext);
}

{COMMA}			{
	fprintf(tokenout, "<COMMA, %s> ", yytext);
	fprintf(logout, "\nLine no %d: Token <COMMA> Lexeme %s found\n", line_count, yytext);
}

{SEMICOLON}		{
	fprintf(tokenout, "<SEMICOLON, %s> ", yytext);
	fprintf(logout, "\nLine no %d: Token <SEMICOLON> Lexeme %s found\n", line_count, yytext);
}

\'\\{ESCAPE_CHARS}\'	{
	string token = "\'\\";
	token += yytext[2];
	token += "\'";
	string character = "";

	if (yytext[2] == 'n') character = "\n";
	else if (yytext[2] == 't') character = "\t";
	else if (yytext[2] == '\\') character = "\\";
	else if (yytext[2] == 'a') character = "\a";
	else if (yytext[2] == 'f') character = "\f";
	else if (yytext[2] == 'r') character = "\r";
	else if (yytext[2] == 'b') character = "\b";
	else if (yytext[2] == 'v') character = "\v";
	else if (yytext[2] == '\"') character = "\"";
	else if (yytext[2] == '0') character = "\0";
	else character = "\'";

	fprintf(tokenout, "<CHAR_CONST, %s> ", character.c_str());
	fprintf(logout, "\nLine no %d: Token <CONST_CHAR> Lexeme %s found --> <CHAR_CONST, %s>\n",line_count, token.c_str(), character.c_str());
	if (symbolTable->Insert(logout, token, "CONST_CHAR"))
		symbolTable->printAllScope(logout);
}

\'[^\\\']\'			{
	fprintf(tokenout, "<CHAR_CONST, %c> ", yytext[1]);
	fprintf(logout, "\nLine no %d: Token <CONST_CHAR> Lexeme %s found --> <CHAR_CONST, %c>\n",line_count, yytext, yytext[1]);
	if (symbolTable->Insert(logout, yytext, "CONST_CHAR"))
		symbolTable->printAllScope(logout);
}

{STRING}		{
	string token = "", yytexttemp = yytext;
	int temp_line_no = line_count;

	for (int i = 0; i < (int) yytexttemp.size() - 1; i++) {

		if (yytexttemp[i] == '\\' && (yytexttemp[i + 1] == '\n' || (i < (int) yytexttemp.size() - 2 && yytexttemp[i + 1] == '\r' && yytexttemp[i + 2] == '\n'))) {
			if (i < (int) yytexttemp.size() - 2 && yytexttemp[i + 1] == '\r' && yytexttemp[i + 2] == '\n') {
				i += 2;
			}
			else i++;

			line_count++;
		}
		else if (yytexttemp[i] == '\\' && yytexttemp[i + 1] == 'n') {
			token += "\n";
			i++;
		}
		else if (yytexttemp[i] == '\\' && yytexttemp[i + 1] == 't') {
			token += "\t";
			i++;
		}
		else if (yytexttemp[i] == '\\' && yytexttemp[i + 1] == '\\') {
			token += "\\";
			i++;
		}
		else if (yytexttemp[i] == '\\' && yytexttemp[i + 1] == '\'') {
			token += "\'";
			i++;
		}
		else if (yytexttemp[i] == '\\' && yytexttemp[i + 1] == '\"') {
			token += "\"";
			i++;
		}
		else if (yytexttemp[i] == '\\' && yytexttemp[i + 1] == 'a') {
			token += "\a";
			i++;
		}
		else if (yytexttemp[i] == '\\' && yytexttemp[i + 1] == 'f') {
			token += "\f";
			i++;
		}
		else if (yytexttemp[i] == '\\' && yytexttemp[i + 1] == 'r') {
			token += "\r";
			i++;
		}
		else if (yytexttemp[i] == '\\' && yytexttemp[i + 1] == 'b') {
			token += "\b";
			i++;
		}
		else if (yytexttemp[i] == '\\' && yytexttemp[i + 1] == 'v') {
			token += "\v";
			i++;
		}
		else {
			token += yytexttemp[i];
		}

	}
	token += "\"";

	fprintf(tokenout, "<STRING, %s> ", token.c_str());
	fprintf(logout, "\nLine no %d: Token <STRING> Lexeme %s found --> <STRING, %s>\n", temp_line_no, yytext, token.c_str());

}

{COMMENT}		{
	fprintf(logout, "\nLine no %d: Token <COMMENT> Lexeme %s found\n", line_count, yytext);

	string token = yytext;
	for (int i = 0; i < token.size(); i++) {
		if (token[i] == '\n') line_count++;
	}
}

{DIGITS}\.({DIGITS}\.)+{DIGITS}	{
	fprintf(logout, "\nError at line no %d: Too many decimal points %s\n", line_count, yytext);
	error_count++;
}

({DIGITS}(\.{DIGITS})?(E|e)[+-]?)*({DIGITS}\.)+{DIGITS}* 		{
	fprintf(logout, "\nError at line no %d: Ill formed number %s\n", line_count, yytext);
	error_count++;
}

{DIGITS}{IDENTIFIER} 		{
	fprintf(logout, "\nError at line no %d: Invalid prefix on ID or invalid suffix on Number %s\n", line_count, yytext);
	error_count++;
}

\'..+\'			{
	fprintf(logout, "\nError at line no %d: Multi character constant error %s\n", line_count, yytext);
	error_count++;
}

\'(\\\'|[^'\r\n])*		{
	fprintf(logout, "\nError at line no %d: Unterminated character %s\n", line_count, yytext);
	error_count++;
}

\'\'			{
	fprintf(logout, "\nError at line no %d: Empty character constant error %s\n", line_count, yytext);
	error_count++;
}

{UTSTRING}		{
	fprintf(logout, "\nError at line no %d: Unterminated String %s\n", line_count, yytext);
	error_count++;

	string token = yytext;
	for (int i = 0; i < token.size(); i++) {
		if (token[i] == '\n') line_count++;
	}
}

{UTCOMMENT}		{
	fprintf(logout, "\nError at line no %d: Unterminated Comment %s\n", line_count, yytext);
	error_count++;

	string token = yytext;
	for (int i = 0; i < token.size(); i++) {
		if (token[i] == '\n') line_count++;
	}
}

{WHITESPACE}	{}
. 				{
	fprintf(logout, "\nError at line no %d: Unrecognized character %s\n", line_count, yytext);
	error_count++;
}

<<EOF>>			{
	symbolTable->printAllScope(logout);
	fprintf(logout, "\nTotal lines: %d\n", line_count);
	fprintf(logout, "Total errors: %d\n", error_count);
	return 0;
}

%%

int main(int argc,char *argv[]){

	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}

	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}

	logout= fopen("1605051_log.txt","w");
	tokenout= fopen("1605051_token.txt","w");

	symbolTable = new SymbolTable(7);

	yyin = fin;
	yylex();

	fclose(yyin);
	fclose(tokenout);
	fclose(logout);
	return 0;
}
