#!/usr/bin/env bash
set -euo pipefail

NLOHMANN_JSON_STAMP="${DEPS_DIR}/.stamp-nlohmann-json"

if [[ ! -f "${NLOHMANN_JSON_STAMP}" ]]; then
  echo "[nlohmann_json] Installing nlohmann_json to ${DEPS_DIR} ..."
  pushd "${DEPS_TMP_DIR}" >/dev/null

  git clone https://github.com/nlohmann/json.git
  pushd json >/dev/null

  rm -rf build
  mkdir -p build
  cd build

  cmake \
    -DJSON_BuildTests=OFF \
    -DCMAKE_INSTALL_PREFIX="${DEPS_DIR}" \
    -DCMAKE_BUILD_TYPE=Release \
    ..

  cmake --build . --target install -j

  popd >/dev/null # json
  popd >/dev/null # tmp

  rm -rf "${DEPS_TMP_DIR}/json"

  touch "${NLOHMANN_JSON_STAMP}"
  echo "[nlohmann_json] Installed."
else
  echo "[nlohmann_json] Found stamp ${NLOHMANN_JSON_STAMP}, skipping install."
fi
