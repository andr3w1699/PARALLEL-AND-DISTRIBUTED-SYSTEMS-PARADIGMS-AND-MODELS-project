#include "partition_cuda.cuh"
#include <cuda_runtime.h>
#include <iostream>

// ==========================
// Device hash
// ==========================
// __device__: runs on GPU, callable from GPU only
// __forceinline__: compiler hint to inline the function
__device__ __forceinline__ uint64_t hash64(uint64_t x) {
    x ^= x >> 33;
    x *= 0xff51afd7ed558ccdULL;
    x ^= x >> 33;
    return x;
}

// ==========================
// CUDA kernel
// ==========================
//__global__: callable from CPU, runs on GPU
__global__ void partition_kernel(const uint64_t* keys,
                                 uint32_t* part_id,
                                 size_t N,
                                 uint32_t P) {
    
    // thread indexing
    // blockIdx.x: which block in the grid
    // blockDim.x: how many threads per block
    // threadIdx.x: which thread in the block
    size_t i = blockIdx.x * blockDim.x + threadIdx.x;

    // boundary check 
    if (i < N) {
        // work per thread
        uint64_t h = hash64(keys[i]);
        part_id[i] = h & (P - 1);
    }
}

// ==========================
// Host wrapper with timings
// ==========================
// host function: CPU controls GPU execution
void compute_partitions_cuda(const uint64_t* keys,
                             uint32_t* part_id,
                             size_t N,
                             uint32_t P) {
    // device pointers
    // d_ prefix means storage on the device (GPU)                            
    uint64_t* d_keys;
    uint32_t* d_part;

    // sizes in bytes
    size_t keys_size = N * sizeof(uint64_t);
    size_t part_size = N * sizeof(uint32_t);

    // CUDA events for GPU timing
    cudaEvent_t start_H2D, end_H2D;
    cudaEvent_t start_kernel, end_kernel;
    cudaEvent_t start_D2H, end_D2H;

    // allocate event objects
    cudaEventCreate(&start_H2D);
    cudaEventCreate(&end_H2D);
    cudaEventCreate(&start_kernel);
    cudaEventCreate(&end_kernel);
    cudaEventCreate(&start_D2H);
    cudaEventCreate(&end_D2H);

    // -------------------------
    // Allocate memory on GPU
    // -------------------------
    cudaMalloc(&d_keys, keys_size);
    cudaMalloc(&d_part, part_size);

    // -------------------------
    // H → D
    // -------------------------
    cudaEventRecord(start_H2D);
    cudaMemcpy(d_keys, keys, keys_size, cudaMemcpyHostToDevice);
    cudaEventRecord(end_H2D);
    cudaEventSynchronize(end_H2D); // wait until the copy finishes

    // -------------------------
    // Kernel launch
    // -------------------------
    int blockSize = 256; // threads per block
    int gridSize = (N + blockSize - 1) / blockSize; // enough treads to cover N elements

    cudaEventRecord(start_kernel);
    partition_kernel<<<gridSize, blockSize>>>(d_keys, d_part, N, P);
    cudaEventRecord(end_kernel);
    cudaEventSynchronize(end_kernel);

    // -------------------------
    // D → H
    // -------------------------
    cudaEventRecord(start_D2H);
    cudaMemcpy(part_id, d_part, part_size, cudaMemcpyDeviceToHost);
    cudaEventRecord(end_D2H);
    cudaEventSynchronize(end_D2H);

    // -------------------------
    // Compute times separately
    // time to copy from Host to Device, time to execute the kernel, time to copy from Device to Host
    // -------------------------
    float time_H2D = 0, time_kernel = 0, time_D2H = 0;

    cudaEventElapsedTime(&time_H2D, start_H2D, end_H2D);
    cudaEventElapsedTime(&time_kernel, start_kernel, end_kernel);
    cudaEventElapsedTime(&time_D2H, start_D2H, end_D2H);

    std::cout << "H2D time (ms): " << time_H2D << "\n";
    std::cout << "Kernel time (ms): " << time_kernel << "\n";
    std::cout << "D2H time (ms): " << time_D2H << "\n";

    // free
    cudaFree(d_keys);
    cudaFree(d_part);

    cudaEventDestroy(start_H2D);
    cudaEventDestroy(end_H2D);
    cudaEventDestroy(start_kernel);
    cudaEventDestroy(end_kernel);
    cudaEventDestroy(start_D2H);
    cudaEventDestroy(end_D2H);
}