#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

METRICS_DIR="${PROJECT_DIR}/tmp/11_throughput/sssp_gunrock"
RESULTS_DIR="${PROJECT_DIR}/results/11_throughput"
STAMP="${RESULTS_DIR}/.stamp.throughput_sssp_gunrock"
ANALYZE_SCRIPT="${SCRIPT_DIR}/analyze_throughput.sh"
SUMMARY_CSV_TEMP="${METRICS_DIR}/_sssp_gunrock_throughput_summary.csv"
SUMMARY_CSV="${RESULTS_DIR}/throughput_sssp_gunrock.csv"

if [[ -f "$STAMP" ]]; then
  echo "Experiment 11 Gunrock-SSSP throughput already generated (stamp found)"
  exit 0
fi

require_executable "$GUNROCK_SSSP_THROUGHPUT_BIN" "Gunrock SSSP throughput binary"
rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR" "$RESULTS_DIR"

for entry in "${DATASET_SSSP_LIST[@]}"; do
  IFS='|' read -r DATASET _LIGRA_GRAPH GUNROCK_GRAPH SRC_FILE <<< "$entry"
  require_file "$GUNROCK_GRAPH" "${DATASET} Gunrock weighted graph"
  require_file "$SRC_FILE" "${DATASET} source list"
  SRC="$(first_source_node "$SRC_FILE")"
  TIMING_OUT="${METRICS_DIR}/sssp_gunrock_${DATASET}_throughput.txt"
  : > "$TIMING_OUT"

  echo "Running Gunrock-SSSP throughput on ${DATASET} (src=${SRC})..."
  "$GUNROCK_SSSP_THROUGHPUT_BIN" -s "$SRC" -m "$GUNROCK_GRAPH" | tee -a "$TIMING_OUT"
  "$ANALYZE_SCRIPT" "$DATASET" "$TIMING_OUT" "$SUMMARY_CSV_TEMP"
done

cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"
touch "$STAMP"
echo "Summary saved at ${SUMMARY_CSV}"
