#include "xbsm_gpu/xblossom_gpu_engine_7.h"
#include <glog/logging.h>
#include "utils/cuda_algo.h"
#include "common/stopwatch.h"

namespace zblossom {
  XBlossomGpuEngine7::XBlossomGpuEngine7(const HGraph &g)
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
  }

  XBlossomGpuEngine7::XBlossomGpuEngine7(const HGraph &g, size_t path_table_buffer_ratio)
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
  }


  void XBlossomGpuEngine7::FindAndFlipAugmentingPath() {
    ms_t time_total_it{0};
    ms_t time_augmenting_path_it{0};
    ms_t time_expand_it{0};
    ms_t time_blossom_it{0};

    this->InitAlternatingForest();

    // Continue while even nodes remain and no augmenting path has been found
    // while (!this->IsExhausted()
    //        && !this->FindAndFlipAugmentingPathInAlternatingForest()) {
    //   this->ExpandAlternatingForest();
    //   this->TransformOddNodesInBlossom();
    // }

    Stopwatch sw;
    bool found = false;
    while (!found && this->enode_queue_.HasFrontier()) {
      if (this->FindAndFlipAugmentingPathInAlternatingForest()) {
        found = true;
        break;
      }

      sw.Start();
      this->ExpandAlternatingForest();
      sw.Stop();
      time_expand_it += sw.GetMs();

      // Continue to Expand till exhausted
      while (!found && this->enode_queue_.HasFrontier()) {
        if (this->FindAndFlipAugmentingPathInAlternatingForest()) {
          found = true;
          break;
        }

        sw.Start();
        this->ExpandAlternatingForest();
        sw.Stop();
        time_expand_it += sw.GetMs();
      }

      if (!found) {
        this->TransformOddNodesInBlossom();
      }
    }

    LOG(INFO) << "{Iteration} Total Expanding time is " << time_expand_it << " ms";
  }

  void XBlossomGpuEngine7::InitAlternatingForest() {
    // ---- 1. Reset Host-side Structures ----
    LOG(INFO) << "---- Reset Everything ---- ";
    path_table_.ResetPathTable();

    // Capture nnodes_ explicitly as a scalar before the lambda
    // this->enode_queue_.Clear();
    this->enode_queue_.Clear();

    // this->blossom_to_base_.Fill(this->nnodes_);
    this->atomic_locks_tree_.Fill(DFLAG_FALSE);
    this->atomic_locks_match_.Fill(DFLAG_FALSE);
    this->atomic_locks_odd_nodes_.Fill(DFLAG_FALSE);

    this->dev_found_.SetH2D(DFLAG_FALSE);
    // this->found_ = DFLAG_FALSE;

    // Make sure the fills are finished before we use the table again

    index_t nnodes = this->nnodes_;
    auto input_matching_dview = this->dev_matching_.DeviceView();
    auto is_even_dview = this->is_even_.DeviceView();
    auto tree_roots_dview = this->tree_roots_.DeviceView();
    auto enode_queue_dview = this->enode_queue_.DeviceView();

    // for logging
    // auto enode1_begin = this->enode_queue_.ExpandBegin();
    // this->enode_queue_.PrepareExpand();

    // Find all exposed nodes
    CUDA_CHECK(cudaDeviceSynchronize());


    this->ExecuteNTasklet(nnodes_, [=] __device__ (index_t node) mutable {
      if (input_matching_dview[node] == nnodes) {
        // if node idx is exposed,
        // then it is an even node, root of an alternating tree, and it should be appended to the queue of even nodes
        is_even_dview[node] = 1;
        // printf("Reset: Set Node %d as even\n", idx);
        tree_roots_dview[node] = node;
        __threadfence();
        // enode_queue_dview.AppendENode1(node);
        enode_queue_dview.AppendENode(node);
      } else {
        is_even_dview[node] = 0;
        tree_roots_dview[node] = nnodes;
        __threadfence();
      }
    });

    // auto enode1_end = enode_queue_.ExpandEnd();
    // LOG(INFO) << "[Init] Enqueue " << enode1_end - enode1_begin << " enodes";
    LOG(INFO) << "[Init] Enqueue " << enode_queue_.ExpandSize() << " enodes";

    // this->enode_queue_.PrepareForAppendingENode2();
    this->enode_queue_.FinalizeExpand();

    CUDA_CHECK(cudaDeviceSynchronize());
  }

  bool XBlossomGpuEngine7::FindAndFlipAugmentingPathInAlternatingForest() {
    auto start_time = getNanoSecond();

    // const size_t total_even_nodes = enode_queue_.Size();
    const size_t total_even_nodes = enode_queue_.AugPathSize();
    if (total_even_nodes == 0) {
      return false;
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

    // index_t enode_base_offset = this->enode_queue_.Begin();
    index_t enode_base_offset = this->enode_queue_.AugPathBegin();

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
      }
    });

    CUDA_CHECK(cudaDeviceSynchronize());
    auto end_time = getNanoSecond();

    // std::cout << "AugPath() ends" << std::endl;

    this->time_augmenting_path += end_time - start_time;

    this->found_ = this->dev_found_.GetD2H();

    return this->found_;
  }


  void XBlossomGpuEngine7::ExpandAlternatingForest() {
    auto start_time = getNanoSecond();

    // const size_t total_even_nodes = enode_queue_.Size();
    const size_t total_even_nodes = enode_queue_.ExpandSize();
    LOG(INFO) << "[Expand] Processes " << enode_queue_.ExpandSize() << " enodes";
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

    // index_t enode_base_offset = this->enode_queue_.Begin();
    index_t enode_base_offset = this->enode_queue_.ExpandBegin();

    // Bug-fix: prepare to add enodes1 only after retrieving the base offset
    // this->enode_queue_.PrepareForAppendingENode1();
    this->enode_queue_.PrepareExpand();

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
    // auto enode1_begin = enode_queue_.ENnode1Begin();

    CUDA_CHECK(cudaDeviceSynchronize());

    this->ExecuteNTasklet(total_num_pairs, [=] __device__ (index_t tid) mutable {
      index_t v_idx = FindRightmostLTEQ(col_indices_presum_dview, total_even_nodes, tid);
      index_t v = enode_queue_dview[enode_base_offset + v_idx];
      int delta = tid - col_indices_presum_dview[v_idx];

      index_t w_offset = graph_dview.row_offsets[v] + delta;
      index_t w = graph_dview.col_indices[w_offset];

      index_t root_v = tree_roots_dview[v];
      index_t root_w = tree_roots_dview[w];

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

          // enode_queue_dview.AppendENode1(x);
          enode_queue_dview.AppendENode(x);
        }
      }
    });

    CUDA_CHECK(cudaDeviceSynchronize());

    this->enode_queue_.FinalizeExpand();

    // auto enode1_end = enode_queue_.ENnode1End();
    // LOG(INFO) << "[Expand] Enqueue " << enode1_end - enode1_begin << " enodes";
    LOG(INFO) << "[Expand] Enqueue " << enode_queue_.ExpandSize() << " enodes";

    auto end_time = getNanoSecond();
    this->time_expand += end_time - start_time;
    LOG(INFO) << "[Expand] takes " << (end_time - start_time) / 1e6 << " ms";
  }

  void XBlossomGpuEngine7::TransformOddNodesInBlossom() {
    auto start_time = getNanoSecond();

    // const size_t total_even_nodes = enode_queue_.Size();
    const size_t total_even_nodes = enode_queue_.BlossomSize();
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

    // index_t enode_base_offset = this->enode_queue_.Begin();
    index_t enode_base_offset = this->enode_queue_.BlossomBegin();

    // Bug-fix: prepare to add enodes1 only after retrieving the base offset
    // this->enode_queue_.PrepareForAppendingENode2();
    this->enode_queue_.PrepareBlossom();

    // Bug-fix: Reset BlossomBuffer before reconstruction of trees
    this->path_table_.ResetBlossomBuffer();

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

    LOG(INFO) << "[Blossom] Total nodes " << total_even_nodes;
    LOG(INFO) << "[Blossom] Total edges " << total_num_pairs;

    // auto enode2_begin = enode_queue_.ENnode2Begin();

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
                continue;
              }


              path_table_dview.ExpandNodesFromBlossomRightwards(cur, blossom_offset, nnodes_in_blossom, k + 1);
              __threadfence();
              // enode_queue_dview.AppendENode2(cur);
              enode_queue_dview.AppendENode(cur);
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
                continue;
              }

              // printf("[TRANSFORM] Node %d becomes an even node by edge (v: %d, w: %d).\n", cur, v, w);
              path_table_dview.ExpandNodesFromBlossomLeftwards(cur, blossom_offset, k - 1);
              __threadfence();
              // enode_queue_dview.AppendENode2(cur);
              enode_queue_dview.AppendENode(cur);
              __threadfence();
              // is_even_dview[cur] = 1;
              atomicExch(&is_even_dview[cur], 1);
            }
          }
        }
      }
    });

    // std::cout << "Blossom() ends" << std::endl;

    this->enode_queue_.FinalizeBlossom();

    CUDA_CHECK(cudaDeviceSynchronize());

    // auto enode2_end = enode_queue_.End();
    // LOG(INFO) << "[Transform] Enqueue " << enode2_end - enode2_begin << " enodes" << " with end <" << enode2_end << ">";
    LOG(INFO) << "[Transform] Enqueue " << enode_queue_.ExpandSize() << " enodes";

    auto end_time = getNanoSecond(); // Stop Profiling
    this->time_blossom += end_time - start_time;
    LOG(INFO) << "[Blossom] takes " << (end_time - start_time) / 1e6 << " ms";
  }
}
