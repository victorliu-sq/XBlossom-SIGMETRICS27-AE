#include <glog/logging.h>
#include "xbsm_gpu/xblssom_gpu_engine_5.h"
#include "path_table/path_table.h"
#include "utils/cuda_algo.h"

namespace zblossom {
  XBlossomGpuEngine5::XBlossomGpuEngine5(const HGraph &g)
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
      num_odd_nodes_in_blossom_list_(PATH_TABLE_ODD_NODE_RATIO * nnodes_ + 1),
      num_odd_nodes_in_blossom_psum_(PATH_TABLE_ODD_NODE_RATIO * nnodes_ + 1) {
    // MultiGPU Init
    int num_gpus;
    cudaGetDeviceCount(&num_gpus);
    LOG(INFO) << "Number of Gpus is : " << num_gpus;
    cuda_streams_.resize(num_gpus);

    for (int gpu_id = 0; gpu_id < num_gpus; ++gpu_id) {
      cudaSetDevice(gpu_id);
      cuda_streams_[gpu_id] = CudaStream(StreamPriority::kDefault);

      // Enable Peer Access to GPU0
      if (gpu_id != 0) {
        int can_access_peer = 0;
        cudaDeviceCanAccessPeer(&can_access_peer, gpu_id, 0);
        if (can_access_peer) {
          cudaDeviceEnablePeerAccess(0, 0);
        }
      }
    }

    // Set default back to GPU 0
    cudaSetDevice(0);
  }

  void XBlossomGpuEngine5::FindAndFlipAugmentingPath() {
    this->InitAlternatingForest();

    // while (!this->IsExhausted() &&
    //        !this->AugPathAndExpandAndBlossom()) {
    // }

    while (!this->IsExhausted()
           && !this->AugPathAndExpand()) {
      this->TransformOddNodesInBlossom();
    }
  }

  void XBlossomGpuEngine5::InitAlternatingForest() {
    // ---- 1. Reset Host-side Structures ----
    LOG(INFO) << "---- Reset Everything ---- ";
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
    LOG(INFO) << "[Init] Enqueue " << enode1_end - enode1_begin << " enodes";

    this->enode_queue_.PrepareForAppendingENode2();

    // Init Parallize AugPath
    start_nodes_.Clear();
    num_flips_.Fill(0);
    num_flips_psum_.Fill(0);

    CUDA_CHECK(cudaDeviceSynchronize());
  }

  bool XBlossomGpuEngine5::AugPathAndExpandAndBlossom() {
    auto start_time = getNanoSecond();

    const size_t total_even_nodes = enode_queue_.Size();
    if (total_even_nodes == 0) {
      return false;
    }

    // AugPath Data
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

    auto col_indices_sizes_dview = this->col_indices_sizes_.DeviceView();
    auto col_indices_presum_dview = this->col_indices_presum_.DeviceView();

    this->ExecuteNTasklet(total_even_nodes, [=] __device__ (index_t idx) mutable {
      index_t v = enode_queue_dview[enode_base_offset + idx];
      col_indices_sizes_dview[idx] = graph_dview.row_offsets[v + 1] - graph_dview.row_offsets[v];
    });

    // Expansion Data
    auto atomic_locks_match_dview = this->atomic_locks_match_.DeviceView();


    // Compute Presum
    thrust::exclusive_scan(this->col_indices_sizes_.begin(),
                           this->col_indices_sizes_.begin() + total_even_nodes + 1,
                           this->col_indices_presum_.begin());

    size_t total_num_pairs = col_indices_presum_[total_even_nodes];

    // Expansion: Prepare to add enodes1 only after retrieving the base offset
    this->enode_queue_.PrepareForAppendingENode1();

    // Transform
    auto atomic_locks_odd_nodes_dview = this->atomic_locks_odd_nodes_.DeviceView();

    // For ParBlossom
    blossom_offset_list_.Clear();
    auto blossom_offset_list_dview = this->blossom_offset_list_.DeviceView();
    auto num_nodes_in_blossom_list_dview = this->num_nodes_in_blossom_list_.DeviceView();
    auto num_odd_nodes_in_blossom_list_dview = this->num_odd_nodes_in_blossom_list_.DeviceView();


    // MultiGPU
    // size_t pairs_per_gpu = (total_num_pairs + num_gpus - 1) / num_gpus;

    int num_gpus = cuda_streams_.size();
    const size_t MIN_TASKS_FOR_MULTIGPU = 30000; // Threshold
    int effective_num_gpus = (total_num_pairs < MIN_TASKS_FOR_MULTIGPU) ? 1 : num_gpus;
    size_t pairs_per_gpu = (total_num_pairs + effective_num_gpus - 1) / effective_num_gpus;


    // AugPath + Expand + Blossom
    // this->ExecuteNTasklet(total_num_pairs, [=] __device__ (index_t tid) mutable {
    //   index_t v_idx = FindRightmostLTEQ(col_indices_presum_dview, total_even_nodes + 1, tid);
    //   index_t v = enode_queue_dview[enode_base_offset + v_idx];
    //   // printf("For tid: %d, v_idx is :%d, v is :%d\n", tid, v_idx, v);
    //   int delta = tid - col_indices_presum_dview[v_idx];
    //
    //   index_t w_offset = graph_dview.row_offsets[v] + delta;
    //   index_t w = graph_dview.col_indices[w_offset];
    //
    //   index_t root_v = tree_roots_dview[v];
    //   index_t root_w = tree_roots_dview[w];
    //
    //   if (root_v != nnodes && root_w != nnodes && is_even_dview[w] && root_v != root_w) {
    //     index_t first_lock = MIN(root_v, root_w);
    //     index_t second_lock = MAX(root_v, root_w);
    //     // printf("Try to add augmentpath between Node %d and Node %d\n", v, w);
    //
    //     // Lock the smaller index first
    //     if (atomicCAS(&atomic_locks_tree_dview[first_lock], DFLAG_FALSE, DFLAG_TRUE) != DFLAG_FALSE) {
    //       return;
    //     }
    //
    //     // Lock the larger index second
    //     if (atomicCAS(&atomic_locks_tree_dview[second_lock], DFLAG_FALSE, DFLAG_TRUE) != DFLAG_FALSE) {
    //       atomicExch(&atomic_locks_tree_dview[first_lock], DFLAG_FALSE);
    //       return;
    //     }
    //
    //     path_table_dview.AddAugmentingPath(v, w, matching_dview);
    //
    //     // found_dview = DFLAG_TRUE;
    //     atomicExch(&found_dview, DFLAG_TRUE);
    //   }
    //
    //
    //   // ********************************************************************************************
    //   // Expand
    //   if (root_w == nnodes) {
    //     index_t x = matching_dview[w];
    //     index_t match_idx = MIN(w, x);
    //     if (atomicCAS(&atomic_locks_match_dview[match_idx], DFLAG_FALSE, DFLAG_TRUE) == DFLAG_FALSE) {
    //       path_table_dview.ExpandTwoNodes(v, w, x);
    //
    //       __threadfence();
    //
    //       enode_queue_dview.AppendENode1(x);
    //
    //       __threadfence();
    //
    //       // is_even_dview[w] = 0;
    //       // is_even_dview[x] = 1;
    //       // printf("Expand: Set Node %d as even\n", x);
    //
    //       // tree_roots_dview[w] = root_v;
    //       // tree_roots_dview[x] = root_v;
    //
    //       /****** atomicvisibility changes ***** */
    //       atomicExch(&is_even_dview[w], 0);
    //       atomicExch(&is_even_dview[x], 1);
    //
    //       atomicExch(&tree_roots_dview[w], root_v);
    //       atomicExch(&tree_roots_dview[x], root_v);
    //       /* **************************************** */
    //       __threadfence();
    //     }
    //   }
    //
    //   // ********************************************************************************************
    //   // Blossom
    //   if (is_even_dview[w] && root_v == root_w && matching_dview[v] != w && root_w != nnodes) {
    //     index_t blossom_offset;
    //     size_t nnodes_in_blossom;
    //
    //     index_t v_idx_in_blossom;
    //     // path_table_dview.FindBlossom(v, w, blossom_offset, nnodes_in_blossom, v_idx_in_blossom);
    //     // path_table_dview.FindAndAddBlossomImplicit(v, w, blossom_offset, nnodes_in_blossom, v_idx_in_blossom);
    //     path_table_dview.FindAndAddBlossomImplicitByAnchorNode(v, w, blossom_offset, nnodes_in_blossom,
    //                                                            v_idx_in_blossom);
    //
    //     if (v_idx_in_blossom / 2 == 0) {
    //       return;
    //     }
    //
    //     index_t offset_par_blossom = blossom_offset_list_dview.Append(blossom_offset);
    //     num_nodes_in_blossom_list_dview[offset_par_blossom] = nnodes_in_blossom;
    //     num_odd_nodes_in_blossom_list_dview[offset_par_blossom] = v_idx_in_blossom / 2;
    //   }
    //
    //   /* ------------  DEVICE–SIDE FENCE ------------- */
    //   __threadfence(); // visible to the whole GPU
    // });

    // Launch on all GPUs
    for (int gpu_id = 0; gpu_id < effective_num_gpus; ++gpu_id) {
      // for (int gpu_id = 0; gpu_id < num_gpus; ++gpu_id) {
      cudaSetDevice(gpu_id);
      size_t gpu_start = gpu_id * pairs_per_gpu;
      size_t gpu_end = min(gpu_start + pairs_per_gpu, total_num_pairs);
      size_t gpu_pairs = gpu_end - gpu_start;
      if (gpu_pairs == 0) continue;

      ExecuteNTasklet(cuda_streams_[gpu_id], gpu_pairs, [=] __device__ (index_t local_tid) mutable {
        index_t tid = gpu_start + local_tid;

        index_t v_idx = FindRightmostLTEQ(col_indices_presum_dview, total_even_nodes + 1, tid);
        index_t v = enode_queue_dview[enode_base_offset + v_idx];
        int delta = tid - col_indices_presum_dview[v_idx];

        index_t w_offset = graph_dview.row_offsets[v] + delta;
        index_t w = graph_dview.col_indices[w_offset];

        index_t root_v = tree_roots_dview[v];
        index_t root_w = tree_roots_dview[w];

        if (root_v != nnodes && root_w != nnodes && is_even_dview[w] && root_v != root_w) {
          index_t first_lock = MIN(root_v, root_w);
          index_t second_lock = MAX(root_v, root_w);

          if (atomicCAS(&atomic_locks_tree_dview[first_lock], DFLAG_FALSE, DFLAG_TRUE) != DFLAG_FALSE) {
            return;
          }
          if (atomicCAS(&atomic_locks_tree_dview[second_lock], DFLAG_FALSE, DFLAG_TRUE) != DFLAG_FALSE) {
            atomicExch(&atomic_locks_tree_dview[first_lock], DFLAG_FALSE);
            return;
          }

          path_table_dview.AddAugmentingPath(v, w, matching_dview);
          atomicExch(&found_dview, DFLAG_TRUE);
        }

        if (root_w == nnodes) {
          index_t x = matching_dview[w];
          index_t match_idx = MIN(w, x);
          if (atomicCAS(&atomic_locks_match_dview[match_idx], DFLAG_FALSE, DFLAG_TRUE) == DFLAG_FALSE) {
            path_table_dview.ExpandTwoNodes(v, w, x);
            __threadfence();
            enode_queue_dview.AppendENode1(x);
            atomicExch(&is_even_dview[w], 0);
            atomicExch(&is_even_dview[x], 1);
            atomicExch(&tree_roots_dview[w], root_v);
            atomicExch(&tree_roots_dview[x], root_v);
            __threadfence();
          }
        }

        if (is_even_dview[w] && root_v == root_w && matching_dview[v] != w && root_w != nnodes) {
          index_t blossom_offset, v_idx_in_blossom;
          size_t nnodes_in_blossom;

          path_table_dview.FindAndAddBlossomImplicitByAnchorNode(v, w, blossom_offset, nnodes_in_blossom,
                                                                 v_idx_in_blossom);

          if (v_idx_in_blossom / 2 == 0) return;

          index_t offset_par_blossom = blossom_offset_list_dview.Append(blossom_offset);
          num_nodes_in_blossom_list_dview[offset_par_blossom] = nnodes_in_blossom;
          num_odd_nodes_in_blossom_list_dview[offset_par_blossom] = v_idx_in_blossom / 2;
        }
        __threadfence();
      });
    }
    cudaSetDevice(0);

    CUDA_CHECK(cudaDeviceSynchronize());

    // prefix sum
    size_t num_blossom = blossom_offset_list_.size();
    thrust::exclusive_scan(num_odd_nodes_in_blossom_list_.begin(),
                           num_odd_nodes_in_blossom_list_.begin() + num_blossom + 1,
                           num_odd_nodes_in_blossom_psum_.begin());
    size_t total_num_transforms = num_odd_nodes_in_blossom_psum_[num_blossom];

    auto num_odd_nodes_in_blossom_psum_dview = this->num_odd_nodes_in_blossom_psum_.DeviceView();

    if (total_num_transforms > 0) {
      this->ExecuteNTasklet(total_num_transforms, [=] __device__ (index_t tid) mutable {
        index_t offset_par_blossom_idx = FindRightmostLTEQ(num_odd_nodes_in_blossom_psum_dview,
                                                           num_blossom + 1,
                                                           tid);
        index_t blossom_offset = blossom_offset_list_dview[offset_par_blossom_idx];
        index_t nnodes_in_blossom = num_nodes_in_blossom_list_dview[offset_par_blossom_idx];

        // delta
        index_t odd_idx = 1 + 2 * (tid - num_odd_nodes_in_blossom_psum_dview[offset_par_blossom_idx]);

        index_t odd_node = path_table_dview.GetNodeFromBlossom(blossom_offset, odd_idx);

        // blossom base
        index_t blossom_base = path_table_dview.GetNodeFromBlossom(blossom_offset, 0);

        if (!is_even_dview[odd_node] && path_table_dview.IsPathEmpty(odd_node) &&
            atomicCAS(&atomic_locks_odd_nodes_dview[odd_node], DFLAG_FALSE, DFLAG_TRUE) == DFLAG_FALSE) {
          index_t offset = blossom_offset + odd_idx + 1;
          // (blossom length - 1) - odd_idx + 1 (- 1) (exclude node itself)
          size_t length = nnodes_in_blossom - static_cast<size_t>(odd_idx) - 1;

          if (path_table_dview.CheckDuplication(offset, length)) {
            return;
          }

          path_table_dview.ExpandNodesFromBlossomReusePath(odd_node, blossom_base, offset, length);

          __threadfence();

          // is_even_dview[odd_node] = 1;
          atomicExch(&is_even_dview[odd_node], 1);

          // enode_queue_dview.AppendENode2(odd_node);
          enode_queue_dview.AppendENode1(odd_node);
        }
      });
    }

    this->enode_queue_.PrepareForAppendingENode2();

    auto end_time = getNanoSecond();
    this->time_augpath_and_expand_and_blossom += end_time - start_time;
    // AugPath return found
    auto found = this->dev_found_.GetD2H();

    return found == DFLAG_TRUE;
  }

  bool XBlossomGpuEngine5::AugPathAndExpand() {
    auto start_time = getNanoSecond();


    const size_t total_even_nodes = enode_queue_.Size();
    if (total_even_nodes == 0) {
      return false;
    }

    // AugPath Data
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

    // For logging
    auto enode1_begin = enode_queue_.ENnode1Begin();

    auto col_indices_sizes_dview = this->col_indices_sizes_.DeviceView();
    auto col_indices_presum_dview = this->col_indices_presum_.DeviceView();

    this->ExecuteNTasklet(total_even_nodes, [=] __device__ (index_t idx) mutable {
      index_t v = enode_queue_dview[enode_base_offset + idx];
      col_indices_sizes_dview[idx] = graph_dview.row_offsets[v + 1] - graph_dview.row_offsets[v];
    });

    // Expansion Data
    auto atomic_locks_match_dview = this->atomic_locks_match_.DeviceView();

    // Compute Presum
    thrust::exclusive_scan(this->col_indices_sizes_.begin(),
                           this->col_indices_sizes_.begin() + total_even_nodes + 1,
                           this->col_indices_presum_.begin());

    size_t total_num_pairs = col_indices_presum_[total_even_nodes];

    // Expansion: Prepare to add enodes1 only after retrieving the base offset
    this->enode_queue_.PrepareForAppendingENode1();

    // MultiGPU
    const size_t MULTI_GPU_THRESHOLD = 300000;
    int num_gpus = cuda_streams_.size();
    int active_gpus = (total_num_pairs >= MULTI_GPU_THRESHOLD) ? num_gpus : 1;
    size_t pairs_per_gpu = (total_num_pairs + active_gpus - 1) / active_gpus;

    // AugPath
    // this->ExecuteNTasklet(total_num_pairs, [=] __device__ (index_t tid) mutable {
    //   // __shared__ bool s_found;
    //
    //   // *****************************************************************************************************
    //   // AugPath
    //   index_t v_idx = FindRightmostLTEQ(col_indices_presum_dview, total_even_nodes + 1, tid);
    //   index_t v = enode_queue_dview[enode_base_offset + v_idx];
    //   // printf("For tid: %d, v_idx is :%d, v is :%d\n", tid, v_idx, v);
    //   int delta = tid - col_indices_presum_dview[v_idx];
    //
    //   index_t w_offset = graph_dview.row_offsets[v] + delta;
    //   index_t w = graph_dview.col_indices[w_offset];
    //
    //   index_t root_v = tree_roots_dview[v];
    //   index_t root_w = tree_roots_dview[w];
    //
    //   if (root_v != nnodes && root_w != nnodes && is_even_dview[w] && root_v != root_w) {
    //     index_t first_lock = MIN(root_v, root_w);
    //     index_t second_lock = MAX(root_v, root_w);
    //     // printf("Try to add augmentpath between Node %d and Node %d\n", v, w);
    //
    //     // Lock the smaller index first
    //     if (atomicCAS(&atomic_locks_tree_dview[first_lock], DFLAG_FALSE, DFLAG_TRUE) != DFLAG_FALSE) {
    //       return;
    //     }
    //
    //     // Lock the larger index second
    //     if (atomicCAS(&atomic_locks_tree_dview[second_lock], DFLAG_FALSE, DFLAG_TRUE) != DFLAG_FALSE) {
    //       atomicExch(&atomic_locks_tree_dview[first_lock], DFLAG_FALSE);
    //       return;
    //     }
    //
    //     // found_dview = DFLAG_TRUE;
    //     atomicExch(&found_dview, DFLAG_TRUE);
    //     __threadfence();
    //
    //     path_table_dview.AddAugmentingPath(v, w, matching_dview);
    //   }
    //
    //   // *****************************************************************************************************
    //   // Expand
    //   if (root_w == nnodes) {
    //     index_t x = matching_dview[w];
    //     index_t match_idx = MIN(w, x);
    //     if (atomicCAS(&atomic_locks_match_dview[match_idx], DFLAG_FALSE, DFLAG_TRUE) == DFLAG_FALSE) {
    //       path_table_dview.ExpandTwoNodes(v, w, x);
    //
    //       // __threadfence();
    //
    //       enode_queue_dview.AppendENode1(x);
    //
    //       __threadfence();
    //
    //       is_even_dview[w] = 0;
    //       is_even_dview[x] = 1;
    //       // printf("Expand: Set Node %d as even\n", x);
    //
    //       tree_roots_dview[w] = root_v;
    //       tree_roots_dview[x] = root_v;
    //
    //       /****** atomicvisibility changes ***** */
    //       // atomicExch(&is_even_dview[w], 0);
    //       // atomicExch(&is_even_dview[x], 1);
    //       //
    //       // atomicExch(&tree_roots_dview[w], root_v);
    //       // atomicExch(&tree_roots_dview[x], root_v);
    //       /* **************************************** */
    //       __threadfence();
    //     }
    //   }
    // });

    // Launch kernel on active GPUs
    for (int gpu_id = 0; gpu_id < active_gpus; ++gpu_id) {
      cudaSetDevice(gpu_id);

      size_t gpu_start = gpu_id * pairs_per_gpu;
      size_t gpu_end = min(gpu_start + pairs_per_gpu, total_num_pairs);
      size_t gpu_pairs = gpu_end - gpu_start;

      if (gpu_pairs == 0) continue;

      ExecuteNTasklet(cuda_streams_[gpu_id], gpu_pairs, [=] __device__(index_t local_tid) mutable {
        size_t tid = gpu_start + local_tid;

        // AugPath
        index_t v_idx = FindRightmostLTEQ(col_indices_presum_dview, total_even_nodes + 1, tid);
        index_t v = enode_queue_dview[enode_base_offset + v_idx];
        int delta = tid - col_indices_presum_dview[v_idx];

        index_t w_offset = graph_dview.row_offsets[v] + delta;
        index_t w = graph_dview.col_indices[w_offset];

        index_t root_v = tree_roots_dview[v];
        index_t root_w = tree_roots_dview[w];

        if (root_v != nnodes && root_w != nnodes && is_even_dview[w] && root_v != root_w) {
          index_t first_lock = MIN(root_v, root_w);
          index_t second_lock = MAX(root_v, root_w);

          if (atomicCAS(&atomic_locks_tree_dview[first_lock], DFLAG_FALSE, DFLAG_TRUE) != DFLAG_FALSE) {
            return;
          }
          if (atomicCAS(&atomic_locks_tree_dview[second_lock], DFLAG_FALSE, DFLAG_TRUE) != DFLAG_FALSE) {
            atomicExch(&atomic_locks_tree_dview[first_lock], DFLAG_FALSE);
            return;
          }

          atomicExch(&found_dview, DFLAG_TRUE);
          __threadfence();

          path_table_dview.AddAugmentingPath(v, w, matching_dview);
        }

        // Expand
        if (root_w == nnodes) {
          index_t x = matching_dview[w];
          index_t match_idx = MIN(w, x);
          if (atomicCAS(&atomic_locks_match_dview[match_idx], DFLAG_FALSE, DFLAG_TRUE) == DFLAG_FALSE) {
            path_table_dview.ExpandTwoNodes(v, w, x);
            enode_queue_dview.AppendENode1(x);

            atomicExch(&is_even_dview[w], 0);
            atomicExch(&is_even_dview[x], 1);
            atomicExch(&tree_roots_dview[w], root_v);
            atomicExch(&tree_roots_dview[x], root_v);
            __threadfence();
          }
        }
      });
    }

    cudaSetDevice(0); // Restore primary GPU

    auto enode1_end = enode_queue_.ENnode1End();
    LOG(INFO) << "[Expand] Enqueue " << enode1_end - enode1_begin << " enodes";

    auto end_time = getNanoSecond();
    this->time_augpath_and_expand += end_time - start_time;
    // AugPath return found
    auto found = this->dev_found_.GetD2H();

    if (found) {
      LOG(INFO) << "[Wasted]" << enode1_end - enode1_begin << " enodes";
    }

    return found == DFLAG_TRUE;
  }

  void XBlossomGpuEngine5::TransformOddNodesInBlossom() {
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

    LOG(INFO) << "[Blossom] Total nodes " << total_even_nodes;
    LOG(INFO) << "[Blossom] Total edges " << total_num_pairs;

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

        // path_table_dview.FindBlossom(v, w, blossom_offset, nnodes_in_blossom, v_idx_in_blossom);
        // path_table_dview.FindAndAddBlossomImplicit(v, w, blossom_offset, nnodes_in_blossom, v_idx_in_blossom);
        path_table_dview.FindAndAddBlossomImplicitByAnchorNode(v, w, blossom_offset, nnodes_in_blossom,
                                                               v_idx_in_blossom);

        if (v_idx_in_blossom / 2 == 0) {
          return;
        }

        index_t offset_par_blossom = blossom_offset_list_dview.Append(blossom_offset);
        num_nodes_in_blossom_list_dview[offset_par_blossom] = nnodes_in_blossom;
        num_odd_nodes_in_blossom_list_dview[offset_par_blossom] = v_idx_in_blossom / 2;
      }

      /* ------------  DEVICE–SIDE FENCE ------------- */
      __threadfence(); // visible to the whole GPU
    });

    // std::cout << "Num of blossom =" << num_blossom.GetD2H() << std::endl;
    // std::cout << "Num of transformed odd nodes =" << num_odd_nodes.GetD2H() << std::endl;

    CUDA_CHECK(cudaDeviceSynchronize());

    // prefix sum
    size_t num_blossom = blossom_offset_list_.size();
    thrust::exclusive_scan(num_odd_nodes_in_blossom_list_.begin(),
                           num_odd_nodes_in_blossom_list_.begin() + num_blossom + 1,
                           num_odd_nodes_in_blossom_psum_.begin());
    size_t total_num_transforms = num_odd_nodes_in_blossom_psum_[num_blossom];

    auto num_odd_nodes_in_blossom_psum_dview = this->num_odd_nodes_in_blossom_psum_.DeviceView();

    if (total_num_transforms > 0) {
      this->ExecuteNTasklet(total_num_transforms, [=] __device__ (index_t tid) mutable {
        index_t offset_par_blossom_idx = FindRightmostLTEQ(num_odd_nodes_in_blossom_psum_dview,
                                                           num_blossom + 1,
                                                           tid);
        index_t blossom_offset = blossom_offset_list_dview[offset_par_blossom_idx];
        index_t nnodes_in_blossom = num_nodes_in_blossom_list_dview[offset_par_blossom_idx];

        // delta
        index_t odd_idx = 1 + 2 * (tid - num_odd_nodes_in_blossom_psum_dview[offset_par_blossom_idx]);

        index_t odd_node = path_table_dview.GetNodeFromBlossom(blossom_offset, odd_idx);

        // blossom base
        index_t blossom_base = path_table_dview.GetNodeFromBlossom(blossom_offset, 0);

        if (!is_even_dview[odd_node] && path_table_dview.IsPathEmpty(odd_node) &&
            atomicCAS(&atomic_locks_odd_nodes_dview[odd_node], DFLAG_FALSE, DFLAG_TRUE) == DFLAG_FALSE) {
          index_t offset = blossom_offset + odd_idx + 1;
          // (blossom length - 1) - odd_idx + 1 (- 1) (exclude node itself)
          size_t length = nnodes_in_blossom - static_cast<size_t>(odd_idx) - 1;

          if (path_table_dview.CheckDuplication(offset, length)) {
            return;
          }

          path_table_dview.ExpandNodesFromBlossomReusePath(odd_node, blossom_base, offset, length);

          // is_even_dview[odd_node] = 1;
          atomicExch(&is_even_dview[odd_node], 1);

          __threadfence();
          enode_queue_dview.AppendENode2(odd_node);
        }
      });
    }

    auto enode2_end = enode_queue_.End();
    LOG(INFO) << "[Transform] Enqueue " << enode2_end - enode2_begin << " enodes" << " with end <" << enode2_end << ">";

    auto end_time = getNanoSecond(); // Stop Profiling
    this->time_blossom += end_time - start_time;
  }
}
