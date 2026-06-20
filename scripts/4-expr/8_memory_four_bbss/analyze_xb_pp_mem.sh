#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
ANALYZER_NAME="$(basename "$SCRIPT_PATH" .sh).py"

source "${SCRIPT_DIR}/../common.sh"

run_python "${SCRIPT_DIR}/${ANALYZER_NAME}" "$@"
