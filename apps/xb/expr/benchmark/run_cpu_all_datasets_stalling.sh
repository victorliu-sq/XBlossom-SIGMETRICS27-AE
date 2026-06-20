#!/bin/bash
set -euo pipefail

# This script must be invoked from the project root:
#   ./expr/run_all_cpu_stalls.sh

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
BUILD_DIR=cmake-build-release/test/xbsm_cpu
BINARY=$BUILD_DIR/run_zblsm_cpu_by_dataset
METRICS_DIR=tmp/metrics

mkdir -p $METRICS_DIR

for dataset in "${datasets[@]}"; do
  echo "=== Running dataset: $dataset ==="

  stall_out="$METRICS_DIR/cpu__stalls_tma_${dataset}.txt"

  # Run perf with TopdownL1 for stall breakdown
  echo "Profiling stalls for $dataset with perf ..."
  perf stat \
    -M TopdownL1 \
    -e cpu_core/cycles/ \
    -o "$stall_out" \
    -- $BINARY --dataset $dataset > /dev/null

  echo "--------------------------------"
done

echo "All CPU datasets processed (stalling analysis). Results are in $METRICS_DIR"
