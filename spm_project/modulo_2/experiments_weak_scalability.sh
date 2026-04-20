#!/bin/bash

# Compile
g++ -O3 -march=native -std=c++20 hashjoin_seq.cpp -o hashjoin_par -pthread

BASE=1000000
P=256
SEED=42
MAXKEY=100000

RUNS=10

echo "==== WEAK SCALABILITY ===="

# Baseline (1 thread)
nt=1
NR=$BASE
NS=$BASE

base_total=0

for i in $(seq 1 $RUNS); do
    out=$(./hashjoin_par -nr $NR -ns $NS -seed $SEED -max-key $MAXKEY -p $P -nt 1)
    t=$(echo "$out" | grep "time_sec" | cut -d= -f2)
    base_total=$(echo "$base_total + $t" | bc -l)
done

T1=$(echo "$base_total / $RUNS" | bc -l)

echo "Baseline (1 thread): $T1 sec"
echo ""

# Weak scaling loop
for nt in 1 2 4 8 16 32 64; do

    NR=$(($BASE * $nt))
    NS=$(($BASE * $nt))

    par_total=0

    for i in $(seq 1 $RUNS); do
        out=$(./hashjoin_par -nr $NR -ns $NS -seed $SEED -max-key $MAXKEY -p $P -nt $nt)
        t=$(echo "$out" | grep "time_sec" | cut -d= -f2)
        par_total=$(echo "$par_total + $t" | bc -l)
    done

    Tn=$(echo "$par_total / $RUNS" | bc -l)

    weak_eff=$(echo "$T1 / $Tn" | bc -l)

    echo "Threads=$nt | NR=$NR | Time=$Tn | WeakEff=$weak_eff"
done