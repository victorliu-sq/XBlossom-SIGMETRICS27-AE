#ifndef ENODE_QUEUE_2_H
#define ENODE_QUEUE_2_H

#include "utils/types_gpu.h"
#include "utils/dev_array.h"
#include "utils/dev_value.h"
#include <cooperative_groups.h>

namespace zblossom {
  template<typename XBlossomEngine>
  class XbsmGpuEngineTester;

  // class XBlossomGpuEngineTester;
  // class XBlossomGpuEngineParEdgeTester;

  class ENodeQueue2DeviceView {
  public:
    explicit ENodeQueue2DeviceView(DArrayView<index_t> enodes_buffer,
                                   DValueView<index_t> frontier_begin,
                                   DValueView<index_t> frontier_end,
                                   DValueView<index_t> blossom_begin,
                                   DValueView<index_t> blossom_end
    ): enodes_buffer_(enodes_buffer),
       frontier_begin_(frontier_begin),
       frontier_end_(frontier_end),
       blossom_begin_(blossom_begin),
       blossom_end_(blossom_end) {
    }

    DEV_INLINE void AppendENode(index_t enode) {
      index_t enodes_offset = atomicAdd(&frontier_end_, 1);
      enodes_buffer_[enodes_offset] = enode;
      __threadfence();
    }

    DEV_INLINE index_t &operator[](index_t idx) {
      return this->enodes_buffer_[idx];
    }

  private:
    DArrayView<index_t> enodes_buffer_;

    DValueView<index_t> frontier_begin_;
    DValueView<index_t> frontier_end_;
    DValueView<index_t> blossom_begin_;
    DValueView<index_t> blossom_end_;
  };

  class ENodeQueue2 {
    friend class ENodeQueue2Tester;
    // friend class zblossom::XBlossomGpuEngineTester;
    // friend class zblossom::XBlossomGpuEngineParEdgeTester;

    template<typename XBlossomEngine>
    friend class XbsmGpuEngineTester;

  public:
    ENodeQueue2(size_t n)
      : enodes_buffer_(n),
        frontier_begin_(0),
        frontier_end_(0),
        blossom_begin_(0),
        blossom_end_(0),
        capacity_(n) {
    }

    ENodeQueue2DeviceView DeviceView() {
      return ENodeQueue2DeviceView(enodes_buffer_.DeviceView(),
                                   frontier_begin_.DeviceView(),
                                   frontier_end_.DeviceView(),
                                   blossom_begin_.DeviceView(),
                                   blossom_end_.DeviceView());
    }

    inline void Clear() {
      this->frontier_begin_.SetH2D(0);
      this->frontier_end_.SetH2D(0);
      this->blossom_begin_.SetH2D(0);
      this->blossom_end_.SetH2D(0);
    }

    inline bool HasFrontier() {
      return this->frontier_end_.GetD2H() - this->frontier_begin_.GetD2H() > 0;
    }

    inline bool CanBlossom() {
      return this->blossom_end_.GetD2H() - this->blossom_begin_.GetD2H() > 0;
    }

    // **********************************************************************
    // Return base_offset and size for Expand() and Blossom() Operation
    // AugPath
    inline index_t AugPathBegin() {
      return this->frontier_begin_.GetD2H();
    }

    inline index_t AugPathEnd() {
      return this->frontier_end_.GetD2H();
    }

    inline size_t AugPathSize() {
      return this->frontier_end_.GetD2H() - this->frontier_begin_.GetD2H();
    }

    // Expand
    inline index_t ExpandBegin() {
      return this->frontier_begin_.GetD2H();
    }

    inline index_t ExpandEnd() {
      return this->frontier_end_.GetD2H();
    }

    inline size_t ExpandSize() {
      return this->frontier_end_.GetD2H() - this->frontier_begin_.GetD2H();
    }

    // Blossom
    inline index_t BlossomBegin() {
      return this->blossom_begin_.GetD2H();
    }

    inline index_t BlossomEnd() {
      return this->blossom_end_.GetD2H();
    }

    inline size_t BlossomSize() {
      return this->blossom_end_.GetD2H() - this->blossom_begin_.GetD2H();
    }

    // **********************************************************************
    // Begin and End for Expand() and Blossom() Operation

    // Invoke Prepare After Getting BaseOffset and Size for Expansion
    inline void PrepareExpand() {
      this->frontier_begin_.SetD2D(this->frontier_end_);
    }

    // Invoke Finalize After Expand operation to update blossom end
    inline void FinalizeExpand() {
      this->blossom_end_.SetD2D(this->frontier_end_);
    }

    // Invoke Prepare After Getting BaseOffset and Size for Blssom
    inline void PrepareBlossom() {
      this->blossom_begin_.SetD2D(this->blossom_end_);
      this->frontier_begin_.SetD2D(this->blossom_end_);
      this->frontier_end_.SetD2D(this->blossom_end_);
    }

    // Invoke Finalize After Blossom operation to update blossom end
    inline void FinalizeBlossom() {
      this->blossom_end_.SetD2D(this->frontier_end_);
    }

  private:
    DArray<index_t> enodes_buffer_;

    DValue<index_t> frontier_begin_;
    DValue<index_t> frontier_end_;
    DValue<index_t> blossom_begin_;
    DValue<index_t> blossom_end_;

    size_t capacity_;
  };
}

#endif //ENODE_QUEUE_2_H
