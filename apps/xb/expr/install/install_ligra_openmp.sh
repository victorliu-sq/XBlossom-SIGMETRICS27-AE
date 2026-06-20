#!/usr/bin/env bash
# ============================================================
# build_ligra_openmp.sh
# ------------------------------------------------------------
# Automatically clones and builds Ligra using OpenMP
# (for modern GCC versions, e.g., g++ 7+)
#
# Output binaries: <PROJECT_DIR>/third_party/ligra/apps/*
# ============================================================

set -e  # Stop if any command fails

# --- Step 0: Define paths ---
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export DEPS_DIR="${PROJECT_DIR}/third_party"
LIGRA_DIR="${DEPS_DIR}/ligra"
LIGRA_STAMP="${DEPS_DIR}/.stamp.ligra"

# --- Skip if already installed ---
if [ -f "$LIGRA_STAMP" ]; then
  echo "✅ Ligra already installed (stamp found)"
  exit 0
fi

echo "📂 Project root:  $PROJECT_DIR"
echo "📦 Dependencies:  $DEPS_DIR"
echo

# --- Step 1: Clone Ligra if not exists ---
if [ ! -d "$LIGRA_DIR" ]; then
  echo "🌱 Cloning Ligra repository into $LIGRA_DIR..."
  mkdir -p "$DEPS_DIR"
  git clone https://github.com/jshun/ligra.git "$LIGRA_DIR"
else
  echo "✅ Ligra already exists in $LIGRA_DIR"
fi

# --- Step 2: Move into apps directory ---
cd "$LIGRA_DIR/apps"

echo "🧹 Cleaning previous builds..."
make clean || true

# --- Step 3: Build Ligra ---
echo "🔧 Ligra Setup with OPENMP"

# Enable CILK
unset CILK
unset MKLROOT
export OPENMP=1

# --- Step 6: Build Ligra with OPENMP ---
echo "⚙️  Building Ligra with OPENMP support..."
make -j

# --- Create stamp file ---
touch "$LIGRA_STAMP"

echo
echo "✅ Ligra build completed successfully!"
echo "------------------------------------------------------------"
echo "Binaries are in: ${LIGRA_DIR}/apps/"
#echo
#echo "Example usage:"
#echo "  cd ${LIGRA_DIR}/apps"
#echo "  ./CC -s ../inputs/rMatGraph_J_5_100"
#echo "------------------------------------------------------------"
