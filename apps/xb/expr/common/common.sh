#!/usr/bin/env bash
set -euo pipefail

# Compared to $PWD, this command improves portability.
# PROJECT_DIR and EXPR_DIR are evaluated from this file's absolute path.
export PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
export EXPR_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

#export LD_LIBRARY_PATH="${EXPR_DIR}/third_party/lib":$LD_LIBRARY_PATH

# downloader
download() {
  local url="$1" out="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -L "$url" -o "$out"
  elif command -v wget >/dev/null 2>&1; then
    wget "$url" -O "$out"
  else
    echo "ERROR: need curl or wget" >&2
    exit 1
  fi
}
export -f download
