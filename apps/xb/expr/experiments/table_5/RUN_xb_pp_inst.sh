#!/usr/bin/zsh
set -euo pipefail

# List of DATASETS
DATASETS=(
  Amazon
  GPlus
  Hyperlink
  Livejournal
  HiggsNets
  Patent
  Stackoverflow
  Twitch
  Wikipedia
  Youtube
)

CUDA_BIN="build/bin/run_xb_pp_by_dataset"
METRICS_DIR="tmp/xb_pp_metrics_inst"
RESULTS_DIR="data/results"
STAMP="${RESULTS_DIR}/.stamp.table_5_xbpp"

#NCU_METRICS="dram__bytes_read.sum,sm__sass_thread_inst_executed.sum"
#NCU_METRIC_1="dram__bytes_read.sum"
NCU_METRIC_2="sm__sass_thread_inst_executed.sum"
PYTHON_SCRIPT="expr/experiments/table_5/RUN_xb_pp_inst.py"
SUMMARY_CSV_TEMP="$METRICS_DIR/_xb_pp_inst_summary.csv"
SUMMARY_CSV="$RESULTS_DIR/table_5_xb_pp.csv"


# Check the existence of stamp
if [ -f "$STAMP" ]; then
  echo "✅ Table 5 XBPP Part already generated (stamp found)"
  exit 0
fi

if [[ ! -f ${CUDA_BIN} ]]; then
  echo "Binary does not exist"
  exit 1
else
  echo "CUDA_BIN is ${CUDA_BIN}"
fi

rm -rf $METRICS_DIR
mkdir -p $METRICS_DIR

for DATASET in "${DATASETS[@]}";
do
  TIMING_OUT="$METRICS_DIR/xb_pp_timing_${DATASET}.txt"

#  PROFILING_OUT="$METRICS_DIR/xb_pp_profile_${DATASET}.csv"

#  PROFILING_OUT_1="$METRICS_DIR/xb_pp_profile_${DATASET}_1.csv"
  PROFILING_OUT="$METRICS_DIR/xb_pp_profile_${DATASET}_2.csv"

  echo "=== Running dataset: $DATASET ==="
  # Step 1: Measure the runtime for one round
  $CUDA_BIN --dataset=$DATASET | tee -a $TIMING_OUT

  # Step 2: Profile data transfer rate and instruction execution rate
#  ncu --metrics $NCU_METRICS_NCU_METRICS --csv \
#          $CUDA_BIN --dataset=$DATASET > $PROFILING_OUT

#  echo "Measuring data transfer rate for $DATASET ..."
#  ncu --metrics $NCU_METRIC_1 --csv \
#      $CUDA_BIN --dataset=$DATASET > $PROFILING_OUT_1

  echo "Measuring instruction execution rate for $DATASET ..."
  ncu --metrics $NCU_METRIC_2 --csv \
      $CUDA_BIN --dataset=$DATASET > $PROFILING_OUT

  # Step 3: Aggregate metrics of all kernels, and calculate the rate using python script
  conda run -n xb-env python3 "$PYTHON_SCRIPT" "$DATASET" "$TIMING_OUT" "$PROFILING_OUT" "$SUMMARY_CSV_TEMP"
done

# ============================================================
# Finalize summary
# ============================================================
cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"

touch $STAMP

echo "============================================================"
echo "All GPU DATASETS processed (instruction execution rate analysis). "
echo "Results are in ${SUMMARY_CSV}."