#!/bin/bash

set -e

# Number of runs
RUNS=100

# Temporary files for storing times and checksums
TMP_OUTPUT=$(mktemp)
TMP_TIMES=$(mktemp)

# Executable names
EXES=("partition_novec" "partition_vec" "partition_avx2")
EXE_LABELS=("novec" "vec" "avx2")

# Clean old builds
echo "Compiling all variants..."
rm -f src/main.o src/partition.o "${EXES[@]}"

# Compile novec (no vectorization)
g++ -std=c++20 -Wall -Wextra -O3 -fno-tree-vectorize src/main.cpp src/partition.cpp -o partition_novec

# Compile vec (auto-vectorization)
g++ -std=c++20 -Wall -Wextra -O3 -march=native -fopt-info-vec-all src/main.cpp src/partition.cpp -o partition_vec

# Compile avx2
g++ -std=c++20 -Wall -Wextra -O3 -march=native -mavx2 -DUSE_AVX2 src/main.cpp src/partition.cpp -o partition_avx2

# Arrays to store results
declare -A AVG
declare -A VAR
declare -A CHECKSUMS

# Function to compute average and variance from array of numbers
function compute_stats {
    local arr=("$@")
    local sum=0
    local sumsq=0
    local n=${#arr[@]}
    for x in "${arr[@]}"; do
        sum=$(echo "$sum + $x" | bc -l)
        sumsq=$(echo "$sumsq + ($x * $x)" | bc -l)
    done
    local avg=$(echo "$sum / $n" | bc -l)
    local var=$(echo "($sumsq / $n) - ($avg * $avg)" | bc -l)
    echo "$avg $var"
}

# Run each executable
for idx in ${!EXES[@]}; do
    exe=${EXES[$idx]}
    label=${EXE_LABELS[$idx]}
    echo "Running $label $RUNS times..."

    TIMES=()
    CHECKSUM=""

    for ((i=0;i<RUNS;i++)); do
        ./$exe > $TMP_OUTPUT
        time=$(grep "Time:" $TMP_OUTPUT | awk '{print $2}')
        checksum=$(grep "Checksum:" $TMP_OUTPUT | awk '{print $2}')
        TIMES+=($time)
        if [ -z "$CHECKSUM" ]; then
            CHECKSUM=$checksum
        elif [ "$CHECKSUM" != "$checksum" ]; then
            echo "Warning: checksum mismatch on run $i for $label"
        fi
    done

    CHECKSUMS[$label]=$CHECKSUM
    read avg var <<< $(compute_stats "${TIMES[@]}")
    AVG[$label]=$avg
    VAR[$label]=$var
done

# Check if all checksums match
echo "Checksums:"
for label in "${EXE_LABELS[@]}"; do
    echo "$label: ${CHECKSUMS[$label]}"
done

first_checksum=${CHECKSUMS[novec]}
all_match=true
for label in "${EXE_LABELS[@]}"; do
    if [ "${CHECKSUMS[$label]}" != "$first_checksum" ]; then
        all_match=false
        break
    fi
done

if [ "$all_match" = true ]; then
    echo "All checksums match."
else
    echo "⚠ Checksums differ!"
fi

# Print execution times and speedups
echo ""
echo "Execution times (avg sec, variance sec^2):"
for label in "${EXE_LABELS[@]}"; do
    echo "$label: avg=${AVG[$label]} var=${VAR[$label]}"
done

echo ""
echo "Speedups relative to novec:"
novec_avg=${AVG[novec]}
for label in "${EXE_LABELS[@]}"; do
    speedup=$(echo "$novec_avg / ${AVG[$label]}" | bc -l)
    echo "$label: $speedup"
done

# Clean up
rm -f $TMP_OUTPUT $TMP_TIMES