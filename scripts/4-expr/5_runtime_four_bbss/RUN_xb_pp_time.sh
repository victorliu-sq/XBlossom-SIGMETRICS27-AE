#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

XB_PP_BIN="${XB_BIN_DIR}/run_xb_pp_by_dataset"
METRICS_DIR="${PROJECT_DIR}/tmp/5_runtime_four_bbss/xb_pp"
RESULTS_DIR="${PROJECT_DIR}/results/5_runtime_four_bbss"
STAMP="${RESULTS_DIR}/.stamp.figure_5_xbpp"
ANALYZE_SCRIPT="${SCRIPT_DIR}/analyze_xb_pp_time.sh"
SUMMARY_CSV_TEMP="${METRICS_DIR}/_xb_pp_summary.csv"
SUMMARY_CSV="${RESULTS_DIR}/figure_5_xb_pp.csv"
SAMPLES_CSV="${RESULTS_DIR}/figure_5_xb_pp_samples.csv"
ROUNDS="${ROUNDS:-20}"

if [[ -f "$STAMP" ]]; then
  echo "Figure 12 XB-PP part already generated (stamp found)"
  exit 0
fi

require_executable "$XB_PP_BIN" "XB-PP binary"
rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR" "$RESULTS_DIR"

for entry in "${DATASET_CSR_LIST[@]}"; do
  IFS='|' read -r DATASET ROW_OFFSETS COL_INDICES PATH_BUFFER_RATIO <<< "$entry"
  TIMING_OUT="${METRICS_DIR}/xb_pp_${DATASET}_timing.txt"
  : > "$TIMING_OUT"

  echo "Running XB-PP on ${DATASET} (${ROUNDS} rounds)..."
  run_xb_dataset "$XB_PP_BIN" "$DATASET" "$ROUNDS" "$ROW_OFFSETS" "$COL_INDICES" "$PATH_BUFFER_RATIO" | tee -a "$TIMING_OUT"
  "$ANALYZE_SCRIPT" "$DATASET" "$TIMING_OUT" "$SUMMARY_CSV_TEMP"
done

cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"
cp "${SUMMARY_CSV_TEMP%.csv}_samples.csv" "$SAMPLES_CSV"
touch "$STAMP"
echo "Summary saved at ${SUMMARY_CSV}"
