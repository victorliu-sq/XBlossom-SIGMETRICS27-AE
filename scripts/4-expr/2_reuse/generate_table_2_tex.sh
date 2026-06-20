#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

RESULTS_DIR="${PROJECT_DIR}/results/2_reuse"
CPU_SUMMARY_CSV="${RESULTS_DIR}/table_2_left.csv"
GPU_SUMMARY_CSV="${RESULTS_DIR}/table_2_right.csv"
SUMMARY_TEX="${RESULTS_DIR}/tab_reuse.tex"
SUMMARY_TEX_CI="${RESULTS_DIR}/tab_reuse_ci.tex"

require_file "$CPU_SUMMARY_CSV" "Table 2 CPU summary CSV"
require_file "$GPU_SUMMARY_CSV" "Table 2 GPU summary CSV"

run_python "${SCRIPT_DIR}/generate_table_2_tex.py" \
    "$CPU_SUMMARY_CSV" \
    "$GPU_SUMMARY_CSV" \
    "$SUMMARY_TEX"

echo "LaTeX table saved at ${SUMMARY_TEX}"
echo "LaTeX table with CI saved at ${SUMMARY_TEX_CI}"
