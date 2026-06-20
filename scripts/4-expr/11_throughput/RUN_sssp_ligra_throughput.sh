#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

METRICS_DIR="${PROJECT_DIR}/tmp/11_throughput/sssp_ligra"
RESULTS_DIR="${PROJECT_DIR}/results/11_throughput"
STAMP="${RESULTS_DIR}/.stamp.throughput_sssp_ligra"
ANALYZE_SCRIPT="${SCRIPT_DIR}/analyze_throughput.sh"
SUMMARY_CSV_TEMP="${METRICS_DIR}/_sssp_ligra_throughput_summary.csv"
SUMMARY_CSV="${RESULTS_DIR}/throughput_sssp_ligra.csv"
# RUN MODE: quick-check uses 2 rounds so scripts finish quickly.
# RUN MODE: analysis uses ROUNDS="${ROUNDS:-20}" for final reported results.
# To switch modes, comment the quick-check line and uncomment the analysis line.
# ROUNDS="${ROUNDS:-20}"
ROUNDS="${ROUNDS:-2}"
SYMMETICS_TRUE=1

if [[ -f "$STAMP" ]]; then
  echo "Experiment 11 Ligra-SSSP throughput already generated (stamp found)"
  exit 0
fi

require_executable "$LIGRA_SSSP_THROUGHPUT_BIN" "Ligra SSSP throughput binary"
rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR" "$RESULTS_DIR"

for entry in "${DATASET_SSSP_LIST[@]}"; do
  IFS='|' read -r DATASET LIGRA_GRAPH _GUNROCK_GRAPH SRC_FILE <<< "$entry"
  require_file "$LIGRA_GRAPH" "${DATASET} Ligra weighted graph"
  require_file "$SRC_FILE" "${DATASET} source list"
  SRC="$(first_source_node "$SRC_FILE")"
  TIMING_OUT="${METRICS_DIR}/sssp_ligra_${DATASET}_throughput.txt"
  : > "$TIMING_OUT"

  echo "Running Ligra-SSSP throughput on ${DATASET} (${ROUNDS} rounds, symmetric=${SYMMETICS_TRUE}, src=${SRC})..."
  "$LIGRA_SSSP_THROUGHPUT_BIN" -rounds "$ROUNDS" -r "$SRC" -s "$LIGRA_GRAPH" | tee -a "$TIMING_OUT"
  "$ANALYZE_SCRIPT" "$DATASET" "$TIMING_OUT" "$SUMMARY_CSV_TEMP"
done

cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"
touch "$STAMP"
echo "Summary saved at ${SUMMARY_CSV}"
