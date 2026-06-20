#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

RESULTS_DIR="${PROJECT_DIR}/results/14_memory_four_bbss"
ANALYZE_SCRIPT="${SCRIPT_DIR}/analyze_ligra_mem.sh"
ROUNDS="${ROUNDS:-200}"
ITERATIONS="${ITERATIONS:-5}"
SYMMETICS_TRUE=1

METRICS_DIR="${PROJECT_DIR}/tmp/14_memory_four_bbss/multisssp_ligra"
SUMMARY_CSV_TEMP="${METRICS_DIR}/_multisssp_ligra_mem_summary.csv"
SUMMARY_CSV="${RESULTS_DIR}/table_14_multisssp_ligra.csv"
STAMP="${RESULTS_DIR}/.stamp.table_14_multisssp_ligra"

if [[ -f "$STAMP" ]]; then
  echo "Table 14 MultiSSSP Ligra part already generated (stamp found)"
  exit 0
fi

require_executable "$LIGRA_MULTISSSP_BIN" "Ligra MultiSSSP binary"
rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR" "$RESULTS_DIR"

for entry in "${DATASET_MULTISSSP_LIST[@]}"; do
  IFS='|' read -r DATASET LIGRA_GRAPH _GUNROCK_GRAPH SRC_FILE NODE_COUNT SRC_COUNT_ARG <<< "$entry"
  require_file "$LIGRA_GRAPH" "${DATASET} Ligra weighted graph"
  SRC_COUNT="${SRC_COUNT_ARG:-$(percent_count "$NODE_COUNT")}"
  SRC="count${SRC_COUNT}"

  for ITERATION in $(seq 1 "$ITERATIONS"); do
    TIMING_OUT="${METRICS_DIR}/ligra_${DATASET}_src${SRC}_iter_${ITERATION}_timing.txt"
    PROFILER_OUT="${METRICS_DIR}/ligra_${DATASET}_src${SRC}_iter_${ITERATION}_profiling.txt"
    : > "$TIMING_OUT"
    : > "$PROFILER_OUT"

    echo "Profiling Ligra-MultiSSSP memory on ${DATASET} iteration ${ITERATION}/${ITERATIONS} (${ROUNDS} rounds, symmetric=${SYMMETICS_TRUE}, src=${SRC})..."
    perf stat -a -x, -e instructions,mem_load_retired.l3_miss,mem_load_retired.l3_hit -o "$PROFILER_OUT" -- \
        "$LIGRA_MULTISSSP_BIN" -rounds "$ROUNDS" --src-count "$SRC_COUNT" -s "$LIGRA_GRAPH" | tee -a "$TIMING_OUT"
  done
  "$ANALYZE_SCRIPT" "$DATASET" "$METRICS_DIR" "$SUMMARY_CSV_TEMP"
done

cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"
cp "${SUMMARY_CSV_TEMP%.csv}_samples.csv" "${RESULTS_DIR}/table_14_multisssp_ligra_samples.csv"
touch "$STAMP"
echo "Summary saved at $SUMMARY_CSV"
