#ifndef XBLSM_GLOG_GUARD_H
#define XBLSM_GLOG_GUARD_H

#include "glog/logging.h"
#include <cerrno>
#include <string>
#include <sys/stat.h>
#include <sys/types.h>

namespace zblossom {
  static inline void EnsureGlogDir(const std::string& path) {
    std::string current;
    for (char ch : path) {
      current.push_back(ch);
      if (ch == '/' && current.size() > 1) {
        if (::mkdir(current.c_str(), 0755) != 0 && errno != EEXIST) {
          return;
        }
      }
    }
    if (!current.empty()) {
      ::mkdir(current.c_str(), 0755);
    }
  }

  class GlogGuard {
  public:
    explicit GlogGuard(const char* name, const char* log_dir = "tmp/logs")
      : log_dir_(log_dir) {
      EnsureGlogDir(log_dir_);
      FLAGS_log_dir = log_dir;
      google::InitGoogleLogging(name);
      google::InstallFailureSignalHandler();
    }

    ~GlogGuard() {
      google::ShutdownGoogleLogging();
    }

    // Disable copy and move to ensure one active guard per process
    GlogGuard(const GlogGuard&) = delete;
    GlogGuard& operator=(const GlogGuard&) = delete;
    GlogGuard(GlogGuard&&) = delete;
    GlogGuard& operator=(GlogGuard&&) = delete;

    const std::string& LogDir() const noexcept {
      return log_dir_;
    }

  private:
    std::string log_dir_;
  };

  static inline auto CreateGlogGuard(const char* test_name) {
    return std::make_unique<GlogGuard>(test_name);
  }

  using GlogGuardUptr = std::unique_ptr<GlogGuard>;
}

#endif //XBLSM_GLOG_GUARD_H
