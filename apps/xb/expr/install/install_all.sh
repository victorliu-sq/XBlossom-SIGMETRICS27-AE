#!/usr/bin/env bash
set -euo pipefail

# --- Installation Config
export DEPS_DIR="${PROJECT_DIR}/third_party"
export DEPS_TMP_DIR="${DEPS_DIR}/tmp"
INSTALL_DIR="${EXPR_DIR}/install"

mkdir -p \
  "${DEPS_DIR}" \
  "${DEPS_TMP_DIR}"

# --- Install gflags (once) ----------------------------------------------------
bash "${INSTALL_DIR}/install_gflags.sh"

# --- Install glog (once) ----------------------------------------------------
bash "${INSTALL_DIR}/install_glog.sh"

# --- Install gtest (once) ----------------------------------------------------
bash "${INSTALL_DIR}/install_gtest.sh"

# --- Install google benchmark (once) ----------------------------------------------------
bash "${INSTALL_DIR}/install_gbenchmark.sh"

bash "${INSTALL_DIR}/install_python.sh"

# --- Install Ligra ----------------------------------------------------
bash "${EXPR_DIR}/install/install_ligra_openmp.sh" # Install Ligra

# --- Install Gunrock ----------------------------------------------------
bash "${EXPR_DIR}/install/install_gunrock.sh" # Install Gunrock

#export LD_LIBRARY_PATH="${DEPS_DIR}/lib:${PROJECT_DIR}/bin:${LD_LIBRARY_PATH:-}"
#echo "[INFO] LD_LIBRARY_PATH set to: $LD_LIBRARY_PATH"

# remove the tmp directory
rm -rf ${DEPS_TMP_DIR}