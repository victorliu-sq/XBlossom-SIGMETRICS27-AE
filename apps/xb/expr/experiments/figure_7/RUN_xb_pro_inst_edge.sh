#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Run XBPro on all real-world DATASETS.
#   (1) Measure runtime once
#   (2) Collect perf counters for 1 round (system-wide)
#   (3) Analyze results with Python script
# ============================================================

XB_PRO_BIN="build/bin/run_xb_pro_peredge_by_dataset"
METRICS_DIR="tmp/xb_pro_edge_level_inst"
RESULTS_DIR="data/results"
STAMP="${RESULTS_DIR}/.stamp.figure_7_edge"

PYTHON_SCRIPT="expr/experiments/figure_7/RUN_xb_pro_inst_edge.py"
SUMMARY_CSV_TEMP="$METRICS_DIR/_xb_pro_summary.csv"
SUMMARY_CSV="$RESULTS_DIR/figure_7_edge.csv"

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

# =============== Check the existence of stamp ==================
if [ -f "$STAMP" ]; then
  echo "✅ Figure 7 Edge Part already generated (stamp found)"
  exit 0
fi

# clean all previous data
rm -rf $METRICS_DIR
mkdir -p $METRICS_DIR

for DATASET in "${DATASETS[@]}"; do
  echo "============================================================"
  echo "▶️  Running DATASET: $DATASET"
  echo "------------------------------------------------------------"

  TIMING_OUT="$METRICS_DIR/xb_pro_${DATASET}_timing.txt"
  PROFILER_OUT="$METRICS_DIR/xb_pro_${DATASET}_profiling.txt"

  # Reset files
  : > $TIMING_OUT
  : > $PROFILER_OUT

#  ROUNDS=50   # You can later change this and Python will respect it
  ROUNDS=3

  echo "📊  Profiling $DATASET ($ROUNDS round)..."
  perf stat -a -x, \
      -e instructions \
      -o $PROFILER_OUT \
      -- $XB_PRO_BIN --dataset=$DATASET --rounds=$ROUNDS | tee -a $TIMING_OUT

  echo "📈  Aggregating results for dataset $DATASET..."
  conda run -n xb-env python3 "$PYTHON_SCRIPT" \
      "$DATASET" \
      "$TIMING_OUT" \
      "$PROFILER_OUT" \
      "$SUMMARY_CSV_TEMP" \
      "$ROUNDS"

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