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
        ExpressionResult() : truelist(), falselist(), nextlist() {}
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

compound_statement[bool isFunction] returns [vector<int> nextList]
    : LCURL {
        if (!isFunction) 
            st->enter_scope();
    } st=statements RCURL {
        if (isFunction) {
            st->print_all_scope();
        }
        if (!isFunction) {
            st->exit_scope();
        }
        $nextList = $st.nextList;
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
        $nextList = vector<int>{};
    }
    ;

statements returns [vector<int> nextList]
    : pl1=printLabel s1=statement {
        $nextList = $s1.nextList;
    }
    | s=statements pl1=printLabel s2=statement pl2=printLabel {
        code.push_back(";coming for backpatching nextlist\n");
        if(!$s2.nextList.empty()) {
            backpatch($s2.nextList, $pl2.label);
        }
        $nextList = $s2.nextList;
    }
    ;

statement returns [vector<int> nextList]
    : var_declaration{
        $nextList = vector<int>{};  // No next list for variable declaration
    }
    | expression_statement{
        $nextList = vector<int>{};  // No next list for variable declaration
    }
    | cs=compound_statement[false]{
        $nextList = $cs.nextList;  // No next list for compound statement
    }
    | FOR LPAREN expression_statement expression_statement expression RPAREN statement{
        auto forLabel = label->getNextLabel();
        code.push_back(forLabel + ":\n");
        code.push_back("\t" + $expression_statement.text + "\n");
        code.push_back("\t" + $expression.text + "\n");
        code.push_back("\t" + $expression_statement.text + "\n");
        code.push_back("\tJMP " + forLabel + "\n");
        $nextList = $statement.nextList;  // Carry forward nextlist of the most recent stmt
    }
    | IF LPAREN expression RPAREN pl1=printLabel s1=statement next  ELSE pl2=printLabel s2=statement {
        backpatch($expression.result.truelist, $pl1.label); // True → then-block
        backpatch($expression.result.falselist, $pl2.label); // False → else-block
        $nextList = merge(merge($s1.nextList, $next.nextList), $s2.nextList);
    }

    
    | IF LPAREN expression RPAREN pl=printLabel st=statement {
        backpatch($expression.result.truelist, $pl.label);  
        $nextList = merge($expression.result.falselist, $st.nextList);
    }


    | WHILE pl1=printLabel LPAREN expr=expression RPAREN pl2=printLabel st=statement{
        backpatch($st.nextList, $pl1.label); 
        backpatch($expr.result.truelist, $pl2.label);
        $nextList =$expr.result.falselist;
        code.push_back("\tJMP " + $pl1.label + "\n");
    }
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
    | RETURN expression SEMICOLON{
        // if ($expression.result.truelist.empty() && $expression.result.falselist.empty()) {
        //     code.push_back("\tPOP AX\n");
        // } else {
        //     string trueLabel = label->getNextLabel();
        //     string falseLabel = label->getNextLabel();
        //     string endLabel = label->getNextLabel();
        //     backpatch($expression.result.truelist, trueLabel);
        //     backpatch($expression.result.falselist, falseLabel);
        //     code.push_back(trueLabel + ":\n");
        //     code.push_back("\tMOV AX, 1\n");
        //     code.push_back("\tJMP " + endLabel + "\n");
        //     code.push_back(falseLabel + ":\n");
        //     code.push_back("\tMOV AX, 0\n");
        //     code.push_back(endLabel + ":\n");
        // }
        // code.push_back("\tRET\n");
    }
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

expression returns [ExpressionResult result]
    : logic=logic_expression {
        $result = $logic.result;
    }
    | var=variable ASSIGNOP logic=logic_expression {
        if (!$logic.result.truelist.empty() || !$logic.result.falselist.empty()) {
            string trueLabel = label->getNextLabel();
            string falseLabel = label->getNextLabel();
            string endLabel = label->getNextLabel();
            backpatch($logic.result.truelist, trueLabel);
            backpatch($logic.result.falselist, falseLabel);
            code.push_back(trueLabel + ":\n");
            code.push_back("\tMOV AX, 1\n");
            code.push_back("\tMOV " + $var.text + ", AX\n");
            code.push_back("\tJMP " + endLabel + "\n");
            code.push_back(falseLabel + ":\n");
            code.push_back("\tMOV AX, 0\n");
            code.push_back("\tMOV " + $var.text + ", AX\n");
            code.push_back(endLabel + ":\n");
        } else {
            // CASE 2: Numeric assignment — just move value
            code.push_back("\tPOP AX\n");
            code.push_back("\tMOV " + $var.text + ", AX\n");
        }
    }
    ;

logic_expression returns [ExpressionResult result]
    : r=rel_expression{
        $result = $r.result;
    }
    | left=rel_expression LOGICOP right=rel_expression {
        $result = ExpressionResult();
        string newLabel = label->getNextLabel();
        if($LOGICOP->getText() == "&&"){
            backpatch($left.result.truelist, newLabel);
            $result.truelist = $right.result.truelist;
            $result.falselist = merge($left.result.falselist, $right.result.falselist);
        }
        else if($LOGICOP->getText() == "||") {
            backpatch($left.result.falselist, newLabel);
            $result.truelist = merge($left.result.truelist, $right.result.truelist);
            $result.falselist = $right.result.falselist;
        }
        code.push_back(newLabel + ":\n");
    }
    ;
rel_expression returns [ExpressionResult result]
    :  simple_expression{
        // FIX: Convert a numeric value to a boolean context.
        // Any non-zero value is true, zero is false.
        code.push_back("\tPOP AX\n");
        code.push_back("\tCMP AX, 0\n");
        code.push_back("\tJNE PLACEHOLDER\n"); // JUMP IF NOT ZERO (TRUE)
        $result.truelist = makelist(code.size() - 1);
        code.push_back("\tJMP PLACEHOLDER\n"); // JUMP IF ZERO (FALSE)
        $result.falselist = makelist(code.size() - 1);
    }
    | simple_expression RELOP simple_expression{
        $result = ExpressionResult();
        code.push_back("\tPOP BX\n");
        code.push_back("\tPOP AX\n");
        code.push_back("\tCMP AX, BX\n");

        if ($RELOP->getText() == "==") {
            code.push_back("\tJE PLACEHOLDER\n");
        } else if ($RELOP->getText() == "!=") {
            code.push_back("\tJNE PLACEHOLDER\n");
        } else if ($RELOP->getText() == "<") {
            code.push_back("\tJL PLACEHOLDER\n");
        } else if ($RELOP->getText() == "<=") {
            code.push_back("\tJLE PLACEHOLDER\n");
        } else if ($RELOP->getText() == ">") {
            code.push_back("\tJG PLACEHOLDER\n");
        } else if ($RELOP->getText() == ">=") {
            code.push_back("\tJGE PLACEHOLDER\n");
        }
        $result.truelist = makelist(code.size() - 1);
        code.push_back("\tJMP PLACEHOLDER\n");
        $result.falselist = makelist(code.size() - 1);
    }
    ;

simple_expression returns [ExpressionResult result]
    : term {
        $result = ExpressionResult();
    }
    | simple_expression ADDOP term {
        $result = ExpressionResult();
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
        if ($ADDOP->getText() == "-") {
            code.push_back("\tPOP AX\n");
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
        // Correct post-increment: push old value, then increment
        code.push_back("\tMOV AX, " + $var.text + "\n");
        code.push_back("\tPUSH AX\n");
        code.push_back("\tINC " + $var.text + "\n");
    }
    | var=variable DECOP {
        // Correct post-decrement: push old value, then decrement
        code.push_back("\tMOV AX, " + $var.text + "\n");
        code.push_back("\tPUSH AX\n");
        code.push_back("\tDEC " + $var.text + "\n");
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

printLabel returns [string label]
    : /* empty */ {
        code.push_back(label->getNextLabel() + ":\n");
        $label = label->getCurrentLabel();
    }
    ;
next returns [vector<int> nextList]
    : { 
        code.push_back("\tJMP PLACEHOLDER\n");
        $nextList = makelist(code.size() - 1); 
    }
    ;