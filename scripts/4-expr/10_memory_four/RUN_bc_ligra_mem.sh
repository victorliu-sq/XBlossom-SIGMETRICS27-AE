#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

RESULTS_DIR="${PROJECT_DIR}/results/10_memory_four"
ANALYZE_SCRIPT="${SCRIPT_DIR}/analyze_ligra_mem.sh"
ROUNDS="${ROUNDS:-50}"
SYMMETICS_TRUE=1

METRICS_DIR="${PROJECT_DIR}/tmp/10_memory_four/bc_ligra"
SUMMARY_CSV_TEMP="${METRICS_DIR}/_bc_ligra_mem_summary.csv"
SUMMARY_CSV="${RESULTS_DIR}/table_10_bc_ligra.csv"
STAMP="${RESULTS_DIR}/.stamp.table_10_bc_ligra"

if [[ -f "$STAMP" ]]; then
  echo "Table 10 BC Ligra part already generated (stamp found)"
  exit 0
fi

require_executable "$LIGRA_BC_BIN" "Ligra BC binary"
rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR" "$RESULTS_DIR"

for entry in "${DATASET_BFS_LIST[@]}"; do
  IFS='|' read -r DATASET LIGRA_GRAPH _GUNROCK_GRAPH SRC_FILE <<< "$entry"
  require_file "$LIGRA_GRAPH" "${DATASET} Ligra graph"
  require_file "$SRC_FILE" "${DATASET} source list"
  SRC="$(first_source_node "$SRC_FILE")"

  TIMING_OUT="${METRICS_DIR}/ligra_${DATASET}_src${SRC}_timing.txt"
  PROFILER_OUT="${METRICS_DIR}/ligra_${DATASET}_src${SRC}_profiling.txt"
  : > "$TIMING_OUT"
  : > "$PROFILER_OUT"

  echo "Profiling Ligra-BC memory on ${DATASET} (${ROUNDS} rounds, symmetric=${SYMMETICS_TRUE}, src=${SRC})..."
  perf stat -a -x, -e instructions,mem_load_retired.l3_miss,mem_load_retired.l3_hit -o "$PROFILER_OUT" -- \
      "$LIGRA_BC_BIN" -rounds "$ROUNDS" -r "$SRC" -s "$LIGRA_GRAPH" | tee -a "$TIMING_OUT"
  "$ANALYZE_SCRIPT" "$DATASET" "$METRICS_DIR" "$SUMMARY_CSV_TEMP"
done

cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"
touch "$STAMP"
echo "Summary saved at $SUMMARY_CSV"
