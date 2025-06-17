// filepath: /workspaces/CSE-310-Compiler/offline3/cpp/return_data.h
#ifndef RETURN_DATA_H
#define RETURN_DATA_H

#include <string> // Required for std::string

struct ReturnData {
    std::string text; // Use std::string for clarity
    int line;
};

#endif // RETURN_DATA_H