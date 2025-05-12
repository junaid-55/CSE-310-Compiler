#include <iostream>
#include <cstring>
#include <sstream>
#include "hash.hpp"
using namespace std;
typedef unsigned int (*HashFunction)(const string &, unsigned int);

struct Hash_analysis
{
    int collision_count;
    int total_inserted;
    int bucket_size;
    int scope_count;
    Hash_analysis()
    {
        collision_count = 0;
        total_inserted = 0;
        bucket_size = 0;
        scope_count = 0;
    }
};

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
    Hash_analysis *hash_analysis;
    HashFunction hash;

public:
    ScopeTable(int n, HashFunction hash, Hash_analysis *hash_analysis)
    {
        this->size = n;
        buckets = new SymbolInfo *[size];
        for (int i = 0; i < size; i++)
            buckets[i] = NULL;
        this->parent_scope = NULL;
        this->hash_analysis = hash_analysis;
        this->hash = hash;
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
        int i = hash(name, this->size) % this->size;
        int bucket_num = i + 1, pos = 1;
        if (buckets[i] != NULL)
            hash_analysis->collision_count++;
        hash_analysis->total_inserted++;
        SymbolInfo *temp = buckets[i], *prev = NULL;
        while (temp != NULL)
        {
            if (temp->getName() == name)
            {
                cout << "\t'" << name << "' already exists in the current ScopeTable" << endl;
                return false;
            }
            prev = temp;
            temp = temp->getNext();
            pos++;
        }

        SymbolInfo *symbol = new SymbolInfo(name, type);
        if (prev == NULL)
            buckets[i] = symbol;
        else
            prev->setNext(symbol);
        cout << "\tInserted in ScopeTable# " << scope_num << " at position " << bucket_num << ", " << pos << endl;
        return true;
    }

    SymbolInfo *lookup(string name)
    {
        int i = hash(name, this->size) % this->size;
        int bucket_num = i + 1, pos = 0;
        SymbolInfo *temp = buckets[i];
        while (temp != NULL)
        {
            if (temp->getName() == name)
            {
                cout << "\t'" << name << "' found in ScopeTable# " << scope_num << " at position " << bucket_num << ", " << pos + 1 << endl;
                return temp;
            }
            temp = temp->getNext();
            pos++;
        }
        return NULL;
    }

    bool delete_symbol(string name)
    {
        int i = hash(name, this->size) % this->size;
        int bucket_num = i + 1, pos = 1;
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
                cout << " " << curr->to_string();
                curr = curr->getNext();
            }
            cout << " " << endl;
        }
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
    int size, scope_count;
    string hash_function;
    HashFunction hash;
    int colission_count = 0;
    Hash_analysis *hash_analysis;
public:
    SymbolTable(int n, string hash_function)
    {
        this->hash_function = hash_function;
        this->size = n;
        this->scope_count = 1;
        this->hash_analysis = new Hash_analysis();
        this->hash_analysis->bucket_size = n;
        current_scope = NULL;
        if (hash_function == "SDBM")
            this->hash = sdbmHash;
        else if (hash_function == "DJB2")
            this->hash = djb2Hash;
        else if (hash_function == "FNV1A")
            this->hash = fnv1aHash;
        else
            this->hash = sdbmHash;
        this->enter_scope();
    }

    void enter_scope()
    {
        ScopeTable *new_scope = new ScopeTable(size, hash, hash_analysis);
        hash_analysis->scope_count++;
        new_scope->set_Parent_scope(this->current_scope);
        if (current_scope == NULL)
            new_scope->set_scope_num(1);
        else
            new_scope->set_scope_num(++scope_count);
        this->current_scope = new_scope;
        cout << "\tScopeTable# " << current_scope->get_scope_num() << " created" << endl;
        return;
    }

    void exit_scope(bool override = false)
    {
        if (!override && current_scope->get_parent_scope() == NULL)
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

        cout << "\t'" << name << "' not found in any of the ScopeTables" << endl;
        return NULL;
    }

    void delete_all_scope()
    {
        while (current_scope->get_parent_scope() != NULL)
            this->exit_scope();
        this->exit_scope(true);
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

    Hash_analysis* get_hash_analyser(){
        return hash_analysis;
    }

    string get_hash_function()
    {
        return this->hash_function;
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
        delete hash_analysis;
    }
};
