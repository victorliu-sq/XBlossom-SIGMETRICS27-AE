#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

RESULTS_DIR="${PROJECT_DIR}/results/8_runtime_four"

mkdir -p "$RESULTS_DIR"
run_python "${SCRIPT_DIR}/generate_runtime_ci_tables.py" \
    --xb_pro_csv="${RESULTS_DIR}/figure_8_xb_pro.csv" \
    --bfs_ligra_csv="${RESULTS_DIR}/figure_8_bfs_ligra.csv" \
    --sssp_ligra_csv="${RESULTS_DIR}/figure_8_sssp_ligra.csv" \
    --mssp_ligra_csv="${RESULTS_DIR}/figure_8_multisssp_ligra.csv" \
    --csv_output="${RESULTS_DIR}/table_8_runtime_ci.csv" \
    --tex_output="${RESULTS_DIR}/table_8_runtime_ci.tex"
