#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

RESULTS_DIR="${PROJECT_DIR}/results/12_runtime_four_bbss"

mkdir -p "$RESULTS_DIR"
run_python "${SCRIPT_DIR}/generate_table_12.py" \
    --metrics_root="${PROJECT_DIR}/tmp/12_runtime_four_bbss" \
    --samples_root="${RESULTS_DIR}" \
    --xb_pro_csv="${RESULTS_DIR}/figure_12_xb_pro.csv" \
    --xb_pp_csv="${RESULTS_DIR}/figure_12_xb_pp.csv" \
    --csv_output="${RESULTS_DIR}/tab_runtime_four_ci.csv" \
    --tex_output="${RESULTS_DIR}/tab_runtime_four_ci.tex"
