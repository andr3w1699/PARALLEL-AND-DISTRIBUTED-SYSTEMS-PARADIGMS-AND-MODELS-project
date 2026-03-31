#include <iostream>
#include <random>
#include <chrono>
#include <cstdlib>
#include <cmath>

#include "partition.h"

int main() {
    size_t N = 1 << 24;
    uint32_t P = 1024;

    // aligned memory (32 bytes for AVX2)
    uint64_t* keys = (uint64_t*) aligned_alloc(32, N * sizeof(uint64_t));
    uint32_t* part_id = (uint32_t*) aligned_alloc(32, N * sizeof(uint32_t));

    if (!keys || !part_id) {
        std::cerr << "Memory allocation failed\n";
        return 1;
    }

    // deterministic input
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

    // optional: distribution stats (unchanged)
    uint64_t* histogram = (uint64_t*) calloc(P, sizeof(uint64_t));

    for (size_t i = 0; i < N; i++) {
        histogram[part_id[i]]++;
    }

    uint64_t min_count = histogram[0];
    uint64_t max_count = histogram[0];
    double sum = 0;

    for (uint32_t i = 0; i < P; i++) {
        if (histogram[i] < min_count) min_count = histogram[i];
        if (histogram[i] > max_count) max_count = histogram[i];
        sum += histogram[i];
    }

    double mean = sum / P;

    double variance = 0;
    for (uint32_t i = 0; i < P; i++) {
        double diff = histogram[i] - mean;
        variance += diff * diff;
    }
    variance /= P;

    std::cout << "\n--- Distribution stats ---\n";
    std::cout << "Min: " << min_count << "\n";
    std::cout << "Max: " << max_count << "\n";
    std::cout << "Mean: " << mean << "\n";
    std::cout << "Stddev: " << std::sqrt(variance) << "\n";
    std::cout << "Imbalance: " << (double)max_count / mean << "\n";

    free(keys);
    free(part_id);
    free(histogram);

    return 0;
}