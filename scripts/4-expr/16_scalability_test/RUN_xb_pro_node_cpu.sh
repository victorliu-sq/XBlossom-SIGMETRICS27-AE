#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

XB_PRO_NODE_BIN="${XB_BIN_DIR}/run_xb_pro_pernode_by_dataset"
METRICS_DIR="${PROJECT_DIR}/tmp/16_scalability_test/xb_pro_node_cpu"
RESULTS_DIR="${PROJECT_DIR}/results/16_scalability_test"
SUMMARY_CSV="${RESULTS_DIR}/xb_pro_node_cpu_scalability.csv"
ROUNDS="${ROUNDS:-20}"
THREAD_LIST="${THREAD_LIST:-1 2 4 8 16 32 48}"
XB_PRO_ONLY_DATASETS="${XB_PRO_ONLY_DATASETS:-}"

require_executable "$XB_PRO_NODE_BIN" "XB-Pro node-level binary"
rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR" "$RESULTS_DIR"

if [[ -n "$XB_PRO_ONLY_DATASETS" && -f "$SUMMARY_CSV" ]]; then
  SUMMARY_CSV_TEMP="${METRICS_DIR}/_xb_pro_node_cpu_scalability.csv"
  seed_csv_excluding_datasets "$SUMMARY_CSV" "$SUMMARY_CSV_TEMP" "$XB_PRO_ONLY_DATASETS"
  mv "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"
else
  printf 'Dataset,Threads,AvgRuntime(s),Speedup\n' > "$SUMMARY_CSV"
fi

if [[ -n "$XB_PRO_ONLY_DATASETS" ]]; then
  DATASET_LIST=("${DATASET_CSR_LIST[@]}")
else
  DATASET_LIST=("${DATASET_XB_SCALABILITY_LIST[@]}")
fi

for entry in "${DATASET_LIST[@]}"; do
  IFS='|' read -r DATASET ROW_OFFSETS COL_INDICES PATH_BUFFER_RATIO <<< "$entry"
  selected_dataset "$DATASET" "$XB_PRO_ONLY_DATASETS" || continue

  require_file "$ROW_OFFSETS" "${DATASET} row offsets"
  require_file "$COL_INDICES" "${DATASET} column indices"

  base_runtime=""
  for threads in $THREAD_LIST; do
    TIMING_OUT="${METRICS_DIR}/xb_pro_node_${DATASET}_${threads}t.txt"
    : > "$TIMING_OUT"

    echo "Running XB-Pro node-level on ${DATASET} with ${threads} CPU threads (${ROUNDS} rounds)..."
    "$XB_PRO_NODE_BIN" \
        --dataset="$DATASET" \
        --rounds="$ROUNDS" \
        --row_offsets="$ROW_OFFSETS" \
        --col_indices="$COL_INDICES" \
        --path_buffer_ratio="$PATH_BUFFER_RATIO" \
        --num_threads="$threads" \
        | tee -a "$TIMING_OUT"

    runtime="$(awk '/Average runtime:/ {value=$3} END {if (value == "") exit 1; print value}' "$TIMING_OUT")"
    if [[ -z "$base_runtime" ]]; then
      base_runtime="$runtime"
    fi
    speedup="$(awk -v base="$base_runtime" -v current="$runtime" 'BEGIN {printf "%.6f", base / current}')"
    printf '%s,%s,%.6f,%s\n' "$DATASET" "$threads" "$runtime" "$speedup" >> "$SUMMARY_CSV"
  done
done

echo "Summary saved at ${SUMMARY_CSV}"
