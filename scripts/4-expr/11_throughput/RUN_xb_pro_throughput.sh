#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

XB_PRO_BIN="${XB_BIN_DIR}/run_xb_pro_by_dataset"
METRICS_DIR="${PROJECT_DIR}/tmp/11_throughput/xb_pro"
RESULTS_DIR="${PROJECT_DIR}/results/11_throughput"
STAMP="${RESULTS_DIR}/.stamp.throughput_xb_pro"
ANALYZE_SCRIPT="${SCRIPT_DIR}/analyze_xb_throughput.sh"
SUMMARY_CSV_TEMP="${METRICS_DIR}/_xb_pro_throughput_summary.csv"
SUMMARY_CSV="${RESULTS_DIR}/throughput_xb_pro.csv"
# RUN MODE: quick-check uses 2 rounds so scripts finish quickly.
# RUN MODE: analysis uses ROUNDS="${ROUNDS:-20}" for final reported results.
# To switch modes, comment the quick-check line and uncomment the analysis line.
# ROUNDS="${ROUNDS:-20}"
ROUNDS="${ROUNDS:-2}"
XB_PRO_THREADS="${XB_PRO_THREADS:-$(default_xb_pro_threads)}"

if [[ -f "$STAMP" ]]; then
  echo "Experiment 11 XB-Pro throughput already generated (stamp found)"
  exit 0
fi

require_executable "$XB_PRO_BIN" "XB-Pro binary"
rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR" "$RESULTS_DIR"

for entry in "${DATASET_CSR_LIST[@]}"; do
  IFS='|' read -r DATASET ROW_OFFSETS COL_INDICES PATH_BUFFER_RATIO <<< "$entry"
  TIMING_OUT="${METRICS_DIR}/xb_pro_${DATASET}_throughput.txt"
  : > "$TIMING_OUT"

  echo "Running XB-Pro throughput on ${DATASET} (${ROUNDS} rounds, ${XB_PRO_THREADS} threads)..."
  "$XB_PRO_BIN" \
      --dataset="$DATASET" \
      --rounds="$ROUNDS" \
      --num_threads="$XB_PRO_THREADS" \
      --row_offsets="$ROW_OFFSETS" \
      --col_indices="$COL_INDICES" \
      --path_buffer_ratio="$PATH_BUFFER_RATIO" \
      | tee -a "$TIMING_OUT"
  "$ANALYZE_SCRIPT" "$DATASET" "$TIMING_OUT" "$SUMMARY_CSV_TEMP"
done

cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"
touch "$STAMP"
echo "Summary saved at ${SUMMARY_CSV}"
