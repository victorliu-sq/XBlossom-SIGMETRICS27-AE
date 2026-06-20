#include "xblsm_cpu/xblsm_cpu.h"
#include "xblsm_cpu/xblsm_cpu_pro.h"
#include "graph/xgraph.h"
#include "xblsm_cpu/xblsm_cpu_config.h"
#include "xblsm_cpu/xb_cpu_reuse.h"

namespace xblossom {
  extern int nodes;
  extern int num_of_threads;
  extern int count;
  extern std::chrono::microseconds duration_blossom;
  extern std::chrono::microseconds duration_augmenting_path;
  extern std::chrono::microseconds duration_expand;
  extern std::chrono::microseconds duration_edge;
  extern std::chrono::microseconds duration_prepare;
  extern std::chrono::microseconds duration_update;
  extern uint64_t num_aug_path_discovery_iterations;

  static void test_M_valid_and_size(std::vector<int> &M, bool &valid_M, int &matching_size) {
    bool is_valid = true;
    matching_size = 0;

    for (int i = 0; i < M.size(); i++) {
      int k = M[i];
      if (k != -1 && M[k] != i) {
        is_valid = false;
      }
      if (k != -1) {
        matching_size++;
      }
    }

    if (is_valid) {
    } else {
      valid_M = false;
      std::cout << "The matching is NOT valid !!!" << std::endl;
      std::cout << "valid_M = " << valid_M << std::endl;
    }
  }


  void parFindMaximumMatchingNoRecursionUpdatePathTable_pro_pernode(Graph &G, std::vector<int> &M, bool &valid_M,
                                                                    int threshold) {
    bool finished = false;
    std::vector<std::vector<int> > path_collection;
    path_collection.reserve(num_of_threads);
    std::vector<std::vector<int> > path_table_vector;
    path_table_vector.resize(nodes);
    for (auto &sub_vector: path_table_vector) {
      sub_vector.reserve(100);
      sub_vector.clear();
    }

    // Initialize is_even and belongs
    std::vector<int> is_even(nodes, 0); // Whether a node is even or not
    std::vector<int> belongs(nodes, -1); // Which tree the node belongs to

    while (!finished) {
      count++;

      // 1. Reset the path table (alternating tree)
      // Already put in parFindAugmentingPathNoRecursionUpdatePathTable_pro_all
      // for (auto &sub_vector: path_table_vector) {
      //   sub_vector.clear();
      // }

      // 2. Run the XBlossom algorithm to find disjoint augmenting path
      parFindAugmentingPathNoRecursionUpdatePathTable_pernode(G, M, path_collection, path_table_vector, is_even,
                                                              belongs);

      if (path_collection.empty()) {
        finished = true;
        break;
      }

      // 3. Flip the augmenting paths
      parNewMatchingVector(M, path_collection);
      path_collection.clear();


      int matching_size = 0;
      test_M_valid_and_size(M, valid_M, matching_size);

      if (!valid_M || matching_size / 2 >= threshold) {
        break;
      }
    }
  }

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  static std::mutex path_mutex_lock;


  static void parAugmentingPath_pro_all(const std::vector<int> &rowOffsets,
                                        const std::vector<int> &columnIndices,
                                        const std::vector<int> &nodes_vector,
                                        std::atomic<size_t> &next_node, int chunk_size, std::vector<int> &is_even,
                                        std::vector<int> &belongs,
                                        std::vector<std::vector<int> > &path_table_vector,
                                        std::vector<std::atomic<int> > &select_tree,
                                        std::vector<std::vector<int> > &path_collection
  ) {
    std::vector<int> local_path;
    int estimated_size = static_cast<int>((static_cast<double>(is_even.size()) / num_of_threads) * 1.25);
    local_path.reserve(estimated_size);

    int local_num_aug_path = 0; // NEW: per-thread augmenting path counter
    int local_num_edges_processed = 0; // NEW: # of edges processed

    while (true) {
      const size_t begin = next_node.fetch_add(chunk_size, std::memory_order_relaxed);
      if (begin >= nodes_vector.size()) {
        break;
      }
      const size_t end = std::min(begin + static_cast<size_t>(chunk_size), nodes_vector.size());

      for (size_t i = begin; i < end; i++) {
        int v = nodes_vector[i];
        int start_index = rowOffsets[v];
        int end_index = rowOffsets[v + 1];

        local_num_edges_processed += end_index - start_index + 1; // NEW: update # of edges processed

        for (int j = start_index; j < end_index; j++) {
          int w = columnIndices[j];
          int expected = 0;
          int tree_v = belongs[v];
          int tree_w = belongs[w];

          if (is_even[w] && tree_v != tree_w && tree_v != -1 && tree_w != -1) {
            if (select_tree[tree_v].compare_exchange_strong(expected, 1)) {
              if (select_tree[tree_w].compare_exchange_strong(expected, 1)) {
                std::vector<int> path_v_vector = find_path_vector(path_table_vector, v);
                std::vector<int> path_w_vector = find_path_vector(path_table_vector, w);

                for (int s = path_v_vector.size() - 1; s >= 0; s--) {
                  local_path.push_back(path_v_vector[s]);
                }

                for (int t = 0; t < path_w_vector.size(); t++) {
                  local_path.push_back(path_w_vector[t]);
                }

                // NEW: we discovered an augmenting path
                local_num_aug_path++;
              } else {
                int expected_to = 1;
                select_tree[tree_v].compare_exchange_strong(expected_to, 0);
              }
            } else {
              break;
            }
          }
        }
      }
    }
    // Lock Guard to update discovered augmenting paths
    {
      std::lock_guard<std::mutex> guard(path_mutex_lock);
      if (!local_path.empty()) {
        path_collection.push_back(local_path);
      }

      // NEW update global config
      num_aug_path += local_num_aug_path;
      num_edges_processed += local_num_edges_processed;
      num_aug_path_edges_processed += local_num_edges_processed;
      cur_num_edges_processed += local_num_edges_processed;
    }
  }


  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  static std::mutex expand_mutex_lock;

  static void parExpand_pro_all(const std::vector<int> &rowOffsets,
                                const std::vector<int> &columnIndices,
                                const std::vector<int> &nodes_vector,
                                std::atomic<size_t> &next_node, int chunk_size, std::vector<int> &is_even, std::vector<int> &belongs,
                                std::vector<std::vector<int> > &path_table_vector, std::vector<int> &vector_1,
                                std::vector<std::atomic<int> > &select_match, std::vector<int> &M) {
    std::vector<int> local_vector;
    int estimated_size = static_cast<int>((static_cast<double>(is_even.size()) / num_of_threads) * 1.25);
    local_vector.reserve(estimated_size);

    int local_num_edges_processed = 0;

    while (true) {
      const size_t begin = next_node.fetch_add(chunk_size, std::memory_order_relaxed);
      if (begin >= nodes_vector.size()) {
        break;
      }
      const size_t end = std::min(begin + static_cast<size_t>(chunk_size), nodes_vector.size());

      for (size_t i = begin; i < end; i++) {
        int v = nodes_vector[i];
        int start_index = rowOffsets[v];
        int end_index = rowOffsets[v + 1];

        local_num_edges_processed += end_index - start_index + 1;

        for (int j = start_index; j < end_index; j++) {
          int w = columnIndices[j];
          int x = M[w];

          if (belongs[w] == -1) {
            int expected = 0;
            int min_w_x = std::min(w, x);

            if (select_match[min_w_x].compare_exchange_strong(expected, 1)) {
              path_table_vector[x].push_back(w);
              path_table_vector[x].push_back(v);

              is_even[w] = 0;
              is_even[x] = 1;

              belongs[w] = belongs[v];
              belongs[x] = belongs[v];

              local_vector.push_back(x);
            }
          }
        }
      }
    } {
      std::lock_guard<std::mutex> guard(expand_mutex_lock);
      vector_1.insert(vector_1.end(), local_vector.begin(), local_vector.end());
      num_edges_processed += local_num_edges_processed;
      num_expand_edges_processed += local_num_edges_processed;
      cur_num_edges_processed += local_num_edges_processed;
    }
  }


  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  static std::mutex blossom_mutex_lock;

  static void findBlossom(std::vector<std::vector<int> > &path_table_vector,
                          int v,
                          int w,
                          std::vector<int> &blossom,
                          std::vector<int> &belongs,
                          bool &consistent_flag,
                          bool &valid_flag) {
    consistent_flag = true;
    valid_flag = true;
    blossom.clear();

    // ======================================================
    // 1. Find the blossom base of v and w
    // ======================================================
    int cur_v = v;
    int cur_w = w;
    int it = 0;

    while (cur_v != cur_w) {
      if (path_table_vector[cur_v].empty()) {
        cur_v = w; // switch side
      } else {
        cur_v = path_table_vector[cur_v].back();
      }

      if (path_table_vector[cur_w].empty()) {
        cur_w = v; // switch side
      } else {
        cur_w = path_table_vector[cur_w].back();
      }

      if (++it > (int) path_table_vector.size()) {
        consistent_flag = false;
        valid_flag = false;
        return;
      }
    }
    int blossom_base = cur_v;

    // ======================================================
    // 2. Materialize blossom
    // ======================================================

    // v → base (reverse order)
    // {
    //   std::vector<int> tmp;
    //   int cur = v;
    //   tmp.push_back(cur);
    //
    //   while (cur != blossom_base && !path_table_vector[cur].empty()) {
    //     // append full chain of cur
    //     tmp.insert(tmp.end(),
    //                path_table_vector[cur].begin(),
    //                path_table_vector[cur].end());
    //     cur = tmp.back();
    //   }
    //
    //   // reverse append to blossom
    //   blossom.insert(blossom.end(), tmp.rbegin(), tmp.rend());
    // }
    {
      int cur = v;
      blossom.insert(blossom.begin(), cur); // place v at front

      while (cur != blossom_base && !path_table_vector[cur].empty()) {
        // insert this entire chain reversed into the *front*
        blossom.insert(blossom.begin(),
                       path_table_vector[cur].rbegin(),
                       path_table_vector[cur].rend());
        cur = path_table_vector[cur].back();
      }
    }

    // w → base (forward order)
    {
      int cur = w;
      blossom.push_back(cur);

      while (cur != blossom_base && !path_table_vector[cur].empty()) {
        blossom.insert(blossom.end(),
                       path_table_vector[cur].begin(),
                       path_table_vector[cur].end());
        cur = blossom.back();
      }
    }
  }

  static void parBlossom_pro_all(const std::vector<int> &rowOffsets,
                                 const std::vector<int> &columnIndices,
                                 const std::vector<int> &nodes_vector,
                                 std::atomic<size_t> &next_node, int chunk_size, std::vector<int> &is_even, std::vector<int> &belongs,
                                 std::vector<std::vector<int> > &path_table_vector, std::vector<int> &vector_2,
                                 std::vector<std::atomic<int> > &select_blossom,
                                 std::vector<int> &blossom_to_base, std::vector<int> &M) {
    std::vector<int> local_vector;
    int estimated_size = static_cast<int>((static_cast<double>(is_even.size()) / num_of_threads));
    local_vector.reserve(estimated_size);

    // NEW: count the # of blossoms
    int local_num_blossom = 0;
    int local_num_edges_processed = 0;

    while (true) {
      const size_t begin = next_node.fetch_add(chunk_size, std::memory_order_relaxed);
      if (begin >= nodes_vector.size()) {
        break;
      }
      const size_t end = std::min(begin + static_cast<size_t>(chunk_size), nodes_vector.size());

      for (size_t i = begin; i < end; i++) {
        int v = nodes_vector[i];
        int start_index = rowOffsets[v];
        int end_index = rowOffsets[v + 1];

        local_num_edges_processed += end_index - start_index + 1;

        for (int j = start_index; j < end_index; j++) {
          int w = columnIndices[j];

          if (is_even[w] && belongs[w] == belongs[v] && w != M[v] && belongs[w] != -1) {
            bool consistent_flag = true;
            bool valid_flag = true;


            // NEW: increment the # of blossoms
            local_num_blossom++;


            // std::vector<int> path_v_vector = find_path_vector_blossom(path_table_vector, v);
            // std::vector<int> path_w_vector = find_path_vector_blossom_w(path_table_vector, w, belongs, consistent_flag);
            //
            // if (!consistent_flag) {
            //   std::cout << "Cycle Detection!" << std::endl;
            //   continue;
            // }
            //
            // std::vector<int> blossom;
            // blossom.reserve(path_v_vector.size() + path_w_vector.size());
            // find_blossom_vector_debug(path_v_vector, path_w_vector, blossom, path_table_vector, valid_flag);
            // if (!valid_flag) {
            //   std::cout << "Cycle Detection in Blossom!" << std::endl;
            //   continue;
            // }
            // base:  blossom[0], blossom[blossom.size() - 1];
            // blossom.reserve(path_v_vector.size() + path_w_vector.size());


            // ===============================================================================================
            std::vector<int> blossom;
            findBlossom(path_table_vector, v, w, blossom, belongs, consistent_flag, valid_flag);
            // ===============================================================================================

            blossom_to_base[blossom[0]] = blossom[0];

            ////////////////////////////////////////////////////////////////////////////////////////////

            // iterate original odd nodes anti-clockwise
            for (int k = blossom.size() - 3; k >= 0; k = k - 2) {
              int current = blossom[k];

              if (blossom_to_base[current] == -1) {
                blossom_to_base[current] = blossom[0];
              }

              // The update of is_even may be missing
              if (!is_even[current] && path_table_vector[current].empty()) {
                int expected = 0;

                if (select_blossom[current].compare_exchange_strong(expected, 1)) {
                  bool test = true;

                  // store the path anti-clockwise
                  for (int n = k + 1; n < blossom.size(); n++) {
                    path_table_vector[current].push_back(blossom[n]);
                  }

                  // Debugging
                  for (int c = 0; c < path_table_vector[current].size(); c++) {
                    int check = path_table_vector[current][c];
                    for (int d = c + 1; d < path_table_vector[current].size(); d++) {
                      if (check == path_table_vector[current][d]) {
                        test = false;
                        // std::cout << "Cycle Detection in Blossom!" << std::endl;
                        break;
                      }
                    }
                  }

                  if (!test) {
                    path_table_vector[current].clear();
                    continue;
                  } else {
                    // Main logics
                    local_vector.push_back(current);
                    is_even[current] = 1;
                  }
                }
              }
            }

            ////////////////////////////////////////////////////////////////////////////////////////////

            // iterate original odd nodes clockwise
            for (int k = 2; k < blossom.size() - 1; k = k + 2) {
              int current = blossom[k];

              if (blossom_to_base[current] == -1) {
                blossom_to_base[current] = blossom[0];
              }

              if (!is_even[current] && path_table_vector[current].empty()) {
                int expected = 0;

                if (select_blossom[current].compare_exchange_strong(expected, 1)) {
                  bool test = true;

                  // store the path clockwise
                  for (int m = k - 1; m >= 0; m--) {
                    path_table_vector[current].push_back(blossom[m]);
                  }

                  for (int c = 0; c < path_table_vector[current].size(); c++) {
                    int check = path_table_vector[current][c];
                    for (int d = c + 1; d < path_table_vector[current].size(); d++) {
                      if (check == path_table_vector[current][d]) {
                        test = false;
                        // std::cout << "Cycle Detection in Blossom!" << std::endl;
                        break;
                      }
                    }
                  }

                  if (!test) {
                    path_table_vector[current].clear();
                    continue;
                  } else {
                    local_vector.push_back(current);
                    is_even[current] = 1;
                  }
                }
              }
            }
          }

          ////////////////////////////////////////////////////////////////////////////////////////////
        }
      }
    }
    // update vector 2
    {
      std::lock_guard<std::mutex> guard(blossom_mutex_lock);
      vector_2.insert(vector_2.end(), local_vector.begin(), local_vector.end());

      // NEW: update the global # of blossoms
      num_blossom += local_num_blossom;
      num_edges_processed += local_num_edges_processed;
      num_blossom_edges_processed += local_num_edges_processed;
      cur_num_edges_processed += local_num_edges_processed;
    }
  }


  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  void parFindAugmentingPathNoRecursionUpdatePathTable_pernode(Graph &G,
                                                               std::vector<int> &M,
                                                               std::vector<std::vector<int> > &path_collection,
                                                               std::vector<std::vector<int> > &path_table_vector,
                                                               std::vector<int> &is_even,
                                                               std::vector<int> &belongs) {
    //    auto start_prepare = std::chrono::high_resolution_clock::now();

    bool check_all = false;

    std::vector<std::atomic<int> > select_tree(nodes);
    std::vector<std::atomic<int> > select_match(nodes);
    std::vector<std::atomic<int> > select_blossom(nodes);

    parInitializeAtomicStructures(select_tree, select_match, select_blossom, nodes, num_of_threads);

    // Done below
    // parInitializeExposed(exposed, is_even, belongs, num_of_threads);

    std::vector<std::thread> threads;
    threads.reserve(num_of_threads);

    ////////////////////////////////////////////////////

    std::vector<int> nodes_vector;
    nodes_vector.reserve(nodes);
    // nodes_vector = exposed;

    std::vector<int> vector_1;
    vector_1.reserve(nodes);

    std::vector<int> vector_2;
    vector_2.reserve(nodes);
    const int node_schedule_chunk = 64;

    // ================================ Reset the entire PathTable ========================================
    // Find all exposed nodes
    // std::vector<int> exposed;
    // exposed.reserve(nodes);
    // parExposedNode(exposed, M);
    //
    // is_even.resize(nodes, 0);
    // belongs.resize(nodes, -1);
    //
    // parInitializeAtomicPathTable(select_tree, select_match, select_blossom, path_table_vector, nodes, num_of_threads);
    // parInitializeExposed(exposed, is_even, belongs, num_of_threads);
    // for (auto &sub_vector: path_table_vector) {
    //   sub_vector.clear();
    // }
    // nodes_vector = exposed;
    // ================================ Reset the entire PathTable ========================================


    // ================================ Reuse the PathTable ========================================
    for (int tid = 0; tid < num_of_threads; tid++) {
      threads.emplace_back(
        parReuseRemainingTrees,
        tid,
        num_of_threads,
        nodes,
        std::ref(M),
        std::ref(is_even),
        std::ref(belongs),
        std::ref(path_table_vector),
        std::ref(vector_1),
        std::ref(vector_2),
        std::ref(queue_mutex)
      );
    }

    for (auto &th: threads) th.join();

    threads.clear();

    copy_vector_to_vector(nodes_vector, vector_1, vector_2);
    // ================================ Reuse the PathTable ========================================


    ////////////////////////////////////////////////////

    //    auto end_prepare = std::chrono::high_resolution_clock::now();
    //    duration_prepare = std::chrono::duration_cast<std::chrono::microseconds>(end_prepare-start_prepare)+duration_prepare;

    ////////////////////////////////////////////////////


    ////////////////////////////////////////////////////
    std::vector<int> blossom_to_base(nodes, -1);

    while (!check_all) {
      num_search_phase_iterations++;

      // 1. Augmenting Path

      // NEW: try to record maximum # of edges per iter
      cur_num_edges_processed = 0;

      auto start_augmenting_path = std::chrono::high_resolution_clock::now();
      std::atomic<size_t> next_aug_node{0};
      for (int begin = 0; begin < num_of_threads; begin++) {
        threads.emplace_back(parAugmentingPath_pro_all,
                             std::ref(G.rowOffsets),
                             std::ref(G.columnIndices),
                             std::ref(nodes_vector),
                             std::ref(next_aug_node),
                             node_schedule_chunk,
                             std::ref(is_even),
                             std::ref(belongs),
                             std::ref(path_table_vector),
                             std::ref(select_tree),
                             std::ref(path_collection));
      }

      for (auto &thread: threads) {
        thread.join();
      }

      // NEW: try to record maximum # of edges per iter
      max_num_edges_processed = std::max(max_num_edges_processed, cur_num_edges_processed);


      auto end_augmenting_path = std::chrono::high_resolution_clock::now();
      duration_augmenting_path = std::chrono::duration_cast<std::chrono::microseconds>(
                                   end_augmenting_path - start_augmenting_path) + duration_augmenting_path;

      if (!path_collection.empty()) {
        num_aug_path_discovery_iterations++;
        return;
      }

      threads.clear();

      copy_vector_to_vector(nodes_vector, vector_1, vector_2);
      vector_1.clear();

      ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
      // 2. Expansion
      auto start_expand = std::chrono::high_resolution_clock::now();
      std::atomic<size_t> next_expand_node{0};
      for (int begin = 0; begin < num_of_threads; begin++) {
        threads.emplace_back(parExpand_pro_all,
                             std::ref(G.rowOffsets),
                             std::ref(G.columnIndices),
                             std::ref(nodes_vector),
                             std::ref(next_expand_node),
                             node_schedule_chunk,
                             std::ref(is_even),
                             std::ref(belongs),
                             std::ref(path_table_vector),
                             std::ref(vector_1),
                             std::ref(select_match),
                             std::ref(M));
      }

      for (auto &thread: threads) {
        thread.join();
      }
      auto end_expand = std::chrono::high_resolution_clock::now();
      duration_expand = std::chrono::duration_cast<std::chrono::microseconds>(end_expand - start_expand) +
                        duration_expand;

      threads.clear();
      // nodes_vector will be reset.
      // vector_1 stores all newly expanded even nodes from leaves of alternating trees
      copy_vector_to_vector(nodes_vector, vector_1, vector_2);
      vector_2.clear();

      ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
      // 3. Blossom
      auto start_blossom = std::chrono::high_resolution_clock::now();
      std::atomic<size_t> next_blossom_node{0};
      for (int begin = 0; begin < num_of_threads; begin++) {
        threads.emplace_back(parBlossom_pro_all, std::ref(G.rowOffsets), std::ref(G.columnIndices),
                             std::ref(nodes_vector),
                             std::ref(next_blossom_node), node_schedule_chunk, std::ref(is_even), std::ref(belongs),
                             std::ref(path_table_vector), std::ref(vector_2), std::ref(select_blossom),
                             std::ref(blossom_to_base), std::ref(M));
      }

      for (auto &thread: threads) {
        thread.join();
      }

      auto end_blossom = std::chrono::high_resolution_clock::now();
      duration_blossom = std::chrono::duration_cast<std::chrono::microseconds>(end_blossom - start_blossom) +
                         duration_blossom;


      threads.clear();
      // nodes_vector will be reset.
      // vector_2 stores all newly expanded even nodes from blossom
      copy_vector_to_vector(nodes_vector, vector_1, vector_2);

      ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

      if (nodes_vector.empty()) {
        check_all = true;
        break;
      }
    }

    return;
  }
}
