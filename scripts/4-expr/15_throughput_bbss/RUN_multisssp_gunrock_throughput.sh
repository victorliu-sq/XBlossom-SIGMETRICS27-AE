#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

METRICS_DIR="${PROJECT_DIR}/tmp/15_throughput_bbss/multisssp_gunrock"
RESULTS_DIR="${PROJECT_DIR}/results/15_throughput_bbss"
STAMP="${RESULTS_DIR}/.stamp.throughput_multisssp_gunrock"
ANALYZE_SCRIPT="${SCRIPT_DIR}/analyze_throughput.sh"
SUMMARY_CSV_TEMP="${METRICS_DIR}/_multisssp_gunrock_throughput_summary.csv"
SUMMARY_CSV="${RESULTS_DIR}/throughput_multisssp_gunrock.csv"

if [[ -f "$STAMP" ]]; then
  echo "Experiment 15 Gunrock-MultiSSSP throughput already generated (stamp found)"
  exit 0
fi

require_executable "$GUNROCK_MULTISSSP_THROUGHPUT_BIN" "Gunrock MultiSSSP throughput binary"
rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR" "$RESULTS_DIR"

for entry in "${DATASET_MULTISSSP_LIST[@]}"; do
  IFS='|' read -r DATASET _LIGRA_GRAPH GUNROCK_GRAPH SRC_FILE NODE_COUNT SRC_COUNT_ARG <<< "$entry"
  require_file "$GUNROCK_GRAPH" "${DATASET} Gunrock weighted graph"
  SRC_COUNT="${SRC_COUNT_ARG:-$(percent_count "$NODE_COUNT")}"
  TIMING_OUT="${METRICS_DIR}/multisssp_gunrock_${DATASET}_throughput.txt"
  : > "$TIMING_OUT"

  echo "Running Gunrock-MultiSSSP throughput on ${DATASET} (src-count=${SRC_COUNT})..."
  "$GUNROCK_MULTISSSP_THROUGHPUT_BIN" --src-count "$SRC_COUNT" -m "$GUNROCK_GRAPH" | tee -a "$TIMING_OUT"
  "$ANALYZE_SCRIPT" "$DATASET" "$TIMING_OUT" "$SUMMARY_CSV_TEMP"
done

cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"
touch "$STAMP"
echo "Summary saved at ${SUMMARY_CSV}"
