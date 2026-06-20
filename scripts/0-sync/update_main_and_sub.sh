#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
REMOTE_HOST="${REMOTE_HOST:-aws-gpu}"
REMOTE_REPO_DIR="${REMOTE_REPO_DIR:-/home/ubuntu/XBlossom-SIGMETRICS27-AE}"
REMOTE_BRANCH="${REMOTE_BRANCH:-$(git -C "${PROJECT_DIR}" rev-parse --abbrev-ref HEAD)}"

if [[ "${REMOTE_BRANCH}" == "HEAD" ]]; then
  echo "[REMOTE UPDATE] Local checkout is detached. Set REMOTE_BRANCH explicitly." >&2
  exit 1
fi

echo "[REMOTE UPDATE] Host repo dir is ${REMOTE_REPO_DIR}"
echo "[REMOTE UPDATE] Host is ${REMOTE_HOST}"
echo "[REMOTE UPDATE] Force remote checkout to origin/${REMOTE_BRANCH}"
echo "[REMOTE UPDATE] Remote uncommitted changes will be discarded."

exec ssh "${REMOTE_HOST}" \
  "REMOTE_REPO_DIR='${REMOTE_REPO_DIR}' REMOTE_BRANCH='${REMOTE_BRANCH}' bash -s" <<'REMOTE_SCRIPT'
set -euo pipefail

cd "${REMOTE_REPO_DIR}"

force_clean_repo() {
  git reset --hard
  git clean -ffdx
}

echo "[REMOTE UPDATE] Clean main repo working tree"
force_clean_repo

echo "[REMOTE UPDATE] Clean submodule working trees"
git submodule foreach --recursive 'git reset --hard && git clean -ffdx'

echo "[REMOTE UPDATE] Fetch main repo"
git fetch --prune origin

if ! git show-ref --verify --quiet "refs/remotes/origin/${REMOTE_BRANCH}"; then
  echo "[REMOTE UPDATE] origin/${REMOTE_BRANCH} does not exist on remote host." >&2
  exit 1
fi

echo "[REMOTE UPDATE] Reset main repo to origin/${REMOTE_BRANCH}"
git checkout -B "${REMOTE_BRANCH}" "origin/${REMOTE_BRANCH}"
git reset --hard "origin/${REMOTE_BRANCH}"
git clean -ffdx

echo "[REMOTE UPDATE] Sync and initialize submodules to recorded commits"
git submodule sync --recursive
git submodule update --init --recursive --force

echo "[REMOTE UPDATE] Final clean submodule working trees"
git submodule foreach --recursive 'git reset --hard && git clean -ffdx'

if [[ -n "$(git status --short)" ]]; then
  echo "[REMOTE UPDATE] Remote checkout is still dirty after force update:" >&2
  git status --short >&2
  exit 1
fi

echo "[REMOTE UPDATE] Remote checkout is clean"

echo "[REMOTE UPDATE] Complete"
REMOTE_SCRIPT
