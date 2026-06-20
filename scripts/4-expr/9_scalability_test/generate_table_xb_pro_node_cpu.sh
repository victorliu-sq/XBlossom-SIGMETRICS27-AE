#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

METRICS_DIR="${PROJECT_DIR}/tmp/9_scalability_test/xb_pro_node_cpu"
OUTPUT_TEX="${PROJECT_DIR}/results/9_scalability_test/tab_xb_pro_node_cpu_scalability_ci.tex"
THREAD_LIST="${THREAD_LIST:-1 2 4 8 16 32 48}"
DATASETS=()

for entry in "${DATASET_XB_SCALABILITY_LIST[@]}"; do
  IFS='|' read -r DATASET _ _ _ <<< "$entry"
  DATASETS+=("$DATASET")
done

run_python "${SCRIPT_DIR}/generate_table_xb_pro_node_cpu.py" \
    --metrics-dir "$METRICS_DIR" \
    --output "$OUTPUT_TEX" \
    --datasets "${DATASETS[@]}" \
    --configs $THREAD_LIST \
    --prefix "xb_pro_node" \
    --suffix "t" \
    --title "XB-Pro node-level CPU scalability" \
    --config-label "CPU thread counts"

echo "LaTeX table saved at ${OUTPUT_TEX}"
