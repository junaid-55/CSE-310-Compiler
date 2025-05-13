%option noyywrap

%{
    
#include<bits/stdc++.h>
#include <string>
#include <fstream>
#include <iostream>
#include "headers/2105006_symbol_table.hpp"
using namespace std;
	int line_count=1;
	int error_count = 0;

	string char_str,str;
	ofstream logout;
	ofstream tokenout;


    int n = 7;
    string hash_function = "SDBM";
    SymbolTable *table = new SymbolTable(n, hash_function);

	string to_upper(string str) {
		for (char& c : str) {
			c = toupper(c);
		}
		return str;
	}
%}

%x CHAR_STATE
%x STRING_STATE
%x SINGLE_LINE_COMMENT_STATE
%x MULTI_LINE_COMMENT_STATE

WHITESPACE [ \t\f\r\v]+ 
LETTER [a-zA-Z]
DIGIT [0-9]

INT {DIGIT}+
DOTTED_NUMBER {DIGIT}*(\.{DIGIT}*)+
MULTI_DOT_NUMBER {DIGIT}*(\.{DIGIT}*){2,}

EXPONENT    [eE][+-]?{INT}
DECIMAL_PART ({DIGIT}*\.?{INT})
FLOAT ({DECIMAL_PART}{EXPONENT}?)
INVALID_FLOAT {DECIMAL_PART}[eE][+-]?{DOTTED_NUMBER}

ESCAPE_CHAR  (\\([abfnrtv0'"\\])) 
CHARACTER_LITERAL ({LETTER}|{ESCAPE_CHAR})
NEWLINE \n
ALPHANUMERIC ({LETTER}|{DIGIT})


ADDOP [\+\-]
MULOP [\*\/\%]
INCOP ((\+\+)|(\-\-))
RELOP (([<>]=?)|(!=|==))
ASSIGNOP [=]
LOGICOP ((\&\&)|(\|\|))
NOT [!]
LPAREN [\(]
RPAREN [\)]
LCURL [{]
RCURL [}]
LTHIRD [\[]
RTHIRD [\]]
COMMA [,]
SEMICOLON [;]

KEYWORD (if|else|goto|long|short|static|unsigned|while|break|char|double|return|case|continue|for|do|int|float|void|switch|defaul)

IDENTIFIER (({LETTER}|_)+(({LETTER}|_)|{DIGIT})*)
INVALID_IDENTIFIER {DIGIT}+{IDENTIFIER}


%%
{WHITESPACE} {}
{NEWLINE} {line_count++;}

{KEYWORD} {
			str.assign(yytext, yyleng);
            tokenout << "<" << to_upper(str) << "> ";
            logout << "Line no " << line_count << ": TOKEN <" << to_upper(yytext) << "> Lexeme " << yytext << " found\n";
        }

{INT} {
            tokenout << "<CONST_INT," << yytext << "> ";
            logout << "Line no " << line_count << ": TOKEN <CONST_INT> Lexeme " << yytext << " found\n";
}


{FLOAT} {
            tokenout << "<CONST_FLOAT," << yytext << "> ";
            logout << "Line no " << line_count << ": TOKEN <CONST_FLOAT> Lexeme " << yytext << " found\n";
}

{MULTI_DOT_NUMBER} {
            logout << "Error at line no " << line_count << ": Too many decimal points " << yytext << "\n";
}

{INVALID_FLOAT} {
            logout << "Error at line no " << line_count << ": Ill formed number " << yytext << "\n";
}

{IDENTIFIER} {
            tokenout << "<ID," << yytext << "> ";
            logout << "Line no " << line_count << ": TOKEN <ID> Lexeme " << yytext << " found\n";
}	

{INVALID_IDENTIFIER} {
            error_count++;
            logout << "Error at line no " << line_count << ": Invalid prefix on ID or invalid suffix on Number " << yytext << "\n";
}	

\" {
    str.clear();
    BEGIN STRING_STATE;
}

<STRING_STATE>{LETTER} {
    str.push_back(yytext[0]);
    cout << str << endl;
}

<STRING_STATE>\" {
    cout << str << endl;
    BEGIN(INITIAL);
}

' 	{
            char_str.clear();
            BEGIN CHAR_STATE;
}

<CHAR_STATE>{ESCAPE_CHAR}"'" {
            char_str.assign(yytext, yyleng - 1);
            cout << "DEBUG: ESCAPE_CHAR content: " << char_str << endl;
            char c;
            switch (char_str[1]){
                case 'a': c = '\a'; break;
                case 'b': c = '\b'; break;
                case 'f': c = '\f'; break;
                case 'n': c = '\n'; break;
                case 'r': c = '\r'; break;
                case 't': c = '\t'; break;
                case 'v': c = '\v'; break;
                case '\\': c = '\\'; break;
                case '\'': c = '\''; break;
                case '"': c = '\"'; break;
                case '0': c = '\0'; break;
            }
            tokenout << "<CONST_CHAR, " << c << "> ";
            logout << "Line no " << line_count << ": TOKEN <CONST_CHAR> Lexeme '" << char_str << "' found\n";
            BEGIN INITIAL;
}

<CHAR_STATE>{ALPHANUMERIC}"'" {
            char_str.assign(yytext, yyleng - 1);
            cout << "DEBUG: ALPHANUMERIC content: " << char_str << endl;
            tokenout << "<CONST_CHAR, " << char_str[0] << "> ";
            logout << "Line no " << line_count << ": TOKEN <CONST_CHAR> Lexeme '" << char_str << "' found\n";
            BEGIN INITIAL;
}


<CHAR_STATE>"'" {
        error_count++;
        logout << "Error at line no " << line_count << ": Empty character constant error ''\n";
        BEGIN INITIAL;
            
}

<CHAR_STATE>[^'\n]*"'" { 
        char_str.assign(yytext, yyleng - 1);
		error_count++;
        // cout << "CHARACTER: " << char_str << endl; 
        logout << "Error at line no " << line_count << ": Multi-character constant error '" << char_str << "'\n";
        BEGIN(INITIAL);
}


<CHAR_STATE>({ESCAPE_CHAR}|([^'\n]*)){NEWLINE} {
        // cout << "DEBUG: Error line " << line_count << ": Unterminated character content before newline: '" << char_str << "'\n";
        error_count++;
		line_count++;
        char_str.assign(yytext, yyleng-1);
        logout << "Error at line no " << line_count << ": Unterminated character '" << char_str << "\n";
        BEGIN(INITIAL);
}

<CHAR_STATE><<EOF>> {
        error_count++;
		char_str.assign(yytext,yyleng);
        logout << "Error at line no " << line_count << ": Unterminated character  '" << char_str << "', EOF encountered.\n";
        BEGIN(INITIAL);
}


{LOGICOP} {
            tokenout << "<LOGICOP, " << yytext << "> ";
            logout << "Line no " << line_count << ": TOKEN <LOGICOP> Lexeme " << yytext << " found\n";
}
{RELOP} {
            tokenout << "<RELOP, " << yytext << "> ";
            logout << "Line no " << line_count << ": TOKEN <RELOP> Lexeme " << yytext << " found\n";
}

{INCOP} {
            tokenout << "<INCOP, " << yytext << "> ";
            logout << "Line no " << line_count << ": TOKEN <INCOP> Lexeme " << yytext << " found\n";
}

{ADDOP} {
            tokenout << "<ADDOP, " << yytext << "> ";
            logout << "Line no " << line_count << ": TOKEN <ADDOP> Lexeme " << yytext << " found\n";
}
{MULOP} {
            tokenout << "<MULOP, " << yytext << "> ";
            logout << "Line no " << line_count << ": TOKEN <MULOP> Lexeme " << yytext << " found\n";
}
{ASSIGNOP} {
            tokenout << "<ASSIGNOP, " << yytext << "> ";
            logout << "Line no " << line_count << ": TOKEN <ASSIGNOP> Lexeme " << yytext << " found\n";
}
{NOT} {
            tokenout << "<NOT, " << yytext << "> ";
            logout << "Line no " << line_count << ": TOKEN <NOT> Lexeme " << yytext << " found\n";
}
{LPAREN} {
            tokenout << "<LPAREN, " << yytext << "> ";
            logout << "Line no " << line_count << ": TOKEN <LPAREN> Lexeme " << yytext << " found\n";
}
{RPAREN} {
            tokenout << "<RPAREN, " << yytext << "> ";
            logout << "Line no " << line_count << ": TOKEN <RPAREN> Lexeme " << yytext << " found\n";
}
{LCURL} {
            tokenout << "<LCURL, " << yytext << "> ";
            logout << "Line no " << line_count << ": TOKEN <LCURL> Lexeme " << yytext << " found\n";
}
{RCURL} {
            tokenout << "<RCURL, " << yytext << "> ";
            logout << "Line no " << line_count << ": TOKEN <RCURL> Lexeme " << yytext << " found\n";
}
{LTHIRD} {
            tokenout << "<LTHIRD, " << yytext << "> ";
            logout << "Line no " << line_count << ": TOKEN <LTHIRD> Lexeme " << yytext << " found\n";
}
{RTHIRD} {
            tokenout << "<RTHIRD, " << yytext << "> ";
            logout << "Line no " << line_count << ": TOKEN <RTHIRD> Lexeme " << yytext << " found\n";
}
{COMMA} {
            tokenout << "<COMMA, " << yytext << "> ";
            logout << "Line no " << line_count << ": TOKEN <COMMA> Lexeme " << yytext << " found\n";
}
{SEMICOLON} {
            tokenout << "<SEMICOLON, " << yytext << "> ";
            logout << "Line no " << line_count << ": TOKEN <SEMICOLON> Lexeme " << yytext << " found\n";
}

            

%%

int main(int argc, char *argv[]) {
    
    if(argc != 2) {
        cout << "Please provide input file name and try again" << endl;
        return 0;
    }
    
    ifstream fin(argv[1]);
    if(!fin.is_open()) {
        cout << "Cannot open specified file" << endl;
        return 0;
    }
    
    logout.open("log.txt");
    tokenout.open("token.txt");

    FILE* yyin_file = fopen(argv[1], "r");
    yyin = yyin_file;
    
    yylex();
    
    if(yyin_file) fclose(yyin_file);
    logout.close();
    tokenout.close();
    fin.close();
    
    return 0;
}