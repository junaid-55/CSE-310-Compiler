#include <sstream> // For std::istringstream
#include <iostream>
#include <vector>
using namespace std;


// struct TOKEN
// {
//     string token;
//     TOKEN *next;
//     TOKEN(string token)
//     {
//         this->token = token;
//         this->next = NULL;
//     }
//     ~TOKEN()
//     {
//         delete next;
//     }
// };


// void line_parser(string line)
// {
//     vector<string> tokens;
//     istringstream stream(line);
//     string token;
//     int count = 0;

//     while (stream >> token)
//     {
//         count++;
//     }

//     cout << count << endl;
// }
// pair<string *, int> parser(string line)
// {
//     TOKEN *tokens = NULL, *ptr = NULL;
//     string token = "";
//     for (char c : line)
//     {
//         if (c != ' ')
//             token += c;
//         else
//         {
//             if (token == "")
//                 continue;
//             TOKEN *new_token = new TOKEN(token);
//             if (tokens == NULL)
//             {
//                 tokens = new_token;
//                 ptr = tokens;
//             }
//             else
//             {
//                 ptr = new_token;
//                 ptr = ptr->next;
//             }
//             token = "";
//         }
//     }
//     if (token != "")
//     {
//         TOKEN *new_token = new TOKEN(token);
//         if (tokens == NULL)
//         {
//             tokens = new_token;
//         }
//         else
//         {
//             ptr->next = new_token;
//         }
//     }

//     int count = 0, i = 0;
//     ptr = tokens;
//     while (ptr != NULL)
//     {
//         ptr = ptr->next;
//         count++;
//     }
//     if (count == 0)
//         return {NULL, 0};

//     string arr[count];
//     while (ptr != NULL)
//     {
//         arr[i] = ptr->token;
//         TOKEN *temp = ptr;
//         ptr = ptr->next;
//         delete temp;
//     }

//     return {arr, count};
// }

vector<string> line_parser(string line)
{
    vector<string> tokens;
    string token = "";
    for (char c : line)
    {
        if (c != ' ')
            token += c;
        else
        {
            if (token == "")
                continue;
            tokens.push_back(token);
            token = "";
        }
    }
    if (token != "")
        tokens.push_back(token);
    return tokens;
}

int main()
{
    int n;
    cin >> n;
    cin.ignore();
    for (int i = 0; i < n; i++)
    {
        string line;
        getline(cin, line);
        line_parser(line);
    }
}