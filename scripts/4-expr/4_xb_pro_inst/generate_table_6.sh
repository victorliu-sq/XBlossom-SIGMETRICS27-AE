#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

RESULTS_DIR="${PROJECT_DIR}/results/4_xb_pro_inst"

mkdir -p "$RESULTS_DIR"
run_python "${SCRIPT_DIR}/generate_table_6.py" \
    --node_csv="${RESULTS_DIR}/figure_7_xb_pro_node.csv" \
    --edge_csv="${RESULTS_DIR}/figure_7_xb_pro_edge.csv" \
    --csv_output="${RESULTS_DIR}/tab_xb_pro_inst_ci.csv" \
    --tex_output="${RESULTS_DIR}/tab_xb_pro_inst_ci.tex"
