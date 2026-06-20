#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

RESULTS_DIR="${PROJECT_DIR}/results/9_inst_rate_four"
PYTHON_SCRIPT="${SCRIPT_DIR}/generate_table_9.py"

mkdir -p "$RESULTS_DIR"
run_python "$PYTHON_SCRIPT" \
    --xb_pro_csv="${RESULTS_DIR}/table_9_xb_pro.csv" \
    --xb_pp_csv="${RESULTS_DIR}/table_9_xb_pp.csv" \
    --bfs_ligra_csv="${RESULTS_DIR}/table_9_bfs_ligra.csv" \
    --bc_ligra_csv="${RESULTS_DIR}/table_9_bc_ligra.csv" \
    --sssp_ligra_csv="${RESULTS_DIR}/table_9_sssp_ligra.csv" \
    --bfs_gunrock_csv="${RESULTS_DIR}/table_9_bfs_gunrock.csv" \
    --bc_gunrock_csv="${RESULTS_DIR}/table_9_bc_gunrock.csv" \
    --sssp_gunrock_csv="${RESULTS_DIR}/table_9_sssp_gunrock.csv" \
    --output="${RESULTS_DIR}/table_9.csv"
