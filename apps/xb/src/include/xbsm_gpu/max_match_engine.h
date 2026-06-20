#ifndef MAX_MATCH_ENGINE_H
#define MAX_MATCH_ENGINE_H
#include "utils/dev_array.h"
#include "utils/dev_value.h"
#include "utils/mm_types_gpu.h"

namespace zblossom {
  class AbstractMaximumMatchingEngine {
  public:
    virtual ~AbstractMaximumMatchingEngine() = default;

    virtual auto FindMaximumMatch() -> Matching = 0;

    virtual auto FindMaximumMatch(const Matching &initial_matching) -> Matching = 0;
  };

  // ***************************************** CPU Engine *****************************************
  class SecondaryMaximumMatchingEngine : public AbstractMaximumMatchingEngine {
  public:
    SecondaryMaximumMatchingEngine() = delete;

    explicit SecondaryMaximumMatchingEngine(size_t nnodes): nnodes_(nnodes) {
    }

    virtual ~SecondaryMaximumMatchingEngine() = default;

    auto FindMaximumMatch() -> Matching override {
      // Without explicit initial matching, an empty set is provided.
      Matching matching(nnodes_);
      for (index_t i = 0; i < nnodes_; ++i) {
        matching[i] = nnodes_;
      }

      return FindMaximumMatch(matching);
    }

    auto FindMaximumMatch(const Matching &initial_matching) -> Matching override {
      Matching matching = initial_matching;
      // Iteratively Find an augmenting path and flip it until there is no augmenting path
      Vector<AugPath> aug_path_vector;
      this->FindAugmentingPath(aug_path_vector, matching);
      while (aug_path_vector.size() > 0) {
        this->FlipAugmentingPath(aug_path_vector, matching);

        aug_path_vector.clear();
        this->FindAugmentingPath(aug_path_vector, matching);
      }
      return matching;
    }

  private:
    size_t nnodes_;

  protected:
    // Finds one or multiple augmenting paths based on the current graph and matching.
    virtual void FindAugmentingPath(Vector<AugPath> &aug_path, const Matching &matching) = 0;

    // aug_path_vector contains all augmenting paths returned from last iteration
    // matching need to be flipped
    virtual void FlipAugmentingPath(const Vector<AugPath> &aug_path, Matching &matching) = 0;
  };

  // ***************************************** GPU Engine *****************************************
  class SecondaryMaximumMatchingGPUEngine : public AbstractMaximumMatchingEngine {
    // friend class XBlossomGpuEngineTester;
    // friend class XBlossomGpuEngineParEdgeTester;
    // friend class XBlossomGpuEngine3Tester;

    template<typename XBlossomEngine>
    friend class XbsmGpuEngineTester;

  public:
    SecondaryMaximumMatchingGPUEngine() = delete;

    explicit SecondaryMaximumMatchingGPUEngine(size_t nnodes)
      : nnodes_(nnodes),
        dev_matching_(nnodes, nnodes),
        // exhausted_(DFLAG_FALSE)
        found_(DFLAG_FALSE) {
    }

    virtual ~SecondaryMaximumMatchingGPUEngine() = default;

    auto FindMaximumMatch() -> Matching override {
      // Without explicit initial matching, an empty set is provided.
      Matching matching(nnodes_);
      for (index_t i = 0; i < nnodes_; ++i) {
        matching[i] = nnodes_;
      }
      return FindMaximumMatch(matching);
    }

    auto FindMaximumMatch(const Matching &initial_matching) -> Matching override {
      this->InitMatching(initial_matching);
      this->InitFound();

      Matching host_matching(nnodes_);

      this->FindAndFlipAugmentingPath();
      while (this->found_ == DFLAG_TRUE) {
        // thrust::copy(dev_matching_.begin(), dev_matching_.end(), host_matching.begin());
        // if (!TestMatching(host_matching)) {
        //   LOG(FATAL) << "TestMatching failed";
        // }

        this->found_ = DFLAG_FALSE;
        this->FindAndFlipAugmentingPath();
      }

      Matching result_matching(this->nnodes_);
      thrust::copy(dev_matching_.begin(), dev_matching_.end(), result_matching.begin());
      return result_matching;
    }

  protected:
    size_t nnodes_;
    DArray<index_t> dev_matching_;
    int found_;

    virtual void FindAndFlipAugmentingPath() = 0;

    // For testing
    virtual void InitMatching(const Matching &initial_matching) {
      dev_matching_.resize(nnodes_);
      assert(initial_matching.size() == nnodes_);
      thrust::copy(initial_matching.begin(), initial_matching.end(), dev_matching_.begin());
    }

    virtual void InitFound() {
      this->found_ = DFLAG_FALSE;
    }
  };
}


#endif //MAX_MATCH_ENGINE_H
