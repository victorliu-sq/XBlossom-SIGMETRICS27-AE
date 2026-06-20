#!/bin/bash
set -euo pipefail

# This script must be invoked from the project root:
#   ./expr/run_gpu_all_datasets.sh

# List of datasets
datasets=(
  gplus
#  stackoverflow
#  patent
#  livejournal
#  hyperlink
#  twitch
#  higgnets
#  wiki
#  amazon
#  youtube
)

# Paths relative to project root
BUILD_DIR=cmake-build-release/test/xbsm_gpu
BINARY=$BUILD_DIR/run_zblsm_gpu_10_by_dataset
METRICS_DIR=tmp/metrics

mkdir -p $METRICS_DIR

# Nsight Compute stall metrics (all major categories)
#STALL_METRICS="
#"
STALL_METRICS="l1tex__m_l1tex2xbar_req_cycles_stalled,\
l1tex__f_tex2sm_cycles_stalled,\
l1tex__texin_sm2tex_req_cycles_stalled"

#smsp__warp_issue_stalled.barrier,
#smsp__warp_issue_stalled.dispatch_stall,
#smsp__warp_issue_stalled.long_scoreboard,
#smsp__warp_issue_stalled.memory_dependency,
#smsp__warp_issue_stalled.membar,
#smsp__warp_issue_stalled.math_pipe_throttle,
#smsp__warp_issue_stalled.not_selected,
#smsp__warp_issue_stalled.short_scoreboard,
#smsp__warp_issue_stalled.tex_throttle,
#smsp__warp_issue_stalled.wait

for dataset in "${datasets[@]}"; do
  echo "=== Profiling dataset: $dataset ==="

  profiler_out="$METRICS_DIR/gpu_${dataset}_stalling.csv"

#  ncu --metrics $STALL_METRICS \
#      --csv \
#      --log-file "$profiler_out" \
#      $BINARY --dataset $dataset

  ncu --metrics $STALL_METRICS \
      --target-processes all \
      $BINARY --dataset $dataset

  echo "Results saved to $profiler_out"
  echo "--------------------------------"
done

echo "All datasets processed. Stall results are in $METRICS_DIR"