#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Run XBPro on all real-world DATASETS.
#   (1) Measure runtime once
#   (2) Collect perf counters for 1 round (system-wide)
#   (3) Analyze results with Python script
# ============================================================

XB_PRO_BIN="build/bin/run_xb_by_dataset"
METRICS_DIR="tmp/xb_metrics"
PYTHON_SCRIPT="expr/xb_pro/RUN_xb_all_datasets_intel_inst_llc_count_analysis.py"
SUMMARY_CSV="$METRICS_DIR/_xb_summary.csv"

DATASETS=(
  Amazon
  GPlus
  HiggsNets
  Hyperlink
  Livejournal
  Patent
  Stackoverflow
  Twitch
  Wikipedia
  Youtube
)

# clean all previous data
rm -rf $METRICS_DIR
mkdir -p $METRICS_DIR

echo "Profile original X-Blossom"

for DATASET in "${DATASETS[@]}"; do
  echo "============================================================"
  echo "▶️  Running DATASET: $DATASET"
  echo "------------------------------------------------------------"

  TIMING_OUT="$METRICS_DIR/xb_${DATASET}_timing.txt"
  PROFILER_OUT="$METRICS_DIR/xb_${DATASET}_profiling.txt"

  # Reset files
  : > $TIMING_OUT
  : > $PROFILER_OUT

  ROUNDS=50   # You can later change this and Python will respect it

  echo "📊  Profiling $DATASET ($ROUNDS round)..."
  perf stat -a -x, \
      -e instructions \
      -e cpu_core/LLC-load-misses/,cpu_core/LLC-loads/ \
      -o $PROFILER_OUT \
      -- $XB_PRO_BIN --dataset=$DATASET --rounds=$ROUNDS | tee -a $TIMING_OUT

  echo "📈  Aggregating results for dataset $DATASET..."
  conda run -n xb-env python3 "$PYTHON_SCRIPT" \
      "$DATASET" \
      "$TIMING_OUT" \
      "$PROFILER_OUT" \
      "$SUMMARY_CSV" \
      "$ROUNDS"

done

echo "============================================================"
echo "🎉 All DATASETS processed. Summary saved at:"
echo "   $SUMMARY_CSV"
echo "============================================================"