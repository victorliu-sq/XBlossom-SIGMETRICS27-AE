#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

RESULTS_DIR="${PROJECT_DIR}/results/10_memory_four"
PYTHON_SCRIPT="${SCRIPT_DIR}/generate_table_10.py"

mkdir -p "$RESULTS_DIR"
run_python "$PYTHON_SCRIPT" \
    --xb_pro_csv="${RESULTS_DIR}/table_10_xb_pro.csv" \
    --xb_pp_csv="${RESULTS_DIR}/table_10_xb_pp.csv" \
    --bfs_ligra_csv="${RESULTS_DIR}/table_10_bfs_ligra.csv" \
    --bc_ligra_csv="${RESULTS_DIR}/table_10_bc_ligra.csv" \
    --sssp_ligra_csv="${RESULTS_DIR}/table_10_sssp_ligra.csv" \
    --bfs_gunrock_csv="${RESULTS_DIR}/table_10_bfs_gunrock.csv" \
    --bc_gunrock_csv="${RESULTS_DIR}/table_10_bc_gunrock.csv" \
    --sssp_gunrock_csv="${RESULTS_DIR}/table_10_sssp_gunrock.csv" \
    --output="${RESULTS_DIR}/table_10.csv"
