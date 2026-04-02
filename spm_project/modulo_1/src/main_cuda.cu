#include <iostream>
#include <random>
#include <chrono>
#include <cstdlib>
#include <cstring>

#include "partition_cuda.cuh"

int main() {
    size_t N = 1 << 24;
    uint32_t P = 256;

    uint64_t* keys = (uint64_t*) aligned_alloc(32, N * sizeof(uint64_t));
    uint32_t* part_id = (uint32_t*) aligned_alloc(32, N * sizeof(uint32_t));
    // Zero-initialize the allocated memory
    if (keys) {
        ::memset(keys, 0, N * sizeof(uint64_t));
    }
    if (part_id) {
        ::memset(part_id, 0, N * sizeof(uint32_t));
    }

    std::mt19937_64 rng(42);
    for (size_t i = 0; i < N; i++) {
        keys[i] = rng();
    }

    auto start = std::chrono::high_resolution_clock::now();

    compute_partitions_cuda(keys, part_id, N, P);

    auto end = std::chrono::high_resolution_clock::now();

    double total_time = std::chrono::duration<double>(end - start).count();

    uint64_t checksum = 0;
    for (size_t i = 0; i < N; i++) {
        checksum += part_id[i];
    }

    std::cout << "Total CUDA time: " << total_time << " s\n";
    std::cout << "Checksum: " << checksum << "\n";

    free(keys);
    free(part_id);

    return 0;
}