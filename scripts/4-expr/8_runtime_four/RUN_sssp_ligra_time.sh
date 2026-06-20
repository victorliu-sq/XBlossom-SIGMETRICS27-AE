#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

RESULTS_DIR="${PROJECT_DIR}/results/8_runtime_four"
ANALYZE_SCRIPT="${SCRIPT_DIR}/analyze_ligra_time.sh"
ROUNDS="${ROUNDS:-20}"
SYMMETICS_TRUE=1

METRICS_DIR="${PROJECT_DIR}/tmp/8_runtime_four/sssp_ligra"
SUMMARY_CSV_TEMP="${METRICS_DIR}/_sssp_ligra_summary.csv"
SUMMARY_CSV="${RESULTS_DIR}/figure_8_sssp_ligra.csv"
STAMP="${RESULTS_DIR}/.stamp.figure_8_sssp_ligra"

if [[ -f "$STAMP" ]]; then
  echo "Figure 8 SSSP Ligra part already generated (stamp found)"
  exit 0
fi

require_executable "$LIGRA_SSSP_BIN" "Ligra SSSP binary"
rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR" "$RESULTS_DIR"

for entry in "${DATASET_SSSP_LIST[@]}"; do
  IFS='|' read -r DATASET LIGRA_GRAPH _GUNROCK_GRAPH SRC_FILE <<< "$entry"
  require_file "$LIGRA_GRAPH" "${DATASET} Ligra weighted graph"
  require_file "$SRC_FILE" "${DATASET} source list"
  SRC="$(first_source_node "$SRC_FILE")"

  TIMING_OUT="${METRICS_DIR}/ligra_${DATASET}_src${SRC}_timing.txt"
  PROFILER_OUT="${METRICS_DIR}/ligra_${DATASET}_src${SRC}_profiling.txt"
  : > "$TIMING_OUT"
  : > "$PROFILER_OUT"

  echo "Profiling Ligra-SSSP on ${DATASET} (${ROUNDS} rounds, symmetric=${SYMMETICS_TRUE}, src=${SRC})..."
  perf stat -a -x, -e instructions -o "$PROFILER_OUT" -- \
      "$LIGRA_SSSP_BIN" -rounds "$ROUNDS" -r "$SRC" -s "$LIGRA_GRAPH" | tee -a "$TIMING_OUT"
  "$ANALYZE_SCRIPT" "$DATASET" "$METRICS_DIR" "$SUMMARY_CSV_TEMP"
done

cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"
cp "${SUMMARY_CSV_TEMP%.csv}_samples.csv" "${RESULTS_DIR}/figure_8_sssp_ligra_samples.csv"
touch "$STAMP"
echo "Summary saved at $SUMMARY_CSV"
