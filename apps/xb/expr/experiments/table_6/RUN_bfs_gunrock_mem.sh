#!/usr/bin/bash
set -euo pipefail

CUDA_BIN="third_party/gunrock/build/bin/bfs"
METRICS_DIR="tmp/bfs_gunrock_mem"
RESULTS_DIR="data/results"
STAMP="${RESULTS_DIR}/.stamp.table_6_gunrock"

NCU_METRIC_1="dram__bytes_read.sum"
#NCU_METRIC_2="sm__sass_thread_inst_executed.sum"

PYTHON_SCRIPT="expr/experiments/table_6/RUN_bfs_gunrock_mem.py"
SUMMARY_CSV_TEMP="$METRICS_DIR/_bfs_gunrock_mem_summary.csv"
SUMMARY_CSV="$RESULTS_DIR/table_6_bfs_gunrock.csv"

# List of datasets
DATASETS=(
  "Amazon        data/realworld_datasets/Amazon/amazon.mtx        data/realworld_datasets/Amazon/amazon_sources.txt"
  "GPlus         data/realworld_datasets/Google/gplus.mtx         data/realworld_datasets/Google/gplus_sources.txt"
  "HiggsNets     data/realworld_datasets/HiggsNets/higgsnets.mtx  data/realworld_datasets/HiggsNets/higgsnets_sources.txt"
  "Hyperlink     data/realworld_datasets/Hyperlink/hyperlink.mtx  data/realworld_datasets/Hyperlink/hyperlink_sources.txt"
  "Livejournal   data/realworld_datasets/LiveJournal/livejournal.mtx data/realworld_datasets/LiveJournal/livejournal_sources.txt"
  "Patent        data/realworld_datasets/Patent/patents.mtx       data/realworld_datasets/Patent/patents_sources.txt"
  "Stackoverflow data/realworld_datasets/StackOverflow/stackoverflow.mtx data/realworld_datasets/StackOverflow/stackoverflow_sources.txt"
  "Twitch        data/realworld_datasets/Twitch/twitch.mtx        data/realworld_datasets/Twitch/twitch_sources.txt"
  "Wikipedia     data/realworld_datasets/Wikipedia/wiki.mtx       data/realworld_datasets/Wikipedia/wiki_sources.txt"
  "Youtube       data/realworld_datasets/Youtube/youtube.mtx      data/realworld_datasets/Youtube/youtube_sources.txt"
)

# =============== Check the existence of stamp ==================
if [ -f "$STAMP" ]; then
  echo "✅ Table 6 Gunrock Part already generated (stamp found)"
  exit 0
fi

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
  SRC_FILE_PATH=$3

  echo "------------------------------------------------------------"
  echo "📦 Processing:"
  echo "   DATASET_NAME: $DATASET_NAME"
  echo "   DATASET_PATH: $DATASET_PATH"
  echo "   Source File: $SRC_FILE_PATH"

  # Load source nodes, skip comments
  mapfile -t SRC_NODES < <(grep -v '^#' "$SRC_FILE_PATH")
  SRC=${SRC_NODES[0]}

  TIMING_OUT="$METRICS_DIR/gunrock_bfs_timing_${DATASET_NAME}.txt"

  PROFILING_OUT_1="$METRICS_DIR/gunrock_bfs_profile_${DATASET_NAME}_1.csv"
#  PROFILING_OUT_2="$METRICS_DIR/gunrock_bfs_profile_${DATASET_NAME}_2.csv"

  # Step 1: Measure the runtime for one round
  touch $TIMING_OUT
  $CUDA_BIN -s "$SRC" -m $DATASET_PATH | tee -a $TIMING_OUT

  # Step 2: Profile data transfer rate and instruction execution rate
  echo "Measuring data transfer rate for $DATASET_NAME ..."
  ncu --metrics $NCU_METRIC_1 --csv \
      $CUDA_BIN -s "$SRC" -m $DATASET_PATH > $PROFILING_OUT_1

#  echo "Measuring instruction execution rate for $DATASET_NAME ..."
#  ncu --metrics $NCU_METRIC_2 --csv \
#      $CUDA_BIN -s "$SRC" -m $DATASET_PATH > $PROFILING_OUT_2

  # Step 3: Aggregate metrics of all kernels, and calculate the rate using python script
#  conda run -n xb-env --no-capture-output python3 "$PYTHON_SCRIPT" "$DATASET_NAME" "$TIMING_OUT" "$PROFILING_OUT_2" "$SUMMARY_CSV_TEMP"
  conda run -n xb-env --no-capture-output python3 "$PYTHON_SCRIPT" "$DATASET_NAME" "$TIMING_OUT" "$PROFILING_OUT_1" "$SUMMARY_CSV_TEMP"
done

# ============================================================
# Finalize summary
# ============================================================
cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"

touch $STAMP

echo "============================================================"
echo "All GPU DATASETS processed (instruction execution rate analysis). "
echo "Results are in ${SUMMARY_CSV}."
