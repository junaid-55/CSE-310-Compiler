#ifndef HASH
#define HASH
#include "hash.h"

unsigned int djb2Hash(const std::string& str, unsigned int table_size) {
    unsigned int hash = 5381;
    for (char c : str)
        hash = ((hash << 5) + hash) + c;
    return hash % table_size;
}

unsigned int fnv1aHash(const std::string& str, unsigned int table_size) {
    unsigned int hash = 2166136261u;
    for (char c : str)
        hash ^= c, hash *= 16777619;
    return hash % table_size;
}

unsigned int sdbmHash(const std::string& str, unsigned int table_size) {
    unsigned int hash = 0;
    for (char c : str)
        hash = c + (hash << 6) + (hash << 16) - hash;
    return hash % table_size;
}
#endif
