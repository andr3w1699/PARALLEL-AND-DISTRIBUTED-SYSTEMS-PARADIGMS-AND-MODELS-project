#include "partition.h"
#include <cstddef>
#include <immintrin.h>

// Hash function (64-bit mix)
// derived from MurmurHash3's finalizer, but simplified for 64-bit input
uint64_t hash64(uint64_t x) {
    x ^= x >> 33; // Bit mixing XOR with shifted version
    x *= 0xff51afd7ed558ccd; // Multiplication with a large constant to further mix bits
    x ^= x >> 33; // Final bit mixing to remove patterns introduced by multiplication
    return x;
}

// Partition mapping
// Scalar version (baseline)
void compute_partitions(const std::vector<uint64_t>& keys,
                        std::vector<uint32_t>& part_id,
                        uint32_t P) {
    size_t N = keys.size();

    for (size_t i = 0; i < N; i++) {
        uint64_t h = hash64(keys[i]);
        // h % P   ≡   h & (P - 1)   (ONLY if P is power of 2)
        // division is slow/expensive, so we use bitwise AND which is faster/almost free
        part_id[i] = h & (P - 1);
    }
}

#ifdef USE_AVX2
void compute_partitions_avx2(const std::vector<uint64_t>& keys,
                             std::vector<uint32_t>& part_id,
                             uint32_t P) {
    size_t N = keys.size();
    size_t i = 0;
     
    // Constants 
    // Broadcast: same value in all 4 lanes
    // example: mask = [P-1, P-1, P-1, P-1]
    __m256i mask = _mm256_set1_epi64x(P - 1);
    __m256i mul_const = _mm256_set1_epi64x(0xff51afd7ed558ccd);

    for (; i + 4 <= N; i += 4) {
        // Load 4 keys
        // example: k = [keys[i], keys[i+1], keys[i+2], keys[i+3]]
        __m256i k = _mm256_loadu_si256((__m256i*)&keys[i]);

        // hash: x ^= x >> 33
        __m256i shift = _mm256_srli_epi64(k, 33);
        k = _mm256_xor_si256(k, shift);

        // x *= constant
        k = _mm256_mullo_epi64(k, mul_const);

        // x ^= x >> 33
        shift = _mm256_srli_epi64(k, 33);
        k = _mm256_xor_si256(k, shift);
        
        
        // Partition mapping: h & (P - 1)
        k = _mm256_and_si256(k, mask);
        
        /* ATTEMPT 1
        // CRITICAL BOTTLENECK //
        // Store (convert 64 → 32 bit)
        uint64_t temp[4];
        _mm256_storeu_si256((__m256i*)temp, k);

        for (int j = 0; j < 4; j++) {
            part_id[i + j] = (uint32_t)temp[j];
        }
        */
        
        /* ATTEMPT 2
        // Extract lower 32 bits from each 64-bit lane

        __m128i low = _mm256_castsi256_si128(k);         // k0, k1
        __m128i high = _mm256_extracti128_si256(k, 1);   // k2, k3

        // Mask lower 32 bits
        __m128i mask32 = _mm_set1_epi64x(0xFFFFFFFF);

        // keep lower 32 bits of each 64-bit lane.
        low = _mm_and_si128(low, mask32);
        high = _mm_and_si128(high, mask32);

        // Now we need to pack 64 → 32 manually
        uint32_t tmp[4];

        tmp[0] = (uint32_t)_mm_cvtsi128_si64(low);
        tmp[1] = (uint32_t)(_mm_extract_epi64(low, 1));
        tmp[2] = (uint32_t)_mm_cvtsi128_si64(high);
        tmp[3] = (uint32_t)(_mm_extract_epi64(high, 1));

        // store back into part_id 
        _mm_storeu_si128((__m128i*)&part_id[i], _mm_loadu_si128((__m128i*)tmp));
        */
       // ATTEMPT 3 Even optimized version fully SIMD
       __m256i mask32 = _mm256_set1_epi64x(0xFFFFFFFF);
       __m256i k32 = _mm256_and_si256(k, mask32);  // keep lower 32 bits
       __m128i lo = _mm256_castsi256_si128(k32);      // k0, k1
       __m128i hi = _mm256_extracti128_si256(k32, 1); // k2, k3
       lo = _mm_shuffle_epi32(lo, _MM_SHUFFLE(2,0,2,0)); // extract lower 32 bits of k0, k1
       hi = _mm_shuffle_epi32(hi, _MM_SHUFFLE(2,0,2,0)); // extract lower 32 bits of k2, k3
       __m128i result = _mm_unpacklo_epi32(lo, hi); // final 4x32-bit vector
       _mm_storeu_si128((__m128i*)&part_id[i], result);
    }

    // tail case
    // Handles leftover keys if N isn’t divisible by 4.
    for (; i < N; i++) {
        uint64_t h = hash64(keys[i]);
        part_id[i] = h & (P - 1);
    }
}
#endif