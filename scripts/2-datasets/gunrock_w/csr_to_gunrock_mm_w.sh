#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}"
SCRIPT="${SCRIPT_DIR}/csr_to_gunrock_mm_w.py"
INPUT_DIR="${PROJECT_DIR}/data/xb"
OUTPUT_DIR="${PROJECT_DIR}/data/gunrock_w"
STAMP="${OUTPUT_DIR}/.stamp.csr_to_gunrock_mm_w"
CONDA_ENV_NAME="${CONDA_ENV_NAME:-graph-env}"

mkdir -p "${OUTPUT_DIR}"

if [[ -f "$STAMP" ]]; then
  echo "Weighted Gunrock conversion already completed."
  echo "Stamp found at: $STAMP"
  exit 0
fi

DATASETS=(
  "${INPUT_DIR}/Amazon/amazon_rowOffsets.txt ${INPUT_DIR}/Amazon/amazon_colIndices.txt ${OUTPUT_DIR}/Amazon/amazon.mtx"
  "${INPUT_DIR}/Google/gplus_rowOffsets.txt ${INPUT_DIR}/Google/gplus_columnIndices.txt ${OUTPUT_DIR}/Google/gplus.mtx"
  "${INPUT_DIR}/HiggsNets/higgsnets_rowOffsets.txt ${INPUT_DIR}/HiggsNets/higgsnets_colIndices.txt ${OUTPUT_DIR}/HiggsNets/higgsnets.mtx"
  "${INPUT_DIR}/Hyperlink/hyperlink_rowOffsets.txt ${INPUT_DIR}/Hyperlink/hyperlink_colIndices.txt ${OUTPUT_DIR}/Hyperlink/hyperlink.mtx"
  "${INPUT_DIR}/LiveJournal/livejournal_rowOffsets.txt ${INPUT_DIR}/LiveJournal/livejournal_colIndices.txt ${OUTPUT_DIR}/LiveJournal/livejournal.mtx"
  "${INPUT_DIR}/Patent/Patents_rowOffsets.txt ${INPUT_DIR}/Patent/Patents_colIndices.txt ${OUTPUT_DIR}/Patent/patents.mtx"
  "${INPUT_DIR}/StackOverflow/stackOverflow_rowOffsets.txt ${INPUT_DIR}/StackOverflow/stackOverflow_columnIndices.txt ${OUTPUT_DIR}/StackOverflow/stackoverflow.mtx"
  "${INPUT_DIR}/Twitch/large_twitch_edges_rowOffsets.txt ${INPUT_DIR}/Twitch/large_twitch_edges_colIndices.txt ${OUTPUT_DIR}/Twitch/twitch.mtx"
  "${INPUT_DIR}/Wikipedia/wiki_rowOffsets.txt ${INPUT_DIR}/Wikipedia/wiki_colIndices.txt ${OUTPUT_DIR}/Wikipedia/wiki.mtx"
  "${INPUT_DIR}/Youtube/youtube_rowOffsets.txt ${INPUT_DIR}/Youtube/youtube_colIndices.txt ${OUTPUT_DIR}/Youtube/youtube.mtx"
)

for entry in "${DATASETS[@]}"; do
  set -- $entry
  row_file=$1
  col_file=$2
  out_file=$3

  echo "------------------------------------------------------------"
  echo "Processing weighted Gunrock graph:"
  echo "  Row file: $row_file"
  echo "  Col file: $col_file"
  echo "  Output:   $out_file"
  echo "------------------------------------------------------------"

  conda run -n "${CONDA_ENV_NAME}" --live-stream python3 "$SCRIPT" --row "$row_file" --col "$col_file" --out "$out_file"
done

touch "$STAMP"
echo "All weighted Gunrock datasets processed successfully."
