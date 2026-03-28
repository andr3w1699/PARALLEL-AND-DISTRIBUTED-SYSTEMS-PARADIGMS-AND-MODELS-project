# Compiler
CXX = g++

# Base flags
CXXFLAGS = -std=c++17 -Wall -Wextra

# Optimization flags
# OPTFLAGS = -O3 -march=native
OPTFLAGS = -O3 -march=native -mavx2

# Vectorization report
VECFLAGS = -fopt-info-vec-all

# Target
TARGET = partition

# Source files
SRC = src/main.cpp src/partition.cpp

# Object files
OBJ = $(SRC:.cpp=.o)

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CXX) $(CXXFLAGS) $(OPTFLAGS) -o $@ $^

%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(OPTFLAGS) -c $< -o $@

# Build with vectorization report
vec:
	$(CXX) $(CXXFLAGS) $(OPTFLAGS) $(VECFLAGS) $(SRC) -o $(TARGET)

novec:
	$(CXX) $(CXXFLAGS) -O3 -fno-tree-vectorize $(SRC) -o $(TARGET)_novec

# Clean
clean:
	rm -f $(OBJ) $(TARGET) $(TARGET)_novec