parser grammar C2105006Parser;

options {
    tokenVocab = C2105006Lexer;
}

@parser::header {
    #include <iostream>
    #include <fstream>
    #include <string>
    #include <cstdlib>
    #include "C2105006Lexer.h"
    #include "headers/return_data.hpp" 
    #include "headers/symbol_table.h"
    using namespace std;

    extern ofstream parserLogFile;
    extern ofstream errorFile;

    extern int syntaxErrorCount;
}

@parser::members {
    SymbolTable *st = new SymbolTable(7);
    string current_type = "";
    bool isSemiColonError = true;
    vector<ReturnData> args;
    ReturnData buffer;
    void writeIntoparserLogFile(const string message) {
        if (!parserLogFile) {
            cout << "Error opening parserLogFile.txt" << endl;
            return;
        }

        parserLogFile << message;
        parserLogFile.flush();
    }

    void writeIntoErrorFile(const string message) {
        if (!errorFile) {
            cout << "Error opening errorFile.txt" << endl;
            return;
        }
        errorFile << message;
        errorFile.flush();
    }

    vector<pair<string, string>> parseParameterList(const string& paramList) {
        vector<pair<string, string>> params;
        stringstream ss(paramList);
        string token;

        while (getline(ss, token, ',')) {
            size_t spacePos = token.find(' ');
            if (spacePos != string::npos) {
                string type = token.substr(0, spacePos);
                string name = token.substr(spacePos + 1);
                params.emplace_back(toUpperString(type), name);
            }
            else {
                params.emplace_back(toUpperString(token), "");
            }
        }
        return params;
    }

    vector<string> splitCommaSeparated(const string& input) {
        vector<string> tokens;
        stringstream ss(input);
        string token;

        while (getline(ss, token, ',')) {
            tokens.push_back(token);
        }

        return tokens;
    }

    string toUpperString(string type){
        for (auto &c : type)
            c = toupper(c);
        return type;
    }
}

start
    : program
    ;

program
    : program unit
    | unit
    ;

unit
    : var_declaration
    | func_declaration
    | func_definition
    ;

var_declaration
    : type_specifier declaration_list SEMICOLON
    ;

type_specifier
    : INT
    | FLOAT
    | VOID
    ;

declaration_list
    : declaration_list COMMA ID
    | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
    | ID
    | ID LTHIRD CONST_INT RTHIRD
    ;

func_declaration
    : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
    | type_specifier ID LPAREN RPAREN SEMICOLON
    ;

func_definition
    : type_specifier ID LPAREN parameter_list RPAREN
      compound_statement
    | type_specifier ID LPAREN RPAREN
      compound_statement
    ;

parameter_list
    : parameter_list COMMA type_specifier ID
    | parameter_list COMMA type_specifier
    | type_specifier ID
    | type_specifier
    ;

compound_statement
    : LCURL statements RCURL
    | LCURL RCURL
    ;

statements
    : statement
    | statements statement
    ;

statement
    : var_declaration
    | expression statement
    | compound_statement
    | FOR LPAREN expression statement expression_statement expression RPAREN statement
    | IF LPAREN expression RPAREN statement
    | IF LPAREN expression RPAREN statement ELSE statement
    | WHILE LPAREN expression RPAREN statement
    | PRINTLN LPAREN ID RPAREN SEMICOLON
    | RETURN expression SEMICOLON
    ;

expression_statement
    : SEMICOLON
    | expression SEMICOLON
    ;

expression
    : logic_expression
    | variable ASSIGNOP logic_expression
    ;

logic_expression
    : rel_expression
    | rel_expression LOGICOP rel_expression
    ;

rel_expression
    : simple_expression
    | simple_expression RELOP simple_expression
    ;

simple_expression
    : term
    | simple_expression ADDOP term
    ;

term
    : unary_expression
    | term MULOP unary_expression
    ;

unary_expression
    : ADDOP unary_expression
    | NOT unary_expression
    | factor
    ;

factor
    : variable
    | ID LPAREN argument_list RPAREN
    | LPAREN expression RPAREN
    | CONST_INT
    | CONST_FLOAT
    | variable INCOP
    | variable DECOP
    ;

variable
    : ID
    | ID LTHIRD expression RTHIRD
    ;

argument_list
    : arguments
    | /* empty */
    ;

arguments
    : arguments COMMA logic_expression
    | logic_expression
    ;