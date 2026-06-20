#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

RESULTS_DIR="${PROJECT_DIR}/results/3_load_balance"
CPU_SUMMARY_CSV="${RESULTS_DIR}/table_3_left.csv"
GPU_SUMMARY_CSV="${RESULTS_DIR}/table_3_right.csv"
SUMMARY_TEX="${RESULTS_DIR}/tab_load_balance.tex"
SUMMARY_TEX_CI="${RESULTS_DIR}/tab_load_balance_ci.tex"

require_file "$CPU_SUMMARY_CSV" "Table 3 CPU summary CSV"
require_file "$GPU_SUMMARY_CSV" "Table 3 GPU summary CSV"

run_python "${SCRIPT_DIR}/generate_table_3_tex.py" \
    "$CPU_SUMMARY_CSV" \
    "$GPU_SUMMARY_CSV" \
    "$SUMMARY_TEX"

echo "LaTeX table saved at ${SUMMARY_TEX}"
echo "LaTeX table with CI saved at ${SUMMARY_TEX_CI}"
