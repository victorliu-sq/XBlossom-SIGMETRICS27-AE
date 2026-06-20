#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

RESULTS_DIR="${PROJECT_DIR}/results/8_runtime_four"
ANALYZE_SCRIPT="${SCRIPT_DIR}/analyze_ligra_time.sh"
ROUNDS="${ROUNDS:-20}"
SYMMETICS_TRUE=1

METRICS_DIR="${PROJECT_DIR}/tmp/8_runtime_four/multisssp_ligra"
SUMMARY_CSV_TEMP="${METRICS_DIR}/_multisssp_ligra_summary.csv"
SUMMARY_CSV="${RESULTS_DIR}/figure_8_multisssp_ligra.csv"
SAMPLES_CSV="${RESULTS_DIR}/figure_8_multisssp_ligra_samples.csv"
STAMP="${RESULTS_DIR}/.stamp.figure_8_multisssp_ligra"

if [[ -f "$STAMP" ]]; then
  echo "Figure 8 MultiSSSP Ligra part already generated (stamp found)"
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

  TIMING_OUT="${METRICS_DIR}/ligra_${DATASET}_src${SRC}_timing.txt"
  PROFILER_OUT="${METRICS_DIR}/ligra_${DATASET}_src${SRC}_profiling.txt"
  : > "$TIMING_OUT"
  : > "$PROFILER_OUT"

  echo "Profiling Ligra-MultiSSSP on ${DATASET} (${ROUNDS} rounds, symmetric=${SYMMETICS_TRUE}, src=${SRC})..."
  perf stat -a -x, -e instructions -o "$PROFILER_OUT" -- \
      "$LIGRA_MULTISSSP_BIN" -rounds "$ROUNDS" --src-count "$SRC_COUNT" -s "$LIGRA_GRAPH" | tee -a "$TIMING_OUT"
  "$ANALYZE_SCRIPT" "$DATASET" "$METRICS_DIR" "$SUMMARY_CSV_TEMP"
done

cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"
cp "${SUMMARY_CSV_TEMP%.csv}_samples.csv" "$SAMPLES_CSV"
touch "$STAMP"
echo "Summary saved at $SUMMARY_CSV"
