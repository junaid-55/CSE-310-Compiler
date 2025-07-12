#include "symbol_table.h"

using namespace std;

Hash_analysis::Hash_analysis()
{
    collision_count = 0;
    total_inserted = 0;
    bucket_size = 0;
    scope_count = 0;
}

FunctionData::FunctionData(const string &declaration)
{
    return_type = "";
    function_name = "";
    parameter_count = 0;
    parameter_list.clear();
    parse(declaration);
}

void FunctionData::parse(string declaration)
{
    if (!declaration.empty() && declaration.back() == ';')
        declaration.pop_back();

    istringstream stream(declaration);
    string token, parameters = "";
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
            return_type = toUpperCase(return_type);
        }
        else
        {
            function_name = token;
        }
    }

    //  (type, name) pairs
    if (!parameters.empty())
    {
        istringstream param_stream(parameters);
        string param;
        while (getline(param_stream, param, ','))
        {
            istringstream param_tokens(param);
            string type, name;
            param_tokens >> type >> name;
            if (!type.empty() && !name.empty())
            {
                parameter_list.push_back({toUpperCase(type), name});
                parameter_count++;
            }
        }
    }
}

SymbolInfo::SymbolInfo(const string &name, const string &type, bool is_declared, bool is_defined, bool is_array, int array_size, int stack_offset)
{
    this->name = name;
    this->type = type;
    this->next = nullptr;
    this->is_declared = is_declared;
    this->is_defined = is_defined;
    this->is_array = is_array;
    this->array_size = array_size;
    this->stack_offset = stack_offset;
    if (this->type == "FUNCTION")
    {
        is_function = true;
        function_data = new FunctionData(name);
        this->name = function_data->getFunctionName();
    }
    else
    {
        function_data = nullptr;
        is_function = false;
    }
}

SymbolInfo::~SymbolInfo()
{
    delete function_data;
    next = nullptr;
}

string SymbolInfo::getDebugData() const
{
    string result = "";
    result += name + " : " + type + "\n";
    if (is_function)
    {
        result += "Function Name: " + function_data->getFunctionName() + "\n";
        result += "Return Type: " + function_data->getReturnType() + "\n";
        result += "Parameters: ";
        for (const auto &param : function_data->getParameters())
        {
            result += param.first + " " + param.second + ", ";
        }
        if (!function_data->getParameters().empty())
            result.pop_back();
        result += "\n";
        if (is_declared)
        {
            result += "Declared: true\n";
        }
        else
        {
            result += "Declared: false\n";
        }
        if (is_defined)
        {
            result += "Defined: true\n";
        }
        else
        {
            result += "Defined: false\n";
        }
    }
    if (is_array)
    {
        result += "Array: true\n";
    }
    else
    {
        result += "Array: false\n";
    }
    return result;
}

bool SymbolInfo::operator==(const SymbolInfo *symbol) const
{
    return (this->name == symbol->name && this->type == symbol->type);
}

ScopeTable::ScopeTable(int n, HashFunction hash, Hash_analysis *hash_analysis)
{
    this->size = n;
    buckets = new SymbolInfo *[size]();
    for (int i = 0; i < size; i++)
        buckets[i] = nullptr;
    this->parent_scope = nullptr;
    this->hash_analysis = hash_analysis;
    this->hash = hash;
    this->child_count = 0;
    this->stack_offset = 0;
}

ScopeTable::~ScopeTable()
{
    for (int i = 0; i < size; i++)
    {
        SymbolInfo *curr = buckets[i];
        while (curr)
        {
            SymbolInfo *temp = curr;
            curr = curr->getNext();
            delete temp;
        }
    }
    delete[] buckets;
}

void ScopeTable::increase_child_count()
{
    this->child_count++;
}

bool ScopeTable::insert(const string &name, const string &type, bool is_declared, bool is_defined, bool is_array, int array_size)
{
    if (scope_id != "1")
    {
        if (is_array)
            stack_offset += 2 * array_size;
        else if (type != "FUNCTION")
            stack_offset += 2;
    }
    SymbolInfo *symbol = new SymbolInfo(name, type, is_declared, is_defined, is_array, array_size, stack_offset);
    auto hash_name = symbol->getName();
    int i = hash(hash_name, this->size) % this->size;
    int bucket_num = i, pos = 0;
    if (buckets[i] != nullptr)
        hash_analysis->collision_count++;
    hash_analysis->total_inserted++;
    SymbolInfo *temp = buckets[i], *prev = nullptr;
    while (temp != nullptr)
    {
        prev = temp;
        temp = temp->getNext();
        pos++;
    }

    if (prev == nullptr)
        buckets[i] = symbol;
    else
        prev->setNext(symbol);
    return true;
}

SymbolInfo *ScopeTable::lookup(const string &name)
{
    int i = hash(name, this->size) % this->size;
    SymbolInfo *temp = buckets[i];
    while (temp != nullptr)
    {
        if (temp->getName() == name)
        {
            return temp;
        }
        temp = temp->getNext();
    }
    return nullptr;
}

SymbolInfo *ScopeTable::lookupCurrentScope(const string &name)
{
    int i = hash(name, this->size) % this->size;
    SymbolInfo *temp = buckets[i];
    while (temp != nullptr)
    {
        if (temp->getName() == name)
        {
            return temp;
        }
        temp = temp->getNext();
    }
    return nullptr;
}

bool ScopeTable::delete_symbol(const string &name)
{
    int i = hash(name, this->size) % this->size;
    SymbolInfo *prev = nullptr, *curr = buckets[i];
    while (curr != nullptr)
    {
        if (curr->getName() == name)
        {
            if (prev == nullptr)
                buckets[i] = curr->getNext();
            else
                prev->setNext(curr->getNext());
            curr->setNext(nullptr); // Prevent deletion of chain
            delete curr;
            return true;
        }
        prev = curr;
        curr = curr->getNext();
    }
    return false;
}

void ScopeTable::print(ofstream &out)
{
    out << "ScopeTable # " << this->scope_id << endl;
    for (int i = 0; i < size; i++)
    {
        SymbolInfo *curr = buckets[i];
        if (curr == nullptr)
            continue;
        out << i << " -->";
        while (curr != nullptr)
        {
            out << " " << curr->to_string();
            curr = curr->getNext();
        }
        out << endl;
    }
}

void ScopeTable::print(int indent)
{
    string prefix(indent, '\t');
    cout << prefix << "ScopeTable# " << this->scope_id << endl;
    for (int i = 0; i < size; i++)
    {
        SymbolInfo *curr = buckets[i];
        if (curr == nullptr)
            continue;
        cout << prefix << " " << (i + 1) << " -->";
        while (curr != nullptr)
        {
            cout << " " << curr->to_string();
            curr = curr->getNext();
        }
        cout << endl;
    }
}

SymbolTable::SymbolTable(int n)
{
    this->hash_function = "SDBM";
    this->size = n;
    this->scope_count = 1;
    this->hash_analysis = new Hash_analysis();
    this->hash_analysis->bucket_size = n;
    current_scope = nullptr;
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

SymbolTable::~SymbolTable()
{
    delete_all_scope();
    delete hash_analysis;
}

void SymbolTable::enter_scope()
{
    ScopeTable *new_scope = new ScopeTable(size, hash, hash_analysis);
    hash_analysis->scope_count++;
    new_scope->set_Parent_scope(this->current_scope);
    if (current_scope != nullptr)
        current_scope->increase_child_count();

    if (current_scope == nullptr)
    {
        new_scope->set_scope_id("1");
    }
    else
    {
        string parent_id = current_scope->get_scope_id();
        parent_id.append("." + to_string(current_scope->get_child_count()));
        new_scope->set_scope_id(parent_id);
    }
    this->current_scope = new_scope;
}

void SymbolTable::exit_scope(bool override)
{
    if (!override && current_scope->get_parent_scope() == nullptr)
    {
        return;
    }
    ScopeTable *parent_scope = this->current_scope->get_parent_scope();
    delete this->current_scope;
    this->current_scope = parent_scope;
}

bool SymbolTable::insert(const string &name, const string &type, bool is_declared, bool is_defined, bool is_array, int array_size)
{
    if (this->current_scope == nullptr)
    {
        return false;
    }
    return this->current_scope->insert(name, type, is_declared, is_defined, is_array, array_size);
}

bool SymbolTable::insertInParentScope(const string &name, const string &type, bool is_declared, bool is_defined, bool is_array, int array_size)
{
    if (this->current_scope == nullptr || this->current_scope->get_parent_scope() == nullptr)
    {
        return false;
    }
    return this->current_scope->get_parent_scope()->insert(name, type, is_declared, is_defined, is_array, array_size);
}

bool SymbolTable::delete_symbol(const string &name)
{
    if (this->current_scope == nullptr || !this->current_scope->delete_symbol(name))
    {
        return false;
    }
    return true;
}

SymbolInfo *SymbolTable::lookup(const string &name)
{
    ScopeTable *curr = this->current_scope;
    while (curr != nullptr)
    {
        SymbolInfo *target = curr->lookup(name);
        if (target != nullptr)
            return target;
        curr = curr->get_parent_scope();
    }
    return nullptr;
}
SymbolInfo *SymbolTable::lookupCurrentScope(const string &name)
{
    if (this->current_scope == nullptr)
    {
        return nullptr;
    }
    return this->current_scope->lookupCurrentScope(name);
}

void SymbolTable::delete_all_scope()
{
    while (current_scope != nullptr)
    {
        exit_scope(true);
    }
}

void SymbolTable::print_current_scope()
{
    if (current_scope != nullptr)
        current_scope->print(1);
}

void SymbolTable::print_all_scope()
{
    ScopeTable *curr = this->current_scope;
    int indent = 1;
    while (curr != nullptr)
    {
        curr->print(indent++);
        curr = curr->get_parent_scope();
    }
}

void SymbolTable::print_all_scope(ofstream &out)
{
    ScopeTable *curr = this->current_scope;
    int indent = 1;
    while (curr != nullptr)
    {
        out << "\n\n\n";
        curr->print(out);
        curr = curr->get_parent_scope();
    }
}
