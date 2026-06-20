#ifndef XBLOSSOM_GPU_ENGINE_10_H
#define XBLOSSOM_GPU_ENGINE_10_H

#include "max_match_engine.h"
#include "enode_queue/enode_queue.h"
#include "path_table/path_table.h"
#include "utils/stream.h"
#include "utils/launcher.h"

namespace zblossom {
  class XBlossomGpuEngineNR : public SecondaryMaximumMatchingGPUEngine {
    // template<typename XBlossomEngine>
    friend class XbsmGpuEngineTester<XBlossomGpuEngineNR>;

  public:
    static String EngineName() {
      return "XBlossomGpuEngineNR(X-Blossom++ w/o Reuse)";
    }

    XBlossomGpuEngineNR() = delete;

    XBlossomGpuEngineNR(const HGraph &g);

    XBlossomGpuEngineNR(const HGraph &g, size_t path_table_buffer_ratio);

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
  };
}

#endif //XBLOSSOM_GPU_ENGINE_10_H
