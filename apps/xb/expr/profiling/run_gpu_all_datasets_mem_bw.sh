#!/bin/bash
set -euo pipefail

# This script must be invoked from the project root:
#   ./expr/run_all_cpu_stalls.sh

# List of DATASETS
DATASETS=(
  Amazon
#  GPlus
#  Hyperlink
#  Livejournal
#  HiggsNets
#  Patent
#  Stackoverflow
#  Twitch
#  Wikipedia
#  Youtube
)

# Paths relative to project root
XB_PP_BIN="build/bin/run_xb_pp_by_dataset"
METRICS_DIR="tmp/xb_pp_metrics"
echo "XB_PP_BIN is ${XB_PP_BIN}"

mkdir -p $METRICS_DIR

for DATASET in "${DATASETS[@]}"; do
#  FLAG_METRICS_FILE="$METRICS_DIR/gpu_mem_bw_$DATASET.done"
#
#  if [[ -f $FLAG_METRICS_FILE ]]; then
#    echo "Dataset $DATASET is already processed"
#    continue
#  fi

  echo "=== Running dataset: $DATASET ==="

  OUTPUT_FILE="$METRICS_DIR/gpu_mem_bw_${DATASET}.csv"

  if [[ ! -f ${XB_PP_BIN} ]]; then
      echo "Binary does not exist"
      exit 1
  fi

  # Run perf for memory bandwidth estimation
  echo "Measuring memory bandwidth for $DATASET ..."
  ncu --metrics dram__bytes_read.sum \
          --csv \
          $XB_PP_BIN --dataset=$DATASET \
          > $OUTPUT_FILE

#  touch $FLAG_METRICS_FILE
  echo "--------------------------------"
done

echo "All GPU DATASETS processed (effective memory bandwidth analysis). Results are in $METRICS_DIR"

# -------------- Python Script ------------------------
PY_SCRIPT="expr/profiling/gpu_dram_bytes_read_aggregator.py"
SUMMARY_FILE="${METRICS_DIR}/_gpu_dram_bytes_summary.txt"

DATASETS=(
  Amazon
#  GPlus
#  Hyperlink
#  Livejournal
#  HiggsNets
#  Patent
#  Stackoverflow
#  Twitch
#  Wikipedia
#  Youtube
)

for DATASET in "${DATASETS[@]}"; do
  OUTPUT_FILE="$METRICS_DIR/gpu_mem_bw_${DATASET}.csv"
  echo "Try to find output file ${OUTPUT_FILE}"

  if [[ -f $OUTPUT_FILE ]]; then
    echo "Aggregating results for $DATASET ..."
#    conda run -n xblossom-python --live-stream python3 "$PY_SCRIPT" "$OUTPUT_FILE"
#    conda run -n xblossom-python --live-stream python3 "$PY_SCRIPT" "$OUTPUT_FILE" "$SUMMARY_FILE"
    python3 "$PY_SCRIPT" "$OUTPUT_FILE" "$SUMMARY_FILE"
    echo "--------------------------------"
  fi
done

echo "All GPU DATASETS aggregated. Results are in $METRICS_DIR"
