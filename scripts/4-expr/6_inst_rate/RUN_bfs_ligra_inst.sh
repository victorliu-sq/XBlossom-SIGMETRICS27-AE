#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

METRICS_DIR="${PROJECT_DIR}/tmp/6_inst_rate/bfs_ligra"
RESULTS_DIR="${PROJECT_DIR}/results/6_inst_rate"
STAMP="${RESULTS_DIR}/.stamp.table_5_ligra"
ANALYZE_SCRIPT="${SCRIPT_DIR}/analyze_bfs_ligra_inst.sh"
SUMMARY_CSV_TEMP="${METRICS_DIR}/_bfs_ligra_inst_summary.csv"
SUMMARY_CSV="${RESULTS_DIR}/table_5_bfs_ligra.csv"
# RUN MODE: quick-check uses 2 rounds so scripts finish quickly.
# RUN MODE: analysis uses ROUNDS="${ROUNDS:-500}" for final reported results.
# To switch modes, comment the quick-check line and uncomment the analysis line.
# ROUNDS="${ROUNDS:-500}"
ROUNDS="${ROUNDS:-2}"
LLC_EVENTS="${PERF_LLC_EVENTS:-$(perf_llc_events)}"

if [[ -f "$STAMP" ]]; then
  echo "Table 5 Ligra part already generated (stamp found)"
  exit 0
fi

require_executable "$LIGRA_BFS_BIN" "Ligra BFS binary"
rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR" "$RESULTS_DIR"

for entry in "${DATASET_BFS_LIST[@]}"; do
  IFS='|' read -r DATASET LIGRA_GRAPH _GUNROCK_GRAPH SRC_FILE <<< "$entry"
  SRC="$(first_source_node "$SRC_FILE")"
  TIMING_OUT="${METRICS_DIR}/ligra_${DATASET}_src${SRC}_timing.txt"
  PROFILER_OUT="${METRICS_DIR}/ligra_${DATASET}_src${SRC}_profiling.txt"
  : > "$TIMING_OUT"
  : > "$PROFILER_OUT"

  perf stat -a -x, -e instructions -e "$LLC_EVENTS" -o "$PROFILER_OUT" -- \
      "$LIGRA_BFS_BIN" -rounds "$ROUNDS" -r "$SRC" -s "$LIGRA_GRAPH" | tee -a "$TIMING_OUT"
  "$ANALYZE_SCRIPT" "$DATASET" "$METRICS_DIR" "$SUMMARY_CSV_TEMP"
done

cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"
touch "$STAMP"
echo "Summary saved at ${SUMMARY_CSV}"
