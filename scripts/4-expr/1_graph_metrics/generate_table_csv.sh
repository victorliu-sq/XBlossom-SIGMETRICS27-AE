#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

METRICS_DIR="${PROJECT_DIR}/tmp/1_graph_metrics"
RESULTS_DIR="${PROJECT_DIR}/results/1_graph_metrics"
PYTHON_SCRIPT="${SCRIPT_DIR}/generate_table_csv.py"
SUMMARY_CSV_TEMP="${METRICS_DIR}/_graph_metrics_summary.csv"
SUMMARY_CSV="${RESULTS_DIR}/graph_metrics.csv"

mkdir -p "$METRICS_DIR" "$RESULTS_DIR"
rm -f "$SUMMARY_CSV_TEMP"

for entry in "${DATASET_CSR_LIST[@]}"; do
  IFS='|' read -r DATASET _ _ _ <<< "$entry"

  GRAPH_METRICS_OUT="${METRICS_DIR}/graph_metrics_${DATASET}.txt"
  require_file "$GRAPH_METRICS_OUT" "${DATASET} graph metrics log"

  run_python "$PYTHON_SCRIPT" \
      "$DATASET" \
      "$GRAPH_METRICS_OUT" \
      "$SUMMARY_CSV_TEMP"
done

cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"

echo "Graph metrics CSV saved at ${SUMMARY_CSV}"
