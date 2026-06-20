#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

METRICS_DIR="${PROJECT_DIR}/tmp/7_memory/bfs_gunrock"
RESULTS_DIR="${PROJECT_DIR}/results/7_memory"
STAMP="${RESULTS_DIR}/.stamp.table_6_gunrock"
ANALYZE_SCRIPT="${SCRIPT_DIR}/analyze_bfs_gunrock_mem.sh"
SUMMARY_CSV_TEMP="${METRICS_DIR}/_bfs_gunrock_mem_summary.csv"
SUMMARY_CSV="${RESULTS_DIR}/table_6_bfs_gunrock.csv"
NCU_METRIC="dram__bytes_read.sum"

if [[ -f "$STAMP" ]]; then
  echo "Table 6 Gunrock part already generated (stamp found)"
  exit 0
fi

require_executable "$GUNROCK_BFS_BIN" "Gunrock BFS binary"
rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR" "$RESULTS_DIR"

for entry in "${DATASET_BFS_LIST[@]}"; do
  IFS='|' read -r DATASET _LIGRA_GRAPH GUNROCK_GRAPH SRC_FILE <<< "$entry"
  SRC="$(first_source_node "$SRC_FILE")"
  TIMING_OUT="${METRICS_DIR}/gunrock_bfs_timing_${DATASET}.txt"
  PROFILING_OUT="${METRICS_DIR}/gunrock_bfs_profile_${DATASET}.csv"
  : > "$TIMING_OUT"

  "$GUNROCK_BFS_BIN" -s "$SRC" -m "$GUNROCK_GRAPH" | tee -a "$TIMING_OUT"
  run_ncu --metrics "$NCU_METRIC" --csv "$GUNROCK_BFS_BIN" -s "$SRC" -m "$GUNROCK_GRAPH" > "$PROFILING_OUT"
  "$ANALYZE_SCRIPT" "$DATASET" "$TIMING_OUT" "$PROFILING_OUT" "$SUMMARY_CSV_TEMP"
done

cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"
touch "$STAMP"
echo "Summary saved at ${SUMMARY_CSV}"
