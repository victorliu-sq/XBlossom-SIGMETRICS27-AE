#!/usr/bin/env bash
set -euo pipefail

PYTHON_SCRIPT="expr/experiments/table_6/generate_table_6.py"
RESULTS_DIR="data/results"
XB_PRO_SUMMARY_CSV="$RESULTS_DIR/table_6_xb_pro.csv"
XB_PP_SUMMARY_CSV="$RESULTS_DIR/table_6_xb_pp.csv"
BFS_LIGRA_SUMMARY_CSV="$RESULTS_DIR/table_6_bfs_ligra.csv"
BFS_GUNROCK_SUMMARY_CSV="$RESULTS_DIR/table_6_bfs_gunrock.csv"

echo "Generating Table-6 csv "

conda run -n xb-env python3 "$PYTHON_SCRIPT" \
    --xb_pro_csv="$XB_PRO_SUMMARY_CSV" \
    --xb_pp_csv="$XB_PP_SUMMARY_CSV" \
    --bfs_ligra_csv="$BFS_LIGRA_SUMMARY_CSV" \
    --bfs_gunrock_csv="$BFS_GUNROCK_SUMMARY_CSV"
