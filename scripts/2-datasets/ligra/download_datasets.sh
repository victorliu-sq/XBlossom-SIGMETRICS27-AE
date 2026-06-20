#!/usr/bin/env bash
set -euo pipefail

echo "[Datasets] Download Realworld Datasets for Ligra"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}"
DATASETS_DIR="${PROJECT_DIR}/data/ligra"
CONDA_ENV_NAME="${CONDA_ENV_NAME:-graph-env}"
mkdir -p "${DATASETS_DIR}"

pushd "${DATASETS_DIR}" >/dev/null

DATASET_STAMP=".stamp.ligra_datasets.Dataset"
TARBALL="ligra_datasets.tar.gz"
URL="https://buckeyemailosu-my.sharepoint.com/:u:/g/personal/liu_11080_buckeyemail_osu_edu/IQA2hulaNaDnQrSrg64AFGeUAdJNBiui-nM-j68E0uOcunI?e=NzvmuO"
PY_SCRIPT="${SCRIPT_DIR}/download_dataset.py"

if [[ ! -f "${DATASET_STAMP}" ]]; then
  echo "[download] Downloading Ligra datasets ..."
  conda run -n "${CONDA_ENV_NAME}" --live-stream python3 "${PY_SCRIPT}" "${URL}" "${TARBALL}"

  tar -xzf "${TARBALL}"
  rm -f "${TARBALL}"
  touch "${DATASET_STAMP}"
  echo "[download] Ligra datasets done!"
else
  echo "[download] Ligra datasets already exist, skipping download"
fi

popd >/dev/null
