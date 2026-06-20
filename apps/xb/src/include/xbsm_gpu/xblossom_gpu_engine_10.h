#ifndef XBLOSSOM_GPU_ENGINE_10_H
#define XBLOSSOM_GPU_ENGINE_10_H

#include "max_match_engine.h"
#include "enode_queue/enode_queue.h"
#include "path_table/path_table.h"
#include "utils/stream.h"
#include "utils/launcher.h"
#include <cub/cub.cuh>

namespace zblossom {
  class XBlossomGpuEngine10 : public SecondaryMaximumMatchingGPUEngine {
    // template<typename XBlossomEngine>
    friend class XbsmGpuEngineTester<XBlossomGpuEngine10>;

  public:
    static String EngineName() {
      return "XBlossomGpuEngine10(Reuse+ParBlossom+AtomicExch)";
    }

    XBlossomGpuEngine10() = delete;

    XBlossomGpuEngine10(const HGraph &g);

    XBlossomGpuEngine10(const HGraph &g, size_t path_table_buffer_ratio);

    void FindAndFlipAugmentingPath() override;

    // ------------ Methods -----------------------------------
    void InitAlternatingForest();

    bool FindAndFlipAugmentingPathInAlternatingForest();

    void ExpandAlternatingForest();

    void TransformOddNodesInBlossom();

    // ------------ Profliing Methods -------------------------
    void PrintTimingSummary() const {
      auto augmenting_path_time_ms = this->time_augmenting_path / 1e9;
      auto expand_time_ms = this->time_expand / 1e9;
      auto blossom_time_ms = this->time_blossom / 1e9;
      auto preprocessing_time_ms = this->time_preprocessing / 1e9;
      LOG(INFO) << "XBlossomGPUEngine Timing Summary:";
      LOG(INFO) << "Augmenting Path: " << augmenting_path_time_ms;
      LOG(INFO) << "Expand: " << expand_time_ms;
      LOG(INFO) << "Blossom: " << blossom_time_ms;
      LOG(INFO) << "Preprocessing Time: " << preprocessing_time_ms;
      LOG(INFO) << "Total Time: " << augmenting_path_time_ms + expand_time_ms + blossom_time_ms;

      std::cout << EngineName() <<" Timing Summary:" << std::endl;
      std::cout << "Augmenting Path: " << augmenting_path_time_ms << std::endl;
      std::cout << "Expand: " << expand_time_ms << std::endl;
      std::cout << "Blossom: " << blossom_time_ms << std::endl;
      std::cout << "Preprocessing Time: " << preprocessing_time_ms << std::endl;
      std::cout << "Total Time: " << augmenting_path_time_ms + expand_time_ms + blossom_time_ms << std::endl;
    }

    void GetTimingSummary(double& augmenting_path_ms,
                          double& expand_ms,
                          double& blossom_ms,
                          double& total_ms) const {
      augmenting_path_ms = this->time_augmenting_path / 1e9;
      expand_ms          = this->time_expand / 1e9;
      blossom_ms         = this->time_blossom / 1e9;
      total_ms           = augmenting_path_ms + expand_ms + blossom_ms;
    }

    size_t NumEdgesProcessed() const {
      return this->num_edges_processed_;
    }

    size_t NumAugmentingPathEdgesProcessed() const {
      return this->num_aug_path_edges_processed_;
    }

    size_t NumExpandEdgesProcessed() const {
      return this->num_expand_edges_processed_;
    }

    size_t NumBlossomEdgesProcessed() const {
      return this->num_blossom_edges_processed_;
    }

    size_t NumBlossoms() const {
      return this->num_blossoms_;
    }

    size_t NumReusedTreeNodes() const {
      return this->num_reused_tree_nodes_;
    }

    size_t NumResetTreeNodes() const {
      return this->num_reset_tree_nodes_;
    }

  private:
    // ===================================================================
    // Timing
    ns_t time_total{0};
    ns_t time_augmenting_path{0};
    ns_t time_expand{0};
    ns_t time_blossom{0};
    ns_t time_augpath_and_expand{0};
    ns_t time_augpath_and_expand_and_blossom{0};
    ns_t time_expand_and_blossom{0};
    ns_t time_preprocessing{0};
    size_t num_edges_processed_{0};
    size_t num_aug_path_edges_processed_{0};
    size_t num_expand_edges_processed_{0};
    size_t num_blossom_edges_processed_{0};
    size_t num_blossoms_{0};
    size_t num_reused_tree_nodes_{0};
    size_t num_reset_tree_nodes_{0};

    // For Degree of Parallelism analysis
    Vector<Pair<size_t, size_t> > augmenting_path_stats_{};
    Vector<Pair<size_t, size_t> > expand_stats_{};
    Vector<Pair<size_t, size_t> > blossom_stats_{};

    // For Load Balance analysis
    // Vector<Vector<size_t> > augmenting_path_w_histogram_{};
    // Vector<Vector<size_t> > expand_w_histogram_{};
    // Vector<Vector<size_t> > blossom_w_histogram_{};

    // ---------------------------------------------------------
    // Modified Termination Point
    int exhausted_{DFLAG_FALSE};
    int first_init_{DFLAG_TRUE};

    DValue<DFlag> dev_found_;
    DValue<unsigned long long> dev_reused_tree_nodes_;
    DValue<unsigned long long> dev_reset_tree_nodes_;
    // host_graph_t host_graph_;
    device_graph_t device_graph_;

    // ------------ Host-only Data Structure ------------------
    // path_table_ stays strictly on host for path tracing.
    dev::PathTable path_table_;

    // ------------ Device-side Storage -------------------------
    DArray<DFlag> is_even_;
    DArray<index_t> tree_roots_;
    DArray<index_t> blossom_to_base_;

    DArray<DAtomicFlag> atomic_locks_tree_;
    DArray<DAtomicFlag> atomic_locks_match_;
    DArray<DAtomicFlag> atomic_locks_odd_nodes_;

    ENodeQueue enode_queue_;

    // ------------ Prefix Sum for Par Edge -------------------
    // of length n + 1
    DArray<index_t> col_indices_sizes_;
    DArray<index_t> col_indices_presum_;

    // ------------ For Parallize AugPath -------------------
    // of length n + 1
    DList<index_t> start_nodes_;
    DArray<index_t> num_flips_;
    DArray<index_t> num_flips_psum_; // prefix sum

    // ------------ For Parallize Blossom -------------------
    // DList<index_t> v_index_in_blossom_list_;
    DList<index_t> blossom_offset_list_;
    DArray<index_t> num_nodes_in_blossom_list_;
    DArray<index_t> num_odd_nodes_in_blossom_list_;
    DArray<index_t> num_odd_nodes_in_blossom_psum_;
    // for leftwards scan
    DArray<index_t> num_odd_nodes_vside_in_blossom_list_;

    // ------------ GPU Streams -------------------
    CudaStream cuda_stream_;
    DVector<char> cub_scan_temp_storage_;
    size_t cub_scan_temp_storage_bytes_{0};
    bool edge_prefix_cache_valid_{false};
    index_t edge_prefix_cache_begin_{0};
    size_t edge_prefix_cache_size_{0};
    size_t edge_prefix_cache_total_pairs_{0};

    // ------------ utility methods ----------------------------------
    inline bool IsExhausted() {
      if (this->enode_queue_.Size() == 0) {
        this->exhausted_ = DFLAG_TRUE;
      }
      return this->exhausted_;
    }

    // ------------ cuda utility methods -----------------------------
    template<typename F, typename... Arg>
    void ExecuteOneTasklet(F f, Arg... args) {
      LaunchKernelSingleThread(this->cuda_stream_, f, args...);
    }

    template<typename F, typename... Arg>
    void ExecuteNTasklets(size_t n, F f, Arg... arg) {
      LaunchKernelForEach(this->cuda_stream_, n, f, arg...);
    }

    template<typename F, typename... Arg>
    void ExecuteNTaskletsMax(size_t n, F f, Arg... arg) {
      LaunchKernelForEachMax(this->cuda_stream_, n, f, arg...);
    }

    template<typename InputIt, typename OutputIt>
    void ExclusiveScan(InputIt input_begin, OutputIt output_begin, size_t count) {
      void* temp_storage = thrust::raw_pointer_cast(cub_scan_temp_storage_.data());
      CUDA_CHECK(cub::DeviceScan::ExclusiveSum(temp_storage,
                                               cub_scan_temp_storage_bytes_,
                                               input_begin,
                                               output_begin,
                                               static_cast<int>(count),
                                               this->cuda_stream_.cuda_stream()));
      this->cuda_stream_.Sync();
    }

    inline void InitCubScanTempStorage(size_t max_count) {
      void* temp_storage = nullptr;
      size_t temp_storage_bytes = 0;
      CUDA_CHECK(cub::DeviceScan::ExclusiveSum(temp_storage,
                                               temp_storage_bytes,
                                               num_odd_nodes_in_blossom_list_.begin(),
                                               num_odd_nodes_in_blossom_psum_.begin(),
                                               static_cast<int>(max_count),
                                               this->cuda_stream_.cuda_stream()));
      if (temp_storage_bytes > cub_scan_temp_storage_bytes_) {
        cub_scan_temp_storage_.resize(temp_storage_bytes);
        cub_scan_temp_storage_bytes_ = temp_storage_bytes;
      }
    }

  public:
    inline void InvalidateEdgePrefixCache() {
      edge_prefix_cache_valid_ = false;
    }

    template<typename GraphView>
    size_t PrepareEdgePrefix(size_t total_even_nodes,
                             index_t enode_base_offset,
                             GraphView graph_dview,
                             ENodeQueueDeviceView enode_queue_dview) {
      if (edge_prefix_cache_valid_ &&
          edge_prefix_cache_begin_ == enode_base_offset &&
          edge_prefix_cache_size_ == total_even_nodes) {
        return edge_prefix_cache_total_pairs_;
      }

      auto col_indices_sizes_dview = this->col_indices_sizes_.DeviceView();
      this->ExecuteNTaskletsMax(total_even_nodes, [=] __device__ (index_t idx) mutable {
        index_t v = enode_queue_dview[enode_base_offset + idx];
        col_indices_sizes_dview[idx] = graph_dview.row_offsets[v + 1] - graph_dview.row_offsets[v];
      });

      this->ExclusiveScan(this->col_indices_sizes_.begin(),
                          this->col_indices_presum_.begin(),
                          total_even_nodes + 1);

      edge_prefix_cache_valid_ = true;
      edge_prefix_cache_begin_ = enode_base_offset;
      edge_prefix_cache_size_ = total_even_nodes;
      edge_prefix_cache_total_pairs_ = this->col_indices_presum_[total_even_nodes];
      return edge_prefix_cache_total_pairs_;
    }
  };
}

#endif //XBLOSSOM_GPU_ENGINE_10_H
