#ifndef RETURN_DATA_H
#define RETURN_DATA_H

#include <string>
using namespace std;
struct ReturnData {
    string text; 
    int line;
    string type;
    int argument_count;bool was_error = false;
    ReturnData() : text(""), line(0), type("UNKNOWN"), argument_count(0) {}
    void reset() {
        text = "";
        line = 0;
        type = "UNKNOWN";
        argument_count = 0;
    }
    void setError(){
        was_error = true;
    }
};

#endif 