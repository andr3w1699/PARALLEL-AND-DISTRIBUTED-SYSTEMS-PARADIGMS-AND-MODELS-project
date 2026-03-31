#!/bin/bash

# =========================
# Build all versions
# =========================
make cuda
make cuda2
make cuda3

# =========================
# Variables
# =========================
RUNS=100

sum_v1=0
sum_v2=0
sum_v3=0

echo "Running Version 1 (baseline)..."

# =========================
# Version 1
# =========================
for i in $(seq 1 $RUNS)
do
    output=$(./partition_cuda)

    time=$(echo "$output" | grep "Total CUDA time" | awk '{print $4}')

    sum_v1=$(echo "$sum_v1 + $time" | bc -l)
done

avg_v1=$(echo "$sum_v1 / $RUNS" | bc -l)

echo "Average time V1: $avg_v1 s"

# =========================
# Version 2
# =========================
echo "Running Version 2 (optimized)..."

for i in $(seq 1 $RUNS)
do
    output=$(./partition_cuda_2)

    time=$(echo "$output" | grep "Total CUDA time" | awk '{print $4}')

    sum_v2=$(echo "$sum_v2 + $time" | bc -l)
done

avg_v2=$(echo "$sum_v2 / $RUNS" | bc -l)

echo "Average time V2: $avg_v2 s"

# =========================
# Version 3
# =========================
echo "Running Version 3 (advanced)..."

for i in $(seq 1 $RUNS)
do
    output=$(./partition_cuda_3)

    time=$(echo "$output" | grep "Total CUDA time" | awk '{print $4}')

    sum_v3=$(echo "$sum_v3 + $time" | bc -l)
done

avg_v3=$(echo "$sum_v3 / $RUNS" | bc -l)

echo "Average time V3: $avg_v3 s"

# =========================
# Speedups
# =========================
speedup_v2v1=$(echo "$avg_v1 / $avg_v2" | bc -l)
speedup_v3v1=$(echo "$avg_v1 / $avg_v3" | bc -l)
speedup_v3v2=$(echo "$avg_v2 / $avg_v3" | bc -l)

echo "Speedup (V2 vs V1): $speedup_v2v1 x"
echo "Speedup (V3 vs V1): $speedup_v3v1 x"
echo "Speedup (V3 vs V2): $speedup_v3v2 x"