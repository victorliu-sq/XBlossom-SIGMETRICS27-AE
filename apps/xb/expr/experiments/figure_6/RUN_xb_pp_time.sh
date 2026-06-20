#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Run XBPro on all real-world DATASETS.
#   (1) Measure runtime once
#   (2) Collect perf counters for 1 round (system-wide)
#   (3) Analyze results with Python script
# ============================================================

XB_PP_BIN="build/bin/run_xb_pp_by_dataset"
METRICS_DIR="tmp/xb_pp_time"
RESULTS_DIR="data/results"
STAMP="${RESULTS_DIR}/.stamp.figure_6_xbpp"

PYTHON_SCRIPT="expr/experiments/figure_6/RUN_xb_pp_time.py"
SUMMARY_CSV_TEMP="$METRICS_DIR/_xb_pp_summary.csv"
SUMMARY_CSV="$RESULTS_DIR/figure_6_xb_pp.csv"

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

# =============== Check the existence of stamp ==================
if [ -f "$STAMP" ]; then
  echo "✅ Figure 6 XB++ Part already generated (stamp found)"
  exit 0
fi

# clean all previous data
rm -rf $METRICS_DIR
mkdir -p $METRICS_DIR

for DATASET in "${DATASETS[@]}"; do
  echo "============================================================"
  echo "▶️  Running DATASET: $DATASET"
  echo "------------------------------------------------------------"

  TIMING_OUT_XB_PP="$METRICS_DIR/xb_pp_${DATASET}_timing.txt"

  # Reset files for this source node
  : > $TIMING_OUT_XB_PP

  ROUNDS=3

  # Run XB-PP
  echo "📊  Running XB-PP on  $DATASET ($ROUNDS round)..."
  $XB_PP_BIN --dataset=$DATASET --rounds=$ROUNDS | tee -a $TIMING_OUT_XB_PP

  # Analysis the profiling metrics
  echo "📈  Aggregating results for dataset $DATASET..."
  conda run -n xb-env python3 "$PYTHON_SCRIPT" \
      "$DATASET" \
      "$TIMING_OUT_XB_PP" \
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