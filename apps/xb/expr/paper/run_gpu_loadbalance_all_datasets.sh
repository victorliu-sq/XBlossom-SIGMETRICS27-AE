#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Run XBPro on all real-world DATASETS.
#   (1) Measure runtime once
#   (2) Collect perf counters for 1 round (system-wide)
#   (3) Analyze results with Python script
# ============================================================

XB_PP_PER_NODE_BIN="build/bin/run_xb_pp_pernode_by_dataset"
XB_PP_PER_EDGE_BIN="build/bin/run_xb_pp_peredge_by_dataset"
METRICS_DIR="tmp/xb_pp_pernode_peredge"
PYTHON_SCRIPT="expr/paper/run_gpu_loadbalance_all_datasets.py"
SUMMARY_CSV="$METRICS_DIR/_gpu_loadbalance_summary.csv"

DATASETS=(
  Stackoverflow
  Patent
  Wikipedia
  Youtube
  HiggsNets
  Amazon
  GPlus
  Twitch
  Hyperlink
  Livejournal
)

# clean all previous data
rm -rf $METRICS_DIR
mkdir -p $METRICS_DIR

for DATASET in "${DATASETS[@]}"; do
  echo "============================================================"
  echo "▶️  Running DATASET: $DATASET"
  echo "------------------------------------------------------------"

  TIMING_OUT_XB_PP_PEREDGE="$METRICS_DIR/xb_pp_peredge_${DATASET}_timing.txt"
  TIMING_OUT_XB_PP_PERNODE="$METRICS_DIR/xb_pp_pernode_${DATASET}_timing.txt"

  # Reset files for this source node
  : > $TIMING_OUT_XB_PP_PEREDGE
  : > $TIMING_OUT_XB_PP_PERNODE

  ROUNDS=8

  # Run XB-Pro-PerNode
  echo "📊  Running XB-PerNode on  $DATASET ($ROUNDS round)..."
  $XB_PP_PER_NODE_BIN --dataset=$DATASET --rounds=$ROUNDS | tee -a $TIMING_OUT_XB_PP_PERNODE

  # Run XB-Pro-PerEdge
  echo "📊  Running XB-PerEdge on $DATASET ($ROUNDS round)..."
  $XB_PP_PER_EDGE_BIN --dataset=$DATASET --rounds=$ROUNDS | tee -a $TIMING_OUT_XB_PP_PEREDGE

  # Analysis the profiling metrics
  echo "📈  Aggregating results for dataset $DATASET..."
  conda run -n xb-env python3 "$PYTHON_SCRIPT" \
      "$DATASET" \
      "$TIMING_OUT_XB_PP_PEREDGE" \
      "$TIMING_OUT_XB_PP_PERNODE" \
      "$SUMMARY_CSV"

done

echo "============================================================"
echo "🎉 All DATASETS processed. Summary saved at:"
echo "   $SUMMARY_CSV"
echo "============================================================"
