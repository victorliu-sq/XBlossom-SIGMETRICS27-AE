#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}"

XB_PP_NR_BIN="${PROJECT_DIR}/build/apps/xb/bin/run_xb_pp_nr_by_dataset"
XB_PP_BIN="${PROJECT_DIR}/build/apps/xb/bin/run_xb_pp_by_dataset"
METRICS_DIR="${PROJECT_DIR}/tmp/2_reuse/xb_pp_r_and_nr"
RESULTS_DIR="${PROJECT_DIR}/results/2_reuse"
STAMP="${RESULTS_DIR}/.stamp.xb_pp_r_and_nr"
SUMMARY_CSV="${RESULTS_DIR}/table_2_right.csv"

if [ -f "$STAMP" ]; then
  echo "Table 2 GPU part already generated (stamp found)"
  exit 0
fi

DATASET_CSR_LIST=(
  "Wikipedia|${PROJECT_DIR}/data/xb/Wikipedia/wiki_rowOffsets.txt|${PROJECT_DIR}/data/xb/Wikipedia/wiki_colIndices.txt|19"
  "Youtube|${PROJECT_DIR}/data/xb/Youtube/youtube_rowOffsets.txt|${PROJECT_DIR}/data/xb/Youtube/youtube_colIndices.txt|20"
  "HiggsNets|${PROJECT_DIR}/data/xb/HiggsNets/higgsnets_rowOffsets.txt|${PROJECT_DIR}/data/xb/HiggsNets/higgsnets_colIndices.txt|1350"
  "Amazon|${PROJECT_DIR}/data/xb/Amazon/amazon_rowOffsets.txt|${PROJECT_DIR}/data/xb/Amazon/amazon_colIndices.txt|20"
  "GPlus|${PROJECT_DIR}/data/xb/Google/gplus_rowOffsets.txt|${PROJECT_DIR}/data/xb/Google/gplus_columnIndices.txt|5650"
  "Twitch|${PROJECT_DIR}/data/xb/Twitch/large_twitch_edges_rowOffsets.txt|${PROJECT_DIR}/data/xb/Twitch/large_twitch_edges_colIndices.txt|1200"
  "Stackoverflow|${PROJECT_DIR}/data/xb/StackOverflow/stackOverflow_rowOffsets.txt|${PROJECT_DIR}/data/xb/StackOverflow/stackOverflow_columnIndices.txt|87"
  "Hyperlink|${PROJECT_DIR}/data/xb/Hyperlink/hyperlink_rowOffsets.txt|${PROJECT_DIR}/data/xb/Hyperlink/hyperlink_colIndices.txt|420"
  "Livejournal|${PROJECT_DIR}/data/xb/LiveJournal/livejournal_rowOffsets.txt|${PROJECT_DIR}/data/xb/LiveJournal/livejournal_colIndices.txt|80"
  "Patent|${PROJECT_DIR}/data/xb/Patent/Patents_rowOffsets.txt|${PROJECT_DIR}/data/xb/Patent/Patents_colIndices.txt|120"
)

rm -rf "$METRICS_DIR"
mkdir -p "$METRICS_DIR" "$RESULTS_DIR"

if [[ ! -x "$XB_PP_NR_BIN" || ! -x "$XB_PP_BIN" ]]; then
  echo "ERROR: XB++ binaries not found under ${PROJECT_DIR}/build/apps/xb/bin" >&2
  echo "Run 'make build' before running this script." >&2
  exit 1
fi

for entry in "${DATASET_CSR_LIST[@]}"; do
  IFS='|' read -r DATASET ROW_OFFSETS COL_INDICES PATH_BUFFER_RATIO <<< "$entry"

  echo "============================================================"
  echo "Running DATASET: $DATASET"
  echo "------------------------------------------------------------"

  TIMING_OUT_XB_PP_NR="$METRICS_DIR/xb_pp_nr_${DATASET}_timing.txt"
  TIMING_OUT_XB_PP="$METRICS_DIR/xb_pp_${DATASET}_timing.txt"

  : > "$TIMING_OUT_XB_PP_NR"
  : > "$TIMING_OUT_XB_PP"

  ROUNDS="${ROUNDS:-20}"

  echo "Running XB-PP-NR on $DATASET ($ROUNDS rounds)..."
  "$XB_PP_NR_BIN" \
      --dataset="$DATASET" \
      --rounds="$ROUNDS" \
      --row_offsets="$ROW_OFFSETS" \
      --col_indices="$COL_INDICES" \
      --path_buffer_ratio="$PATH_BUFFER_RATIO" \
      | tee -a "$TIMING_OUT_XB_PP_NR"

  echo "Running XB-PP on $DATASET ($ROUNDS rounds)..."
  "$XB_PP_BIN" \
      --dataset="$DATASET" \
      --rounds="$ROUNDS" \
      --row_offsets="$ROW_OFFSETS" \
      --col_indices="$COL_INDICES" \
      --path_buffer_ratio="$PATH_BUFFER_RATIO" \
      | tee -a "$TIMING_OUT_XB_PP"

done

touch "$STAMP"

echo "============================================================"
echo "All DATASETS processed. Timing files saved under:"
echo "   $METRICS_DIR"
echo "Run ${SCRIPT_DIR}/generate_table_gpu.sh to generate:"
echo "   $SUMMARY_CSV"
echo "============================================================"
