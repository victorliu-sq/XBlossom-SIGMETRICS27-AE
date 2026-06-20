#include <benchmark/benchmark.h>
#include "common/dataset_config.h"
#include "common/macros.h"
#include <glog/logging.h>
#include "utils/mm_types_cpu.h"
#include "xblsm_cpu/xblsm_cpu.h"
#include "xblsm_cpu/xblsm_cpu_pro.h"
#include "xblsm_cpu/xblsm_cpu_config.h"

static bool LoadXGraphFromFiles(const std::string &rowOffsetsFilePath,
                                const std::string &columnIndicesFilePath,
                                xblossom::Graph &graph) {
  std::vector<int> rowOffsets;
  std::vector<int> columnIndices;
  xblossom::readFileIntoVector(rowOffsetsFilePath, rowOffsets);
  xblossom::readFileIntoVector(columnIndicesFilePath, columnIndices);

  graph = xblossom::Graph(rowOffsets, columnIndices);
  size_t nnodes = graph.num_of_nodes;
  size_t nedges = columnIndices.size() / 2;

  // std::cout << "The graph has " << nnodes << " nodes and " << nedges << " edges.\n";
  LOG(INFO) << "The graph has " << nnodes << " nodes and " << nedges << " edges.\n";

  return true;
}

template<class DatasetConfig>
class CpuEngineDatasetFixture : public benchmark::Fixture {
protected:
  void SetUp(const benchmark::State &) override {
    LoadXGraphFromFiles(DatasetConfig::PATH_ROW_OFFSETS,
                        DatasetConfig::PATH_COL_INDICES,
                        graph_);
    xblossom::nodes = graph_.num_of_nodes;
    xblossom::num_of_threads = 8;
    xblossom::count = 0;
  }

  void TearDown(const benchmark::State &) override {
  }

  xgraph_t graph_;
};

BENCHMARK_TEMPLATE_METHOD_F(CpuEngineDatasetFixture, RunXblossomCpuEnginePro)
(benchmark::State &state) {
  for (auto _: state) {
    Vector<int> matching(xblossom::nodes, -1);
    xblossom::testParBlossom_pro_all(this->graph_, matching, INT_MAX);

    // Extract per-phase timings
    double aug_ms, expand_ms, blossom_ms, total_ms;
    xblossom::GetTimingSummary(aug_ms, expand_ms, blossom_ms, total_ms);

    // Record them as counters
    state.counters["AugmentingPath_ms"] = aug_ms;
    state.counters["Expand_ms"]         = expand_ms;
    state.counters["Blossom_ms"]        = blossom_ms;
    state.counters["Total_ms"]          = total_ms;
  }
}

BENCHMARK_TEMPLATE_INSTANTIATE_F(CpuEngineDatasetFixture, RunXblossomCpuEnginePro, DatasetConfig<DatasetID::Amazon>);
BENCHMARK_TEMPLATE_INSTANTIATE_F(CpuEngineDatasetFixture, RunXblossomCpuEnginePro, DatasetConfig<DatasetID::GPlus>);
BENCHMARK_TEMPLATE_INSTANTIATE_F(CpuEngineDatasetFixture, RunXblossomCpuEnginePro, DatasetConfig<DatasetID::Hyperlink>);
BENCHMARK_TEMPLATE_INSTANTIATE_F(CpuEngineDatasetFixture, RunXblossomCpuEnginePro, DatasetConfig<DatasetID::Livejournal>);
BENCHMARK_TEMPLATE_INSTANTIATE_F(CpuEngineDatasetFixture, RunXblossomCpuEnginePro, DatasetConfig<DatasetID::Patent>);
BENCHMARK_TEMPLATE_INSTANTIATE_F(CpuEngineDatasetFixture, RunXblossomCpuEnginePro, DatasetConfig<DatasetID::Twitch>);
BENCHMARK_TEMPLATE_INSTANTIATE_F(CpuEngineDatasetFixture, RunXblossomCpuEnginePro, DatasetConfig<DatasetID::Stackoverflow>);
BENCHMARK_TEMPLATE_INSTANTIATE_F(CpuEngineDatasetFixture, RunXblossomCpuEnginePro, DatasetConfig<DatasetID::HiggsNets>);
BENCHMARK_TEMPLATE_INSTANTIATE_F(CpuEngineDatasetFixture, RunXblossomCpuEnginePro, DatasetConfig<DatasetID::Wikipedia>);
BENCHMARK_TEMPLATE_INSTANTIATE_F(CpuEngineDatasetFixture, RunXblossomCpuEnginePro, DatasetConfig<DatasetID::Youtube>);

BENCHMARK_MAIN_WITH_GLOG("benchmark_xb_cpu_pro");
