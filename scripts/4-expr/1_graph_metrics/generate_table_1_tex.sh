#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

RESULTS_DIR="${PROJECT_DIR}/results/1_graph_metrics"
SUMMARY_CSV="${RESULTS_DIR}/graph_metrics.csv"
SUMMARY_TEX="${RESULTS_DIR}/tab_graph_metrics.tex"
SUMMARY_TEX_CI="${RESULTS_DIR}/tab_graph_metrics_ci.tex"

require_file "$SUMMARY_CSV" "Table 1 graph metrics CSV"

run_python "${SCRIPT_DIR}/generate_table_1_tex.py" \
    "$SUMMARY_CSV" \
    "$SUMMARY_TEX"

echo "LaTeX table saved at ${SUMMARY_TEX}"
echo "LaTeX table with CI saved at ${SUMMARY_TEX_CI}"
