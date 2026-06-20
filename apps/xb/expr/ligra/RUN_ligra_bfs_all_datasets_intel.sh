#!/usr/bin/env bash
# ============================================================
# run_ligra_bfs_dynamic_src.sh
# ------------------------------------------------------------
# Run Ligra BFS on all real-world DATASETS using a dynamic list
# of source nodes loaded from a *_sources.txt file for each graph.
#
# Arguments in DATASETS:
# 1. Dataset Name (e.g., Amazon)
# 2. Graph File Path (Ligra .adj.txt)
# 3. Source Nodes File Path (e.g., amazon_sources.txt)
# ============================================================

set -euo pipefail

# --- Configuration ---
LIGRA_BIN="./third_party/ligra/apps/BFS"
METRICS_DIR="tmp/ligra_bfs_metrics_llc"
PYTHON_SCRIPT="expr/ligra/RUN_ligra_bfs_all_datasets_intel_analyze.py"
SUMMARY_CSV="$METRICS_DIR/_ligra_bfs_summary.csv"

# New Configuration for Aggregation
#AGGREGATE_SCRIPT="expr/ligra/aggregate_ligra_profile_rand_src.py"
#AGGREGATE_CSV="$METRICS_DIR/_ligra_bfs_aggregated_summary.csv"

# --- Dataset Definition ---
# NOTE: Ensure the second and third paths are correct relative to your execution directory.
DATASETS=(
  # Name        Graph Path (.adj.txt)                                Source Path (*_sources.txt)
  "GPlus       data/realworld_datasets/Google/gplus_adj.txt         data/realworld_datasets/Google/gplus_sources.txt"
  "Amazon      data/realworld_datasets/Amazon/amazon_adj.txt        data/realworld_datasets/Amazon/amazon_sources.txt"
  "HiggsNets   data/realworld_datasets/HiggsNets/higgsnets_adj.txt  data/realworld_datasets/HiggsNets/higgsnets_sources.txt"
  "Hyperlink   data/realworld_datasets/Hyperlink/hyperlink_adj.txt  data/realworld_datasets/Hyperlink/hyperlink_sources.txt"
  "LiveJournal data/realworld_datasets/LiveJournal/livejournal_adj.txt data/realworld_datasets/LiveJournal/livejournal_sources.txt"
  "Patent      data/realworld_datasets/Patent/patents_adj.txt       data/realworld_datasets/Patent/patents_sources.txt"
  "StackOverflow data/realworld_datasets/StackOverflow/stackoverflow_adj.txt data/realworld_datasets/StackOverflow/stackoverflow_sources.txt"
  "Twitch      data/realworld_datasets/Twitch/twitch_adj.txt        data/realworld_datasets/Twitch/twitch_sources.txt"
  "Wikipedia   data/realworld_datasets/Wikipedia/wiki_adj.txt       data/realworld_datasets/Wikipedia/wiki_sources.txt"
  "Youtube     data/realworld_datasets/Youtube/youtube_adj.txt      data/realworld_datasets/Youtube/youtube_sources.txt"
)

# --- Setup ---
echo "🗑️ Cleaning previous metrics directory..."
rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR"

# --- Main Processing Loop ---
for DATASET_ENTRY in "${DATASETS[@]}"; do
  set -- $DATASET_ENTRY
  DATASET_NAME=$1
  DATASET_PATH=$2
  SRC_FILE_PATH=$3

  echo "------------------------------------------------------------"
  echo "📦 Processing DATASET: $DATASET_NAME"
  echo "  Graph Path: $DATASET_PATH"
  echo "  Source Path: $SRC_FILE_PATH"

  # Read source nodes from the file, skipping comment lines starting with '#'
  # The mapfile command reads lines into an array
  mapfile -t SRC_NODES < <(grep -v '^#' "$SRC_FILE_PATH")

  for SRC in "${SRC_NODES[@]}"; do
    echo "  Loaded One Source Nodes: $SRC"

    # Define output files based on dataset name and source node
    TIMING_OUT="$METRICS_DIR/ligra_${DATASET_NAME}_src${SRC}_timing.txt"
    PROFILER_OUT="$METRICS_DIR/ligra_${DATASET_NAME}_src${SRC}_profiling.txt"

    # Reset files for this source node
    : > $TIMING_OUT
    : > $PROFILER_OUT

    ROUNDS=1000

    echo "📊  Profiling $DATASET_NAME ($ROUNDS round) for src $SRC..."
    perf stat -a -x, \
      -e cpu_core/LLC-load-misses/,cpu_core/LLC-loads/ \
      -o $PROFILER_OUT \
      -- $LIGRA_BIN -rounds $ROUNDS -r $SRC -s $DATASET_PATH | tee -a $TIMING_OUT

  done

  # for each dataset, aggregate all runtimes and llc cache misses.
  # Call Python aggregation for this dataset
  echo "📈  Aggregating results for dataset $DATASET_NAME..."
  conda run -n xb-env python3 "$PYTHON_SCRIPT" \
      "$DATASET_NAME" \
      "$METRICS_DIR" \
      "$SUMMARY_CSV"

done # End of DATASETS loop

#echo "============================================================"
echo "✨ Aggregating results are in $SUMMARY_CSV"
