#ifndef XBLSM_CONFIG_H
#define XBLSM_CONFIG_H
#include <chrono>
#include <climits>

namespace xblossom {
  // definitions of all config variables are contained within src files
  extern int nodes;
  extern int num_of_threads;
  extern int count;
  extern std::chrono::microseconds duration_blossom;
  extern std::chrono::microseconds duration_augmenting_path;
  extern std::chrono::microseconds duration_expand;
  extern std::chrono::microseconds duration_edge;
  extern std::chrono::microseconds duration_prepare;
  extern std::chrono::microseconds duration_update;
  extern std::chrono::microseconds duration_total;
  extern std::chrono::microseconds duration_overhead_elp;
  extern bool stop_immediately;

  // dataset information
  extern uint64_t num_aug_path;
  extern uint64_t num_blossom;
  extern uint64_t num_edges_processed;
  extern uint64_t num_aug_path_edges_processed;
  extern uint64_t num_expand_edges_processed;
  extern uint64_t num_blossom_edges_processed;
  extern uint64_t num_search_phase_iterations;
  extern uint64_t num_aug_path_discovery_iterations;
  extern uint64_t num_reused_tree_nodes;
  extern uint64_t num_reset_tree_nodes;

  extern uint64_t cur_num_edges_processed;
  extern uint64_t max_num_edges_processed;

  struct XBlossomCpuEngineConfig {
    size_t num_of_threads;
    int threshold;

    explicit XBlossomCpuEngineConfig(size_t num_of_threads_ = 1, int threshold_ = INT_MAX)
      : num_of_threads(num_of_threads_), threshold(threshold_) {
    }
  };

  static inline void GetTimingSummary(double &augmenting_ms,
                                      double &expand_ms,
                                      double &blossom_ms,
                                      double &total_ms) {
    augmenting_ms = duration_augmenting_path.count() / 1000.0; // us → ms
    expand_ms = duration_expand.count() / 1000.0;
    blossom_ms = duration_blossom.count() / 1000.0;
    total_ms = augmenting_ms + expand_ms + blossom_ms;
  }
}

#endif //XBLSM_CONFIG_H
