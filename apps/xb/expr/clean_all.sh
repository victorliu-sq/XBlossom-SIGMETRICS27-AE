#!/usr/bin/env bash
set -euo pipefail

COMMON_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common/common.sh"
source "${COMMON_FILE}"

echo "[CLEAN] Clean Begins."

REMOVE_DIRS=(
  "${PROJECT_DIR}/third_party"
  "${PROJECT_DIR}/bin"
  "${PROJECT_DIR}/build"
  "${PROJECT_DIR}/data"
)

for d in "${REMOVE_DIRS[@]}"; do
  if [[ -e "${d}" ]]; then
    echo "[CLEAN] Remove ${d} ..."
    rm -rf "${d}"
  else
    echo "[CLEAN] ${d} does not exist!"
  fi
done

echo "[CLEAN] Clean ."