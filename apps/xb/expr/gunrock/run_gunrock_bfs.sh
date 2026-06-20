#!/usr/bin/bash
set -euo pipefail

# ============================================================
# Gunrock BFS GPU Runner (with dynamic source node)
# ============================================================

DATASETS=(
  "Amazon     data/realworld_datasets/Amazon/amazon.mtx         data/realworld_datasets/Amazon/amazon_sources.txt"
  "GPlus      data/realworld_datasets/Google/gplus.mtx          data/realworld_datasets/Google/gplus_sources.txt"
  "HiggsNets  data/realworld_datasets/HiggsNets/higgsnets.mtx   data/realworld_datasets/HiggsNets/higgsnets_sources.txt"
  "Hyperlink  data/realworld_datasets/Hyperlink/hyperlink.mtx   data/realworld_datasets/Hyperlink/hyperlink_sources.txt"
  "Livejournal data/realworld_datasets/LiveJournal/livejournal.mtx data/realworld_datasets/LiveJournal/livejournal_sources.txt"
  "Patent     data/realworld_datasets/Patent/patents.mtx        data/realworld_datasets/Patent/patents_sources.txt"
  "Stackoverflow data/realworld_datasets/StackOverflow/stackoverflow.mtx data/realworld_datasets/StackOverflow/stackoverflow_sources.txt"
  "Twitch     data/realworld_datasets/Twitch/twitch.mtx         data/realworld_datasets/Twitch/twitch_sources.txt"
  "Wikipedia  data/realworld_datasets/Wikipedia/wiki.mtx        data/realworld_datasets/Wikipedia/wiki_sources.txt"
  "Youtube    data/realworld_datasets/Youtube/youtube.mtx       data/realworld_datasets/Youtube/youtube_sources.txt"
)

CUDA_BIN="third_party/gunrock/build/bin/bfs"
METRICS_DIR="tmp/gunrock_bfs_metrics"

NCU_METRIC_1="dram__bytes_read.sum"
NCU_METRIC_2="sm__sass_thread_inst_executed.sum"

PYTHON_SCRIPT="expr/gunrock/gunrock_bfs_profile_analyzer_indep.py"
SUMMARY_OUT="$METRICS_DIR/_gunrock_bfs_summary.csv"

# ============================================================
# Pre-flight checks
# ============================================================

if [[ ! -f "$CUDA_BIN" ]]; then
  echo "❌ Gunrock BFS binary not found: $CUDA_BIN"
  exit 1
fi

echo "CUDA_BIN = $CUDA_BIN"

rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR"

# ============================================================
# Main Loop
# ============================================================

for ENTRY in "${DATASETS[@]}"; do
  set -- $ENTRY
  DATASET_NAME=$1
  DATASET_PATH=$2
  SRC_FILE=$3

  echo "------------------------------------------------------------"
  echo "📦 DATASET: $DATASET_NAME"
  echo "📄 Graph:   $DATASET_PATH"
  echo "📄 SRC:     $SRC_FILE"

  # Load only the first valid source node
  mapfile -t SRC_NODES < <(grep -v '^#' "$SRC_FILE")
  SRC="${SRC_NODES[0]}"

  echo "🔍 Using source node = $SRC"

  # Output file names include dataset + src
  TIMING_OUT="$METRICS_DIR/gunrock_bfs_${DATASET_NAME}_src${SRC}_timing.txt"
  PROFILING_OUT_1="$METRICS_DIR/gunrock_bfs_${DATASET_NAME}_src${SRC}_profile_1.csv"
  PROFILING_OUT_2="$METRICS_DIR/gunrock_bfs_${DATASET_NAME}_src${SRC}_profile_2.csv"

  : > "$TIMING_OUT"
  : > "$PROFILING_OUT_1"
  : > "$PROFILING_OUT_2"

  # ============================================================
  # Step 1: Runtime (Gunrock BFS)
  # ============================================================
  echo "⏱ Running BFS for $DATASET_NAME (SRC=$SRC)"
  "$CUDA_BIN" -s "$SRC" -m "$DATASET_PATH" | tee -a "$TIMING_OUT"

  # ============================================================
  # Step 2: Profiling
  # ============================================================

  echo "📊 Profiling dram__bytes_read for $DATASET_NAME"
  ncu --metrics $NCU_METRIC_1 --csv \
      "$CUDA_BIN" -s "$SRC" -m "$DATASET_PATH" > "$PROFILING_OUT_1"

  echo "📊 Profiling sm__sass_thread_inst_executed for $DATASET_NAME"
  ncu --metrics $NCU_METRIC_2 --csv \
      "$CUDA_BIN" -s "$SRC" -m "$DATASET_PATH" > "$PROFILING_OUT_2"

  # ============================================================
  # Step 3: Python Aggregation Per Dataset
  # ============================================================

  conda run -n xb-env python3 "$PYTHON_SCRIPT" \
      "$DATASET_NAME" \
      "$TIMING_OUT" \
      "$PROFILING_OUT_1" \
      "$PROFILING_OUT_2" \
      "$SUMMARY_OUT"

done

echo "============================================================"
echo "🎉 All GPU BFS runs complete!"
echo "📊 Summary located at: $SUMMARY_OUT"
echo "============================================================"
