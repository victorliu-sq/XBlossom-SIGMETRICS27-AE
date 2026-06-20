#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

PER_NODE_BIN="${XB_BIN_DIR}/run_xb_pp_pernode_by_dataset"
PER_EDGE_BIN="${XB_BIN_DIR}/run_xb_pp_peredge_by_dataset"
METRICS_DIR="${PROJECT_DIR}/tmp/3_load_balance/gpu"
RESULTS_DIR="${PROJECT_DIR}/results/3_load_balance"
STAMP="${RESULTS_DIR}/.stamp.table_3_gpu"
SUMMARY_CSV="${RESULTS_DIR}/table_3_right.csv"
ROUNDS="${ROUNDS:-20}"

if [[ -f "$STAMP" ]]; then
  echo "Table 3 GPU part already generated (stamp found)"
  exit 0
fi

require_executable "$PER_NODE_BIN" "XB-PP per-node binary"
require_executable "$PER_EDGE_BIN" "XB-PP per-edge binary"
rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR" "$RESULTS_DIR"

for entry in "${DATASET_CSR_LIST[@]}"; do
  IFS='|' read -r DATASET ROW_OFFSETS COL_INDICES PATH_BUFFER_RATIO <<< "$entry"
  require_file "$ROW_OFFSETS" "${DATASET} row offsets"
  require_file "$COL_INDICES" "${DATASET} column indices"

  TIMING_OUT_PEREDGE="${METRICS_DIR}/xb_pp_peredge_${DATASET}_timing.txt"
  TIMING_OUT_PERNODE="${METRICS_DIR}/xb_pp_pernode_${DATASET}_timing.txt"
  : > "$TIMING_OUT_PEREDGE"
  : > "$TIMING_OUT_PERNODE"

  echo "Running XB-PP per-edge on ${DATASET} (${ROUNDS} rounds)..."
  run_xb_dataset \
      "$PER_EDGE_BIN" \
      "$DATASET" \
      "$ROUNDS" \
      "$ROW_OFFSETS" \
      "$COL_INDICES" \
      "$PATH_BUFFER_RATIO" \
      | tee -a "$TIMING_OUT_PEREDGE"

  echo "Running XB-PP per-node on ${DATASET} (${ROUNDS} rounds)..."
  run_xb_dataset \
      "$PER_NODE_BIN" \
      "$DATASET" \
      "$ROUNDS" \
      "$ROW_OFFSETS" \
      "$COL_INDICES" \
      "$PATH_BUFFER_RATIO" \
      | tee -a "$TIMING_OUT_PERNODE"

done

touch "$STAMP"
echo "Timing files saved under ${METRICS_DIR}"
echo "Run ${SCRIPT_DIR}/generate_table_gpu.sh to generate ${SUMMARY_CSV}"
