#ifndef MACROS_H
#define MACROS_H

#include "utils/utils_gpu.h"

inline static void PrintGPUInfo(int device = 0) {
  cudaDeviceProp prop;
  cudaGetDeviceProperties(&prop, device);

  int l2CacheSize = 0;
  cudaDeviceGetAttribute(&l2CacheSize, cudaDevAttrL2CacheSize, device);


  std::cout << "\033[1;31m" // red color
      << "[GPU Info] Device " << device << ": " << prop.name
      << "\n  Global Memory: " << (prop.totalGlobalMem / (1024.0 * 1024 * 1024)) << " GB"
      << "\n  L2 Cache Size: " << (l2CacheSize / (1024.0 * 1024)) << " MB"
      << "\n  SMs: " << prop.multiProcessorCount
      << "\n  Max Threads/Block: " << prop.maxThreadsPerBlock
      << "\033[0m" << std::endl;
}

// Helper macro: Benchmark main with GLOG init/shutdown
#define BENCHMARK_MAIN_WITH_GLOG(name)                                   \
  int main(int argc, char** argv) {                                      \
    INIT_GLOG_STR(name);                                                 \
                                                                          \
    benchmark::MaybeReenterWithoutASLR(argc, argv);                      \
    char arg0_default[] = "benchmark";                                   \
    char* args_default = reinterpret_cast<char*>(arg0_default);          \
    if (!argv) {                                                         \
      argc = 1;                                                          \
      argv = &args_default;                                              \
    }                                                                    \
    ::benchmark::Initialize(&argc, argv);                                \
    if (::benchmark::ReportUnrecognizedArguments(argc, argv)) return 1;  \
    ::benchmark::RunSpecifiedBenchmarks();                               \
    ::benchmark::Shutdown();                                             \
                                                                          \
    SHUTDOWN_GLOG();                                                     \
    return 0;                                                            \
  }                                                                      \
  int main(int, char**)

// Helper macro: Benchmark main with GLOG init/shutdown
#define BENCHMARK_MAIN_WITH_GLOG_GPU_INFO(name)                                   \
  int main(int argc, char** argv) {                                      \
    INIT_GLOG_STR(name);                                                 \
                                                                          \
    PrintGPUInfo();                                                       \
                                                                         \
    benchmark::MaybeReenterWithoutASLR(argc, argv);                      \
    char arg0_default[] = "benchmark";                                   \
    char* args_default = reinterpret_cast<char*>(arg0_default);          \
    if (!argv) {                                                         \
      argc = 1;                                                          \
      argv = &args_default;                                              \
    }                                                                    \
    ::benchmark::Initialize(&argc, argv);                                \
    if (::benchmark::ReportUnrecognizedArguments(argc, argv)) return 1;  \
    ::benchmark::RunSpecifiedBenchmarks();                               \
    ::benchmark::Shutdown();                                             \
                                                                          \
    SHUTDOWN_GLOG();                                                     \
    return 0;                                                            \
  }                                                                      \
  int main(int, char**)
#endif //MACROS_H
