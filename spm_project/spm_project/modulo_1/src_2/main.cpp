
#include <iostream>
#include <random>
#include <chrono>
#include <cstdlib>
#include <cmath>
#include <cstring>

#include "partition.h"

int main() {
    size_t N = 1 << 24;
    uint32_t P = 256;

    // aligned memory (32 bytes for AVX2)
    uint64_t* keys = (uint64_t*) aligned_alloc(32, N * sizeof(uint64_t));
    uint32_t* part_id = (uint32_t*) aligned_alloc(32, N * sizeof(uint32_t));
    // Zero-initialize the allocated memory
    if (keys) {
        ::memset(keys, 0, N * sizeof(uint64_t));
    }
    if (part_id) {
        ::memset(part_id, 0, N * sizeof(uint32_t));
    }

    if (!keys || !part_id) {
        std::cerr << "Memory allocation failed\n";
        return 1;
    }

    std::mt19937_64 rng(42);
    for (size_t i = 0; i < N; i++) {
        keys[i] = rng();
    }

    auto start = std::chrono::high_resolution_clock::now();

    #ifdef USE_AVX2
        compute_partitions_avx2(keys, part_id, N, P);
    #else
        compute_partitions(keys, part_id, N, P);
    #endif

    auto end = std::chrono::high_resolution_clock::now();

    double time = std::chrono::duration<double>(end - start).count();

    // checksum
    uint64_t checksum = 0;
    for (size_t i = 0; i < N; i++) {
        checksum += part_id[i];
    }

    std::cout << "Time: " << time << " s\n";
    std::cout << "Checksum: " << checksum << "\n";

    // print first 20 elements of part_id
    std::cout << "First 20 partition IDs: ";
    for (size_t i = 0; i < 20 && i < N; i++) {
        std::cout << part_id[i] << " ";
    }
    std::cout << "\n";

    free(keys);
    free(part_id);

    return 0;
}