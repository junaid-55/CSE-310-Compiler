lexer grammar C2105006Lexer;

@lexer::header {
    #pragma once
    #include <iostream>
    #include <fstream>
    #include <string>
    using namespace std;
    extern ofstream lexLogFile;
}

@lexer::members {
    void writeIntoLexLogFile(const string &message) {
        if (!lexLogFile.is_open()) {
            lexLogFile.open("lexLogFile.txt", ios::app);
            if (!lexLogFile) {
                cerr << "Error opening lexLogFile.txt" << endl;
                return;
            }
        }
        lexLogFile << message << endl;
        lexLogFile.flush();
    }
}

// ------------------------------
// 1) Comments (skipped + logged)
// ------------------------------

// Single-line comments: '//' then anything except newline
LINE_COMMENT
    : '//' ~[\r\n]* {
        writeIntoLexLogFile(
          "Line# " + to_string(getLine())
          + ": Token <SINGLE LINE COMMENT> Lexeme "
          + getText()
        );
    } -> skip
    ;

// Multi-line comments
BLOCK_COMMENT
  : '/*' ( . | '\r' | '\n' )*? '*/' {
      // extra braces create a new scope for your variables
      {
        string txt = getText();
        string content = txt.substr(2, txt.size() - 4);
        writeIntoLexLogFile(
          "Line# " + to_string(getLine())
          + ": Token <MULTI LINE COMMENT> Lexeme /*"
          + content + "*/"
        );
      }
    }
    -> skip
  ;


// ------------------------------
// 2) String literals (skipped + logged)
// ------------------------------

// A basic string rule with escape support :contentReference[oaicite:5]{index=5}
STRING
    : '"' ( '\\' . | ~["\\\r\n] )* '"' {
        writeIntoLexLogFile(
          "Line# " + to_string(getLine())
          + ": Token <STRING> Lexeme " + getText()
        );
    } -> skip
    ;

// ------------------------------
// 3) Whitespace & Newlines (skipped)
// ------------------------------

WS      : [ \t\f\r\n]+ -> skip ;

// ------------------------------
// 4) Keywords & Symbols
// ------------------------------

IF       : 'if' { writeIntoLexLogFile("Line# " + to_string(getLine()) + ": Token <IF> Lexeme " + getText()); };
ELSE     : 'else' { writeIntoLexLogFile("Line# " + to_string(getLine()) + ": Token <ELSE> Lexeme " + getText()); };
FOR      : 'for' { writeIntoLexLogFile("Line# " + to_string(getLine()) + ": Token <FOR> Lexeme " + getText()); };
WHILE    : 'while' { writeIntoLexLogFile("Line# " + to_string(getLine()) + ": Token <WHILE> Lexeme " + getText()); };
PRINTLN  : 'printf' { writeIntoLexLogFile("Line# " + to_string(getLine()) + ": Token <PRINTLN> Lexeme " + getText()); };
RETURN   : 'return' { writeIntoLexLogFile("Line# " + to_string(getLine()) + ": Token <RETURN> Lexeme " + getText()); };
INT      : 'int' { writeIntoLexLogFile("Line# " + to_string(getLine()) + ": Token <INT> Lexeme " + getText()); };
FLOAT    : 'float' { writeIntoLexLogFile("Line# " + to_string(getLine()) + ": Token <FLOAT> Lexeme " + getText()); };
VOID     : 'void' { writeIntoLexLogFile("Line# " + to_string(getLine()) + ": Token <VOID> Lexeme " + getText()); };

LPAREN   : '(' { writeIntoLexLogFile("Line# " + to_string(getLine()) + ": Token <LPAREN> Lexeme " + getText()); };
RPAREN   : ')' { writeIntoLexLogFile("Line# " + to_string(getLine()) + ": Token <RPAREN> Lexeme " + getText()); };
LCURL    : '{' { writeIntoLexLogFile("Line# " + to_string(getLine()) + ": Token <LCURL> Lexeme " + getText()); };
RCURL    : '}' { writeIntoLexLogFile("Line# " + to_string(getLine()) + ": Token <RCURL> Lexeme " + getText()); };
LTHIRD   : '[' { writeIntoLexLogFile("Line# " + to_string(getLine()) + ": Token <LTHIRD> Lexeme " + getText()); };
RTHIRD   : ']' { writeIntoLexLogFile("Line# " + to_string(getLine()) + ": Token <RTHIRD> Lexeme " + getText()); };
SEMICOLON: ';' { writeIntoLexLogFile("Line# " + to_string(getLine()) + ": Token <SEMICOLON> Lexeme " + getText()); };
COMMA    : ',' { writeIntoLexLogFile("Line# " + to_string(getLine()) + ": Token <COMMA> Lexeme " + getText()); };


ADDOP    : [+\-] { writeIntoLexLogFile("Line# " + to_string(getLine()) + ": Token <ADDOP> Lexeme " + getText()); };
SUBOP    : [+\-] { writeIntoLexLogFile("Line# " + to_string(getLine()) + ": Token <SUBOP> Lexeme " + getText()); };
MULOP    : [*/%] { writeIntoLexLogFile("Line# " + to_string(getLine()) + ": Token <MULOP> Lexeme " + getText()); };
INCOP    : '++' { writeIntoLexLogFile("Line# " + to_string(getLine()) + ": Token <INCOP> Lexeme " + getText()); };
DECOP    : '--' { writeIntoLexLogFile("Line# " + to_string(getLine()) + ": Token <DECOP> Lexeme " + getText()); };
NOT      : '!' { writeIntoLexLogFile("Line# " + to_string(getLine()) + ": Token <NOT> Lexeme " + getText()); };
RELOP    : '<=' | '==' | '>=' | '>' | '<' | '!=' { writeIntoLexLogFile("Line# " + to_string(getLine()) + ": Token <RELOP> Lexeme " + getText()); };
LOGICOP  : '&&' | '||' { writeIntoLexLogFile("Line# " + to_string(getLine()) + ": Token <LOGICOP> Lexeme " + getText()); };
ASSIGNOP : '=' { writeIntoLexLogFile("Line# " + to_string(getLine()) + ": Token <ASSIGNOP> Lexeme " + getText()); };

// ------------------------------
// 5) Identifiers & Numbers
// ------------------------------

ID         : [A-Za-z_] [A-Za-z0-9_]* { writeIntoLexLogFile("Line# " + to_string(getLine()) + ": Token <ID> Lexeme " + getText()); };
CONST_INT  : [0-9]+ { writeIntoLexLogFile("Line# " + to_string(getLine()) + ": Token <CONST_INT> Lexeme " + getText()); };
CONST_FLOAT
    : [0-9]+ ('.' [0-9]*)? ([Ee][+\-]? [0-9]+)? {
        writeIntoLexLogFile(
          "Line# " + to_string(getLine())
          + ": Token <CONST_FLOAT> Lexeme " + getText()
        );
    }
    | '.' [0-9]+ {
        writeIntoLexLogFile(
          "Line# " + to_string(getLine())
          + ": Token <CONST_FLOAT> Lexeme " + getText()
        );
    }
    | [0-9]+ '.' {
        writeIntoLexLogFile(
          "Line# " + to_string(getLine())
          + ": Token <CONST_FLOAT> Lexeme " + getText()
        );
    }
    ;
INVALID_CHAR :[#@$?~`] {
    writeIntoLexLogFile(
      "Line# " + to_string(getLine())
      + ": Token <INVALID CHAR> Lexeme " + getText()
    );
};