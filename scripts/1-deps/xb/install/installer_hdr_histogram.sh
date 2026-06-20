#!/usr/bin/env bash
set -euo pipefail

HDR_HISTOGRAM_VER="0.9.9"
HDR_HISTOGRAM_STAMP="${DEPS_DIR}/.stamp-hdr-histogram"

if [[ ! -f "${HDR_HISTOGRAM_STAMP}" ]]; then
  echo "[hdr_histogram] Installing HdrHistogram_c to ${DEPS_DIR} ..."
  mkdir -p "${DEPS_DIR}" "${DEPS_TMP_DIR}"
  pushd "${DEPS_TMP_DIR}" >/dev/null

  # tmp projects
  rm -rf HdrHistogram_c
  git clone --branch "${HDR_HISTOGRAM_VER}" --depth 1 https://github.com/HdrHistogram/HdrHistogram_c.git

  pushd "HdrHistogram_c" >/dev/null

  # --- install HdrHistogram_c following its own CMake build
  rm -rf build
  mkdir -p build && cd build

  cmake -DHDR_HISTOGRAM_BUILD_PROGRAMS=OFF \
        -DHDR_HISTOGRAM_BUILD_SHARED=OFF \
        -DHDR_HISTOGRAM_BUILD_STATIC=ON \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -DCMAKE_INSTALL_PREFIX="${DEPS_DIR}" \
        -DCMAKE_BUILD_TYPE=Release \
        ..
  cmake --build . --target install -j

  popd >/dev/null # HdrHistogram_c
  popd >/dev/null # tmp

  # remove tmp files
  rm -rf "${DEPS_TMP_DIR}/HdrHistogram_c"

  touch "${HDR_HISTOGRAM_STAMP}"
  echo "[hdr_histogram] Installed."
else
  echo "[hdr_histogram] Found stamp ${HDR_HISTOGRAM_STAMP}, skipping install."
fi
