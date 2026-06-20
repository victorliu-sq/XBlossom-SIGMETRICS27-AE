#include "gtest/gtest.h"
#include "common/glog_guard.h"
#include "device/gtest_dev.h"
#include "utils/dev_array.h"
#include "utils/launcher.h"
#include "utils/cuda_algo.h"

// -------------------------------------------------------------------------------
// Test Suite Setup
static std::string test_log_name = "scan_test";

// -------------------------------------------------------------------------------
// Glog Wrapper
using glog_guard_t = zblossom::GlogGuard;
static std::unique_ptr<glog_guard_t> glog_guard;

// -------------------------------------------------------------------------------
// Test Environment
class TestEnvironment : public ::testing::Environment {
public:
  ~TestEnvironment() override {}

  // Override this to define how to set up the environment.
  void SetUp() override {
    glog_guard = std::make_unique<glog_guard_t>(test_log_name.c_str());
  }

  // Override this to define how to tear down the environment.
  void TearDown() override {}
};

// Register the environment before any tests run
::testing::Environment* const global_env =
  ::testing::AddGlobalTestEnvironment(new TestEnvironment);


// -------------------------------------------------------------------------------
// Test Fixture
class TestScanFixture : public ::testing::Test {
protected:
  virtual void SetUp() {
    auto info = ::testing::UnitTest::GetInstance()->current_test_info();
    std::string test_suite = info->test_suite_name();
    std::string test_name = info->name();
    std::string prefix = glog_guard->LogDir() + "/log-" + test_suite + "-" + test_name;

    // Redirect log output to per-test files
    google::SetLogDestination(google::INFO, (prefix + ".INFO.").c_str());
    google::SetLogDestination(google::WARNING, (prefix + ".WARNING.").c_str());
    google::SetLogDestination(google::ERROR, (prefix + ".ERROR.").c_str());
    google::SetLogDestination(google::FATAL, (prefix + ".FATAL.").c_str());
  }

  virtual void TearDown() {}

};

TEST_F_PUBLIC(TestScanFixture, BasicScanBSTest5N15E) {
  const size_t num_nodes = 5;
  const size_t exp_num_tasklets = 15;
  const size_t n = 5;
  DArray<index_t> node_ids(num_nodes);
  DArray<index_t> num_edges(num_nodes);
  DArray<index_t> scan_results(num_nodes + 1);

  DArray<index_t> tasklet_node_ids(exp_num_tasklets);
  DArray<index_t> tasklet_edge_ids(exp_num_tasklets);

  node_ids[0] = 1;
  node_ids[1] = 2;
  node_ids[2] = 3;
  node_ids[3] = 4;
  node_ids[4] = 5;

  num_edges[0] = 5;
  num_edges[1] = 4;
  num_edges[2] = 3;
  num_edges[3] = 2;
  num_edges[4] = 1;

  LOG(INFO) << "NodeID: # of Edges\n" << num_edges;

  // -------------------------------------------------------------------------
  // Run Scan
  simple_exclusive_scan(num_edges.begin(), num_edges.end(), scan_results.begin());
  LOG(INFO) << "Presum:\n" << scan_results;

  size_t act_num_tasklets = scan_results[n];

  // -------------------------------------------------------------------------
  // Test Scan
  ASSERT_EQ(exp_num_tasklets, act_num_tasklets);

  // -------------------------------------------------------------------------
  // Run Binary Search
  LOG(INFO) << "Total number of edges / tasklets: \n" << scan_results[n];

  // Prepare device views
  auto node_ids_dview = node_ids.DeviceView();
  auto scan_results_dview = scan_results.DeviceView();
  auto tasklet_node_id_dview = tasklet_node_ids.DeviceView();
  auto tasklet_edge_id_dview = tasklet_edge_ids.DeviceView();

  // Launch the kernel
  DefaultLauncher::ExecuteNTasklet(act_num_tasklets, [=] __device__(size_t tid) mutable {
    index_t value_idx = FindRightmostLTEQ(scan_results_dview, n, tid);
    index_t delta = tid - scan_results_dview[value_idx];
    tasklet_node_id_dview[tid] = node_ids_dview[value_idx];
    tasklet_edge_id_dview[tid] = delta;
  });

  // -------------------------------------------------------------------------
  // Test Binary Search
  LOG(INFO) << "tasklet_node_ids:\n" << tasklet_node_ids;
  LOG(INFO) << "tasklet_edge_id:\n" << tasklet_edge_ids;


  size_t offset = 0;
  for (size_t node = 0; node < num_nodes; ++node) {
    index_t nid = node_ids[node];
    index_t num_edges_for_node = num_edges[node];

    for (index_t e = 0; e < num_edges_for_node; ++e) {
      size_t tid = offset + e;
      EXPECT_EQ(tasklet_node_ids[tid], nid)
          << "Mismatch at tid=" << tid << ": expected nid=" << nid
          << ", got " << tasklet_node_ids[tid];
      EXPECT_EQ(tasklet_edge_ids[tid], e)
          << "Mismatch at tid=" << tid << ": expected eid=" << e
          << ", got " << tasklet_edge_ids[tid];
    }

    offset += num_edges_for_node;
  }

  LOG(INFO) << "All tasklet (nid, eid) pairs verified successfully.";
}

TEST_F_PUBLIC(TestScanFixture, BasicScanAdvBSTest5N15E) {
  const size_t num_nodes = 5;
  const size_t exp_num_tasklets = 15;
  const size_t n = 5;
  DArray<index_t> node_ids(num_nodes);
  DArray<index_t> num_edges(num_nodes);
  DArray<index_t> scan_results(num_nodes + 1);

  DArray<index_t> tasklet_node_ids(exp_num_tasklets);
  DArray<index_t> tasklet_edge_ids(exp_num_tasklets);

  node_ids[0] = 1;
  node_ids[1] = 2;
  node_ids[2] = 3;
  node_ids[3] = 4;
  node_ids[4] = 5;

  num_edges[0] = 5;
  num_edges[1] = 4;
  num_edges[2] = 3;
  num_edges[3] = 2;
  num_edges[4] = 1;

  LOG(INFO) << "NodeID: # of Edges\n" << num_edges;

  // -------------------------------------------------------------------------
  // Run Scan
  simple_exclusive_scan(num_edges.begin(), num_edges.end(), scan_results.begin());
  LOG(INFO) << "Presum:\n" << scan_results;

  size_t act_num_tasklets = scan_results[n];

  // -------------------------------------------------------------------------
  // Test Scan
  ASSERT_EQ(exp_num_tasklets, act_num_tasklets);

  // -------------------------------------------------------------------------
  // Run Binary Search
  LOG(INFO) << "Total number of edges / tasklets: \n" << scan_results[n];

  // Prepare device views
  auto node_ids_dview = node_ids.DeviceView();
  auto scan_results_dview = scan_results.DeviceView();
  auto tasklet_node_id_dview = tasklet_node_ids.DeviceView();
  auto tasklet_edge_id_dview = tasklet_edge_ids.DeviceView();

  // Launch the kernel
  DefaultLauncher::ExecuteNTasklet(act_num_tasklets, [=] __device__(size_t tid) mutable {
    index_t value_idx = RightmostLTEQ(scan_results_dview, n, tid);
    index_t delta = tid - scan_results_dview[value_idx];
    tasklet_node_id_dview[tid] = node_ids_dview[value_idx];
    tasklet_edge_id_dview[tid] = delta;
  });

  // -------------------------------------------------------------------------
  // Test Binary Search
  LOG(INFO) << "tasklet_node_ids:\n" << tasklet_node_ids;
  LOG(INFO) << "tasklet_edge_id:\n" << tasklet_edge_ids;


  size_t offset = 0;
  for (size_t node = 0; node < num_nodes; ++node) {
    index_t nid = node_ids[node];
    index_t num_edges_for_node = num_edges[node];

    for (index_t e = 0; e < num_edges_for_node; ++e) {
      size_t tid = offset + e;
      EXPECT_EQ(tasklet_node_ids[tid], nid)
          << "Mismatch at tid=" << tid << ": expected nid=" << nid
          << ", got " << tasklet_node_ids[tid];
      EXPECT_EQ(tasklet_edge_ids[tid], e)
          << "Mismatch at tid=" << tid << ": expected eid=" << e
          << ", got " << tasklet_edge_ids[tid];
    }

    offset += num_edges_for_node;
  }

  LOG(INFO) << "All tasklet (nid, eid) pairs verified successfully.";
}
