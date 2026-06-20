#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

RESULTS_DIR="${PROJECT_DIR}/results/8_memory_four_bbss"

mkdir -p "$RESULTS_DIR"
run_python "${SCRIPT_DIR}/generate_cpu_ci_table_8.py" \
    --xb_pro_csv="${RESULTS_DIR}/table_8_xb_pro.csv" \
    --bfs_ligra_csv="${RESULTS_DIR}/table_8_bfs_ligra.csv" \
    --sssp_ligra_csv="${RESULTS_DIR}/table_8_sssp_ligra.csv" \
    --mssp_ligra_csv="${RESULTS_DIR}/table_8_multisssp_ligra.csv" \
    --csv_output="${RESULTS_DIR}/table_8_cpu_memory_ci.csv" \
    --tex_output="${RESULTS_DIR}/table_8_cpu_memory_ci.tex"
