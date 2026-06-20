#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

RESULTS_DIR="${PROJECT_DIR}/results/15_throughput_bbss"

mkdir -p "$RESULTS_DIR"
run_python "${SCRIPT_DIR}/generate_runtime_table_15.py" \
    --xb_pro_csv="${RESULTS_DIR}/throughput_xb_pro.csv" \
    --xb_pp_csv="${RESULTS_DIR}/throughput_xb_pp.csv" \
    --csv_output="${RESULTS_DIR}/table_15_runtime_ci.csv" \
    --tex_output="${RESULTS_DIR}/table_15_runtime_ci.tex"
