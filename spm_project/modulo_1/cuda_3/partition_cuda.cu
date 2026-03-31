#include "partition_cuda.cuh"
#include <cuda_runtime.h>
#include <iostream>

#define NUM_STREAMS 4

// ==========================
// Device hash
// ==========================
__device__ __forceinline__ uint64_t hash64(uint64_t x) {
    x ^= x >> 33;
    x *= 0xff51afd7ed558ccdULL;
    x ^= x >> 33;
    return x;
}

// ==========================
// GRID-STRIDE KERNEL
// ==========================
__global__ void partition_kernel(const uint64_t* keys,
                                 uint32_t* part_id,
                                 size_t N,
                                 uint32_t P) {

    size_t tid = blockIdx.x * blockDim.x + threadIdx.x;
    size_t stride = blockDim.x * gridDim.x;

    for (size_t i = tid; i < N; i += stride) {
        uint64_t h = hash64(keys[i]);
        part_id[i] = h & (P - 1);
    }
}

// ==========================
// ADVANCED HOST FUNCTION
// ==========================
void compute_partitions_cuda(const uint64_t* keys,
                             uint32_t* part_id,
                             size_t N,
                             uint32_t P) {

    size_t chunk_size = N / NUM_STREAMS;

    cudaStream_t streams[NUM_STREAMS];
    uint64_t* d_keys[NUM_STREAMS];
    uint32_t* d_part[NUM_STREAMS];

    // Events for total time
    cudaEvent_t start_total, end_total;
    cudaEventCreate(&start_total);
    cudaEventCreate(&end_total);

    cudaEventRecord(start_total);

    // ==========================
    // Init streams + device memory
    // ==========================
    for (int i = 0; i < NUM_STREAMS; i++) {
        cudaStreamCreate(&streams[i]);

        cudaMalloc(&d_keys[i], chunk_size * sizeof(uint64_t));
        cudaMalloc(&d_part[i], chunk_size * sizeof(uint32_t));
    }

    int blockSize = 256;
    int gridSize = 512;

    // ==========================
    // PIPELINE
    // ==========================
    for (int i = 0; i < NUM_STREAMS; i++) {

        size_t offset = i * chunk_size;

        // H → D (async)
        cudaMemcpyAsync(d_keys[i],
                        keys + offset,
                        chunk_size * sizeof(uint64_t),
                        cudaMemcpyHostToDevice,
                        streams[i]);

        // Kernel (async)
        partition_kernel<<<gridSize, blockSize, 0, streams[i]>>>(
            d_keys[i], d_part[i], chunk_size, P);

        // D → H (async)
        cudaMemcpyAsync(part_id + offset,
                        d_part[i],
                        chunk_size * sizeof(uint32_t),
                        cudaMemcpyDeviceToHost,
                        streams[i]);
    }

    // ==========================
    // Synchronize all streams
    // ==========================
    for (int i = 0; i < NUM_STREAMS; i++) {
        cudaStreamSynchronize(streams[i]);
    }

    cudaEventRecord(end_total);
    cudaEventSynchronize(end_total);

    float total_ms;
    cudaEventElapsedTime(&total_ms, start_total, end_total);

    std::cout << "Total CUDA async time (ms): " << total_ms << "\n";

    // ==========================
    // Cleanup
    // ==========================
    for (int i = 0; i < NUM_STREAMS; i++) {
        cudaFree(d_keys[i]);
        cudaFree(d_part[i]);
        cudaStreamDestroy(streams[i]);
    }

    cudaEventDestroy(start_total);
    cudaEventDestroy(end_total);
}