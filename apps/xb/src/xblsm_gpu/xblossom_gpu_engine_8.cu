#include "xbsm_gpu/xblossom_gpu_engine_8.h"
#include <glog/logging.h>
#include "utils/cuda_algo.h"
#include "common/stopwatch.h"

namespace zblossom {
  XBlossomGpuEngine8::XBlossomGpuEngine8(const HGraph &g)
    : SecondaryMaximumMatchingGPUEngine(g.nnodes),
      // host_graph_(g),
      device_graph_(g),
      path_table_(nnodes_),
      is_even_(nnodes_),
      tree_roots_(nnodes_),
      blossom_to_base_(nnodes_),
      atomic_locks_tree_(nnodes_),
      atomic_locks_match_(nnodes_),
      atomic_locks_odd_nodes_(nnodes_),
      enode_queue_(nnodes_),
      col_indices_presum_(nnodes_ + 1),
      col_indices_sizes_(nnodes_ + 1) {
    // Reset PathTable and TreeRoots at the beginning
    this->path_table_.ResetPathTable();
    this->tree_roots_.Fill(nnodes_);
  }

  XBlossomGpuEngine8::XBlossomGpuEngine8(const HGraph &g, size_t path_table_buffer_ratio)
    : SecondaryMaximumMatchingGPUEngine(g.nnodes),
      // host_graph_(g),
      device_graph_(g),
      path_table_(nnodes_, path_table_buffer_ratio),
      is_even_(nnodes_),
      tree_roots_(nnodes_),
      blossom_to_base_(nnodes_),
      atomic_locks_tree_(nnodes_),
      atomic_locks_match_(nnodes_),
      atomic_locks_odd_nodes_(nnodes_),
      enode_queue_(nnodes_),
      col_indices_presum_(nnodes_ + 1),
      col_indices_sizes_(nnodes_ + 1) {
    // Reset PathTable and TreeRoots at the beginning
    this->path_table_.ResetPathTable();
    this->tree_roots_.Fill(nnodes_);
  }


  void XBlossomGpuEngine8::FindAndFlipAugmentingPath() {
    ms_t time_expand_it{0};
    ms_t time_blossom_it{0};
    Stopwatch sw;

    this->InitAlternatingForest();

    // Continue while even nodes remain and no augmenting path has been found
    while (!this->IsExhausted()
           && !this->FindAndFlipAugmentingPathInAlternatingForest()) {
      sw.Start();
      this->ExpandAlternatingForest();
      sw.Stop();
      time_expand_it += sw.GetMs();

      sw.Start();
      this->TransformOddNodesInBlossom();
      sw.Stop();
      time_blossom_it += sw.GetMs();
    }

    LOG(INFO) << "{Iteration} Total Expanding time is " << time_expand_it << " ms";
    LOG(INFO) << "{Iteration} Total Blossom time is " << time_blossom_it << " ms";
  }

  void XBlossomGpuEngine8::InitAlternatingForest() {
    // ---- 1. Reset Host-side Structures ----
    LOG(INFO) << "---- Lazy Reset ---- ";
    // Not need to reset entire path table for efficiency
    // path_table_.ResetPathTable();

    // Capture nnodes_ explicitly as a scalar before the lambda
    this->atomic_locks_tree_.Fill(DFLAG_FALSE);
    this->atomic_locks_match_.Fill(DFLAG_FALSE);
    this->atomic_locks_odd_nodes_.Fill(DFLAG_FALSE);

    // Reset all of them if a node is not in a tree yet (root[x] == nnodes)
    // Or its root has been reset (is_root_and_reset[root[x]] == 1)
    this->dev_found_.SetH2D(DFLAG_FALSE);

    // Make sure the fills are finished before we use the table again

    index_t nnodes = this->nnodes_;
    auto input_matching_dview = this->dev_matching_.DeviceView();

    auto is_even_dview = this->is_even_.DeviceView();
    auto tree_roots_dview = this->tree_roots_.DeviceView();

    auto enode_queue_dview = this->enode_queue_.DeviceView();

    // Find all exposed nodes
    CUDA_CHECK(cudaDeviceSynchronize());

    this->enode_queue_.Clear();
    enode_queue_.PrepareForAppendingENode1();
    // for logging
    auto enode1_begin = enode_queue_.ENnode1Begin();

    auto path_table_dview = this->path_table_.DeviceView();

    this->ExecuteNTasklet(nnodes_, [=] __device__ (index_t x) mutable {
      // With Prev
      if (input_matching_dview[x] == nnodes) {
        // unmatched
        is_even_dview[x] = 1;
        tree_roots_dview[x] = x;
        enode_queue_dview.AppendENode1(x);
        path_table_dview.ResetNode(x);
      } else {
        // matched
        index_t root = tree_roots_dview[x];
        if (root == nnodes || input_matching_dview[root] != nnodes) {
          // If matched, and either not in a tree yet or in a tree whose root is matched now
          is_even_dview[x] = 0;
          tree_roots_dview[x] = nnodes;
          // Reset everything
          path_table_dview.ResetNode(x);
        }
      }
    });

    auto enode1_end = enode_queue_.ENnode1End();
    LOG(INFO) << "[Init] Enqueue " << enode1_end - enode1_begin << " enodes";

    this->enode_queue_.PrepareForAppendingENode2();

    this->ExecuteNTasklet(nnodes_, [=] __device__ (index_t x) mutable {
      // With Prev
      if (input_matching_dview[x] != nnodes) {
        // matched
        index_t root = tree_roots_dview[x];
        if (root != nnodes && input_matching_dview[root] == nnodes) {
          // If matched, and already in a tree whose root is still unmatched.
          if (is_even_dview[x]) {
            // if even node in a tree, try to expand from it
            // is_even_dview[x] = 1;
            // tree_roots_dview[x] = root;
            enode_queue_dview.AppendENode2(x);
          }
          // if odd node in a tree
          // else {
          //   is_even_dview[x] = 0;
          //   tree_roots_dview[x] = root;
          // }
        }
      }
    });

    // Reset reset bits
    // this->is_root_and_reset_.Fill(DFLAG_FALSE);

    CUDA_CHECK(cudaDeviceSynchronize());
  }

  bool XBlossomGpuEngine8::FindAndFlipAugmentingPathInAlternatingForest() {
    auto start_time = getNanoSecond();

    index_t enode_base_offset = this->enode_queue_.Begin();
    const size_t total_even_nodes = enode_queue_.Size();
    if (total_even_nodes == 0) {
      this->found_ = false;
      return this->found_;
    }

    const size_t nnodes = this->nnodes_;
    auto graph_dview = this->device_graph_.DeviceView();
    auto matching_dview = this->dev_matching_.DeviceView();
    auto path_table_dview = this->path_table_.DeviceView();

    auto is_even_dview = this->is_even_.DeviceView();
    auto tree_roots_dview = this->tree_roots_.DeviceView();
    auto enode_queue_dview = this->enode_queue_.DeviceView();

    auto atomic_locks_tree_dview = this->atomic_locks_tree_.DeviceView();
    auto found_dview = this->dev_found_.DeviceView();


    auto col_indices_sizes_dview = this->col_indices_sizes_.DeviceView();
    auto col_indices_presum_dview = this->col_indices_presum_.DeviceView();

    CUDA_CHECK(cudaDeviceSynchronize());

    this->ExecuteNTasklet(total_even_nodes, [=] __device__ (index_t idx) mutable {
      index_t v = enode_queue_dview[enode_base_offset + idx];
      col_indices_sizes_dview[idx] = graph_dview.row_offsets[v + 1] - graph_dview.row_offsets[v];
    });

    // Compute Presum
    thrust::exclusive_scan(this->col_indices_sizes_.begin(),
                           this->col_indices_sizes_.begin() + total_even_nodes + 1,
                           this->col_indices_presum_.begin());

    // std::cout << "Presum:" << std::endl;
    // for (int i = 0; i < total_even_nodes + 1; ++i) {
    //   std::cout << "i: " << this->col_indices_presum_[i] << std::endl;
    // }

    size_t total_num_pairs = col_indices_presum_[total_even_nodes];
    // std::cout << "Total number of pairs : " << total_num_pairs << std::endl;

    CUDA_CHECK(cudaDeviceSynchronize());

    // std::cout << "AugPath() begins" << std::endl;

    // auto reset_roots_dview = this->is_root_and_reset_.DeviceView();

    this->ExecuteNTasklet(total_num_pairs, [=] __device__ (index_t tid) mutable {
      index_t v_idx = FindRightmostLTEQ(col_indices_presum_dview, total_even_nodes + 1, tid);
      index_t v = enode_queue_dview[enode_base_offset + v_idx];
      // printf("For tid: %d, v_idx is :%d, v is :%d\n", tid, v_idx, v);
      int delta = tid - col_indices_presum_dview[v_idx];

      index_t w_offset = graph_dview.row_offsets[v] + delta;
      index_t w = graph_dview.col_indices[w_offset];

      index_t root_v = tree_roots_dview[v];
      index_t root_w = tree_roots_dview[w];

      if (is_even_dview[w] && root_v != root_w && root_v != nnodes && root_w != nnodes) {
        index_t first_lock = MIN(root_v, root_w);
        index_t second_lock = MAX(root_v, root_w);
        // printf("Try to add augmentpath between Node %d and Node %d\n", v, w);

        // Lock the smaller index first
        if (atomicCAS(&atomic_locks_tree_dview[first_lock], DFLAG_FALSE, DFLAG_TRUE) != DFLAG_FALSE) {
          return;
        }

        // Lock the larger index second
        if (atomicCAS(&atomic_locks_tree_dview[second_lock], DFLAG_FALSE, DFLAG_TRUE) != DFLAG_FALSE) {
          atomicExch(&atomic_locks_tree_dview[first_lock], DFLAG_FALSE);
          return;
        }

        path_table_dview.AddAugmentingPath(v, w, matching_dview);
        __threadfence();

        // found_dview = DFLAG_TRUE;
        atomicExch(&found_dview, DFLAG_TRUE);

        // Reset these two trees
        // reset_roots_dview[root_v] = DFLAG_TRUE;
        // reset_roots_dview[root_w] = DFLAG_TRUE;
      }
    });

    CUDA_CHECK(cudaDeviceSynchronize());
    auto end_time = getNanoSecond();

    // std::cout << "AugPath() ends" << std::endl;

    this->time_augmenting_path += end_time - start_time;

    this->found_ = this->dev_found_.GetD2H();

    LOG(INFO) << "(ENodeQueue is Not Empty) AugPath found: " << this->found_;

    return this->found_;
  }


  void XBlossomGpuEngine8::ExpandAlternatingForest() {
    auto start_time = getNanoSecond();

    const size_t total_even_nodes = enode_queue_.Size();
    if (total_even_nodes == 0) {
      return;
    }

    const size_t nnodes = this->nnodes_;
    auto graph_dview = this->device_graph_.DeviceView();
    auto matching_dview = this->dev_matching_.DeviceView();
    auto path_table_dview = this->path_table_.DeviceView();

    auto is_even_dview = this->is_even_.DeviceView();
    auto tree_roots_dview = this->tree_roots_.DeviceView();
    auto enode_queue_dview = this->enode_queue_.DeviceView();

    auto atomic_locks_match_dview = this->atomic_locks_match_.DeviceView();

    index_t enode_base_offset = this->enode_queue_.Begin();

    // Bug-fix: prepare to add enodes1 only after retrieving the base offset
    this->enode_queue_.PrepareForAppendingENode1();

    // Presum Begins
    auto col_indices_sizes_dview = this->col_indices_sizes_.DeviceView();
    auto col_indices_presum_dview = this->col_indices_presum_.DeviceView();

    CUDA_CHECK(cudaDeviceSynchronize());

    this->ExecuteNTasklet(total_even_nodes, [=] __device__ (index_t idx) mutable {
      index_t v = enode_queue_dview[enode_base_offset + idx];
      col_indices_sizes_dview[idx] = graph_dview.row_offsets[v + 1] - graph_dview.row_offsets[v];
    });

    // Exclusive Scan
    thrust::exclusive_scan(this->col_indices_sizes_.begin(),
                           this->col_indices_sizes_.begin() + total_even_nodes + 1,
                           this->col_indices_presum_.begin());

    size_t total_num_pairs = col_indices_presum_[total_even_nodes];

    // for logging
    auto enode1_begin = enode_queue_.ENnode1Begin();

    CUDA_CHECK(cudaDeviceSynchronize());

    this->ExecuteNTasklet(total_num_pairs, [=] __device__ (index_t tid) mutable {
      index_t v_idx = FindRightmostLTEQ(col_indices_presum_dview, total_even_nodes, tid);
      index_t v = enode_queue_dview[enode_base_offset + v_idx];
      int delta = tid - col_indices_presum_dview[v_idx];

      index_t w_offset = graph_dview.row_offsets[v] + delta;
      index_t w = graph_dview.col_indices[w_offset];

      index_t root_v = tree_roots_dview[v];
      index_t root_w = tree_roots_dview[w];

      // if w is matched, and it is not in an alternating tree yet => expand it
      // if w is unmatched, its root will be init to itself
      if (root_w == nnodes) {
        index_t x = matching_dview[w];
        index_t match_idx = MIN(w, x);
        if (atomicCAS(&atomic_locks_match_dview[match_idx], DFLAG_FALSE, DFLAG_TRUE) == DFLAG_FALSE) {
          /* **************************************** */
          path_table_dview.ExpandTwoNodes(v, w, x);

          __threadfence();

          // is_even_dview[w] = 0;
          // is_even_dview[x] = 1;
          // printf("Expand: Set Node %d as even\n", x);

          // tree_roots_dview[w] = root_v;
          // tree_roots_dview[x] = root_v;

          /****** atomicvisibility changes ***** */
          atomicExch(&is_even_dview[w], 0);
          atomicExch(&is_even_dview[x], 1);

          atomicExch(&tree_roots_dview[w], root_v);
          atomicExch(&tree_roots_dview[x], root_v);

          __threadfence();

          enode_queue_dview.AppendENode1(x);
        }
      }
    });

    CUDA_CHECK(cudaDeviceSynchronize());

    auto enode1_end = enode_queue_.ENnode1End();
    LOG(INFO) << "[Expand] Enqueue " << enode1_end - enode1_begin << " enodes";

    auto end_time = getNanoSecond();
    this->time_expand += end_time - start_time;
    LOG(INFO) << "[Expand] takes " << (end_time - start_time) / 1e6 << " ms";
  }

  void XBlossomGpuEngine8::TransformOddNodesInBlossom() {
    auto start_time = getNanoSecond();

    const size_t total_even_nodes = enode_queue_.Size();
    if (total_even_nodes == 0) {
      return;
    }

    const size_t nnodes = this->nnodes_;
    auto graph_dview = this->device_graph_.DeviceView();
    auto matching_dview = this->dev_matching_.DeviceView();
    auto path_table_dview = this->path_table_.DeviceView();

    auto is_even_dview = this->is_even_.DeviceView();
    auto tree_roots_dview = this->tree_roots_.DeviceView();
    auto enode_queue_dview = this->enode_queue_.DeviceView();
    auto blossom_to_base_dview = this->blossom_to_base_.DeviceView();

    auto atomic_locks_odd_nodes_dview = this->atomic_locks_odd_nodes_.DeviceView();

    index_t enode_base_offset = this->enode_queue_.Begin();

    // Bug-fix: prepare to add enodes1 only after retrieving the base offset
    this->enode_queue_.PrepareForAppendingENode2();

    // Bug-fix: Reset BlossomBuffer before reconstruction of trees
    this->path_table_.ResetBlossomBuffer();

    auto start_presum = getNanoSecond();
    // Presum Begins
    auto col_indices_sizes_dview = this->col_indices_sizes_.DeviceView();
    auto col_indices_presum_dview = this->col_indices_presum_.DeviceView();

    CUDA_CHECK(cudaDeviceSynchronize());

    this->ExecuteNTasklet(total_even_nodes, [=] __device__ (index_t idx) mutable {
      index_t v = enode_queue_dview[enode_base_offset + idx];
      col_indices_sizes_dview[idx] = graph_dview.row_offsets[v + 1] - graph_dview.row_offsets[v];
    });

    // Exclusive Scan
    thrust::exclusive_scan(this->col_indices_sizes_.begin(),
                           this->col_indices_sizes_.begin() + total_even_nodes + 1,
                           this->col_indices_presum_.begin());

    size_t total_num_pairs = col_indices_presum_[total_even_nodes];

    auto end_presum = getNanoSecond();
    LOG(INFO) << "[Blossom] Presum Time is " << (end_presum - start_presum) / 1e6 << " ms";

    LOG(INFO) << "[Blossom] Total nodes " << total_even_nodes;
    LOG(INFO) << "[Blossom] Total edges " << total_num_pairs;

    auto enode2_begin = enode_queue_.ENnode2Begin();

    CUDA_CHECK(cudaDeviceSynchronize());

    // std::cout << "Blossom() begins" << std::endl;

    this->ExecuteNTasklet(total_num_pairs, [=] __device__ (index_t tid) mutable {
      index_t v_idx = FindRightmostLTEQ(col_indices_presum_dview, total_even_nodes, tid);
      index_t v = enode_queue_dview[enode_base_offset + v_idx];
      int delta = tid - col_indices_presum_dview[v_idx];

      index_t w_offset = graph_dview.row_offsets[v] + delta;
      index_t w = graph_dview.col_indices[w_offset];

      index_t root_v = tree_roots_dview[v];
      index_t root_w = tree_roots_dview[w];

      if (is_even_dview[w] && root_v == root_w && matching_dview[v] != w && root_w != nnodes) {
        index_t blossom_offset;
        size_t nnodes_in_blossom;

        index_t v_idx_in_blossom;
        index_t w_idx_in_blossom;

        path_table_dview.FindBlossomInBlossomBuffer(v, w, blossom_offset, nnodes_in_blossom, v_idx_in_blossom,
                                                    w_idx_in_blossom);
        __threadfence();
        // index_t blossom_base = path_table_dview.GetNodeFromBlossomInBlossomBuffer(blossom_offset, 0);

        // Bug: Remove Detection of Duplication fix bug of Amazon
        // if (path_table_dview.CheckDuplicationInBlossomBuffer(blossom_offset, nnodes_in_blossom)) {
        //   // printf("Duplication Detected!\n");
        //   return;
        // }

        // ************************************************************************************
        // rightwards from blossom buffer
        for (index_t k = 1; k < v_idx_in_blossom; k += 2) {
          index_t cur = path_table_dview.GetNodeFromBlossomInBlossomBuffer(blossom_offset, k);
          // if (blossom_to_base_dview[cur] == nnodes) {
          //   blossom_to_base_dview[cur] = blossom_base;
          //   // atomicExch(&blossom_to_base_dview[cur], blossom_base);
          // }

          // printf("[TRANSFORM] Node %d tries to be an even node by edge (v: %d, w: %d).\n", cur, v, w);
          if (!is_even_dview[cur] && path_table_dview.IsPathEmpty(cur)) {
            if (atomicCAS(&atomic_locks_odd_nodes_dview[cur], DFLAG_FALSE, DFLAG_TRUE) == DFLAG_FALSE) {
              // printf("[TRANSFORM] Node %d becomes an even node by edge (v: %d, w: %d).\n", cur, v, w);

              if (path_table_dview.CheckPathDuplicationInBlossomBufferRightwards(
                blossom_offset + k, (nnodes_in_blossom - 1) - k + 1)) {
                // printf("Path Duplication Deteced when going rightwards\n");

                // if (nnodes_in_blossom == 4) {
                //   printf(
                //     "Path Duplication Deteced when going rightwards\n,"
                //     "with v : %d, w: %d, cur: %d, cur_idx: %d, blossom_len:%lu\n,"
                //     "blossoms: %d, %d, %d, %d\n",
                //     v, w, cur, k, nnodes_in_blossom,
                //     path_table_dview.GetNodeFromBlossomInBlossomBuffer(blossom_offset, 0), path_table_dview.GetNodeFromBlossomInBlossomBuffer(blossom_offset, 1), path_table_dview.GetNodeFromBlossomInBlossomBuffer(blossom_offset, 2), path_table_dview.GetNodeFromBlossomInBlossomBuffer(blossom_offset, 3));
                // }
                // atomicExch(&atomic_locks_odd_nodes_dview[cur], DFLAG_FALSE);
                continue;
              }

              path_table_dview.ExpandNodesFromBlossomRightwards(cur, blossom_offset, nnodes_in_blossom, k + 1);
              __threadfence();
              enode_queue_dview.AppendENode2(cur);
              __threadfence();
              // is_even_dview[cur] = 1;
              atomicExch(&is_even_dview[cur], 1);
            }
          }
        }

        // ************************************************************************************
        // leftwards from blossom buffer
        // for (index_t k = nnodes_in_blossom - 1; k > w_idx_in_blossom; k -= 2) {
        for (index_t k = nnodes_in_blossom - 2; k > w_idx_in_blossom; k -= 2) {
          index_t cur = path_table_dview.GetNodeFromBlossomInBlossomBuffer(blossom_offset, k);
          // if (blossom_to_base_dview[cur] == nnodes) {
          //   blossom_to_base_dview[cur] = blossom_base;
          //   // atomicExch(&blossom_to_base_dview[cur], blossom_base);
          // }

          // printf("[TRANSFORM] Node %d tries to be an even node by edge (v: %d, w: %d).\n", cur, v, w);
          if (!is_even_dview[cur] && path_table_dview.IsPathEmpty(cur)) {
            if (atomicCAS(&atomic_locks_odd_nodes_dview[cur], DFLAG_FALSE, DFLAG_TRUE) == DFLAG_FALSE) {

              if (path_table_dview.CheckPathDuplicationInBlossomBufferLeftwards(blossom_offset + k, k - 0 + 1)) {
                // printf("Path Duplication Deteced when going leftwards\n");
                // atomicExch(&atomic_locks_odd_nodes_dview[cur], DFLAG_FALSE);
                continue;
              }

              // printf("[TRANSFORM] Node %d becomes an even node by edge (v: %d, w: %d).\n", cur, v, w);
              path_table_dview.ExpandNodesFromBlossomLeftwards(cur, blossom_offset, k - 1);
              __threadfence();
              enode_queue_dview.AppendENode2(cur);
              __threadfence();
              // is_even_dview[cur] = 1;
              atomicExch(&is_even_dview[cur], 1);
            }
          }
        }
      }
    });

    // std::cout << "Blossom() ends" << std::endl;

    CUDA_CHECK(cudaDeviceSynchronize());

    auto enode2_end = enode_queue_.End();
    LOG(INFO) << "[Transform] Enqueue " << enode2_end - enode2_begin << " enodes" << " with end <" << enode2_end << ">";

    auto end_time = getNanoSecond(); // Stop Profiling
    this->time_blossom += end_time - start_time;
    LOG(INFO) << "[Blossom] takes " << (end_time - start_time) / 1e6 << " ms";
  }
}
