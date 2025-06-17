parser grammar C8086Parser;

options {
    tokenVocab = C8086Lexer;
}

@parser::header {
    #include <iostream>
    #include <fstream>
    #include <string>
    #include <cstdlib>
    #include "C8086Lexer.h"
    #include "return_data.hpp" // Assuming return_data.hpp contains the ReturnData struct
    using namespace std;

    extern ofstream parserLogFile;
    extern ofstream errorFile;

    extern int syntaxErrorCount;
}

@parser::members {
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
        errorFile << message << endl;
        errorFile.flush();
    }
}


start : program
    {
        writeIntoparserLogFile("Parsing completed successfully with " + to_string(syntaxErrorCount) + " syntax errors.\n");
    }
    ;

program returns [ReturnData data]
     : pgm=program unt=unit {
        $data.text = $pgm.data.text + "\n" + $unt.data.text;
        $data.line = $unt.data.line; 
        writeIntoparserLogFile(
            "\nLine "+to_string($data.line) + ":" +
            " program : program unit\n\n" +
            $data.text + "\n\n\n"
        );
     }
     | unt=unit{
        $data = $unt.data; 
        writeIntoparserLogFile(
            "\nLine "+to_string($data.line) + ":" +
            " program : unit\n\n" +
            $data.text + "\n\n\n"
        );
     }
    ;
    
unit returns [ReturnData data]
     : vd=var_declaration { 
        $data = $vd.data; 
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " unit : var_declaration\n\n" +
            $data.text + "\n\n"
        );
      }
     | fd=func_declaration { 
        $data = $fd.data; 
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " unit : func_declaration\n\n" +
            $data.text + "\n\n"
        );
      }
     | fdef=func_definition { 
        $data = $fdef.data;
         writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " unit : func_definition\n\n" +
            $data.text + "\n\n"
        );
     }
     ;
     
func_declaration returns [ReturnData data]
    : ts=type_specifier id=ID lp=LPAREN pl=parameter_list rp=RPAREN sm=SEMICOLON {
        $data.text = $ts.data.text + " " + $id->getText() + $lp->getText() + ($pl.ctx ? $pl.data.text : "") + $rp->getText() + $sm->getText();
        $data.line = $sm->getLine(); 
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" + 
            " func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n\n" +
            $data.text + "\n\n"
        );
    }
    | ts=type_specifier id=ID lp=LPAREN rp=RPAREN sm=SEMICOLON {
        $data.text = $ts.data.text + " " + $id->getText() + $lp->getText() + $rp->getText() + $sm->getText();
        $data.line = $sm->getLine();
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" + 
            " func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n\n" +
            $data.text + "\n\n"
        );
    }
    ;
         
func_definition returns [ReturnData data]
    : ts=type_specifier id=ID lp=LPAREN pl=parameter_list rp=RPAREN cs=compound_statement {
        $data.text = $ts.data.text + " " + $id->getText() + $lp->getText() + ($pl.ctx ? $pl.data.text : "") + $rp->getText() + $cs.data.text; 
        $data.line = $cs.data.line;
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n" +
            $data.text + "\n\n"
        );
    }
    | ts=type_specifier id=ID lp=LPAREN rp=RPAREN cs=compound_statement {
        $data.text = $ts.data.text + " " + $id->getText() + $lp->getText() + $rp->getText() + $cs.data.text;
        $data.line = $cs.data.line;
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " func_definition : type_specifier ID LPAREN RPAREN compound_statement\n\n" +
            $data.text + "\n\n"
        );
    }
    ;				


parameter_list returns [ReturnData data]
    : prev_list=parameter_list cm=COMMA ts=type_specifier id=ID {
        $data.text = $prev_list.data.text + $cm->getText() + $ts.data.text + " " + $id->getText();
        $data.line = $id->getLine();
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " parameter_list : parameter_list COMMA type_specifier ID\n\n" +
            $data.text + "\n\n"
        );
    }
    | prev_list=parameter_list cm=COMMA ts=type_specifier { 
        $data.text = $prev_list.data.text + $cm->getText() + $ts.data.text;
        $data.line = $ts.data.line;
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " parameter_list : parameter_list COMMA type_specifier\n\n" +
            $data.text + "\n\n"
        );
    }
    | ts=type_specifier id=ID {
        $data.text = $ts.data.text + " " + $id->getText();
        $data.line = $id->getLine();
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " parameter_list : type_specifier ID\n\n" +
            $data.text + "\n\n"
        );
    }
    | ts=type_specifier {
        $data = $ts.data;
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " parameter_list : type_specifier\n\n" +
            $data.text + "\n\n"
        );
    }
    ;
        
compound_statement returns [ReturnData data]
	: LCURL stmts=statements RCURL {
		$data.text = $LCURL->getText() + "\n" + $stmts.data.text + "\n" + $RCURL->getText();
		$data.line = $RCURL->getLine();
		writeIntoparserLogFile(
			"Line "+to_string($data.line) + ":" +
			" compound_statement : LCURL statements RCURL\n\n" +
			$data.text + "\n\n"
		);
	}
	| LCURL RCURL {
		$data.text = $LCURL->getText()+ "\n" + $RCURL->getText();
		$data.line = $RCURL->getLine();
		writeIntoparserLogFile(
			"Line "+to_string($data.line) + ":" +
			" compound_statement : LCURL RCURL\n\n" +
			$data.text + "\n\n"
		);
	}
	;

            
var_declaration returns [ReturnData data]
    : t=type_specifier dl=declaration_list sm=SEMICOLON {
        $data.text = $t.data.text + " " + $dl.data.text + $sm->getText(); 
        $data.line = $sm->getLine(); 
        
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " var_declaration : type_specifier declaration_list SEMICOLON\n\n" +
            $data.text + "\n\n"
        );
      }
    | t=type_specifier de=declaration_list_err sm=SEMICOLON {
        $data.text = $t.data.text + " " + $de.data.text + $sm->getText(); 
        $data.line = $sm->getLine(); 
        writeIntoErrorFile(
            string("Line# ") + to_string($data.line) +
            " with error name: " + $de.data.text + 
            " - Syntax error at declaration list of variable declaration"
        );
        syntaxErrorCount++;
      }
    ;

declaration_list_err returns [ReturnData data]
    : { 
        $data.text = "Error in declaration list";
        $data.line = 0; // Or a more specific line if available from context
    };
         
type_specifier returns [ReturnData data]	
    : kw=INT { 
        $data.text = $kw->getText();
        $data.line = $kw->getLine();
        writeIntoparserLogFile("Line "+to_string($data.line) + ":" + " type_specifier : INT\n\n" + $data.text + "\n\n" ); 
    }
    | kw=FLOAT { 
        $data.text = $kw->getText();
        $data.line = $kw->getLine();
        writeIntoparserLogFile("Line "+to_string($data.line) + ":" + " type_specifier : FLOAT\n\n" + $data.text + "\n\n");
    }
    | kw=VOID { 
        $data.text = $kw->getText();
        $data.line = $kw->getLine();
        writeIntoparserLogFile("Line "+to_string($data.line) + ":" + " type_specifier : VOID\n\n" + $data.text + "\n\n");
    }
    ;

declaration_list returns [ReturnData data]
    : prev_list=declaration_list cm=COMMA current_id=ID {
        $data.text = $prev_list.data.text + $cm->getText() + $current_id->getText();
        $data.line = $current_id->getLine(); 
        writeIntoparserLogFile("Line "+to_string($data.line) + ":" + " declaration_list : declaration_list COMMA ID\n\n" + $data.text + "\n\n");
    }
    | prev_list_arr=declaration_list cm=COMMA current_id_arr=ID lt=LTHIRD const_val_arr=CONST_INT rt=RTHIRD {
        string currentArrText = $current_id_arr->getText() + $lt->getText() + $const_val_arr->getText() + $rt->getText();
        $data.text = $prev_list_arr.data.text + $cm->getText() + currentArrText;
        $data.line = $current_id_arr->getLine(); 
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n\n" +
            $data.text + "\n\n"
        );
    }
    | base_id=ID {
        $data.text = $base_id->getText();
        $data.line = $base_id->getLine();
        writeIntoparserLogFile("Line "+to_string($data.line) + ":" + " declaration_list : ID\n\n" + $data.text + "\n\n");
    }
    | base_id_arr=ID lt=LTHIRD const_val_base_arr=CONST_INT rt=RTHIRD {
        $data.text = $base_id_arr->getText() + $lt->getText() + $const_val_base_arr->getText() + $rt->getText();
        $data.line = $base_id_arr->getLine();
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " declaration_list : ID LTHIRD CONST_INT RTHIRD\n\n" +
            $data.text + "\n\n"
        );
    }
    ;

statements returns [ReturnData data]
    : prev_stmts=statements stmt=statement { 
        $data.text = $prev_stmts.data.text + "\n" + $stmt.data.text; 
        $data.line = $stmt.data.line; 
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " statements : statements statement\n\n" +
            $data.text + "\n\n"
        );
    }
    | stmt=statement { 
        $data = $stmt.data;
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " statements : statement\n\n" +
            $data.text + "\n\n"
        );
    }
    ;

statement returns [ReturnData data]
    : vd=var_declaration {
        $data = $vd.data;
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " statement : var_declaration\n\n" +
            $data.text + "\n\n"
        );
    }
    | es=expression_statement {
        $data = $es.data;
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " statement : expression_statement\n\n" +
            $data.text + "\n\n"
        );
    }
    | cs_lc=LCURL stmts=statements cs_rc=RCURL { // compound_statement with statements
        $data.text = $cs_lc->getText() + " " + $stmts.data.text + " " + $cs_rc->getText();
        $data.line = $cs_lc->getLine();
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " statement : compound_statement (LCURL statements RCURL)\n\n" +
            $data.text + "\n\n"
        );
    }
    | cs_lc_empty=LCURL cs_rc_empty=RCURL { // empty compound_statement
        $data.text = $cs_lc_empty->getText() + $cs_rc_empty->getText();
        $data.line = $cs_lc_empty->getLine();
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " statement : compound_statement (LCURL RCURL)\n\n" +
            $data.text + "\n\n"
        );
    }
    | kw_for=FOR lp_for=LPAREN es1_for=expression_statement es2_for=expression_statement expr_for=expression rp_for=RPAREN stmt_for=statement {
        $data.text = $kw_for->getText() + $lp_for->getText() + $es1_for.data.text + " " + $es2_for.data.text + " " + $expr_for.data.text + $rp_for->getText() + " " + $stmt_for.data.text;
        $data.line = $kw_for->getLine();
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n" +
            $data.text + "\n\n"
        );
    }
    | kw_if_else=IF lp_if_else=LPAREN expr_if_else=expression rp_if_else=RPAREN stmt_if_else=statement kw_else=ELSE stmt_else=statement {
        $data.text = $kw_if_else->getText() + $lp_if_else->getText() + $expr_if_else.data.text + $rp_if_else->getText() + " " + $stmt_if_else.data.text + " " + $kw_else->getText() + " " + $stmt_else.data.text;
        $data.line = $kw_if_else->getLine();
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " statement : IF LPAREN expression RPAREN statement ELSE statement\n\n" +
            $data.text + "\n\n"
        );
    }
    | kw_if=IF lp_if=LPAREN expr_if=expression rp_if=RPAREN stmt_if=statement {
        $data.text = $kw_if->getText() + $lp_if->getText() + $expr_if.data.text + $rp_if->getText() + " " + $stmt_if.data.text;
        $data.line = $kw_if->getLine();
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " statement : IF LPAREN expression RPAREN statement\n\n" +
            $data.text + "\n\n"
        );
    }
    | kw_while=WHILE lp_while=LPAREN expr_while=expression rp_while=RPAREN stmt_while=statement {
        $data.text = $kw_while->getText() + $lp_while->getText() + $expr_while.data.text + $rp_while->getText() + " " + $stmt_while.data.text;
        $data.line = $kw_while->getLine();
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " statement : WHILE LPAREN expression RPAREN statement\n\n" +
            $data.text + "\n\n"
        );
    }
    | kw_println=PRINTLN lp_println=LPAREN id_println=ID rp_println=RPAREN sm_println=SEMICOLON {
        $data.text = $kw_println->getText() + $lp_println->getText() + $id_println->getText() + $rp_println->getText() + $sm_println->getText();
        $data.line = $kw_println->getLine();
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n" +
            $data.text + "\n\n"
        );
    }
    | kw_return=RETURN expr_return=expression sm_return=SEMICOLON {
        $data.text = $kw_return->getText() + " " + $expr_return.data.text + $sm_return->getText();
        $data.line = $kw_return->getLine();
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " statement : RETURN expression SEMICOLON\n\n" +
            $data.text + "\n\n"
        );
    }
    ;
      
expression_statement returns [ReturnData data]
    : sm=SEMICOLON {
        $data.text = $sm->getText();
        $data.line = $sm->getLine();
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " expression_statement : SEMICOLON\n\n" +
            $data.text + "\n\n"
        );
    }
    | expr=expression sm=SEMICOLON {
        $data.text = $expr.data.text + $sm->getText();
        $data.line = $expr.data.line; 
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " expression_statement : expression SEMICOLON\n\n" +
            $data.text + "\n\n"
        );
    }
    ;
      
variable returns [ReturnData data]
    : id_tok=ID {
        $data.text = $id_tok->getText();
        $data.line = $id_tok->getLine();
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " variable : ID\n\n" +
            $data.text + "\n\n"
        );
    }
    | id_tok=ID lthird=LTHIRD expr=expression rthird=RTHIRD {
        $data.text = $id_tok->getText() + $lthird->getText() + $expr.data.text + $rthird->getText();
        $data.line = $id_tok->getLine();
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " variable : ID LTHIRD expression RTHIRD\n\n" +
            $data.text + "\n\n"
        );
    }
    ;
     
expression returns [ReturnData data]
    : le=logic_expression {
        $data = $le.data;
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " expression : logic expression\n\n" +
            $data.text + "\n\n"
        );
    }
    | v=variable op=ASSIGNOP le=logic_expression {
        $data.text = $v.data.text + " " + $op->getText() + " " + $le.data.text;
        $data.line = $v.data.line; 
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " expression : variable ASSIGNOP logic expression\n\n" +
            $data.text + "\n\n"
        );
    }
    ;
            
logic_expression returns [ReturnData data]
    : re=rel_expression {
        $data = $re.data;
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " logic_expression : rel_expression\n\n" +
            $data.text + "\n\n"
        );
    }
    | re1=rel_expression op=LOGICOP re2=rel_expression {
        $data.text = $re1.data.text + " " + $op->getText() + " " + $re2.data.text;
        $data.line = $re1.data.line; 
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " logic_expression : rel_expression LOGICOP rel_expression\n\n" +
            $data.text + "\n\n"
        );
    }
    ;
            
rel_expression returns [ReturnData data]
    : se=simple_expression {
        $data = $se.data;
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " rel_expression : simple_expression\n\n" +
            $data.text + "\n\n"
        );
    }
    | se1=simple_expression op=RELOP se2=simple_expression {
        $data.text = $se1.data.text + " " + $op->getText() + " " + $se2.data.text;
        $data.line = $se1.data.line; 
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " rel_expression : simple_expression RELOP simple_expression\n\n" +
            $data.text + "\n\n"
        );
    }
    ;
                
simple_expression returns [ReturnData data]
    : t=term {
        $data = $t.data;
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " simple_expression : term\n\n" +
            $data.text + "\n\n"
        );
    }
    | se=simple_expression op=ADDOP t=term {
        $data.text = $se.data.text + $op->getText() + $t.data.text;
        $data.line = $se.data.line; 
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " simple_expression : simple_expression ADDOP term\n\n" +
            $data.text + "\n\n"
        );
    }
    ;
                    
term returns [ReturnData data]
    : ue=unary_expression {
        $data = $ue.data;
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " term : unary_expression\n\n" +
            $data.text + "\n\n"
        );
    }
    | t=term op=MULOP ue=unary_expression {
        $data.text = $t.data.text  + $op->getText() + $ue.data.text;
        $data.line = $t.data.line; 
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " term : term MULOP unary_expression\n\n" + 
            $data.text + "\n\n"
        );
    }
    ;

unary_expression returns [ReturnData data]
    : op=ADDOP ue=unary_expression { 
        $data.text = $op->getText() + $ue.data.text; 
        $data.line = $op->getLine();
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " unary_expression : ADDOP unary_expression\n\n" +
            $data.text + "\n\n"
        );
    }
    | op_not=NOT ue=unary_expression { 
        $data.text = $op_not->getText() + $ue.data.text; 
        $data.line = $op_not->getLine();
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " unary_expression : NOT unary_expression\n\n" +
            $data.text + "\n\n"
        );
    }
    | f=factor { 
        $data = $f.data; 
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " unary_expression : factor\n\n" +
            $data.text + "\n\n"
        );
    }
    ;
    // Removed duplicate unary_expression rule that did not have returns
    
factor returns [ReturnData data]
    : v=variable {
        $data = $v.data;
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " factor : variable\n\n" +
            $data.text + "\n\n"
        );
    }
    | id_tok=ID lp=LPAREN al=argument_list rp=RPAREN {
        $data.text = $id_tok->getText() + $lp->getText() + ($al.ctx ? $al.data.text : "") + $rp->getText();
        $data.line = $id_tok->getLine();
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " factor : ID LPAREN argument_list RPAREN\n\n" +
            $data.text + "\n\n"
        );
    }
    | lp=LPAREN expr_val=expression rp=RPAREN {
        $data.text = $lp->getText() + $expr_val.data.text + $rp->getText();
        $data.line = $lp->getLine();
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " factor : LPAREN expression RPAREN\n\n" +
            $data.text + "\n\n"
        );
    }
    | tok=CONST_INT {
        $data.text = $tok->getText();
        $data.line = $tok->getLine();
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " factor : CONST_INT\n\n" +
            $data.text + "\n\n"
        );
    }
    | tok=CONST_FLOAT {
        $data.text = $tok->getText();
        $data.line = $tok->getLine();
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " factor : CONST_FLOAT\n\n" +
            $data.text + "\n\n"
        );
    }
    | v=variable op=INCOP {
        $data.text = $v.data.text + $op->getText();
        $data.line = $v.data.line;
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " factor : variable INCOP\n\n" +
            $data.text + "\n\n"
        );
    }
    | v=variable op=DECOP {
        $data.text = $v.data.text + $op->getText();
        $data.line = $v.data.line;
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " factor : variable DECOP\n\n" +
            $data.text + "\n\n"
        );
    }
    ;
    
argument_list returns [ReturnData data]
    : args=arguments {
        $data = $args.data;
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " argument_list : arguments\n\n" +
            $data.text + "\n\n"
        );
    }
    | { 
        $data.text = "";
        $data.line = 0; 
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" + 
            " argument_list : <empty>\n\n" +
            $data.text + "\n\n"
        );
    }
    ;
    
arguments returns [ReturnData data]
    : prev_args=arguments cm=COMMA le=logic_expression { 
        $data.text = $prev_args.data.text + $cm->getText() + $le.data.text;
        $data.line = $le.data.line; 
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " arguments : arguments COMMA logic_expression\n\n" +
            $data.text + "\n\n"
        );
    }
    | le=logic_expression { 
        $data = $le.data; 
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " arguments : logic_expression\n\n" +
            $data.text + "\n\n"
        );
    }
    ;