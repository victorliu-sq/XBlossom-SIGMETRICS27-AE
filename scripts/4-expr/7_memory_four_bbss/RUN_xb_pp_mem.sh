#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

XB_PP_BIN="${XB_BIN_DIR}/run_xb_pp_by_dataset"
METRICS_DIR="${PROJECT_DIR}/tmp/7_memory_four_bbss/xb_pp"
RESULTS_DIR="${PROJECT_DIR}/results/7_memory_four_bbss"
STAMP="${RESULTS_DIR}/.stamp.table_7_xbpp"
ANALYZE_SCRIPT="${SCRIPT_DIR}/analyze_xb_pp_mem.sh"
SUMMARY_CSV_TEMP="${METRICS_DIR}/_xb_pp_mem_summary.csv"
SUMMARY_CSV="${RESULTS_DIR}/table_7_xb_pp.csv"
SAMPLES_CSV="${RESULTS_DIR}/table_7_xb_pp_samples.csv"
NCU_METRIC="dram__bytes_op_read.sum"
ROUNDS="${ROUNDS:-500}"
TIMING_CHUNKS="${TIMING_CHUNKS:-20}"
CHUNK_ROUNDS="${CHUNK_ROUNDS:-25}"
PROFILE_ROUNDS="${PROFILE_ROUNDS:-1}"
PROFILE_RUNS="${PROFILE_RUNS:-20}"
XB_PP_RETRIES="${XB_PP_RETRIES:-3}"
START_DATASET="${START_DATASET:-}"

if [[ -f "$STAMP" ]]; then
  echo "Table 14 XB-PP part already generated (stamp found)"
  exit 0
fi

require_executable "$XB_PP_BIN" "XB-PP binary"
if [[ -z "$START_DATASET" ]]; then
  rm -rf "$METRICS_DIR"
fi
mkdir -p "$METRICS_DIR" "$RESULTS_DIR"

run_with_retries() {
  local label="$1"
  shift

  local attempt
  for attempt in $(seq 1 "$XB_PP_RETRIES"); do
    if "$@"; then
      return 0
    fi
    echo "WARNING: ${label} failed on attempt ${attempt}/${XB_PP_RETRIES}" >&2
    sleep 2
  done

  echo "ERROR: ${label} failed after ${XB_PP_RETRIES} attempts" >&2
  return 1
}

started=0
if [[ -z "$START_DATASET" ]]; then
  started=1
fi

for entry in "${DATASET_CSR_LIST[@]}"; do
  IFS='|' read -r DATASET ROW_OFFSETS COL_INDICES PATH_BUFFER_RATIO <<< "$entry"
  if [[ "$started" == "0" ]]; then
    if [[ "$DATASET" == "$START_DATASET" ]]; then
      started=1
    else
      echo "Skipping XB++ ${DATASET}; waiting for START_DATASET=${START_DATASET}"
      continue
    fi
  fi

  TIMING_OUT="${METRICS_DIR}/xb_pp_${DATASET}_timing.txt"
  PROFILING_DIR="${METRICS_DIR}/xb_pp_${DATASET}_profile"
  : > "$TIMING_OUT"
  rm -rf "$PROFILING_DIR"
  mkdir -p "$PROFILING_DIR"

  echo "Running XB++ ${DATASET} memory timing (${ROUNDS} rounds as ${TIMING_CHUNKS}x${CHUNK_ROUNDS})..."
  for CHUNK in $(seq 1 "$TIMING_CHUNKS"); do
    echo "Timing chunk ${CHUNK}/${TIMING_CHUNKS}" | tee -a "$TIMING_OUT"
    run_with_retries "XB++ ${DATASET} timing chunk ${CHUNK}" \
        run_xb_dataset "$XB_PP_BIN" "$DATASET" "$CHUNK_ROUNDS" "$ROW_OFFSETS" "$COL_INDICES" "$PATH_BUFFER_RATIO" \
        | tee -a "$TIMING_OUT"
  done
  echo "Profiling XB++ ${DATASET} memory counter (${PROFILE_RUNS} profile runs, ${PROFILE_ROUNDS} rounds each)..."
  for PROFILE_RUN in $(seq 1 "$PROFILE_RUNS"); do
    printf -v PROFILE_ID "%02d" "$PROFILE_RUN"
    PROFILING_OUT="${PROFILING_DIR}/profile_${PROFILE_ID}.csv"
    echo "Profile run ${PROFILE_RUN}/${PROFILE_RUNS}" | tee -a "$TIMING_OUT"
    run_with_retries "XB++ ${DATASET} profile run ${PROFILE_RUN}" \
        run_ncu --metrics "$NCU_METRIC" --csv \
        "$XB_PP_BIN" --dataset="$DATASET" --rounds="$PROFILE_ROUNDS" --row_offsets="$ROW_OFFSETS" --col_indices="$COL_INDICES" --path_buffer_ratio="$PATH_BUFFER_RATIO" \
        > "$PROFILING_OUT"
  done
  "$ANALYZE_SCRIPT" "$DATASET" "$TIMING_OUT" "$PROFILING_DIR" "$SUMMARY_CSV_TEMP" "$ROUNDS" "$PROFILE_ROUNDS"
done

cp "$SUMMARY_CSV_TEMP" "$SUMMARY_CSV"
cp "${SUMMARY_CSV_TEMP%.csv}_samples.csv" "$SAMPLES_CSV"
touch "$STAMP"
echo "Summary saved at ${SUMMARY_CSV}"
