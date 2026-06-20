#!/usr/bin/env bash
set -euo pipefail

GUNROCK_DEPS_SCRIPT_DIR="${GUNROCK_DEPS_SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
PROJECT_DIR="${PROJECT_DIR:-$(cd "${GUNROCK_DEPS_SCRIPT_DIR}/../../.." && pwd)}"
DEPS_DIR="${DEPS_DIR:-${PROJECT_DIR}/deps/gunrock}"
DEPS_BUILD_DIR="${DEPS_BUILD_DIR:-${DEPS_DIR}}"

mkdir -p "${DEPS_DIR}"

echo "[gunrock-deps] Preparing dependency sources and build metadata in ${DEPS_DIR}"

if [[ -f "${DEPS_BUILD_DIR}/CMakeCache.txt" ]] &&
    grep -Eq "/deps/(_scripts/gunrock|scripts/gunrock|_gunrock)" "${DEPS_BUILD_DIR}/CMakeCache.txt"; then
  echo "[gunrock-deps] Removing stale CMake cache from old deps/scripts layout"
  rm -rf "${DEPS_BUILD_DIR}/CMakeCache.txt" "${DEPS_BUILD_DIR}/CMakeFiles"
fi

STALE_SUBBUILD_CACHE="$(
  find "${DEPS_BUILD_DIR}" -maxdepth 2 -name CMakeCache.txt -print 2>/dev/null |
    while IFS= read -r cache_file; do
      if grep -Eq "/deps/(_scripts/gunrock|scripts/gunrock|_gunrock)" "${cache_file}"; then
        printf '%s\n' "${cache_file}"
        break
      fi
    done
)"
if [[ -n "${STALE_SUBBUILD_CACHE}" ]]; then
  echo "[gunrock-deps] Removing stale FetchContent subbuild caches from old deps layout"
  find "${DEPS_BUILD_DIR}" -maxdepth 1 -type d -name "*-subbuild" -exec rm -rf {} +
fi

cmake \
  -S "${GUNROCK_DEPS_SCRIPT_DIR}" \
  -B "${DEPS_BUILD_DIR}" \
  -DPROJECT_ROOT_DIR="${PROJECT_DIR}" \
  -DPROJECT_DEPS_DIR="${DEPS_DIR}" \
  -DCMAKE_BUILD_TYPE=Release

echo "[gunrock-deps] Dependency sources are ready in ${DEPS_DIR}"
