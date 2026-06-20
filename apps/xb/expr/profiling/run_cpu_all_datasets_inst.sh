#!/bin/bash
set -euo pipefail

# List of DATASETS
DATASETS=(
  amazon
  gplus
  stackoverflow
  patent
  livejournal
  hyperlink
  twitch
  higgnets
  wiki
  youtube
)

# Paths relative to project root
METRICS_DIR="${PROJECT_DIR}/data/metrics"
mkdir -p ${METRICS_DIR}

BINARY="${PROJECT_DIR}/bin/run_zblsm_cpu_by_dataset"
OUTPUT_FILE="${METRICS_DIR}/cpu_inst_all.txt"

# Clear or create the single output file
: > "$OUTPUT_FILE"
echo "Instruction Count Metrics" >> "$OUTPUT_FILE"

for DATASET in "${DATASETS[@]}"; do
  echo "=== Running dataset: $DATASET ==="


  if [[ ! -f ${BINARY} ]]; then
      echo "Binary does not exist"
      exit 1
  fi

  {
    echo "--------------------------------"
    echo "DATASET: $DATASET"
    perf stat \
      -x, \
      -e instructions \
      -- ${BINARY} --dataset "$DATASET" > /dev/null
    echo
  } >> "$OUTPUT_FILE" 2>&1
done

echo "All CPU DATASETS processed (retired instruction count). Results are in $METRICS_DIR"
