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
PYTHON_SCRIPT=expr/visualize/analyze_gpu_profile.py

mkdir -p $METRICS_DIR

for dataset in "${datasets[@]}"; do
  echo "=== Running dataset: $dataset ==="

  profiler_out="$METRICS_DIR/gpu_${dataset}_profiling.csv"
  timing_out="$METRICS_DIR/gpu_${dataset}_timing.txt"
  result_out="$METRICS_DIR/gpu_${dataset}_results.txt"

  # Step 1: Profiling with Nsight Compute
  echo "Profiling $dataset ..."
  ncu --metrics sm__sass_thread_inst_executed_op_integer_pred_on.sum \
      --csv \
      --log-file "$profiler_out" \
      $BINARY --dataset $dataset > /dev/null

  # Step 2: Run for timing info
  echo "Running $dataset for timing ..."
  $BINARY --dataset $dataset > "$timing_out"

  # Step 3: Analyze with Python script
  echo "Analyzing results for $dataset ..."
  python3 $PYTHON_SCRIPT $dataset "$profiler_out" "$timing_out" "$result_out"

  echo "Results saved to $result_out"
  echo "--------------------------------"
done

echo "All datasets processed. Results are in $METRICS_DIR"
