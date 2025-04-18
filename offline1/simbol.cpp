#include <iostream>
#include <cstring>
#include <sstream>
using namespace std;

class SymbolInfo
{
    string name, type;
    SymbolInfo *next;

public:
    SymbolInfo(string name, string type)
    {
        this->name = name;
        this->type = type;
        this->next = NULL;
    }

    // getter methods
    string getName() { return name; }
    string getType() { return type; }
    SymbolInfo *getNext() { return this->next; }

    // setter methods
    void setNext(SymbolInfo *next)
    {
        this->next = next;
    }

    // rest of the code
    // Overload the << operator for SymbolInfo
    string to_string()
    {
        string type_info, out = "", result = "";
        istringstream stream(type);
        stream >> type_info;
        if (type_info == "STRUCT" || type_info == "UNION")
        {
            string temp_type, temp_name;
            out += "{";
            while (stream >> temp_type >> temp_name)
            {
                if (out != "{")
                    out += ",";
                out += "(" + temp_type + "," + temp_name + ")";
            }
            out += "}";
        }
        else if (type_info == "FUNCTION")
        {
            string temp_type;
            bool stat = false;
            stream >> temp_type;
            out += temp_type + "<==(";
            while (stream >> temp_type)
            {
                if (stat)
                    out += ",";
                out += temp_type;
                stat = true;
            }
            out += ")";
        }

        result += "<" + this->name + "," + type_info;
        if (out != "")
            result += +"," + out;
        result += ">";
        return result;
    }

    bool operator==(SymbolInfo *symbol)
    {
        return (this->name == symbol->name && this->type == symbol->type);
    }

    ~SymbolInfo()
    {
        delete next;
    }
};

class ScopeTable
{
    SymbolInfo **buckets;
    ScopeTable *parent_scope;
    int size, scope_num;

public:
    ScopeTable(int n)
    {
        this->size = n;
        buckets = new SymbolInfo *[size];
        for (int i = 0; i < size; i++)
            buckets[i] = NULL;
        this->parent_scope = NULL;
    }

    void set_scope_num(int scope_num)
    {
        this->scope_num = scope_num;
    }

    void set_Parent_scope(ScopeTable *parent_scope)
    {
        this->parent_scope = parent_scope;
    }

    int get_scope_num()
    {
        return scope_num;
    }
    ScopeTable *get_parent_scope()
    {
        return parent_scope;
    }

    bool insert(string name, string type)
    {
        int i = hash(name) % this->size;
        int bucket_num = i + 1, pos = 1;
        SymbolInfo *temp = buckets[i];
        while (temp != NULL)
        {
            if (temp->getName() == name)
            {
                cout << "\t'" << name << "' already exists in the current ScopeTable" << endl;
                return false;
            }
            temp = temp->getNext();
        }

        SymbolInfo *symbol = new SymbolInfo(name, type);
        symbol->setNext(buckets[i]);
        buckets[i] = symbol;
        cout << "\tInserted in ScopeTable# " << scope_num << " at position " << bucket_num << ", " << pos << endl;
        return true;
    }

    SymbolInfo *lookup(string name)
    {
        int i = hash(name) % this->size;
        int bucket_num = i + 1, pos = 0;
        SymbolInfo *temp = buckets[i];
        while (temp != NULL)
        {
            if (temp->getName() == name)
            {
                cout << "\t'" << name << "' found in ScopeTable# " << scope_num << " at position " << bucket_num << "," << pos + 1 << endl;
                return temp;
            }
            temp = temp->getNext();
            pos++;
        }
        return NULL;
    }

    bool delete_symbol(string name)
    {
        int i = hash(name) % this->size;
        int bucket_num = i + 1, pos = 0;
        bool status = false;
        SymbolInfo *prev, *curr;
        prev = NULL, curr = buckets[i];
        while (curr != NULL)
        {
            if (curr->getName() == name)
            {
                status = true;
                break;
            }
            prev = curr;
            curr = curr->getNext();
            pos++;
        }
        if (!status)
            return false;
        if (prev == NULL)
            buckets[i] = curr->getNext();
        else
            prev->setNext(curr->getNext());
        delete curr;
        cout << "\tDeleted '" << name << "' from ScopeTable# " << scope_num << " at position " << bucket_num << ", " << pos << endl;
        return true;
    }

    void print(int indent = 0)
    {
        string prefix = "";
        for (int i = 0; i < indent; i++)
            prefix += '\t';
        cout << prefix << "ScopeTable# " << this->scope_num << endl;
        for (int i = 0; i < size; i++)
        {
            cout << prefix << (i + 1) << "-->";
            SymbolInfo *curr = buckets[i];
            while (curr != NULL)
            {
                cout << curr->to_string();
                curr = curr->getNext();
            }
            cout << endl;
        }
    }

    static unsigned int hash(string str)
    {
        unsigned int hash = 0;
        unsigned int i = 0;
        unsigned int len = str.length();

        for (i = 0; i < len; i++)
        {
            hash = (str[i]) + (hash << 6) + (hash << 16) - hash;
        }

        return hash;
    }

    ~ScopeTable()
    {
        for (int i = 0; i < size; i++)
        {
            delete buckets[i];
        }
        delete[] buckets;
    }
};

class SymbolTable
{
    ScopeTable *current_scope;
    int size;

public:
    SymbolTable(int n)
    {
        this->size = n;
        current_scope = NULL;
    }

    void enter_scope()
    {
        ScopeTable *new_scope = new ScopeTable(size);
        new_scope->set_Parent_scope(this->current_scope);
        if (current_scope == NULL)
            new_scope->set_scope_num(1);
        else
            new_scope->set_scope_num(current_scope->get_scope_num() + 1);
        this->current_scope = new_scope;
        cout << "\tScopeTable# " << current_scope->get_scope_num() << " created" << endl;
        return;
    }

    void exit_scope()
    {
        if (current_scope == NULL)
        {
            cout << "\tNo scope to exit from" << endl;
            return;
        }
        ScopeTable *parent_scope = this->current_scope->get_parent_scope();
        int deleted_scope_num = this->current_scope->get_scope_num();
        delete this->current_scope;
        this->current_scope = parent_scope;
        cout << "\tScopeTable# " << deleted_scope_num << " removed" << endl;
    }

    bool insert(string name, string type)
    {
        if (this->current_scope == NULL)
        {
            cout << "\tNo scope to insert Symbol" << endl;
            return false;
        }
        return this->current_scope->insert(name, type);
    }

    bool delete_symbol(string name)
    {
        if (this->current_scope == NULL || !this->current_scope->delete_symbol(name))
        {
            cout << "\tNot found in the current ScopeTable" << endl;
            return false;
        }
        return true;
    }

    SymbolInfo *lookup(string name)
    {
        ScopeTable *curr = this->current_scope;
        while (curr != NULL)
        {
            SymbolInfo *target = curr->lookup(name);
            if (target != NULL)
                return target;
            curr = curr->get_parent_scope();
        }

        cout << "\t'" << name << "' not found in any of the ScopeTable" << endl;
        return NULL;
    }

    void print_current_scope()
    {
        this->current_scope->print(1);
    }

    void print_all_scope()
    {
        ScopeTable *curr = this->current_scope;
        int indent = 1;
        while (curr != NULL)
        {
            curr->print(indent++);
            curr = curr->get_parent_scope();
        }
    }
    ~SymbolTable()
    {
        ScopeTable *curr = current_scope;
        while (curr != NULL)
        {
            ScopeTable *temp = curr;
            curr = curr->get_parent_scope();
            delete temp;
        }
    }
};

int main()
{
    freopen("in.txt", "r", stdin);
    freopen("out.txt", "w", stdout);
    int n, cmd_count = 0;
    cin >> n;
    cin.ignore();
    SymbolTable *table = new SymbolTable(n);
    table->enter_scope();
    while (true)
    {
        char option;
        int count = 0;
        string line, token;
        getline(cin, line);
        istringstream stream(line);
        while (stream >> token)
            count++;
        stream.clear();
        stream.str(line);
        stream >> option;
        cout << "Cmd " << ++cmd_count << ": " << line << endl;
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
        case 'P': // Print scope table(s)
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
            delete table; // Clean up memory
            cout << "Exiting program." << endl;
            return 0;
        }
        default:
            cout << "\tNumber of parameters mismatch for the command" << endl;
            break;
        }
    }
}
