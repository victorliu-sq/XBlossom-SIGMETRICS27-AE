#ifndef X_BLOSSOM_XB_CPU_REUSE_H
#define X_BLOSSOM_XB_CPU_REUSE_H

#include "xblsm_cpu/xblsm_cpu_config.h"

static std::mutex queue_mutex;

static void parReuseRemainingTrees(
  int tid,
  int num_threads,
  int nodes,
  std::vector<int> &M,
  std::vector<int> &is_even,
  std::vector<int> &belongs,
  std::vector<std::vector<int> > &path_table_vector,
  std::vector<int> &vector_1,
  std::vector<int> &vector_2,
  std::mutex &queue_mutex
) {
  std::vector<int> local_v1;
  std::vector<int> local_v2;
  uint64_t local_reused_tree_nodes = 0;
  uint64_t local_reset_tree_nodes = 0;

  // int est = nodes / num_threads + 16;
  // local_v1.reserve(est);
  // local_v2.reserve(est);

  // Stride loop over nodes
  for (int x = tid; x < nodes; x += num_threads) {
    int mate = M[x];
    int root = belongs[x];

    if (mate == -1) {
      // Case 1: Unmatched node
      is_even[x] = 1;
      belongs[x] = x;
      path_table_vector[x].clear();
      local_reset_tree_nodes++;
      local_v1.push_back(x);
    } else {
      if (root == -1 || M[root] != -1) {
        // Case 2: no valid tree
        is_even[x] = 0;
        belongs[x] = -1;
        path_table_vector[x].clear();
        local_reset_tree_nodes++;
      } else {
        // Case 3: in valid alternating tree
        local_reused_tree_nodes++;
        if (is_even[x]) {
          local_v2.push_back(x);
        }
      }
    }
  }

  // Merge results into shared vectors
  {
    std::lock_guard<std::mutex> guard(queue_mutex);

    if (!local_v1.empty()) {
      vector_1.insert(vector_1.end(), local_v1.begin(), local_v1.end());
    }
    if (!local_v2.empty()) {
      vector_2.insert(vector_2.end(), local_v2.begin(), local_v2.end());
    }
    xblossom::num_reused_tree_nodes += local_reused_tree_nodes;
    xblossom::num_reset_tree_nodes += local_reset_tree_nodes;
  }
}

static void initialize_range_atomic_vectors(std::vector<std::atomic<int> > &vec1,
                                            std::vector<std::atomic<int> > &vec2,
                                            std::vector<std::atomic<int> > &vec3,
                                            int start, int end) {
  for (int i = start; i < end; ++i) {
    vec1[i] = 0;
    vec2[i] = 0;
    vec3[i] = 0;
  }
}

static void parInitializeAtomicStructures(std::vector<std::atomic<int> > &select_tree,
                                          std::vector<std::atomic<int> > &select_match,
                                          std::vector<std::atomic<int> > &select_blossom,
                                          int nodes, int num_threads) {
  std::vector<std::thread> threads;
  int chunk_size = (nodes + num_threads - 1) / num_threads;

  for (int t = 0; t < num_threads; ++t) {
    int start = t * chunk_size;
    int end = std::min(start + chunk_size, nodes);
    threads.emplace_back(initialize_range_atomic_vectors, std::ref(select_tree), std::ref(select_match),
                         std::ref(select_blossom), start, end);
  }

  for (auto &thread: threads) {
    thread.join();
  }
}

#endif //X_BLOSSOM_XB_CPU_REUSE_H
