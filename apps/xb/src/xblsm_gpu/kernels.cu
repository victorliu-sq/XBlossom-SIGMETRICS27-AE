#include "xbsm_gpu/kernels.h"

#include "utils/cuda_algo.h"

namespace zblossom {
  // ======================= K1: Augmenting path pairs =======================
  __global__ void KFindAndFlipAugmentingPathPairs(
    size_t total_pairs,
    index_t enode_base_offset,
    index_t total_even_nodes,
    index_t nnodes,
    DArrayView<index_t> col_indices_presum_dview,
    ENodeQueueDeviceView enode_queue_dview,
    DGraphView graph_dview,
    DArrayView<index_t> matching_dview,
    dev::PathTableView path_table_dview,
    DArrayView<int> is_even_dview,
    DArrayView<index_t> tree_roots_dview,
    DArrayView<int> atomic_locks_tree_dview,
    DValueView<int> found_dview) {
    index_t tid = blockIdx.x * blockDim.x + threadIdx.x;
    if (tid >= (index_t) total_pairs) return;

    index_t v_idx = FindRightmostLTEQ(col_indices_presum_dview, total_even_nodes + 1, tid);
    index_t v = enode_queue_dview[enode_base_offset + v_idx];
    int delta = tid - col_indices_presum_dview[v_idx];

    index_t w_offset = graph_dview.row_offsets[v] + delta;
    index_t w = graph_dview.col_indices[w_offset];

    index_t root_v = tree_roots_dview[v];
    index_t root_w = tree_roots_dview[w];

    if (is_even_dview[w] && root_v != root_w && root_v != nnodes && root_w != nnodes) {
      index_t first_lock = MIN(root_v, root_w);
      index_t second_lock = MAX(root_v, root_w);

      if (atomicCAS(&atomic_locks_tree_dview[first_lock], DFLAG_FALSE, DFLAG_TRUE) != DFLAG_FALSE) return;

      if (atomicCAS(&atomic_locks_tree_dview[second_lock], DFLAG_FALSE, DFLAG_TRUE) != DFLAG_FALSE) {
        atomicExch(&atomic_locks_tree_dview[first_lock], DFLAG_FALSE);
        return;
      }

      path_table_dview.AddAugmentingPath(v, w, matching_dview);
      __threadfence();
      atomicExch(&found_dview, DFLAG_TRUE);
    }
  }

  // ======================= K2: Expansion pairs =======================
  __global__ void KExpandAlternatingForestPairs(
    size_t total_pairs,
    index_t enode_base_offset,
    index_t total_even_nodes,
    index_t nnodes,
    DArrayView<index_t> col_indices_presum_dview,
    ENodeQueueDeviceView enode_queue_dview,
    DGraphView graph_dview,
    DArrayView<index_t> matching_dview,
    dev::PathTableView path_table_dview,
    DArrayView<int> is_even_dview,
    DArrayView<index_t> tree_roots_dview,
    DArrayView<int> atomic_locks_match_dview) {
    index_t tid = blockIdx.x * blockDim.x + threadIdx.x;
    if (tid >= (index_t) total_pairs) return;

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
        path_table_dview.ExpandTwoNodes(v, w, x);

        __threadfence();

        atomicExch(&is_even_dview[w], 0);
        atomicExch(&is_even_dview[x], 1);

        atomicExch(&tree_roots_dview[w], root_v);
        atomicExch(&tree_roots_dview[x], root_v);

        __threadfence();
        enode_queue_dview.AppendENode1(x);
      }
    }
  }

  // ======================= K3: Blossom transform pairs =======================
  __global__ void KTransformOddNodesInBlossomPairs(
    size_t total_pairs,
    index_t enode_base_offset,
    index_t total_even_nodes,
    index_t nnodes,
    DArrayView<index_t> col_indices_presum_dview,
    ENodeQueueDeviceView enode_queue_dview,
    DGraphView graph_dview,
    DArrayView<index_t> matching_dview,
    dev::PathTableView path_table_dview,
    DArrayView<int> is_even_dview,
    DArrayView<index_t> tree_roots_dview,
    DArrayView<int> atomic_locks_odd_nodes_dview) {
    index_t tid = blockIdx.x * blockDim.x + threadIdx.x;
    if (tid >= (index_t) total_pairs) return;

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

      path_table_dview.FindBlossomInBlossomBuffer(
        v, w, blossom_offset, nnodes_in_blossom, v_idx_in_blossom, w_idx_in_blossom);
      __threadfence();

      // ---- Rightwards
      for (index_t k = 1; k < v_idx_in_blossom; k += 2) {
        index_t cur = path_table_dview.GetNodeFromBlossomInBlossomBuffer(blossom_offset, k);
        if (!is_even_dview[cur] && path_table_dview.IsPathEmpty(cur)) {
          if (atomicCAS(&atomic_locks_odd_nodes_dview[cur], DFLAG_FALSE, DFLAG_TRUE) == DFLAG_FALSE) {
            if (path_table_dview.CheckPathDuplicationInBlossomBufferRightwards(
              blossom_offset + k, (nnodes_in_blossom - 1) - k + 1)) {
              continue;
            }
            path_table_dview.ExpandNodesFromBlossomRightwards(cur, blossom_offset, nnodes_in_blossom, k + 1);
            __threadfence();
            enode_queue_dview.AppendENode2(cur);
            __threadfence();
            atomicExch(&is_even_dview[cur], 1);
          }
        }
      }

      // ---- Leftwards
      for (index_t k = nnodes_in_blossom - 2; k > w_idx_in_blossom; k -= 2) {
        index_t cur = path_table_dview.GetNodeFromBlossomInBlossomBuffer(blossom_offset, k);
        if (!is_even_dview[cur] && path_table_dview.IsPathEmpty(cur)) {
          if (atomicCAS(&atomic_locks_odd_nodes_dview[cur], DFLAG_FALSE, DFLAG_TRUE) == DFLAG_FALSE) {
            if (path_table_dview.CheckPathDuplicationInBlossomBufferLeftwards(
              blossom_offset + k, k - 0 + 1)) {
              continue;
            }
            path_table_dview.ExpandNodesFromBlossomLeftwards(cur, blossom_offset, k - 1);
            __threadfence();
            enode_queue_dview.AppendENode2(cur);
            __threadfence();
            atomicExch(&is_even_dview[cur], 1);
          }
        }
      }
    }
  }

  // ==========================================================================================
  // P2 - Transform Odd Nodes in Parallel

  // ======================================================================
  // KCollectBlossomMeta
  //   Builds the blossom metadata lists (offset, sizes, odd counts)
  //   by scanning all (v, w) candidate edges in parallel.
  // ======================================================================
  __global__ void KCollectBlossomMeta(
    size_t total_pairs,
    index_t enode_base_offset,
    index_t total_even_nodes,
    index_t nnodes,
    DArrayView<index_t> col_indices_presum_dview,
    ENodeQueueDeviceView enode_queue_dview,
    DGraphView graph_dview,
    DArrayView<index_t> matching_dview,
    dev::PathTableView path_table_dview,
    DArrayView<int> is_even_dview,
    DArrayView<index_t> tree_roots_dview,
    DListView<index_t> blossom_offset_list_dview,
    DArrayView<index_t> num_nodes_in_blossom_list_dview,
    DArrayView<index_t> num_odd_nodes_in_blossom_list_dview,
    DArrayView<index_t> num_odd_nodes_vside_in_blossom_list_dview) {
    index_t tid = blockIdx.x * blockDim.x + threadIdx.x;
    if (tid >= (index_t) total_pairs) return;

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
      index_t v_idx_in_blossom, w_idx_in_blossom;

      path_table_dview.FindBlossomInBlossomBuffer(
        v, w, blossom_offset, nnodes_in_blossom, v_idx_in_blossom, w_idx_in_blossom);

      // #odd on v-side: v_idx_in_blossom / 2
      size_t num_odd_v = (size_t) v_idx_in_blossom >> 1;
      // total #odd (exclude two bases, divide by 2)
      size_t num_odd_total = (nnodes_in_blossom - 2) >> 1;

      if (num_odd_total == 0) return;

      index_t off = blossom_offset_list_dview.Append(blossom_offset);
      num_nodes_in_blossom_list_dview[off] = (index_t) nnodes_in_blossom;
      num_odd_nodes_in_blossom_list_dview[off] = (index_t) num_odd_total;
      num_odd_nodes_vside_in_blossom_list_dview[off] = (index_t) num_odd_v;
    }

    __threadfence();
  }

  // ======================================================================
  // KTransformOddNodesFromMeta
  //   Uses the prefix-summed odd-counts to dispatch one thread per
  //   odd node and expand its path (branchless left/right).
  // ======================================================================
  __global__ void KTransformOddNodesFromMeta(
    size_t total_transforms,
    index_t num_blossom, // number of entries in the lists
    DArrayView<index_t> num_odd_nodes_in_blossom_psum_dview,
    DListView<index_t> blossom_offset_list_dview,
    DArrayView<index_t> num_nodes_in_blossom_list_dview,
    DArrayView<index_t> num_odd_nodes_vside_in_blossom_list_dview,
    dev::PathTableView path_table_dview,
    DArrayView<int> is_even_dview,
    DArrayView<int> atomic_locks_odd_nodes_dview,
    ENodeQueueDeviceView enode_queue_dview) {
    index_t tid = blockIdx.x * blockDim.x + threadIdx.x;
    if (tid >= (index_t) total_transforms) return;

    index_t par_idx = FindRightmostLTEQ(
      num_odd_nodes_in_blossom_psum_dview, num_blossom + 1, tid);

    index_t blossom_offset = blossom_offset_list_dview[par_idx];
    index_t nnodes_in_blossom = num_nodes_in_blossom_list_dview[par_idx];
    index_t num_vside_odd = num_odd_nodes_vside_in_blossom_list_dview[par_idx];

    index_t delta = tid - num_odd_nodes_in_blossom_psum_dview[par_idx];
    int vside = (delta <= (num_vside_odd - 1)); // 0/1

    // Branchless odd index:
    index_t odd_idx = 1 + 2 * delta + (1 - vside);
    index_t odd_node = path_table_dview.GetNodeFromBlossomInBlossomBuffer(blossom_offset, odd_idx);

    if (!is_even_dview[odd_node] && path_table_dview.IsPathEmpty(odd_node) &&
        atomicCAS(&atomic_locks_odd_nodes_dview[odd_node], DFLAG_FALSE, DFLAG_TRUE) == DFLAG_FALSE) {
      int step = vside ? +1 : -1;
      index_t start_idx = odd_idx + step;
      size_t path_len = vside
                          ? (nnodes_in_blossom - odd_idx - 1)
                          : (static_cast<size_t>(odd_idx));

      if (path_table_dview.CheckPathDuplicationInBlossomBufferDirectional(
        blossom_offset, start_idx, path_len, step)) {
        return;
      }

      path_table_dview.ExpandNodesFromBlossomDirectional(
        odd_node, blossom_offset, nnodes_in_blossom, start_idx, path_len, step);

      atomicExch(&is_even_dview[odd_node], 1);
      enode_queue_dview.AppendENode2(odd_node);
    }
  }
} // namespace zblossom
