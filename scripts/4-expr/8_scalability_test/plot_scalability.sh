#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

RESULTS_DIR="${PROJECT_DIR}/results/8_scalability_test"
PYTHON_SCRIPT="${SCRIPT_DIR}/plot_scalability.py"

mkdir -p "$RESULTS_DIR"
run_python "$PYTHON_SCRIPT" \
    --results-dir="${RESULTS_DIR}" \
    --output="${RESULTS_DIR}/plot_scalability.png"
