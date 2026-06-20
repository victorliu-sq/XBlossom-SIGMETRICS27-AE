#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

XB_PRO_BIN="${XB_BIN_DIR}/run_xb_pro_by_dataset"
METRICS_DIR="${PROJECT_DIR}/tmp/9_inst_rate_four/xb_pro"
RESULTS_DIR="${PROJECT_DIR}/results/9_inst_rate_four"
STAMP="${RESULTS_DIR}/.stamp.table_9_xbpro"
ANALYZE_SCRIPT="${SCRIPT_DIR}/analyze_xb_pro_inst.sh"
SUMMARY_CSV_TEMP="${METRICS_DIR}/_xb_pro_summary.csv"
SUMMARY_CSV="${RESULTS_DIR}/table_9_xb_pro.csv"
# RUN MODE: quick-check originally used 2 rounds so scripts finished quickly.
# RUN MODE: analysis uses ROUNDS="${ROUNDS:-3}" for final reported results.
# To switch modes, comment the quick-check line and uncomment the analysis line.
# ROUNDS="${ROUNDS:-3}"
ROUNDS="${ROUNDS:-2}"


XB_PRO_THREADS="${XB_PRO_THREADS:-$(default_xb_pro_threads)}"

if [[ -f "$STAMP" ]]; then
  echo "Table 9 XB-Pro part already generated (stamp found)"
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

  perf stat -a -x, -e instructions -o "$PROFILER_OUT" -- \
      "$XB_PRO_BIN" --dataset="$DATASET" --rounds="$ROUNDS" --num_threads="$XB_PRO_THREADS" --row_offsets="$ROW_OFFSETS" --col_indices="$COL_INDICES" --path_buffer_ratio="$PATH_BUFFER_RATIO" \
      | tee -a "$TIMING_OUT"
  "$ANALYZE_SCRIPT" "$DATASET" "$TIMING_OUT" "$PROFILER_OUT" "$SUMMARY_CSV_TEMP" "$ROUNDS"
done

cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"
touch "$STAMP"
echo "Summary saved at ${SUMMARY_CSV}"
