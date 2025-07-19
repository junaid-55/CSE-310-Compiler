#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#include <string>
#include <iostream>
#include <sstream>
#include <fstream>
#include <vector>
#include <utility>
#include "hash.h"
using namespace std;
using std::ofstream;
using std::string;

typedef unsigned int (*HashFunction)(const string &, unsigned int);

struct Hash_analysis
{
    int collision_count;
    int total_inserted;
    int bucket_size;
    int scope_count;

    Hash_analysis();
};

class FunctionData
{
public:
    string return_type;
    string function_name;
    vector<pair<string, string>> parameter_list;
    int parameter_count;

    FunctionData(const string &declaration);
    void parse(string declaration);
    string getReturnType() const { return return_type; }
    string getFunctionName() const { return function_name; }
    vector<pair<string, string>> getParameters() const { return parameter_list; }
    int getParameterCount() const { return parameter_count; }

    string toUpperCase(string name) const
    {
        string result = name;
        for (char &c : result)
        {
            c = toupper(c);
        }
        return result;
    }
};

class SymbolInfo
{
    string name;
    string type;
    bool is_function;
    FunctionData *function_data;
    bool is_inside= false;
    bool is_defined;
    bool is_declared;
    bool is_array = false;
    bool has_returned = false;
    bool is_func_param = false;
    int stack_offset, array_size;
    SymbolInfo *next;

public:
    SymbolInfo(const string &name, const string &type, bool is_declared, bool is_defined, bool is_array, int array_size, int stack_offset);
    ~SymbolInfo();

    void setIsParam(bool value){ this->is_func_param = value; }
    bool isParam() const { return is_func_param; }
    void setInside(bool inside)
    {
        if (is_function && function_data != nullptr)
            is_inside = inside;
    }
    bool isInside() const { return is_inside; }
    bool isReturned() const { return has_returned; }
    void setReturned(bool has_returned) { this->has_returned = has_returned; }
    void setArraySize(int array_size) { this->array_size = array_size; }
    int getArraySize() const { return array_size; }
    void setDefined(bool is_defined) { this->is_defined = is_defined; }
    void setDeclared(bool is_declared) { this->is_declared = is_declared; }
    string getName() const { return name; }
    string getType() const { return type; }
    SymbolInfo *getNext() const { return next; }
    bool isFunction() const { return is_function; }
    bool isDefined() const { return is_defined; }
    bool isDeclared() const { return is_declared; }
    void setArray(bool is_array) { this->is_array = is_array; }
    bool isArray() const { return is_array; }
    bool isGlobal() const{ return stack_offset == 0; }
    void setStackOffset(int offset) { this->stack_offset = offset; }
    int getStackOffset() const { return stack_offset; }
    string getFunctionName() const
    {
        if (is_function && function_data != nullptr)
        {
            return function_data->getFunctionName();
        }
        return "";
    }
    string getReturnType() const
    {
        if (is_function && function_data != nullptr)
        {
            return function_data->getReturnType();
        }
        return "";
    }
    vector<pair<string, string>> getParameters() const
    {
        if (is_function && function_data != nullptr)
        {
            return function_data->getParameters();
        }
        return {};
    }
    int getParameterCount() const
    {
        if (is_function && function_data != nullptr)
        {
            return function_data->getParameterCount();
        }
        return 0;
    }

    void setNext(SymbolInfo *next) { this->next = next; }
    string to_string() const { 
        string offset = (is_func_param? "+": "-") + std::to_string(stack_offset);
        return "< " + name + " , " + type + " , " + offset + " >"; 
    };
    string getDebugData() const;
    bool operator==(const SymbolInfo *symbol) const;
    FunctionData *getFunctionData() const { return function_data; }
};

class ScopeTable
{
    SymbolInfo **buckets;
    ScopeTable *parent_scope;
    int stack_offset, inherited_stack_offset,current_stack_offset;
    int size;
    int child_count;
    bool scope_returned;
    string scope_id;
    Hash_analysis *hash_analysis;
    HashFunction hash;

public:
    ScopeTable(int n, HashFunction hash, Hash_analysis *hash_analysis);
    ~ScopeTable();

    int get_current_stack_offset() const { return current_stack_offset; }
    void set_inherited_stack_offset(int offset) { inherited_stack_offset = offset; }
    int get_inherited_stack_offset() const { return inherited_stack_offset; }
    int getStackTop() const { return current_stack_offset + inherited_stack_offset; }
    void set_scope_returned(bool value) { scope_returned = value; }
    bool get_scope_returned() const { return scope_returned; }
    void increase_child_count();
    int get_child_count() const { return child_count; }
    void set_scope_id(const string &scope_id) { this->scope_id = scope_id; }
    void set_Parent_scope(ScopeTable *parent_scope) { this->parent_scope = parent_scope; }
    string get_scope_id() const { return scope_id; }
    ScopeTable *get_parent_scope() const { return parent_scope; }

    bool insert(const string &name, const string &type, bool is_declared = false, bool is_defined = false, bool is_array = false, int array_size = 0, bool  override = false );
    SymbolInfo *insideFunction();
    SymbolInfo *lookup(const string &name);
    SymbolInfo *lookupCurrentScope(const string &name);
    bool delete_symbol(const string &name);
    void print(ofstream &out);
    void print(int indent = 0);
};

class SymbolTable
{
    ScopeTable *current_scope;
    int size;
    int scope_count;
    string hash_function;
    HashFunction hash;
    Hash_analysis *hash_analysis;

public:
    SymbolTable(int n);
    ~SymbolTable();

    void setCurrentScopeReturned(bool value)
    {
        if (current_scope != nullptr)
            current_scope->set_scope_returned(value);
    }
    bool getCurrentScopeReturned() const
    {
        if (current_scope != nullptr)
            return current_scope->get_scope_returned();
        return false;
    }
    void enter_scope();
    void exit_scope(bool override = false);
    string get_current_scope_id() const
    {
        if (current_scope != nullptr)
            return current_scope->get_scope_id();
        return "";
    }

    int getCurrentScopeStackTop() const
    {
        if (current_scope != nullptr)
            return current_scope->get_current_stack_offset();
        return 0;
    }

    int getTotalStackOffset() const
    {
        if (current_scope != nullptr)
            return current_scope->getStackTop();
        return 0;
    }

    bool insert(const string &name, const string &type, bool is_declared = false, bool is_defined = false, bool is_array = false, int array_size = 0,bool override = false);

    bool insertInParentScope(const string &name, const string &type, bool is_declared = false, bool is_defined = false, bool is_array = false, int array_size = 0);

    bool delete_symbol(const string &name);

    string get_scope_id(SymbolInfo *symbol) const
    {
        if (symbol != nullptr && current_scope != nullptr)
        {
            ScopeTable *scope = current_scope;
            while (scope != nullptr)
            {
                SymbolInfo *found_symbol = scope->lookupCurrentScope(symbol->getName());
                if (found_symbol != nullptr && found_symbol== symbol)
                {
                    return scope->get_scope_id();
                }
                scope = scope->get_parent_scope();
            }
        }
        return "";
    }
    SymbolInfo *lookup(const string &name);
    SymbolInfo *lookupCurrentScope(const string &name);
    SymbolInfo *insideFunction();
    void delete_all_scope();
    void print_current_scope();
    void print_all_scope();
    void print_all_scope(ofstream &out);
    Hash_analysis *get_hash_analyser() const { return hash_analysis; }
    string get_hash_function() const { return hash_function; }
};

#endif