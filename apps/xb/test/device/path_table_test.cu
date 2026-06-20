#include "gtest/gtest.h"
#include "common/glog_guard.h"
#include "device/gtest_dev.h"
#include "path_table/path_table.h"
#include "utils/types_gpu.h"
#include "utils/dev_array.h"
#include "utils/launcher.h"

// -------------------------------------------------------------------------------
// Test Suite Setup
static std::string test_log_name = "path_table_test";

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
// -------------------------------------------------------------------------------
class TestPathTableFixture : public ::testing::Test {
protected:
  void SetUp() override {
    auto info = ::testing::UnitTest::GetInstance()->current_test_info();
    std::string test_suite = info->test_suite_name();
    std::string test_name = info->name();
    std::string prefix = g_glog_guard->LogDir() + "/log-" + test_suite + "-" + test_name;

    google::SetLogDestination(google::INFO, (prefix + ".INFO.").c_str());
    google::SetLogDestination(google::WARNING, (prefix + ".WARNING.").c_str());
    google::SetLogDestination(google::ERROR, (prefix + ".ERROR.").c_str());
    google::SetLogDestination(google::FATAL, (prefix + ".FATAL.").c_str());
  }

  // ---------------------------------------------------------------------------
  // Protected accessors to internal arrays of PathTable
  // ---------------------------------------------------------------------------
  static DArray<index_t>& RootDistance(zblossom::dev::PathTable& pt) {
    return pt.root_distance_;
  }

  static DArray<DPair<index_t, size_t>>& OffsetLength(zblossom::dev::PathTable& pt) {
    return pt.offset_length_;
  }

  // ---------------------------------------------------------------------------
  // Utility: copy device array to host and log
  // ---------------------------------------------------------------------------
  template<typename T>
  static HVector<T> GetAndLog(const DArray<T>& darr, const std::string& name) {
    HVector<T> host;
    darr.GetFromDevice(host);
    LOG(INFO) << name << ":";
    for (size_t i = 0; i < host.size(); ++i)
      LOG(INFO) << "  [" << i << "] = " << host[i];
    return host;
  }
};

// -------------------------------------------------------------------------------
// TEST GRAPH 1
// -------------------------------------------------------------------------------
TEST_F_PUBLIC(TestPathTableFixture, ExpandTwoNodesForGraph1) {
  const size_t nnnodes = 8;
  zblossom::dev::PathTable path_table(nnnodes);
  path_table.ResetPathTable();
  auto dview = path_table.DeviceView();

  DefaultLauncher::ExecuteOneTasklet([dview] __device__() mutable {
    dview.ExpandTwoNodes(0, 1, 2);
    dview.ExpandTwoNodes(0, 3, 4);
    dview.ExpandTwoNodes(4, 5, 6);
  });

  auto host_root_distance = GetAndLog(RootDistance(path_table), "Root Distances");
  EXPECT_EQ(host_root_distance[0], 0);
  EXPECT_EQ(host_root_distance[2], 2);
  EXPECT_EQ(host_root_distance[4], 2);
  EXPECT_EQ(host_root_distance[6], 4);

  HArray<DPair<index_t, size_t>> host_offset_length;
  OffsetLength(path_table).GetFromDevice(host_offset_length);
  for (size_t i = 0; i < host_offset_length.size(); ++i) {
    LOG(INFO) << "Node[" << i << "]: Offset = " << host_offset_length[i].first
              << ", Length = " << host_offset_length[i].second;
  }
  EXPECT_EQ(host_offset_length[6].second, 2);

  // Prepare matching array
  DArray<index_t> matching_dev(nnnodes, nnnodes);
  matching_dev[1] = 2; matching_dev[2] = 1;
  matching_dev[3] = 4; matching_dev[4] = 3;
  matching_dev[5] = 6; matching_dev[6] = 5;

  DefaultLauncher::ExecuteOneTasklet([dview, matching = matching_dev.DeviceView()] __device__() mutable {
    dview.AddAugmentingPath(6, 7, matching);
  });

  auto matching_host = GetAndLog(matching_dev, "Matching");
  EXPECT_EQ(matching_host[0], 3);
  EXPECT_EQ(matching_host[3], 0);
  EXPECT_EQ(matching_host[1], 2);
  EXPECT_EQ(matching_host[2], 1);
  EXPECT_EQ(matching_host[4], 5);
  EXPECT_EQ(matching_host[5], 4);
  EXPECT_EQ(matching_host[6], 7);
  EXPECT_EQ(matching_host[7], 6);
}

// -------------------------------------------------------------------------------
// TEST GRAPH 2
// -------------------------------------------------------------------------------
TEST_F_PUBLIC(TestPathTableFixture, ExpandTwoNodesForGraph2) {
  const size_t nnnodes = 19;
  zblossom::dev::PathTable path_table(nnnodes);
  path_table.ResetPathTable();
  auto dview = path_table.DeviceView();

  DefaultLauncher::ExecuteOneTasklet([dview] __device__() mutable {
    dview.ExpandTwoNodes(0, 1, 2);
    dview.ExpandTwoNodes(2, 3, 4);
    dview.ExpandTwoNodes(2, 5, 6);
    dview.ExpandTwoNodes(4, 7, 8);
    dview.ExpandTwoNodes(8, 9, 10);
    dview.ExpandTwoNodes(8, 11, 12);
    dview.ExpandTwoNodes(6, 13, 14);
    dview.ExpandTwoNodes(6, 15, 16);
    dview.ExpandTwoNodes(16, 17, 18);
  });

  auto host_root_distance = GetAndLog(RootDistance(path_table), "Root Distances");
  EXPECT_EQ(host_root_distance[0], 0);
  EXPECT_EQ(host_root_distance[2], 2);
  EXPECT_EQ(host_root_distance[4], 4);
  EXPECT_EQ(host_root_distance[6], 4);
  EXPECT_EQ(host_root_distance[8], 6);
  EXPECT_EQ(host_root_distance[10], 8);
  EXPECT_EQ(host_root_distance[12], 8);
  EXPECT_EQ(host_root_distance[18], 8);

  DefaultLauncher::ExecuteOneTasklet([dview] __device__() mutable {
    index_t blossom_offset; size_t blossom_length; index_t v_idx;
    dview.FindAndAddBlossomImplicit(10, 12, blossom_offset, blossom_length, v_idx);
    dview.ExpandNodesFromBlossomRightwardsTillV(blossom_offset, blossom_length, v_idx);
    dview.FindAndAddBlossomImplicit(12, 10, blossom_offset, blossom_length, v_idx);
    dview.ExpandNodesFromBlossomRightwardsTillV(blossom_offset, blossom_length, v_idx);
    dview.FindAndAddBlossomImplicit(14, 18, blossom_offset, blossom_length, v_idx);
    dview.ExpandNodesFromBlossomRightwardsTillV(blossom_offset, blossom_length, v_idx);
    dview.FindAndAddBlossomImplicit(18, 14, blossom_offset, blossom_length, v_idx);
    dview.ExpandNodesFromBlossomRightwardsTillV(blossom_offset, blossom_length, v_idx);
    dview.FindAndAddBlossomImplicit(11, 17, blossom_offset, blossom_length, v_idx);
    dview.ExpandNodesFromBlossomRightwardsTillV(blossom_offset, blossom_length, v_idx);
    dview.FindAndAddBlossomImplicit(17, 11, blossom_offset, blossom_length, v_idx);
    dview.ExpandNodesFromBlossomRightwardsTillV(blossom_offset, blossom_length, v_idx);
  });

  GetAndLog(RootDistance(path_table), "Root Distances (After Blossoms)");
}

// -------------------------------------------------------------------------------
// TEST GRAPH 3
// -------------------------------------------------------------------------------
TEST_F_PUBLIC(TestPathTableFixture, ExpandTwoNodesForGraph3) {
  const size_t nnnodes = 5;
  zblossom::dev::PathTable path_table(nnnodes);
  path_table.ResetPathTable();
  auto dview = path_table.DeviceView();

  DefaultLauncher::ExecuteOneTasklet([dview] __device__() mutable {
    dview.ExpandTwoNodes(0, 1, 2);
    dview.ExpandTwoNodes(2, 3, 4);
  });

  auto host_root_distance = GetAndLog(RootDistance(path_table), "Root Distances");
  EXPECT_EQ(host_root_distance[0], 0);
  EXPECT_EQ(host_root_distance[2], 2);
  EXPECT_EQ(host_root_distance[4], 4);

  DefaultLauncher::ExecuteOneTasklet([dview] __device__() mutable {
    index_t blossom_offset; size_t blossom_length; index_t v_idx;
    dview.FindAndAddBlossomImplicit(0, 4, blossom_offset, blossom_length, v_idx);
    dview.ExpandNodesFromBlossomRightwardsTillV(blossom_offset, blossom_length, v_idx);
    dview.FindAndAddBlossomImplicit(4, 0, blossom_offset, blossom_length, v_idx);
    dview.ExpandNodesFromBlossomRightwardsTillV(blossom_offset, blossom_length, v_idx);
  });

  GetAndLog(OffsetLength(path_table), "Offset-Length");
  GetAndLog(RootDistance(path_table), "Root Distances (Final)");
}

// -------------------------------------------------------------------------------
// TEST GRAPH 4
// -------------------------------------------------------------------------------
TEST_F_PUBLIC(TestPathTableFixture, ExpandTwoNodesForGraph4) {
  const size_t nnnodes = 7;
  zblossom::dev::PathTable path_table(nnnodes);
  path_table.ResetPathTable();
  auto dview = path_table.DeviceView();

  DefaultLauncher::ExecuteOneTasklet([dview] __device__() mutable {
    dview.ExpandTwoNodes(0, 1, 2);
    dview.ExpandTwoNodes(2, 3, 4);
    dview.ExpandTwoNodes(2, 5, 6);
  });

  auto host_root_distance = GetAndLog(RootDistance(path_table), "Root Distances");
  EXPECT_EQ(host_root_distance[0], 0);
  EXPECT_EQ(host_root_distance[2], 2);
  EXPECT_EQ(host_root_distance[4], 4);
  EXPECT_EQ(host_root_distance[6], 4);

  DefaultLauncher::ExecuteOneTasklet([dview] __device__() mutable {
    index_t blossom_offset; size_t blossom_length; index_t v_idx;
    dview.FindAndAddBlossomImplicit(4, 6, blossom_offset, blossom_length, v_idx);
    dview.ExpandNodesFromBlossomRightwardsTillV(blossom_offset, blossom_length, v_idx);
    dview.FindAndAddBlossomImplicit(6, 4, blossom_offset, blossom_length, v_idx);
    dview.ExpandNodesFromBlossomRightwardsTillV(blossom_offset, blossom_length, v_idx);
  });

  GetAndLog(OffsetLength(path_table), "Offset-Length");
  GetAndLog(RootDistance(path_table), "Root Distances (Final)");
}

// -------------------------------------------------------------------------------
// TEST GRAPH 5
// -------------------------------------------------------------------------------
TEST_F_PUBLIC(TestPathTableFixture, ExpandTwoNodesForGraph5) {
  const size_t nnnodes = 7;
  zblossom::dev::PathTable path_table(nnnodes);
  path_table.ResetPathTable();
  auto dview = path_table.DeviceView();

  DefaultLauncher::ExecuteOneTasklet([dview] __device__() mutable {
    dview.ExpandTwoNodes(0, 1, 2);
    dview.ExpandTwoNodes(2, 3, 4);
    dview.ExpandTwoNodes(0, 5, 6);
  });

  auto host_root_distance = GetAndLog(RootDistance(path_table), "Root Distances");
  EXPECT_EQ(host_root_distance[0], 0);
  EXPECT_EQ(host_root_distance[2], 2);
  EXPECT_EQ(host_root_distance[4], 4);
  EXPECT_EQ(host_root_distance[6], 2);

  DefaultLauncher::ExecuteOneTasklet([dview] __device__() mutable {
    index_t blossom_offset; size_t blossom_length; index_t v_idx;
    dview.FindAndAddBlossomImplicit(4, 6, blossom_offset, blossom_length, v_idx);
    dview.ExpandNodesFromBlossomRightwardsTillV(blossom_offset, blossom_length, v_idx);
    dview.FindAndAddBlossomImplicit(6, 4, blossom_offset, blossom_length, v_idx);
    dview.ExpandNodesFromBlossomRightwardsTillV(blossom_offset, blossom_length, v_idx);
  });

  GetAndLog(OffsetLength(path_table), "Offset-Length");
  GetAndLog(RootDistance(path_table), "Root Distances (Final)");
}
