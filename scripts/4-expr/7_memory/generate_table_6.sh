#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

RESULTS_DIR="${PROJECT_DIR}/results/7_memory"
PYTHON_SCRIPT="${SCRIPT_DIR}/generate_table_6.py"

mkdir -p "$RESULTS_DIR"
run_python "$PYTHON_SCRIPT" \
    --xb_pro_csv="${RESULTS_DIR}/table_6_xb_pro.csv" \
    --xb_pp_csv="${RESULTS_DIR}/table_6_xb_pp.csv" \
    --bfs_ligra_csv="${RESULTS_DIR}/table_6_bfs_ligra.csv" \
    --bfs_gunrock_csv="${RESULTS_DIR}/table_6_bfs_gunrock.csv"
