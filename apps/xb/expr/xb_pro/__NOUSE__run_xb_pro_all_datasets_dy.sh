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
#PYTHON_SCRIPT="expr/xb_pro/__NOUSE__analyze_xb_pro_profile_diff.py"

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

  PROGRAM="$XB_PRO_BIN --dataset=$DATASET --rounds=1"
  TIMING_OUT="$METRICS_DIR/xb_pro_${DATASET}_timing.txt"
  PROFIING_OUT="$METRICS_DIR/xb_pro_${DATASET}_profiling.txt"

  # Step 1: timing for one round
  echo "[Shell] Measuring Runtime ... "

  > $TIMING_OUT
  $PROGRAM > $TIMING_OUT & # tee is disallowed
  PID=$!

  # Step 2: Await loading graph
  echo "[Shell] Waiting for $PID's LOAD_DONE..."
  while read LINE;
  do
      [[ $LINE == *"[LOAD_DONE]"* ]] && break
  done < $TIMING_OUT

  # Attach perf to the running process
  echo "[Shell] Attaching perf to PID $PID ..."
  perf stat -p $PID \
      -a -x , \
      -e instructions,cache-misses \
      -o $PROFIING_OUT > /dev/null

  # Step 3: analysis
  #  echo "📈  Analyzing results..."
  #  python3 "$PYTHON_SCRIPT" "$DATASET" "$profiler1_out" "$profiler4_out" "$TIMING_OUT"

done

# remove intermediate files
#sudo rm tmp/xb_pro_metrics/xb_pro_*

echo "============================================================"
echo "🎉 All DATASETS processed. Results saved to $METRICS_DIR"
