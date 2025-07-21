#include <vector>
#include <string>
#include <map>
#include <algorithm>
#include <fstream>
#include <sstream>
using namespace std;
class Optimizer
{
    vector<string> code;
    map<string, int> labels;
    string inputFile;
    string outputFile;
public:
    Optimizer(string input, string output)
    {
        inputFile = input;
        outputFile = output;
        ifstream file(input);
        string line;
        while (getline(file, line))
            code.push_back(line);
        file.close();
    }
    void optimize()
    {
        // removeRedundantLabels();
        // removeUnreachableCode();
        code =  removeRedundantPushes();
        ofstream out(outputFile);
        for (const auto &line : code)
            out << line << endl;
        out.close();
    }
    void removeRedundantLabels()
    {
        vector<string> optimizedCode;
        for (const auto &line : code)
        {
            if (line.find(":") != string::npos)
            {
                string label = line.substr(0, line.find(":"));
                if (labels.find(label) == labels.end())
                {
                    labels[label] = optimizedCode.size();
                    optimizedCode.push_back(line);
                }
            }
            else
            {
                optimizedCode.push_back(line);
            }
        }
        code = optimizedCode;
    }
    vector<string> removeRedundantPushes()
    {
        vector<string> optimizedCode;

        for (int i = 0; i < code.size(); ++i)
        {
            string currentLine = code[i];
            if (i + 1 < code.size() &&
                currentLine.find("PUSH") != string::npos &&
                code[i + 1].find("POP") != string::npos)
            {
                string pushReg = extractRegister(currentLine);
                string popReg = extractRegister(code[i + 1]);

                if (pushReg == popReg)
                {
                    ++i;
                    continue;
                }
            }
            optimizedCode.push_back(currentLine);
        }
        return optimizedCode;
    }

    string extractRegister(const string &instruction)
    {
        stringstream ss(instruction);
        string ins, reg;
        ss >> ins >> reg;
        return reg;
    }
};