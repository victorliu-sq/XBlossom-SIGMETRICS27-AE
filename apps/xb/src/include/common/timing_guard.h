#ifndef X_BLOSSOM_TIMING_GUARD_H
#define X_BLOSSOM_TIMING_GUARD_H
#include <numeric>

#include "utils/cpp_types.h"

namespace zblossom {
  class TimingVectorGuard {
  public:
    // Initialize TimingGuard with an initialized vector
    explicit TimingVectorGuard(std::vector<std::chrono::nanoseconds> &timing_vector) noexcept
      : timing_vector_(timing_vector), start_(std::chrono::high_resolution_clock::now()) {
    }

    ~TimingVectorGuard() {
      auto end = std::chrono::high_resolution_clock::now();
      timing_vector_.push_back(end - start_);
    }

  private:
    std::vector<std::chrono::nanoseconds> &timing_vector_;
    std::chrono::high_resolution_clock::time_point start_;
  };

  // ===================================================================================
  // Helper functions
  // template<class TickPeriod=std::ratio<1> >
  // static double AvgRuntime(std::vector<std::chrono::nanoseconds> duration_vec) {
  //   // accumulate all durations in nanoseconds
  //   std::chrono::nanoseconds total{0};
  //   for (auto &d: duration_vec) {
  //     total += d;
  //   }
  //
  //   // convert the duraiton into target duration
  //   using TargetDuration = std::chrono::duration<double, TickPeriod>;
  //   TargetDuration converted = std::chrono::duration_cast<TargetDuration>(total);
  //
  //   // average
  //   return converted.count() / duration_vec.size();
  // }
  template<class TickPeriod = std::ratio<1> >
  static double AvgRuntime(const std::vector<std::chrono::nanoseconds> &duration_vec) {
    if (duration_vec.empty()) {
      throw std::invalid_argument("Need at least 1 sample");
    }

    std::chrono::nanoseconds total{0};
    std::chrono::nanoseconds min = duration_vec[0];
    std::chrono::nanoseconds max = duration_vec[0];

    for (const auto &d: duration_vec) {
      total += d;
      if (d < min) min = d;
      if (d > max) max = d;
    }

    std::size_t count = duration_vec.size();

    // Drop min and max only if we have enough samples
    if (count >= 3) {
      total -= min;
      total -= max;
      count -= 2;
    }

    using TargetDuration = std::chrono::duration<double, TickPeriod>;
    TargetDuration converted = std::chrono::duration_cast<TargetDuration>(total);

    return converted.count() / count;
  }


  template<class TickPeriod=std::ratio<1> >
  static double SumRuntime(std::vector<std::chrono::nanoseconds> duration_vec) {
    // accumulate all durations in nanoseconds
    std::chrono::nanoseconds total{0};
    for (auto &d: duration_vec) {
      total += d;
    }

    // convert the duraiton into target duration
    using TargetDuration = std::chrono::duration<double, TickPeriod>;
    TargetDuration converted = std::chrono::duration_cast<TargetDuration>(total);

    // Sum
    return converted.count();
  }
}

#endif //X_BLOSSOM_TIMING_GUARD_H
