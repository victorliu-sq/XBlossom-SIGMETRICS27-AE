#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Run XBPro on all real-world DATASETS.
#   (1) Measure runtime once
#   (2) Collect perf counters for 1 round (system-wide)
#   (3) Analyze results with Python script
# ============================================================

XB_PRO_BIN="build/bin/run_xb_pro_by_dataset"
METRICS_DIR="tmp/xb_pro_metrics"
PYTHON_SCRIPT="expr/xb_pro/__NOUSE__analyze_xb_pro_profile_simple.py"
SUMMARY_CSV="$METRICS_DIR/_xb_pro_summary.csv"

DATASETS=(
  Amazon
  GPlus
  Hyperlink
  Livejournal
  HiggsNets
  Patent
  Stackoverflow
  Twitch
  Wikipedia
  Youtube
)

# clean all previous data
rm -rf $METRICS_DIR
mkdir -p $METRICS_DIR

for DATASET in "${DATASETS[@]}"; do
  echo "============================================================"
  echo "▶️  Running DATASET: $DATASET"
  echo "------------------------------------------------------------"

  TIMING_OUT="$METRICS_DIR/xb_pro_${DATASET}_timing.txt"
  PROFILER_OUT="$METRICS_DIR/xb_pro_${DATASET}_profiling.txt"

  # ----------------------------------------
  # Step 1 — Measure runtime for 1 round
  # ----------------------------------------
  echo "⏱️  Measuring runtime for 1 round..."
  $XB_PRO_BIN --dataset="$DATASET" --rounds=1 | tee "$TIMING_OUT"

  # ----------------------------------------
  # Step 2 — System-wide perf profiling
  # ----------------------------------------
  echo "📊  Profiling $DATASET (1 round)..."
  perf stat -a -x, \
      -e instructions,l3_misses \
      -o "$PROFILER_OUT" \
      -- $XB_PRO_BIN --dataset="$DATASET" --rounds=1 > /dev/null

  # ----------------------------------------
  # Step 3 — Analyze results
  # ----------------------------------------
  echo "📈  Analyzing results into summary CSV..."
  conda run -n xb-env python3 $PYTHON_SCRIPT $DATASET $PROFILER_OUT $TIMING_OUT $SUMMARY_CSV

done

echo "============================================================"
echo "🎉 All DATASETS processed. Summary saved at:"
echo "   $SUMMARY_CSV"
echo "============================================================"
