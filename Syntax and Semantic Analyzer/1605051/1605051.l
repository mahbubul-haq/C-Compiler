%option noyywrap

%{
#include<iostream>
#include<cstdio>
#include<stdlib.h>
#include<string>
#include<cstring>

#include "SymbolInfo.cpp"
#include "y.tab.h"

using namespace std;

int line_count=1;
int error_count = 0;

FILE *logfile = fopen("log.txt", "w");
FILE *errorfile = fopen("error.txt", "w");

extern YYSTYPE yylval;

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

INCOP				"++"

DECOP				"--"

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

{WHITESPACE}	{}
{NEWLINE} 		{line_count++;}

"if" 			{return IF;}
"else"			{return ELSE;}
"for" 			{return FOR;}
"while" 		{return WHILE;}
"int" 			{return INT;}
"float" 		{return FLOAT;}
"return" 		{return RETURN;}
"void" 			{return VOID;}
"printf"		{return PRINTLN;}

{IDENTIFIER}	{

	yylval.symbolinfo =  new SymbolInfo(yytext, "ID");
	return ID;
}

{DIGITS}		{
	yylval.symbolinfo =  new SymbolInfo(yytext, "CONST_INT", "int");
	return CONST_INT;
}

{FLOAT_VALUE}	{
	yylval.symbolinfo = new SymbolInfo(yytext, "CONST_FLOAT", "float");
	return CONST_FLOAT;
}

{ADDOP}			{
	yylval.symbolinfo =  new SymbolInfo(yytext, "ADDOP");
	return ADDOP;
}

{MULOP}			{
	yylval.symbolinfo =  new SymbolInfo(yytext, "MULOP");
	return MULOP;
}

{INCOP}			{
	return INCOP;
}

{DECOP}			{
	return DECOP;
}

{RELOP}			{
	yylval.symbolinfo =  new SymbolInfo(yytext, "RELOP");
	return RELOP;
}

{ASSIGNOP}		{
	return ASSIGNOP;
}

{LOGICOP}		{
	yylval.symbolinfo =  new SymbolInfo(yytext, "LOGICOP");
	return LOGICOP;
}

{NOT}			{
	return NOT;
}

{LPAREN}		{
	return LPAREN;
}

{RPAREN}		{
	return RPAREN;
}

{LCURL}			{
	return LCURL;
}

{RCURL}			{
	return RCURL;
}

{LTHIRD}		{
	return LTHIRD;
}

{RTHIRD}		{
	return RTHIRD;
}

{COMMA}			{
	return COMMA;
}

{SEMICOLON}		{
	return SEMICOLON;
}

\'\\{ESCAPE_CHARS}\'	{
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

	//yylval.symbolinfo = new SymbolInfo(character, "CONST_CHAR");
	//return CONST_CHAR;
}

\'[^\\\']\'			{
	string character = "";
	character += yytext[1];
	//yylval.symbolinfo = new SymbolInfo(character, "CONST_CHAR");
	//return CONST_CHAR;
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
}

{COMMENT}		{
	string token = yytext;
	for (int i = 0; i < token.size(); i++) {
		if (token[i] == '\n') line_count++;
	}
}

{DIGITS}*\.({DIGITS}\.)+{DIGITS}*	{
	fprintf(errorfile, "Error at Line %d: Too many decimal points %s\n\n", line_count, yytext);
	fprintf(logfile, "Error at Line %d: Too many decimal points %s\n\n", line_count, yytext);

	error_count++;
}

({DIGITS}(\.{DIGITS})?(E|e)[+-]?)*({DIGITS}\.)+{DIGITS}* 		{
	fprintf(errorfile, "Error at Line %d: Ill formed number %s\n\n", line_count, yytext);
	fprintf(logfile, "Error at Line %d: Ill formed number %s\n\n", line_count, yytext);
	error_count++;
}

{DIGITS}{IDENTIFIER} 		{
	fprintf(errorfile, "Error at Line %d: Invalid prefix on ID or invalid suffix on Number %s\n\n", line_count, yytext);
	fprintf(logfile, "Error at Line %d: Invalid prefix on ID or invalid suffix on Number %s\n\n", line_count, yytext);
	error_count++;
}

\'..+\'			{
	fprintf(errorfile, "Error at Line %d: Multi character constant error %s\n\n", line_count, yytext);
	fprintf(logfile, "Error at Line %d: Multi character constant error %s\n\n", line_count, yytext);
	error_count++;
}

\'(\\\'|[^'\r\n])*		{
	fprintf(errorfile, "Error at Line %d: Unterminated character %s\n\n", line_count, yytext);
	fprintf(logfile, "Error at Line %d: Unterminated character %s\n\n", line_count, yytext);
	error_count++;
}

\'\'			{
	fprintf(errorfile, "Error at Line %d: Empty character constant error %s\n\n", line_count, yytext);
	fprintf(logfile, "Error at Line %d: Empty character constant error %s\n\n", line_count, yytext);
	error_count++;
}

{UTSTRING}		{
	fprintf(errorfile, "Error at Line %d: Unterminated String %s\n\n", line_count, yytext);
	fprintf(logfile, "Error at Line %d: Unterminated String %s\n\n", line_count, yytext);
	error_count++;

	string token = yytext;
	for (int i = 0; i < token.size(); i++) {
		if (token[i] == '\n') line_count++;
	}
}

{UTCOMMENT}		{
	fprintf(errorfile, "Error at Line %d: Unterminated Comment %s\n\n", line_count, yytext);
	fprintf(logfile, "Error at Line %d: Unterminated Comment %s\n\n", line_count, yytext);
	error_count++;

	string token = yytext;
	for (int i = 0; i < token.size(); i++) {
		if (token[i] == '\n') line_count++;
	}
}


. 				{
	fprintf(errorfile, "Error at Line %d: Unrecognized character %s\n\n", line_count, yytext);
	fprintf(logfile, "Error at Line %d: Unrecognized character %s\n\n", line_count, yytext);
	error_count++;
}

<<EOF>>			{
	return 0;
}

%%
