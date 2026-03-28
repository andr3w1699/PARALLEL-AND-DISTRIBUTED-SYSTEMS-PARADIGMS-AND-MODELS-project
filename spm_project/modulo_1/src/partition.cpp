#include "partition.h"
#include <cstddef>
#include <immintrin.h>

// Hash function
uint64_t hash64(uint64_t x) {
    x ^= x >> 33;
    x *= 0xff51afd7ed558ccd;
    x ^= x >> 33;
    return x;
}

// Scalar version (baseline)
void compute_partitions(const std::vector<uint64_t>& keys,
                        std::vector<uint32_t>& part_id,
                        uint32_t P) {
    size_t N = keys.size();

    for (size_t i = 0; i < N; i++) {
        uint64_t h = hash64(keys[i]);
        part_id[i] = h & (P - 1);
    }
}

/*
void compute_partitions_avx2(const std::vector<uint64_t>& keys,
                             std::vector<uint32_t>& part_id,
                             uint32_t P) {
    size_t N = keys.size();
    size_t i = 0;

    __m256i mask = _mm256_set1_epi64x(P - 1);
    __m256i mul_const = _mm256_set1_epi64x(0xff51afd7ed558ccd);

    for (; i + 4 <= N; i += 4) {
        // Load 4 keys
        __m256i k = _mm256_loadu_si256((__m256i*)&keys[i]);

        // hash: x ^= x >> 33
        __m256i shift = _mm256_srli_epi64(k, 33);
        k = _mm256_xor_si256(k, shift);

        // x *= constant
        k = _mm256_mullo_epi64(k, mul_const);

        // x ^= x >> 33
        shift = _mm256_srli_epi64(k, 33);
        k = _mm256_xor_si256(k, shift);
        
        
        // mask
        k = _mm256_and_si256(k, mask);
        
        
        // Store (convert 64 → 32 bit)
        uint64_t temp[4];
        _mm256_storeu_si256((__m256i*)temp, k);

        for (int j = 0; j < 4; j++) {
            part_id[i + j] = (uint32_t)temp[j];
        }
        
        // Extract lower 32 bits from each 64-bit lane

        __m128i low = _mm256_castsi256_si128(k);         // k0, k1
        __m128i high = _mm256_extracti128_si256(k, 1);   // k2, k3

        // Mask lower 32 bits
        __m128i mask32 = _mm_set1_epi64x(0xFFFFFFFF);

        low = _mm_and_si128(low, mask32);
        high = _mm_and_si128(high, mask32);

        // Now we need to pack 64 → 32 manually
        uint32_t tmp[4];

        tmp[0] = (uint32_t)_mm_cvtsi128_si64(low);
        tmp[1] = (uint32_t)(_mm_extract_epi64(low, 1));
        tmp[2] = (uint32_t)_mm_cvtsi128_si64(high);
        tmp[3] = (uint32_t)(_mm_extract_epi64(high, 1));

        _mm_storeu_si128((__m128i*)&part_id[i], _mm_loadu_si128((__m128i*)tmp));
    }

    // tail case
    for (; i < N; i++) {
        uint64_t h = hash64(keys[i]);
        part_id[i] = h & (P - 1);
    }
}
*/