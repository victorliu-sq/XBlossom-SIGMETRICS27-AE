#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

XB_PP_BIN="${XB_BIN_DIR}/run_xb_pp_by_dataset"
METRICS_DIR="${PROJECT_DIR}/tmp/15_throughput_bbss/xb_pp"
RESULTS_DIR="${PROJECT_DIR}/results/15_throughput_bbss"
STAMP="${RESULTS_DIR}/.stamp.throughput_xb_pp"
ANALYZE_SCRIPT="${SCRIPT_DIR}/analyze_xb_throughput.sh"
SUMMARY_CSV_TEMP="${METRICS_DIR}/_xb_pp_throughput_summary.csv"
SUMMARY_CSV="${RESULTS_DIR}/throughput_xb_pp.csv"
SAMPLES_CSV="${RESULTS_DIR}/throughput_xb_pp_samples.csv"
ROUNDS="${ROUNDS:-20}"

if [[ -f "$STAMP" ]]; then
  echo "Experiment 15 XB++ throughput already generated (stamp found)"
  exit 0
fi

require_executable "$XB_PP_BIN" "XB++ binary"
rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR" "$RESULTS_DIR"

for entry in "${DATASET_CSR_LIST[@]}"; do
  IFS='|' read -r DATASET ROW_OFFSETS COL_INDICES PATH_BUFFER_RATIO <<< "$entry"
  TIMING_OUT="${METRICS_DIR}/xb_pp_${DATASET}_throughput.txt"
  : > "$TIMING_OUT"

  echo "Running XB++ throughput on ${DATASET} (${ROUNDS} rounds)..."
  run_xb_dataset "$XB_PP_BIN" "$DATASET" "$ROUNDS" "$ROW_OFFSETS" "$COL_INDICES" "$PATH_BUFFER_RATIO" \
      | tee -a "$TIMING_OUT"
  "$ANALYZE_SCRIPT" "$DATASET" "$TIMING_OUT" "$SUMMARY_CSV_TEMP"
done

cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"
cp "${SUMMARY_CSV_TEMP%.csv}_samples.csv" "$SAMPLES_CSV"
touch "$STAMP"
echo "Summary saved at ${SUMMARY_CSV}"
