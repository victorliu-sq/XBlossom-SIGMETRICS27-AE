#!/usr/bin/bash
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
METRICS_DIR="tmp/xb_pp_metrics_dram_read_stalled_cycles"

NCU_METRIC_1="dram__bytes_read.sum"
NCU_METRIC_2="sm__sass_thread_inst_executed.sum"
NCU_METRIC_3="smsp__average_warp_latency_issue_stalled_long_scoreboard"

PYTHON_SCRIPT="expr/xb_pp/RUN_xb_pp_dram_read_stalled_cycles_analyze.py"
SUMMARY_OUT="$METRICS_DIR/_xb_pp_summary.csv"

if [[ ! -f ${CUDA_BIN} ]]; then
  echo "Binary does not exist"
  exit 1
else
  echo "CUDA_BIN is ${CUDA_BIN}"
fi

rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR"

for DATASET in "${DATASETS[@]}"; do
  TIMING_OUT="$METRICS_DIR/xb_pp_timing_${DATASET}.txt"

  PROFILING_OUT_1="$METRICS_DIR/xb_pp_profile_${DATASET}_1.csv"  # DRAM bytes
  PROFILING_OUT_2="$METRICS_DIR/xb_pp_profile_${DATASET}_2.csv"  # Instructions
  PROFILING_OUT_3="$METRICS_DIR/xb_pp_profile_${DATASET}_3.csv"  # Long scoreboard latency

  echo "=== Running dataset: $DATASET ==="

  # Step 1: Measure the runtime for one round
  "$CUDA_BIN" --dataset="$DATASET" | tee -a "$TIMING_OUT"

  # Step 2: Profile data transfer rate, instruction rate, and long scoreboard latency

  echo "Measuring data transfer rate for $DATASET ..."
  ncu --metrics "$NCU_METRIC_1" --csv \
      "$CUDA_BIN" --dataset="$DATASET" > "$PROFILING_OUT_1"

  echo "Measuring instruction execution rate for $DATASET ..."
  ncu --metrics "$NCU_METRIC_2" --csv \
      "$CUDA_BIN" --dataset="$DATASET" > "$PROFILING_OUT_2"

  echo "Measuring long scoreboard warp latency for $DATASET ..."
  ncu --metrics "$NCU_METRIC_3" --csv \
      "$CUDA_BIN" --dataset="$DATASET" > "$PROFILING_OUT_3"

  # Step 3: Aggregate metrics of all kernels, and calculate the rates using python script
  python3 "$PYTHON_SCRIPT" \
          "$DATASET" \
          "$TIMING_OUT" \
          "$PROFILING_OUT_1" \
          "$PROFILING_OUT_2" \
          "$PROFILING_OUT_3" \
          "$SUMMARY_OUT"
done

echo "All GPU DATASETS processed (effective memory bandwidth + stall analysis). Results are in $METRICS_DIR"
