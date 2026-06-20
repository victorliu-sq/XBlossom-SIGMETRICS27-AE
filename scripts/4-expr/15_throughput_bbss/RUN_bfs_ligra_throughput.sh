#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

METRICS_DIR="${PROJECT_DIR}/tmp/15_throughput_bbss/bfs_ligra"
RESULTS_DIR="${PROJECT_DIR}/results/15_throughput_bbss"
STAMP="${RESULTS_DIR}/.stamp.throughput_bfs_ligra"
ANALYZE_SCRIPT="${SCRIPT_DIR}/analyze_throughput.sh"
SUMMARY_CSV_TEMP="${METRICS_DIR}/_bfs_ligra_throughput_summary.csv"
SUMMARY_CSV="${RESULTS_DIR}/throughput_bfs_ligra.csv"
# Default to 200 rounds for stable Ligra measurements.
ROUNDS="${ROUNDS:-200}"
SYMMETICS_TRUE=1

if [[ -f "$STAMP" ]]; then
  echo "Experiment 15 Ligra-BFS throughput already generated (stamp found)"
  exit 0
fi

require_executable "$LIGRA_BFS_THROUGHPUT_BIN" "Ligra BFS throughput binary"
rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR" "$RESULTS_DIR"

for entry in "${DATASET_BFS_LIST[@]}"; do
  IFS='|' read -r DATASET LIGRA_GRAPH _GUNROCK_GRAPH SRC_FILE <<< "$entry"
  require_file "$LIGRA_GRAPH" "${DATASET} Ligra graph"
  require_file "$SRC_FILE" "${DATASET} source list"
  SRC="$(first_source_node "$SRC_FILE")"
  TIMING_OUT="${METRICS_DIR}/bfs_ligra_${DATASET}_throughput.txt"
  : > "$TIMING_OUT"

  echo "Running Ligra-BFS throughput on ${DATASET} (${ROUNDS} rounds, symmetric=${SYMMETICS_TRUE}, src=${SRC})..."
  "$LIGRA_BFS_THROUGHPUT_BIN" -rounds "$ROUNDS" -r "$SRC" -s "$LIGRA_GRAPH" | tee -a "$TIMING_OUT"
  "$ANALYZE_SCRIPT" "$DATASET" "$TIMING_OUT" "$SUMMARY_CSV_TEMP"
done

cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"
touch "$STAMP"
echo "Summary saved at ${SUMMARY_CSV}"
