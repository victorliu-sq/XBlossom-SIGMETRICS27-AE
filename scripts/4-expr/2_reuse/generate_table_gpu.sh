#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

METRICS_DIR="${PROJECT_DIR}/tmp/2_reuse/xb_pp_r_and_nr"
RESULTS_DIR="${PROJECT_DIR}/results/2_reuse"
PYTHON_SCRIPT="${SCRIPT_DIR}/generate_table_gpu.py"
SUMMARY_CSV_TEMP="${METRICS_DIR}/_xb_pp_r_and_nr_summary.csv"
SUMMARY_CSV="${RESULTS_DIR}/table_2_right.csv"

mkdir -p "$METRICS_DIR" "$RESULTS_DIR"
rm -f "$SUMMARY_CSV_TEMP"

for entry in "${DATASET_CSR_LIST[@]}"; do
  IFS='|' read -r DATASET _ _ _ <<< "$entry"

  TIMING_OUT_XB_PP_NR="${METRICS_DIR}/xb_pp_nr_${DATASET}_timing.txt"
  TIMING_OUT_XB_PP="${METRICS_DIR}/xb_pp_${DATASET}_timing.txt"
  require_file "$TIMING_OUT_XB_PP_NR" "${DATASET} XB++NR timing"
  require_file "$TIMING_OUT_XB_PP" "${DATASET} XB++ timing"

  run_python "$PYTHON_SCRIPT" \
      "$DATASET" \
      "$TIMING_OUT_XB_PP_NR" \
      "$TIMING_OUT_XB_PP" \
      "$SUMMARY_CSV_TEMP"
done

cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"

echo "Summary saved at ${SUMMARY_CSV}"
