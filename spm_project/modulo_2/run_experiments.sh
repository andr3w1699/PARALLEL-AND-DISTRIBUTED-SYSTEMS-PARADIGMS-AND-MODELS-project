#!/bin/bash

# Compile
g++ -O3 -march=native -std=c++20 hashjoin_seq.cpp -o hashjoin_seq
g++ -O3 -march=native -std=c++20 -pthread hashjoin_seq.cpp -o hashjoin_par

NR=1000000
NS=1000000
P=256
SEED=42
MAXKEY=100000

RUNS=25

echo "==== SEQUENTIAL ===="

seq_total=0

for i in $(seq 1 $RUNS); do
    out=$(./hashjoin_seq -nr $NR -ns $NS -seed $SEED -max-key $MAXKEY -p $P -nt 1) # nt is ignored in sequential version, but we set it to 1 for clarity
    t=$(echo "$out" | grep "time_sec" | cut -d= -f2)
    seq_total=$(echo "$seq_total + $t" | bc -l)
done

seq_avg=$(echo "$seq_total / $RUNS" | bc -l)
echo "SEQ AVG TIME = $seq_avg"

echo ""
echo "==== PARALLEL ===="

for nt in 0 2 4 8 16 32 64 128; do
    par_total=0

    for i in $(seq 1 $RUNS); do
        out=$(./hashjoin_par -nr $NR -ns $NS -seed $SEED -max-key $MAXKEY -p $P -nt $nt)
        t=$(echo "$out" | grep "time_sec" | cut -d= -f2)
        par_total=$(echo "$par_total + $t" | bc -l)
    done

    par_avg=$(echo "$par_total / $RUNS" | bc -l)

    speedup=$(echo "$seq_avg / $par_avg" | bc -l)

    echo "Threads=$nt | Time=$par_avg | Speedup=$speedup"
done