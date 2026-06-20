#include "xbsm_gpu/xblossom_gpu_engine_10.h"
#include "gtest/gtest.h"
#include "common/dataset_config.h"
#include "common/glog_guard.h"
#include "common/test_utils.h"

// -------------------------------------------------------------------------------
// Test Suite Setup
using xb_engine_t = zblossom::XBlossomGpuEngine10;
using glog_guard_t = zblossom::GlogGuardUptr;

std::string test_log_name = "xblsm_gpu_engine_10_test";
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
class TestXBlsmGpuEngine10Fixture : public ::testing::Test {
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
static void RunXBlossomGPUOnDatasetConfig(T config) {
  auto path_row_offsets = config.PATH_ROW_OFFSETS;
  auto path_column_indices = config.PATH_COL_INDICES;
  auto path_table_buffer_ratio = config.PATH_BUFFER_RATIO;
  auto expected_matching_size = config.MATCHING_SIZE;

  zgraph_t graph(path_row_offsets, path_column_indices);
  Matching initial_matching(graph.nnodes, graph.nnodes);
  xb_engine_t xb_engine(graph, path_table_buffer_ratio);

  // Run XBlosom Algorithm
  auto matching = xb_engine.FindMaximumMatch(initial_matching);

  // Assert Invariants
  ASSERT_TRUE(ValidateMatchingGPU(matching));
  ASSERT_EQ(expected_matching_size, GetActualMatchingSizeGPU(matching));
}

// -------------------------------------------------------------------------------
// Test Cases
TEST_F(TestXBlsmGpuEngine10Fixture, TestLiveAmazon) {
  // Test Environment
  constexpr auto dataset_id = DatasetID::Amazon;
  DispatchFuncOnDataset(dataset_id, [&](auto config) {
    RunXBlossomGPUOnDatasetConfig(config);
  });
}

TEST_F(TestXBlsmGpuEngine10Fixture, TestGPlus) {
  constexpr auto dataset_id = DatasetID::GPlus;
  DispatchFuncOnDataset(dataset_id, [&](auto config) {
    RunXBlossomGPUOnDatasetConfig(config);
  });
}

TEST_F(TestXBlsmGpuEngine10Fixture, TestHyperlink) {
  constexpr auto dataset_id = DatasetID::Hyperlink;
  DispatchFuncOnDataset(dataset_id, [&](auto config) {
    RunXBlossomGPUOnDatasetConfig(config);
  });
}

TEST_F(TestXBlsmGpuEngine10Fixture, TestLivejournal) {
  constexpr auto dataset_id = DatasetID::Livejournal;
  DispatchFuncOnDataset(dataset_id, [&](auto config) {
    RunXBlossomGPUOnDatasetConfig(config);
  });
}

TEST_F(TestXBlsmGpuEngine10Fixture, TestPatent) {
  constexpr auto dataset_id = DatasetID::Patent;
  DispatchFuncOnDataset(dataset_id, [&](auto config) {
    RunXBlossomGPUOnDatasetConfig(config);
  });
}

TEST_F(TestXBlsmGpuEngine10Fixture, TestStackoverflow) {
  constexpr auto dataset_id = DatasetID::Stackoverflow;
  DispatchFuncOnDataset(dataset_id, [&](auto config) {
    RunXBlossomGPUOnDatasetConfig(config);
  });
}

TEST_F(TestXBlsmGpuEngine10Fixture, TestTwitch) {
  constexpr auto dataset_id = DatasetID::Twitch;
  DispatchFuncOnDataset(dataset_id, [&](auto config) {
    RunXBlossomGPUOnDatasetConfig(config);
  });
}

TEST_F(TestXBlsmGpuEngine10Fixture, TestHiggsNets) {
  constexpr auto dataset_id = DatasetID::HiggsNets;
  DispatchFuncOnDataset(dataset_id, [&](auto config) {
    RunXBlossomGPUOnDatasetConfig(config);
  });
}

TEST_F(TestXBlsmGpuEngine10Fixture, TestWikipedia) {
  constexpr auto dataset_id = DatasetID::Wikipedia;
  DispatchFuncOnDataset(dataset_id, [&](auto config) {
    RunXBlossomGPUOnDatasetConfig(config);
  });
}

TEST_F(TestXBlsmGpuEngine10Fixture, TestYoutube) {
  constexpr auto dataset_id = DatasetID::Youtube;
  DispatchFuncOnDataset(dataset_id, [&](auto config) {
    RunXBlossomGPUOnDatasetConfig(config);
  });
}

// TEST_F(TestXBlsmGpuEngine10Fixture, TestRandomN10M_D8) {
//   constexpr auto dataset_id = DatasetID::Random_N10M_D8;
//   DispatchFuncOnDataset(dataset_id, [&](auto config) {
//     RunXBlossomGPUOnDatasetConfig(config);
//   });
// }
