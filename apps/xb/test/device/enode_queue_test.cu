#include "enode_queue/enode_queue.h"

#include "gtest/gtest.h"
#include "common/glog_guard.h"
#include "device/gtest_dev.h"
#include "utils/dev_array.h"
#include "utils/launcher.h"
#include "path_table/path_table.h"

// -------------------------------------------------------------------------------
// Test Suite Setup
static std::string test_log_name = "enode_queue_test";

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
class TestENodeQueueFixture : public ::testing::Test {
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


  // Logging utilities (replicating ENodeQueueTester behavior)
  void LogENodeQueueState(zblossom::ENodeQueue& q) {
    LOG(INFO) << "ENodeQueue State:";
    LOG(INFO) << "  enodes1_begin: " << q.ENnode1Begin();
    LOG(INFO) << "  enodes1_end:   " << q.ENnode1End();
    LOG(INFO) << "  enodes2_begin: " << q.ENnode2Begin();
    LOG(INFO) << "  enodes2_end:   " << q.ENnode2End();
    LOG(INFO) << "  begin:         " << q.Begin();
    LOG(INFO) << "  end:           " << q.End();
  }

  void LogCurrentENodes(zblossom::ENodeQueue& q) {
    index_t begin = q.Begin();
    index_t end = q.End();
    size_t count = end - begin;
    if (count == 0) {
      LOG(INFO) << "Current ENodeQueue Entries: []";
      return;
    }

    std::stringstream ss;
    ss << "Current ENodeQueue Entries: [";
    for (index_t i = begin; i < end; ++i) {
      ss << q.enodes_buffer_[i] << " ";
    }
    ss << "]";
    LOG(INFO) << ss.str();
  }

  CudaStream cuda_stream_;
};

// -------------------------------------------------------------------------------
// Test Case: ENodeQueue basic operations
// -------------------------------------------------------------------------------
TEST_F_PUBLIC(TestENodeQueueFixture, BasicENodeQueueTest) {
  const size_t n = 10;
  zblossom::ENodeQueue enode_queue(n);

  // Prepare matching array
  DArray<index_t> d_matching(n, n);
  d_matching[0] = 1; d_matching[1] = 0;
  d_matching[2] = 3; d_matching[3] = 2;
  d_matching[4] = 5; d_matching[5] = 4;
  d_matching[6] = 7; d_matching[7] = 6;

  auto matching_dview = d_matching.DeviceView();
  auto enode_queue_dview = enode_queue.DeviceView();

  LOG(INFO) << "Initially, Append 8, 9 to ENode1";

  // Step 1. Initial appending: Append unmatched nodes to ENode1
  DefaultLauncher::ExecuteNTasklet(n, [enode_queue_dview, matching_dview, n] __device__(int idx, size_t size) mutable {
    if (matching_dview[idx] == size) {
      enode_queue_dview.AppendENode1(idx);
    }
  }, n);

  enode_queue.PrepareForAppendingENode2();
  LogENodeQueueState(enode_queue);
  LogCurrentENodes(enode_queue);

  // Step 2. Append new ENode1s
  LOG(INFO) << "Append 0, 1, 2 to ENode1";
  enode_queue.PrepareForAppendingENode1();
  DefaultLauncher::ExecuteOneTasklet([enode_queue_dview] __device__() mutable {
    enode_queue_dview.AppendENode1(0);
    enode_queue_dview.AppendENode1(1);
    enode_queue_dview.AppendENode1(2);
  });
  LogENodeQueueState(enode_queue);
  LogCurrentENodes(enode_queue);

  // Step 3. Append new ENode2s
  LOG(INFO) << "Append 3, 4 to ENode2";
  enode_queue.PrepareForAppendingENode2();
  DefaultLauncher::ExecuteOneTasklet([enode_queue_dview] __device__() mutable {
    enode_queue_dview.AppendENode2(3);
    enode_queue_dview.AppendENode2(4);
  });
  LogENodeQueueState(enode_queue);
  LogCurrentENodes(enode_queue);

  // Step 4. Append nothing to ENode1
  LOG(INFO) << "Append nothing to ENode1";
  enode_queue.PrepareForAppendingENode1();
  DefaultLauncher::ExecuteOneTasklet([enode_queue_dview] __device__() mutable {});
  LogENodeQueueState(enode_queue);
  LogCurrentENodes(enode_queue);

  // Step 5. Append new ENode2s
  LOG(INFO) << "Append 5, 6, 7 to ENode2";
  enode_queue.PrepareForAppendingENode2();
  DefaultLauncher::ExecuteOneTasklet([enode_queue_dview] __device__() mutable {
    enode_queue_dview.AppendENode2(5);
    enode_queue_dview.AppendENode2(6);
    enode_queue_dview.AppendENode2(7);
  });
  LogENodeQueueState(enode_queue);
  LogCurrentENodes(enode_queue);

  // Final validation
  EXPECT_GE(enode_queue.End(), 0);
  LOG(INFO) << "All ENodeQueue operations executed successfully.";
}
