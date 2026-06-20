#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

RESULTS_DIR="${PROJECT_DIR}/results/4_xb_pro_inst"
PYTHON_SCRIPT="${SCRIPT_DIR}/plot_figure_7.py"

mkdir -p "$RESULTS_DIR"
run_python "$PYTHON_SCRIPT" \
    --node_csv="${RESULTS_DIR}/figure_7_xb_pro_node.csv" \
    --edge_csv="${RESULTS_DIR}/figure_7_xb_pro_edge.csv"
