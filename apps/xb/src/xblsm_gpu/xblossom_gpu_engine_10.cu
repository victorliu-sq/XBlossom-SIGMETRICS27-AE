#include <glog/logging.h>
#include <thrust/sort.h>
#include "xbsm_gpu/kernels.h"
#include "utils/cuda_algo.h"
#include "xbsm_gpu/xblossom_gpu_engine_10.h"

namespace zblossom {
  XBlossomGpuEngine10::XBlossomGpuEngine10(const HGraph &g)
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
      // For ParEdge
      col_indices_presum_(nnodes_ + 1),
      col_indices_sizes_(nnodes_ + 1),
      // For ParAugPath
      start_nodes_(nnodes_ + 1),
      num_flips_(nnodes_ + 1),
      num_flips_psum_(nnodes_ + 1),
      // For ParBlossom
      blossom_offset_list_(PATH_TABLE_ODD_NODE_RATIO * nnodes_ + 1),
      num_nodes_in_blossom_list_(PATH_TABLE_ODD_NODE_RATIO * nnodes_ + 1),
      // For double sides
      num_odd_nodes_vside_in_blossom_list_(PATH_TABLE_ODD_NODE_RATIO * nnodes_ + 1),
      num_odd_nodes_in_blossom_list_(PATH_TABLE_ODD_NODE_RATIO * nnodes_ + 1),
      num_odd_nodes_in_blossom_psum_(PATH_TABLE_ODD_NODE_RATIO * nnodes_ + 1) {
    this->InitCubScanTempStorage(num_odd_nodes_in_blossom_psum_.size());
  }
  // 50 for Hyperlink

  // 30 for Google
#define ODD_NODE_RATIO 30

  // 10 for other datasets
  // #define ODD_NODE_RATIO 10

  XBlossomGpuEngine10::XBlossomGpuEngine10(const HGraph &g, size_t path_table_buffer_ratio)
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
      // For ParEdge
      col_indices_presum_(nnodes_ + 1),
      col_indices_sizes_(nnodes_ + 1),
      // For ParAugPath
      start_nodes_(nnodes_ + 1),
      num_flips_(nnodes_ + 1),
      num_flips_psum_(nnodes_ + 1),
      // For ParBlossom
      blossom_offset_list_(ODD_NODE_RATIO * nnodes_ + 1),
      num_nodes_in_blossom_list_(ODD_NODE_RATIO * nnodes_ + 1),
      num_odd_nodes_vside_in_blossom_list_(ODD_NODE_RATIO * nnodes_ + 1),
      num_odd_nodes_in_blossom_list_(ODD_NODE_RATIO * nnodes_ + 1),
      num_odd_nodes_in_blossom_psum_(ODD_NODE_RATIO * nnodes_ + 1) {
    this->InitCubScanTempStorage(num_odd_nodes_in_blossom_psum_.size());
  }

  void XBlossomGpuEngine10::FindAndFlipAugmentingPath() {
    this->InitAlternatingForest();

    // Continue while even nodes remain and no augmenting path has been found
    while (!this->IsExhausted()
           && !this->FindAndFlipAugmentingPathInAlternatingForest()) {
      this->ExpandAlternatingForest();
      this->TransformOddNodesInBlossom();
    }
  }

  void XBlossomGpuEngine10::InitAlternatingForest() {
    // ---- 1. Reset Host-side Structures ----
    LOG(INFO) << "---- Lazy Reset ---- ";
    this->InvalidateEdgePrefixCache();
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

    this->dev_reused_tree_nodes_.SetH2D(0);
    this->dev_reset_tree_nodes_.SetH2D(0);
    auto reused_tree_nodes_dview = this->dev_reused_tree_nodes_.DeviceView();
    auto reset_tree_nodes_dview = this->dev_reset_tree_nodes_.DeviceView();

    this->enode_queue_.Clear();
    enode_queue_.PrepareForAppendingENode1();
    // for logging
    auto enode1_begin = enode_queue_.ENnode1Begin();
    auto path_table_dview = this->path_table_.DeviceView();

    this->ExecuteNTaskletsMax(nnodes_, [=] __device__ (index_t x) mutable {

      // With Prev
      if (input_matching_dview[x] == nnodes) {
        // exposed nodes
        is_even_dview[x] = 1;
        tree_roots_dview[x] = x;
        enode_queue_dview.AppendENode1(x);
        path_table_dview.ResetNode(x);
        atomicAdd(&reset_tree_nodes_dview, 1ULL);
      } else {
        // matched
        index_t root = tree_roots_dview[x];
        // If matched,
        // and either not in a tree yet or in a tree whose root is matched now
        if (root == nnodes || input_matching_dview[root] != nnodes) {
          is_even_dview[x] = 0;
          tree_roots_dview[x] = nnodes;
          // Reset everything
          path_table_dview.ResetNode(x);
          atomicAdd(&reset_tree_nodes_dview, 1ULL);
        } else {
          atomicAdd(&reused_tree_nodes_dview, 1ULL);
        }
      }
    });

    this->num_reused_tree_nodes_ += this->dev_reused_tree_nodes_.GetD2H();
    this->num_reset_tree_nodes_ += this->dev_reset_tree_nodes_.GetD2H();

    auto enode1_end = enode_queue_.ENnode1End();
    LOG(INFO) << "[Init] Enqueue " << enode1_end - enode1_begin << " enodes";

    this->enode_queue_.PrepareForAppendingENode2();

    this->ExecuteNTaskletsMax(nnodes_, [=] __device__ (index_t x) mutable {
      // With Prev
      if (input_matching_dview[x] != nnodes) {
        // matched
        index_t root = tree_roots_dview[x];
        if (root != nnodes && input_matching_dview[root] == nnodes) {
          // If matched,
          // and already in a tree and the root is still unmatched.
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

    // if (first_init_ == DFLAG_TRUE) {
    //   int total_even_nodes = enode_queue_.Size();
    //   thrust::sort(thrust::device, enode_queue_.BeginIterator(), enode_queue_.BeginIterator() + total_even_nodes);
    //   first_init_ = DFLAG_FALSE;
    // }

    // Reset reset bits
    // this->is_root_and_reset_.Fill(DFLAG_FALSE);
  }

  bool XBlossomGpuEngine10::FindAndFlipAugmentingPathInAlternatingForest() {
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

    auto col_indices_presum_dview = this->col_indices_presum_.DeviceView();

    // std::cout << "Presum:" << std::endl;
    // for (int i = 0; i < total_even_nodes + 1; ++i) {
    //   std::cout << "i: " << this->col_indices_presum_[i] << std::endl;
    // }

    size_t total_num_pairs = this->PrepareEdgePrefix(total_even_nodes,
                                                     enode_base_offset,
                                                     graph_dview,
                                                     enode_queue_dview);
    this->num_edges_processed_ += total_num_pairs;
    this->num_aug_path_edges_processed_ += total_num_pairs;
    // std::cout << "Total number of pairs : " << total_num_pairs << std::endl;

    // std::cout << "AugPath() begins" << std::endl;

    this->ExecuteNTaskletsMax(total_num_pairs, [=] __device__ (index_t tid) mutable {
      const int* col_indices_presum_data = &col_indices_presum_dview[0];
      const int pos = cub::UpperBound(col_indices_presum_data, static_cast<int>(total_even_nodes + 1), tid);
      index_t v_idx = static_cast<index_t>(pos - 1);
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

        if (atomicExch(&atomic_locks_tree_dview[first_lock], DFLAG_TRUE) != DFLAG_FALSE) {
          return;
        }
        if (atomicExch(&atomic_locks_tree_dview[second_lock], DFLAG_TRUE) != DFLAG_FALSE) {
          // atomicExch(&atomic_locks_tree_dview[first_lock], DFLAG_FALSE);
          atomic_locks_tree_dview[first_lock] = DFLAG_FALSE;
          return;
        }

        path_table_dview.AddAugmentingPath(v, w, matching_dview);

        atomicExch(&found_dview, DFLAG_TRUE);
      }
    });

    this->found_ = this->dev_found_.GetD2H();
    auto end_time = getNanoSecond();

    // std::cout << "AugPath() ends" << std::endl;

    this->time_augmenting_path += end_time - start_time;

    return this->found_;
  }

  void XBlossomGpuEngine10::ExpandAlternatingForest() {
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
    auto col_indices_presum_dview = this->col_indices_presum_.DeviceView();

    auto start_preprocessing_time = getNanoSecond();

    size_t total_num_pairs = this->PrepareEdgePrefix(total_even_nodes,
                                                     enode_base_offset,
                                                     graph_dview,
                                                     enode_queue_dview);
    this->num_edges_processed_ += total_num_pairs;
    this->num_expand_edges_processed_ += total_num_pairs;

    auto end_preprocessing_time = getNanoSecond();
    this->time_preprocessing += end_preprocessing_time - start_preprocessing_time;

    // For logging
    auto enode1_begin = enode_queue_.ENnode1Begin();

    this->ExecuteNTaskletsMax(total_num_pairs, [=] __device__ (index_t tid) mutable {
      const int* col_indices_presum_data = &col_indices_presum_dview[0];
      const int pos = cub::UpperBound(col_indices_presum_data, static_cast<int>(total_even_nodes + 1), tid);
      index_t v_idx = static_cast<index_t>(pos - 1);
      index_t v = enode_queue_dview[enode_base_offset + v_idx];
      int delta = tid - col_indices_presum_dview[v_idx];

      index_t w_offset = graph_dview.row_offsets[v] + delta;
      index_t w = graph_dview.col_indices[w_offset];

      index_t root_v = tree_roots_dview[v];
      index_t root_w = tree_roots_dview[w];

      if (root_w == nnodes) {
        index_t x = matching_dview[w];
        index_t match_idx = MIN(w, x);
        if (atomicExch(&atomic_locks_match_dview[match_idx], DFLAG_TRUE) == DFLAG_FALSE) {
          is_even_dview[w] = 0;
          is_even_dview[x] = 1;

          tree_roots_dview[w] = root_v;
          tree_roots_dview[x] = root_v;
          /* **************************************** */
          __threadfence();

          path_table_dview.ExpandTwoNodes(v, w, x);

          __threadfence();

          // enode_queue_dview.AppendENode1(x);
          enode_queue_dview.AppendENode1Warp(x);
        }
      }
      /* ------------  DEVICE–SIDE FENCE ------------- */
      __threadfence(); // visible to the whole GPU
    });

    this->InvalidateEdgePrefixCache();

    auto enode1_end = enode_queue_.ENnode1End();
    LOG(INFO) << "[Expand] Enqueue " << enode1_end - enode1_begin << " enodes";
    if (dev_found_.GetD2H()) {
      LOG(INFO) << "[Wasted]" << enode1_end - enode1_begin << " enodes";
    }

    auto end_time = getNanoSecond();
    this->time_expand += end_time - start_time;
  }


  void XBlossomGpuEngine10::TransformOddNodesInBlossom() {
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

    // Transform
    auto atomic_locks_odd_nodes_dview = this->atomic_locks_odd_nodes_.DeviceView();

    index_t enode_base_offset = this->enode_queue_.Begin();

    // Bug-fix: prepare to add enodes1 only after retrieving the base offset
    this->enode_queue_.PrepareForAppendingENode2();

    // Bug-fix: Reset BlossomBuffer before reconstruction of trees
    this->path_table_.ResetBlossomBuffer();

    // Presum Begins
    auto start_preprocessing_time = getNanoSecond();

    auto col_indices_presum_dview = this->col_indices_presum_.DeviceView();

    size_t total_num_pairs = this->PrepareEdgePrefix(total_even_nodes,
                                                     enode_base_offset,
                                                     graph_dview,
                                                     enode_queue_dview);
    this->num_edges_processed_ += total_num_pairs;
    this->num_blossom_edges_processed_ += total_num_pairs;

    auto end_preprocessing_time = getNanoSecond();
    this->time_preprocessing += end_preprocessing_time - start_preprocessing_time;

    LOG(INFO) << "[Blossom Meta] Total nodes " << total_even_nodes;
    LOG(INFO) << "[Blossom Meta] Total edges " << total_num_pairs;

    auto enode2_begin = enode_queue_.ENnode2Begin();

    // DValue<index_t> num_odd_nodes;
    // DValue<index_t> num_blossom;
    // num_odd_nodes.SetH2D(0);
    // num_blossom.SetH2D(0);
    // auto num_odd_nodes_dview = num_odd_nodes.DeviceView();
    // auto num_blossom_dview = num_blossom.DeviceView();

    // For ParBlossom
    blossom_offset_list_.Clear();
    auto blossom_offset_list_dview = this->blossom_offset_list_.DeviceView();
    auto num_nodes_in_blossom_list_dview = this->num_nodes_in_blossom_list_.DeviceView();
    auto num_odd_nodes_in_blossom_list_dview = this->num_odd_nodes_in_blossom_list_.DeviceView();
    auto num_odd_nodes_vside_in_blossom_list_dview = this->num_odd_nodes_vside_in_blossom_list_.DeviceView();

    auto find_begin = getNanoSecond();
    this->ExecuteNTaskletsMax(total_num_pairs, [=] __device__ (index_t tid) mutable {
      const int* col_indices_presum_data = &col_indices_presum_dview[0];
      const int pos = cub::UpperBound(col_indices_presum_data, static_cast<int>(total_even_nodes + 1), tid);
      index_t v_idx = static_cast<index_t>(pos - 1);
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

        // path_table_dview.FindBlossomInBlossomBuffer(v,
        //                                             w,
        //                                             blossom_offset,
        //                                             nnodes_in_blossom,
        //                                             v_idx_in_blossom,
        // w_idx_in_blossom);

        path_table_dview.FindAndAddBlossomImplicitByAnchorNodeInBlossomBuffer(
          v,
          w,
          blossom_offset,
          nnodes_in_blossom,
          v_idx_in_blossom);
        w_idx_in_blossom = v_idx_in_blossom + 1;


        // ((v_idx - 0 + 1) - 1) / 2
        // (1) compute # of nodes in vside
        // (2) exclude the bb
        // (3) divide by 2 to compute # of odd nodes
        size_t num_odd_nodes_vside_in_blossom = v_idx_in_blossom >> 1;
        size_t num_odd_nodes_in_blossom = (nnodes_in_blossom - 2) >> 1;

        if (num_odd_nodes_in_blossom == 0) {
          return;
        }

        index_t offset_par_blossom = blossom_offset_list_dview.Append(blossom_offset);
        num_nodes_in_blossom_list_dview[offset_par_blossom] = nnodes_in_blossom;
        num_odd_nodes_in_blossom_list_dview[offset_par_blossom] = num_odd_nodes_in_blossom;
        num_odd_nodes_vside_in_blossom_list_dview[offset_par_blossom] = num_odd_nodes_vside_in_blossom;
      }
    });

    auto find_end = getNanoSecond();
    LOG(INFO) << "[Blossom Meta] (Find) takes " << (find_end - find_begin) / 1e6 << " ms";

    // std::cout << "Num of blossom =" << num_blossom.GetD2H() << std::endl;
    // std::cout << "Num of transformed odd nodes =" << num_odd_nodes.GetD2H() << std::endl;

    // prefix sum
    size_t num_blossom = blossom_offset_list_.size();
    this->num_blossoms_ += num_blossom;
    this->ExclusiveScan(num_odd_nodes_in_blossom_list_.begin(),
                        num_odd_nodes_in_blossom_psum_.begin(),
                        num_blossom + 1);
    size_t total_num_transforms = num_odd_nodes_in_blossom_psum_[num_blossom];

    LOG(INFO) << "[Blossom Meta] Total Odd Nodes " << total_num_transforms;

    auto num_odd_nodes_in_blossom_psum_dview = this->num_odd_nodes_in_blossom_psum_.DeviceView();

    auto transform_begin = getNanoSecond();
    if (total_num_transforms > 0) {
      this->ExecuteNTaskletsMax(total_num_transforms, [=] __device__ (index_t tid) mutable {
        index_t offset_par_blossom_idx = FindRightmostLTEQ(num_odd_nodes_in_blossom_psum_dview,
                                                           num_blossom + 1,
                                                           tid);
        index_t blossom_offset = blossom_offset_list_dview[offset_par_blossom_idx];
        index_t nnodes_in_blossom = num_nodes_in_blossom_list_dview[offset_par_blossom_idx];
        index_t num_odd_nodes_vside_in_blossom = num_odd_nodes_vside_in_blossom_list_dview[offset_par_blossom_idx];

        // delta
        index_t delta = tid - num_odd_nodes_in_blossom_psum_dview[offset_par_blossom_idx];

        int is_vside = delta <= (num_odd_nodes_vside_in_blossom - 1);

        // index_t v_idx = num_odd_nodes_vside_in_blossom * 2;
        // index_t v = path_table_dview.GetNodeFromBlossomInBlossomBuffer(blossom_offset, v_idx);
        // index_t w = path_table_dview.GetNodeFromBlossomInBlossomBuffer(blossom_offset, v_idx + 1);

        // index_t odd_idx;
        // if (is_vside) {
        //   odd_idx = 1 + 2 * delta;
        // } else {
        //   odd_idx = 2 + 2 * delta;
        // }
        index_t odd_idx = 1 + 2 * delta + (1 - is_vside);

        // index_t odd_node = path_table_dview.GetNodeFromBlossom(blossom_offset, odd_idx);
        index_t odd_node = path_table_dview.GetNodeFromBlossomInBlossomBuffer(blossom_offset, odd_idx);

        if (!is_even_dview[odd_node] && path_table_dview.IsPathEmpty(odd_node) &&
            atomicExch(&atomic_locks_odd_nodes_dview[odd_node], DFLAG_TRUE) == DFLAG_FALSE) {
          // Directional parameters
          int step = is_vside ? +1 : -1; // +1: rightwards, -1: leftwards
          index_t start_idx = odd_idx + step; // first element after/before odd node
          size_t path_len = is_vside
                              ? (nnodes_in_blossom - odd_idx - 1) // rightwards length
                              : (static_cast<size_t>(odd_idx)); // leftwards length

          // Unified duplication check
          if (path_table_dview.CheckPathDuplicationInBlossomBufferDirectional(
            blossom_offset, start_idx, path_len, step)) {
            return;
          }

          // Unified expansion
          path_table_dview.ExpandNodesFromBlossomDirectional(
            odd_node, blossom_offset, nnodes_in_blossom, start_idx, path_len, step);

          // is_even_dview[odd_node] = 1;
          atomicExch(&is_even_dview[odd_node], 1);

          // __threadfence();
          enode_queue_dview.AppendENode2(odd_node);
        }
      });

      auto transform_end = getNanoSecond();
      LOG(INFO) << "[Blossom Meta] (Transform) takes " << (transform_end - transform_begin) / 1e6 << " ms";
    }

    auto enode2_end = enode_queue_.End();
    LOG(INFO) << "[Transform] Enqueue " << enode2_end - enode2_begin << " enodes" << " with end <" << enode2_end << ">";
    this->InvalidateEdgePrefixCache();

    auto end_time = getNanoSecond(); // Stop Profiling
    this->time_blossom += end_time - start_time;
    LOG(INFO) << "[Blossom] takes " << (end_time - start_time) / 1e6 << " ms";
  }
}
