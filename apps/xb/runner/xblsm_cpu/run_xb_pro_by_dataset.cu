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
  size_t max_degree = 0;
  xblossom::nodes = graph.num_of_nodes;
  for (int i = 0; i < nnodes; ++i) {
    int cur_nnodes = graph.rowOffsets[i + 1] - graph.rowOffsets[i];
    if (cur_nnodes > max_degree) {
      max_degree = cur_nnodes;
    }
  }

  xblossom::num_of_threads = FLAGS_num_threads;
  std::cout << "XB-Pro threads: " << xblossom::num_of_threads << std::endl;
  xblossom::count = 0;

  // 3. Run XBlossomPro for "rounds" times
  std::vector<std::chrono::nanoseconds> timing_vector;
  std::vector<double> reuse_ratio_vector;
  uint64_t total_num_blossoms = 0;
  uint64_t total_reused_tree_nodes = 0;
  uint64_t total_reset_tree_nodes = 0;

  for (uint32_t i = 0; i < FLAGS_rounds; i++) {
    std::cout << "Run: # " << i + 1 << " / " << FLAGS_rounds << std::endl;

    xblossom::num_blossom = 0;
    xblossom::num_reused_tree_nodes = 0;
    xblossom::num_reset_tree_nodes = 0;

    {
      // zblossom::TimingGuard timing_guard(timing_vector);
      zblossom::TimingVectorGuard timing_guard(timing_vector);

      Matching matching(nnodes, -1);
      int threshold = INT_MAX;
      xblossom::testParBlossom_pro_pernode(graph, matching, threshold);
    }

    const auto round_num_blossoms = xblossom::num_blossom;
    const auto round_reused_tree_nodes = xblossom::num_reused_tree_nodes;
    const auto round_reset_tree_nodes = xblossom::num_reset_tree_nodes;
    const auto round_reuse_ratio_denominator =
        round_reused_tree_nodes + round_reset_tree_nodes;
    const auto round_reuse_ratio =
        round_reuse_ratio_denominator == 0
            ? 0.0
            : static_cast<double>(round_reused_tree_nodes) /
                  static_cast<double>(round_reuse_ratio_denominator);
    reuse_ratio_vector.push_back(round_reuse_ratio);
    total_num_blossoms += round_num_blossoms;
    total_reused_tree_nodes += round_reused_tree_nodes;
    total_reset_tree_nodes += round_reset_tree_nodes;
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
  std::cout << "Average runtime: " << avg_runtime << std::endl;

  // Average Runtime in Milliseconds
  // std::cout << "Average runtime: " <<
  // zblossom::GetAvgRuntime<std::milli>(timing_vector) << std::endl;

  // NEW: print dataset info
  std::cout << "Num of Nodes: " << graph.num_of_nodes << std::endl;
  std::cout << "Num of Edges: " << graph.num_of_edges << std::endl;
  std::cout << "Number of Blossoms: " << total_num_blossoms / FLAGS_rounds
            << std::endl;
  std::cout << "Number of Processed Edges: "
            << xblossom::num_edges_processed / FLAGS_rounds << std::endl;
  std::cout << "AugmentingPath Processed Edges: "
            << xblossom::num_aug_path_edges_processed / FLAGS_rounds
            << std::endl;
  std::cout << "Expand Processed Edges: "
            << xblossom::num_expand_edges_processed / FLAGS_rounds
            << std::endl;
  std::cout << "Blossom Processed Edges: "
            << xblossom::num_blossom_edges_processed / FLAGS_rounds
            << std::endl;
  std::cout << "Number of Search Phase Iterations: "
            << xblossom::num_search_phase_iterations / FLAGS_rounds
            << std::endl;
  std::cout << "Number of Augmenting Path Discovery Iterations: "
            << xblossom::num_aug_path_discovery_iterations / FLAGS_rounds
            << std::endl;
  const auto aug_path_discovery_frequency =
      xblossom::num_search_phase_iterations == 0
          ? 0.0
          : static_cast<double>(xblossom::num_aug_path_discovery_iterations) /
                static_cast<double>(xblossom::num_search_phase_iterations);
  std::cout << "Augmenting Path Discovery Frequency: "
            << aug_path_discovery_frequency << std::endl;
  const auto avg_reused_tree_nodes =
      static_cast<double>(total_reused_tree_nodes) / FLAGS_rounds;
  const auto avg_reset_tree_nodes =
      static_cast<double>(total_reset_tree_nodes) / FLAGS_rounds;
  double reuse_ratio = 0.0;
  for (const auto round_reuse_ratio : reuse_ratio_vector) {
    reuse_ratio += round_reuse_ratio;
  }
  if (!reuse_ratio_vector.empty()) {
    reuse_ratio /= static_cast<double>(reuse_ratio_vector.size());
  }
  std::cout << "Number of Reused Tree Nodes: "
            << total_reused_tree_nodes / FLAGS_rounds << std::endl;
  std::cout << "ReusedTreeNodes/s: " << avg_reused_tree_nodes / avg_runtime
            << std::endl;
  std::cout << "Number of Reset Tree Nodes: "
            << total_reset_tree_nodes / FLAGS_rounds << std::endl;
  std::cout << "ResetTreeNodes/s: " << avg_reset_tree_nodes / avg_runtime
            << std::endl;
  std::cout << "ReuseRatio: " << reuse_ratio << std::endl;

  auto dtime = static_cast<double>(avg_runtime);
  auto dnum_nodes = static_cast<double>(graph.num_of_nodes);
  auto dnum_edges = static_cast<double>(graph.num_of_edges);
  auto dnum_bloss = static_cast<double>(total_num_blossoms);
  auto dnum_max_edges = static_cast<double>(xblossom::max_num_edges_processed);
  auto drounds = static_cast<double>(FLAGS_rounds);
  auto dsearch_phase_iterations =
      static_cast<double>(xblossom::num_search_phase_iterations);
  auto dnum_edges_processed =
      static_cast<double>(xblossom::num_edges_processed);
  auto davg_edges_processed = dnum_edges_processed / drounds;

  auto davg_edges_processed_per_it =
      davg_edges_processed / dsearch_phase_iterations;
  auto davg_bloss_per_it = dnum_bloss / drounds / dsearch_phase_iterations;

  std::cout << "Max Degree: " << max_degree << std::endl;
  std::cout << "Avg Degree: " << dnum_edges / dnum_nodes << std::endl;
  std::cout << "blossoms(Milli) per Second: " << dnum_bloss / 1e6 / dtime
            << std::endl;
  std::cout << "blossoms(Milli) per Second per Node: "
            << dnum_bloss / 1e6 / dtime / dnum_nodes << std::endl;
  std::cout << "Avg blossoms per Node: " << dnum_bloss / drounds / dnum_nodes
            << std::endl;
  std::cout << "Avg blossoms per Edge: " << dnum_bloss / drounds / dnum_edges
            << std::endl;
  std::cout << "Avg blossoms per Node per Edge: "
            << dnum_bloss / drounds / dnum_nodes / dnum_edges << std::endl;
  std::cout << "Avg blossoms per (Max) Edge: "
            << dnum_bloss / drounds / dnum_max_edges << std::endl;

  std::cout << "Max Edges per Iteration: " << dnum_max_edges << std::endl;

  std::cout << "Avg Edges per Iteration: " << davg_edges_processed_per_it
            << std::endl;
  std::cout << "Avg blossoms per Iteration: " << davg_bloss_per_it << std::endl;
  std::cout << "Product of Avg Edges(PerIter) * Avg blossom(PerIter): "
            << dnum_edges_processed / drounds / dsearch_phase_iterations +
                   2. * dnum_bloss / drounds / dsearch_phase_iterations
            << std::endl;
  std::cout << "Avg Million Edges per Second: "
            << davg_edges_processed / 1e6 / dtime << std::endl;
  std::cout << "Avg Processed Edges per Second: "
            << davg_edges_processed / dtime << std::endl;
  std::cout << "Avg blossoms per Processed Edge: "
            << davg_bloss_per_it / davg_edges_processed_per_it /
                   davg_edges_processed_per_it / davg_edges_processed_per_it
            << std::endl;
  // std::cout << "Avg blossoms per Processed Edge: " << dnum_bloss /
  // (dnum_edges_processed / drounds) << std::endl;

  return 0;
}
