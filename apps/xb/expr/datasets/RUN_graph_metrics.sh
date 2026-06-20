#!/usr/bin/env bash
set -euo pipefail

XB_PRO_BIN="build/bin/run_xb_pro_by_dataset"
METRICS_DIR="tmp/graph_metrics"
RESULTS_DIR="data/results"
PYTHON_SCRIPT="expr/datasets/RUN_graph_metrics.py"
SUMMARY_CSV_TEMP="$METRICS_DIR/_grpah_metrics_summary.csv"
SUMMARY_CSV="$RESULTS_DIR/table_1.csv"

# ============================================================
# DATASET | rowOffsets | colIndices
# ============================================================
DATASET_CSR_LIST=(
  "Amazon|data/realworld_datasets/Amazon/amazon_rowOffsets.txt|data/realworld_datasets/Amazon/amazon_colIndices.txt"
  "GPlus|data/realworld_datasets/Google/gplus_rowOffsets.txt|data/realworld_datasets/Google/gplus_columnIndices.txt"
  "Wikipedia|data/realworld_datasets/Wikipedia/wiki_rowOffsets.txt|data/realworld_datasets/Wikipedia/wiki_colIndices.txt"
  "Youtube|data/realworld_datasets/Youtube/youtube_rowOffsets.txt|data/realworld_datasets/Youtube/youtube_colIndices.txt"
  "HiggsNets|data/realworld_datasets/HiggsNets/higgsnets_rowOffsets.txt|data/realworld_datasets/HiggsNets/higgsnets_colIndices.txt"
  "Twitch|data/realworld_datasets/Twitch/large_twitch_edges_rowOffsets.txt|data/realworld_datasets/Twitch/large_twitch_edges_colIndices.txt"
  "Stackoverflow|data/realworld_datasets/StackOverflow/stackOverflow_rowOffsets.txt|data/realworld_datasets/StackOverflow/stackOverflow_columnIndices.txt"
  "Hyperlink|data/realworld_datasets/Hyperlink/hyperlink_rowOffsets.txt|data/realworld_datasets/Hyperlink/hyperlink_colIndices.txt"
  "Livejournal|data/realworld_datasets/LiveJournal/livejournal_rowOffsets.txt|data/realworld_datasets/LiveJournal/livejournal_colIndices.txt"
  "Patent|data/realworld_datasets/Patent/Patents_rowOffsets.txt|data/realworld_datasets/Patent/Patents_colIndices.txt"
)

# clean all previous data
rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR" "$RESULTS_DIR"

# ============================================================
# Main loop
# ============================================================
for entry in "${DATASET_CSR_LIST[@]}"; do
  IFS='|' read -r DATASET ROW_OFFSETS COL_INDICES <<< "$entry"

  echo "============================================================"
  echo "▶️  Running DATASET: $DATASET"
  echo "------------------------------------------------------------"

  GRAPH_METRICS_OUT="$METRICS_DIR/graph_metrics_${DATASET}.txt"
  : > "$GRAPH_METRICS_OUT"

#  ROUNDS=20
  ROUNDS=3

  echo "📊  Running XB-Pro on $DATASET ($ROUNDS rounds)..."
  "$XB_PRO_BIN" --dataset="$DATASET" --rounds="$ROUNDS" | tee -a "$GRAPH_METRICS_OUT"

  echo "📈  Aggregating results for dataset $DATASET..."
  conda run -n xb-env python3 "$PYTHON_SCRIPT" \
      "$DATASET" \
      "$GRAPH_METRICS_OUT" \
      "$SUMMARY_CSV_TEMP" \
      "$ROW_OFFSETS" \
      "$COL_INDICES"
done

# ============================================================
# Finalize summary
# ============================================================
cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"

echo "============================================================"
echo "🎉 All DATASETS processed."
echo "📄 Summary saved at:"
echo "   $SUMMARY_CSV"
echo "============================================================"
