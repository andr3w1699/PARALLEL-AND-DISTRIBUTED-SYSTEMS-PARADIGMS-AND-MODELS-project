
#!/bin/bash
# =========================
# CONFIGURATION
# =========================
RUNS=20  # Number of runs for each version
# Fixed number of elements (must match the value in your main programs)
N=16777216  # 1<<24

# =========================
# BUILD ALL BINARIES
# =========================
echo "Building all binaries..."
make clean
make all
echo "Build completed."
echo

# =========================
# BENCHMARK FUNCTION
# =========================
# Arguments: exe label pattern
run_benchmark() {
    exe=$1
    label=$2
    pattern=$3

    sum=0
    sum_sq=0
    times=()

    echo "Running $label ..."


    for i in $(seq 1 $RUNS); do
        # Run without arguments (N is fixed in the code)
        output=$(./$exe)
        # Extract time (number before 's' or ms)
        time=$(echo "$output" | grep "$pattern" | awk '{print $(NF-1)}')
        times+=("$time")
        sum=$(echo "$sum + $time" | bc -l)
        sum_sq=$(echo "$sum_sq + ($time * $time)" | bc -l)
    done

    avg=$(echo "$sum / $RUNS" | bc -l)
    var=$(echo "($sum_sq / $RUNS) - ($avg * $avg)" | bc -l)
    std=$(echo "sqrt($var)" | bc -l)

    # Throughput: N / avg_time (convert ms to s if needed)
    if [[ "$pattern" == *ms* ]]; then
        avg_s=$(echo "$avg / 1000" | bc -l)
    else
        avg_s=$avg
    fi
    throughput=$(echo "$N / $avg_s" | bc -l)

    # Print results
    echo "$label AVG: $avg_s s"
    echo "$label STD: $std s"
    echo "$label THROUGHPUT: $throughput keys/s"
    echo

    # Export for speedup calculation
    eval "${label}_avg=$avg_s"
    eval "${label}_std=$std"
    eval "${label}_throughput=$throughput"
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