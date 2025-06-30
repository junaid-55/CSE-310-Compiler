#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#include <string>
#include <iostream>
#include <sstream>
#include <fstream>
#include <vector>

#include "hash.h"
using namespace std;
using std::string;
using std::ofstream;

typedef unsigned int (*HashFunction)(const string&, unsigned int);

struct Hash_analysis {
    int collision_count;
    int total_inserted;
    int bucket_size;
    int scope_count;

    Hash_analysis();
};

class FunctionData {
    public:
    string return_type;
    string function_name;
    vector<pair<string,string>> parameter_list;
    int parameter_count;

    FunctionData(const string& declaration);
    void parse(string declaration);
    string getReturnType() const { return return_type; }
    string getFunctionName() const { return function_name; }
    vector<pair<string,string>> getParameters() const { return parameter_list; }
    int getParameterCount() const { return parameter_count; }
    
    string toUpperCase(string  name) const {
        string result = name;
        for (char& c : result) {
            c = toupper(c);
        }
        return result;
    }
};

class SymbolInfo {
    string name;
    string type;
    bool is_function;
    FunctionData* function_data;
    bool is_defined;
    bool is_declared;
    bool is_array = false;
    SymbolInfo* next;

public:
    SymbolInfo(const string& name, const string& type, bool is_declared = false, bool is_defined = false);
    ~SymbolInfo();

    void setDefined(bool is_defined) { this->is_defined = is_defined; }
    void setDeclared(bool is_declared) { this->is_declared = is_declared; }
    string getName() const { return name; }
    string getType() const { return type; }
    SymbolInfo* getNext() const { return next; }
    bool isFunction() const { return is_function; }
    bool isDefined() const { return is_defined; }
    bool isDeclared() const { return is_declared; }
    void setArray(bool is_array) { this->is_array = is_array; }
    bool isArray() const { return is_array; }
    string getFunctionName() const {
        if (is_function && function_data != nullptr) {
            return function_data->getFunctionName();
        }
        return "";
    }
    string getReturnType() const {
        if (is_function && function_data != nullptr) {
            return function_data->getReturnType();
        }
        return "";
    }
    vector<pair<string,string>> getParameters() const {
        if (is_function && function_data != nullptr) {
            return function_data->getParameters();
        }
        return {};
    }
    int getParameterCount() const {
        if (is_function && function_data != nullptr) {
            return function_data->getParameterCount();
        }
        return 0;
    }

    void setNext(SymbolInfo* next) { this->next = next; }
    string to_string() const{return "< "+ name + " , ID >" ;};
    string getDebugData() const;
    bool operator==(const SymbolInfo* symbol) const;
    FunctionData* getFunctionData() const { return function_data; }
};

class ScopeTable {
    SymbolInfo** buckets;
    ScopeTable* parent_scope;
    int size;
    int child_count;
    string scope_id;
    Hash_analysis* hash_analysis;
    HashFunction hash;

public:
    ScopeTable(int n, HashFunction hash, Hash_analysis* hash_analysis);
    ~ScopeTable();

    void increase_child_count();
    int get_child_count() const { return child_count; }
    void set_scope_id(const string& scope_id) { this->scope_id = scope_id; }
    void set_Parent_scope(ScopeTable* parent_scope) { this->parent_scope = parent_scope; }
    string get_scope_id() const { return scope_id; }
    ScopeTable* get_parent_scope() const { return parent_scope; }

    bool insert(const string& name, const string& type, ofstream& out);
    bool insert(const string& name, const string& type, bool is_declared = false, bool is_defined = false);
    SymbolInfo* lookup(const string& name);
    SymbolInfo* lookupCurrentScope(const string& name);
    bool delete_symbol(const string& name);
    void print(ofstream& out);
    void print(int indent = 0);
};

class SymbolTable {
    ScopeTable* current_scope;
    int size;
    int scope_count;
    string hash_function;
    HashFunction hash;
    Hash_analysis* hash_analysis;

public:
    SymbolTable(int n);
    ~SymbolTable();

    void enter_scope();
    void exit_scope(bool override = false);
    bool insert(const string& name, const string& type, ofstream& out);
    bool insert(const string& name, const string& type, bool is_declared = false, bool is_defined = false);
    bool insertInParentScope(const string& name, const string& type, bool is_declared = false, bool is_defined = false);
    bool delete_symbol(const string& name);
    SymbolInfo* lookup(const string& name);
    SymbolInfo* lookupCurrentScope(const string& name);
    void delete_all_scope();
    void print_current_scope();
    void print_all_scope();
    void print_all_scope(ofstream &out);
    Hash_analysis* get_hash_analyser() const { return hash_analysis; }
    string get_hash_function() const { return hash_function; }
};

#endif