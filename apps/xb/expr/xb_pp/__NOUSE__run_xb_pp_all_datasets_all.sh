#!/usr/bin/zsh
set -euo pipefail

# List of DATASETS
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

XB_PP_BIN="build/bin/run_xb_pp_by_dataset"
METRICS_DIR="tmp/xb_pp_metrics"
NCU_METRICS="dram__bytes_read.sum,sm__sass_thread_inst_executed.sum"
PYTHON_SCRIPT="expr/xb_pp/__NOUSE__xb_pp_profile_analyzer_all.py"

if [[ ! -f ${XB_PP_BIN} ]]; then
  echo "Binary does not exist"
  exit 1
else
  echo "XB_PP_BIN is ${XB_PP_BIN}"
fi

rm -rf $METRICS_DIR
mkdir -p $METRICS_DIR

for DATASET in "${DATASETS[@]}"; do
  TIMING_OUT="$METRICS_DIR/xb_pp_timing_${DATASET}.txt"
  PROFILING_OUT="$METRICS_DIR/xb_pp_profile_${DATASET}.csv"
  SUMMARY_OUT="$METRICS_DIR/_xb_pp_summary_${DATASET}.csv"

  echo "=== Running dataset: $DATASET ==="
  # Step 1: Measure the runtime for one round
  $XB_PP_BIN --dataset=$DATASET | tee -a $TIMING_OUT

  # Step 2: Profile data transfer rate and instruction execution rate
  echo "Measuring data transfer rate and instruction execution rate for $DATASET ..."
  ncu --metrics $NCU_METRICS --csv \
          $XB_PP_BIN --dataset=$DATASET > $PROFILING_OUT

  # Step 3: Aggregate metrics of all kernels, and calculate the rate using python script
  python3 "$PYTHON_SCRIPT" "$DATASET" "$TIMING_OUT" "$PROFILING_OUT" "$SUMMARY_OUT"
done

echo "All GPU DATASETS processed (effective memory bandwidth analysis). Results are in $METRICS_DIR"
