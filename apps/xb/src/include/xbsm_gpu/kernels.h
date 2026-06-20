#ifndef KERNELS_H
#define KERNELS_H
#include "enode_queue/enode_queue.h"
#include "path_table/path_table.h"
#include "utils/dev_array.h"
#include "utils/utils_gpu.h"
#include "graph/dgraph.h"

namespace zblossom {
  // --------------------------- P1 ------------------------------------
  // -------------------- K1: Augmenting path pairs --------------------
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
    DValueView<int> found_dview);

  // -------------------- K2: Expansion pairs --------------------
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
    DArrayView<int> atomic_locks_match_dview);


  // -------------------- K3: Blossom transform pairs --------------------
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
    DArrayView<int> atomic_locks_odd_nodes_dview);

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
    DArrayView<index_t> num_odd_nodes_vside_in_blossom_list_dview);

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
    ENodeQueueDeviceView enode_queue_dview);
} // namespace zblossom


#endif //KERNELS_H
