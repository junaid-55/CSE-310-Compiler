#ifndef RETURN_DATA_H
#define RETURN_DATA_H

#include <string>
using namespace std;
struct ReturnData {
    string text; 
    int line;
    string type;
    int argument_count;
    ReturnData() : text(""), line(0), type("UNKNOWN"), argument_count(0) {}
    void reset() {
        text = "";
        line = 0;
        type = "UNKNOWN";
        argument_count = 0;
    }
};

#endif 