#!/usr/bin/env bash
set -euo pipefail

PYTHON_SCRIPT="expr/experiments/figure_7/plot_figure_7.py"
RESULTS_DIR="data/results"
NODE_SUMMARY_CSV="$RESULTS_DIR/figure_7_node.csv"
EDGE_SUMMARY_CSV="$RESULTS_DIR/figure_7_edge.csv"

echo "Generating Figure 7 plot (node: $NODE_SUMMARY_CSV, edge: $EDGE_SUMMARY_CSV) ..."

conda run -n xb-env python3 "$PYTHON_SCRIPT" \
    --node_csv="$NODE_SUMMARY_CSV" \
    --edge_csv="$EDGE_SUMMARY_CSV"