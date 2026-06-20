#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

RESULTS_DIR="${PROJECT_DIR}/results/7_inst_rate_four_bbss"

mkdir -p "$RESULTS_DIR"
run_python "${SCRIPT_DIR}/generate_cpu_ci_table_7.py" \
    --xb_pro_csv="${RESULTS_DIR}/table_7_xb_pro.csv" \
    --bfs_ligra_csv="${RESULTS_DIR}/table_7_bfs_ligra.csv" \
    --sssp_ligra_csv="${RESULTS_DIR}/table_7_sssp_ligra.csv" \
    --mssp_ligra_csv="${RESULTS_DIR}/table_7_multisssp_ligra.csv" \
    --csv_output="${RESULTS_DIR}/table_7_cpu_inst_ci.csv" \
    --tex_output="${RESULTS_DIR}/table_7_cpu_inst_ci.tex"
