#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Run XBPro on all real-world DATASETS.
#   (1) Measure runtime once
#   (2) Collect perf counters for 1 round (system-wide)
#   (3) Analyze results with Python script
# ============================================================

XB_BIN="build/bin/run_xb_by_dataset"
XB_PRO_BIN="build/bin/run_xb_pro_by_dataset"
METRICS_DIR="tmp/xb_and_xb_pro"
PYTHON_SCRIPT="expr/xb_pro/RUN_xb_and_xb_pro.py"
SUMMARY_CSV="$METRICS_DIR/_xb_and_xb_pro_summary.csv"

DATASETS=(
  Wikipedia
  Youtube
  HiggsNets
  Amazon
  GPlus
  Twitch
  Stackoverflow
  Hyperlink
  Livejournal
  Patent
)

# clean all previous data
rm -rf $METRICS_DIR
mkdir -p $METRICS_DIR

for DATASET in "${DATASETS[@]}"; do
  echo "============================================================"
  echo "▶️  Running DATASET: $DATASET"
  echo "------------------------------------------------------------"

  TIMING_OUT_XB="$METRICS_DIR/xb_${DATASET}_timing.txt"
  TIMING_OUT_XB_PRO="$METRICS_DIR/xb_pro_${DATASET}_timing.txt"

  # Reset files for this source node
  : > $TIMING_OUT_XB
  : > $TIMING_OUT_XB_PRO

  ROUNDS=20

  # Run XB
  echo "📊  Running XB on $DATASET ($ROUNDS round)..."
  $XB_BIN --dataset=$DATASET --rounds=$ROUNDS | tee -a $TIMING_OUT_XB

  # Run XB-Pro
  echo "📊  Running XB-Pro on  $DATASET ($ROUNDS round)..."
  $XB_PRO_BIN --dataset=$DATASET --rounds=$ROUNDS | tee -a $TIMING_OUT_XB_PRO

  # Analysis the profiling metrics
  echo "📈  Aggregating results for dataset $DATASET..."
  conda run -n xb-env python3 "$PYTHON_SCRIPT" \
      "$DATASET" \
      "$TIMING_OUT_XB" \
      "$TIMING_OUT_XB_PRO" \
      "$SUMMARY_CSV"

done

echo "============================================================"
echo "🎉 All DATASETS processed. Summary saved at:"
echo "   $SUMMARY_CSV"
echo "============================================================"