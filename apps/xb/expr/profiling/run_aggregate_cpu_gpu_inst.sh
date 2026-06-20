#!/bin/bash
set -euo pipefail

METRICS_DIR="${PROJECT_DIR}/data/metrics"
PY_SCRIPT="${EXPR_DIR}/profiling/aggregate_cpu_gpu_inst.py"

CPU_JSON="$METRICS_DIR/benchmark_xblsm_cpu_pro.json"
GPU_JSON="$METRICS_DIR/benchmark_xblsm_gpu_10.json"
CPU_INST_TXT="$METRICS_DIR/cpu_inst_all.txt"
GPU_INST_TXT="$METRICS_DIR/gpu_inst_all.txt"
OUTPUT_CSV="$METRICS_DIR/cpu_gpu_inst_summary.csv"

echo "Aggregating CPU/GPU instruction throughput into $OUTPUT_CSV ..."

conda run -n xblossom-python --live-stream python3 "$PY_SCRIPT" \
    "$CPU_JSON" "$GPU_JSON" "$CPU_INST_TXT" "$GPU_INST_TXT" "$OUTPUT_CSV"

echo "Done. Results stored in $OUTPUT_CSV"
