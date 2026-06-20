#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

METRICS_DIR="${PROJECT_DIR}/tmp/2_reuse/xb_and_xb_pro"
RESULTS_DIR="${PROJECT_DIR}/results/2_reuse"
PYTHON_SCRIPT="${SCRIPT_DIR}/generate_table_cpu.py"
SUMMARY_CSV_TEMP="${METRICS_DIR}/_xb_and_xb_pro_summary.csv"
SUMMARY_CSV="${RESULTS_DIR}/table_2_left.csv"

mkdir -p "$METRICS_DIR" "$RESULTS_DIR"
rm -f "$SUMMARY_CSV_TEMP"

for entry in "${DATASET_CSR_LIST[@]}"; do
  IFS='|' read -r DATASET _ _ _ <<< "$entry"

  TIMING_OUT_XB="${METRICS_DIR}/xb_${DATASET}_timing.txt"
  TIMING_OUT_XB_PRO="${METRICS_DIR}/xb_pro_${DATASET}_timing.txt"
  require_file "$TIMING_OUT_XB" "${DATASET} XB timing"
  require_file "$TIMING_OUT_XB_PRO" "${DATASET} XB-Pro timing"

  run_python "$PYTHON_SCRIPT" \
      "$DATASET" \
      "$TIMING_OUT_XB" \
      "$TIMING_OUT_XB_PRO" \
      "$SUMMARY_CSV_TEMP"
done

cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"

echo "Summary saved at ${SUMMARY_CSV}"
