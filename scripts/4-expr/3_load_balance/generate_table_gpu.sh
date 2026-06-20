#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

METRICS_DIR="${PROJECT_DIR}/tmp/3_load_balance/gpu"
RESULTS_DIR="${PROJECT_DIR}/results/3_load_balance"
PYTHON_SCRIPT="${SCRIPT_DIR}/generate_table_gpu.py"
SUMMARY_CSV_TEMP="${METRICS_DIR}/_gpu_loadbalance_summary.csv"
SUMMARY_CSV="${RESULTS_DIR}/table_3_right.csv"

mkdir -p "$METRICS_DIR" "$RESULTS_DIR"
rm -f "$SUMMARY_CSV_TEMP"

for entry in "${DATASET_CSR_LIST[@]}"; do
  IFS='|' read -r DATASET _ _ _ <<< "$entry"

  TIMING_OUT_PEREDGE="${METRICS_DIR}/xb_pp_peredge_${DATASET}_timing.txt"
  TIMING_OUT_PERNODE="${METRICS_DIR}/xb_pp_pernode_${DATASET}_timing.txt"
  require_file "$TIMING_OUT_PEREDGE" "${DATASET} XB++ per-edge timing"
  require_file "$TIMING_OUT_PERNODE" "${DATASET} XB++ per-node timing"

  run_python "$PYTHON_SCRIPT" \
      "$DATASET" \
      "$TIMING_OUT_PEREDGE" \
      "$TIMING_OUT_PERNODE" \
      "$SUMMARY_CSV_TEMP"
done

cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"
echo "Summary saved at ${SUMMARY_CSV}"
