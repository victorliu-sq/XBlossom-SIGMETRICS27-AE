#!/usr/bin/env bash
set -euo pipefail

# --- Installation Config
export XB_DEPS_SCRIPT_DIR="${XB_DEPS_SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
export INSTALLER_DIR="${INSTALLER_DIR:-${XB_DEPS_SCRIPT_DIR}/install}"
export PROJECT_DIR="${PROJECT_DIR:-$(cd "${XB_DEPS_SCRIPT_DIR}/../../.." && pwd)}"
export SCRIPTS_DIR="${SCRIPTS_DIR:-${PROJECT_DIR}/scripts}"
export DEPS_DIR="${DEPS_DIR:-${PROJECT_DIR}/deps/xb}"
export DEPS_TMP_DIR="${DEPS_TMP_DIR:-${DEPS_DIR}/tmp}"
export CONDA_ENV_NAME="${CONDA_ENV_NAME:-graph-env}"

if ! declare -F download >/dev/null 2>&1; then
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
fi

# --- Create Directories ----------------------------------------------------
mkdir -p \
  "${DEPS_DIR}" \
  "${DEPS_TMP_DIR}"

# --- Install gflags  ----------------------------------------------------
bash "${INSTALLER_DIR}/installer_gflags.sh"

# --- Install glog  ----------------------------------------------------
bash "${INSTALLER_DIR}/installer_glog.sh"

# --- Install gtest  ----------------------------------------------------
bash "${INSTALLER_DIR}/installer_gtest.sh"

# --- Install google benchmark  ----------------------------------------------------
bash "${INSTALLER_DIR}/installer_gbenchmark.sh"

# --- Install Python Env ----------------------------------------------------
bash "${INSTALLER_DIR}/installer_python.sh"

# remove the tmp directory
rm -rf "${DEPS_TMP_DIR}"
