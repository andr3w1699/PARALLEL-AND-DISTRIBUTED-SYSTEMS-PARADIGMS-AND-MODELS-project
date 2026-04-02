#ifndef PARTITION_CUDA_CUH
#define PARTITION_CUDA_CUH

#include <cstdint>
#include <cstddef>

void compute_partitions_cuda(const uint64_t* keys,
                             uint32_t* part_id,
                             size_t N,
                             uint32_t P);

#endif