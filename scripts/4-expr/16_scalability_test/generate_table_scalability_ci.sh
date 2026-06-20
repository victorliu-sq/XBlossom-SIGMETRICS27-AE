#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

METRICS_ROOT="${PROJECT_DIR}/tmp/16_scalability_test"
OUTPUT_TEX="${PROJECT_DIR}/results/16_scalability_test/tab_scalability_ci_tables.tex"
THREAD_LIST="${THREAD_LIST:-1 2 4 8 16 32 48}"
GPU_SMS="${GPU_SMS:-188}"
GPU_SM_LIST="${GPU_SM_LIST:-1 2 4 8 16 32 64 96 128 188}"
DATASETS=()
SM_CONFIGS=()

for entry in "${DATASET_XB_SCALABILITY_LIST[@]}"; do
  IFS='|' read -r DATASET _ _ _ <<< "$entry"
  DATASETS+=("$DATASET")
done

for sm in $GPU_SM_LIST; do
  if ((sm <= GPU_SMS)); then
    SM_CONFIGS+=("$sm")
  fi
done

run_python "${SCRIPT_DIR}/generate_table_scalability_ci.py" \
    --metrics-root "$METRICS_ROOT" \
    --output "$OUTPUT_TEX" \
    --datasets "${DATASETS[@]}" \
    --thread-configs $THREAD_LIST \
    --sm-configs "${SM_CONFIGS[@]}"

echo "LaTeX tables saved at ${OUTPUT_TEX}"
