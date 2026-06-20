#pragma once

#include <algorithm>
#include <chrono>
#include <cerrno>
#include <iostream>
#include <limits>
#include <numeric>
#include <string>
#include <vector>
#include <glog/logging.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <thrust/execution_policy.h>
#include <thrust/scan.h>
#include <thrust/system/cuda/memory_resource.h>

#include "flag.h"
#include "utils/types_gpu.h"

#if defined(__CUDACC__) || defined(__CUDABE__)
#define DEV_HOST __device__ __host__
#define DEV_HOST_INLINE __device__ __host__ __forceinline__
#define DEV_INLINE __device__ __forceinline__
#define CONST_STATIC_INIT(...)
#else
#define DEV_HOST
#define DEV_HOST_INLINE
#define DEV_INLINE
#define CONST_STATIC_INIT(...) = __VA_ARGS__
#endif

#define CEIL_DIV(x, y) (((x) + (y) - 1) / (y))

#define MIN(a, b) (((a) < (b)) ? (a) : (b))
#define MAX(a, b) (((a) > (b)) ? (a) : (b))

#define MAX_GRID_SIZE (1024)
// #define MAX_GRID_SIZE (128)
#define MAX_BLOCK_SIZE (256)

// #define MAX_GRID_SIZE (16)
// #define MAX_BLOCK_SIZE (1024)

// #define MAX_GRID_SIZE (1)
// #define MAX_BLOCK_SIZE (8)

#define TID_1D (threadIdx.x + blockIdx.x * blockDim.x)
#define TOTAL_THREADS_1D (gridDim.x * blockDim.x)

#define PARTITION_SIZE(n, num_gpus, gpu_id) ((n) / (num_gpus) + ((gpu_id) < ((n) % (num_gpus)) ? 1 : 0))
#define PARTITION_START(n, num_gpus, gpu_id) (((n) / (num_gpus)) * (gpu_id) + min((gpu_id), (n) % (num_gpus)))

#define CUDA_CHECK(func)                                                       \
  do {                                                                         \
    cudaError_t rt = (func);                                                   \
    if (rt != cudaSuccess) {                                                   \
      std::cout << "API call failure \"" #func "\" with " << rt << " at "      \
                << __FILE__ << ":" << __LINE__                                 \
                << " with err msg: " << cudaGetErrorString(rt) << std::endl;   \
      throw;                                                                   \
    }                                                                          \
  } while (0);

static DEV_HOST_INLINE size_t round_up(size_t numerator,
                                       size_t denominator) {
  return (numerator + denominator - 1) / denominator;
}

static uint64_t getNanoSecond() {
  return std::chrono::high_resolution_clock::now().time_since_epoch().count();
}

// Raw pointer extraction macro
#define CastRawPtr(v) thrust::raw_pointer_cast((v).data())

static inline void XBEnsureGlogDir(const std::string& path) {
  std::string current;
  for (char ch : path) {
    current.push_back(ch);
    if (ch == '/' && current.size() > 1) {
      if (::mkdir(current.c_str(), 0755) != 0 && errno != EEXIST) {
        return;
      }
    }
  }
  if (!current.empty()) {
    ::mkdir(current.c_str(), 0755);
  }
}

// GLog Setup and Teardown
#define INIT_GLOG_ARGS()                    \
  XBEnsureGlogDir("tmp/logs");              \
  FLAGS_log_dir = "tmp/logs";               \
  google::InitGoogleLogging(argv[0]);        \
  google::InstallFailureSignalHandler();

// Set up GLog with custom log directory and benchmark name (no argv required)
#define INIT_GLOG_STR(name)                                           \
  XBEnsureGlogDir("tmp/logs");                                        \
  FLAGS_log_dir = "tmp/logs";                                         \
  google::InitGoogleLogging(name);                                     \
  google::InstallFailureSignalHandler();

// Add a "/" to separate the future filename
static inline std::string GetLogDir() {
  return FLAGS_log_dir + "/";
}

#define SHUTDOWN_GLOG() \
  google::ShutdownGoogleLogging();

inline void ApplyCudaLaunchCaps(int& block_num, int& block_size) {
  if (FLAGS_max_cuda_sms > 0) {
    const int capped_sms = static_cast<int>(
        std::min<uint64_t>(FLAGS_max_cuda_sms,
                           static_cast<uint64_t>(std::numeric_limits<int>::max())));
    block_num = std::max(1, std::min(block_num, capped_sms));
  }
}

inline void KernelSizing(int &block_num, int &block_size, size_t work_size) {
  block_size = MAX_BLOCK_SIZE;
  block_num = std::min(MAX_GRID_SIZE, (int) round_up(work_size, block_size));
  ApplyCudaLaunchCaps(block_num, block_size);
}


#define SYNC_ALL_STREAMS(streams) \
for (auto &stream : (streams)) { \
stream.Sync(); \
}

#define FOR_EACH_GPU(num_gpus, gpu_id) \
for (int gpu_id = 0; gpu_id < (num_gpus); ++gpu_id) if ((cudaSetDevice(gpu_id), true))

// template<typename T>
// void SafeCudaMemcpyAsync(DVector<T> &dst, const T *src, size_t count, cudaMemcpyKind kind, cudaStream_t stream,
//                                 const char *error_context) {
//   cudaError_t status = cudaMemcpyAsync(CastRawPtr(dst), src, count * sizeof(T), kind, stream);
//   CHECK_EQ(status, cudaSuccess) << "cudaMemcpyAsync (" << error_context << ") error: "
//                                 << cudaGetErrorString(status);
// }

#define SLEEP_MILLISECONDS(us) std::this_thread::sleep_for(std::chrono::milliseconds(us))

// Overflow Problem of index
#define IDX_MUL(a, b) (static_cast<size_t>(a) * static_cast<size_t>(b))
#define SIZE_MUL(a, b) (static_cast<size_t>(a) * static_cast<size_t>(b))
#define IDX_ADD(a, b) (static_cast<size_t>(a) + static_cast<size_t>(b))
#define IDX_MUL_ADD(a, b, c)  (static_cast<size_t>(a) * static_cast<size_t>(b) + static_cast<size_t>(c))

// Compute Thread Task Range
// using index_t = uint64_t;
// using index_t = unsigned long long;
// using index_t = int64_t;
static inline void ComputeTaskletRange(size_t num_tasks,
                                       size_t num_threads,
                                       index_t thread_id,
                                       index_t& start,
                                       index_t& end) {
  const size_t num_tasks_per_thread = (num_tasks + num_threads - 1) / num_threads;
  start = thread_id * num_tasks_per_thread;
  end = std::min(start + num_tasks_per_thread, num_tasks);
}

// Profiling Statement: only enabled in profiling mode
#ifdef MM_PROFILE
  #define PROFILE_STATEMENT(stmt) stmt
#else
  #define PROFILE_STATEMENT(stmt)
#endif

#define SET_MIN_MAX(v, w) \
  do {                    \
    if ((v) > (w)) {      \
      index_t temp = (v); \
      (v) = (w);          \
      (w) = temp;         \
    }                     \
  } while (0)


static void LogGPUInfo(int gpu_id = 0) {
  cudaDeviceProp prop;
  cudaError_t err = cudaGetDeviceProperties(&prop, gpu_id);

  if (err != cudaSuccess) {
    LOG(ERROR) << "Failed to get device properties for GPU-" << gpu_id << ": "
               << cudaGetErrorString(err);
    return;
  }

  int num_sm = prop.multiProcessorCount;
  int max_threads_per_sm = prop.maxThreadsPerMultiProcessor;
  int total_cuda_threads = num_sm * max_threads_per_sm;
  size_t total_global_mem = prop.totalGlobalMem;

  int l2_cache_bytes = 0;
  cudaError_t err_l2 =
      cudaDeviceGetAttribute(&l2_cache_bytes, cudaDevAttrL2CacheSize, gpu_id);

  if (err_l2 != cudaSuccess) {
    LOG(WARNING) << "Could not read L2 cache size: "
                 << cudaGetErrorString(err_l2);
  }

  int shared_mem_per_sm = 0;
  cudaError_t err_sm =
      cudaDeviceGetAttribute(&shared_mem_per_sm,
                             cudaDevAttrMaxSharedMemoryPerMultiprocessor,
                             gpu_id);

  size_t total_shared_mem = 0;
  if (err_sm != cudaSuccess) {
    LOG(WARNING) << "Could not read shared memory per SM: "
                 << cudaGetErrorString(err_sm);
  } else {
    total_shared_mem =
        static_cast<size_t>(shared_mem_per_sm) * static_cast<size_t>(num_sm);
  }

  LOG(INFO) << "GPU-" << gpu_id << " Info:";
  LOG(INFO) << "Number of SMs: " << num_sm;
  LOG(INFO) << "Max Threads per SM: " << max_threads_per_sm;
  LOG(INFO) << "Total CUDA Threads: " << total_cuda_threads;

  LOG(INFO) << "Total Global Memory: "
            << (total_global_mem / (1024.0 * 1024.0)) << " MB";

  LOG(INFO) << "L2 Cache Size: "
            << (l2_cache_bytes / (1024.0 * 1024.0)) << " MB ("
            << l2_cache_bytes << " bytes)";

  LOG(INFO) << "Shared Memory per SM: "
            << (shared_mem_per_sm / 1024.0) << " KB";

  LOG(INFO) << "Total Shared Memory Across All SMs: "
            << (total_shared_mem / (1024.0 * 1024.0)) << " MB ("
            << total_shared_mem << " bytes)";
}

template <typename InputIterator, typename OutputIterator>
OutputIterator simple_exclusive_scan(InputIterator first, InputIterator last, OutputIterator result)
{
  return thrust::exclusive_scan(first, last + 1, result);
}
