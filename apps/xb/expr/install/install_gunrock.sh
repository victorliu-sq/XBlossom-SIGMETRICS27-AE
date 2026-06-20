#!/usr/bin/env bash
set -e
# ============================================================
# install_gunrock.sh
# ============================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export DEPS_DIR="${PROJECT_DIR}/third_party"
GUNROCK_DIR="${PROJECT_DIR}/third_party/gunrock"
GUNROCK_STAMP="${DEPS_DIR}/.stamp.gunrock"

# --- Skip if already installed ---
if [ -f "$GUNROCK_STAMP" ]; then
  echo "✅ Gunrock already installed (stamp found)"
  exit 0
fi

# --- Step 1: Clone Gunrock if not exists ---
if [ ! -d "$GUNROCK_DIR" ]; then
  echo "🌱 Cloning Gunrock repository into $GUNROCK_DIR..."
  git clone https://github.com/gunrock/gunrock.git "$GUNROCK_DIR"
else
  echo "✅ Gunrock already exists in $GUNROCK_DIR"
fi

# ------------ Start build  ------------------
TARGETS=(
  bfs
)

BUILD_DIR="$GUNROCK_DIR/build"
OUTPUT_BIN_DIR="$BUILD_DIR/bin"

# thirdparty/gunrock
pushd $GUNROCK_DIR >/dev/null

echo "[Cmake] Generating build files for Gunrock ..."

mkdir -p $BUILD_DIR

# build
pushd $BUILD_DIR >/dev/null

cmake .. -DCMAKE_RUNTIME_OUTPUT_DIRECTORY="${OUTPUT_BIN_DIR}"

# Build
make "${TARGETS[@]}" -j

# --- Create stamp file ---
touch "$GUNROCK_STAMP"

# thirdparty/gunrock
popd >/dev/null

# project
popd >/dev/null
