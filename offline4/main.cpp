#include <iostream>
#include <fstream>
#include <string>
#include "antlr4-runtime.h"
#include "C2105006Lexer.h"
#include "C2105006Parser.h"
#include "Listener.h" 
using namespace antlr4;
using namespace std;

ofstream parserLogFile; // global output stream
ofstream errorFile; // global error stream
ofstream lexLogFile; // global lexer log stream
ofstream asmFile; // global assembly output stream

int syntaxErrorCount = 0;

int main(int argc, const char* argv[]) {
    if (argc < 2) {
        cerr << "Usage: " << argv[0] << " <input_file>" << endl;
        return 1;
    }

    // ---- Input File ----
    ifstream inputFile(argv[1]);
    if (!inputFile.is_open()) {
        cerr << "Error opening input file: " << argv[1] << endl;
        return 1;
    }

    string outputDirectory = "output/";
    string parserLogFileName = outputDirectory + "log.txt";
    string errorFileName = outputDirectory + "error.txt";
    string lexLogFileName = outputDirectory + "lexer.txt";
    string asmFileName = outputDirectory + "code.asm";

    // create output directory if it doesn't exist
    system(("mkdir -p " + outputDirectory).c_str());

    // ---- Output Files ----
    parserLogFile.open(parserLogFileName);
    if (!parserLogFile.is_open()) {
        cerr << "Error opening parser log file: " << parserLogFileName << endl;
        return 1;
    }

    errorFile.open(errorFileName);
    if (!errorFile.is_open()) {
        cerr << "Error opening error log file: " << errorFileName << endl;
        return 1;
    }

    lexLogFile.open(lexLogFileName);
    if (!lexLogFile.is_open()) {
        cerr << "Error opening lexer log file: " << lexLogFileName << endl;
        return 1;
    }

    asmFile.open(asmFileName);
    if (!asmFile.is_open()) {
        cerr << "Error opening assembly output file: " << asmFileName << endl;
        return 1;
    }
   
    // ---- Parsing Flow ----
    ANTLRInputStream input(inputFile);
    C2105006Lexer lexer(&input);
    CommonTokenStream tokens(&lexer);
    C2105006Parser parser(&tokens);

    // this is necessary to avoid the default error listener and use our custom error handling
    parser.removeErrorListeners();

    try {
        // start parsing at the 'start' rule
        auto tree = parser.start();
        
        // Create and use the listener
        // MyASMListener myListener;
        // antlr4::tree::ParseTreeWalker walker;
        // walker.walk(&myListener, tree);
        
    } catch (const exception& e) {
        cerr << "Parsing error: " << e.what() << endl;
        syntaxErrorCount++;
    }

    // clean up
    inputFile.close();
    parserLogFile.close();
    errorFile.close();
    lexLogFile.close();
    
    return (syntaxErrorCount > 0) ? 1 : 0;
}