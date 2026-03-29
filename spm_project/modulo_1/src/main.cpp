#include <iostream>
#include <vector>
#include <random>
#include <chrono>

#include "partition.h"

int main() {
    size_t N = 1 << 24;   // 16M elements 
    uint32_t P = 1024;    // must be power of 2

    std::vector<uint64_t> keys(N);
    // std::vector<uint32_t> part_id(N);
    std::vector<uint32_t> part_id(N);

    // deterministic input
    std::mt19937_64 rng(42);
    for (size_t i = 0; i < N; i++) {
        keys[i] = rng();
    }

    // timing start
    auto start = std::chrono::high_resolution_clock::now();

    // -----------------------------
    // Choose function based on build
    // -----------------------------
    #ifdef USE_AVX2
        compute_partitions_avx2(keys, part_id, P);
    #else
        compute_partitions(keys, part_id, P);
    #endif

    // timing end
    auto end = std::chrono::high_resolution_clock::now();

    double time = std::chrono::duration<double>(end - start).count();

    // simple checksum (for correctness)
    uint64_t checksum = 0;
    for (auto v : part_id) checksum += v;

    std::cout << "Time: " << time << " s\n";
    std::cout << "Checksum: " << checksum << std::endl;

    return 0;
}