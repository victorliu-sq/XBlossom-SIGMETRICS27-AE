#ifndef X_BLOSSOM_GFLAGS_GUARD_H
#define X_BLOSSOM_GFLAGS_GUARD_H

#pragma once
#include <gflags/gflags.h>
#include <memory>

namespace zblossom {

class GflagsGuard {
public:
  explicit GflagsGuard(int& argc, char**& argv, bool remove_flags = true) noexcept
      : argc_(argc), argv_(argv), remove_flags_(remove_flags) {
    gflags::ParseCommandLineFlags(&argc_, &argv_, remove_flags_);
  }

  ~GflagsGuard() noexcept {
    gflags::ShutDownCommandLineFlags();
  }

  // Disable copy and move to ensure one active guard per process
  GflagsGuard(const GflagsGuard&) = delete;
  GflagsGuard& operator=(const GflagsGuard&) = delete;
  GflagsGuard(GflagsGuard&&) = delete;
  GflagsGuard& operator=(GflagsGuard&&) = delete;

private:
  int& argc_;
  char**& argv_;
  bool remove_flags_;
};

// Factory helper (same pattern as your GlogGuard)
static inline std::unique_ptr<GflagsGuard> CreateGflagsGuard(int& argc, char**& argv, bool remove_flags = true) {
  return std::make_unique<GflagsGuard>(argc, argv, remove_flags);
}

using GflagsGuardUptr = std::unique_ptr<GflagsGuard>;

} // namespace zblossom

#endif //X_BLOSSOM_GFLAGS_GUARD_H