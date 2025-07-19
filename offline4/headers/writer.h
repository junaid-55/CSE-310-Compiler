#include <string>
#include <iostream>
#include <fstream>
#include <vector>
#include <limits>
using namespace std;
class Writer {
    string filename;
    ofstream file;
public:
    Writer(string filename) : filename(filename) {
        // Open in append mode to avoid truncating the file on creation
        file.open(filename, ios::out | ios::app);
        if (!file.is_open()) {
            cerr << "Error opening file: " << filename << endl;
        } 
    }

    ~Writer() {
        if (file.is_open()) {
            file.close();
        }
    }

    void write(const string& data) {
        if (file.is_open()) {
            file << data << "\n";
        }
    }

    void writeAtLine(const string& data, int line) {
        if (file.is_open()) {
            file.close();
        }
        
        vector<string> lines;
        ifstream in(filename);
        if (!in.is_open()) {
            cerr << "Error opening file for reading: " << filename << endl;
            // Re-open file in append mode to restore state
            file.open(filename, ios::out | ios::app);
            return;
        }

        string current_line;
        while (getline(in, current_line)) {
            lines.push_back(current_line);
        }
        in.close();

        if (line > 0 && line <= lines.size()) {
            lines[line - 1] = data;
        } else {
            cerr << "Error: Line " << line << " is out of bounds." << endl;
            // Re-open file in append mode to restore state
            file.open(filename, ios::out | ios::app);
            return;
        }

        ofstream out(filename, ofstream::trunc);
        if (!out.is_open()) {
            cerr << "Error opening file for writing: " << filename << endl;
            // Re-open file in append mode to restore state
            file.open(filename, ios::out | ios::app);
            return;
        }

        for (const auto& l : lines) {
            out << l << '\n';
        }
        out.close();

        // Re-open file in append mode to allow subsequent writes
        file.open(filename, ios::out | ios::app);
    }

    void write(const vector<string>& data) {
        for (const auto& item : data) {
            write(item);
        }
    }
};