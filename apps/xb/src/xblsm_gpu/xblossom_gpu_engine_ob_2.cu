#include "xbsm_gpu/xblossom_gpu_engine_ob_2.h"

#include <glog/logging.h>
#include "path_table/path_table.h"
#include "utils/cuda_algo.h"

namespace zblossom {
  XBlossomGpuEngineOb2::XBlossomGpuEngineOb2(const HGraph &g)
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
      num_flips_psum_(nnodes_ + 1)
      // For ParBlossom
      // blossom_offset_list_(PATH_TABLE_ODD_NODE_RATIO * nnodes_ + 1),
      // num_nodes_in_blossom_list_(PATH_TABLE_ODD_NODE_RATIO * nnodes_ + 1),
      // num_odd_nodes_in_blossom_list_(PATH_TABLE_ODD_NODE_RATIO * nnodes_ + 1),
      // num_odd_nodes_in_blossom_psum_(PATH_TABLE_ODD_NODE_RATIO * nnodes_ + 1)
  {
  }

  XBlossomGpuEngineOb2::XBlossomGpuEngineOb2(const HGraph &g, size_t path_table_buffer_ratio)
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
      num_flips_psum_(nnodes_ + 1)
      // For ParBlossom
      // blossom_offset_list_(PATH_TABLE_ODD_NODE_RATIO * nnodes_ + 1),
      // num_nodes_in_blossom_list_(PATH_TABLE_ODD_NODE_RATIO * nnodes_ + 1),
      // num_odd_nodes_in_blossom_list_(PATH_TABLE_ODD_NODE_RATIO * nnodes_ + 1),
      // num_odd_nodes_in_blossom_psum_(PATH_TABLE_ODD_NODE_RATIO * nnodes_ + 1)
  {
  }

  void XBlossomGpuEngineOb2::FindAndFlipAugmentingPath() {
    this->InitAlternatingForest();

    // Continue while even nodes remain and no augmenting path has been found
    while (!this->IsExhausted()
           && !this->FindAndFlipAugmentingPathInAlternatingForest()) {
      this->ExpandAlternatingForest();
      this->TransformOddNodesInBlossom();
    }

    // while (!this->IsExhausted()
    //        && !this->AugPathAndExpand()) {
    //   this->TransformOddNodesInBlossom();
    // }

    /*
    while (!this->IsExhausted() && !this->AugPathAndExpandAndBlossom()) {
    }
    */

    // while (!this->IsExhausted()
    //        && !this->FindAndFlipAugmentingPathInAlternatingForest()) {
    //   this->ExpandAndBlossom();
    // }
  }

  void XBlossomGpuEngineOb2::InitAlternatingForest() {
    // ---- 1. Reset Host-side Structures ----
    // LOG(INFO) << "---- Reset Everything ---- ";
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

    // for logging
    auto enode1_begin = enode_queue_.ENnode1Begin();

    // Init enode Queue: Find all exposed nodes
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

    auto enode1_end = enode_queue_.ENnode1End();
    // LOG(INFO) << "[Init] Enqueue " << enode1_end - enode1_begin << " enodes";

    this->enode_queue_.PrepareForAppendingENode2();

    // Init Parallize AugPath
    start_nodes_.Clear();
    num_flips_.Fill(0);
    num_flips_psum_.Fill(0);

    CUDA_CHECK(cudaDeviceSynchronize());
  }

  bool XBlossomGpuEngineOb2::FindAndFlipAugmentingPathInAlternatingForest() {
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

    // For Par Edge
    auto start_preprocessing_time = getNanoSecond();

    auto col_indices_sizes_dview = this->col_indices_sizes_.DeviceView();
    auto col_indices_presum_dview = this->col_indices_presum_.DeviceView();

    this->ExecuteNTasklet(total_even_nodes, [=] __device__ (index_t idx) mutable {
      index_t v = enode_queue_dview[enode_base_offset + idx];
      col_indices_sizes_dview[idx] = graph_dview.row_offsets[v + 1] - graph_dview.row_offsets[v];
    });

    // Compute Presum
    thrust::exclusive_scan(this->col_indices_sizes_.begin(),
                           this->col_indices_sizes_.begin() + total_even_nodes + 1,
                           this->col_indices_presum_.begin());

    auto end_preprocessing_time = getNanoSecond();
    this->time_preprocessing += end_preprocessing_time - start_preprocessing_time;
    // std::cout << "Prefix Sum:" << std::endl;
    // for (int i = 0; i < total_even_nodes + 1; ++i) {
    //   std::cout << "i: " << this->col_indices_presum_[i] << std::endl;
    // }

    size_t total_num_pairs = col_indices_presum_[total_even_nodes];
    // std::cout << "Total number of pairs : " << total_num_pairs << std::endl;

    // For Par AugPath()
    auto start_nodes_dview = this->start_nodes_.DeviceView();
    auto num_flips_dview = this->num_flips_.DeviceView();

    this->ExecuteNTasklet(total_num_pairs, [=] __device__ (index_t tid) mutable {
      index_t v_idx = FindRightmostLTEQ(col_indices_presum_dview, total_even_nodes + 1, tid);
      index_t v = enode_queue_dview[enode_base_offset + v_idx];
      // printf("For tid: %d, v_idx is :%d, v is :%d\n", tid, v_idx, v);
      int delta = tid - col_indices_presum_dview[v_idx];

      index_t w_offset = graph_dview.row_offsets[v] + delta;
      index_t w = graph_dview.col_indices[w_offset];

      index_t root_v = tree_roots_dview[v];
      index_t root_w = tree_roots_dview[w];

      if (root_v != nnodes && root_w != nnodes && is_even_dview[w] && root_v != root_w) {
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

        // found_dview = DFLAG_TRUE;
        atomicExch(&found_dview, DFLAG_TRUE);

        // path_table_dview.AddAugmentingPath(v, w, matching_dview);

        // ParAugPath
        const index_t threshold = 1; // minimum value is 1
        index_t root_dist_v = path_table_dview.GetRootDistance(v);
        index_t root_dist_w = path_table_dview.GetRootDistance(w);

        // if (!path_table_dview.IsRoot(v)) {
        //   index_t offset_v = start_nodes_dview.Append(v);
        //   num_flips_dview[offset_v] = path_table_dview.GetRootDistance(v) / 2;
        // }
        //
        // if (!path_table_dview.IsRoot(w)) {
        //   index_t offset_w = start_nodes_dview.Append(w);
        //   num_flips_dview[offset_w] = path_table_dview.GetRootDistance(w) / 2;
        // }

        if (root_dist_v >= threshold) {
          index_t offset_v = start_nodes_dview.Append(v);
          num_flips_dview[offset_v] = path_table_dview.GetRootDistance(v) / 2;
        } else {
          path_table_dview.AddAugmentingPath(v, matching_dview);
        }

        if (root_dist_w >= threshold) {
          index_t offset_w = start_nodes_dview.Append(w);
          num_flips_dview[offset_w] = path_table_dview.GetRootDistance(w) / 2;
        } else {
          path_table_dview.AddAugmentingPath(w, matching_dview);
        }

        // flip v and w
        matching_dview[v] = w;
        matching_dview[w] = v;
      }
    });
    CUDA_CHECK(cudaDeviceSynchronize());

    // Compute prefix sum of root distance.
    size_t num_start_nodes = start_nodes_.size();

    thrust::exclusive_scan(num_flips_.begin(),
                           num_flips_.begin() + num_start_nodes + 1,
                           num_flips_psum_.begin());

    auto num_flips_psum_dview = num_flips_psum_.DeviceView();
    size_t total_num_flips = num_flips_psum_[num_start_nodes];

    if (total_num_flips > 0) {
      // HVector<index_t> host_start_nodes;
      // start_nodes_.GetFromDevice(host_start_nodes);
      // std::cout << "Start Nodes: ";
      // for (int i = 0; i < num_start_nodes; ++i) {
      //   std::cout << host_start_nodes[i] << " ";
      // }
      // std::cout << std::endl;

      // std::cout << "Total number of flips = " << total_num_flips << std::endl;

      this->ExecuteNTasklet(total_num_flips, [=] __device__ (index_t tid) mutable {
        index_t start_node_idx = FindRightmostLTEQ(num_flips_psum_dview,
                                                   num_start_nodes + 1,
                                                   tid);
        index_t start_node = start_nodes_dview[start_node_idx];

        // delta
        index_t flip_idx = tid - num_flips_psum_dview[start_node_idx];

        index_t read_length = 0;
        DPair<index_t, size_t> offset_length = path_table_dview.GetOffsetLength(start_node);
        index_t cur_node = start_node;
        while (read_length + offset_length.second <= 2 * flip_idx) {
          read_length += offset_length.second;
          cur_node = path_table_dview.GetAnchorNode(offset_length);
          offset_length = path_table_dview.GetOffsetLength(cur_node);
        }

        index_t n1_idx_in_path = 2 * flip_idx - read_length;
        index_t n2_idx_in_path = 2 * flip_idx + 1 - read_length;

        index_t n1 = path_table_dview.GetNode(offset_length.first, n1_idx_in_path);
        index_t n2 = path_table_dview.GetNode(offset_length.first, n2_idx_in_path);

        matching_dview[n1] = n2;
        matching_dview[n2] = n1;
      });
    }
    CUDA_CHECK(cudaDeviceSynchronize());


    auto end_time = getNanoSecond();
    this->time_augmenting_path += end_time - start_time;

    auto found = this->dev_found_.GetD2H();

    return found == DFLAG_TRUE;
  }

  void XBlossomGpuEngineOb2::ExpandAlternatingForest() {
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

    auto start_preprocessing_time = getNanoSecond();

    this->ExecuteNTasklet(total_even_nodes, [=] __device__ (index_t idx) mutable {
      index_t v = enode_queue_dview[enode_base_offset + idx];
      col_indices_sizes_dview[idx] = graph_dview.row_offsets[v + 1] - graph_dview.row_offsets[v];
    });

    // Exclusive Scan
    thrust::exclusive_scan(this->col_indices_sizes_.begin(),
                           this->col_indices_sizes_.begin() + total_even_nodes + 1,
                           this->col_indices_presum_.begin());

    size_t total_num_pairs = col_indices_presum_[total_even_nodes];

    auto end_preprocessing_time = getNanoSecond();
    this->time_preprocessing += end_preprocessing_time - start_preprocessing_time;

    // For logging
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

      if (root_w == nnodes) {
        index_t x = matching_dview[w];
        index_t match_idx = MIN(w, x);
        if (atomicCAS(&atomic_locks_match_dview[match_idx], DFLAG_FALSE, DFLAG_TRUE) == DFLAG_FALSE) {
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
          /* **************************************** */
          __threadfence();

          path_table_dview.ExpandTwoNodes(v, w, x);

          __threadfence();

          enode_queue_dview.AppendENode1(x);
          // enode_queue_dview.AppendENode1Warp(x);
        }
      }
    });

    CUDA_CHECK(cudaDeviceSynchronize());

    auto enode1_end = enode_queue_.ENnode1End();
    // LOG(INFO) << "[Expand] Enqueue " << enode1_end - enode1_begin << " enodes";
    // if (dev_found_.GetD2H()) {
    //   LOG(INFO) << "[Wasted]" << enode1_end - enode1_begin << " enodes";
    // }

    auto end_time = getNanoSecond();
    this->time_expand += end_time - start_time;
  }

  void XBlossomGpuEngineOb2::TransformOddNodesInBlossom() {
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

    auto col_indices_sizes_dview = this->col_indices_sizes_.DeviceView();
    auto col_indices_presum_dview = this->col_indices_presum_.DeviceView();

    this->ExecuteNTasklet(total_even_nodes, [=] __device__ (index_t idx) mutable {
      index_t v = enode_queue_dview[enode_base_offset + idx];
      col_indices_sizes_dview[idx] = graph_dview.row_offsets[v + 1] - graph_dview.row_offsets[v];
    });

    // Exclusive Scan
    thrust::exclusive_scan(this->col_indices_sizes_.begin(),
                           this->col_indices_sizes_.begin() + total_even_nodes + 1,
                           this->col_indices_presum_.begin());

    size_t total_num_pairs = col_indices_presum_[total_even_nodes];

    auto end_preprocessing_time = getNanoSecond();
    this->time_preprocessing += end_preprocessing_time - start_preprocessing_time;

    // LOG(INFO) << "[Blossom] Total nodes " << total_even_nodes;
    // LOG(INFO) << "[Blossom] Total edges " << total_num_pairs;

    auto enode2_begin = enode_queue_.ENnode2Begin();

    // DValue<index_t> num_odd_nodes;
    // DValue<index_t> num_blossom;
    // num_odd_nodes.SetH2D(0);
    // num_blossom.SetH2D(0);
    // auto num_odd_nodes_dview = num_odd_nodes.DeviceView();
    // auto num_blossom_dview = num_blossom.DeviceView();

    // For ParBlossom
    // blossom_offset_list_.Clear();
    // auto blossom_offset_list_dview = this->blossom_offset_list_.DeviceView();
    // auto num_nodes_in_blossom_list_dview = this->num_nodes_in_blossom_list_.DeviceView();
    // auto num_odd_nodes_in_blossom_list_dview = this->num_odd_nodes_in_blossom_list_.DeviceView();

    this->ExecuteNTasklet(total_num_pairs, [=] __device__ (index_t tid) mutable {
      index_t v_idx = FindRightmostLTEQ(col_indices_presum_dview, total_even_nodes, tid);
      index_t v = enode_queue_dview[enode_base_offset + v_idx];
      int delta = tid - col_indices_presum_dview[v_idx];

      index_t w_offset = graph_dview.row_offsets[v] + delta;
      index_t w = graph_dview.col_indices[w_offset];

      index_t root_v = tree_roots_dview[v];
      index_t root_w = tree_roots_dview[w];

      if (is_even_dview[w] && root_v == root_w && matching_dview[v] != w && root_w != nnodes) {
        // if (v == 8) {
        //   printf("Hello");
        // }
        index_t blossom_offset;
        size_t nnodes_in_blossom;

        index_t v_idx_in_blossom;
        index_t w_idx_in_blossom;

        path_table_dview.FindBlossom(v, w, blossom_offset, nnodes_in_blossom, v_idx_in_blossom);
        // path_table_dview.FindBlossomInBlossomBuffer(v, w, blossom_offset, nnodes_in_blossom, v_idx_in_blossom, w_idx_in_blossom);
        // path_table_dview.FindAndAddBlossomImplicit(v, w, blossom_offset, nnodes_in_blossom, v_idx_in_blossom);
        // path_table_dview.FindAndAddBlossomImplicitByAnchorNode(v, w, blossom_offset, nnodes_in_blossom,
        //                                                        v_idx_in_blossom);

        index_t blossom_base = path_table_dview.GetNodeFromBlossom(blossom_offset, 0);
        // index_t blossom_base = path_table_dview.GetNodeFromBlossomInBlossomBuffer(blossom_offset, 0);

        // blossom_to_base_dview[blossom_base] = blossom_base;

        // for (index_t i = 0; i <= v_idx_in_blossom; ++i) {
        //   index_t node = path_table_dview.GetNodeFromBlossom(blossom_offset, i);
        //   if (blossom_to_base_dview[node] == nnodes) {
        //     blossom_to_base_dview[node] = blossom_base;
        //   }
        // }

        // Log # of blossom
        // atomicAdd(&num_blossom_dview, 1);
        // Log # of odd nodes to process
        // atomicAdd(&num_odd_nodes_dview, v_idx_in_blossom / 2);
        // log max # of odd nodes to process by a single thread
        // atomicMax(&num_odd_nodes_dview, v_idx_in_blossom / 2);

        // rightwards
        for (index_t i = 1; i <= v_idx_in_blossom; i += 2) {
          index_t odd_node = path_table_dview.GetNodeFromBlossom(blossom_offset, i);
          // index_t odd_node = path_table_dview.GetNodeFromBlossomInBlossomBuffer(blossom_offset, i);
          if (!is_even_dview[odd_node] && path_table_dview.IsPathEmpty(odd_node) &&
              atomicCAS(&atomic_locks_odd_nodes_dview[odd_node], DFLAG_FALSE, DFLAG_TRUE) == DFLAG_FALSE) {
            index_t offset = blossom_offset + i + 1;
            // (blossom length - 1) - i + 1 (- 1) (exclude node itself)
            size_t length = nnodes_in_blossom - static_cast<size_t>(i) - 1;

            // if (path_table_dview.CheckDuplicationInBlossomBuffer(offset, length)) {
            //   continue;
            // }
            if (path_table_dview.CheckDuplication(offset, length)) {
              continue;
            }

            // printf("Node %d is TRANFORMED into an Even-Node by v: %d, w: %d\n", odd_node, v, w);

            path_table_dview.ExpandNodesFromBlossomReusePath(odd_node, blossom_base, offset, length);
            // path_table_dview.ExpandNodesFromBlossomRightwards(odd_node, blossom_offset, nnodes_in_blossom, i + 1);

            is_even_dview[odd_node] = 1;
            // atomicExch(&is_even_dview[odd_node], 1);

            __threadfence();
            enode_queue_dview.AppendENode2(odd_node);
            // enode_queue_dview.AppendENode2Warp(odd_node);
          }
        }

        // if (v_idx_in_blossom / 2 == 0) {
        //   return;
        // }
        //
        // index_t offset_par_blossom = blossom_offset_list_dview.Append(blossom_offset);
        // num_nodes_in_blossom_list_dview[offset_par_blossom] = nnodes_in_blossom;
        // num_odd_nodes_in_blossom_list_dview[offset_par_blossom] = v_idx_in_blossom / 2;
      }
    });

    // std::cout << "Num of blossom =" << num_blossom.GetD2H() << std::endl;
    // std::cout << "Num of transformed odd nodes =" << num_odd_nodes.GetD2H() << std::endl;

    CUDA_CHECK(cudaDeviceSynchronize());

    // prefix sum
    // size_t num_blossom = blossom_offset_list_.size();
    // thrust::exclusive_scan(num_odd_nodes_in_blossom_list_.begin(),
    //                        num_odd_nodes_in_blossom_list_.begin() + num_blossom + 1,
    //                        num_odd_nodes_in_blossom_psum_.begin());
    // size_t total_num_transforms = num_odd_nodes_in_blossom_psum_[num_blossom];
    //
    // auto num_odd_nodes_in_blossom_psum_dview = this->num_odd_nodes_in_blossom_psum_.DeviceView();
    //
    // if (total_num_transforms > 0) {
    //   this->ExecuteNTasklet(total_num_transforms, [=] __device__ (index_t tid) mutable {
    //     index_t offset_par_blossom_idx = FindRightmostLTEQ(num_odd_nodes_in_blossom_psum_dview,
    //                                                        num_blossom + 1,
    //                                                        tid);
    //     index_t blossom_offset = blossom_offset_list_dview[offset_par_blossom_idx];
    //     index_t nnodes_in_blossom = num_nodes_in_blossom_list_dview[offset_par_blossom_idx];
    //
    //     // delta
    //     index_t odd_idx = 1 + 2 * (tid - num_odd_nodes_in_blossom_psum_dview[offset_par_blossom_idx]);
    //
    //     index_t odd_node = path_table_dview.GetNodeFromBlossom(blossom_offset, odd_idx);
    //
    //     // blossom base
    //     index_t blossom_base = path_table_dview.GetNodeFromBlossom(blossom_offset, 0);
    //
    //     if (!is_even_dview[odd_node] && path_table_dview.IsPathEmpty(odd_node) &&
    //         atomicCAS(&atomic_locks_odd_nodes_dview[odd_node], DFLAG_FALSE, DFLAG_TRUE) == DFLAG_FALSE) {
    //       index_t offset = blossom_offset + odd_idx + 1;
    //       // (blossom length - 1) - odd_idx + 1 (- 1) (exclude node itself)
    //       size_t length = nnodes_in_blossom - static_cast<size_t>(odd_idx) - 1;
    //
    //       if (path_table_dview.CheckDuplication(offset, length)) {
    //         return;
    //       }
    //
    //       path_table_dview.ExpandNodesFromBlossomReusePath(odd_node, blossom_base, offset, length);
    //
    //       // is_even_dview[odd_node] = 1;
    //       atomicExch(&is_even_dview[odd_node], 1);
    //
    //       __threadfence();
    //       enode_queue_dview.AppendENode2(odd_node);
    //     }
    //   });
    // }

    auto enode2_end = enode_queue_.End();
    // LOG(INFO) << "[Transform] Enqueue " << enode2_end - enode2_begin << " enodes" << " with end <" << enode2_end << ">";

    auto end_time = getNanoSecond(); // Stop Profiling
    this->time_blossom += end_time - start_time;
  }
}
