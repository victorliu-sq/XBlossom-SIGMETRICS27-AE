#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

METRICS_DIR="${PROJECT_DIR}/tmp/9_scalability_test/xb_pp_edge_gpu_sm"
OUTPUT_TEX="${PROJECT_DIR}/results/9_scalability_test/tab_xb_pp_edge_gpu_sm_scalability_ci.tex"
GPU_SMS="${GPU_SMS:-188}"
GPU_SM_LIST="${GPU_SM_LIST:-1 2 4 8 16 32 64 96 128 188}"
DATASETS=()
CONFIGS=()

for entry in "${DATASET_XB_SCALABILITY_LIST[@]}"; do
  IFS='|' read -r DATASET _ _ _ <<< "$entry"
  DATASETS+=("$DATASET")
done

for sm in $GPU_SM_LIST; do
  if ((sm <= GPU_SMS)); then
    CONFIGS+=("$sm")
  fi
done

run_python "${SCRIPT_DIR}/generate_table_xb_pp_edge_gpu_sm.py" \
    --metrics-dir "$METRICS_DIR" \
    --output "$OUTPUT_TEX" \
    --datasets "${DATASETS[@]}" \
    --configs "${CONFIGS[@]}" \
    --prefix "xb_pp_edge" \
    --suffix "sms" \
    --title "XB++ edge-level GPU scalability" \
    --config-label "maximum GPU SM counts"

echo "LaTeX table saved at ${OUTPUT_TEX}"
