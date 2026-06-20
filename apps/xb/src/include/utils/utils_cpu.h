#pragma once

#include <chrono>
#include <cerrno>
#include <iostream>
#include <numeric>
#include <string>
#include <vector>
#include <glog/logging.h>
#include <sys/stat.h>
#include <sys/types.h>

#include "utils/types_cpu.h"

#define DEV_HOST
#define DEV_HOST_INLINE
#define DEV_INLINE
#define CONST_STATIC_INIT(...) = __VA_ARGS__

#define CEIL_DIV(x, y) (((x) + (y) - 1) / (y))

#define MIN(a, b) (((a) < (b)) ? (a) : (b))
#define MAX(a, b) (((a) > (b)) ? (a) : (b))

static DEV_HOST_INLINE size_t round_up(size_t numerator,
                                       size_t denominator) {
  return (numerator + denominator - 1) / denominator;
}

static uint64_t getNanoSecond() {
  return std::chrono::high_resolution_clock::now().time_since_epoch().count();
}

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

#define INIT_GLOG_ARGS()                    \
  XBEnsureGlogDir("tmp/logs");              \
  FLAGS_log_dir = "tmp/logs";               \
  google::InitGoogleLogging(argv[0]);        \
  google::InstallFailureSignalHandler();

#define INIT_GLOG_STR(name)                                           \
  XBEnsureGlogDir("tmp/logs");                                        \
  FLAGS_log_dir = "tmp/logs";                                         \
  google::InitGoogleLogging(name);                                     \
  google::InstallFailureSignalHandler();

static inline std::string GetLogDir() {
  return FLAGS_log_dir + "/";
}

#define SHUTDOWN_GLOG() \
  google::ShutdownGoogleLogging();

#define SLEEP_MILLISECONDS(us) std::this_thread::sleep_for(std::chrono::milliseconds(us))

#define IDX_MUL(a, b) (static_cast<size_t>(a) * static_cast<size_t>(b))
#define SIZE_MUL(a, b) (static_cast<size_t>(a) * static_cast<size_t>(b))
#define IDX_ADD(a, b) (static_cast<size_t>(a) + static_cast<size_t>(b))
#define IDX_MUL_ADD(a, b, c)  (static_cast<size_t>(a) * static_cast<size_t>(b) + static_cast<size_t>(c))

static inline void ComputeTaskletRange(size_t num_tasks,
                                       size_t num_threads,
                                       index_t thread_id,
                                       index_t& start,
                                       index_t& end) {
  const size_t num_tasks_per_thread = (num_tasks + num_threads - 1) / num_threads;
  start = thread_id * num_tasks_per_thread;
  end = std::min(start + num_tasks_per_thread, num_tasks);
}

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
  LOG(WARNING) << "GPU info requested in a CPU-only XB build for GPU-"
               << gpu_id;
}

template <typename InputIterator, typename OutputIterator>
OutputIterator simple_exclusive_scan(InputIterator first, InputIterator last, OutputIterator result)
{
  return std::exclusive_scan(first, last + 1, result, 0);
}
