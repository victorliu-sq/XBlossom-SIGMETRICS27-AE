#!/usr/bin/bash
set -euo pipefail

# List of datasets
DATASETS=(
#  "GunrockSample third_party/gunrock/datasets/chesapeake/chesapeake.mtx"
  "Amazon data/realworld_datasets/Amazon/amazon.mtx"
  "GPlus data/realworld_datasets/Google/gplus.mtx"
  "HiggsNets data/realworld_datasets/HiggsNets/higgsnets.mtx"
  "Hyperlink data/realworld_datasets/Hyperlink/hyperlink.mtx"
  "Livejournal data/realworld_datasets/LiveJournal/livejournal.mtx"
  "Patent data/realworld_datasets/Patent/patents.mtx"
  "Stackoverflow data/realworld_datasets/StackOverflow/stackoverflow.mtx"
  "Twitch data/realworld_datasets/Twitch/twitch.mtx"
  "Wikipedia data/realworld_datasets/Wikipedia/wiki.mtx"
  "Youtube data/realworld_datasets/Youtube/youtube.mtx"
)

CUDA_BIN="third_party/gunrock/build/bin/bfs"
METRICS_DIR="tmp/gunrock_bfs_metrics_dram_read"

NCU_METRIC_1="dram__bytes_read.sum"
NCU_METRIC_2="sm__sass_thread_inst_executed.sum"

PYTHON_SCRIPT="expr/gunrock/RUN_gunrock_bfs_all_datasets_dram_read_analysis.py"
SUMMARY_OUT="$METRICS_DIR/_gunrock_bfs_summary.csv"

# Check for the existence of gunrock-bfs binary
if [[ ! -f ${CUDA_BIN} ]]; then
  echo "Binary does not exist"
  exit 1
else
  echo "CUDA_BIN is ${CUDA_BIN}"
fi

# Reset the metrics directory
rm -rf $METRICS_DIR
mkdir -p $METRICS_DIR

# Iterate over datasets, run bfs on each of them, and profile the execution.
for DATASET_ENTRY in "${DATASETS[@]}";
do
  set -- $DATASET_ENTRY
  DATASET_NAME=$1
  DATASET_PATH=$2

  echo "------------------------------------------------------------"
  echo "📦 Processing:"
  echo "   DATASET_NAME: $DATASET_NAME"
  echo "   DATASET_PATH: $DATASET_PATH"

  TIMING_OUT="$METRICS_DIR/gunrock_bfs_timing_${DATASET_NAME}.txt"

  PROFILING_OUT_1="$METRICS_DIR/gunrock_bfs_profile_${DATASET_NAME}_1.csv"
  PROFILING_OUT_2="$METRICS_DIR/gunrock_bfs_profile_${DATASET_NAME}_2.csv"

  # Step 1: Measure the runtime for one round
  touch $TIMING_OUT
  $CUDA_BIN -s 0 -m $DATASET_PATH | tee -a $TIMING_OUT

  # Step 2: Profile data transfer rate and instruction execution rate
  echo "Measuring data transfer rate for $DATASET_NAME ..."
  ncu --metrics $NCU_METRIC_1 --csv \
      $CUDA_BIN -s 0 -m $DATASET_PATH > $PROFILING_OUT_1

  echo "Measuring instruction execution rate for $DATASET_NAME ..."
  ncu --metrics $NCU_METRIC_2 --csv \
      $CUDA_BIN -s 0 -m $DATASET_PATH > $PROFILING_OUT_2

  # Step 3: Aggregate metrics of all kernels, and calculate the rate using python script
  conda run -n xb-env --no-capture-output python3 "$PYTHON_SCRIPT" "$DATASET_NAME" "$TIMING_OUT" "$PROFILING_OUT_1" "$PROFILING_OUT_2" "$SUMMARY_OUT"
done