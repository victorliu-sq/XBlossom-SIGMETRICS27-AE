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
  size_t max_degree = 0;
  const auto &row_offsets = graph.GetRowOffsetsVector();
  for (size_t i = 0; i < graph.nnodes; ++i) {
    const auto degree = row_offsets[i + 1] - row_offsets[i];
    if (degree > max_degree) {
      max_degree = degree;
    }
  }

  std::vector<std::chrono::nanoseconds> timing_vector; // timing
  size_t num_blossoms = 0;
  size_t num_edges_processed = 0;
  size_t num_aug_path_edges_processed = 0;
  size_t num_expand_edges_processed = 0;
  size_t num_blossom_edges_processed = 0;
  size_t num_reused_tree_nodes = 0;
  size_t num_reset_tree_nodes = 0;
  std::vector<double> reuse_ratio_vector;

  {
    Matching initial_matching(graph.nnodes, graph.nnodes);
    xb_engine_t xb_engine(graph, FLAGS_path_buffer_ratio);
    Matching actual_matching = xb_engine.FindMaximumMatch(initial_matching);
  }

  // 2. Run Blossom Algorithms for # of rounds times
  for (uint32_t i = 0; i < FLAGS_rounds; i++) {
    Matching initial_matching(graph.nnodes, graph.nnodes);
    xb_engine_t xb_engine(graph, FLAGS_path_buffer_ratio);

    {
      zblossom::TimingVectorGuard timing_guard(timing_vector); // timing

      Matching actual_matching = xb_engine.FindMaximumMatch(initial_matching);
      xb_engine.PrintTimingSummary();
    }
    const auto round_num_blossoms = xb_engine.NumBlossoms();
    num_edges_processed += xb_engine.NumEdgesProcessed();
    num_aug_path_edges_processed += xb_engine.NumAugmentingPathEdgesProcessed();
    num_expand_edges_processed += xb_engine.NumExpandEdgesProcessed();
    num_blossom_edges_processed += xb_engine.NumBlossomEdgesProcessed();
    num_blossoms += round_num_blossoms;
    const auto round_reused_tree_nodes = xb_engine.NumReusedTreeNodes();
    const auto round_reset_tree_nodes = xb_engine.NumResetTreeNodes();
    const auto round_reuse_ratio_denominator =
        round_reused_tree_nodes + round_reset_tree_nodes;
    const auto round_reuse_ratio =
        round_reuse_ratio_denominator == 0
            ? 0.0
            : static_cast<double>(round_reused_tree_nodes) /
                  static_cast<double>(round_reuse_ratio_denominator);
    reuse_ratio_vector.push_back(round_reuse_ratio);
    num_reused_tree_nodes += round_reused_tree_nodes;
    num_reset_tree_nodes += round_reset_tree_nodes;
    std::cout << "Round Number of Blossoms: " << round_num_blossoms
              << std::endl;
    std::cout << "Round Reused Tree Nodes: " << round_reused_tree_nodes
              << std::endl;
    std::cout << "Round Reset Tree Nodes: " << round_reset_tree_nodes
              << std::endl;
    std::cout << "Round ReuseRatio: " << round_reuse_ratio << std::endl;
  }

  // Average Runtime in Second
  for (uint32_t i = 0; i < timing_vector.size(); i++) {
    const auto round_runtime =
        std::chrono::duration<double>(timing_vector[i]).count();
    std::cout << "Round runtime: " << round_runtime << std::endl;
  }
  const auto avg_runtime = zblossom::AvgRuntime(timing_vector);
  const auto avg_num_blossoms =
      static_cast<double>(num_blossoms) / FLAGS_rounds;
  const auto avg_num_edges_processed =
      static_cast<double>(num_edges_processed) / FLAGS_rounds;
  const auto avg_num_aug_path_edges_processed =
      static_cast<double>(num_aug_path_edges_processed) / FLAGS_rounds;
  const auto avg_num_expand_edges_processed =
      static_cast<double>(num_expand_edges_processed) / FLAGS_rounds;
  const auto avg_num_blossom_edges_processed =
      static_cast<double>(num_blossom_edges_processed) / FLAGS_rounds;
  const auto avg_num_reused_tree_nodes =
      static_cast<double>(num_reused_tree_nodes) / FLAGS_rounds;
  const auto avg_num_reset_tree_nodes =
      static_cast<double>(num_reset_tree_nodes) / FLAGS_rounds;
  double reuse_ratio = 0.0;
  for (const auto round_reuse_ratio : reuse_ratio_vector) {
    reuse_ratio += round_reuse_ratio;
  }
  if (!reuse_ratio_vector.empty()) {
    reuse_ratio /= static_cast<double>(reuse_ratio_vector.size());
  }
  std::cout << "Average runtime: " << avg_runtime << std::endl;
  std::cout << "Num of Nodes: " << graph.nnodes << std::endl;
  std::cout << "Num of Edges: " << graph.nedges << std::endl;
  std::cout << "Number of Blossoms: " << avg_num_blossoms << std::endl;
  std::cout << "Number of Processed Edges: " << avg_num_edges_processed
            << std::endl;
  std::cout << "AugmentingPath Processed Edges: "
            << avg_num_aug_path_edges_processed << std::endl;
  std::cout << "Expand Processed Edges: " << avg_num_expand_edges_processed
            << std::endl;
  std::cout << "Blossom Processed Edges: " << avg_num_blossom_edges_processed
            << std::endl;
  std::cout << "Number of Reused Tree Nodes: " << avg_num_reused_tree_nodes
            << std::endl;
  std::cout << "ReusedTreeNodes/s: "
            << avg_num_reused_tree_nodes / avg_runtime << std::endl;
  std::cout << "Number of Reset Tree Nodes: " << avg_num_reset_tree_nodes
            << std::endl;
  std::cout << "ResetTreeNodes/s: "
            << avg_num_reset_tree_nodes / avg_runtime << std::endl;
  std::cout << "ReuseRatio: " << reuse_ratio << std::endl;
  std::cout << "Max Degree: " << max_degree << std::endl;
  std::cout << "Avg Degree: "
            << static_cast<double>(graph.nedges) / graph.nnodes << std::endl;
  std::cout << "blossoms(Milli) per Second: "
            << static_cast<double>(num_blossoms) / 1e6 / avg_runtime
            << std::endl;
  std::cout << "blossoms(Milli) per Second per Node: "
            << static_cast<double>(num_blossoms) / 1e6 / avg_runtime /
                   graph.nnodes
            << std::endl;
  std::cout << "Avg blossoms per Node: "
            << avg_num_blossoms / graph.nnodes << std::endl;
  std::cout << "Avg blossoms per Edge: "
            << avg_num_blossoms / graph.nedges << std::endl;
  std::cout << "Avg blossoms per Node per Edge: "
            << avg_num_blossoms / graph.nnodes / graph.nedges << std::endl;
  std::cout << "Avg blossoms per (Max) Edge: "
            << avg_num_blossoms / max_degree << std::endl;
  std::cout << "Processed Edges per Second: "
            << avg_num_edges_processed / avg_runtime << std::endl;
  return 0;
}
