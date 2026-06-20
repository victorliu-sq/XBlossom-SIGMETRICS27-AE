#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

echo "[RUNME] PROJECT_DIR is ${PROJECT_DIR}"

make -C "$PROJECT_DIR" \
    1_graph_metrics \
    2_reuse \
    3_load_balance \
    4_xb_pro_inst \
    5_runtime_four_bbss \
    6_inst_rate_four_bbss \
    7_memory_four_bbss \
    8_scalability_test
