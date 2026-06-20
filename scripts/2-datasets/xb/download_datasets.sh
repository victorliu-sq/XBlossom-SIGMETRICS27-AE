#!/usr/bin/env bash
set -euo pipefail

echo "[Datasets] Download Realworld Datasets for XB"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}"
DATASETS_DIR="${PROJECT_DIR}/data/xb"
CONDA_ENV_NAME="${CONDA_ENV_NAME:-graph-env}"
mkdir -p "${DATASETS_DIR}"

pushd "${DATASETS_DIR}" >/dev/null

DATASET_STAMP=".stamp.xb_datasets.Dataset"
TARBALL="xb_datasets.tar.gz"
URL="https://buckeyemailosu-my.sharepoint.com/:u:/g/personal/liu_11080_buckeyemail_osu_edu/IQC6Kqks_kLaRqXHs4l9lMIYAdATq9ThT8MIw8jJNd9ie38?e=CjNalD"
PY_SCRIPT="${SCRIPT_DIR}/download_dataset.py"

if [[ ! -f "${DATASET_STAMP}" ]]; then
  echo "[download] Downloading XB datasets ..."
  conda run -n "${CONDA_ENV_NAME}" --live-stream python3 "${PY_SCRIPT}" "${URL}" "${TARBALL}"

  tar -xzf "${TARBALL}"
  rm -f "${TARBALL}"
  touch "${DATASET_STAMP}"
  echo "[download] XB datasets done!"
else
  echo "[download] XB datasets already exist, skipping download"
fi

popd >/dev/null
