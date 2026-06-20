#!/bin/bash
set -euo pipefail

# This script must be invoked from the project root:
#   ./expr/run_all_cpu_stalls.sh

# List of DATASETS
DATASETS=(
  Amazon
  GPlus
  Hyperlink
  Livejournal
  HiggsNets
  Patent
  Stackoverflow
  Twitch
  Wikipedia
  Youtube
)

# Paths relative to project root
BINARY="build/bin/run_zblsm_gpu_10_by_dataset"
METRICS_DIR="data/xb_pp_metrics"
echo "BINARY is ${BINARY}"

mkdir -p $METRICS_DIR

for DATASET in "${DATASETS[@]}"; do
  FLAG_METRICS_FILE="$METRICS_DIR/gpu_inst_$DATASET.done"

#  if [[ -f $FLAG_METRICS_FILE ]]; then
#    echo "Dataset $DATASET is already processed"
#    continue
#  fi

  echo "=== Running dataset: $DATASET ==="

  OUTPUT_FILE="$METRICS_DIR/gpu_inst_${DATASET}.csv"

  if [[ ! -f ${BINARY} ]]; then
      echo "Binary does not exist"
      exit 1
  fi

  # Run perf for memory bandwidth estimation
  echo "Measuring count of executed instructions for $DATASET ..."
  sudo ncu --metrics sm__sass_thread_inst_executed.sum \
          --csv \
          $BINARY --dataset "$DATASET" \
          > $OUTPUT_FILE

  touch $FLAG_METRICS_FILE
  echo "--------------------------------"
done

echo "All GPU DATASETS processed (effective memory bandwidth analysis). Results are in $METRICS_DIR"

# -------------- Python Script ------------------------
#PY_SCRIPT="${EXPR_DIR}/profiling/gpu_warp_inst_aggregator.py"
#SUMMARY_FILE="${METRICS_DIR}/gpu_inst_all.txt"
#
#for DATASET in "${DATASETS[@]}"; do
#  OUTPUT_FILE="$METRICS_DIR/gpu_inst_${DATASET}.csv"
#  if [[ -f $OUTPUT_FILE ]]; then
#    echo "Aggregating results for $DATASET ..."
#    conda run -n xblossom-python --live-stream python3 "$PY_SCRIPT" "$OUTPUT_FILE" "$SUMMARY_FILE"
#    echo "--------------------------------"
#  fi
#done
#
#echo "All GPU DATASETS aggregated. Results are in $METRICS_DIR"

# -------------- Python Script ------------------------
PY_SCRIPT="${EXPR_DIR}/profiling/gpu_thread_inst_aggregator.py"
SUMMARY_FILE="${METRICS_DIR}/gpu_inst_all.txt"

: > $SUMMARY_FILE

for DATASET in "${DATASETS[@]}"; do
  OUTPUT_FILE="$METRICS_DIR/gpu_inst_${DATASET}.csv"
  if [[ -f $OUTPUT_FILE ]]; then
    echo "Aggregating results for $DATASET ..."
    conda run -n xblossom-python --live-stream python3 "$PY_SCRIPT" "$OUTPUT_FILE" "$SUMMARY_FILE"
    echo "--------------------------------"
  fi
done

echo "All GPU DATASETS aggregated. Results are in $METRICS_DIR"
