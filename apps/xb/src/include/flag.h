#pragma once

#include <gflags/gflags.h>

DECLARE_string(dataset);
DECLARE_string(row_offsets);
DECLARE_string(col_indices);
DECLARE_uint32(rounds);
DECLARE_uint32(num_threads);
DECLARE_uint64(path_buffer_ratio);
DECLARE_uint64(max_cuda_sms);
