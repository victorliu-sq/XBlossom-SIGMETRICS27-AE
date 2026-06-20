#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

RESULTS_DIR="${PROJECT_DIR}/results/8_runtime_four"
PYTHON_SCRIPT="${SCRIPT_DIR}/plot_figure_8.py"

mkdir -p "$RESULTS_DIR"
run_python "$PYTHON_SCRIPT" \
    --xb_pro_csv="${RESULTS_DIR}/figure_8_xb_pro.csv" \
    --xb_pp_csv="${RESULTS_DIR}/figure_8_xb_pp.csv" \
    --bfs_ligra_csv="${RESULTS_DIR}/figure_8_bfs_ligra.csv" \
    --bc_ligra_csv="${RESULTS_DIR}/figure_8_bc_ligra.csv" \
    --sssp_ligra_csv="${RESULTS_DIR}/figure_8_sssp_ligra.csv" \
    --bfs_gunrock_csv="${RESULTS_DIR}/figure_8_bfs_gunrock.csv" \
    --bc_gunrock_csv="${RESULTS_DIR}/figure_8_bc_gunrock.csv" \
    --sssp_gunrock_csv="${RESULTS_DIR}/figure_8_sssp_gunrock.csv" \
    --output="${RESULTS_DIR}/figure_8.png"
