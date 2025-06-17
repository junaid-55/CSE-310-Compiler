antlr4 -v 4.13.2 -Dlanguage=Cpp C8086Lexer.g4
antlr4 -v 4.13.2 -Dlanguage=Cpp C8086Parser.g4
g++ -std=c++17 -w -I/usr/local/include/antlr4-runtime -c C8086Lexer.cpp C8086Parser.cpp main.cpp
g++ -std=c++17 -w C8086Lexer.o C8086Parser.o main.o -L/usr/local/lib/ -lantlr4-runtime -o main.out -pthread
if [ -z "$1" ]; then
    LD_LIBRARY_PATH=/usr/local/lib ./main.out input/test.c
else
    LD_LIBRARY_PATH=/usr/local/lib ./main.out "$1"
fi
bash clean.sh