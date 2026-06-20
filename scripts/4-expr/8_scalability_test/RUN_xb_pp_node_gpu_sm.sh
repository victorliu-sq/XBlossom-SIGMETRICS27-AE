#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

XB_PP_NODE_BIN="${XB_BIN_DIR}/run_xb_pp_pernode_by_dataset"
METRICS_DIR="${PROJECT_DIR}/tmp/8_scalability_test/xb_pp_node_gpu_sm"
RESULTS_DIR="${PROJECT_DIR}/results/8_scalability_test"
SUMMARY_CSV="${RESULTS_DIR}/xb_pp_node_gpu_sm_scalability.csv"
ROUNDS="${ROUNDS:-20}"

GPU_SMS="${GPU_SMS:-188}"
GPU_SM_LIST="${GPU_SM_LIST:-1 2 4 8 16 32 64 96 128 188}"

require_executable "$XB_PP_NODE_BIN" "XB++ node-level binary"
rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR" "$RESULTS_DIR"

printf 'Dataset,MaxCUDASMs,SMPercent,AvgRuntime(s),Speedup\n' > "$SUMMARY_CSV"

for entry in "${DATASET_XB_SCALABILITY_LIST[@]}"; do
  IFS='|' read -r DATASET ROW_OFFSETS COL_INDICES PATH_BUFFER_RATIO <<< "$entry"

  require_file "$ROW_OFFSETS" "${DATASET} row offsets"
  require_file "$COL_INDICES" "${DATASET} column indices"

  base_runtime=""
  for max_cuda_sms in $GPU_SM_LIST; do
    if ((max_cuda_sms > GPU_SMS)); then
      continue
    fi

    sm_percent="$(awk -v used="$max_cuda_sms" -v total="$GPU_SMS" 'BEGIN {printf "%.6f", used * 100.0 / total}')"
    TIMING_OUT="${METRICS_DIR}/xb_pp_node_${DATASET}_${max_cuda_sms}sms.txt"
    : > "$TIMING_OUT"

    echo "Running XB++ node-level on ${DATASET} with max ${max_cuda_sms}/${GPU_SMS} SMs (${ROUNDS} rounds)..."
    "$XB_PP_NODE_BIN" \
        --dataset="$DATASET" \
        --rounds="$ROUNDS" \
        --row_offsets="$ROW_OFFSETS" \
        --col_indices="$COL_INDICES" \
        --path_buffer_ratio="$PATH_BUFFER_RATIO" \
        --max_cuda_sms="$max_cuda_sms" \
        | tee -a "$TIMING_OUT"

    runtime="$(awk '/Average runtime:/ {value=$3} END {if (value == "") exit 1; print value}' "$TIMING_OUT")"
    if [[ -z "$base_runtime" ]]; then
      base_runtime="$runtime"
    fi
    speedup="$(awk -v base="$base_runtime" -v current="$runtime" 'BEGIN {printf "%.6f", base / current}')"
    printf '%s,%s,%s,%.6f,%s\n' "$DATASET" "$max_cuda_sms" "$sm_percent" "$runtime" "$speedup" >> "$SUMMARY_CSV"
  done
done

echo "Summary saved at ${SUMMARY_CSV}"
