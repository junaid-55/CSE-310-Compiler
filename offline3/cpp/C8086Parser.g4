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
    #include "return_data.hpp" 
    #include "/workspaces/CSE-310-Compiler/offline3/cpp/headers/symbol_table.h"
    using namespace std;

    extern ofstream parserLogFile;
    extern ofstream errorFile;

    extern int syntaxErrorCount;
}

@parser::members {
    SymbolTable *st = new SymbolTable(7);
    string current_type = "";
    string current_func = "";
    int param_count = 0;
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
                // If no space found, treat the whole token as a type with no name
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


start : pg = program
    {
        writeIntoparserLogFile(
            "Line " + to_string($pg.data.line)+": start : program\n"
        );
        st->print_all_scope(parserLogFile);
        parserLogFile << "\n\n";

        writeIntoparserLogFile(
            "Total lines : " +to_string($pg.data.line) + "\n"
            "Total errors: " + to_string(syntaxErrorCount) + "\n\n"
        );
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
            "\nLine "+to_string($data.line) + ":" +
            " unit : func_declaration\n\n" +
            $data.text + "\n\n"
        );
      }
     | fdef=func_definition { 
        $data = $fdef.data;
         writeIntoparserLogFile(
            "\nLine "+to_string($data.line) + ":" +
            " unit : func_definition\n\n" +
            $data.text + "\n\n\n"
        );
     }
     ;
     
func_declaration returns [ReturnData data]
    : ts=type_specifier id=ID lp=LPAREN {st->enter_scope();}pl=parameter_list rp=RPAREN{
        auto parse_list = parseParameterList($pl.data.text);
        for(int i=0; i<parse_list.size(); i++){
            auto name = parse_list[i].second;
            if(name == ""){
                writeIntoErrorFile(
                    "Error at line " + to_string($pl.data.line) + 
                    ": " + to_string(i+1) + "th parameter's name not given in function declaration of " + $id->getText() + "\n\n"
                );
                writeIntoparserLogFile(
                    "Error at line " + to_string($pl.data.line) + 
                    ": " + to_string(i+1) + "th parameter's name not given in function declaration of " + $id->getText() + "\n\n"
                );
                syntaxErrorCount++;
            }
        }
    }
     sm=SEMICOLON {
        st->exit_scope();
        $data.text = $ts.data.text+ " "  + $id->getText() + $lp->getText() + ($pl.ctx ? $pl.data.text : "") + $rp->getText() + $sm->getText();
        $data.line = $sm->getLine(); 
        st->insert($data.text,"FUNCTION",true,false);
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" + 
            " func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n\n" +
            $data.text + "\n\n"
        );
    }
    | ts=type_specifier id=ID lp=LPAREN{st->enter_scope();}rp=RPAREN
     sm=SEMICOLON {
        st->exit_scope();
        $data.text = $ts.data.text + " " + $id->getText() + $lp->getText() + $rp->getText() + $sm->getText();
        $data.line = $sm->getLine();
        st->insert($data.text,"FUNCTION",true,false);
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" + 
            " func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n\n" +
            $data.text + "\n\n"
        );
    }
    ;
         
func_definition returns [ReturnData data]
    : ts=type_specifier id=ID 
    lp=LPAREN{st->enter_scope();}
     pl=parameter_list 
        rp=RPAREN {
            {
                auto parse_list = parseParameterList($pl.data.text);
                for(int i=0; i<parse_list.size(); i++){
                    auto name = parse_list[i].second;
                    if(name == ""){
                        writeIntoErrorFile(
                            "Error at line " + to_string($pl.data.line) + 
                            ": " + to_string(i+1) + "th parameter's name not given in function declaration of " + $id->getText() + "\n\n"
                        );
                        writeIntoparserLogFile(
                            "Error at line " + to_string($pl.data.line) + 
                            ": " + to_string(i+1) + "th parameter's name not given in function declaration of " + $id->getText() + "\n\n"
                        );
                        syntaxErrorCount++;
                    }
                }
            }
            auto sb = st->lookup($id->getText());
            if(sb == nullptr) {
                string func_data = $ts.data.text + " " + $id->getText() + $lp->getText() + ($pl.ctx ? $pl.data.text : "") + $rp->getText();
                st->insertInParentScope(func_data, "FUNCTION", false, true);
            }
            else if(sb->isFunction() && !sb->isDefined()) {
                    sb->setDefined(true);
                    
                    // if the return type matches the function declaration
                    if(toUpperString(sb->getReturnType()) != toUpperString($ts.data.text)) {
                        writeIntoErrorFile(
                            "Error at line " + to_string($ts.data.line) + 
                            ": Return type mismatch with function declaration in function " + $id->getText() + "\n\n"
                        );
                        writeIntoparserLogFile(
                            "Error at line " + to_string($ts.data.line) + 
                            ": Return type mismatch with function declaration in function " + $id->getText() + "\n\n"
                        );
                        syntaxErrorCount++;
                    }     

                    // if parameter count is same with declaration
                    auto param_count = sb->getParameterCount();
                    auto param_list = sb->getParameters();
                    auto current_param_list = parseParameterList($pl.data.text);
                    if(param_count != current_param_list.size()) {
                        writeIntoErrorFile(
                            "Error at line " + to_string($ts.data.line) + 
                            ": Total number of arguments mismatch with declaration in function " + $id->getText() + "\n\n"
                        );
                        writeIntoparserLogFile(
                            "Error at line " + to_string($ts.data.line) + 
                            ": Total number of arguments mismatch with declaration in function " + $id->getText() + "\n\n"
                        );
                        syntaxErrorCount++;
                    } else {

                    // if parameter types are same with declaration
                        for(size_t i = 0; i < param_list.size(); ++i) {
                            if(param_list[i].first != toUpperString(current_param_list[i].first)) {
                                writeIntoErrorFile(
                                    "Error at line " + to_string($ts.data.line) + 
                                    ": Type mismatch in parameter " + param_list[i].first + " in function " + $id->getText() + "\n\n"
                                );
                                writeIntoparserLogFile(
                                    "Error at line " + to_string($ts.data.line) + 
                                    ": Type mismatch in parameter " + param_list[i].first + " in function " + $id->getText() + "\n\n"
                                );
                                syntaxErrorCount++;
                            }
                        }
                    }

            }
            else{
                writeIntoErrorFile(
                    "Error at line " + to_string($ts.data.line) + 
                    ": Multiple declaration of " + $id->getText() + "\n\n"
                );
                writeIntoparserLogFile(
                    "Error at line " + to_string($ts.data.line) + 
                    ": Multiple declaration of " + $id->getText() + "\n\n"
                );
                syntaxErrorCount++;
            }
        }
        cs=compound_statement[true]
        {
        
        $data.text = $ts.data.text + " " + $id->getText() + $lp->getText() + ($pl.ctx ? $pl.data.text : "") + $rp->getText() + $cs.data.text; 
        $data.line = $cs.data.line;
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n" +
            $data.text + "\n\n"
        );
    }
    | ts=type_specifier id=ID lp=LPAREN{st->enter_scope();}
     rp=RPAREN{
        auto sb = st->lookup($id->getText());
        if(sb == nullptr) {
            string func_data = $ts.data.text + " " + $id->getText() + $lp->getText() + $rp->getText();
            st->insertInParentScope(func_data, "FUNCTION", false, true);
        }
        else if(sb->isFunction() && !sb->isDefined()) {
                sb->setDefined(true);
                
                // if the return type matches the function declaration
                if(toUpperString(sb->getReturnType()) != toUpperString($ts.data.text)) {
                    writeIntoErrorFile(
                        "Error at line " + to_string($ts.data.line) + 
                        ": Return type mismatch with function declaration in function " + $id->getText() + "\n\n"
                    );
                    writeIntoparserLogFile(
                        "Error at line " + to_string($ts.data.line) + 
                        ": Return type mismatch with function declaration in function " + $id->getText() + "\n\n"
                    );
                    syntaxErrorCount++;
                }     

                // if parameter count is same with declaration
                auto param_count = sb->getParameterCount();
                if(param_count != 0) {
                    writeIntoErrorFile(
                        "Error at line " + to_string($ts.data.line) + 
                        ": Total number of arguments mismatch with declaration in function " + $id->getText() + "\n\n"
                    );
                    writeIntoparserLogFile(
                        "Error at line " + to_string($ts.data.line) + 
                        ": Total number of arguments mismatch with declaration in function " + $id->getText() + "\n\n"
                    );
                    syntaxErrorCount++;
                } 
        }
        else{
            writeIntoErrorFile(
                "Error at line " + to_string($ts.data.line) + 
                ": Multiple declaration of " + $id->getText() + "\n\n"
            );
            writeIntoparserLogFile(
                "Error at line " + to_string($ts.data.line) + 
                ": Multiple declaration of " + $id->getText() + "\n\n"
            );
            syntaxErrorCount++;
        }
    }
    cs=compound_statement[true] {
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
        $data.was_error = false;
        param_count++;  

        auto sb = st->lookupCurrentScope($id->getText());
        if(sb == nullptr) {
            st->insert($id->getText(), toUpperString($ts.data.text));
        } else {
            writeIntoErrorFile(
                "Error at line " + to_string($data.line) + 
                ": Multiple declaration of " + $id->getText() + " in parameter\n\n"
            );

            writeIntoparserLogFile(
                "Error at line " + to_string($data.line) + 
                ": Multiple declaration of " + $id->getText() + " in parameter\n\n"
            );

            syntaxErrorCount++;
        }

        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " parameter_list : parameter_list COMMA type_specifier ID\n\n"
        );

        writeIntoparserLogFile(
            $data.text + "\n\n"
        );

    }
    | prev_list=parameter_list cm=COMMA ts=type_specifier { 
        $data.text = $prev_list.data.text + $cm->getText() + $ts.data.text;
        $data.line = $ts.data.line;
        $data.was_error = false;
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " parameter_list : parameter_list COMMA type_specifier\n\n" +
            $data.text + "\n\n"
        );
    
    }
    |prev_list=parameter_list id=ID{
        $data.text = $prev_list.data.text;
        $data.line = $id->getLine();
        $data.was_error = true;
    }
    |pl=parameter_list ic=(ADDOP|LOGICOP|RELOP|MULOP|SUBOP|INCOP|DECOP) {
        $data.text = $pl.data.text;
        $data.line = $ic->getLine();
        $data.was_error = true;

        writeIntoErrorFile(
            "Error at line " + to_string($data.line) + 
            ": syntax error\n\n"
        );
        writeIntoparserLogFile(
            "Error at line "+to_string($data.line) + ":" +
            " syntax error\n\n"
        );
        syntaxErrorCount++;
    }
    | ts=type_specifier id=ID {
        $data.text = $ts.data.text + " " + $id->getText();
        $data.line = $id->getLine();
        param_count++;

        auto sb = st->lookupCurrentScope($id->getText());
        if(sb == nullptr) {
            st->insert($id->getText(), toUpperString($ts.data.text));
        } else {
            writeIntoErrorFile(
                "Error at line " + to_string($data.line) + 
                ": Multiple declaration of " + $id->getText() + " in parameter\n\n"
            );

            writeIntoparserLogFile(
                "Error at line " + to_string($data.line) + 
                ": Multiple declaration of " + $id->getText() + " in parameter\n\n"
            );

            syntaxErrorCount++;
        }
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " parameter_list : type_specifier ID\n\n"
        );
        
        writeIntoparserLogFile(
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
        
compound_statement[bool isFunction]
returns [ReturnData data]
	: LCURL {
        if(!isFunction){
            st->enter_scope();
            int line = $LCURL->getLine();
            cout<< "Entering scope for compound statement- > line"<< to_string(line) << endl;
            st->print_all_scope();
        }
    }
     stmts=statements RCURL  {
		$data.text = $LCURL->getText() + "\n" + $stmts.data.text + "\n" + $RCURL->getText();
		$data.line = $RCURL->getLine();
		writeIntoparserLogFile(
			"Line "+to_string($data.line) + ":" +
			" compound_statement : LCURL statements RCURL\n\n" +
			$data.text + "\n\n"
		);

        st->print_all_scope(parserLogFile);
        parserLogFile << "\n\n";
        st->exit_scope();
	}
	| LCURL{if(!isFunction)st->enter_scope();} RCURL  {
		$data.text = $LCURL->getText()+ "\n" + $RCURL->getText();
		$data.line = $RCURL->getLine();
		writeIntoparserLogFile(
			"Line "+to_string($data.line) + ":" +
			" compound_statement : LCURL RCURL\n\n" +
			$data.text + "\n\n"
		);

        st->print_all_scope(parserLogFile);
        parserLogFile << "\n\n";
        st->exit_scope();
	}
	;

            
var_declaration returns [ReturnData data]
    : t=type_specifier{current_type = toUpperString($t.data.text);} dl=declaration_list sm=SEMICOLON {
        $data.text = $t.data.text + " " + $dl.data.text + $sm->getText(); 
        $data.line = $sm->getLine(); 
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " var_declaration : type_specifier declaration_list SEMICOLON\n\n" +
            $data.text + "\n\n"
        );
      }
    ;

         
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
    :  prev_list=declaration_list cm=COMMA current_id=ID {
        $data.text = $prev_list.data.text + $cm->getText() + $current_id->getText();
        $data.line = $current_id->getLine(); 
        $data.was_error = false;


        auto sb = st->lookupCurrentScope($current_id->getText());
        if(sb == nullptr) {
            st->insert($current_id->getText(), current_type);
        } else {
            writeIntoErrorFile(
                "Error at line " + to_string($data.line) + 
                ": Multiple declaration of " + $current_id->getText() + "\n\n"
            );

            writeIntoparserLogFile(
                "Error at line " + to_string($data.line) + 
                ": Multiple declaration of " + $current_id->getText() + "\n\n"
            );
            syntaxErrorCount++;
        }

        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " declaration_list : declaration_list COMMA ID\n\n"
        );

        writeIntoparserLogFile(
            $data.text + "\n\n"
        );
    }
    | prev_list=declaration_list  ic=(ADDOP|LOGICOP|RELOP|MULOP|SUBOP|INCOP|DECOP) current_id=ID {
        $data.text = $prev_list.data.text ;
        $data.line = $ic->getLine();
        $data.was_error = true;
        if(!$prev_list.data.was_error){
            writeIntoErrorFile(
                "Error at line " + to_string($data.line) + 
                ": syntax error\n\n"
            );
            writeIntoparserLogFile(
                "Error at line " + to_string($data.line) + 
                ": syntax error\n\n"
            );
            writeIntoparserLogFile(
                $data.text + "\n\n"
            );
            syntaxErrorCount++;
        }
    }
    | prev_list_arr=declaration_list cm=COMMA current_id_arr=ID lt=LTHIRD const_val_arr=CONST_INT rt=RTHIRD {
        string currentArrText = $current_id_arr->getText() + $lt->getText() + $const_val_arr->getText() + $rt->getText();
        $data.text = $prev_list_arr.data.text + $cm->getText() + currentArrText;
        $data.line = $current_id_arr->getLine(); 
        $data.was_error = false;

        auto sb = st->lookupCurrentScope($current_id_arr->getText());
        if(sb == nullptr) {
            st->insert($current_id_arr->getText(), current_type);
            auto sb = st->lookupCurrentScope($current_id_arr->getText());
            sb->setArray(true); 
        } else {
            writeIntoErrorFile(
                "Error at line " + to_string($data.line) + 
                ": Multiple declaration of " + $current_id_arr->getText() + "\n\n"
            );

            writeIntoparserLogFile(
                "Error at line " + to_string($data.line) + 
                ": Multiple declaration of " + $current_id_arr->getText() + "\n\n"
            );
            syntaxErrorCount++;
        }

        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n\n"
        );
        writeIntoparserLogFile(
            $data.text + "\n\n"
        );
    }
    |prev_list_arr=declaration_list ic=(ADDOP|LOGICOP|RELOP|MULOP|SUBOP|INCOP|DECOP) current_id_arr=ID lt=LTHIRD const_val_arr=CONST_INT rt=RTHIRD {
        $data.text = $prev_list_arr.data.text;
        $data.line = $ic->getLine(); 
        $data.was_error = true;
        if(!$prev_list_arr.data.was_error){
            writeIntoErrorFile(
                "Error at line " + to_string($data.line) + 
                ": syntax error\n\n"
            );
            writeIntoparserLogFile(
                "Error at line " + to_string($data.line) + 
                ": syntax error\n\n"
            );
            writeIntoparserLogFile(
                $data.text + "\n\n"
            );
            syntaxErrorCount++;
        }
    }
    | ic=(ADDOP|LOGICOP|RELOP|MULOP|SUBOP|INCOP|DECOP) base_id=ID {
        $data.text = "";
        $data.line = $ic->getLine();
        $data.was_error = true;
        writeIntoErrorFile(
            "Error at line " + to_string($data.line) + 
            ": syntax error\n\n"
        );
        writeIntoparserLogFile(
            "Error at line " + to_string($data.line) + 
            ": syntax error\n\n"
        );
        writeIntoparserLogFile(
            $data.text + "\n\n"
        );
        syntaxErrorCount++;
    }
    | base_id=ID {
        $data.text = $base_id->getText();
        $data.line = $base_id->getLine();
        $data.was_error = false;

        auto sb = st->lookupCurrentScope($data.text);
        if(sb == nullptr) {
            if(current_type == "VOID") {
                writeIntoErrorFile(
                    "Error at line " + to_string($data.line) + 
                    ": Variable type cannot be void\n\n"
                );

                writeIntoparserLogFile(
                    "Error at line " + to_string($data.line) + 
                    ": Variable type cannot be void\n\n"
                );

                syntaxErrorCount++;
            }
            else 
                st->insert($data.text, current_type);
        } else {
            writeIntoErrorFile(
                "Error at line " + to_string($data.line) + 
                ": Multiple declaration of " +$data.text + "\n\n"
            );

            writeIntoparserLogFile(
                "Error at line " + to_string($data.line) + 
                ": Multiple declaration of " +$data.text + "\n\n"
            );

            syntaxErrorCount++;
        }

        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " declaration_list : ID\n\n"
        );
        writeIntoparserLogFile(
            $data.text + "\n\n"
        );
    }
    | ic=(ADDOP|LOGICOP|RELOP|MULOP|SUBOP|INCOP|DECOP) base_id_arr=ID lt=LTHIRD const_val_base_arr=CONST_INT rt=RTHIRD {
        $data.text = "";
        $data.line = $ic->getLine();
        $data.was_error = true;
        writeIntoErrorFile(
            "Error at line " + to_string($data.line) + 
            ": syntax error\n\n"
        );
        writeIntoparserLogFile(
            "Error at line " + to_string($data.line) + 
            ": syntax error\n\n"
        );
        writeIntoparserLogFile(
            $data.text + "\n\n"
        );
        syntaxErrorCount++;
    }
    | base_id_arr=ID lt=LTHIRD const_val_base_arr=CONST_INT rt=RTHIRD {
        $data.text = $base_id_arr->getText() + $lt->getText() + $const_val_base_arr->getText() + $rt->getText();
        $data.line = $base_id_arr->getLine();
        $data.was_error = false;
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " declaration_list : ID LTHIRD CONST_INT RTHIRD\n\n"
        );

        auto sb = st->lookupCurrentScope($base_id_arr->getText());
        if(sb == nullptr) {
            st->insert($base_id_arr->getText(), current_type);
            sb = st->lookupCurrentScope($base_id_arr->getText());
            sb->setArray(true);
        } else {
            writeIntoErrorFile(
                "Error at line " + to_string($data.line) + 
                ": Multiple declaration of " +$data.text + "\n\n"
            );

            writeIntoparserLogFile(
                "Error at line " + to_string($data.line) + 
                ": Multiple declaration of " +$data.text + "\n\n"
            );
            syntaxErrorCount++;
        }
        writeIntoparserLogFile(
            $data.text + "\n\n"
        );
    }
    | ic=(ADDOP|LOGICOP|RELOP|MULOP|SUBOP|INCOP|DECOP) base_id_float_arr=ID lt_float=LTHIRD const_val_float_arr=CONST_FLOAT rt_float=RTHIRD {
        $data.text = "";
        $data.line = $ic->getLine();
        $data.was_error = true;
        writeIntoErrorFile(
            "Error at line " + to_string($data.line) + 
            ": syntax error\n\n"
        );
        writeIntoparserLogFile(
            "Error at line " + to_string($data.line) + 
            ": syntax error\n\n"
        );
        writeIntoparserLogFile(
            $data.text + "\n\n"
        );
        syntaxErrorCount++;
    }

    | base_id_float_arr=ID lt_float=LTHIRD const_val_float_arr=CONST_FLOAT rt_float=RTHIRD {
        $data.text = $base_id_float_arr->getText() + $lt_float->getText() + $const_val_float_arr->getText() + $rt_float->getText();
        $data.line = $base_id_float_arr->getLine();
        writeIntoErrorFile(
            "Error at line " + to_string($data.line) +
            " : Expression inside third brackets not an integer\n\n"
        );
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " declaration_list : ID LTHIRD CONST_FLOAT RTHIRD\n\n" +
            $data.text + "\n\n"
        );
        syntaxErrorCount++;
    }
    ;

statements returns [ReturnData data]
    : prev_stmts=statements stmt=statement { 
        $data.text = $prev_stmts.data.text + "\n" + $stmt.data.text; 
        $data.line = $stmt.data.line; 
        writeIntoparserLogFile(
            "\nLine "+to_string($data.line) + ":" +
            " statements : statements statement\n\n" +
            $data.text + "\n\n\n"
        );
    }
    | stmt=statement { 
        $data = $stmt.data;
        writeIntoparserLogFile(
            "\nLine "+to_string($data.line) + ":" +
            " statements : statement\n\n" +
            $data.text + "\n\n\n"
        );
    }
    ;

statement returns [ReturnData data]
    :kw_if_else=IF lp_if_else=LPAREN expr_if_else=expression rp_if_else=RPAREN stmt_if_else=statement kw_else=ELSE stmt_else=statement {
        $data.text = $kw_if_else->getText()+" " + $lp_if_else->getText() + $expr_if_else.data.text + $rp_if_else->getText() + $stmt_if_else.data.text + " " + $kw_else->getText() + " " + $stmt_else.data.text;
        $data.line = $stmt_else.data.line;
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " statement : IF LPAREN expression RPAREN statement ELSE statement\n\n" +
            $data.text + "\n\n"
        );
    }
    | kw_if=IF lp_if=LPAREN expr_if=expression rp_if=RPAREN stmt_if=statement {
        $data.text = $kw_if->getText()+" " + $lp_if->getText() + $expr_if.data.text + $rp_if->getText()  + $stmt_if.data.text;
        $data.line = $stmt_if.data.line;
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " statement : IF LPAREN expression RPAREN statement\n\n" +
            $data.text + "\n\n"
        );
    }
    | vd=var_declaration {
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
    | cs=compound_statement[false] {
        $data = $cs.data;
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " statement : compound_statement\n\n" +
            $data.text + "\n\n\n"
        );
    }
    | fr=FOR lp=LPAREN exp1=expression_statement exp2=expression_statement exp=expression rp=RPAREN st=statement{
        $data.text = $fr->getText() + " " + $lp->getText() + $exp1.data.text + $exp2.data.text + $exp.data.text + $rp->getText() + $st.data.text;
        $data.line = $st.data.line;
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n" +
            $data.text + "\n\n"
        );
    }

    |   kw_while=WHILE lp_while=LPAREN expr_while=expression rp_while=RPAREN stmt_while=statement {
        $data.text = $kw_while->getText()+" " + $lp_while->getText() + $expr_while.data.text + $rp_while->getText() + $stmt_while.data.text;
        $data.line = $stmt_while.data.line;
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " statement : WHILE LPAREN expression RPAREN statement\n\n" +
            $data.text + "\n\n"
        );
    }
    | kw_println=PRINTLN lp_println=LPAREN id_println=ID rp_println=RPAREN sm_println=SEMICOLON {
        $data.text = $kw_println->getText() + $lp_println->getText() + $id_println->getText() + $rp_println->getText() + $sm_println->getText();
        $data.line = $sm_println->getLine();
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n"
        );
        auto sb = st->lookup($id_println->getText());
        if(sb == nullptr) {
            writeIntoErrorFile(
                "Error at line " + to_string($data.line) + 
                ": Undeclared variable " + $id_println->getText() + "\n\n"
            );
            writeIntoparserLogFile(
                "Error at line " + to_string($data.line) +
                ": Undeclared variable " + $id_println->getText() + "\n\n"
            );
            syntaxErrorCount++;
            $data.type = "UNKNOWN";
        } else if(sb->isArray()) {
            writeIntoErrorFile(
                "Error at line " + to_string($data.line) +
                ": Type mismatch, " + $id_println->getText() + " is an array\n\n"
            );
            writeIntoparserLogFile(
                "Error at line " + to_string($data.line) +
                ": Type mismatch, " + $id_println->getText() + " is an array\n\n"
            );
            syntaxErrorCount++;
            $data.type = "UNKNOWN";
        } else {
            $data.type = sb->getType();
        }
        writeIntoparserLogFile(
            $data.text + "\n\n"
        );
    }
    | kw_return=RETURN expr_return=expression sm_return=SEMICOLON {
        $data.text = $kw_return->getText() + " " + $expr_return.data.text + $sm_return->getText();
        $data.line = $sm_return->getLine();
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
    | expr=expression {
        $data.text = "";
        $data.line = $expr.data.line; 
        writeIntoErrorFile(
            "Error at line " + to_string($data.line) + 
            ": Expression not terminated with semicolon\n\n"
        );
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " expression_statement : expression\n\n" +
            $data.text + "\n\n"
        );
        syntaxErrorCount++;
    }
    ;
      
variable returns [ReturnData data]
    : id_tok=ID {
        $data.text = $id_tok->getText();
        $data.line = $id_tok->getLine();
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " variable : ID\n\n"
        );

        auto sb = st->lookup($id_tok->getText());
        if(sb == nullptr) {
            writeIntoErrorFile(
                "Error at line " + to_string($data.line) + 
                ": Undeclared variable " + $id_tok->getText() + "\n\n"
            );

            writeIntoparserLogFile(
                "Error at line " + to_string($data.line) + 
                ": Undeclared variable " + $id_tok->getText() + "\n\n"
            );

            syntaxErrorCount++;
            $data.type = "UNKNOWN";
        } else if(sb->isArray()) {
            writeIntoErrorFile(
                "Error at line " + to_string($data.line) + 
                ": Type mismatch, " + $id_tok->getText() + " is an array\n\n"
            );
            writeIntoparserLogFile(
                "Error at line " + to_string($data.line) + 
                ": Type mismatch, " + $id_tok->getText() + " is an array\n\n"
            );
            syntaxErrorCount++;
            $data.type = "UNKNOWN";
        } else {
            $data.type = sb->getType();
        }

        writeIntoparserLogFile(
            $data.text + "\n\n"
        );

    }
    | id_tok=ID lthird=LTHIRD expr=expression rthird=RTHIRD {
        $data.text = $id_tok->getText() + $lthird->getText() + $expr.data.text + $rthird->getText();
        $data.line = $id_tok->getLine();
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " variable : ID LTHIRD expression RTHIRD\n\n"
        );

        auto sb = st->lookup($id_tok->getText());
        if(sb == nullptr) {
            writeIntoErrorFile(
                "Error at line " + to_string($data.line) + 
                ": Undeclared variable " + $id_tok->getText() + "\n\n"
            );
            writeIntoparserLogFile(
                "Error at line " + to_string($data.line) + 
                ": Undeclared variable " + $id_tok->getText() + "\n\n"
            );
            syntaxErrorCount++;
            $data.type = "UNKNOWN";
        } else if(!sb->isArray()) {
            writeIntoErrorFile(
                "Error at line " + to_string($data.line) + 
                ": " + $id_tok->getText() + " not an array\n\n"
            );
            writeIntoparserLogFile(
                "Error at line " + to_string($data.line) + 
                ": " + $id_tok->getText() + " not an array\n\n"
            );
            syntaxErrorCount++;
            $data.type = "UNKNOWN";
        } else {
            $data.type = sb->getType();
        }

        if($expr.data.type != "INT") {
            writeIntoErrorFile(
                "Error at line " + to_string($data.line) +
                ": Expression inside third brackets not an integer\n\n"
            );  
            writeIntoparserLogFile(
                "Error at line " + to_string($data.line) +
                ": Expression inside third brackets not an integer\n\n"
            );
            syntaxErrorCount++;
            $data.type = "UNKNOWN";
        }

        writeIntoparserLogFile(
            $data.text + "\n\n"
        );
    }
    ;
     
expression returns [ReturnData data]
    : le=logic_expression {
        $data = $le.data;
        $data.type = $le.data.type; // Assuming logic_expression does not change type
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " expression : logic expression\n\n" +
            $data.text + "\n\n"
        );
    }
    | v=variable op=ASSIGNOP le=logic_expression {
        $data.text = $v.data.text  + $op->getText() + $le.data.text;
        $data.line = $v.data.line; 
        $data.type = $le.data.type;
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " expression : variable ASSIGNOP logic_expression\n\n"
        );

        if($v.data.type != "UNKNOWN" && $le.data.type != "UNKNOWN"){ 
            if( $le.data.type == "VOID"){
                writeIntoErrorFile(
                    "Error at line " + to_string($data.line) + 
                    ": Void function used in expression\n\n"
                );
                writeIntoparserLogFile(
                    "Error at line " + to_string($data.line) + 
                    ": Void function used in expression\n\n"
                );
                syntaxErrorCount++;
                $data.type = "UNKNOWN";
            }else if($v.data.type == "INT" && $le.data.type != "INT") {
                auto sb = st->lookup($v.data.text);
                writeIntoErrorFile(
                    "Error at line " + to_string($data.line) + 
                    ": Type Mismatch\n\n"
                );
                writeIntoparserLogFile(
                    "Error at line " + to_string($data.line) + 
                    ": Type Mismatch\n\n"
                );
                syntaxErrorCount++;
                $data.type = "UNKNOWN";
            }
        } else if($v.data.type == "UNKNOWN" || $le.data.type == "UNKNOWN") {
            $data.type = "UNKNOWN";
        }
        writeIntoparserLogFile(
            $data.text + "\n\n"
        );
    }
    ;
            
logic_expression returns [ReturnData data]
    : re=rel_expression {
        $data = $re.data;
        $data.type = $re.data.type; // Assuming rel_expression does not change type
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " logic_expression : rel_expression\n\n" +
            $data.text + "\n\n"
        );
    }
    | re1=rel_expression op=LOGICOP re2=rel_expression {
        $data.text = $re1.data.text  + $op->getText()+ $re2.data.text;
        $data.line = $re1.data.line; 
        if($re1.data.type == "UNKNOWN" || $re2.data.type == "UNKNOWN") {
            $data.type = "UNKNOWN";
        } else {
            $data.type = "INT"; 
        }
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
        $data.type = $se.data.type; // Assuming simple_expression does not change type
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " rel_expression : simple_expression\n\n" +
            $data.text + "\n\n"
        );
    }
    | se1=simple_expression op=RELOP se2=simple_expression {
        $data.text = $se1.data.text  + $op->getText() + $se2.data.text;
        $data.line = $se1.data.line; 
        //will do it later
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
        $data.type = $t.data.type; // Assuming term does not change type
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " simple_expression : term\n\n" +
            $data.text + "\n\n"
        );
    }
    | se=simple_expression op=ADDOP t=term {
        $data.text = $se.data.text + $op->getText() + $t.data.text;
        $data.line = $se.data.line; 
        if($se.data.type == "INT" && $t.data.type == "INT") {
            $data.type = "INT";
        } else if($se.data.type == "FLOAT" || $t.data.type == "FLOAT") {
            $data.type = "FLOAT";
        } else {
            $data.type = "UNKNOWN";
        }
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " simple_expression : simple_expression ADDOP term\n\n" +
            $data.text + "\n\n"
        );
    }
    | se=simple_expression op=(ADDOP|SUBOP|MULOP) (ASSIGNOP){
        $data.text = $se.data.text + $op->getText() ;
        $data.line = $se.data.line; 
        $data.type = "UNKNOWN"; // Assignment with ADDP, SUBOP, or MULOP is not valid in simple_expression
        writeIntoErrorFile(
            "Error at line " + to_string($data.line) + ":" +
            " syntax error,unexpected ASSIGNOP\n\n" 
        );
        writeIntoparserLogFile(
            "Error at line " + to_string($data.line) + ":" +
            " syntax error,unexpected ASSIGNOP\n\n" 
        );
        syntaxErrorCount++;
    }
    ;
                    
term returns [ReturnData data]
    : ue=unary_expression {
        $data = $ue.data;
        $data.type = $ue.data.type;
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
            " term : term MULOP unary_expression\n\n"
        );

        if($t.data.type == "INT" && $ue.data.type == "INT") {
            $data.type = "INT";
        } else if($t.data.type == "FLOAT" || $ue.data.type == "FLOAT") {
            $data.type = "FLOAT";
        } else {
            $data.type = "UNKNOWN";
        }

        if($ue.data.type == "VOID") {
            writeIntoErrorFile(
                "Error at line " + to_string($data.line) + 
                ": Void function used in expression\n\n"
            );
            writeIntoparserLogFile(
                "Error at line " + to_string($data.line) + 
                ": Void function used in expression\n\n"
            );
            syntaxErrorCount++;
            $data.type = "UNKNOWN";
        } else {
            if($op->getText() == "%") {
                if($ue.data.type != "INT") {
                    writeIntoErrorFile(
                        "Error at line " + to_string($data.line) + 
                        ": Non-Integer operand on modulus operator\n\n"
                    );
                    writeIntoparserLogFile(
                        "Error at line " + to_string($data.line) + 
                        ": Non-Integer operand on modulus operator\n\n"
                    );
                    syntaxErrorCount++;
                    $data.type = "UNKNOWN";
                } else if( stoi($ue.data.text) == 0) {
                    writeIntoErrorFile(
                        "Error at line " + to_string($data.line) + 
                        ": Modulus by Zero\n\n"
                    );
                    writeIntoparserLogFile(
                        "Error at line " + to_string($data.line) + 
                        ": Modulus by Zero\n\n"
                    );
                    syntaxErrorCount++;
                    $data.type = "UNKNOWN";
                }
            }
        }

        writeIntoparserLogFile(
            $data.text + "\n\n"
        );
    }
    ;

unary_expression returns [ReturnData data]
    : op=ADDOP ue=unary_expression { 
        $data.text = $op->getText() + $ue.data.text; 
        $data.line = $op->getLine();
        $data.type = $ue.data.type;
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " unary_expression : ADDOP unary_expression\n\n"
        );
        
        if($ue.data.type == "VOID") {
            writeIntoErrorFile(
                "Error at line " + to_string($data.line) + 
                ": Void function used in expression\n\n"
            );
            writeIntoparserLogFile(
                "Error at line " + to_string($data.line) + 
                ": Void function used in expression\n\n"
            );
            $data.type = "UNKNOWN";
            syntaxErrorCount++;
        }

        writeIntoparserLogFile(
            $data.text + "\n\n"
        );
    }
    | op_not=NOT ue=unary_expression { 
        $data.text = $op_not->getText() + $ue.data.text; 
        $data.line = $op_not->getLine();
        $data.type = $ue.data.type; 
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " unary_expression : NOT unary expression\n\n"
        );

        if($ue.data.type != "INT" && $ue.data.type != "UNKNOWN") {
            writeIntoErrorFile(
                "Error at line " + to_string($data.line) + 
                ": Non-Integer operand on NOT operator\n\n"
            );
            writeIntoparserLogFile(
                "Error at line " + to_string($data.line) + 
                ": Non-Integer operand on NOT operator\n\n"
            );
            syntaxErrorCount++;
            $data.type = "UNKNOWN";
        }
        writeIntoparserLogFile(
            $data.text + "\n\n"
        );
    }
    | f=factor { 
        $data = $f.data; 
        $data.type = $f.data.type;
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " unary_expression : factor\n\n" +
            $data.text + "\n\n"
        );
    }
    ;
    
factor returns [ReturnData data]
    : v=variable {
        $data = $v.data;
        $data.type = $v.data.type;
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " factor : variable\n\n" +
            $data.text + "\n\n"
        );
    }
    | id_tok=ID lp=LPAREN al=argument_list[$id_tok->getText()] rp=RPAREN {
        $data.text = $id_tok->getText() + $lp->getText() + ($al.ctx ? $al.data.text : "") + $rp->getText();
        $data.line = $id_tok->getLine();
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " factor : ID LPAREN argument_list RPAREN\n\n"
        );

        auto sb = st->lookup($id_tok->getText());
        if(sb == nullptr) {
            //hook for undefined function call 
            writeIntoErrorFile(
                "Error at line " + to_string($data.line) + 
                ": Undeclared function " + $id_tok->getText() + "\n\n"
            );
            writeIntoparserLogFile(
                "Error at line " + to_string($data.line) + 
                ": Undeclared function " + $id_tok->getText() + "\n\n"
            );
            syntaxErrorCount++;
            $data.type = "UNKNOWN";
        } else if(sb->isFunction()) {
            if(!sb->isDefined()) {
                //hook for checking error
            } else {
                //hook for checking if the defined prototype matches the declaration
                //no checking for simplicity
                $data.type = sb->getReturnType();
                auto params = sb->getParameters();
                if(params.size() != args.size()) {
                    writeIntoErrorFile(
                        "Error at line " + to_string($data.line) + 
                        ": Total number of arguments mismatch in function " + $id_tok->getText() + "\n\n"
                    );
                    writeIntoparserLogFile(
                        "Error at line " + to_string($data.line) + 
                        ": Total number of arguments mismatch in function " + $id_tok->getText() + "\n\n"
                    );
                    syntaxErrorCount++;
                } else {
                    for(size_t i = 0; i < params.size(); ++i) {
                        if(args[i].type == "UNKNOWN" || params[i].first == "UNKNOWN" ||( args[i].type == "INT" && params[i].first == "FLOAT")) {
                            continue;
                        }
                        if(params[i].first == "VOID") {
                            writeIntoErrorFile(
                                "Error at line " + to_string($data.line) + 
                                ": Void function used in expression\n\n"
                            );
                            writeIntoparserLogFile(
                                "Error at line " + to_string($data.line) + 
                                ": Void function used in expression\n\n"
                            );
                            syntaxErrorCount++;
                            break;
                        }

                        if(params[i].first != args[i].type) {
                            writeIntoErrorFile(
                                "Error at line " + to_string($data.line) + 
                                ": " + to_string(i+1) + "th argument mismatch in function " + $id_tok->getText() + "\n\n"
                            );
                            writeIntoparserLogFile(
                                "Error at line " + to_string($data.line) + 
                                ": " + to_string(i+1) + "th argument mismatch in function " + $id_tok->getText() + "\n\n"
                            );
                            syntaxErrorCount++;
                            break;
                            if(i == params.size() - 1) {
                                $data.type = sb->getReturnType();
                            }
                        }
                    }
                }
            }
        } else {
            writeIntoErrorFile(
                "Error at line " + to_string($data.line) + 
                ": " + $id_tok->getText() + " is not a function\n\n"
            );

            writeIntoparserLogFile(
                "Error at line " + to_string($data.line) + 
                ": " + $id_tok->getText() + " is not a function\n\n"
            );
            syntaxErrorCount++;
            $data.type = "UNKNOWN";
        }
        args.clear();
        writeIntoparserLogFile(
            $data.text + "\n\n"
        );
    }
    | lp=LPAREN expr_val=expression rp=RPAREN {
        $data.text = $lp->getText() + $expr_val.data.text + $rp->getText();
        $data.line = $lp->getLine();
        $data.type = $expr_val.data.type;
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " factor : LPAREN expression RPAREN\n\n" +
            $data.text + "\n\n"
        );
    }
    | tok=CONST_INT {
        $data.text = $tok->getText();
        $data.line = $tok->getLine();
        $data.type = "INT";
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " factor : CONST_INT\n\n" +
            $data.text + "\n\n"
        );
    }
    | tok=CONST_FLOAT {
        $data.text = $tok->getText();
        $data.line = $tok->getLine();
        $data.type = "FLOAT";
        if($data.text.back() != '0')
            $data.text.push_back('0');
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " factor : CONST_FLOAT\n\n" +
            $data.text + "\n\n"
        );
    }
    | v=variable op=INCOP {
        $data.text = $v.data.text + $op->getText();
        $data.line = $v.data.line;
        $data.type = $v.data.type;
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " factor : variable INCOP\n\n" +
            $data.text + "\n\n"
        );
    }
    | v=variable op=DECOP {
        $data.text = $v.data.text + $op->getText();
        $data.line = $v.data.line;
        $data.type = $v.data.type;
        writeIntoparserLogFile(
            "Line "+to_string($data.line) + ":" +
            " factor : variable DECOP\n\n" +
            $data.text + "\n\n"
        );
    }
    ;
    
argument_list[string func_name]
 returns [ReturnData data]
    : args=arguments {
        $data = $args.data;
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " argument_list : arguments\n\n" +
            $data.text + "\n\n"
        );
    }
    | { 
        // $data.text = "";
        // $data.line = 0; 
        // auto sb = st->lookup(func_name);
        // if(sb == nullptr) {
        //     writeIntoErrorFile(
        //         "Error at line " + to_string($data.line) +
        //         ": Function " + func_name + " not declared\n\n"
        //     );
        // } else if(sb->isFunction()) {
        //     if(!sb->isDefined()) {
        //         writeIntoErrorFile(
        //             "Error at line " + to_string($data.line) +
        //             ": Function " + func_name + " not defined\n\n"
        //         );
        //     } else {
        //         auto params = sb->getParameters();
                
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
        args.push_back($le.data);
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " arguments : arguments COMMA logic_expression\n\n" +
            $data.text + "\n\n"
        );
    }
    | le=logic_expression { 
        $data = $le.data; 
        args.push_back($le.data);
        writeIntoparserLogFile(
            "Line " + to_string($data.line) + ":" +
            " arguments : logic_expression\n\n" +
            $data.text + "\n\n"
        );
    }
    ;