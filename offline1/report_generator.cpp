#include "symbol_table.hpp"
#include <fstream>

int main(int argc, char *argv[])
{
    if (argc < 3)
    {
        cout << "Usage: ./symbol <input_file> <output_file>" << endl;
        return 1;
    }
    freopen(argv[1], "r", stdin);
    ofstream out;
    out.open("report.txt");

    int n, cmd_count = 0;
    cin >> n;
    cin.ignore();
    SymbolTable *sdbm_table = new SymbolTable(n, "SDBM");
    SymbolTable *djb2_table = new SymbolTable(n, "DJB2");
    SymbolTable *fnv1a_table = new SymbolTable(n, "FNV1A");

    out << "Bucket size: " << n << endl;

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
            sdbm_table->insert(name, type);
            djb2_table->insert(name, type);
            fnv1a_table->insert(name, type);
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
            SymbolInfo *symbol = sdbm_table->lookup(name);
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
            sdbm_table->delete_symbol(name);
            djb2_table->delete_symbol(name);
            fnv1a_table->delete_symbol(name);
            break;
        }
        case 'P': // Print scope sdbm_table
        {
            if (count != 2)
            {
                cout << "\tNumber of parameters mismatch for the command P" << endl;
                continue;
            }
            string choice;
            stream >> choice;
            if (choice == "C") // Print current scope
                sdbm_table->print_current_scope();
            else if (choice == "A") // Print all scopes
                sdbm_table->print_all_scope();
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
            sdbm_table->enter_scope();
            djb2_table->enter_scope();
            fnv1a_table->enter_scope();
            break;
        }
        case 'E': // Exit the current scope
        {
            if (count != 1)
            {
                cout << "\tNumber of parameters mismatch for the command E" << endl;
                continue;
            }
            sdbm_table->exit_scope();
            djb2_table->exit_scope();
            fnv1a_table->exit_scope();
            break;
        }
        case 'Q': // Quit the program
        {
            if (count != 1)
            {
                cout << "\tNumber of parameters mismatch for the command Q" << endl;
                continue;
            }
            sdbm_table->delete_all_scope();
            djb2_table->delete_all_scope();
            fnv1a_table->delete_all_scope();
            goto exit_loop;
        }
        default:
            cout << "\tNumber of parameters mismatch for the command" << endl;
            break;
        }
    }
    exit_loop:
    Hash_analysis *sdbm = sdbm_table->get_hash_analyser();
    Hash_analysis *djb2 = djb2_table->get_hash_analyser();
    Hash_analysis *fnv1a = fnv1a_table->get_hash_analyser();

    out << "Number of total insertion in each table: " << sdbm->total_inserted << endl
        << endl;

    out << "Hash function: sdbm" << endl;
    out << "Number of collision: " << sdbm->collision_count << endl;
    out << "Mean ratio: " << (1.0 * sdbm->collision_count / (sdbm->bucket_size * sdbm->scope_count)) << endl
        << endl;

    out << "Hash function: DJB2" << endl;
    out << "Number of collision: " << djb2->collision_count << endl;
    out << "Mean ratio: " << (1.0 * djb2->collision_count / (djb2->bucket_size * djb2->scope_count)) << endl
        << endl;

    out << "Hash function: FNV1A" << endl;
    out << "Number of collision: " << fnv1a->collision_count << endl;
    out << "Mean ratio: " << (1.0 * fnv1a->collision_count / (fnv1a->bucket_size * fnv1a->scope_count)) << endl
        << endl;
        
    delete sdbm_table;
    delete djb2_table;
    delete fnv1a_table;
    out.close();
}
