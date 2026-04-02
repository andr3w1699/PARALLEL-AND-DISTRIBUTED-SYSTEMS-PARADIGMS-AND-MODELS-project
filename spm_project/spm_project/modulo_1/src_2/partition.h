#ifndef PARTITION_H
#define PARTITION_H

#include <cstdint>
#include <cstddef>

// force inline 
// not used 
__attribute__((always_inline)) inline uint64_t hash64(uint64_t x) {
    x ^= x >> 33;
    x *= 0xff51afd7ed558ccd;
    x ^= x >> 33;
    return x;
}

// work with pointers 

void compute_partitions(const uint64_t* __restrict__ keys,
                        uint32_t* __restrict__ part_id,
                        size_t N,
                        uint32_t P);

void compute_partitions_avx2(const uint64_t* __restrict__ keys,
                            uint32_t* __restrict__ part_id,
                            size_t N,
                            uint32_t P);

#endif