#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

XB_PRO_BIN="${XB_BIN_DIR}/run_xb_pro_pernode_by_dataset"
METRICS_DIR="${PROJECT_DIR}/tmp/4_xb_pro_inst/node"
RESULTS_DIR="${PROJECT_DIR}/results/4_xb_pro_inst"
STAMP="${RESULTS_DIR}/.stamp.figure_7_xbpro_node"
ANALYZE_SCRIPT="${SCRIPT_DIR}/analyze_xb_pro_inst_node.sh"
SUMMARY_CSV_TEMP="${METRICS_DIR}/_xb_pro_node_summary.csv"
SUMMARY_CSV="${RESULTS_DIR}/figure_7_xb_pro_node.csv"
SAMPLES_CSV="${RESULTS_DIR}/figure_7_xb_pro_node_samples.csv"
COMBINED_SAMPLES_CSV="${RESULTS_DIR}/figure_7_xb_pro_node_edge_rounds.csv"
ROUNDS="${ROUNDS:-20}"
ITERATIONS="${ITERATIONS:-5}"
XB_PRO_DEFAULT_THREADS="${XB_PRO_THREADS:-$(default_xb_pro_threads)}"
XB_PRO_ONLY_DATASETS="${XB_PRO_ONLY_DATASETS:-}"

if [[ -z "$XB_PRO_ONLY_DATASETS" && -f "$STAMP" ]]; then
  echo "Figure 7 XB-Pro node part already generated (stamp found)"
  exit 0
fi

require_executable "$XB_PRO_BIN" "XB-Pro per-node binary"
rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR" "$RESULTS_DIR"
seed_csv_excluding_datasets "$SAMPLES_CSV" "${SUMMARY_CSV_TEMP%.csv}_samples.csv" "$XB_PRO_ONLY_DATASETS"
if [[ -n "$XB_PRO_ONLY_DATASETS" && -f "$COMBINED_SAMPLES_CSV" ]]; then
  awk -F, -v datasets="$XB_PRO_ONLY_DATASETS" '
    BEGIN {
      split(datasets, names, " ")
      for (idx in names) {
        excluded[names[idx]] = 1
      }
    }
    NR == 1 || !($1 in excluded && $2 == "node")
  ' "$COMBINED_SAMPLES_CSV" > "${METRICS_DIR}/_combined_samples.csv"
  cp "${METRICS_DIR}/_combined_samples.csv" "$COMBINED_SAMPLES_CSV"
else
  : > "$COMBINED_SAMPLES_CSV"
fi

for entry in "${DATASET_CSR_LIST[@]}"; do
  IFS='|' read -r DATASET ROW_OFFSETS COL_INDICES PATH_BUFFER_RATIO <<< "$entry"
  selected_dataset "$DATASET" "$XB_PRO_ONLY_DATASETS" || continue
  CURRENT_XB_PRO_THREADS="$(xb_pro_threads_for_dataset "$DATASET" "$XB_PRO_DEFAULT_THREADS")"
  for ITERATION in $(seq 1 "$ITERATIONS"); do
    TIMING_OUT="${METRICS_DIR}/xb_pro_node_${DATASET}_iter_${ITERATION}_timing.txt"
    PROFILER_OUT="${METRICS_DIR}/xb_pro_node_${DATASET}_iter_${ITERATION}_profiling.txt"
    : > "$TIMING_OUT"
    : > "$PROFILER_OUT"

    echo "Profiling XB-Pro node ${DATASET} iteration ${ITERATION}/${ITERATIONS} (${ROUNDS} rounds, ${CURRENT_XB_PRO_THREADS} threads)..."
    perf stat -a -x, -e instructions -o "$PROFILER_OUT" -- \
        "$XB_PRO_BIN" --dataset="$DATASET" --rounds="$ROUNDS" --num_threads="$CURRENT_XB_PRO_THREADS" --row_offsets="$ROW_OFFSETS" --col_indices="$COL_INDICES" --path_buffer_ratio="$PATH_BUFFER_RATIO" \
        | tee -a "$TIMING_OUT"
    "$ANALYZE_SCRIPT" "$DATASET" "$TIMING_OUT" "$PROFILER_OUT" "$SUMMARY_CSV_TEMP" "$ROUNDS" "$ITERATION" "$COMBINED_SAMPLES_CSV"
  done
done

cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"
cp "${SUMMARY_CSV_TEMP%.csv}_samples.csv" "$SAMPLES_CSV"
touch "$STAMP"
echo "Summary saved at ${SUMMARY_CSV}"
