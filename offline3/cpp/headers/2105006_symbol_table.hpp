#ifndef Symbol
#define Symbol

#include <iostream>
#include <cstring>
#include <sstream>
#include <fstream>
// #include "2105006_hash.hpp"
#include "hash.h"
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

class FunctionData
{
    string return_type;
    string function_name;
    string parameters;
    int parameter_count;

public:
    FunctionData(const string &declaration)
    {
        parse(declaration);
    }

    void parse(string declaration)
    {
        return_type = "";
        function_name = "";
        parameters = "";
        parameter_count = 0;

        if (!declaration.empty() && declaration.back() == ';')
            declaration.pop_back();

        istringstream stream(declaration);
        string token;
        bool in_param = false;

        while (stream >> token)
        {
            if (token.find('(') != string::npos)
            {
                size_t paren_pos = token.find('(');
                function_name = token.substr(0, paren_pos);
                in_param = true;

                string remainder = token.substr(paren_pos + 1);
                if (!remainder.empty())
                {
                    parameters += remainder;
                }
            }
            else if (token.find(')') != string::npos)
            {
                string before_paren = token.substr(0, token.find(')'));
                if (!before_paren.empty())
                {
                    if (!parameters.empty())
                        parameters += " ";
                    parameters += before_paren;
                }
                in_param = false;
            }
            else if (in_param)
            {
                if (!parameters.empty())
                    parameters += " ";
                parameters += token;
            }
            else if (return_type.empty())
            {
                return_type = token;
            }
            else
            {
                function_name = token;
            }
        }

        if (!parameters.empty())
        {
            istringstream param_stream(parameters);
            string param;
            while (getline(param_stream, param, ','))
            {
                if (!param.empty())
                    parameter_count++;
            }
        }
    }

    string getReturnType() { return return_type; }
    string getFunctionName() { return function_name; }
    string getParameters() { return parameters; }
    int getParameterCount() { return parameter_count; }
};
class SymbolInfo
{
    string name, type;
    bool is_function;
    FunctionData *function_data;
    bool is_defined, is_declared;
    SymbolInfo *next;

public:
    SymbolInfo(string name, string type, bool is_declared = false, bool is_defined = false)
    {
        this->name = name;
        this->type = type;
        this->next = NULL;
        this->is_declared = is_declared;
        this->is_defined = is_defined;
        if (this->type == "FUNCTION")
        {
            is_function = true;
            function_data = new FunctionData(name);
            this->name = function_data->getFunctionName();
        }
        else
        {
            function_data = NULL;
            is_function = false;
        }
    }

    void setDefined(bool is_defined)
    {
        this->is_defined = is_defined;
    }
    
    void setDeclared(bool is_declared)
    {
        this->is_declared = is_declared;
    }
    string getName() { return name; }
    string getType() { return type; }
    SymbolInfo *getNext() { return this->next; }
    bool isFunction() { return name == "FUNCTION"; }
    bool isDefined() { return is_defined; }
    bool isDeclared() { return is_declared; }

    void setNext(SymbolInfo *next)
    {
        this->next = next;
    }

    string to_string()
    {
        return "< " + name + ", " + "ID" + " >";
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
    int size, child_count = 0;
    ;
    string scope_id;
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

    void increase_child_count()
    {
        this->child_count++;
    }

    int get_child_count()
    {
        return this->child_count;
    }

    void set_scope_id(string scope_id)
    {
        this->scope_id = scope_id;
    }

    void set_Parent_scope(ScopeTable *parent_scope)
    {
        this->parent_scope = parent_scope;
    }

    string get_scope_id()
    {
        return scope_id;
    }
    ScopeTable *get_parent_scope()
    {
        return parent_scope;
    }

    bool insert(string name, string type, ofstream &out)
    {
        if (this->lookup(name) != NULL)
            // out << name << " already exists in ScopeTable# " << this->scope_id << endl
            //     << endl;
            return false;
        int i = hash(name, this->size) % this->size;
        int bucket_num = i, pos = 0;
        if (buckets[i] != NULL)
            hash_analysis->collision_count++;
        hash_analysis->total_inserted++;
        SymbolInfo *temp = buckets[i], *prev = NULL;
        while (temp != NULL)
        {
            prev = temp;
            temp = temp->getNext();
            pos++;
        }

        SymbolInfo *symbol = new SymbolInfo(name, type);
        if (prev == NULL)
            buckets[i] = symbol;
        else
            prev->setNext(symbol);
        // cout << "\tInserted in ScopeTable# " << scope_num << " at position " << bucket_num << ", " << pos << endl;
        return true;
    }

    bool insert(string name, string type, bool is_declared = false, bool is_defined = false)
    {
        if (this->lookup(name) != NULL)
        {
            return false;
        }
        int i = hash(name, this->size) % this->size;
        int bucket_num = i, pos = 0;
        if (buckets[i] != NULL)
            hash_analysis->collision_count++;
        hash_analysis->total_inserted++;
        SymbolInfo *temp = buckets[i], *prev = NULL;
        while (temp != NULL)
        {
            prev = temp;
            temp = temp->getNext();
            pos++;
        }

        SymbolInfo *symbol = new SymbolInfo(name, type, is_declared, is_defined);
        if (prev == NULL)
            buckets[i] = symbol;
        else
            prev->setNext(symbol);
        // cout << "\tInserted in ScopeTable# " << scope_num << " at position " << bucket_num << ", " << pos << endl;
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
                // cout << "\t'" << name << "' found in ScopeTable# " << scope_num << " at position " << bucket_num << ", " << pos + 1 << endl;
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
        // cout << "\tDeleted '" << name << "' from ScopeTable# " << this->scope_id << " at position " << bucket_num << ", " << pos << endl;
        return true;
    }

    void print(ofstream &out, int indent = 0)
    {
        string prefix = "";
        for (int i = 0; i < indent; i++)
            prefix += '\t';
        out << "ScopeTable # " << this->scope_id << endl;
        for (int i = 0; i < size; i++)
        {
            SymbolInfo *curr = buckets[i];
            if (curr == NULL)
                continue;
            out << " " << (i) << " --> ";
            while (curr != NULL)
            {
                out << curr->to_string() << " ";
                curr = curr->getNext();
            }
            out << endl;
        }
    }

    void print(int indent = 0)
    {
        string prefix = "";
        for (int i = 0; i < indent; i++)
            prefix += '\t';
        cout << "ScopeTable# " << this->scope_id << endl;
        for (int i = 0; i < size; i++)
        {
            SymbolInfo *curr = buckets[i];
            if (curr == NULL)
                continue;
            cout << " " << (i + 1) << " -->";
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
    bool exitingScope = false;
    string hash_function;
    HashFunction hash;
    int colission_count = 0;
    Hash_analysis *hash_analysis;

public:
    SymbolTable(int n, string hash_function = "SDBM")
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
        if (current_scope != NULL)
            current_scope->increase_child_count();

        if (current_scope == NULL)
        {
            new_scope->set_scope_id("1");
        }
        else
        {
            string parent_id = current_scope->get_scope_id();
            if (exitingScope)
            {
                parent_id.pop_back();
                string new_id = parent_id + to_string(current_scope->get_child_count());
                new_scope->set_scope_id(new_id);
            }
            else
                new_scope->set_scope_id(parent_id + ".1");
        }
        exitingScope = false;
        this->current_scope = new_scope;
        // cout << "\tScopeTable# " << current_scope->get_scope_id() << " created" << endl;
        return;
    }
    void exit_scope(bool override = false)
    {
        if (!override && current_scope->get_parent_scope() == NULL)
        {
            // cout << "\tNo scope to exit from" << endl;
            return;
        }
        ScopeTable *parent_scope = this->current_scope->get_parent_scope();
        string deleted_scope_id = this->current_scope->get_scope_id();
        delete this->current_scope;
        this->current_scope = parent_scope;
        exitingScope = true;
        // cout << "\tScopeTable# " << deleted_scope_num << " removed" << endl;
    }

    bool insert(string name, string type, ofstream &out)
    {
        if (this->current_scope == NULL)
        {
            // cout << "\tNo scope to insert Symbol" << endl;
            return false;
        }
        return this->current_scope->insert(name, type, out);
    }

    bool insert(string name, string type, bool is_declared = false, bool is_defined = false)
    {
        if (this->current_scope == NULL)
        {
            // cout << "\tNo scope to insert Symbol" << endl;
            return false;
        }
        return this->current_scope->insert(name, type, is_declared, is_defined);
    }

    bool delete_symbol(string name)
    {
        if (this->current_scope == NULL || !this->current_scope->delete_symbol(name))
        {
            // cout << "\tNot found in the current ScopeTable" << endl;
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

        // cout << "\t'" << name << "' not found in any of the ScopeTables" << endl;
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

    void print_all_scope(ofstream &out)
    {
        ScopeTable *curr = this->current_scope;
        int indent = 1;
        while (curr != NULL)
        {
            curr->print(out, indent++);
            curr = curr->get_parent_scope();
        }
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

    Hash_analysis *get_hash_analyser()
    {
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

#endif