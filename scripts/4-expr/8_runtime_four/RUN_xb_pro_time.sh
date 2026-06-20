#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

XB_PRO_BIN="${XB_BIN_DIR}/run_xb_pro_by_dataset"
METRICS_DIR="${PROJECT_DIR}/tmp/8_runtime_four/xb_pro"
RESULTS_DIR="${PROJECT_DIR}/results/8_runtime_four"
STAMP="${RESULTS_DIR}/.stamp.figure_8_xbpro"
ANALYZE_SCRIPT="${SCRIPT_DIR}/analyze_xb_pro_time.sh"
SUMMARY_CSV_TEMP="${METRICS_DIR}/_xb_pro_summary.csv"
SUMMARY_CSV="${RESULTS_DIR}/figure_8_xb_pro.csv"
ROUNDS="${ROUNDS:-20}"

if [[ -f "$STAMP" ]]; then
  echo "Figure 8 XB-Pro part already generated (stamp found)"
  exit 0
fi

require_executable "$XB_PRO_BIN" "XB-Pro binary"
rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR" "$RESULTS_DIR"

for entry in "${DATASET_CSR_LIST[@]}"; do
  IFS='|' read -r DATASET ROW_OFFSETS COL_INDICES PATH_BUFFER_RATIO <<< "$entry"
  TIMING_OUT="${METRICS_DIR}/xb_pro_${DATASET}_timing.txt"
  PROFILER_OUT="${METRICS_DIR}/xb_pro_${DATASET}_profiling.txt"
  : > "$TIMING_OUT"
  : > "$PROFILER_OUT"

  echo "Profiling XB-Pro on ${DATASET} (${ROUNDS} rounds)..."
  perf stat -a -x, -e instructions -o "$PROFILER_OUT" -- \
      "$XB_PRO_BIN" --dataset="$DATASET" --rounds="$ROUNDS" --row_offsets="$ROW_OFFSETS" --col_indices="$COL_INDICES" --path_buffer_ratio="$PATH_BUFFER_RATIO" \
      | tee -a "$TIMING_OUT"
  "$ANALYZE_SCRIPT" "$DATASET" "$TIMING_OUT" "$PROFILER_OUT" "$SUMMARY_CSV_TEMP" "$ROUNDS"
done

cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"
cp "${SUMMARY_CSV_TEMP%.csv}_samples.csv" "${RESULTS_DIR}/figure_8_xb_pro_samples.csv"
touch "$STAMP"
echo "Summary saved at ${SUMMARY_CSV}"
