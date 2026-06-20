#!/bin/bash
set -euo pipefail

# This script must be invoked from the project root:
#   ./expr/run_all_cpu_datasets.sh

# List of datasets
datasets=(
  gplus
  stackoverflow
  patent
  livejournal
  hyperlink
  twitch
  higgnets
  wiki
  amazon
  youtube
)

# Paths relative to project root
BUILD_DIR=cmake-build-release/test/mm
BINARY=$BUILD_DIR/run_zblsm_cpu_by_dataset
METRICS_DIR=tmp/metrics
PYTHON_SCRIPT=expr/visualize/analyze_cpu_profile.py

mkdir -p $METRICS_DIR

for dataset in "${datasets[@]}"; do
  echo "=== Running dataset: $dataset ==="

  profiler_out="$METRICS_DIR/cpu_${dataset}_profiling.txt"
  timing_out="$METRICS_DIR/cpu_${dataset}_timing.txt"

  # Step 1: Run for timing info
  echo "Running $dataset for timing ..."
  $BINARY --dataset $dataset > "$timing_out"

  # Step 2: Profiling with perf
  echo "Profiling $dataset with perf ..."
  perf stat \
    -e instructions \
    -e branches \
    -e cpu_core/mem_inst_retired.all_stores/ \
    -e cpu_core/mem_inst_retired.all_loads/ \
    -o "$profiler_out" \
    -- $BINARY --dataset $dataset > /dev/null

  # Step 3: Analyze with Python script
  echo "Analyzing results for $dataset ..."
  python3 $PYTHON_SCRIPT $dataset "$profiler_out" "$timing_out"

  echo "--------------------------------"
done

echo "All CPU datasets processed. Results are in $METRICS_DIR"
