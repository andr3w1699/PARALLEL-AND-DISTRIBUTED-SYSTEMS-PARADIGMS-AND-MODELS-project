
CXX = g++

NVCC = nvcc

CXXFLAGS = -std=c++20 -Wall -Wextra
OPTFLAGS = -O3 -march=native
SUPEROPTFLAGS = -O3 -march=native -funroll-loops -fprefetch-loop-arrays -flto -ffast-math -falign-functions=32 -falign-loops=32 -falign-jumps=32 -fstrict-aliasing -fwhole-program -fno-exceptions -fno-rtti
VECFLAGS = -fopt-info-vec-all
CUDAFLAGS = -O3

TARGETS_CPU = partition partition_optimized partition_novec partition_novec_optimized partition_avx2 partition_avx2_optimized
TARGETS_CUDA = partition_cuda partition_cuda_2 partition_cuda_3

SRC = src/main.cpp src/partition.cpp
SRC2 = src_2/main.cpp src_2/partition.cpp
CUDA_SRC = src/main_cuda.cu src/partition_cuda.cu
CUDA2_SRC = cuda_2/main_cuda.cu cuda_2/partition_cuda.cu
CUDA3_SRC = cuda_3/main_cuda.cu cuda_3/partition_cuda.cu

all: cpu cuda

cpu: $(TARGETS_CPU)

partition:
	$(CXX) $(CXXFLAGS) $(SUPEROPTFLAGS) $(VECFLAGS) $(SRC) -o $@

partition_optimized:
	$(CXX) $(CXXFLAGS) $(SUPEROPTFLAGS) $(SRC2) -o $@

partition_novec:
	$(CXX) $(CXXFLAGS) -O3 -fno-tree-vectorize $(SRC) -o $@

partition_novec_optimized:
	$(CXX) $(CXXFLAGS) -O3 -fno-tree-vectorize $(SRC2) -o $@

partition_avx2:
	$(CXX) $(CXXFLAGS)  $(SUPEROPTFLAGS) -mavx2 -DUSE_AVX2 $(SRC) -o $@

partition_avx2_optimized:
	$(CXX) $(CXXFLAGS)  $(SUPEROPTFLAGS) -mavx2 -DUSE_AVX2 $(SRC2) -o $@


cuda: $(TARGETS_CUDA)

partition_cuda:
	$(NVCC) $(CUDAFLAGS) $(CUDA_SRC) -o $@

partition_cuda_2:
	$(NVCC) $(CUDAFLAGS) $(CUDA2_SRC) -o $@

partition_cuda_3:
	$(NVCC) $(CUDAFLAGS) $(CUDA3_SRC) -o $@

clean:
	rm -f $(TARGETS_CPU) $(TARGETS_CUDA)