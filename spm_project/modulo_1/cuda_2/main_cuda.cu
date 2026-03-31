#include <iostream>
#include <random>
#include <chrono>
#include <cuda_runtime.h>

#include "partition_cuda.cuh"

int main() {
    size_t N = 1 << 24;
    uint32_t P = 1024;

    uint64_t* keys;
    uint32_t* part_id;

    // ==========================
    // PINNED MEMORY ALLOCATION
    // ==========================
    cudaMallocHost(&keys, N * sizeof(uint64_t));
    cudaMallocHost(&part_id, N * sizeof(uint32_t));

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

    cudaFreeHost(keys);
    cudaFreeHost(part_id);

    return 0;
}