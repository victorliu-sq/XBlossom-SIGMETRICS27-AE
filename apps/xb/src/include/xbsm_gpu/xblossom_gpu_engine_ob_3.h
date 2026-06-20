#ifndef XBLOSSOM_GPU_ENGINE_OB_3_H
#define XBLOSSOM_GPU_ENGINE_OB_3_H

#include "max_match_engine.h"
#include "enode_queue/enode_queue.h"
#include "path_table/path_table.h"
#include "utils/stream.h"
#include "utils/launcher.h"

namespace zblossom {
  class XBlossomGpuEngineOb3 : public SecondaryMaximumMatchingGPUEngine {
    // template<typename XBlossomEngine>
    friend class XbsmGpuEngineTester<XBlossomGpuEngineOb3>;

  public:
    static inline String EngineName() {
      return "XBlossomGpuEngineOb3(Locality)";
    }

    XBlossomGpuEngineOb3() = delete;

    XBlossomGpuEngineOb3(const HGraph &g);

    XBlossomGpuEngineOb3(const HGraph &g, size_t path_table_buffer_ratio);

    void FindAndFlipAugmentingPath() override;

    // ------------ Methods -----------------------------------
    void InitAlternatingForest();

    bool FindAndFlipAugmentingPathInAlternatingForest();

    void ExpandAlternatingForest();

    void TransformOddNodesInBlossom();

    // ------------ Profliing Methods -------------------------
    void PrintTimingSummary() const {
      auto augmenting_path_time_ms = this->time_augmenting_path / 1e6;
      auto expand_time_ms = this->time_expand / 1e6;
      auto blossom_time_ms = this->time_blossom / 1e6;
      auto preprocessing_time_ms = this->time_preprocessing / 1e6;
      LOG(INFO) << "XBlossomGPUEngine Timing Summary:";
      LOG(INFO) << "Augmenting Path: " << augmenting_path_time_ms << " ms";
      LOG(INFO) << "Expand: " << expand_time_ms << " ms";
      LOG(INFO) << "Blossom: " << blossom_time_ms << " ms";
      LOG(INFO) << "Preprocessing Time: " << preprocessing_time_ms << " ms";
      LOG(INFO) << "Total Time: " << augmenting_path_time_ms + expand_time_ms + blossom_time_ms << " ms";
    }

    void PrintProfilingSummary() const {
#ifdef MM_PROFILE
      LOG(INFO) << "---------------------- Profiling Summary ----------------------";
      size_t num_iterations = augmenting_path_stats_.size();
      for (size_t i = 0; i < num_iterations; ++i) {
        LOG(INFO) << "Iteration " << i + 1 << ":";

        auto [aug_total, aug_effective] = augmenting_path_stats_[i];
        LOG(INFO) << "  Augmenting Path: " << aug_effective << " effective / "
            << aug_total << " total pairs ("
            << 100.0 * aug_effective / (aug_total ? aug_total : 1) << "% efficiency)";

        auto [expand_total, expand_effective] = expand_stats_[i];
        LOG(INFO) << "  Expansion: " << expand_effective << " effective / "
            << expand_total << " total pairs ("
            << 100.0 * expand_effective / (expand_total ? expand_total : 1) << "% efficiency)";

        auto [blossom_total, blossom_effective] = blossom_stats_[i];
        LOG(INFO) << "  Blossom: " << blossom_effective << " effective / "
            << blossom_total << " total pairs ("
            << 100.0 * blossom_effective / (blossom_total ? blossom_total : 1) << "% efficiency)";
      }
      LOG(INFO) << "---------------------------------------------------------------";
#endif
    }

  private:
    // ---------------------------------------------------------
    ns_t time_total{0};
    ns_t time_augmenting_path{0};
    ns_t time_expand{0};
    ns_t time_blossom{0};
    ns_t time_augpath_and_expand{0};
    ns_t time_augpath_and_expand_and_blossom{0};
    ns_t time_expand_and_blossom{0};
    ns_t time_preprocessing{0};

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

    DValue<DFlag> dev_found_;
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

    // ------------ GPU Streams -------------------
    CudaStream cuda_stream_;

    // ------------ utility methods ----------------------------------
    inline bool IsExhausted() {
      if (this->enode_queue_.Size() == 0) {
        this->exhausted_ = DFLAG_TRUE;
      }
      return this->exhausted_;
    }

    inline void LogArray(const DArray<index_t> &dev_array, size_t n) {
      for (size_t i = 0; i < n; ++i) {
        LOG(INFO) << i << ": [" << dev_array[i] << "]";
      }
    }

    // ------------ cuda utility methods -----------------------------
    template<typename F, typename... Arg>
    void ExecuteOneTasklet(F f, Arg... args) {
      LaunchKernelSingleThread(this->cuda_stream_, f, args...);
    }

    template<typename F, typename... Arg>
    void ExecuteNTasklet(size_t n, F f, Arg... arg) {
      LaunchKernelForEach(this->cuda_stream_, n, f, arg...);
    }
  };
}
#endif //XBLOSSOM_GPU_ENGINE_OB_3_H
