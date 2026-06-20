#!/usr/bin/env bash
set -euo pipefail

echo "[Datasets] Download weighted Gunrock datasets"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}"
DATASETS_DIR="${PROJECT_DIR}/data/gunrock_w"
CONDA_ENV_NAME="${CONDA_ENV_NAME:-graph-env}"
DATASET_STAMP=".stamp.csr_to_gunrock_mm_w"
TARBALL="gunrock_datasets_w.tar.gz"
DEFAULT_URL="https://buckeyemailosu-my.sharepoint.com/:u:/g/personal/liu_11080_buckeyemail_osu_edu/IQB0NtdmFRIoQq0L5ZJVp56OAfpjbXh36QzBO4_QdliflHU?e=mu2Ive"
URL="${GUNROCK_W_DATASETS_URL:-${DEFAULT_URL}}"
PY_SCRIPT="${SCRIPT_DIR}/download_dataset.py"

if [[ -z "$URL" ]]; then
  echo "Set GUNROCK_W_DATASETS_URL to the uploaded ${TARBALL} link." >&2
  exit 1
fi

mkdir -p "${DATASETS_DIR}"
pushd "${DATASETS_DIR}" >/dev/null

if [[ ! -f "${DATASET_STAMP}" ]]; then
  echo "[download] Downloading weighted Gunrock datasets ..."
  conda run -n "${CONDA_ENV_NAME}" --live-stream python3 "${PY_SCRIPT}" "${URL}" "${TARBALL}"
  tar -xzf "${TARBALL}"
  rm -f "${TARBALL}"
  touch "${DATASET_STAMP}"
  echo "[download] Weighted Gunrock datasets done!"
else
  echo "[download] Weighted Gunrock datasets already exist, skipping download"
fi

popd >/dev/null
