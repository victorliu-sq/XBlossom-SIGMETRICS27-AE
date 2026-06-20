#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

RESULTS_DIR="${PROJECT_DIR}/results/8_memory_four_bbss"
ANALYZE_SCRIPT="${SCRIPT_DIR}/analyze_gunrock_mem.sh"
NCU_METRIC="dram__bytes_op_read.sum"
PROFILE_RUNS="${PROFILE_RUNS:-20}"
METRICS_DIR="${PROJECT_DIR}/tmp/8_memory_four_bbss/bfs_gunrock"
SUMMARY_CSV_TEMP="${METRICS_DIR}/_bfs_gunrock_mem_summary.csv"
SUMMARY_CSV="${RESULTS_DIR}/table_8_bfs_gunrock.csv"
STAMP="${RESULTS_DIR}/.stamp.table_8_bfs_gunrock"

if [[ -f "$STAMP" ]]; then
  echo "Table 14 BFS Gunrock part already generated (stamp found)"
  exit 0
fi

require_executable "$GUNROCK_BFS_BIN" "Gunrock BFS binary"
rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR" "$RESULTS_DIR"

for entry in "${DATASET_BFS_LIST[@]}"; do
  IFS='|' read -r DATASET _LIGRA_GRAPH GUNROCK_GRAPH SRC_FILE NODE_COUNT SRC_COUNT_ARG <<< "$entry"
  require_file "$GUNROCK_GRAPH" "${DATASET} Gunrock graph"
  require_file "$SRC_FILE" "${DATASET} source list"
  SRC="$(first_source_node "$SRC_FILE")"

  TIMING_OUT="${METRICS_DIR}/gunrock_bfs_timing_${DATASET}.txt"
  PROFILING_DIR="${METRICS_DIR}/gunrock_bfs_profile_${DATASET}"
  : > "$TIMING_OUT"

  echo "Profiling Gunrock-BFS on ${DATASET} (${PROFILE_RUNS} profile runs, src=${SRC})..."
  profile_ncu_repeated "$NCU_METRIC" "$TIMING_OUT" "$PROFILING_DIR" "$PROFILE_RUNS" \
      "$GUNROCK_BFS_BIN" -s "$SRC" -m "$GUNROCK_GRAPH"
  "$ANALYZE_SCRIPT" "$DATASET" "$TIMING_OUT" "$PROFILING_DIR" "$SUMMARY_CSV_TEMP"
done

cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"
touch "$STAMP"
echo "Summary saved at $SUMMARY_CSV"
