#include "common/gflags_guard.h"
#include "common/glog_guard.h"
#include "common/timing_guard.h"
#include "flag.h"
#include "utils/mm_types_cpu.h"
#include "xblsm_cpu/xblsm_cpu.h"
#include "xblsm_cpu/xblsm_cpu_config.h"

int main(int argc, char *argv[]) {
  auto glog_guard = zblossom::CreateGlogGuard("run_xb_pro_by_dataset");
  auto gflags_guard = zblossom::CreateGflagsGuard(argc, argv, true);
  std::cout << "Run XBlossomPro on Dataset " << FLAGS_dataset << std::endl;
  std::cout << "Run XBlossomPro for " << FLAGS_rounds << " times" << std::endl;

  // 1. Load the graph
  const auto &path_row_offsets = FLAGS_row_offsets;
  const auto &path_column_indices = FLAGS_col_indices;

  xgraph_t graph(path_row_offsets, path_column_indices);

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

    zblossom::TimingVectorGuard timing_guard(timing_vector);

    Matching matching(nnodes, -1);
    int threshold = INT_MAX;
    xblossom::testParBlossom_200(graph, matching, threshold);
  }

  // Average Runtime in Second
  for (uint32_t i = 0; i < timing_vector.size(); i++) {
    const auto round_runtime =
        std::chrono::duration<double>(timing_vector[i]).count();
    std::cout << "Round runtime: " << round_runtime << std::endl;
  }
  std::cout << "Average runtime: " << zblossom::AvgRuntime(timing_vector)
            << std::endl;

  return 0;
}
