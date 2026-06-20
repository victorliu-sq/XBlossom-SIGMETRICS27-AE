#!/usr/bin/env bash
# ============================================================
# analyze_all_datasets_separate_output.sh
# ------------------------------------------------------------
# Loads CSR graph files and generates two output files per dataset:
# <dataset>_analysis.txt and <dataset>_sources.txt.
# ============================================================
set -e

# NOTE: Change the SCRIPT variable to the name of the new Python script
SCRIPT="expr/datasets/generate_src_lists.py"
STAMP="data/realworld_datasets/.stamp.generate_src_lists"

# ------------------------------------------------------------
# Skip execution if stamp already exists
# ------------------------------------------------------------
if [[ -f "$STAMP" ]]; then
  echo " Src Lists Generation already completed."
  echo " Stamp found at: $STAMP"
  echo " Skipping all src list generation."
  exit 0
fi

# ------------------------------------------------------------
# Explicit list of dataset file paths
# ------------------------------------------------------------
DATASETS=(
  #   <rowOffsets path>                                 <colIndices path>                                     <output BASE path>
  "data/realworld_datasets/Amazon/amazon_rowOffsets.txt data/realworld_datasets/Amazon/amazon_colIndices.txt data/realworld_datasets/Amazon/amazon"
  "data/realworld_datasets/Google/gplus_rowOffsets.txt data/realworld_datasets/Google/gplus_columnIndices.txt data/realworld_datasets/Google/gplus"
  "data/realworld_datasets/HiggsNets/higgsnets_rowOffsets.txt data/realworld_datasets/HiggsNets/higgsnets_colIndices.txt data/realworld_datasets/HiggsNets/higgsnets"
  "data/realworld_datasets/Hyperlink/hyperlink_rowOffsets.txt data/realworld_datasets/Hyperlink/hyperlink_colIndices.txt data/realworld_datasets/Hyperlink/hyperlink"
  "data/realworld_datasets/LiveJournal/livejournal_rowOffsets.txt data/realworld_datasets/LiveJournal/livejournal_colIndices.txt data/realworld_datasets/LiveJournal/livejournal"
  "data/realworld_datasets/Patent/Patents_rowOffsets.txt data/realworld_datasets/Patent/Patents_colIndices.txt data/realworld_datasets/Patent/patents"
  "data/realworld_datasets/StackOverflow/stackOverflow_rowOffsets.txt data/realworld_datasets/StackOverflow/stackOverflow_columnIndices.txt data/realworld_datasets/StackOverflow/stackoverflow"
  "data/realworld_datasets/Twitch/large_twitch_edges_rowOffsets.txt data/realworld_datasets/Twitch/large_twitch_edges_colIndices.txt data/realworld_datasets/Twitch/twitch"
  "data/realworld_datasets/Wikipedia/wiki_rowOffsets.txt data/realworld_datasets/Wikipedia/wiki_colIndices.txt data/realworld_datasets/Wikipedia/wiki"
  "data/realworld_datasets/Youtube/youtube_rowOffsets.txt data/realworld_datasets/Youtube/youtube_colIndices.txt data/realworld_datasets/Youtube/youtube"
)

# ------------------------------------------------------------
# Process each dataset pair
# ------------------------------------------------------------
for entry in "${DATASETS[@]}"; do
  set -- $entry
  row_file=$1
  col_file=$2
  base_out=$3

  echo "------------------------------------------------------------"
  echo "📦 Processing CSR Graph:"
  echo "    Row file: $row_file"
  echo "    Col file: $col_file"
  echo "    Base Output: ${base_out}_(analysis|sources).txt"
  echo "------------------------------------------------------------"

  # Pass the three arguments to the new Python script
  python3 "$SCRIPT" --row "$row_file" --col "$col_file" --base-out "$base_out"
done

touch "$STAMP"

echo
echo "✅ All datasets analyzed successfully!"