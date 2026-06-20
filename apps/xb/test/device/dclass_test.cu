#include "gtest/gtest.h"
#include "common/glog_guard.h"
#include "device/gtest_dev.h"
#include "utils/dev_array.h"
#include "utils/dev_value.h"
#include "utils/dev_list.h"
#include "utils/launcher.h"

// -------------------------------------------------------------------------------
// Test Suite Setup
static std::string test_log_name = "dclass_test";

// -------------------------------------------------------------------------------
// Glog Wrapper
using glog_guard_t = zblossom::GlogGuard;
static std::unique_ptr<glog_guard_t> g_glog_guard;

// -------------------------------------------------------------------------------
// Test Environment
class TestEnvironment : public ::testing::Environment {
public:
  ~TestEnvironment() override = default;

  void SetUp() override {
    g_glog_guard = std::make_unique<glog_guard_t>(test_log_name.c_str());
  }

  void TearDown() override {}
};

// Register the environment before any tests run
::testing::Environment* const global_env =
  ::testing::AddGlobalTestEnvironment(new TestEnvironment);

// -------------------------------------------------------------------------------
// Test Fixture
class TestDevComponentFixture : public ::testing::Test {
protected:
  void SetUp() override {
    auto info = ::testing::UnitTest::GetInstance()->current_test_info();
    std::string test_suite = info->test_suite_name();
    std::string test_name = info->name();
    std::string prefix = g_glog_guard->LogDir() + "/log-" + test_suite + "-" + test_name;

    // Redirect log output to per-test files
    google::SetLogDestination(google::INFO, (prefix + ".INFO.").c_str());
    google::SetLogDestination(google::WARNING, (prefix + ".WARNING.").c_str());
    google::SetLogDestination(google::ERROR, (prefix + ".ERROR.").c_str());
    google::SetLogDestination(google::FATAL, (prefix + ".FATAL.").c_str());
  }
};

// -------------------------------------------------------------------------------
// DValue Test
// -------------------------------------------------------------------------------
TEST_F_PUBLIC(TestDevComponentFixture, TestDevValue) {
  const int val = 0;
  const int n = 10;
  DValue<int> v;
  v.SetH2D(val);
  auto v_view = v.DeviceView();

  // Set to 10
  DefaultLauncher::ExecuteOneTasklet([=] __device__ () mutable {
    v_view = 10;
  });
  LOG(INFO) << "new_v: " << v.GetD2H();

  // Add 10
  DefaultLauncher::ExecuteOneTasklet([=] __device__ () mutable {
    v_view = v_view.Value() + 10;
  });
  LOG(INFO) << "new_v: " << v.GetD2H();
  ASSERT_EQ(v.GetD2H(), 20);

  // Add indices 0..9
  DefaultLauncher::ExecuteNTasklet(n, [v_view] __device__ (size_t idx) mutable {
    atomicAdd(&v_view, (int)idx);
  });
  LOG(INFO) << "new_v: " << v.GetD2H();
  ASSERT_EQ(v.GetD2H(), 65);
}

// -------------------------------------------------------------------------------
// DArray Test
// -------------------------------------------------------------------------------
TEST_F_PUBLIC(TestDevComponentFixture, TestDevArray) {
  const int n = 10;
  HArray<int> host_array(n);
  DArray<int> dev_array(n);

  // Initialize host_array
  for (int i = 0; i < n; ++i)
    host_array[i] = i;

  dev_array.SetToDevice(host_array);
  auto dev_array_view = dev_array.DeviceView();

  // Increment by 1
  DefaultLauncher::ExecuteNTasklet(n, [dev_array_view] __device__ (int idx) mutable {
    dev_array_view[idx] += 1;
  });

  // Add 10 atomically
  DefaultLauncher::ExecuteNTasklet(n, [dev_array_view] __device__ (int idx) mutable {
    atomicAdd(&dev_array_view[idx], 10);
  });

  // Copy back
  dev_array.GetFromDevice(host_array);
  for (int i = 0; i < n; ++i) {
    LOG(INFO) << "host_array[" << i << "]: " << host_array[i];
    EXPECT_EQ(host_array[i], i + 11);
  }
}

// -------------------------------------------------------------------------------
// DList Test
// -------------------------------------------------------------------------------
TEST_F_PUBLIC(TestDevComponentFixture, TestDevList) {
  const int capacity = 100;
  const int n = 10;

  DList<int> dev_list(capacity);
  auto dev_list_view = dev_list.DeviceView();

  // 1. Append 10 elements
  DefaultLauncher::ExecuteNTasklet(n, [dev_list_view] __device__ (int idx) mutable {
    dev_list_view.Append(idx);
  });

  // 2. Append variable-sized blocks
  DefaultLauncher::ExecuteNTasklet(n, [dev_list_view] __device__ (int idx) mutable {
    size_t size = idx + 1;
    index_t offset = dev_list_view.Reserve(size);
    for (int i = 0; i < size; ++i) {
      dev_list_view[offset + i] = idx + 1;
    }
  });

  HList<int> host_list;
  dev_list.GetFromDevice(host_list);
  LOG(INFO) << "Final host_list size: " << host_list.size();
  ASSERT_EQ(host_list.size(), 65);

  for (int i = 0; i < host_list.size(); ++i) {
    LOG(INFO) << "host_list[" << i << "]: " << host_list[i];
  }
}
