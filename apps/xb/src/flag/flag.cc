#include "flag.h"

#include <thread>

DEFINE_string(dataset, "Amazon", "Dataset Name (ex: Amazon)");
DEFINE_string(row_offsets, "", "Path to CSR row offsets file");
DEFINE_string(col_indices, "", "Path to CSR column indices file");
DEFINE_uint32(rounds, 1, "# of Repeatition to run an algorithm");
DEFINE_uint32(num_threads, std::thread::hardware_concurrency(),
              "# of CPU worker threads used by XB-Pro runners");
DEFINE_uint64(path_buffer_ratio, 1,
              "Path buffer ratio used by GPU X-Blossom runners");
DEFINE_uint64(max_cuda_sms, 0,
              "Maximum launched CUDA blocks for GPU X-Blossom kernels, used "
              "as an SM-budget proxy; 0 keeps the default launch sizing");
