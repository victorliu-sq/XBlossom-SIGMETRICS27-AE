#include "gtest/gtest.h"
#include "xblsm_cpu/xblsm_cpu.h"
#include "xblsm_cpu/xblsm_cpu_pro.h"
#include "xblsm_cpu/xblsm_cpu_config.h"
#include "common/dataset_config.h"
#include "common/glog_guard.h"
#include "common/test_utils.h"
#include "utils/mm_types_cpu.h"

// -------------------------------------------------------------------------------
// Test Suite Setup
using glog_guard_t = zblossom::GlogGuardUptr;

std::string test_log_name = "xblsm_cpu_pro_engine_test";
glog_guard_t glog_guard;


// -------------------------------------------------------------------------------
// Test Environment
class TestEnvironment : public ::testing::Environment {
public:
  ~TestEnvironment() override = default;

  // Override this to define how to set up the environment.
  void SetUp() override {
    glog_guard = zblossom::CreateGlogGuard(test_log_name.c_str());
  }

  // Override this to define how to tear down the environment.
  void TearDown() override {}
};

// Register the environment before any tests run
::testing::Environment* const global_env =
  ::testing::AddGlobalTestEnvironment(new TestEnvironment);


// -------------------------------------------------------------------------------
// Test Fixture
class TestXBlsmProEngineFixture : public ::testing::Test {
protected:
  void SetUp() override {
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

  void TearDown() override {}
};

// The generic function provided to DispatchOnDataset
template <typename T>
static void RunXBlossomProOnDatasetConfig(T config) {
  // 1. Load the graph
  auto path_row_offsets = config.PATH_ROW_OFFSETS;
  auto path_column_indices = config.PATH_COL_INDICES;
  auto expected_matching_size = config.MATCHING_SIZE;

  xgraph_t graph(path_row_offsets, path_column_indices);

  // 2. Setup Execution Context
  size_t nnodes = graph.num_of_nodes;
  xblossom::nodes = graph.num_of_nodes;
  xblossom::num_of_threads = 8;
  xblossom::count = 0;

  // 3. Run XBlosom Algorithm
  Matching actual_matching(nnodes, -1);

  int threshold = INT_MAX;
  // xblossom::testParBlossom_200(graph, actual_matching, threshold);
  xblossom::testParBlossom_pro_peredge(graph, actual_matching, threshold);

  // Assert Invariants
  ASSERT_TRUE(ValidateMatchingCPU(actual_matching));
  ASSERT_EQ(expected_matching_size, GetActualMatchingSizeCPU(actual_matching));
}

// -------------------------------------------------------------------------------
// Test Cases
TEST_F(TestXBlsmProEngineFixture, TestLiveAmazon) {
  // Test Environment
  constexpr auto dataset_id = DatasetID::Amazon;
  DispatchFuncOnDataset(dataset_id, [&](auto config) {
    RunXBlossomProOnDatasetConfig(config);
  });
}

TEST_F(TestXBlsmProEngineFixture, TestGPlus) {
  constexpr auto dataset_id = DatasetID::GPlus;
  DispatchFuncOnDataset(dataset_id, [&](auto config) {
    RunXBlossomProOnDatasetConfig(config);
  });
}

TEST_F(TestXBlsmProEngineFixture, TestHyperlink) {
  constexpr auto dataset_id = DatasetID::Hyperlink;
  DispatchFuncOnDataset(dataset_id, [&](auto config) {
    RunXBlossomProOnDatasetConfig(config);
  });
}

TEST_F(TestXBlsmProEngineFixture, TestLivejournal) {
  constexpr auto dataset_id = DatasetID::Livejournal;
  DispatchFuncOnDataset(dataset_id, [&](auto config) {
    RunXBlossomProOnDatasetConfig(config);
  });
}

TEST_F(TestXBlsmProEngineFixture, TestPatent) {
  constexpr auto dataset_id = DatasetID::Patent;
  DispatchFuncOnDataset(dataset_id, [&](auto config) {
    RunXBlossomProOnDatasetConfig(config);
  });
}

TEST_F(TestXBlsmProEngineFixture, TestStackoverflow) {
  constexpr auto dataset_id = DatasetID::Stackoverflow;
  DispatchFuncOnDataset(dataset_id, [&](auto config) {
    RunXBlossomProOnDatasetConfig(config);
  });
}

TEST_F(TestXBlsmProEngineFixture, TestTwitch) {
  constexpr auto dataset_id = DatasetID::Twitch;
  DispatchFuncOnDataset(dataset_id, [&](auto config) {
    RunXBlossomProOnDatasetConfig(config);
  });
}

TEST_F(TestXBlsmProEngineFixture, TestHiggsNets) {
  constexpr auto dataset_id = DatasetID::HiggsNets;
  DispatchFuncOnDataset(dataset_id, [&](auto config) {
    RunXBlossomProOnDatasetConfig(config);
  });
}

TEST_F(TestXBlsmProEngineFixture, TestWikipedia) {
  constexpr auto dataset_id = DatasetID::Wikipedia;
  DispatchFuncOnDataset(dataset_id, [&](auto config) {
    RunXBlossomProOnDatasetConfig(config);
  });
}

TEST_F(TestXBlsmProEngineFixture, TestYoutube) {
  constexpr auto dataset_id = DatasetID::Youtube;
  DispatchFuncOnDataset(dataset_id, [&](auto config) {
    RunXBlossomProOnDatasetConfig(config);
  });
}