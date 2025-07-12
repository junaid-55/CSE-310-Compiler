parser grammar C2105006Parser;

options {
    tokenVocab = C2105006Lexer;
}

@parser::header {
    #include <iostream>
    #include <fstream>
    #include <string>
    #include <cstdlib>
    #include <map>
    #include "C2105006Lexer.h"
    #include "headers/return_data.hpp" 
    #include "headers/symbol_table.h"
    #include "headers/Label.h"
    using namespace std;

    extern ofstream parserLogFile;
    extern ofstream errorFile;
    extern ofstream asmFile;

    extern int syntaxErrorCount;
}

@parser::members {
    SymbolTable *st = new SymbolTable(7);
    Label *label = new Label();
    vector<int> patches;
    string current_type = "";
    vector<string> data,code;
    struct ExpressionResult {
        vector<int> truelist; 
        vector<int> falselist;
        vector<int> nextlist;
    };

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

    void writeIntoAsmFile(const string message) {
        if (!asmFile) {
            cout << "Error opening asmFile.txt" << endl;
            return;
        }
        asmFile << message;
        asmFile.flush();
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

    void initializeUtilityProcedures() {
        vector<string> utilities = {
            "new_line proc\n",
            "\tpush ax\n",
            "\tpush dx\n",
            "\tmov ah,2\n",
            "\tmov dl,0Dh\n",
            "\tint 21h\n",
            "\tmov ah,2\n",
            "\tmov dl,0Ah\n",
            "\tint 21h\n",
            "\tpop dx\n",
            "\tpop ax\n",
            "\tret\n",
            "new_line endp\n",
            "\n",
            "print_output proc  ;print what is in ax\n",
            "\tpush ax\n",
            "\tpush bx\n",
            "\tpush cx\n",
            "\tpush dx\n",
            "\tpush si\n",
            "\tlea si,number\n",
            "\tmov bx,10\n",
            "\tadd si,4\n",
            "\tcmp ax,0\n",
            "\tjge print\n",          // Changed from jnge to jge
            "\tpush ax\n",            // Handle negative numbers
            "\tmov ah,2\n",
            "\tmov dl,'-'\n",
            "\tint 21h\n",
            "\tpop ax\n",
            "\tneg ax\n",
            "print:\n",
            "\txor dx,dx\n",
            "\tdiv bx\n",
            "\tmov [si],dl\n",
            "\tadd [si],'0'\n",
            "\tdec si\n",
            "\tcmp ax,0\n",
            "\tjne print\n",
            "\tinc si\n",
            "\tlea dx,si\n",
            "\tmov ah,9\n",
            "\tint 21h\n",
            "\tpop si\n",
            "\tpop dx\n",
            "\tpop cx\n",
            "\tpop bx\n",
            "\tpop ax\n",
            "\tret\n",
            "print_output endp\n",
            "\n"
        };
        
        for(const auto& line : utilities) {
            code.push_back(line);
        }
    }
    void backpatch(vector<int>& list, const string& label) {
        for (int index : list) {
            size_t pos = code[index].find("PLACEHOLDER");
            if (pos != string::npos) {
                code[index].replace(pos, 11, label);
            }
        }
    }
    
    vector<int> makelist(int index) {
        return vector<int>{index};
    }
    
    vector<int> merge(const vector<int>& list1, const vector<int>& list2) {
        vector<int> result = list1;
        result.insert(result.end(), list2.begin(), list2.end());
        return result;
    }
}
start
    :{
        writeIntoAsmFile(".MODEL SMALL\n");
        writeIntoAsmFile(".STACK 100H\n");
        writeIntoAsmFile(".DATA\n");
        data.push_back("\tnumber DB \"00000$\"\n");
    }
     program {
        st->print_all_scope();
        initializeUtilityProcedures();
        for(auto &d : data) {
            writeIntoAsmFile(d);
        }
        writeIntoAsmFile(".CODE\n");
        for(auto &c : code) {
            writeIntoAsmFile(c);
        }
        writeIntoAsmFile("END MAIN\n");
        cout<< "Parsing completed successfully." << endl;
    }
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
    : INT { current_type = "INT"; }
    | FLOAT { current_type = "FLOAT"; }
    | VOID  { current_type = "VOID"; }
    ;

declaration_list
    : declaration_list COMMA ID {
        st->insert($ID->getText(), toUpperString(current_type));
        if(st->get_current_scope_id() == "1") {
            data.push_back($ID->getText() + " DW 0\n");
        } else{
            code.push_back("\tSUB SP, 2\n");
        }
    }
    | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
        st->insert($ID->getText(), toUpperString(current_type), true, false, true, stod($CONST_INT->getText()));
    }
    | ID {
        st->insert($ID->getText(), toUpperString(current_type));
        if(st->get_current_scope_id() == "1") {
            data.push_back($ID->getText() + " DW 0\n");
        } else{
            code.push_back("SUB SP, 2\n");
        }
    }
    | ID LTHIRD CONST_INT RTHIRD {
        st->insert($ID->getText(), toUpperString(current_type), true, false, true, stod($CONST_INT->getText()));
    }
    ;

func_declaration
    : type_specifier ID LPAREN {st->enter_scope();} parameter_list RPAREN SEMICOLON {
        st->exit_scope();
        string func_data = $type_specifier.text + " " + $ID->getText() + "(" + ($parameter_list.ctx ? $parameter_list.text : "") + ")";
        st->insert(func_data, "FUNCTION", true, false);
    }
    | type_specifier ID LPAREN {st->enter_scope();} RPAREN SEMICOLON {
        st->exit_scope();
        string func_data = $type_specifier.text + " " + $ID->getText() + "()";
        st->insert(func_data, "FUNCTION", true, false);
    }
    ;

func_definition
    : type_specifier ID LPAREN {st->enter_scope();} parameter_list RPAREN {
        string func_data = $type_specifier.text + " " + $ID->getText() + "(" + ($parameter_list.ctx ? $parameter_list.text : "") + ")";
        st->insertInParentScope(func_data, "FUNCTION", false, true);
        code.push_back($ID->getText() + " PROC\n");
        if($ID->getText() == "main") {
            code.push_back("\tMOV AX, @DATA)\n");
            code.push_back("\tMOV DS, AX\n");
        }
        code.push_back("\tPUSH BP\n");
        code.push_back("\tMOV BP, SP\n");
    } compound_statement[true]{
        if($ID->getText() == "main") {
            code.push_back("\tMOV AX, 4C00H\n");
            code.push_back("\tINT 21H\n");
        }
        code.push_back($ID->getText() + " ENDP\n");
        // if($ID->getText() == "main") {
        //     code.push_back("END main\n");
        // }
    }
    | type_specifier ID LPAREN {st->enter_scope();} RPAREN {
        string func_data = $type_specifier.text + " " + $ID->getText() + "()";
        st->insertInParentScope(func_data, "FUNCTION", false, true);
        code.push_back($ID->getText() + " PROC\n");
        if($ID->getText() == "main") {
            code.push_back("\tMOV AX, @DATA\n");
            code.push_back("\tMOV DS, AX\n");
        }
        code.push_back("\tPUSH BP\n");
        code.push_back("\tMOV BP, SP\n");
    } compound_statement[true]{
        if($ID->getText() == "main") {
            code.push_back("\tMOV AX, 4C00H\n");
            code.push_back("\tINT 21H\n");
        }
        code.push_back($ID->getText() + " ENDP\n");
        // if($ID->getText() == "main") {
        //     code.push_back("END main\n");
        // } 
        st->exit_scope();
    }
    ;

parameter_list
    : parameter_list COMMA type_specifier ID {
        st->insert($ID->getText(), toUpperString($type_specifier.text));
    }
    | parameter_list COMMA type_specifier
    | type_specifier ID {
        st->insert($ID->getText(), toUpperString($type_specifier.text));
    }
    | type_specifier
    ;

compound_statement[bool isFunction]
    : LCURL {
        if (!isFunction) 
            st->enter_scope();
    } statements RCURL {
        if (isFunction) {
            st->print_all_scope();
        }
        if (!isFunction) {
            st->exit_scope();
        }
    }
    | LCURL {
        if (!isFunction)
            st->enter_scope();
    } RCURL {
        if (isFunction) {
            st->print_all_scope();
        }
        if (!isFunction) {
            st->exit_scope();
        }
    }
    ;

statements
    : printLabel statement
    | statements printLabel statement
    ;

statement
    : var_declaration
    | expression_statement
    | compound_statement[false]
    | FOR LPAREN expression_statement expression_statement expression RPAREN statement
    | IF LPAREN expression RPAREN {
        code.push_back("\tPOP AX\n");
        code.push_back("\tCMP AX, 0\n");
        code.push_back("\tJE PLACEHOLDER\n");  // Jump to end if FALSE
        patches.push_back(code.size()-1);
    } statement {
        string endLabel = label->getNextLabel();
        code.push_back(endLabel + ":\n");
        if (!patches.empty()) {
            int patchPos = patches.back();
            patches.pop_back();
            code[patchPos] = "\tJE " + endLabel + "\n";  
        }
    } 
    | IF LPAREN expression RPAREN {
        code.push_back("\tPOP AX\n");
        code.push_back("\tCMP AX, 0\n");
        string elseLabel = label->getNextLabel();
        code.push_back("\tJE " + elseLabel + "\n");  // Jump to ELSE if FALSE
    } statement {
        string elseLabel = label->getSkippedLabel(1);
        string endLabel = label->getCurrentLabel();
        code.push_back("\tJMP " + endLabel + "\n");  // Jump over ELSE
        code.push_back(elseLabel + ":\n");
    } ELSE statement {
        string endLabel = label->getSkippedLabel(1);
        code.push_back(endLabel + ":\n");
    }
    
    | WHILE LPAREN expression RPAREN statement
    | PRINTLN LPAREN ID RPAREN SEMICOLON {
        auto sb = st->lookup($ID->getText()); 
        auto scope_id = st->get_scope_id(sb);
        if (scope_id == "1") {
            code.push_back("\tMOV AX, " + $ID->getText() + "\n");
        } else {
            code.push_back("\tMOV AX, [BP-" + to_string(sb->getStackOffset()) + "]\n");
        }
        code.push_back("\tCALL print_output\n");
        code.push_back("\tCALL new_line\n");
    }
    | RETURN expression SEMICOLON
    ;


expression_statement
    : SEMICOLON
    | expression SEMICOLON
    ;

variable returns [string text]
    : ID {
        auto sb = st->lookup($ID->getText());
        auto scope_id = st->get_scope_id(sb);
        if (scope_id == "1") {
            $text = $ID->getText();
        } else {
            $text = "[BP-" + to_string(sb->getStackOffset()) + "]";
        }
    }
    | ID LTHIRD expression RTHIRD
    ;

expression
    : logic_expression
    | var=variable ASSIGNOP logic_expression{
        code.push_back("\tPOP AX\n");
        code.push_back("\tMOV " + $variable.text + ", AX\n");
    }
    ;

logic_expression
    : rel_expression
    | left=rel_expression LOGICOP {
        code.push_back("\tPOP AX\n");      // Get left operand result
        code.push_back("\tCMP AX, 0\n");   
        
        string shortCircuitLabel = label->getNextLabel();  
        string endLabel = label->getNextLabel();          
        
        if ($LOGICOP->getText() == "&&") {
            // AND: if left is false, short-circuit to false
            code.push_back("\tJE " + shortCircuitLabel + "\n");
        } else if ($LOGICOP->getText() == "||") {
            // OR: if left is true, short-circuit to true
            code.push_back("\tJNE " + shortCircuitLabel + "\n");  
        }
    } right=rel_expression {
        // Normal evaluation: combine left and right
        code.push_back("\tPOP AX\n");      // Right operand result
        
        if ($LOGICOP->getText() == "&&") {
            // Both operands evaluated, AND logic
            code.push_back("\tCMP AX, 0\n");
            string falseLabel = label->getNextLabel();  // Create new label variable
            code.push_back("\tJE " + falseLabel + "\n");  
            code.push_back("\tPUSH 1\n");   // Both true, result = true
            code.push_back("\tJMP " + endLabel + "\n");
            
            // False case for AND normal evaluation
            code.push_back(falseLabel + ":\n");
            code.push_back("\tPUSH 0\n");
        } else if ($LOGICOP->getText() == "||") {
            // Left was false, right was evaluated
            code.push_back("\tCMP AX, 0\n");
            code.push_back("\tJE " + endLabel + "\n");   // If right is false, push 0
            code.push_back("\tPUSH 1\n");               // Right is true, push 1
        }
        
        code.push_back("\tJMP " + endLabel + "\n");
        
        // Short-circuit label (reuse the variable, don't redeclare)
        code.push_back(shortCircuitLabel + ":\n");
        if ($LOGICOP->getText() == "&&") {
            code.push_back("\tPUSH 0\n");   // AND short-circuit = false
        } else if ($LOGICOP->getText() == "||") {
            code.push_back("\tPUSH 1\n");   // OR short-circuit = true  
        }
        
        // End label
        code.push_back(endLabel + ":\n");
    }
    ;
rel_expression
    : simple_expression
    | simple_expression RELOP simple_expression{
        code.push_back("\tPOP BX\n");
        code.push_back("\tPOP AX\n");
        code.push_back("\tCMP AX, BX\n");

        if ($RELOP->getText() == "==") {
            code.push_back("\tJE " + label->getSkippedLabel(1) + "\n");
        } else if ($RELOP->getText() == "!=") {
            code.push_back("\tJNE " + label->getSkippedLabel(1) + "\n");
        } else if ($RELOP->getText() == "<") {
            code.push_back("\tJL " + label->getSkippedLabel(1) + "\n");
        } else if ($RELOP->getText() == "<=") {
            code.push_back("\tJLE " + label->getSkippedLabel(1) + "\n");
        } else if ($RELOP->getText() == ">") {
            code.push_back("\tJG " + label->getSkippedLabel(1) + "\n");
        } else if ($RELOP->getText() == ">=") {
            code.push_back("\tJGE " + label->getSkippedLabel(1) + "\n");
        }
        code.push_back("\tPUSH 0\n"); // Push true
        code.push_back("\tJMP " + label->getSkippedLabel(2) + "\n");
        code.push_back(label->getNextLabel() + ":\n");
        code.push_back("\tPUSH 1\n"); // Push false
        code.push_back(label->getNextLabel() + ":\n");
    }
    ;

simple_expression
    : term 
    | simple_expression ADDOP term {
        if ($ADDOP->getText() == "+") {
            code.push_back("\tPOP BX\n");
            code.push_back("\tPOP AX\n");
            code.push_back("\tADD AX, BX\n");
            code.push_back("\tPUSH AX\n");
        } else if ($ADDOP->getText() == "-") {
            code.push_back("\tPOP BX\n");
            code.push_back("\tPOP AX\n");
            code.push_back("\tSUB AX, BX\n");
            code.push_back("\tPUSH AX\n");
        }
    }
    ;
term
    : unary_expression
    | term MULOP unary_expression{
        code.push_back("\tPOP CX\n");
        code.push_back("\tPOP AX\n");
        code.push_back("\tCWD\n");
        if($MULOP->getText() == "*") {
            code.push_back("\tMUL CX\n");
        } else if ($MULOP->getText() == "/") {
            code.push_back("\tDIV CX\n");
        } else if ($MULOP->getText() == "%") {
            code.push_back("\tDIV CX\n");
            code.push_back("\tMOV AX, DX\n");
        }
        code.push_back("\tPUSH AX\n");
    }
    ;

unary_expression
    : ADDOP unary_expression {
        code.push_back("\tPOP AX\n");
        if ($ADDOP->getText() == "+") {
            code.push_back("\tPUSH AX\n");
        } else if ($ADDOP->getText() == "-") {
            code.push_back("\tNEG AX\n");
            code.push_back("\tPUSH AX\n");
        }
    }
    | NOT unary_expression
    | factor
    ;

factor
    : var=variable {
        code.push_back("MOV AX, " + $var.text + "\n");
        code.push_back("\tPUSH AX\t;Line "+ to_string($var.start->getLine()) + "\n");
    }
    | ID LPAREN argument_list RPAREN
    | LPAREN expression RPAREN
    | CONST_INT{
        code.push_back("MOV AX, " + $CONST_INT->getText() + "\n");
        code.push_back("\tPUSH AX\t;Line "+ to_string($CONST_INT->getLine()) + "\n");
    }
    | CONST_FLOAT
    | var=variable INCOP {
        code.push_back("\tMOV AX, " + $var.text + "\n");
        code.push_back("\tINC AX\n");
        code.push_back("\tMOV " + $var.text + ", AX\n");
    }
    | var=variable DECOP {
        code.push_back("\tPOP AX\n");
        code.push_back("\tDEC AX\n");
        code.push_back("\tMOV " + $var.text + ", AX\n");
    }
    ;

argument_list
    : arguments
    | /* empty */
    ;

arguments
    : arguments COMMA logic_expression
    | logic_expression
    ;

printLabel
    : /* empty */ {
        code.push_back(label->getNextLabel() + ":\n");
    }
    ;