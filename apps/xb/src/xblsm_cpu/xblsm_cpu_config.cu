#include "xblsm_cpu/xblsm_cpu_config.h"
#include <iostream>
#include <set>
#include <vector>
#include <glog/logging.h>

namespace xblossom {
  // these three variables should be initialized by main function
  int nodes;
  int num_of_threads;
  int count;
  std::chrono::microseconds duration_blossom;
  std::chrono::microseconds duration_augmenting_path;
  std::chrono::microseconds duration_expand;
  std::chrono::microseconds duration_edge;
  std::chrono::microseconds duration_prepare;
  std::chrono::microseconds duration_update;
  std::chrono::microseconds duration_total(0);
  std::chrono::microseconds duration_overhead_elp(0);
  bool stop_immediately = false;

  uint64_t num_aug_path = 0;
  uint64_t num_blossom = 0;
  uint64_t num_edges_processed = 0;
  uint64_t num_aug_path_edges_processed = 0;
  uint64_t num_expand_edges_processed = 0;
  uint64_t num_blossom_edges_processed = 0;
  uint64_t num_search_phase_iterations = 0;
  uint64_t num_aug_path_discovery_iterations = 0;
  uint64_t num_reused_tree_nodes = 0;
  uint64_t num_reset_tree_nodes = 0;

  uint64_t cur_num_edges_processed = 0;
  uint64_t max_num_edges_processed = 0;

  void testMatching(std::vector<int> &M) {
    bool is_valid = true;
    for (int i = 0; i < M.size(); i++) {
      int k = M[i];
      if (k != -1 && M[k] != i) {
        is_valid = false;
      }
    }

    std::set<std::pair<int, int> > M_set;
    for (int i = 0; i < M.size(); i++) {
      if (M[i] != -1) {
        M_set.insert({std::min(i, M[i]), std::max(i, M[i])});
      }
    }

    if (is_valid) {
      // std::cout << "The matching is valid and the matching size is " << M_set.size() << std::endl;
      LOG(INFO) << "The matching is valid and the matching size is " << M_set.size();
    } else {
      // std::cout << "The matching is NOT valid !!!" << std::endl;
      LOG(INFO) << "The matching is NOT valid !!!" << std::endl;
    }
  }
}
