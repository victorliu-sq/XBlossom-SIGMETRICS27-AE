#!/usr/bin/env bash
set -euo pipefail

# ----------------------------------------------------------
BIN_DIR="${PROJECT_DIR}/bin"
OUTPUT_METRICS_DIR="${PROJECT_DIR}/data/metrics"

BENCHMARKS=(
  benchmark_xblsm_gpu_10
  benchmark_xblsm_cpu_pro
)

mkdir -p ${OUTPUT_METRICS_DIR}

echo "[BENCHMARK] Benchmark Begins"

for t in "${BENCHMARKS[@]}"; do
  BENCHMARK_FLAG_FILE="$OUTPUT_METRICS_DIR/$t.done"

  if [[ -f $BENCHMARK_FLAG_FILE ]]; then
    echo "Benchmark $t is already done"
    continue
  fi

  echo "[BENCHMARK] Running $t ..."

#  "${BIN_DIR}/${t}" --benchmark_counters_tabular=true

  METRICS_FILE="${OUTPUT_METRICS_DIR}/${t}.json"
  "${BIN_DIR}/${t}" \
    --benchmark_format=json \
    --benchmark_counters_tabular=true \
    > "${METRICS_FILE}"
  echo "[BENCHMARK] Results stored in ${METRICS_FILE}"

  touch $BENCHMARK_FLAG_FILE
done

echo "[BENCHMARK] Benchmark Complete"
