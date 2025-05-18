#!/usr/bin/bash


file="main.l"
# for windows
# powershell.exe -NoProfile -Command "flex '$file'"

# for linux
flex $file

flex $file
if [ -f "lex.yy.c" ]; then
  g++ -fsanitize=address lex.yy.c -o test
  rm lex.yy.c
  ./test input.txt   
fi
rm test