#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
REMOTE_HOST="${REMOTE_HOST:-aws-cpu}"
OUT_DIR="${PROJECT_DIR}/results/perf"

mkdir -p "${OUT_DIR}"

echo "[REMOTE PERF] Fetch remote perf list"
ssh "${REMOTE_HOST}" "perf list" > "${OUT_DIR}/perf-list.txt"

echo "[REMOTE PERF] Fetch remote CPU info"
ssh "${REMOTE_HOST}" "lscpu" > "${OUT_DIR}/lscpu.txt"

echo "[REMOTE PERF] Fetch remote perf permission setting"
ssh "${REMOTE_HOST}" "cat /proc/sys/kernel/perf_event_paranoid" > "${OUT_DIR}/perf_event_paranoid.txt"

echo "[REMOTE PERF] Saved files:"
echo "  ${OUT_DIR}/perf-list.txt"
echo "  ${OUT_DIR}/lscpu.txt"
echo "  ${OUT_DIR}/perf_event_paranoid.txt"
