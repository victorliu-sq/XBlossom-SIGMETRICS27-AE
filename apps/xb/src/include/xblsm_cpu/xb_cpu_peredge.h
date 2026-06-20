#ifndef X_BLOSSOM_XB_CPU_PEREDGE_H
#define X_BLOSSOM_XB_CPU_PEREDGE_H

#include "graph/xgraph.h"
#include <thread>
#include <numeric>

namespace xblossom {
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // Compute degrees of nodes in the current frontier.
  // Input:  nodes_vector = {u1, u2, ...}
  // Output: degrees[i] = degree of nodes_vector[i]
  static inline void compute_degrees(const Graph &G,
                                     const std::vector<int> &nodes_vector,
                                     std::vector<int> &degrees) {
    degrees.resize(nodes_vector.size());
    for (size_t i = 0; i < nodes_vector.size(); i++) {
      int u = nodes_vector[i];
      degrees[i] = G.rowOffsets[u + 1] - G.rowOffsets[u];
    }
  }

  static inline void compute_degrees_parallel(const Graph &G,
                                         const std::vector<int> &nodes_vector,
                                         std::vector<int> &degrees,
                                         std::vector<std::thread> &threads,
                                         int num_of_threads
  ) {
    const int n = static_cast<int>(nodes_vector.size());
    degrees.resize(n);

    const int work_per_thread = (n + num_of_threads - 1) / num_of_threads;

    for (int tid = 0; tid < num_of_threads; tid++) {
      int start = tid * work_per_thread;
      int end = std::min(n, (tid + 1) * work_per_thread);

      if (start >= end) {
        continue;
      }

      threads.emplace_back(
        [&, start, end]() {
          for (int i = start; i < end; i++) {
            int u = nodes_vector[i];
            degrees[i] = G.rowOffsets[u + 1] - G.rowOffsets[u];
          }
        }
      );
    }

    // Both Node-Level Parallelism and Edge-Level Parallelism Completes here
    for (auto &thread: threads) {
      thread.join();
    }
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // Input:  in = {a0, a1, a2}
  // Output: out = {0, a0, a0+a1, a0+a1+a2}   <-- size = n+1
  static inline void exclusive_scan(const std::vector<int> &in, std::vector<int> &out) {
    int n = in.size();
    out.resize(n + 1);
    out[0] = 0;

    // int sum = 0;
    // for (int i = 0; i < n; i++) {
    //   sum += in[i];
    //   out[i + 1] = sum;
    // }
    std::inclusive_scan(in.begin(), in.end(), out.begin() + 1);
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // Parallel builder: precomputes (v,w) endpoints for all edges using binary search
  static inline void build_edge_endpoints_parallel(const std::vector<int> &rowOffsets,
                                                   const std::vector<int> &columnIndices,
                                                   const std::vector<int> &nodes_vector,
                                                   const std::vector<int> &edge_offsets,
                                                   std::vector<int> &v_vector,
                                                   std::vector<int> &w_vector,
                                                   std::vector<std::thread> &threads,
                                                   int num_threads) {
    int total_edges = edge_offsets.back();
    v_vector.resize(total_edges);
    w_vector.resize(total_edges);

    threads.clear();
    threads.reserve(num_threads);

    int edges_per_thread = (total_edges + num_threads - 1) / num_threads;

    for (int tid = 0; tid < num_threads; tid++) {
      int start_edge = tid * edges_per_thread;
      int end_edge = std::min(total_edges, (tid + 1) * edges_per_thread);

      if (start_edge >= end_edge) continue;

      threads.emplace_back([&, start_edge, end_edge]() {
        for (int eid = start_edge; eid < end_edge; eid++) {
          // --- binary search to locate node index ---
          auto it = std::upper_bound(edge_offsets.begin(), edge_offsets.end(), eid);
          int v_idx = static_cast<int>(it - edge_offsets.begin()) - 1;
          int v = nodes_vector[v_idx];

          int offset_in_v = eid - edge_offsets[v_idx];
          int w = columnIndices[rowOffsets[v] + offset_in_v];

          v_vector[eid] = v;
          w_vector[eid] = w;
        }
      });
    }

    for (auto &t: threads) {
      if (t.joinable()) t.join();
    }
    threads.clear();
  }
}


#endif //X_BLOSSOM_XB_CPU_PEREDGE_H
