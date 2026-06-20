#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

RESULTS_DIR="${PROJECT_DIR}/results/3_load_balance"
PYTHON_SCRIPT="${SCRIPT_DIR}/plot_figure_3.py"

require_file "${RESULTS_DIR}/table_3_left.csv" "Table 3 CPU summary CSV"
require_file "${RESULTS_DIR}/table_3_right.csv" "Table 3 GPU summary CSV"

run_python "$PYTHON_SCRIPT" \
    --cpu_csv="${RESULTS_DIR}/table_3_left.csv" \
    --gpu_csv="${RESULTS_DIR}/table_3_right.csv" \
    --output="${RESULTS_DIR}/plot_load_balance.png"

echo "Figure saved at ${RESULTS_DIR}/plot_load_balance.png"
