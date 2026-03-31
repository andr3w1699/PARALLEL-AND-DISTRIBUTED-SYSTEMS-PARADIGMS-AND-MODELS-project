#include "partition_cuda.cuh"
#include <cuda_runtime.h>
#include <iostream>

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
// HOST FUNCTION
// ==========================
void compute_partitions_cuda(const uint64_t* keys,
                             uint32_t* part_id,
                             size_t N,
                             uint32_t P) {

    uint64_t* d_keys;
    uint32_t* d_part;

    size_t keys_size = N * sizeof(uint64_t);
    size_t part_size = N * sizeof(uint32_t);

    // Events
    cudaEvent_t start_H2D, end_H2D;
    cudaEvent_t start_kernel, end_kernel;
    cudaEvent_t start_D2H, end_D2H;

    cudaEventCreate(&start_H2D);
    cudaEventCreate(&end_H2D);
    cudaEventCreate(&start_kernel);
    cudaEventCreate(&end_kernel);
    cudaEventCreate(&start_D2H);
    cudaEventCreate(&end_D2H);

    // Allocate device
    cudaMalloc(&d_keys, keys_size);
    cudaMalloc(&d_part, part_size);

    // ==========================
    // H → D
    // ==========================
    cudaEventRecord(start_H2D);
    cudaMemcpy(d_keys, keys, keys_size, cudaMemcpyHostToDevice);
    cudaEventRecord(end_H2D);
    cudaEventSynchronize(end_H2D);

    // ==========================
    // Kernel launch
    // ==========================
    int blockSize = 256;
    int gridSize = 1024;  // fixed large grid (better occupancy)

    cudaEventRecord(start_kernel);
    partition_kernel<<<gridSize, blockSize>>>(d_keys, d_part, N, P);
    cudaEventRecord(end_kernel);
    cudaEventSynchronize(end_kernel);

    // ==========================
    // D → H
    // ==========================
    cudaEventRecord(start_D2H);
    cudaMemcpy(part_id, d_part, part_size, cudaMemcpyDeviceToHost);
    cudaEventRecord(end_D2H);
    cudaEventSynchronize(end_D2H);

    // ==========================
    // Timing
    // ==========================
    float tH2D, tKernel, tD2H;

    cudaEventElapsedTime(&tH2D, start_H2D, end_H2D);
    cudaEventElapsedTime(&tKernel, start_kernel, end_kernel);
    cudaEventElapsedTime(&tD2H, start_D2H, end_D2H);

    std::cout << "H2D time (ms): " << tH2D << "\n";
    std::cout << "Kernel time (ms): " << tKernel << "\n";
    std::cout << "D2H time (ms): " << tD2H << "\n";

    // cleanup
    cudaFree(d_keys);
    cudaFree(d_part);

    cudaEventDestroy(start_H2D);
    cudaEventDestroy(end_H2D);
    cudaEventDestroy(start_kernel);
    cudaEventDestroy(end_kernel);
    cudaEventDestroy(start_D2H);
    cudaEventDestroy(end_D2H);
}