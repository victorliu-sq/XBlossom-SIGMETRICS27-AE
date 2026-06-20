#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

RESULTS_DIR="${PROJECT_DIR}/results/7_memory_four_bbss"
ANALYZE_SCRIPT="${SCRIPT_DIR}/analyze_gunrock_mem.sh"
NCU_METRIC="dram__bytes_op_read.sum"
PROFILE_RUNS="${PROFILE_RUNS:-20}"
METRICS_DIR="${PROJECT_DIR}/tmp/7_memory_four_bbss/multisssp_gunrock"
SUMMARY_CSV_TEMP="${METRICS_DIR}/_multisssp_gunrock_mem_summary.csv"
SUMMARY_CSV="${RESULTS_DIR}/table_7_multisssp_gunrock.csv"
STAMP="${RESULTS_DIR}/.stamp.table_7_multisssp_gunrock"

if [[ -f "$STAMP" ]]; then
  echo "Table 14 MultiSSSP Gunrock part already generated (stamp found)"
  exit 0
fi

require_executable "$GUNROCK_MULTISSSP_BIN" "Gunrock MultiSSSP binary"
rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR" "$RESULTS_DIR"

for entry in "${DATASET_MULTISSSP_LIST[@]}"; do
  IFS='|' read -r DATASET _LIGRA_GRAPH GUNROCK_GRAPH SRC_FILE NODE_COUNT SRC_COUNT_ARG <<< "$entry"
  require_file "$GUNROCK_GRAPH" "${DATASET} Gunrock weighted graph"
  SRC_COUNT="${SRC_COUNT_ARG:-$(percent_count "$NODE_COUNT")}"
  SRC="count${SRC_COUNT}"

  TIMING_OUT="${METRICS_DIR}/gunrock_multisssp_timing_${DATASET}.txt"
  PROFILING_DIR="${METRICS_DIR}/gunrock_multisssp_profile_${DATASET}"
  : > "$TIMING_OUT"

  echo "Profiling Gunrock-MultiSSSP on ${DATASET} (${PROFILE_RUNS} profile runs, src=${SRC})..."
  profile_ncu_repeated "$NCU_METRIC" "$TIMING_OUT" "$PROFILING_DIR" "$PROFILE_RUNS" \
      "$GUNROCK_MULTISSSP_BIN" --src-count "$SRC_COUNT" -m "$GUNROCK_GRAPH"
  "$ANALYZE_SCRIPT" "$DATASET" "$TIMING_OUT" "$PROFILING_DIR" "$SUMMARY_CSV_TEMP"
done

cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"
touch "$STAMP"
echo "Summary saved at $SUMMARY_CSV"
