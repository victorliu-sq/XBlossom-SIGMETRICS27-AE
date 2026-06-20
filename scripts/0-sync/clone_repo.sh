#!/usr/bin/env bash
set -euo pipefail

REMOTE_HOST="${REMOTE_HOST:?Set REMOTE_HOST to an SSH config host, such as aws-cpu or aws-gpu}"
REMOTE_REPO_DIR="${REMOTE_REPO_DIR:-/home/ubuntu/GACGE}"
REPO_URL="${REPO_URL:-git@github.com:victorliu-sq/Graph-Algorithm-CPU-GPU-Evaluation.git}"

ssh "${REMOTE_HOST}" \
  "REMOTE_REPO_DIR='${REMOTE_REPO_DIR}' REPO_URL='${REPO_URL}' bash -s" <<'REMOTE_SCRIPT'
set -euo pipefail

if [[ -d "${REMOTE_REPO_DIR}/.git" ]]; then
  echo "[REMOTE CLONE] Repository already exists at ${REMOTE_REPO_DIR}"
  exit 0
fi

if [[ -e "${REMOTE_REPO_DIR}" ]]; then
  echo "[REMOTE CLONE] Target exists but is not a git repository: ${REMOTE_REPO_DIR}" >&2
  exit 1
fi

mkdir -p "$(dirname "${REMOTE_REPO_DIR}")"
echo "[REMOTE CLONE] Clone ${REPO_URL} into ${REMOTE_REPO_DIR}"
git clone --recursive "${REPO_URL}" "${REMOTE_REPO_DIR}"
REMOTE_SCRIPT
