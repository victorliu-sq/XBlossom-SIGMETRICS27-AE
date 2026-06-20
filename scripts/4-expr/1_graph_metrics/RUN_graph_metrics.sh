#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

XB_PP_BIN="${XB_BIN_DIR}/run_xb_pp_by_dataset"
METRICS_DIR="${PROJECT_DIR}/tmp/1_graph_metrics"
RESULTS_DIR="${PROJECT_DIR}/results/1_graph_metrics"
STAMP="${RESULTS_DIR}/.stamp.1_graph_metrics"
ROUNDS="${ROUNDS:-50}"

if [[ -f "$STAMP" ]]; then
  echo "Graph metrics logs already generated (stamp found)"
  exit 0
fi

require_executable "$XB_PP_BIN" "XB++ binary"
rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR" "$RESULTS_DIR"

for entry in "${DATASET_CSR_LIST[@]}"; do
  IFS='|' read -r DATASET ROW_OFFSETS COL_INDICES PATH_BUFFER_RATIO <<< "$entry"
  require_file "$ROW_OFFSETS" "${DATASET} row offsets"
  require_file "$COL_INDICES" "${DATASET} column indices"

  GRAPH_METRICS_OUT="${METRICS_DIR}/graph_metrics_${DATASET}.txt"
  : > "$GRAPH_METRICS_OUT"

  echo "============================================================"
  echo "Running XB++ graph metrics on ${DATASET} (${ROUNDS} rounds)..."
  echo "------------------------------------------------------------"

  "$XB_PP_BIN" \
      --dataset="$DATASET" \
      --rounds="$ROUNDS" \
      --row_offsets="$ROW_OFFSETS" \
      --col_indices="$COL_INDICES" \
      --path_buffer_ratio="$PATH_BUFFER_RATIO" \
      | tee -a "$GRAPH_METRICS_OUT"
done

touch "$STAMP"

echo "============================================================"
echo "Graph metrics logs saved under ${METRICS_DIR}"
echo "Run ${SCRIPT_DIR}/generate_table_csv.sh to generate the CSV table."
echo "Run ${SCRIPT_DIR}/generate_table_1_tex.sh to generate the LaTeX tables."
echo "============================================================"
