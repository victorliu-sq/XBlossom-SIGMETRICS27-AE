#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Run XBPro on all real-world DATASETS.
#   (1) Measure runtime once
#   (2) Collect perf counters for 1 and 4 rounds
#   (3) Analyze results via Python script
# ============================================================

XB_PRO_BIN="build/bin/run_xb_pro_by_dataset"
METRICS_DIR="tmp/xb_pro_metrics"
PYTHON_SCRIPT="expr/xb_pro/__NOUSE__analyze_xb_pro_profile_diff.py"

DATASETS=(
  Amazon
#  GPlus
#  Hyperlink
#  Livejournal
#  HiggsNets
#  Patent
#  Stackoverflow
#  Twitch
#  Wikipedia
#  Youtube
)

# clean all previous data
rm -rf $METRICS_DIR
mkdir -p $METRICS_DIR

# For each DATASET, record intermediate result and calculate result.
for DATASET in "${DATASETS[@]}"; do
  echo "============================================================"
  echo "▶️  Running DATASET: $DATASET"
  echo "------------------------------------------------------------"

  timing_out="$METRICS_DIR/xb_pro_${DATASET}_timing.txt"
  profiler1_out="$METRICS_DIR/xb_pro_${DATASET}_1round.txt"
  profiler4_out="$METRICS_DIR/xb_pro_${DATASET}_4rounds.txt"

  # Step 1: timing for one round
  echo "⏱️  Measuring runtime for 1 round..."
  $XB_PRO_BIN --dataset=$DATASET --rounds=1 | tee $timing_out

  # Step 2a: perf 1 round
  echo "📊  Profiling $DATASET (1 round)..."
  perf stat -a -x, \
    -e instructions,cache-misses\
    -o "$profiler1_out" \
    -- $XB_PRO_BIN --dataset=$DATASET --rounds=1 > /dev/null

  # Step 2b: perf 4 rounds
#  echo "📊  profiling $DATASET (4 rounds)..."
#  sudo perf stat -a -x, \
#    -e instructions,\
#uncore_imc_free_running_0/unc_mc0_rdcas_count_freerun/,\
#uncore_imc_free_running_1/unc_mc1_rdcas_count_freerun/ \
#    -o "$profiler4_out" \
#    -- $XB_PRO_BIN --dataset=$DATASET --rounds=4 > /dev/null

  # Step 3: analysis
#  echo "📈  Analyzing results..."
#  python3 "$PYTHON_SCRIPT" "$DATASET" "$profiler1_out" "$profiler4_out" "$timing_out"

done

# remove intermediate files
#sudo rm tmp/xb_pro_metrics/xb_pro_*

echo "============================================================"
echo "🎉 All DATASETS processed. Results saved to $METRICS_DIR"
