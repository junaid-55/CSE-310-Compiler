#ifndef HASH_H
#define HASH_H

#include <string>

unsigned int djb2Hash(const std::string& str, unsigned int table_size);
unsigned int fnv1aHash(const std::string& str, unsigned int table_size);
unsigned int sdbmHash(const std::string& str, unsigned int table_size);

#endif
