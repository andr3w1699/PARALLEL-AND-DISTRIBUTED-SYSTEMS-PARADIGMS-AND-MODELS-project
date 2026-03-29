# Compiler
CXX = g++

# Base flags
CXXFLAGS = -std=c++20 -Wall -Wextra

# Optimization flags
# -O3 enables aggressive optimizations, inlining, loop unrolling, vectorization
# -march=native enables instructions specific to the host CPU and AVX2 automaticcally if supported
# -mavx2 Explicitly enable AVX2 instructions (safe for intrinsics) 
OPTFLAGS = -O3 -march=native
#OPTFLAGS = -O3 -march=native -mavx2

# Vectorization report
VECFLAGS = -fopt-info-vec-all

# Target
TARGET = partition

# Source files
SRC = src/main.cpp src/partition.cpp

# Object files
# pattern substitution for example: src/main.cpp -> src/main.o, src/partition.cpp -> src/partition.o,...
OBJ = $(SRC:.cpp=.o)

# default target: it builds partition executable
all: $(TARGET)

# Linking step: $@ → target name, $^ → all dependencies (object files .o)
# equivalent to g++ flags -o partition src/main.o src/partition.o
$(TARGET): $(OBJ)
	$(CXX) $(CXXFLAGS) $(OPTFLAGS) -o $@ $^
# Compilation rule. Generic rule: $< input file, $@ output file
# Example g++ flags -c src/main.cpp -o src/main.o
%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(OPTFLAGS) -c $< -o $@

# Vectorization build with vectorization report
# to run make vec on Bash
vec:
	$(CXX) $(CXXFLAGS) $(OPTFLAGS) $(VECFLAGS) $(SRC) -o $(TARGET)
# no vectorization build: -fno-tree-vectorize disables compiler auto-vectorization
novec:
	$(CXX) $(CXXFLAGS) -O3 -fno-tree-vectorize $(SRC) -o $(TARGET)_novec
# AVX2 intrinsics build (requires AVX2 enabled)
avx2:
	$(CXX) $(CXXFLAGS) $(OPTFLAGS) -mavx2 -DUSE_AVX2 $(SRC) -o $(TARGET)_avx2

# Clean
clean:
	rm -f $(OBJ) $(TARGET) $(TARGET)_novec $(TARGET)_avx2 $(TARGET)_vec