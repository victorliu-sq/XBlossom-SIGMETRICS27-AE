#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

RESULTS_DIR="${PROJECT_DIR}/results/11_throughput"
PYTHON_SCRIPT="${SCRIPT_DIR}/generate_table_11.py"

mkdir -p "$RESULTS_DIR"
run_python "$PYTHON_SCRIPT" \
    --xb_pro_csv="${RESULTS_DIR}/throughput_xb_pro.csv" \
    --xb_pp_csv="${RESULTS_DIR}/throughput_xb_pp.csv" \
    --bfs_ligra_csv="${RESULTS_DIR}/throughput_bfs_ligra.csv" \
    --bfs_gunrock_csv="${RESULTS_DIR}/throughput_bfs_gunrock.csv" \
    --bc_ligra_csv="${RESULTS_DIR}/throughput_bc_ligra.csv" \
    --bc_gunrock_csv="${RESULTS_DIR}/throughput_bc_gunrock.csv" \
    --sssp_ligra_csv="${RESULTS_DIR}/throughput_sssp_ligra.csv" \
    --sssp_gunrock_csv="${RESULTS_DIR}/throughput_sssp_gunrock.csv" \
    --output="${RESULTS_DIR}/table_11.csv"
