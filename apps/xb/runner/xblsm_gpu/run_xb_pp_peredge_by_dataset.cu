#include "common/gflags_guard.h"
#include "common/glog_guard.h"
#include "common/timing_guard.h"
#include "flag.h"
#include "xbsm_gpu/xblossom_gpu_engine_10.h"

int main(int argc, char *argv[]) {
  // RAII GlogGuard for init and shutdown of glog.
  auto glog_guard =
      zblossom::CreateGlogGuard("run_zblsm_gpu_engine_10_by_dataset");
  auto gflags_guard = zblossom::CreateGflagsGuard(argc, argv, true);
  std::cout << "Run XBlossomGPU on Dataset " << FLAGS_dataset << std::endl;
  std::cout << "Run XBlossomGPU for " << FLAGS_rounds << " times" << std::endl;

  // Log GPU-0 Info
  LogGPUInfo(0);

  using xb_engine_t = zblossom::XBlossomGpuEngine10;

  // 1. Load the graph
  host_graph_t graph(FLAGS_row_offsets, FLAGS_col_indices);

  // 2. Run Blossom Algorithms for # of rounds times
  std::vector<std::chrono::nanoseconds> timing_vector; // timing

  {
    Matching initial_matching(graph.nnodes, graph.nnodes);
    xb_engine_t xb_engine(graph, FLAGS_path_buffer_ratio);
    Matching actual_matching = xb_engine.FindMaximumMatch(initial_matching);
  }

  for (uint32_t i = 0; i < FLAGS_rounds; i++) {
    Matching initial_matching(graph.nnodes, graph.nnodes);
    xb_engine_t xb_engine(graph, FLAGS_path_buffer_ratio);

    {
      zblossom::TimingVectorGuard timing_guard(timing_vector); // timing
      Matching actual_matching = xb_engine.FindMaximumMatch(initial_matching);
      // xb_engine.PrintTimingSummary();
    }

    const auto round_runtime =
        std::chrono::duration<double>(timing_vector.back()).count();
    std::cout << "Round runtime: " << round_runtime << std::endl;
  }

  // Average Runtime in Second
  std::cout << "Average runtime: " << zblossom::AvgRuntime(timing_vector)
            << std::endl;
  return 0;
}
