#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

RESULTS_DIR="${PROJECT_DIR}/results/8_runtime_four"
ANALYZE_SCRIPT="${SCRIPT_DIR}/analyze_gunrock_time.sh"
METRICS_DIR="${PROJECT_DIR}/tmp/8_runtime_four/bc_gunrock"
SUMMARY_CSV_TEMP="${METRICS_DIR}/_bc_gunrock_summary.csv"
SUMMARY_CSV="${RESULTS_DIR}/figure_8_bc_gunrock.csv"
STAMP="${RESULTS_DIR}/.stamp.figure_8_bc_gunrock"

if [[ -f "$STAMP" ]]; then
  echo "Figure 8 BC Gunrock part already generated (stamp found)"
  exit 0
fi

require_executable "$GUNROCK_BC_BIN" "Gunrock BC binary"
rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR" "$RESULTS_DIR"

for entry in "${DATASET_BFS_LIST[@]}"; do
  IFS='|' read -r DATASET _LIGRA_GRAPH GUNROCK_GRAPH SRC_FILE <<< "$entry"
  require_file "$GUNROCK_GRAPH" "${DATASET} Gunrock graph"
  require_file "$SRC_FILE" "${DATASET} source list"
  SRC="$(first_source_node "$SRC_FILE")"

  TIMING_OUT="${METRICS_DIR}/bc_gunrock_timing_${DATASET}.txt"
  : > "$TIMING_OUT"

  echo "Running Gunrock-BC on ${DATASET} (src=${SRC})..."
  "$GUNROCK_BC_BIN" -s "$SRC" -m "$GUNROCK_GRAPH" | tee -a "$TIMING_OUT"
  "$ANALYZE_SCRIPT" "$DATASET" "$TIMING_OUT" "$SUMMARY_CSV_TEMP"
done

cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"
touch "$STAMP"
echo "Summary saved at $SUMMARY_CSV"
