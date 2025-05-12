#include <string>
#include <cstdint>

/**
 * @brief DJB2 hash function for strings
 * 
 * A well-known string hashing algorithm created by Daniel J. Bernstein.
 * It has good distribution and speed on many types of inputs.
 * 
 */
unsigned int djb2Hash(const std::string& str, unsigned int tableSize) {
    unsigned long hash = 5381; // Initial value
    
    for (char c : str) {
        hash = ((hash << 5) + hash) + c;
    }
    
    return hash % tableSize;
}

/**
 * @brief FNV-1a hash function for strings
 * 
 * Fowler-Noll-Vo is another popular string hashing function
 * known for its good dispersion and low collision rate.
 * 
 */
unsigned int fnv1aHash(const std::string& str, unsigned int tableSize) {
    const uint32_t FNV_PRIME = 16777619;
    const uint32_t FNV_OFFSET_BASIS = 2166136261;
    
    uint32_t hash = FNV_OFFSET_BASIS;
    
    for (char c : str) {
        hash ^= static_cast<uint32_t>(c); 
        hash *= FNV_PRIME;                 
    }
    
    return hash % tableSize;
}

/**
 * @brief SDBM hash function for strings
 * 
 * A hash function used in the SDBM (a public-domain implementation of ndbm) database library.
 * This algorithm has good distribution properties and is known for minimizing collisions.
 * 
 * Reference: Originally used in SDBM (a public-domain reimplementation of ndbm)
 * Acknowledgment: The algorithm has been widely used in various hash table implementations.
 * 
 */
unsigned int sdbmHash(const std::string& str, unsigned int tableSize) {
    unsigned long hash = 0;
    
    for (char c : str) {
        hash = (static_cast<unsigned char>(c) + (hash << 6) + (hash << 16) - hash)%tableSize;
    }
    
    return hash % tableSize;
}