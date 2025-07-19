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
    enum ExprCtx { NUMERIC, BOOLEAN, FROMRETURN, ARRAY, FROMFOR };
    bool singleStatus = false;
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
            "NEW_LINE proc\n",
            "\tPUSH AX\n",
            "\tPUSH DX\n",
            "\tMOV AH,2\n",
            "\tMOV DL,0Dh\n",
            "\tINT 21h\n",
            "\tMOV AH,2\n",
            "\tMOV DL,0Ah\n",
            "\tINT 21h\n",
            "\tPOP DX\n",
            "\tPOP AX\n",
            "\tRET\n",
            "NEW_LINE ENDP\n",
            "\n",
            "PRINT_OUTPUT proc  ;print what is in ax\n",
            "\tPUSH AX\n",
            "\tPUSH BX\n",
            "\tPUSH CX\n",
            "\tPUSH DX\n",
            "\tPUSH SI\n",
            "\tLEA SI,NUMBER\n",
            "\tMOV BX,10\n",
            "\tADD SI,4\n",
            "\tCMP AX,0\n",
            "\tJGE print\n",
            "\tPUSH AX\n",
            "\tMOV AH,2\n",
            "\tMOV DL,'-'\n",
            "\tINT 21h\n",
            "\tPOP AX\n",
            "\tNEG AX\n",
            "PRINT:\n",
            "\tXOR DX,DX\n",
            "\tDIV BX\n",
            "\tMOV [SI],DL\n",
            "\tADD [SI],'0'\n",
            "\tDEC SI\n",
            "\tCMP AX,0\n",
            "\tJNE PRINT\n",
            "\tINC SI\n",
            "\tLEA DX,SI\n",
            "\tMOV AH,9\n",
            "\tINT 21h\n",
            "\tPOP SI\n",
            "\tPOP DX\n",
            "\tPOP CX\n",
            "\tPOP BX\n",
            "\tPOP AX\n",
            "\tRET\n",
            "PRINT_OUTPUT ENDP\n",
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

type_specifier returns [string text]
    : INT { current_type = "INT"; 
        $text = "INT";
    }
    | FLOAT { current_type = "FLOAT"; 
        $text = "FLOAT";
    }
    | VOID  { current_type = "VOID"; 
        $text = "VOID";
    }
    ;

declaration_list
    : declaration_list COMMA ID {
        st->insert($ID->getText(), toUpperString(current_type));
        if(st->get_current_scope_id() == "1") {
            data.push_back("\t" + $ID->getText() + " DW 0\n");
        } else{
            code.push_back("\tSUB SP, 2\n");
        }
    }
    | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
        st->insert($ID->getText(), toUpperString(current_type), true, false, true, stod($CONST_INT->getText()));
        if(st->get_current_scope_id() == "1") {
            data.push_back("\t" + $ID->getText() + " DW " + $CONST_INT->getText() + " DUP(0)\n");
        } else{
            int size = stoi($CONST_INT->getText())*2;
            code.push_back("\tSUB SP, " + to_string(size) + "\n");
        }
    }
    | ID {
        st->insert($ID->getText(), toUpperString(current_type));
        if(st->get_current_scope_id() == "1") {
            data.push_back("\t"+$ID->getText() + " DW 0\n");
        } else{
            code.push_back("\tSUB SP, 2\t\t;Line " + to_string($ID->getLine()) + "\n");
        }
    }
    | ID LTHIRD CONST_INT RTHIRD {
        st->insert($ID->getText(), toUpperString(current_type), true, false, true, stod($CONST_INT->getText()));
        if(st->get_current_scope_id() == "1") {
            data.push_back("\t" + $ID->getText() + " DW " + $CONST_INT->getText() + " DUP(0)\n");
        } else{
            int size = stoi($CONST_INT->getText())*2;
            code.push_back("\tSUB SP, " + to_string(size) + "\t\t;Line " + to_string($ID->getLine()) + "\n");
        }
    }
    ;

func_declaration
    : type_specifier ID LPAREN {st->enter_scope();} pl=parameter_list RPAREN SEMICOLON {
        st->exit_scope();
        string func_data = $type_specifier.text + " " + $ID->getText() + "(" +  $pl.data + ")";
        st->insert(func_data, "FUNCTION", true, false);
    }
    | type_specifier ID LPAREN {st->enter_scope();} RPAREN SEMICOLON {
        st->exit_scope();
        string func_data = $type_specifier.text + " " + $ID->getText() + "()";
        st->insert(func_data, "FUNCTION", true, false);
    }
    ;

func_definition
    : type_specifier ID LPAREN {st->enter_scope();} pl=parameter_list RPAREN {
        string func_data = $type_specifier.text + " " + $ID->getText() + "(" + $pl.data + ")";
        st->insertInParentScope(func_data, "FUNCTION", false, true);
        auto sb = st->lookup($ID->getText());
        sb->setInside(true);
        auto params = sb->getParameters();
        
        for(int i = 0; i < params.size(); i++) {
            string paramType = toUpperString(params[i].first);
            string paramName = params[i].second;
            st->insert(paramName, paramType, true, false, false, 0, true);
            auto sb1 = st->lookup(paramName);
            sb1->setStackOffset((params.size() - i) * 2 + 2);
            sb1->setIsParam(true);
        }
        
        code.push_back($ID->getText() + " PROC\n");
        if($ID->getText() == "main") {
            code.push_back("\tMOV AX, @DATA\n");
            code.push_back("\tMOV DS, AX\n");
        }
        code.push_back("\tPUSH BP\n");
        code.push_back("\tMOV BP, SP\n");
    } compound_statement[true]{
        auto sb2 = st->lookup($ID->getText());
        sb2->setInside(false);
        if (!st->getCurrentScopeReturned()) {
            if($ID->getText() == "main") {
                code.push_back("\tPOP BP\n");
                code.push_back("\tMOV AX, 4CH\t\t;Line " + to_string($ID->getLine()) + "\n");
                code.push_back("\tINT 21H\n");
            }else {
                code.push_back("\tPOP BP\n");
                int arg_count = sb2->getParameters().size();
                if (arg_count > 0) {
                    code.push_back("\tRET " + to_string(arg_count * 2) + "\t\t;Line " + to_string($ID->getLine()) + "\n");
                } else {
                    code.push_back("\tRET\t\t;Line " + to_string($ID->getLine()) + "\n");
                }
            }
        }
        sb2->setReturned(true);
        code.push_back($ID->getText() + " ENDP\n");
        st->setCurrentScopeReturned(true);
        st->exit_scope();
    }
    | type_specifier ID LPAREN {st->enter_scope();} RPAREN {
        string func_data = $type_specifier.text + " " + $ID->getText() + "()";
        st->insertInParentScope(func_data, "FUNCTION", false, true);
        auto sb = st->lookup($ID->getText());
        sb->setInside(true);
        code.push_back($ID->getText() + " PROC\n");
        if($ID->getText() == "main") {
            code.push_back("\tMOV AX, @DATA\n");
            code.push_back("\tMOV DS, AX\n");
        }
        code.push_back("\tPUSH BP\n");
        code.push_back("\tMOV BP, SP\n");
    } compound_statement[true]{
        auto sb1 = st->lookup($ID->getText());
        sb1->setInside(false);            
        if (!st->getCurrentScopeReturned()) {
            if($ID->getText() == "main") {
                code.push_back("\tPOP BP\n");
                code.push_back("\tMOV AX, 4CH\t\t;Line " + to_string($ID->getLine()) + "\n");
                code.push_back("\tINT 21H\n");
            }else {
                code.push_back("\tPOP BP\n");
                code.push_back("\tRET\n\t\t;Line " + to_string($ID->getLine()) + "\n");
            }
        }
        sb1->setReturned(true);
        code.push_back($ID->getText() + " ENDP\n");
        st->setCurrentScopeReturned(true);
        st->exit_scope();
    }
    ;

parameter_list returns [string data]
    : pl=parameter_list COMMA type_specifier ID{
        $data = $pl.data + ", " + toUpperString($type_specifier.text) + " " + $ID->getText();
    }
    | parameter_list COMMA type_specifier{
        $data = $pl.data + ", " + toUpperString($type_specifier.text);
    }
    | type_specifier ID {
        $data = toUpperString($type_specifier.text) + " " + $ID->getText();
    }
    | type_specifier{
        $data = toUpperString($type_specifier.text);
    }
    ;

compound_statement[bool isFunction] returns [vector<int> nextList]
    : LCURL {
        if (!isFunction) 
            st->enter_scope();
    } st=statements RCURL {

        if(!st->getCurrentScopeReturned()) {
            if(st->getCurrentScopeStackTop() > 0){
                code.push_back(label->getNextLabel() + ":\n");
                code.push_back("\tADD SP, " + to_string(st->getCurrentScopeStackTop()) + "\n");
            }
        }
        $nextList = $st.nextList;
        if (!isFunction) {
            st->exit_scope();
        }
        if(st->getCurrentScopeReturned())
            code.push_back(";UNREACHABLE CODE ENDS HERE\n");
    }
    | LCURL {
        if (!isFunction)
            st->enter_scope();
    } RCURL {
        if (isFunction) {
        }
        if (!isFunction) {
            st->exit_scope();
        }
        $nextList = vector<int>{};
    }
    ;

statements returns [vector<int> nextList]
    : s1=statement pl2=printLabel {
        $nextList = $s1.nextList;
        if(!$s1.nextList.empty()) {
            backpatch($s1.nextList, $pl2.label);
        }
    }
    | s=statements s2=statement pl2=printLabel {
        if(!$s2.nextList.empty()) {
            backpatch($s2.nextList, $pl2.label);
        }
        $nextList = $s2.nextList;
    }
    ;

statement returns [vector<int> nextList]
    : var_declaration{
        $nextList = vector<int>{};
    }
    | expression_statement[NUMERIC]{
        $nextList = vector<int>{};
    }
    | cs=compound_statement[false]{
        $nextList = $cs.nextList;   
    }
    | FOR LPAREN 
        expression_statement[NUMERIC]   
        pl1=printLabel    
        expst=expression_statement[BOOLEAN] 
        pl2=printLabel 
        expr=expression[FROMFOR]
        next
        RPAREN
        pl3=printLabel
        statement {
        backpatch($expst.result.truelist, $pl3.label);
        backpatch($next.nextList, $pl1.label); 
        code.push_back("\tJMP " + $pl2.label + "\n");
        $nextList = $expst.result.falselist;
    }

    | IF LPAREN expression[BOOLEAN] RPAREN pl1=printLabel s1=statement next  ELSE pl2=printLabel s2=statement {
        backpatch($expression.result.truelist, $pl1.label);
        backpatch($expression.result.falselist, $pl2.label);
        $nextList = merge(merge($s1.nextList, $next.nextList), $s2.nextList);
    }

    | IF LPAREN expression[BOOLEAN] RPAREN pl=printLabel st=statement {
        backpatch($expression.result.truelist, $pl.label);
        $nextList = merge($expression.result.falselist, $st.nextList);
    }


    | WHILE pl1=printLabel LPAREN expr=expression[BOOLEAN] RPAREN pl2=printLabel st=statement{
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
        code.push_back("\tCALL PRINT_OUTPUT\t\t;Line " + to_string($ID->getLine()) + "\n");
        code.push_back("\tCALL NEW_LINE\n");
    }
    | RETURN expression[FROMRETURN] SEMICOLON{
        auto sb = st->insideFunction();
        sb->setReturned(true);
        code.push_back("\tPOP AX\n");
        int top = st->getTotalStackOffset();
        if (top > 0) {
            code.push_back("\tADD SP, " + to_string(top) + "\n");
        }
        code.push_back(label->getNextLabel() + ":\n");
        code.push_back("\tPOP BP\n");
        top = st->getCurrentScopeStackTop();
        if(sb->getFunctionName() != "main") {
            if (sb->getType() == "VOID" || sb->getParameters().empty()) {
                code.push_back("\tRET\t\t;Line " + to_string($RETURN->getLine()) + "\n");
            } else {
                code.push_back("\tRET "+to_string(sb->getParameters().size()*2)+"\t\t;Line " + to_string($RETURN->getLine()) + "\n");
            }
        }else {
            code.push_back("\tMOV AX, 4CH\n");
            code.push_back("\tINT 21H\n");
        }
        if(!st->getCurrentScopeReturned())
            code.push_back(";UNREACHABLE CODE STARTS HERE\n");
        st->setCurrentScopeReturned(true);
    }
    ;
expression_statement[ExprCtx ctx] returns[ExpressionResult result]
    : SEMICOLON{
        $result = ExpressionResult(); 
    }
    | expression[ctx] SEMICOLON{
        if(ctx == NUMERIC) {
            code.push_back("\tPOP AX\n");
        } 
        $result = $expression.result;
    }
    ;

variable[bool isDestination] returns [string text,bool isArray]
    : ID {
        auto sb = st->lookup($ID->getText());
        auto scope_id = st->get_scope_id(sb);
        if (scope_id == "1") {
            $text = $ID->getText();
        } else {
            if(sb->isParam()){
                $text = "[BP+" + to_string(sb->getStackOffset()) + "]";
            } else {
                $text = "[BP-" + to_string(sb->getStackOffset()) + "]"; 
            }
        }
        $isArray = false;
    }
    | ID LTHIRD expression[ARRAY] RTHIRD{
        auto sb = st->lookup($ID->getText());
        auto scope_id = st->get_scope_id(sb);
        code.push_back("\tPOP AX\n");
        code.push_back("\tSHL AX, 1\n"); 
        if (scope_id == "1") {
            if(isDestination){
                code.push_back("\tPUSH AX\n");
            }else{
                code.push_back("\tMOV SI, AX\n");
            }
            $text = "[ "+$ID->getText() + " + SI]";
        } 
        else {
            string offset = to_string(sb->getStackOffset());
            code.push_back("\tSUB AX, " + offset + "\n");
            if(isDestination){
                code.push_back("\tPUSH AX\n");
            }else{
                code.push_back("\tMOV SI, AX\n");
            }
            $text = "[BP + SI]";
        }
        $isArray = true;
    }
    ;

expression[ExprCtx ctx] returns [ExpressionResult result]
    : logic=logic_expression[ctx] {
        $result = ExpressionResult();
        if(ctx == BOOLEAN && $logic.result.truelist.empty() && $logic.result.falselist.empty()) {
            $result = ExpressionResult();
            code.push_back("\tPOP AX\n");
            code.push_back("\tCMP AX, 0\t\t;Line " + to_string($logic.start->getLine()) + "\n");
            code.push_back("\tJNE PLACEHOLDER\n");
            $result.truelist = makelist(code.size() - 1);
            code.push_back("\tJMP PLACEHOLDER\n");
            $result.falselist = makelist(code.size() - 1);
        } 
        else if (ctx == FROMFOR ) {
            code.push_back("\tPOP AX\n");
            $result = $logic.result;
        }
        else {
            $result = $logic.result;
        }
    }
    | var=variable[true] ASSIGNOP logic=logic_expression[NUMERIC] {
        if (!$logic.result.truelist.empty() || !$logic.result.falselist.empty()) {
            string trueLabel = label->getNextLabel();
            string falseLabel = label->getNextLabel();
            string endLabel = label->getNextLabel();
            backpatch($logic.result.truelist, trueLabel);
            backpatch($logic.result.falselist, falseLabel);
            code.push_back(trueLabel + ":\n");
            code.push_back("\tMOV AX, 1\n");
            code.push_back("\tMOV " + $var.text + ", AX\t\t;Line " + to_string($var.start->getLine()) + "\n");
            code.push_back("\tJMP " + endLabel + "\n");
            code.push_back(falseLabel + ":\n");
            code.push_back("\tMOV AX, 0\n");
            code.push_back("\tMOV " + $var.text + ", AX\t\t;Line " + to_string($var.start->getLine()) + "\n");
            code.push_back(endLabel + ":\n");
        } else {
            code.push_back("\tPOP AX\n");
            if($var.isArray){
                code.push_back("\tPOP SI\n");
            }
            code.push_back("\tMOV " + $var.text + ", AX\t\t;Line " + to_string($var.start->getLine()) + "\n");
        }
        if(ctx != FROMFOR)
        code.push_back("\tPUSH AX\n");
    }
    ;

logic_expression[ExprCtx ctx] returns [ExpressionResult result]
    : r=rel_expression[ctx]{
        $result = $r.result;
    }
    | left=rel_expression[BOOLEAN] LOGICOP mark=printLabel right=rel_expression[BOOLEAN] {
        $result = ExpressionResult();
        if($LOGICOP->getText() == "&&"){
            backpatch($left.result.truelist, $mark.label);
            $result.truelist = $right.result.truelist;
            $result.falselist = merge($left.result.falselist, $right.result.falselist);
        }
        else if($LOGICOP->getText() == "||") {
            backpatch($left.result.falselist, $mark.label);
            $result.truelist = merge($left.result.truelist, $right.result.truelist);
            $result.falselist = $right.result.falselist;
        }
    }
    ;
rel_expression[ExprCtx ctx] returns [ExpressionResult result]
    :  simple_expression{
        $result = $simple_expression.result;
        if(ctx  == BOOLEAN && $result.truelist.empty() && $result.falselist.empty()) {
            code.push_back("\tPOP AX\n");
            code.push_back("\tCMP AX, 0\t\t;Line " + to_string($simple_expression.start->getLine()) + "\n");
            code.push_back("\tJNE PLACEHOLDER;\t\tline "+to_string($simple_expression.start->getLine())+ "\n");
            $result.truelist = makelist(code.size() - 1);
            code.push_back("\tJMP PLACEHOLDER;\t\tline "+to_string($simple_expression.start->getLine())+ "\n");
            $result.falselist = makelist(code.size() - 1);
        }
    }
    | simple_expression RELOP simple_expression{
        $result = ExpressionResult();
        code.push_back("\tPOP BX\n");
        code.push_back("\tPOP AX\n");
        code.push_back("\tCMP AX, BX\t\t;Line " + to_string($RELOP->getLine()) + "\n");

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
        $result = $term.result;
    }
    | simple_expression ADDOP term {
        $result = ExpressionResult();
        if ($ADDOP->getText() == "+") {
            code.push_back("\tPOP BX\n");
            code.push_back("\tPOP AX\n");
            code.push_back("\tADD AX, BX\t\t;Line " + to_string($ADDOP->getLine()) + "\n");
            code.push_back("\tPUSH AX\n");
        } else if ($ADDOP->getText() == "-") {
            code.push_back("\tPOP BX\n");
            code.push_back("\tPOP AX\n");
            code.push_back("\tSUB AX, BX\t\t;Line " + to_string($ADDOP->getLine()) + "\n");
            code.push_back("\tPUSH AX\n");
        }
    }
    ;
term returns [ExpressionResult result]
    : unary_expression{
        $result = $unary_expression.result;
    }
    | term MULOP unary_expression{
        code.push_back("\tPOP CX\n");
        code.push_back("\tPOP AX\n");
        code.push_back("\tCWD\n");
        if($MULOP->getText() == "*") {
            code.push_back("\tMUL CX\t\t;Line " + to_string($MULOP->getLine()) + "\n");
        } else if ($MULOP->getText() == "/") {
            code.push_back("\tDIV CX\t\t;Line " + to_string($MULOP->getLine()) + "\n");
        } else if ($MULOP->getText() == "%") {
            code.push_back("\tDIV CX\t\t;Line " + to_string($MULOP->getLine()) + "\n");
            code.push_back("\tMOV AX, DX\n");
        }
        code.push_back("\tPUSH AX\n");
        $result = ExpressionResult();
    }
    ;

unary_expression returns [ExpressionResult result]
    : ADDOP unary_expression {
        if ($ADDOP->getText() == "-") {
            code.push_back("\tPOP AX\n");
            code.push_back("\tNEG AX\t\t;Line " + to_string($ADDOP->getLine()) + "\n");
            code.push_back("\tPUSH AX\n");
        }
        $result = ExpressionResult();
    }
    | NOT unary_expression{
        $result.truelist = $unary_expression.result.falselist;
        $result.falselist = $unary_expression.result.truelist;
    }
    | factor{
        $result= $factor.result;
    }
    ;

factor returns [ExpressionResult result]
    : var=variable[false] {
        code.push_back("\tMOV AX, " + $var.text + "\t\t;Line " + to_string($var.start->getLine()) + "\n");
        code.push_back("\tPUSH AX\n");
        $result = ExpressionResult();
    }
    | ID LPAREN argument_list RPAREN{
        auto sb = st->lookup($ID->getText());
        code.push_back("\tCALL " + $ID->getText() + "\t\t;Line " + to_string($ID->getLine()) + "\n");
        if (sb->getType() != "VOID") {
            code.push_back("\tPUSH AX\n");
        }
        $result = ExpressionResult();
    }
    | LPAREN expression[NUMERIC] RPAREN{
        $result = $expression.result;
    }
    | CONST_INT{
        code.push_back("\tMOV AX, " + $CONST_INT->getText() + "\t\t;Line " + to_string($CONST_INT->getLine()) + "\n");
        code.push_back("\tPUSH AX\n");
        $result = ExpressionResult();
    }
    | CONST_FLOAT{
        $result = ExpressionResult();
    }
    | var=variable[false] INCOP {
        code.push_back("\tMOV AX, " + $var.text + "\t\t;Line " + to_string($var.start->getLine()) + "\n");
        code.push_back("\tPUSH AX\n");
        code.push_back("\tINC AX\n");
        code.push_back("\tMOV " + $var.text + ", AX\n");
        $result = ExpressionResult();
    }
    | var=variable[false] DECOP {
        code.push_back("\tMOV AX, " + $var.text + "\t\t;Line " + to_string($var.start->getLine()) + "\n");
        code.push_back("\tPUSH AX\n");
        code.push_back("\tDEC AX\n");
        code.push_back("\tMOV " + $var.text + ", AX\n");
        $result = ExpressionResult();
    }
    ;

argument_list
    : arguments
    | /* empty */
    ;

arguments
    : arguments COMMA logic_expression[NUMERIC]
    | logic_expression[NUMERIC]
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