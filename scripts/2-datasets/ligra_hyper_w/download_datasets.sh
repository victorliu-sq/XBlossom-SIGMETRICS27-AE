#!/usr/bin/env bash
set -euo pipefail

echo "[Datasets] Download weighted Ligra HyperSSSP datasets"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}"
DATASETS_DIR="${PROJECT_DIR}/data/ligra_hyper_w"
CONDA_ENV_NAME="${CONDA_ENV_NAME:-graph-env}"
DATASET_STAMP=".stamp.csr_to_ligra_hyper_w"
TARBALL="ligra_datasets_hyper_w.tar.gz"
DEFAULT_URL="https://buckeyemailosu-my.sharepoint.com/:u:/g/personal/liu_11080_buckeyemail_osu_edu/IQDHSN_kyctKQ65hDL1V5zgSAXFuJXBeFPBKt8dZe6LCm2M?e=DZ0ReX"
URL="${LIGRA_HYPER_W_DATASETS_URL:-${DEFAULT_URL}}"
PY_SCRIPT="${SCRIPT_DIR}/download_dataset.py"

if [[ -z "$URL" ]]; then
  echo "Set LIGRA_HYPER_W_DATASETS_URL to the uploaded ${TARBALL} link." >&2
  exit 1
fi

mkdir -p "${DATASETS_DIR}"
pushd "${DATASETS_DIR}" >/dev/null

if [[ ! -f "${DATASET_STAMP}" ]]; then
  echo "[download] Downloading weighted Ligra HyperSSSP datasets ..."
  conda run -n "${CONDA_ENV_NAME}" --live-stream python3 "${PY_SCRIPT}" "${URL}" "${TARBALL}"
  tar -xzf "${TARBALL}"
  rm -f "${TARBALL}"
  touch "${DATASET_STAMP}"
  echo "[download] Weighted Ligra HyperSSSP datasets done!"
else
  echo "[download] Weighted Ligra HyperSSSP datasets already exist, skipping download"
fi

popd >/dev/null
