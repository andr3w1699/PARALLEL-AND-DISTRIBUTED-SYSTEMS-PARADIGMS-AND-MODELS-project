#include "partition.h"
#include <immintrin.h>

// ==========================
// SCALAR VERSION (AUTO-VECTORIZABLE)
// ==========================
void compute_partitions(const uint64_t* __restrict__ keys,
                        uint32_t* __restrict__ part_id,
                        size_t N,
                        uint32_t P) {

    uint64_t mask = P - 1;

    size_t i = 0;

    // unroll x4
    #pragma GCC ivdep
    for (; i + 4 <= N; i += 4) {

        /*
        // PREFETCH (64 elements ahead ≈ 512 bytes)
        if (i + 64 < N) {
        _mm_prefetch((const char*)&keys[i + 64], _MM_HINT_T0);
        }
        */

        uint64_t x0 = keys[i];
        uint64_t x1 = keys[i+1];
        uint64_t x2 = keys[i+2];
        uint64_t x3 = keys[i+3];

        x0 ^= x0 >> 33; x0 *= 0xff51afd7ed558ccd; x0 ^= x0 >> 33;
        x1 ^= x1 >> 33; x1 *= 0xff51afd7ed558ccd; x1 ^= x1 >> 33;
        x2 ^= x2 >> 33; x2 *= 0xff51afd7ed558ccd; x2 ^= x2 >> 33;
        x3 ^= x3 >> 33; x3 *= 0xff51afd7ed558ccd; x3 ^= x3 >> 33;

        part_id[i]   = x0 & mask;
        part_id[i+1] = x1 & mask;
        part_id[i+2] = x2 & mask;
        part_id[i+3] = x3 & mask;
    }

    // tail
    for (; i < N; i++) {
        uint64_t x = keys[i];
        x ^= x >> 33;
        x *= 0xff51afd7ed558ccd;
        x ^= x >> 33;
        part_id[i] = x & mask;
    }
}

#ifdef USE_AVX2

// 64-bit multiply workaround
static inline __m256i mul64_avx2(__m256i a, __m256i b) {

    __m256i b_swap = _mm256_shuffle_epi32(b, _MM_SHUFFLE(2,3,0,1));
    __m256i cross  = _mm256_mullo_epi32(a, b_swap);

    __m256i prodlh = _mm256_slli_epi64(cross, 32);
    __m256i prodhl = _mm256_and_si256(cross, _mm256_set1_epi64x(0xFFFFFFFF00000000ULL));
    __m256i sum    = _mm256_add_epi32(prodlh, prodhl);

    __m256i prodll = _mm256_mul_epu32(a, b);

    return _mm256_add_epi32(prodll, sum);
}

// ==========================
// AVX2 VERSION (UNROLLED x2)
// ==========================
void compute_partitions_avx2(const uint64_t* __restrict__ keys,
                            uint32_t* __restrict__ part_id,
                            size_t N,
                            uint32_t P) {

    size_t i = 0;

    __m256i mask = _mm256_set1_epi64x(P - 1);
    __m256i mulc = _mm256_set1_epi64x(0xff51afd7ed558ccd);

    // process 8 elements per iteration
    for (; i + 8 <= N; i += 8) {

        // PREFETCH future data (128 elements ahead)
        if (i + 8 < N) {
        _mm_prefetch((const char*)&keys[i + 128], _MM_HINT_T0);
        }

        __m256i k0 = _mm256_load_si256((__m256i*)&keys[i]);
        __m256i k1 = _mm256_load_si256((__m256i*)&keys[i+4]);

        __m256i s;

        // hash k0
        s = _mm256_srli_epi64(k0, 33);
        k0 = _mm256_xor_si256(k0, s);
        k0 = mul64_avx2(k0, mulc);
        s = _mm256_srli_epi64(k0, 33);
        k0 = _mm256_xor_si256(k0, s);

        // hash k1
        s = _mm256_srli_epi64(k1, 33);
        k1 = _mm256_xor_si256(k1, s);
        k1 = mul64_avx2(k1, mulc);
        s = _mm256_srli_epi64(k1, 33);
        k1 = _mm256_xor_si256(k1, s);

        k0 = _mm256_and_si256(k0, mask);
        k1 = _mm256_and_si256(k1, mask);

        // pack 64 → 32
        __m128i lo0 = _mm256_castsi256_si128(k0);
        __m128i hi0 = _mm256_extracti128_si256(k0, 1);
        __m128i lo1 = _mm256_castsi256_si128(k1);
        __m128i hi1 = _mm256_extracti128_si256(k1, 1);

        __m128i out0 = _mm_set_epi32(
            _mm_extract_epi32(hi0, 2),
            _mm_extract_epi32(hi0, 0),
            _mm_extract_epi32(lo0, 2),
            _mm_extract_epi32(lo0, 0)
        );

        __m128i out1 = _mm_set_epi32(
            _mm_extract_epi32(hi1, 2),
            _mm_extract_epi32(hi1, 0),
            _mm_extract_epi32(lo1, 2),
            _mm_extract_epi32(lo1, 0)
        );

        _mm_store_si128((__m128i*)&part_id[i], out0);
        _mm_store_si128((__m128i*)&part_id[i+4], out1);
    }

    // tail
    for (; i < N; i++) {
        uint64_t x = keys[i];
        x ^= x >> 33;
        x *= 0xff51afd7ed558ccd;
        x ^= x >> 33;
        part_id[i] = x & (P - 1);
    }
}

#endif