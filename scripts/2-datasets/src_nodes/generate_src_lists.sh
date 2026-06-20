#!/usr/bin/env bash
# ============================================================
# generate_src_lists.sh
# ------------------------------------------------------------
# Loads CSR graph files and generates source-node files per dataset:
# <Dataset>_src_nodes.txt. These source lists are shared by BFS,
# SSSP, and multi-source SSSP experiments.
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}"
SCRIPT="${SCRIPT_DIR}/generate_src_lists.py"
INPUT_DIR="${PROJECT_DIR}/data/xb"
OUTPUT_DIR="${PROJECT_DIR}/data/src_nodes"
STAMP="${OUTPUT_DIR}/.stamp.generate_src_nodes"
JOBS="${SRC_NODES_DATASET_JOBS:-${BFS_DATASET_JOBS:-4}}"
NUM_SAMPLES="${SRC_NODES_SAMPLES:-${BFS_SOURCE_SAMPLES:-1000}}"
CONDA_ENV_NAME="${CONDA_ENV_NAME:-graph-env}"

mkdir -p "${OUTPUT_DIR}"

if ! [[ "${JOBS}" =~ ^[1-9][0-9]*$ ]]; then
  echo "ERROR: SRC_NODES_DATASET_JOBS must be a positive integer, got '${JOBS}'." >&2
  exit 1
fi

if ! [[ "${NUM_SAMPLES}" =~ ^[1-9][0-9]*$ ]]; then
  echo "ERROR: SRC_NODES_SAMPLES must be a positive integer, got '${NUM_SAMPLES}'." >&2
  exit 1
fi

if [[ -f "$STAMP" ]]; then
  echo " Source-node generation already completed."
  echo " Stamp found at: $STAMP"
  echo " Skipping source-node generation."
  exit 0
fi

DATASETS=(
  # Dataset       rowOffsets path                                      colIndices path
  "Amazon        ${INPUT_DIR}/Amazon/amazon_rowOffsets.txt             ${INPUT_DIR}/Amazon/amazon_colIndices.txt"
  "GPlus         ${INPUT_DIR}/Google/gplus_rowOffsets.txt              ${INPUT_DIR}/Google/gplus_columnIndices.txt"
  "HiggsNets     ${INPUT_DIR}/HiggsNets/higgsnets_rowOffsets.txt       ${INPUT_DIR}/HiggsNets/higgsnets_colIndices.txt"
  "Hyperlink     ${INPUT_DIR}/Hyperlink/hyperlink_rowOffsets.txt       ${INPUT_DIR}/Hyperlink/hyperlink_colIndices.txt"
  "LiveJournal   ${INPUT_DIR}/LiveJournal/livejournal_rowOffsets.txt   ${INPUT_DIR}/LiveJournal/livejournal_colIndices.txt"
  "Patent        ${INPUT_DIR}/Patent/Patents_rowOffsets.txt            ${INPUT_DIR}/Patent/Patents_colIndices.txt"
  "StackOverflow ${INPUT_DIR}/StackOverflow/stackOverflow_rowOffsets.txt ${INPUT_DIR}/StackOverflow/stackOverflow_columnIndices.txt"
  "Twitch        ${INPUT_DIR}/Twitch/large_twitch_edges_rowOffsets.txt ${INPUT_DIR}/Twitch/large_twitch_edges_colIndices.txt"
  "Wikipedia     ${INPUT_DIR}/Wikipedia/wiki_rowOffsets.txt            ${INPUT_DIR}/Wikipedia/wiki_colIndices.txt"
  "Youtube       ${INPUT_DIR}/Youtube/youtube_rowOffsets.txt           ${INPUT_DIR}/Youtube/youtube_colIndices.txt"
)

run_dataset() {
  local dataset_name="$1"
  local row_file="$2"
  local col_file="$3"
  local base_out="${OUTPUT_DIR}/${dataset_name}"

  echo "------------------------------------------------------------"
  echo "Processing CSR Graph: ${dataset_name}"
  echo "    Row file: $row_file"
  echo "    Col file: $col_file"
  echo "    Source output: ${base_out}_src_nodes.txt"
  echo "    Analysis output: ${base_out}_analysis.txt"
  echo "------------------------------------------------------------"

  conda run -n "${CONDA_ENV_NAME}" --live-stream python3 "$SCRIPT" \
    --row "$row_file" \
    --col "$col_file" \
    --base-out "$base_out" \
    --num-samples "$NUM_SAMPLES"
}

running_jobs=0
failed=0

for entry in "${DATASETS[@]}"; do
  set -- $entry
  dataset_name=$1
  row_file=$2
  col_file=$3

  run_dataset "$dataset_name" "$row_file" "$col_file" &
  running_jobs=$((running_jobs + 1))

  if (( running_jobs >= JOBS )); then
    if ! wait -n; then
      failed=1
    fi
    running_jobs=$((running_jobs - 1))
  fi
done

while (( running_jobs > 0 )); do
  if ! wait -n; then
    failed=1
  fi
  running_jobs=$((running_jobs - 1))
done

if (( failed != 0 )); then
  echo "One or more datasets failed to generate source-node lists." >&2
  exit 1
fi

touch "$STAMP"

echo
echo "All source-node lists generated successfully."
