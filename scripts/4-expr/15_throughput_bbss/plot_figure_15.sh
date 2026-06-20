#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

RESULTS_DIR="${PROJECT_DIR}/results/15_throughput_bbss"
PYTHON_SCRIPT="${SCRIPT_DIR}/plot_figure_15.py"

mkdir -p "$RESULTS_DIR"
run_python "$PYTHON_SCRIPT" \
    --xb_pro_csv="${RESULTS_DIR}/throughput_xb_pro.csv" \
    --xb_pp_csv="${RESULTS_DIR}/throughput_xb_pp.csv" \
    --bfs_ligra_csv="${RESULTS_DIR}/throughput_bfs_ligra.csv" \
    --bfs_gunrock_csv="${RESULTS_DIR}/throughput_bfs_gunrock.csv" \
    --sssp_ligra_csv="${RESULTS_DIR}/throughput_sssp_ligra.csv" \
    --sssp_gunrock_csv="${RESULTS_DIR}/throughput_sssp_gunrock.csv" \
    --multisssp_ligra_csv="${RESULTS_DIR}/throughput_multisssp_ligra.csv" \
    --multisssp_gunrock_csv="${RESULTS_DIR}/throughput_multisssp_gunrock.csv" \
    --output="${RESULTS_DIR}/figure_15.png"
