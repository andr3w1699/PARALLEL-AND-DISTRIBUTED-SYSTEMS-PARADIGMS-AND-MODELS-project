#!/bin/bash

set -e  # stop on error

# -----------------------------
# Configuration
# -----------------------------
N=$((1<<24))   # must match main.cpp
RUNS=100         # number of repetitions

SCALAR_BIN=partition_scalar
OPT_BIN=partition_opt
AVX_BIN=partition_avx2

# -----------------------------
# Compilation
# -----------------------------
echo "Compiling versions..."

# Scalar (no vectorization)
g++ -O3 -fno-tree-vectorize -march=native main.cpp partition.cpp -o $SCALAR_BIN

# Optimized scalar (auto-vectorization)
g++ -O3 -march=native -fopt-info-vec-all main.cpp partition.cpp -o $OPT_BIN

# AVX2 version
g++ -O3 -march=native -mavx2 -DUSE_AVX2 main.cpp partition.cpp -o $AVX_BIN

echo "Compilation done."
echo ""

# -----------------------------
# Function to measure average time
# -----------------------------
run_test() {
    BIN=$1
    TOTAL=0

    echo "Running $BIN ..."

    for ((i=0; i<$RUNS; i++)); do
        OUTPUT=$(./$BIN)

        # extract time
        TIME=$(echo "$OUTPUT" | grep "Time:" | awk '{print $2}')

        echo "  Run $i: $TIME s"

        TOTAL=$(echo "$TOTAL + $TIME" | bc -l)
    done

    AVG=$(echo "$TOTAL / $RUNS" | bc -l)
    echo "Average time for $BIN: $AVG s"
    echo ""

    echo $AVG
}

# -----------------------------
# Run benchmarks
# -----------------------------
T_SCALAR=$(run_test $SCALAR_BIN | tail -n1)
T_OPT=$(run_test $OPT_BIN | tail -n1)
T_AVX=$(run_test $AVX_BIN | tail -n1)

# -----------------------------
# Compute metrics
# -----------------------------
echo "=============================="
echo " RESULTS"
echo "=============================="

echo "Scalar time: $T_SCALAR s"
echo "Optimized time: $T_OPT s"
echo "AVX2 time: $T_AVX s"
echo ""

# Speedups
SPEEDUP_OPT=$(echo "$T_SCALAR / $T_OPT" | bc -l)
SPEEDUP_AVX=$(echo "$T_SCALAR / $T_AVX" | bc -l)

echo "Speedup (opt vs scalar): $SPEEDUP_OPT"
echo "Speedup (AVX2 vs scalar): $SPEEDUP_AVX"
echo ""

# Throughput (elements/sec)
TH_SCALAR=$(echo "$N / $T_SCALAR" | bc -l)
TH_OPT=$(echo "$N / $T_OPT" | bc -l)
TH_AVX=$(echo "$N / $T_AVX" | bc -l)

echo "Throughput (elements/sec):"
echo "  Scalar: $TH_SCALAR"
echo "  Optimized: $TH_OPT"
echo "  AVX2: $TH_AVX"

echo ""
echo "Done."