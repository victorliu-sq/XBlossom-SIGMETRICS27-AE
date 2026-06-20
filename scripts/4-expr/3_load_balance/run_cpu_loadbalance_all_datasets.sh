#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

PER_EDGE_BIN="${XB_BIN_DIR}/run_xb_pro_peredge_by_dataset"
PER_NODE_BIN="${XB_BIN_DIR}/run_xb_pro_pernode_by_dataset"
METRICS_DIR="${PROJECT_DIR}/tmp/3_load_balance/cpu"
RESULTS_DIR="${PROJECT_DIR}/results/3_load_balance"
STAMP="${RESULTS_DIR}/.stamp.table_3_cpu"
SUMMARY_CSV="${RESULTS_DIR}/table_3_left.csv"
XB_THREADS="${XB_THREADS:-$(default_xb_pro_threads)}"
ROUNDS="${ROUNDS:-20}"

if [[ -f "$STAMP" ]]; then
  echo "Table 3 CPU part already generated (stamp found)"
  exit 0
fi

require_executable "$PER_EDGE_BIN" "XB-Pro per-edge binary"
require_executable "$PER_NODE_BIN" "XB-Pro per-node binary"
rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR" "$RESULTS_DIR"

for entry in "${DATASET_CSR_LIST[@]}"; do
  IFS='|' read -r DATASET ROW_OFFSETS COL_INDICES PATH_BUFFER_RATIO <<< "$entry"
  require_file "$ROW_OFFSETS" "${DATASET} row offsets"
  require_file "$COL_INDICES" "${DATASET} column indices"

  TIMING_OUT_PEREDGE="${METRICS_DIR}/xb_pro_peredge_${DATASET}_timing.txt"
  TIMING_OUT_PERNODE="${METRICS_DIR}/xb_pro_pernode_${DATASET}_timing.txt"
  : > "$TIMING_OUT_PEREDGE"
  : > "$TIMING_OUT_PERNODE"

  echo "Running XB-Pro per-edge on ${DATASET} (${ROUNDS} rounds, ${XB_THREADS} threads)..."
  "$PER_EDGE_BIN" --dataset="$DATASET" --rounds="$ROUNDS" --num_threads="$XB_THREADS" --row_offsets="$ROW_OFFSETS" --col_indices="$COL_INDICES" --path_buffer_ratio="$PATH_BUFFER_RATIO" | tee -a "$TIMING_OUT_PEREDGE"

  echo "Running XB-Pro per-node on ${DATASET} (${ROUNDS} rounds, ${XB_THREADS} threads)..."
  "$PER_NODE_BIN" --dataset="$DATASET" --rounds="$ROUNDS" --num_threads="$XB_THREADS" --row_offsets="$ROW_OFFSETS" --col_indices="$COL_INDICES" --path_buffer_ratio="$PATH_BUFFER_RATIO" | tee -a "$TIMING_OUT_PERNODE"

done

touch "$STAMP"
echo "Timing files saved under ${METRICS_DIR}"
echo "Run ${SCRIPT_DIR}/generate_table_cpu.sh to generate ${SUMMARY_CSV}"
