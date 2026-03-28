#ifndef PARTITION_H
#define PARTITION_H

#include <vector>
#include <cstdint>

uint64_t hash64(uint64_t x);

void compute_partitions(const std::vector<uint64_t>& keys,
                        std::vector<uint32_t>& part_id,
                        uint32_t P);

void compute_partitions_avx2(const std::vector<uint64_t>& keys,
                             std::vector<uint32_t>& part_id,
                             uint32_t P);
#endif