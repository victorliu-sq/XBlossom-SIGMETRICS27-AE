#!/usr/bin/env bash
set -euo pipefail

LIGRA_DEPS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(cd "${LIGRA_DEPS_SCRIPT_DIR}/../../.." && pwd)}"
DEPS_DIR="${DEPS_DIR:-${PROJECT_DIR}/deps/ligra}"

mkdir -p "${DEPS_DIR}"
echo "[ligra-deps] No external dependencies required; using ${DEPS_DIR}."
