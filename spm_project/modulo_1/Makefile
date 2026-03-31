# =========================
# CPU COMPILER
# =========================
CXX = g++

# =========================
# CUDA COMPILER
# =========================
NVCC = nvcc

# =========================
# FLAGS
# =========================
CXXFLAGS = -std=c++20 -Wall -Wextra

OPTFLAGS = -O3 -march=native
VECFLAGS = -fopt-info-vec-all

# CUDA flags
CUDAFLAGS = -O3

# =========================
# TARGETS
# =========================
TARGET = partition
CUDA_TARGET = partition_cuda

# =========================
# SOURCE FILES
# =========================
#SRC = src/main.cpp src/partition.cpp
OBJ = $(SRC:.cpp=.o)

CUDA_SRC = src/main_cuda.cu src/partition_cuda.cu
CUDA2_SRC = cuda_2/main_cuda.cu cuda_2/partition_cuda.cu
CUDA3_SRC = cuda_3/main_cuda.cu cuda_3/partition_cuda.cu

# =========================
# DEFAULT BUILD
# =========================
all: $(TARGET)

# =========================
# CPU BUILD
# =========================
$(TARGET): $(OBJ)
	$(CXX) $(CXXFLAGS) $(OPTFLAGS) -o $@ $^

%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(OPTFLAGS) -c $< -o $@

# =========================
# VECTOR REPORT
# =========================
vec:
	$(CXX) $(CXXFLAGS) $(OPTFLAGS) $(VECFLAGS) $(SRC) -o $(TARGET)

# =========================
# NO VECTORIZATION
# =========================
novec:
	$(CXX) $(CXXFLAGS) -O3 -fno-tree-vectorize $(SRC) -o $(TARGET)_novec

# =========================
# AVX2 VERSION
# =========================
avx2:
	$(CXX) $(CXXFLAGS) $(OPTFLAGS) -mavx2 -DUSE_AVX2 $(SRC) -o $(TARGET)_avx2

# =========================
# CUDA BUILD
# =========================
cuda:
	$(NVCC) $(CUDAFLAGS) $(CUDA_SRC) -o $(CUDA_TARGET)

cuda2:
	$(NVCC) $(CUDAFLAGS) $(CUDA2_SRC) -o $(CUDA_TARGET)_2

cuda3:
	$(NVCC) $(CUDAFLAGS) $(CUDA3_SRC) -o $(CUDA_TARGET)_3

# =========================
# CLEAN
# =========================
clean:
	rm -f $(OBJ) $(TARGET) $(TARGET)_novec $(TARGET)_avx2 $(CUDA_TARGET)