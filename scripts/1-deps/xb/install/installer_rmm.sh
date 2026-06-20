#!/usr/bin/env bash
set -euo pipefail

RMM_STAMP="${DEPS_DIR}/.stamp-rmm"

if [[ ! -f "${RMM_STAMP}" ]]; then
  echo "[rmm] Installing rmm to ${DEPS_DIR} ..."
  pushd "${DEPS_TMP_DIR}" >/dev/null

  if [[ ! -d rmm ]]; then
    git clone https://github.com/rapidsai/rmm.git
  else
    echo "[rmm] Found existing ${DEPS_TMP_DIR}/rmm, skipping clone."
  fi
  pushd rmm >/dev/null

  rm -rf build
  mkdir -p build
  cd build

  cmake \
    -DCMAKE_INSTALL_PREFIX="${DEPS_DIR}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTS=OFF \
    -DBUILD_BENCHMARKS=OFF \
    ../cpp

  cmake --build . --target install -j

  popd >/dev/null # rmm
  popd >/dev/null # tmp

  rm -rf "${DEPS_TMP_DIR}/rmm"

  touch "${RMM_STAMP}"
  echo "[rmm] Installed."
else
  echo "[rmm] Found stamp ${RMM_STAMP}, skipping install."
fi
