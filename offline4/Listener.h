#ifndef MY_ASM_LISTENER_H
#define MY_ASM_LISTENER_H

#include "C2105006Parser.h"
#include "C2105006ParserBaseListener.h"
#include <iostream>
#include <string>
#include <fstream>
using namespace std;
class MyASMListener : public C2105006ParserBaseListener {
private:
    ofstream asmFile;

public:
    MyASMListener() {
        asmFile.open("output/code.asm");
        if (asmFile.is_open()) {
            asmFile << ".MODEL SMALL" << endl;
            asmFile << ".STACK 100H" << endl;
            asmFile << ".DATA" << endl;
        }
    }

    ~MyASMListener() {
        if (asmFile.is_open()) {
            asmFile << "END MAIN" << endl;
            asmFile.close();
        }
    }

    void exitVar_declaration(C2105006Parser::Var_declarationContext *ctx) override {
        string type = ctx->type_specifier()->getText();
        
        if (asmFile.is_open()) {
            asmFile << "; Declaring variables of type " << type << endl;
            
            auto decls = ctx->declaration_list();
            
            // Simple approach - get all IDs from declaration_list
            string declText = decls->getText();
            
            // For now, just declare each variable
            if (type == "int") {
                asmFile << "    " << declText << " DW ?" << endl;
            } else if (type == "float") {
                asmFile << "    " << declText << " DD ?" << endl;
            }
        }
    }

    void enterFunc_definition(C2105006Parser::Func_definitionContext *ctx) override {
        string funcName = ctx->ID()->getText();
        
        if (asmFile.is_open()) {
            if (funcName == "main") {
                asmFile << ".CODE" << endl;
                asmFile << "MAIN PROC" << endl;
                asmFile << "    MOV AX, @DATA" << endl;
                asmFile << "    MOV DS, AX" << endl;
            } else {
                asmFile << funcName << " PROC" << endl;
            }
        }
    }

    void exitFunc_definition(C2105006Parser::Func_definitionContext *ctx) override {
        string funcName = ctx->ID()->getText();
        
        if (asmFile.is_open()) {
            if (funcName == "main") {
                asmFile << "    MOV AH, 4CH" << endl;
                asmFile << "    INT 21H" << endl;
                asmFile << "MAIN ENDP" << endl;
            } else {
                asmFile << "    RET" << endl;
                asmFile << funcName << " ENDP" << endl;
            }
        }
    }
};

#endif