#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

RESULTS_DIR="${PROJECT_DIR}/results/5_runtime_four_bbss"
ANALYZE_SCRIPT="${SCRIPT_DIR}/analyze_gunrock_time.sh"
METRICS_DIR="${PROJECT_DIR}/tmp/5_runtime_four_bbss/sssp_gunrock"
SUMMARY_CSV_TEMP="${METRICS_DIR}/_sssp_gunrock_summary.csv"
SUMMARY_CSV="${RESULTS_DIR}/figure_5_sssp_gunrock.csv"
SAMPLES_CSV="${RESULTS_DIR}/figure_5_sssp_gunrock_samples.csv"
STAMP="${RESULTS_DIR}/.stamp.figure_5_sssp_gunrock"
ROUNDS="${ROUNDS:-20}"

if [[ -f "$STAMP" ]]; then
  echo "Figure 12 SSSP Gunrock part already generated (stamp found)"
  exit 0
fi

require_executable "$GUNROCK_SSSP_BIN" "Gunrock SSSP binary"
rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR" "$RESULTS_DIR"

for entry in "${DATASET_SSSP_LIST[@]}"; do
  IFS='|' read -r DATASET _LIGRA_GRAPH GUNROCK_GRAPH SRC_FILE NODE_COUNT SRC_COUNT_ARG <<< "$entry"
  require_file "$GUNROCK_GRAPH" "${DATASET} Gunrock weighted graph"
  require_file "$SRC_FILE" "${DATASET} source list"
  SRC="$(first_source_node "$SRC_FILE")"

  TIMING_OUT="${METRICS_DIR}/sssp_gunrock_timing_${DATASET}.txt"
  : > "$TIMING_OUT"

  echo "Running Gunrock-SSSP on ${DATASET} (${ROUNDS} rounds, src=${SRC})..."
  "$GUNROCK_SSSP_BIN" -n "$ROUNDS" -s "$SRC" -m "$GUNROCK_GRAPH" | tee -a "$TIMING_OUT"
  "$ANALYZE_SCRIPT" "$DATASET" "$TIMING_OUT" "$SUMMARY_CSV_TEMP"
done

cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"
cp "${SUMMARY_CSV_TEMP%.csv}_samples.csv" "$SAMPLES_CSV"
touch "$STAMP"
echo "Summary saved at $SUMMARY_CSV"
