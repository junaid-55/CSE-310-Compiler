#include "2105006_symbol_table.hpp"


int main(int argc, char *argv[])
{
    if (argc < 3)
    {
        cout << "Usage: ./symbol <input_file> <output_file>" << endl;
        return 1;
    }

    freopen(argv[1], "r", stdin);
    freopen(argv[2], "w", stdout);

    string hash_function = "SDMB";
    if (argc == 4)
    {
        hash_function = argv[3];
        if (hash_function != "DJB2" && hash_function != "FNV" && hash_function != "SDBM")
        {
            cout << "Invalid hash function. Using default SDBM." << endl;
            hash_function = "SDBM";
        }
    }
    int n, cmd_count = 0;
    cin >> n;
    cin.ignore();
    SymbolTable *table = new SymbolTable(n, hash_function);
    while (true)
    {
        char option;
        int count = 0;
        string line, token;
        getline(cin, line);
        istringstream stream(line), temp_stream(line);
        while (stream >> token)
            count++;
        stream.clear();
        stream.str(line);
        stream >> option;
        cout << "Cmd " << ++cmd_count << ":";
        while (temp_stream >> token)
            cout << " " << token;
        cout << endl;
        switch (option)
        {
        case 'I': // Insert a symbol
        {
            if (count < 3)
            {
                cout << "\tNumber of parameters mismatch for the command I" << endl;
                continue;
            }
            string name, type;
            stream >> name >> type;
            if (type == "STRUCT" || type == "UNION")
            {
                if (count % 2 == 0)
                {
                    cout << "\tNumber of parameters mismatch for the command I" << endl;
                    continue;
                }

                while (stream >> token)
                    type += " " + token;
            }
            else if (type == "FUNCTION")
            {
                while (stream >> token)
                    type += " " + token;
            }
            table->insert(name, type);
            break;
        }
        case 'L': // Lookup a symbol
        {
            if (count != 2)
            {
                cout << "\tNumber of parameters mismatch for the command L" << endl;
                continue;
            }
            string name;
            stream >> name;
            SymbolInfo *symbol = table->lookup(name);
            break;
        }
        case 'D': // Delete a symbol
        {
            if (count != 2)
            {
                cout << "\tNumber of parameters mismatch for the command D" << endl;
                continue;
            }
            string name;
            stream >> name;
            table->delete_symbol(name);
            break;
        }
        case 'P': // Print scope table
        {
            if (count != 2)
            {
                cout << "\tNumber of parameters mismatch for the command P" << endl;
                continue;
            }
            string choice;
            stream >> choice;
            if (choice == "C") // Print current scope
                table->print_current_scope();
            else if (choice == "A") // Print all scopes
                table->print_all_scope();
            else
                cout << "\tNumber of parameters mismatch for the command" << endl;
            break;
        }
        case 'S': // Enter a new scope
        {
            if (count != 1)
            {
                cout << "\tNumber of parameters mismatch for the command S" << endl;
                continue;
            }
            table->enter_scope();
            break;
        }
        case 'E': // Exit the current scope
        {
            if (count != 1)
            {
                cout << "\tNumber of parameters mismatch for the command E" << endl;
                continue;
            }
            table->exit_scope();
            break;
        }
        case 'Q': // Quit the program
        {
            if (count != 1)
            {
                cout << "\tNumber of parameters mismatch for the command Q" << endl;
                continue;
            }
            table->delete_all_scope();
            delete table;
            return 0;
        }
        default:
            cout << "\tNumber of parameters mismatch for the command" << endl;
            break;
        }
    }
}
