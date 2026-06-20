#include "common/gflags_guard.h"
#include "common/glog_guard.h"
#include "common/timing_guard.h"
#include "flag.h"
#include "utils/mm_types_cpu.h"
#include "xblsm_cpu/xblsm_cpu_config.h" // introduce definitions of all config variables
#include "xblsm_cpu/xblsm_cpu_pro.h"

int main(int argc, char *argv[]) {
  auto glog_guard = zblossom::CreateGlogGuard("run_xb_pro_by_dataset");
  auto gflags_guard = zblossom::CreateGflagsGuard(argc, argv, true);
  std::cout << "Run XBlossomPro on Dataset " << FLAGS_dataset << std::endl;
  std::cout << "Run XBlossomPro for " << FLAGS_rounds << " times" << std::endl;

  // 1. Load the graph
  const auto &path_row_offsets = FLAGS_row_offsets;
  const auto &path_column_indices = FLAGS_col_indices;

  std::chrono::high_resolution_clock::time_point load_start_;
  std::chrono::high_resolution_clock::time_point load_end_;
  load_start_ = std::chrono::high_resolution_clock::now();

  xgraph_t graph(path_row_offsets, path_column_indices);

  load_end_ = std::chrono::high_resolution_clock::now();
  const auto load_duration =
      std::chrono::duration_cast<std::chrono::milliseconds>(load_end_ -
                                                            load_start_);
  std::cout << "Loading Graph " << FLAGS_dataset << " takes "
            << load_duration.count() << " milliseconds" << std::endl;

  // 2. Setup Execution Context
  size_t nnodes = graph.num_of_nodes;
  xblossom::nodes = graph.num_of_nodes;
  xblossom::num_of_threads = FLAGS_num_threads;
  std::cout << "XB-Pro threads: " << xblossom::num_of_threads << std::endl;
  xblossom::count = 0;

  // 3. Run XBlossomPro for "rounds" times
  std::vector<std::chrono::nanoseconds> timing_vector;

  for (uint32_t i = 0; i < FLAGS_rounds; i++) {
    std::cout << "Run: # " << i + 1 << " / " << FLAGS_rounds << std::endl;

    // zblossom::TimingGuard timing_guard(timing_vector);
    zblossom::TimingVectorGuard timing_guard(timing_vector);

    Matching matching(nnodes, -1);
    int threshold = INT_MAX;
    xblossom::testParBlossom_pro_pernode_nab(graph, matching, threshold);
  }

  // Average Runtime in Second
  std::cout << "Average runtime: " << zblossom::AvgRuntime(timing_vector)
            << std::endl;

  return 0;
}
