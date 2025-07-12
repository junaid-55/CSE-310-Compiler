#ifndef LABEL_H
#define LABEL_H

#include <string>
using namespace std;
class Label {
    int id;
public:
    Label(int id= 0){
        this->id = id;
    };
    string getNextLabel() {
        return "L" + to_string(++id);
    };
    string getCurrentLabel() {
        return "L" + to_string(id);
    };
    string getSkippedLabel(int skip = 2) {
        return "L" + to_string(id + skip);
    };
};

#endif