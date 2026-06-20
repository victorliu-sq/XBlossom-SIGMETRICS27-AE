#!/usr/bin/env bash
set -euo pipefail

echo "[Datasets] Download Realworld Datasets for Gunrock"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}"
DATASETS_DIR="${PROJECT_DIR}/data/gunrock"
CONDA_ENV_NAME="${CONDA_ENV_NAME:-graph-env}"
mkdir -p "${DATASETS_DIR}"

pushd "${DATASETS_DIR}" >/dev/null

DATASET_STAMP=".stamp.gunrock_datasets.Dataset"
TARBALL="gunrock_datasets.tar.gz"
URL="https://buckeyemailosu-my.sharepoint.com/:u:/g/personal/liu_11080_buckeyemail_osu_edu/IQD34vUL1ZAvT5nJi5rk-12rAVpmKkqYGoCqI1QnOd0gfKA?e=BlBOCf"
PY_SCRIPT="${SCRIPT_DIR}/download_dataset.py"

if [[ ! -f "${DATASET_STAMP}" ]]; then
  echo "[download] Downloading Gunrock datasets ..."
  conda run -n "${CONDA_ENV_NAME}" --live-stream python3 "${PY_SCRIPT}" "${URL}" "${TARBALL}"

  tar -xzf "${TARBALL}"
  rm -f "${TARBALL}"
  touch "${DATASET_STAMP}"
  echo "[download] Gunrock datasets done!"
else
  echo "[download] Gunrock datasets already exist, skipping download"
fi

popd >/dev/null
