#!/bin/bash

# =========================
# CONFIG
# =========================
RUNS=50

# =========================
# BUILD ALL TARGETS
# =========================
echo "Building all versions..."
make clean
make novec
make vec
make avx2
make novec_optimized
make vec_optimized
make avx2_optimized
make cuda
make cuda2
make cuda3
echo "Build completed."
echo

# =========================
# FUNCTION TO RUN BENCHMARK
# =========================
run_benchmark() {
    exe=$1
    label=$2
    pattern=$3

    sum=0
    sum_sq=0

    echo "Running $label ..."

    for i in $(seq 1 $RUNS); do
        output=$(./$exe)   # CPU programs do not take arguments

        # Extract time (number before 's')
        time=$(echo "$output" | grep "$pattern" | awk '{print $(NF-1)}')

        # Accumulate
        sum=$(echo "$sum + $time" | bc -l)
        sum_sq=$(echo "$sum_sq + ($time * $time)" | bc -l)
    done

    avg=$(echo "$sum / $RUNS" | bc -l)
    var=$(echo "($sum_sq / $RUNS) - ($avg * $avg)" | bc -l)
    std=$(echo "sqrt($var)" | bc -l)

    # Print results
    echo "$label AVG: $avg s"
    echo "$label STD: $std s"
    echo

    # Export results for speedup calculation
    eval "${label}_avg=$avg"
    eval "${label}_std=$std"
}

# =========================
# CPU BENCHMARKS
# =========================
run_benchmark "partition_novec" "novec" "Time:"
run_benchmark "partition" "vec" "Time:"
run_benchmark "partition_avx2" "avx2" "Time:"
run_benchmark "partition_novec_optimized" "novec_opt" "Time:"
run_benchmark "partition_optimized" "vec_opt" "Time:"
run_benchmark "partition_avx2_optimized" "avx2_opt" "Time:"

# =========================
# CUDA BENCHMARKS
# =========================
run_benchmark "partition_cuda" "cuda_v1" "Total CUDA time:"
run_benchmark "partition_cuda_2" "cuda_v2" "Total CUDA time:"
run_benchmark "partition_cuda_3" "cuda_v3" "Total CUDA time:"

# =========================
# SPEEDUPS (vs novec)
# =========================
echo "========================="
echo "SPEEDUPS (vs novec)"
echo "========================="

compute_speedup() {
    base=$1
    other=$2
    label=$3

    speedup=$(echo "$base / $other" | bc -l)
    echo "$label: $speedup x"
}

compute_speedup $novec_avg $vec_avg "vec vs novec"
compute_speedup $novec_avg $avx2_avg "avx2 vs novec"
compute_speedup $novec_avg $novec_opt_avg "novec_opt vs novec"
compute_speedup $novec_avg $vec_opt_avg "vec_opt vs novec"
compute_speedup $novec_avg $avx2_opt_avg "avx2_opt vs novec"
compute_speedup $novec_avg $cuda_v1_avg "cuda_v1 vs novec"
compute_speedup $novec_avg $cuda_v2_avg "cuda_v2 vs novec"
compute_speedup $novec_avg $cuda_v3_avg "cuda_v3 vs novec"

echo
echo "Benchmark completed."