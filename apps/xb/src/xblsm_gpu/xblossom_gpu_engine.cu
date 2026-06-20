#include "xbsm_gpu/xblossom_gpu_engine.h"
#include <glog/logging.h>

namespace zblossom {
  XBlossomGpuEngine::XBlossomGpuEngine(const HGraph &g)
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
      enode_queue_(nnodes_) {
  }

  XBlossomGpuEngine::XBlossomGpuEngine(const HGraph &g, size_t path_table_buffer_ratio)
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
      enode_queue_(nnodes_) {
  }


  void XBlossomGpuEngine::FindAndFlipAugmentingPath() {
    this->InitAlternatingForest();

    // Continue while even nodes remain and no augmenting path has been found
    while (!this->IsExhausted()
           && !this->FindAndFlipAugmentingPathInAlternatingForest()) {
      this->ExpandAlternatingForest();
      this->TransformOddNodesInBlossom();
    }
  }

  void XBlossomGpuEngine::InitAlternatingForest() {
    // ---- 1. Reset Host-side Structures ----
    path_table_.ResetPathTable();

    // Capture nnodes_ explicitly as a scalar before the lambda
    this->enode_queue_.Clear();

    this->blossom_to_base_.Fill(this->nnodes_);
    this->atomic_locks_tree_.Fill(DFLAG_FALSE);
    this->atomic_locks_match_.Fill(DFLAG_FALSE);
    this->atomic_locks_odd_nodes_.Fill(DFLAG_FALSE);

    this->dev_found_.SetH2D(DFLAG_FALSE);

    // Make sure the fills are finished before we use the table again

    index_t nnodes = this->nnodes_;
    auto input_matching_dview = this->dev_matching_.DeviceView();
    auto is_even_dview = this->is_even_.DeviceView();
    auto tree_roots_dview = this->tree_roots_.DeviceView();
    auto enode_queue_dview = this->enode_queue_.DeviceView();

    // auto blossom_to_base_dview = this->blossom_to_base_.DeviceView();
    // auto atomic_locks_tree_dview = this->atomic_locks_tree_.DeviceView();
    // auto atomic_locks_match_dview = this->atomic_locks_match_.DeviceView();
    // auto atomic_locks_odd_nodes_dview = this->atomic_locks_odd_nodes_.DeviceView();
    // auto found_dview = this->dev_found_.DeviceView();

    // Find all exposed nodes
    CUDA_CHECK(cudaDeviceSynchronize());
    this->ExecuteNTasklet(nnodes_, [=] __device__ (index_t idx) mutable {
      if (input_matching_dview[idx] == nnodes) {
        // if node idx is exposed,
        // then it is an even node, root of an alternating tree, and it should be appended to the queue of even nodes
        is_even_dview[idx] = 1;
        // printf("Reset: Set Node %d as even\n", idx);
        tree_roots_dview[idx] = idx;
        enode_queue_dview.AppendENode1(idx);
      } else {
        is_even_dview[idx] = 0;
        tree_roots_dview[idx] = nnodes;
      }
    });
    this->enode_queue_.PrepareForAppendingENode2();

    CUDA_CHECK(cudaDeviceSynchronize());
  }

  bool XBlossomGpuEngine::FindAndFlipAugmentingPathInAlternatingForest() {
    auto start_time = getNanoSecond();

    const size_t total_even_nodes = enode_queue_.Size();
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

    index_t enode_base_offset = this->enode_queue_.Begin();
    this->ExecuteNTasklet(total_even_nodes, [=] __device__ (index_t idx) mutable {
      index_t v = enode_queue_dview[enode_base_offset + idx];

      index_t start_offset = graph_dview.row_offsets[v];
      index_t end_offset = graph_dview.row_offsets[v + 1];

      for (index_t w_offset = start_offset; w_offset < end_offset; ++w_offset) {
        index_t w = graph_dview.col_indices[w_offset];

        index_t root_v = tree_roots_dview[v];
        index_t root_w = tree_roots_dview[w];

        if (root_v != nnodes && root_w != nnodes && is_even_dview[w] && root_v != root_w) {
          index_t first_lock = MIN(root_v, root_w);
          index_t second_lock = MAX(root_v, root_w);

          // Lock the smaller index first
          if (atomicCAS(&atomic_locks_tree_dview[first_lock], DFLAG_FALSE, DFLAG_TRUE) != DFLAG_FALSE) {
            if (first_lock == root_v) {
              // break;
              continue;
            } else {
              // first_lock == root_w
              continue;
            }
          }

          // Lock the larger index second
          if (atomicCAS(&atomic_locks_tree_dview[second_lock], DFLAG_FALSE, DFLAG_TRUE) != DFLAG_FALSE) {
            atomicExch(&atomic_locks_tree_dview[first_lock], DFLAG_FALSE);
            // atomicCAS(&atomic_locks_tree_dview[second_lock], DFLAG_TRUE, DFLAG_FALSE);

            if (second_lock == root_v) {
              // break;
              continue;
            } else {
              // second_lock == root_w
              continue;
            }
          }

          path_table_dview.AddAugmentingPath(v, w, matching_dview);
          found_dview = DFLAG_TRUE;
        }
      }
    });

    auto end_time = getNanoSecond();
    this->time_augmenting_path += end_time - start_time;

    this->found_ = this->dev_found_.GetD2H();

    return this->found_;
  }

  void XBlossomGpuEngine::ExpandAlternatingForest() {
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

    CUDA_CHECK(cudaDeviceSynchronize());
    this->ExecuteNTasklet(total_even_nodes, [=] __device__ (index_t idx) mutable {
      index_t v = enode_queue_dview[enode_base_offset + idx];

      index_t start_offset = graph_dview.row_offsets[v];
      index_t end_offset = graph_dview.row_offsets[v + 1];

      for (index_t w_offset = start_offset; w_offset < end_offset; ++w_offset) {
        index_t w = graph_dview.col_indices[w_offset];
        index_t root_v = tree_roots_dview[v];
        index_t root_w = tree_roots_dview[w];

        index_t x = matching_dview[w];
        if (root_w == nnodes) {
          index_t match_idx = MIN(w, x);
          if (atomicCAS(&atomic_locks_match_dview[match_idx], DFLAG_FALSE, DFLAG_TRUE) == DFLAG_FALSE) {
            path_table_dview.ExpandTwoNodes(v, w, x);
            __threadfence();

            // is_even_dview[w] = 0;
            // is_even_dview[x] = 1;
            // printf("Expand: Set Node %d as even\n", x);

            // tree_roots_dview[w] = root_v;
            // tree_roots_dview[x] = root_v;

            /****** atomicvisibility changes ***** */
            atomicExch(&tree_roots_dview[w], root_v);
            atomicExch(&tree_roots_dview[x], root_v);

            __threadfence();

            atomicExch(&is_even_dview[w], 0);
            atomicExch(&is_even_dview[x], 1);

            __threadfence();

            /* **************************************** */
            enode_queue_dview.AppendENode1(x);
          }
        }
      }
    });

    CUDA_CHECK(cudaDeviceSynchronize());

    auto end_time = getNanoSecond();
    this->time_expand += end_time - start_time;
    LOG(INFO) << "[Expand] takes " << (end_time - start_time) / 1e6 << " ms";
  }

  void XBlossomGpuEngine::TransformOddNodesInBlossom() {
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

    CUDA_CHECK(cudaDeviceSynchronize());
    this->ExecuteNTasklet(total_even_nodes, [=] __device__ (index_t idx) mutable {
      index_t v = enode_queue_dview[enode_base_offset + idx];

      index_t start_offset = graph_dview.row_offsets[v];
      index_t end_offset = graph_dview.row_offsets[v + 1];

      for (index_t w_offset = start_offset; w_offset < end_offset; ++w_offset) {
        index_t w = graph_dview.col_indices[w_offset];
        index_t root_v = tree_roots_dview[v];
        index_t root_w = tree_roots_dview[w];


        if (is_even_dview[w] && root_v == root_w &&
            (blossom_to_base_dview[v] == nnodes || blossom_to_base_dview[w] != blossom_to_base_dview[v])) {
          index_t blossom_offset;
          size_t nnodes_in_blossom;

          index_t v_idx_in_blossom;
          index_t w_idx_in_blossom;


          path_table_dview.FindBlossomInBlossomBuffer(v, w, blossom_offset, nnodes_in_blossom, v_idx_in_blossom,
                                                      w_idx_in_blossom);
          __threadfence();
          // index_t blossom_base = path_table_dview.GetNodeFromBlossomInBlossomBuffer(blossom_offset, 0);

          if (path_table_dview.CheckDuplicationInBlossomBuffer(blossom_offset, nnodes_in_blossom)) {
            continue;
          }


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
      }
    });
    CUDA_CHECK(cudaDeviceSynchronize());

    auto end_time = getNanoSecond(); // Stop Profiling
    this->time_blossom += end_time - start_time;
    LOG(INFO) << "[Blossom] takes " << (end_time - start_time) / 1e6 << " ms";
  }
}
