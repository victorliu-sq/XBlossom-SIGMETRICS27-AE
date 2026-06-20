#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}"
SCRIPT="${SCRIPT_DIR}/csr_to_ligra_adj_w.py"
INPUT_DIR="${PROJECT_DIR}/data/xb"
OUTPUT_DIR="${PROJECT_DIR}/data/ligra_hyper_w"
STAMP="${OUTPUT_DIR}/.stamp.csr_to_ligra_hyper_w"
CONDA_ENV_NAME="${CONDA_ENV_NAME:-graph-env}"

mkdir -p "${OUTPUT_DIR}"

if [[ -f "$STAMP" ]]; then
  echo "Weighted Ligra HyperSSSP conversion already completed."
  echo "Stamp found at: $STAMP"
  exit 0
fi

DATASETS=(
  "${INPUT_DIR}/Amazon/amazon_rowOffsets.txt ${INPUT_DIR}/Amazon/amazon_colIndices.txt ${OUTPUT_DIR}/Amazon/amazon_adj.txt"
  "${INPUT_DIR}/Google/gplus_rowOffsets.txt ${INPUT_DIR}/Google/gplus_columnIndices.txt ${OUTPUT_DIR}/Google/gplus_adj.txt"
  "${INPUT_DIR}/HiggsNets/higgsnets_rowOffsets.txt ${INPUT_DIR}/HiggsNets/higgsnets_colIndices.txt ${OUTPUT_DIR}/HiggsNets/higgsnets_adj.txt"
  "${INPUT_DIR}/Hyperlink/hyperlink_rowOffsets.txt ${INPUT_DIR}/Hyperlink/hyperlink_colIndices.txt ${OUTPUT_DIR}/Hyperlink/hyperlink_adj.txt"
  "${INPUT_DIR}/LiveJournal/livejournal_rowOffsets.txt ${INPUT_DIR}/LiveJournal/livejournal_colIndices.txt ${OUTPUT_DIR}/LiveJournal/livejournal_adj.txt"
  "${INPUT_DIR}/Patent/Patents_rowOffsets.txt ${INPUT_DIR}/Patent/Patents_colIndices.txt ${OUTPUT_DIR}/Patent/patents_adj.txt"
  "${INPUT_DIR}/StackOverflow/stackOverflow_rowOffsets.txt ${INPUT_DIR}/StackOverflow/stackOverflow_columnIndices.txt ${OUTPUT_DIR}/StackOverflow/stackoverflow_adj.txt"
  "${INPUT_DIR}/Twitch/large_twitch_edges_rowOffsets.txt ${INPUT_DIR}/Twitch/large_twitch_edges_colIndices.txt ${OUTPUT_DIR}/Twitch/twitch_adj.txt"
  "${INPUT_DIR}/Wikipedia/wiki_rowOffsets.txt ${INPUT_DIR}/Wikipedia/wiki_colIndices.txt ${OUTPUT_DIR}/Wikipedia/wiki_adj.txt"
  "${INPUT_DIR}/Youtube/youtube_rowOffsets.txt ${INPUT_DIR}/Youtube/youtube_colIndices.txt ${OUTPUT_DIR}/Youtube/youtube_adj.txt"
)

for entry in "${DATASETS[@]}"; do
  set -- $entry
  row_file=$1
  col_file=$2
  out_file=$3

  echo "------------------------------------------------------------"
  echo "Processing weighted Ligra HyperSSSP hypergraph:"
  echo "  Row file: $row_file"
  echo "  Col file: $col_file"
  echo "  Output:   $out_file"
  echo "------------------------------------------------------------"

  conda run -n "${CONDA_ENV_NAME}" --live-stream python3 "$SCRIPT" --row "$row_file" --col "$col_file" --out "$out_file"
done

touch "$STAMP"
echo "All weighted Ligra HyperSSSP datasets processed successfully."
