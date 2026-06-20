#!/bin/bash
set -euo pipefail

# This script must be invoked from the project root:
#   ./expr/run_all_cpu_stalls.sh

# List of DATASETS
DATASETS=(
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
BINARY="${PROJECT_DIR}/bin/run_zblsm_cpu_by_dataset"
METRICS_DIR="${PROJECT_DIR}/tmp/metrics"
echo "BINARY is ${BINARY}"

mkdir -p $METRICS_DIR

for DATASET in "${DATASETS[@]}"; do
  echo "=== Running dataset: $DATASET ==="

  BW_OUT="$METRICS_DIR/cpu_mem_bw_${DATASET}.txt"

  if [[ ! -f ${BINARY} ]]; then
      echo "Binary does not exist"
  else
    # Run perf for memory bandwidth estimation
    echo "Measuring memory bandwidth for $DATASET ..."
    perf stat \
      -x, \
      -e cache-misses \
      -o "$BW_OUT" \
      -- ${BINARY} --dataset $DATASET > /dev/null
  fi
  echo "--------------------------------"
done

echo "All CPU DATASETS processed (effective memory bandwidth analysis). Results are in $METRICS_DIR"
