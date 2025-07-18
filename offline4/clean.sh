#!/bin/bash

# Enable extended globbing for pattern matching
shopt -s extglob

# Loop through all files that do NOT match *.sh, *.g4, or main.cpp
for file in !(*.sh|*.g4|*.asm|*.py|test.c|Listener.h|main.cpp|return_data.hpp); do
    # Only delete if it's a regular file
    if [[ -f "$file" ]]; then
        rm -f "$file"
    fi
done

