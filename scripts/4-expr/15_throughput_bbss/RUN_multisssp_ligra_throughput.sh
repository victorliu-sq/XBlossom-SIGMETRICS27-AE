#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

METRICS_DIR="${PROJECT_DIR}/tmp/15_throughput_bbss/multisssp_ligra"
RESULTS_DIR="${PROJECT_DIR}/results/15_throughput_bbss"
STAMP="${RESULTS_DIR}/.stamp.throughput_multisssp_ligra"
ANALYZE_SCRIPT="${SCRIPT_DIR}/analyze_throughput.sh"
SUMMARY_CSV_TEMP="${METRICS_DIR}/_multisssp_ligra_throughput_summary.csv"
SUMMARY_CSV="${RESULTS_DIR}/throughput_multisssp_ligra.csv"
# Default to 200 rounds for stable Ligra measurements.
ROUNDS="${ROUNDS:-200}"
SYMMETICS_TRUE=1

if [[ -f "$STAMP" ]]; then
  echo "Experiment 15 Ligra-MultiSSSP throughput already generated (stamp found)"
  exit 0
fi

require_executable "$LIGRA_MULTISSSP_THROUGHPUT_BIN" "Ligra MultiSSSP throughput binary"
rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR" "$RESULTS_DIR"

for entry in "${DATASET_MULTISSSP_LIST[@]}"; do
  IFS='|' read -r DATASET LIGRA_GRAPH _GUNROCK_GRAPH SRC_FILE NODE_COUNT SRC_COUNT_ARG <<< "$entry"
  require_file "$LIGRA_GRAPH" "${DATASET} Ligra weighted graph"
  SRC_COUNT="${SRC_COUNT_ARG:-$(percent_count "$NODE_COUNT")}"
  TIMING_OUT="${METRICS_DIR}/multisssp_ligra_${DATASET}_throughput.txt"
  : > "$TIMING_OUT"

  echo "Running Ligra-MultiSSSP throughput on ${DATASET} (${ROUNDS} rounds, symmetric=${SYMMETICS_TRUE}, src-count=${SRC_COUNT})..."
  "$LIGRA_MULTISSSP_THROUGHPUT_BIN" -rounds "$ROUNDS" --src-count "$SRC_COUNT" -s "$LIGRA_GRAPH" | tee -a "$TIMING_OUT"
  "$ANALYZE_SCRIPT" "$DATASET" "$TIMING_OUT" "$SUMMARY_CSV_TEMP"
done

cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"
touch "$STAMP"
echo "Summary saved at ${SUMMARY_CSV}"
