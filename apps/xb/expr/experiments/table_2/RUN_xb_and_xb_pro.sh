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
RESULTS_DIR="data/results"
STAMP="${RESULTS_DIR}/.stamp.table_2_cpu"
PYTHON_SCRIPT="expr/experiments/table_2/RUN_xb_and_xb_pro.py"
SUMMARY_CSV_TEMP="$METRICS_DIR/_xb_and_xb_pro_summary.csv"
SUMMARY_CSV="$RESULTS_DIR/table_2_left.csv"

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

if [ -f "$STAMP" ]; then
  echo "✅ Table 2 CPU part already generated (stamp found)"
  exit 0
fi

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
#  ROUNDS=3

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
      "$SUMMARY_CSV_TEMP"

done

# ============================================================
# Finalize summary
# ============================================================
cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"

touch $STAMP

echo "============================================================"
echo "🎉 All DATASETS processed. Summary saved at:"
echo "   $SUMMARY_CSV"
echo "============================================================"