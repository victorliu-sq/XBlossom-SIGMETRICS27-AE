#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

RESULTS_DIR="${PROJECT_DIR}/results/7_memory_four_bbss"
ANALYZE_SCRIPT="${SCRIPT_DIR}/analyze_ligra_mem.sh"
ROUNDS="${ROUNDS:-200}"
ITERATIONS="${ITERATIONS:-5}"
SYMMETICS_TRUE=1

METRICS_DIR="${PROJECT_DIR}/tmp/7_memory_four_bbss/bfs_ligra"
SUMMARY_CSV_TEMP="${METRICS_DIR}/_bfs_ligra_mem_summary.csv"
SUMMARY_CSV="${RESULTS_DIR}/table_7_bfs_ligra.csv"
STAMP="${RESULTS_DIR}/.stamp.table_7_bfs_ligra"

if [[ -f "$STAMP" ]]; then
  echo "Table 14 BFS Ligra part already generated (stamp found)"
  exit 0
fi

require_executable "$LIGRA_BFS_BIN" "Ligra BFS binary"
rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR" "$RESULTS_DIR"

for entry in "${DATASET_BFS_LIST[@]}"; do
  IFS='|' read -r DATASET LIGRA_GRAPH _GUNROCK_GRAPH SRC_FILE NODE_COUNT SRC_COUNT_ARG <<< "$entry"
  require_file "$LIGRA_GRAPH" "${DATASET} Ligra graph"
  require_file "$SRC_FILE" "${DATASET} source list"
  SRC="$(first_source_node "$SRC_FILE")"

  for ITERATION in $(seq 1 "$ITERATIONS"); do
    TIMING_OUT="${METRICS_DIR}/ligra_${DATASET}_src${SRC}_iter_${ITERATION}_timing.txt"
    PROFILER_OUT="${METRICS_DIR}/ligra_${DATASET}_src${SRC}_iter_${ITERATION}_profiling.txt"
    : > "$TIMING_OUT"
    : > "$PROFILER_OUT"

    echo "Profiling Ligra-BFS memory on ${DATASET} iteration ${ITERATION}/${ITERATIONS} (${ROUNDS} rounds, symmetric=${SYMMETICS_TRUE}, src=${SRC})..."
    perf stat -a -x, -e instructions,mem_load_retired.l3_miss,mem_load_retired.l3_hit -o "$PROFILER_OUT" -- \
        "$LIGRA_BFS_BIN" -rounds "$ROUNDS" -r "$SRC" -s "$LIGRA_GRAPH" | tee -a "$TIMING_OUT"
  done
  "$ANALYZE_SCRIPT" "$DATASET" "$METRICS_DIR" "$SUMMARY_CSV_TEMP"
done

cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"
cp "${SUMMARY_CSV_TEMP%.csv}_samples.csv" "${RESULTS_DIR}/table_7_bfs_ligra_samples.csv"
touch "$STAMP"
echo "Summary saved at $SUMMARY_CSV"
