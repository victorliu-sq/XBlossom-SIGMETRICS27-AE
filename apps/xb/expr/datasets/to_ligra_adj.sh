#!/usr/bin/env bash
# ============================================================
# convert_all_datasets.sh
# ------------------------------------------------------------
# Convert multiple CSR graphs (rowOffsets + colIndices)
# into Ligra-compatible adjacency format.
#
# Each entry in the list explicitly specifies:
#   <rowOffsets path>  <colIndices path>  <output path>
# ============================================================

set -e

SCRIPT="expr/datasets/to_ligra_adj.py"
STAMP="data/realworld_datasets/.stamp.to_ligra_adj"

# ------------------------------------------------------------
# Skip execution if stamp already exists
# ------------------------------------------------------------
if [[ -f "$STAMP" ]]; then
  echo " Conversion already completed."
  echo " Stamp found at: $STAMP"
  echo " Skipping all dataset conversions."
  exit 0
fi

# ------------------------------------------------------------
# Explicit list of dataset file paths
# ------------------------------------------------------------
DATASETS=(
  "data/realworld_datasets/Amazon/amazon_rowOffsets.txt data/realworld_datasets/Amazon/amazon_colIndices.txt data/realworld_datasets/Amazon/amazon_adj.txt"
  "data/realworld_datasets/Google/gplus_rowOffsets.txt data/realworld_datasets/Google/gplus_columnIndices.txt data/realworld_datasets/Google/gplus_adj.txt"
  "data/realworld_datasets/HiggsNets/higgsnets_rowOffsets.txt data/realworld_datasets/HiggsNets/higgsnets_colIndices.txt data/realworld_datasets/HiggsNets/higgsnets_adj.txt"
  "data/realworld_datasets/Hyperlink/hyperlink_rowOffsets.txt data/realworld_datasets/Hyperlink/hyperlink_colIndices.txt data/realworld_datasets/Hyperlink/hyperlink_adj.txt"
  "data/realworld_datasets/LiveJournal/livejournal_rowOffsets.txt data/realworld_datasets/LiveJournal/livejournal_colIndices.txt data/realworld_datasets/LiveJournal/livejournal_adj.txt"
  "data/realworld_datasets/Patent/Patents_rowOffsets.txt data/realworld_datasets/Patent/Patents_colIndices.txt data/realworld_datasets/Patent/patents_adj.txt"
  "data/realworld_datasets/StackOverflow/stackOverflow_rowOffsets.txt data/realworld_datasets/StackOverflow/stackOverflow_columnIndices.txt data/realworld_datasets/StackOverflow/stackoverflow_adj.txt"
  "data/realworld_datasets/Twitch/large_twitch_edges_rowOffsets.txt data/realworld_datasets/Twitch/large_twitch_edges_colIndices.txt data/realworld_datasets/Twitch/twitch_adj.txt"
  "data/realworld_datasets/Wikipedia/wiki_rowOffsets.txt data/realworld_datasets/Wikipedia/wiki_colIndices.txt data/realworld_datasets/Wikipedia/wiki_adj.txt"
  "data/realworld_datasets/Youtube/youtube_rowOffsets.txt data/realworld_datasets/Youtube/youtube_colIndices.txt data/realworld_datasets/Youtube/youtube_adj.txt"
)

# ------------------------------------------------------------
# Process each dataset pair
# ------------------------------------------------------------
for entry in "${DATASETS[@]}"; do
  set -- $entry
  row_file=$1
  col_file=$2
  out_file=$3

  echo "------------------------------------------------------------"
  echo "📦 Processing:"
  echo "   Row file: $row_file"
  echo "   Col file: $col_file"
  echo "   Output:   $out_file"
  echo "------------------------------------------------------------"

  python3 "$SCRIPT" --row "$row_file" --col "$col_file" --out "$out_file"
done

touch "$STAMP"

echo
echo "✅ All datasets processed successfully!"