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

    // -----------------------------
    // Distribution analysis
    // -----------------------------
    std::vector<uint64_t> histogram(P, 0);

    // Count elements per partition
    for (size_t i = 0; i < N; i++) {
        histogram[part_id[i]]++;
    }

    // Compute statistics
    uint64_t min_count = histogram[0];
    uint64_t max_count = histogram[0];
    double sum = 0.0;

    for (uint32_t i = 0; i < P; i++) {
        if (histogram[i] < min_count) min_count = histogram[i];
        if (histogram[i] > max_count) max_count = histogram[i];
        sum += histogram[i];
    }

    double mean = sum / P;

    // Compute variance
    double variance = 0.0;
    for (uint32_t i = 0; i < P; i++) {
        double diff = histogram[i] - mean;
        variance += diff * diff;
    }
    variance /= P;

    double stddev = std::sqrt(variance);

    // Print results
    std::cout << "\n--- Distribution stats ---\n";
    std::cout << "Min: " << min_count << "\n";
    std::cout << "Max: " << max_count << "\n";
    std::cout << "Mean: " << mean << "\n";
    std::cout << "Stddev: " << stddev << "\n";

    double imbalance = (double)max_count / mean;
    std::cout << "Imbalance (max/mean): " << imbalance << "\n";

return 0;
}