#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
REMOTE_HOST="${REMOTE_HOST:-aws-gpu}"
OUT_DIR="${PROJECT_DIR}/results/gpu-counters"

NCU_BIN="${REMOTE_NCU_BIN:-/usr/local/cuda-13.2/bin/ncu}"
NCU_CHIP="${REMOTE_NCU_CHIP:-GB202}"

METRICS_FILE="${OUT_DIR}/ncu-metrics-${NCU_CHIP}.txt"
METRIC_NAMES_FILE="${OUT_DIR}/ncu-metric-names-${NCU_CHIP}.txt"
SUMMARY_FILE="${OUT_DIR}/counter-check-summary.txt"

OLD_THREAD_INST="sm__sass_thread_inst_executed.sum"
OLD_DRAM_READ="dram__bytes_read.sum"
THREAD_INST_REPLACEMENT="sm__sass_thread_inst_executed.sum"
DRAM_READ_REPLACEMENT="dram__bytes_op_read.sum"
DRAM_TOTAL_REPLACEMENT="dram__bytes.sum"

mkdir -p "${OUT_DIR}"

echo "[REMOTE GPU COUNTERS] Fetch GPU info"
ssh "${REMOTE_HOST}" "nvidia-smi --query-gpu=name,driver_version --format=csv,noheader" \
  > "${OUT_DIR}/nvidia-smi.txt"

echo "[REMOTE GPU COUNTERS] Fetch Nsight Compute chip list"
ssh "${REMOTE_HOST}" "'${NCU_BIN}' --list-chips" > "${OUT_DIR}/ncu-chips.txt"

echo "[REMOTE GPU COUNTERS] Fetch Nsight Compute metrics for chip ${NCU_CHIP}"
ssh "${REMOTE_HOST}" "'${NCU_BIN}' --query-metrics --query-metrics-mode all --chips '${NCU_CHIP}'" \
  > "${METRICS_FILE}"

awk 'NF && $1 !~ /^[-=]/ && $1 != "Chip" && $1 != "Metric" { print $1 }' "${METRICS_FILE}" \
  | sort -u > "${METRIC_NAMES_FILE}"

metric_exists() {
  local metric="$1"
  grep -Fxq "${metric}" "${METRIC_NAMES_FILE}"
}

write_metric_status() {
  local label="$1"
  local old_metric="$2"
  local replacement="$3"

  if metric_exists "${old_metric}"; then
    echo "${label}: old metric exists: ${old_metric}"
    echo "${label}: use: ${old_metric}"
  else
    echo "${label}: old metric missing: ${old_metric}"
    if metric_exists "${replacement}"; then
      echo "${label}: recommended replacement exists: ${replacement}"
    else
      echo "${label}: recommended replacement missing: ${replacement}"
    fi
  fi
}

{
  echo "Remote GPU counter check"
  echo "Generated: $(date -Is)"
  echo "NCU binary: ${NCU_BIN}"
  echo "NCU chip: ${NCU_CHIP}"
  echo
  echo "GPU:"
  sed 's/^/  /' "${OUT_DIR}/nvidia-smi.txt"
  echo
  write_metric_status "Executed thread instructions" "${OLD_THREAD_INST}" "${THREAD_INST_REPLACEMENT}"
  echo
  write_metric_status "DRAM read bytes" "${OLD_DRAM_READ}" "${DRAM_READ_REPLACEMENT}"
  echo
  if metric_exists "${DRAM_TOTAL_REPLACEMENT}"; then
    echo "DRAM total bytes alternative exists: ${DRAM_TOTAL_REPLACEMENT}"
  else
    echo "DRAM total bytes alternative missing: ${DRAM_TOTAL_REPLACEMENT}"
  fi
  echo
  echo "Recommended metrics for this remote GPU:"
  echo "  executed thread instructions: ${THREAD_INST_REPLACEMENT}"
  echo "  DRAM read bytes:              ${DRAM_READ_REPLACEMENT}"
  echo "  DRAM total bytes:             ${DRAM_TOTAL_REPLACEMENT}"
  echo
  echo "Saved full metric list:"
  echo "  ${METRICS_FILE}"
  echo "Saved metric-name list:"
  echo "  ${METRIC_NAMES_FILE}"
} | tee "${SUMMARY_FILE}"

echo "[REMOTE GPU COUNTERS] Saved summary:"
echo "  ${SUMMARY_FILE}"
