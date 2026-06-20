#include <benchmark/benchmark.h>
#include "common/dataset_config.h"
#include "common/macros.h"
#include <glog/logging.h>
#include "xbsm_gpu/xblossom_gpu_engine_10.h"
#include <cuda_runtime.h>

using xb_gpu_engine_t = zblossom::XBlossomGpuEngine10;

template<class DatasetConfig>
class GpuEngineDatasetFixture : public benchmark::Fixture {
protected:
  zgraph_t graph_ = zgraph_t(DatasetConfig::PATH_ROW_OFFSETS, DatasetConfig::PATH_COL_INDICES);
  static constexpr size_t path_buffer_ratio_ = DatasetConfig::PATH_BUFFER_RATIO;
};

BENCHMARK_TEMPLATE_METHOD_F(GpuEngineDatasetFixture, RunXblossomGpuEngine)
(benchmark::State &state) {
  for (auto _: state) {
    Matching initial_matching(this->graph_.nnodes, this->graph_.nnodes);
    xb_gpu_engine_t xb_engine(this->graph_, this->path_buffer_ratio_);
    auto result = xb_engine.FindMaximumMatch(initial_matching);

    // Extract timing info via the public method
    double aug_ms, expand_ms, blossom_ms, total_ms;
    xb_engine.GetTimingSummary(aug_ms, expand_ms, blossom_ms, total_ms);

    // Store them as counters
    state.counters["AugmentingPath_ms"] = aug_ms;
    state.counters["Expand_ms"]         = expand_ms;
    state.counters["Blossom_ms"]        = blossom_ms;
    state.counters["Total_ms"]          = total_ms;
  }
}

BENCHMARK_TEMPLATE_INSTANTIATE_F(GpuEngineDatasetFixture, RunXblossomGpuEngine, DatasetConfig<DatasetID::Amazon>);
BENCHMARK_TEMPLATE_INSTANTIATE_F(GpuEngineDatasetFixture, RunXblossomGpuEngine, DatasetConfig<DatasetID::GPlus>);
BENCHMARK_TEMPLATE_INSTANTIATE_F(GpuEngineDatasetFixture, RunXblossomGpuEngine, DatasetConfig<DatasetID::Hyperlink>);
BENCHMARK_TEMPLATE_INSTANTIATE_F(GpuEngineDatasetFixture, RunXblossomGpuEngine, DatasetConfig<DatasetID::Livejournal>);
BENCHMARK_TEMPLATE_INSTANTIATE_F(GpuEngineDatasetFixture, RunXblossomGpuEngine, DatasetConfig<DatasetID::Patent>);
BENCHMARK_TEMPLATE_INSTANTIATE_F(GpuEngineDatasetFixture, RunXblossomGpuEngine, DatasetConfig<DatasetID::Twitch>);
BENCHMARK_TEMPLATE_INSTANTIATE_F(GpuEngineDatasetFixture, RunXblossomGpuEngine, DatasetConfig<DatasetID::Stackoverflow>);
BENCHMARK_TEMPLATE_INSTANTIATE_F(GpuEngineDatasetFixture, RunXblossomGpuEngine, DatasetConfig<DatasetID::HiggsNets>);
BENCHMARK_TEMPLATE_INSTANTIATE_F(GpuEngineDatasetFixture, RunXblossomGpuEngine, DatasetConfig<DatasetID::Wikipedia>);
BENCHMARK_TEMPLATE_INSTANTIATE_F(GpuEngineDatasetFixture, RunXblossomGpuEngine, DatasetConfig<DatasetID::Youtube>);

BENCHMARK_MAIN_WITH_GLOG_GPU_INFO("benchmark_xb_gpu_10");
// BENCHMARK_MAIN();
