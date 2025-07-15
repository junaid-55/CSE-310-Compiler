antlr4 -v 4.13.2 -Dlanguage=Cpp C2105006Lexer.g4
antlr4 -v 4.13.2 -Dlanguage=Cpp C2105006Parser.g4

g++ -std=c++17 -w -I/usr/local/include/antlr4-runtime -c C2105006Lexer.cpp C2105006Parser.cpp main.cpp headers/symbol_table.cpp  headers/hash.cpp
g++ -std=c++17 -w C2105006Lexer.o C2105006Parser.o main.o symbol_table.o hash.o -L/usr/local/lib/ -lantlr4-runtime -o main.out -pthread

# if no argument is provided, use test.c as default
if [ -z "$1" ]; then
    LD_LIBRARY_PATH=/usr/local/lib ./main.out test.c
else
    # if an argument is provided, use it as the input file
    LD_LIBRARY_PATH=/usr/local/lib ./main.out "$1"
fi
python mod.py output/code.asm
# Cleanup
bash clean.sh
