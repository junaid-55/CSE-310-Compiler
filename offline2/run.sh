#!/usr/bin/bash

file="draft.l"
# powershell.exe -NoProfile -Command "flex '$file'"
echo "Compiling $file"
flex $file
if [ -f "lex.yy.c" ]; then
  g++ lex.yy.c -o test
  rm lex.yy.c
  ./test input.txt
fi
rm test