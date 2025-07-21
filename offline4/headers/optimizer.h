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
        code = removeRedundantPushes();
        code = removeSelfAssignment();
        code = removeRedundantLabels();
        ofstream out(outputFile);
        for (const auto &line : code)
            out << line << endl;
        out.close();
    }

    vector<string> removeSelfAssignment()
    {
        vector<string> new_code;
        string prev_dest = "", prev_src = "";
        for (const auto &line : code)
        {
            if (line.find("MOV") != string::npos)
            {
                int movPos = line.find("MOV");
                if (movPos != string::npos)
                {
                    string rest = line.substr(movPos + 3);
                    int commaPos = rest.find(',');
                    if (commaPos != string::npos)
                    {
                        string dest = rest.substr(0, commaPos);
                        string src = rest.substr(commaPos + 1);

                        dest.erase(0, dest.find_first_not_of(" \t"));
                        dest.erase(dest.find_last_not_of(" \t") + 1);
                        src.erase(0, src.find_first_not_of(" \t"));

                        int commentPos = src.find(';');
                        if (commentPos != string::npos)
                            src = src.substr(0, commentPos);
                        src.erase(src.find_last_not_of(" \t") + 1);

                        if (!prev_dest.empty() && !prev_src.empty() &&
                            prev_dest == src && prev_src == dest && !new_code.empty())
                        {
                            new_code.pop_back();
                            prev_dest = "";
                            prev_src = "";
                            continue;
                        }
                        else
                        {
                            prev_dest = dest;
                            prev_src = src;
                        }
                    }
                }
            }
            else
            {
                prev_dest = "";
                prev_src = "";
            }
            new_code.push_back(line);
        }
        return new_code;
    }

    vector<string> removeRedundantLabels()
    {
        map<string, bool> labels;
        vector<string> label_buffer;
        vector<string> new_code;
        for(int i= 0; i< code.size(); i++)
        {
            auto label = jumpLabel(code[i]);
            if (label != "")
               labels[label] = true;
        }
        for (int i = 0; i < code.size(); i++)
        {
            string currentLine = code[i];
            if (currentLine.find(":") != string::npos)
            {
                string label = currentLine.substr(0, currentLine.find(":"));
                label_buffer.push_back(label);
            }
            else
            {
                if ((label_buffer.size() == 1 && currentLine.find("ENDP") == string::npos) || (!label_buffer.empty() && labels[label_buffer[0]]))
                    new_code.push_back(label_buffer[0] + ":");
                else if (label_buffer.size() > 1)
                {
                    bool isadded = false;
                    for (int j = 0; j < label_buffer.size(); j++)
                    {
                        string lbl = label_buffer[j];
                        if (labels[lbl])
                        {
                            new_code.push_back(lbl + ":");
                            isadded = true;
                        }
                    }
                    if (!isadded && currentLine.find("ENDP") == string::npos)
                        new_code.push_back(label_buffer[0] + ":");
                }
                label_buffer.clear();
                new_code.push_back(currentLine);
            }
        }
        return new_code;
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

    string jumpLabel(const string &instruction)
    {
        if (instruction.find("JMP") != string::npos || instruction.find("JZ") != string::npos ||
            instruction.find("JNZ") != string::npos || instruction.find("JE") != string::npos ||
            instruction.find("JNE") != string::npos || instruction.find("JG") != string::npos ||
            instruction.find("JL") != string::npos || instruction.find("JGE") != string::npos ||
            instruction.find("JLE") != string::npos)
        {
            stringstream ss(instruction);
            string ins, label;
            ss >> ins >> label;
            return label;
        }
        return "";
    }
};