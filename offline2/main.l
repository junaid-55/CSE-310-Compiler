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
    int temp_line_count = 0;

	string char_str,str,temp_str;
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

    string get_escaped_char(char c) {
        switch(c){
            case 'a': return "\a";
            case 'b': return "\b";
            case 'f': return "\f";
            case 'n': return "\n";
            case 'r': return "\r";
            case 't': return "\t";
            case 'v': return "\v";
            case '\\': return "\\";
            case '\'': return "'";
            case '"': return "\"";
            case '0': return "\0";
        }
        return "";
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
VALID_CHAR ({ESCAPE_CHAR}|{ALPHANUMERIC})

KEYWORD (if|else|goto|long|short|static|unsigned|while|break|char|double|return|case|continue|for|do|int|float|void|switch|defaul)

IDENTIFIER (({LETTER}|_)+(({LETTER}|_)|{DIGIT})*)
INVALID_IDENTIFIER (({INT}|{FLOAT}){IDENTIFIER})

UNRECOGNIZED_LETTER [^a-zA-Z0-9_\\\'\"\.\n\r\t\f\v]

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




%%
{WHITESPACE} {}
{NEWLINE} {line_count++;}

{KEYWORD} {
        
			str.assign(yytext, yyleng);
            tokenout << "<" << to_upper(str) << "> ";
            logout << "Line no " << line_count << ": Token <" << to_upper(yytext) << "> Lexeme " << yytext << " found\n\n";
        }

{INT} {
            str.assign(yytext, yyleng);
            tokenout << "<CONST_INT, " << yytext << "> ";
            logout << "Line no " << line_count << ": Token <CONST_INT> Lexeme " << yytext << " found\n\n";
            if(table->insert(str,"CONST_INT",logout)){
                table->print_all_scope(logout);
                logout<<endl;
            }
}


{FLOAT} {
            str.assign(yytext, yyleng);
            tokenout << "<CONST_FLOAT, " << str << "> ";
            logout << "Line no " << line_count << ": Token <CONST_FLOAT> Lexeme " << str << " found\n\n";
            if(table->insert(str,"CONST_FLOAT",logout)){
                table->print_all_scope(logout);
                logout<<endl;
            }
}

{MULTI_DOT_NUMBER} {
            logout << "Error at line no " << line_count << ": Too many decimal points " << yytext << "\n\n";
            error_count++;
}

{INVALID_FLOAT} {
            logout << "Error at line no " << line_count << ": Ill formed number " << yytext << "\n\n";
            error_count++;
}

{IDENTIFIER} {
            str.assign(yytext, yyleng);
            tokenout << "<ID, " << yytext << "> ";
            logout << "Line no " << line_count << ": Token <ID> Lexeme " << yytext << " found\n\n";
            if(table->insert(str,"ID",logout)){
                table->print_all_scope(logout);
                logout<<endl;
            }
}	

{INVALID_IDENTIFIER} {
            error_count++;
            logout << "Error at line no " << line_count << ": Invalid prefix on ID or invalid suffix on Number " << yytext << "\n\n";
}	

"//" {
    str.clear();
    BEGIN SINGLE_LINE_COMMENT_STATE;
}

<SINGLE_LINE_COMMENT_STATE>[^\\\n]+ {
    str.append(yytext);
}

<SINGLE_LINE_COMMENT_STATE>\\[^\n] {
    str.append(yytext);
}

<SINGLE_LINE_COMMENT_STATE>\\\n {
    line_count++;
    str.append("\\\n");
}

<SINGLE_LINE_COMMENT_STATE>\n {
    logout << "Line no " << line_count << ": Token <COMMENT> Lexeme //" << str << " found\n\n";
    line_count++;
    str.clear();
    BEGIN INITIAL;
}
<SINGLE_LINE_COMMENT_STATE><<EOF>> {
    logout << "Line no " << line_count << ": Token <COMMENT> Lexeme //" << str << " found\n\n";
    BEGIN(INITIAL);
}

"/*" {
    str.clear();
    temp_line_count=0;
    BEGIN MULTI_LINE_COMMENT_STATE;
}

<MULTI_LINE_COMMENT_STATE>"*/" {
    line_count += temp_line_count;
    logout << "Line no " << line_count << ": Token <COMMENT> Lexeme /*" << str << "*/ found\n\n";
    BEGIN INITIAL;
}

<MULTI_LINE_COMMENT_STATE>[^*\n]+ {
    str.append(yytext);
}

<MULTI_LINE_COMMENT_STATE>"*"+[^*/\n]+ {
    // this part is to handle comment parts like *****/
    // [^*/\n] -> if  ^* is not  included then "*"+ will consume all *
    // comment ending impossible
    str.append(yytext);
}

<MULTI_LINE_COMMENT_STATE>\n {
    str.append("\n");
    temp_line_count++;
}

<MULTI_LINE_COMMENT_STATE><<EOF>> {
    error_count++;
    logout << "Error at line no " << line_count << ": Unterminated comment /*" << str << "\n\n";
    line_count += temp_line_count;
    BEGIN INITIAL;
}


\" {
    str.clear();
    temp_str.clear();
    temp_line_count=0;
    BEGIN STRING_STATE;
}

<STRING_STATE>\" {
    line_count += temp_line_count;
    tokenout << "<STRING, " << str << "> ";
    logout << "Line no " << line_count << ": Token <STRING> Lexeme \"" << temp_str << "\" found --> <STRING, "<<str<<">\n\n";
    BEGIN(INITIAL);
}

<STRING_STATE>[^\\\n\"]* {
    str.append(yytext);
    temp_str.append(yytext);
}

<STRING_STATE>\\[^\n] {
    string c = get_escaped_char(yytext[1]);
    str.append(c);
    temp_str.append(yytext);
}

<STRING_STATE>\\\n {
    temp_line_count++;
    temp_str.append(yytext);
}

<STRING_STATE>\n {
    str.append(yytext);
    logout << "Error at line no " << line_count << ": Unterminated string \"" << temp_str << "\n\n";
    line_count += temp_line_count + 1 ;
    error_count++;
    BEGIN(INITIAL);
}

<STRING_STATE><<EOF>> {
    error_count++;
    line_count += temp_line_count;
    logout << "Error at line no " << line_count << ": Unterminated string \"" << temp_str << "\n\n";
    BEGIN(INITIAL);
}

' 	{
            char_str.clear();
            BEGIN CHAR_STATE;
}

<CHAR_STATE>{ESCAPE_CHAR}"'" {
            char_str.assign(yytext, yyleng - 1);
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
            logout << "Line no " << line_count << ": Token <CONST_CHAR> Lexeme '" << char_str << "' found --> <CONST_CHAR, "<<c<<">\n\n";
            char_str = "'" + char_str+"'";
            if(table->insert(char_str,"CONST_CHAR",logout))
            table->print_all_scope(logout);
            logout<<endl;
            BEGIN INITIAL;
}

<CHAR_STATE>{ALPHANUMERIC}"'" {
            char_str.assign(yytext, yyleng - 1);
            tokenout << "<CONST_CHAR, " << char_str[0] << "> ";
            logout << "Line no " << line_count << ": Token <CONST_CHAR> Lexeme '" << char_str << "' found --> <CONST_CHAR, "<<char_str[0]<<">\n\n";
            char_str = "'" + char_str+"'";
            if(table->insert(char_str,"CONST_CHAR",logout)){
                table->print_all_scope(logout);
                logout<<endl;
            }
            BEGIN INITIAL;
}

<CHAR_STATE>"'" {
        error_count++;
        logout << "Error at line no " << line_count << ": Empty character constant error ''\n\n";
        BEGIN INITIAL;
}

<CHAR_STATE>({ESCAPE_CHAR}|([^'\n]*)){NEWLINE} {
        error_count++;
        char_str.assign(yytext, yyleng);
        logout << "Error at line no " << line_count << ": Unterminated character '" << char_str << "\n\n";
        line_count++;
        BEGIN(INITIAL);
}

<CHAR_STATE>[^'\n]"'" { 
        char_str.assign(yytext, yyleng - 1);
        logout << "Error at line no " << line_count << ": Unrecognized character constant error '" << char_str << "'\n\n";
		error_count++;
        BEGIN(INITIAL);
}

<CHAR_STATE>[^'\n]{2,}"'" { 
        char_str.assign(yytext, yyleng - 1);
		error_count++;
        logout << "Error at line no " << line_count << ": Multi character constant error '" << char_str << "'\n\n";
        BEGIN(INITIAL);
}

<CHAR_STATE><<EOF>> {
		char_str.assign(yytext,yyleng);
        logout << "Error at line no " << line_count << ": Unterminated character  '" << char_str << "', EOF encountered.\n\n";
        BEGIN(INITIAL);
}

{LOGICOP} {
            tokenout << "<LOGICOP, " << yytext << "> ";
            logout << "Line no " << line_count << ": Token <LOGICOP> Lexeme " << yytext << " found\n\n";
}
{RELOP} {
            tokenout << "<RELOP, " << yytext << "> ";
            logout << "Line no " << line_count << ": Token <RELOP> Lexeme " << yytext << " found\n\n";
}

{INCOP} {
            tokenout << "<INCOP, " << yytext << "> ";
            logout << "Line no " << line_count << ": Token <INCOP> Lexeme " << yytext << " found\n\n";
}

{ADDOP} {
            tokenout << "<ADDOP, " << yytext << "> ";
            logout << "Line no " << line_count << ": Token <ADDOP> Lexeme " << yytext << " found\n\n";
}
{MULOP} {
            tokenout << "<MULOP, " << yytext << "> ";
            logout << "Line no " << line_count << ": Token <MULOP> Lexeme " << yytext << " found\n\n";
}
{ASSIGNOP} {
            tokenout << "<ASSIGNOP, " << yytext << "> ";
            logout << "Line no " << line_count << ": Token <ASSIGNOP> Lexeme " << yytext << " found\n\n";
}
{NOT} {
            tokenout << "<NOT, " << yytext << "> ";
            logout << "Line no " << line_count << ": Token <NOT> Lexeme " << yytext << " found\n\n";
}
{LPAREN} {
            tokenout << "<LPAREN, " << yytext << "> ";
            logout << "Line no " << line_count << ": Token <LPAREN> Lexeme " << yytext << " found\n\n";
}
{RPAREN} {
            tokenout << "<RPAREN, " << yytext << "> ";
            logout << "Line no " << line_count << ": Token <RPAREN> Lexeme " << yytext << " found\n\n";
}
{LCURL} {
            table->enter_scope();
            tokenout << "<LCURL, " << yytext << "> ";
            logout << "Line no " << line_count << ": Token <LCURL> Lexeme " << yytext << " found\n\n";
}
{RCURL} {
            table->exit_scope();
            tokenout << "<RCURL, " << yytext << "> ";
            logout << "Line no " << line_count << ": Token <RCURL> Lexeme " << yytext << " found\n\n";
}
{LTHIRD} {
            tokenout << "<LTHIRD, " << yytext << "> ";
            logout << "Line no " << line_count << ": Token <LTHIRD> Lexeme " << yytext << " found\n\n";
}
{RTHIRD} {
            tokenout << "<RTHIRD, " << yytext << "> ";
            logout << "Line no " << line_count << ": Token <RTHIRD> Lexeme " << yytext << " found\n\n";
}
{COMMA} {
            tokenout << "<COMMA, " << yytext << "> ";
            logout << "Line no " << line_count << ": Token <COMMA> Lexeme " << yytext << " found\n\n";
}
{SEMICOLON} {
            tokenout << "<SEMICOLON, " << yytext << "> ";
            logout << "Line no " << line_count << ": Token <SEMICOLON> Lexeme " << yytext << " found\n\n";
}

{UNRECOGNIZED_LETTER} {
            error_count++;
            logout << "Error at line no " << line_count << ": Unrecognized character " << yytext << "\n\n";
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
    tokenout.open("Token.txt");

    FILE* yyin_file = fopen(argv[1], "r");
    yyin = yyin_file;
    yylex();
    table->print_all_scope(logout);
    logout<<endl;
    logout<<"Total lines: "<<line_count<<"\nTotal errors: "<<error_count<<endl;
    if(yyin_file) fclose(yyin_file);
    logout.close();
    tokenout.close();
    fin.close();
    
    return 0;
}