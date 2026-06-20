#!/bin/bash
set -euo pipefail

METRICS_DIR="${PROJECT_DIR}/data/metrics"
PY_SCRIPT="${EXPR_DIR}/profiling/aggregate_cpu_gpu_bw.py"

CPU_JSON="$METRICS_DIR/benchmark_xblsm_cpu_pro.json"
GPU_JSON="$METRICS_DIR/benchmark_xblsm_gpu_10.json"
CPU_BW_TXT="$METRICS_DIR/cpu_mem_bw_all.txt"
GPU_BYTES_TXT="$METRICS_DIR/gpu_dram_bytes_summary.txt"
OUTPUT_CSV="$METRICS_DIR/cpu_gpu_bw_summary.csv"

echo "Aggregating CPU/GPU bandwidth into $OUTPUT_CSV ..."

conda run -n xblossom-python --live-stream python3 "$PY_SCRIPT" \
    "$CPU_JSON" "$GPU_JSON" "$CPU_BW_TXT" "$GPU_BYTES_TXT" "$OUTPUT_CSV"

echo "Done. Results stored in $OUTPUT_CSV"