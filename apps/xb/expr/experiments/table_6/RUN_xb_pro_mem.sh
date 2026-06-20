#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Run XBPro on all real-world DATASETS.
#   (1) Measure runtime once
#   (2) Collect perf counters for 1 round (system-wide)
#   (3) Analyze results with Python script
# ============================================================

XB_PRO_BIN="build/bin/run_xb_pro_by_dataset"
METRICS_DIR="tmp/xb_pro_mem"
RESULTS_DIR="data/results"
STAMP="${RESULTS_DIR}/.stamp.table_6_xbpro"

PYTHON_SCRIPT="expr/experiments/table_6/RUN_xb_pro_mem.py"
SUMMARY_CSV_TEMP="$METRICS_DIR/_xb_pro_mem_summary.csv"
SUMMARY_CSV="$RESULTS_DIR/table_6_xb_pro.csv"

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
  echo "✅ Table 6 XB-Pro Part already generated (stamp found)"
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
      -e cpu_core/LLC-load-misses/,cpu_core/LLC-loads/ \
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