#!/usr/bin/env bash
set -euo pipefail

BOOST_VER="1.85.0"
BOOST_DIR_VER="${BOOST_VER//./_}"
BOOST_STAMP="${DEPS_DIR}/.stamp-boost"

if [[ ! -f "${BOOST_STAMP}" ]]; then
  echo "[boost] Installing Boost v${BOOST_VER} to ${DEPS_DIR} ..."
  pushd "${DEPS_TMP_DIR}" >/dev/null

  TARBALL="boost_${BOOST_DIR_VER}.tar.gz"
  URL="https://archives.boost.io/release/${BOOST_VER}/source/${TARBALL}"
  download "$URL" "$TARBALL"

  rm -rf "boost_${BOOST_DIR_VER}"
  tar zxf "$TARBALL"
  pushd "boost_${BOOST_DIR_VER}" >/dev/null

  ./bootstrap.sh --prefix="${DEPS_DIR}"
  ./b2
  ./b2 install

  popd >/dev/null # boost_${BOOST_DIR_VER}
  popd >/dev/null # tmp

  # remove tmp files
  #  rm "${DEPS_TMP_DIR}/${TARBALL}"
  #  rm -rf "${DEPS_TMP_DIR}/boost_${BOOST_DIR_VER}"

  touch "${BOOST_STAMP}"
  echo "[boost] Installed."
else
  echo "[boost] Found stamp ${BOOST_STAMP}, skipping install."
fi
