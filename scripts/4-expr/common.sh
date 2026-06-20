#!/usr/bin/env bash

ANALYSIS_COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(cd "${ANALYSIS_COMMON_DIR}/../.." && pwd)}"
CONDA_ENV="${CONDA_ENV:-graph-env}"

XB_BIN_DIR="${PROJECT_DIR}/build/apps/xb/bin"
LIGRA_BFS_BIN="${PROJECT_DIR}/build/apps/ligra/bin/BFS"
LIGRA_BC_BIN="${PROJECT_DIR}/build/apps/ligra/bin/BC"
LIGRA_CC_BIN="${PROJECT_DIR}/build/apps/ligra/bin/Components"
LIGRA_SSSP_BIN="${PROJECT_DIR}/build/apps/ligra/bin/SSSP"
LIGRA_MULTISSSP_BIN="${PROJECT_DIR}/build/apps/ligra/bin/MultiSSSP"
LIGRA_BFS_THROUGHPUT_BIN="${PROJECT_DIR}/build/apps/ligra/bin/BFS_Throughput"
LIGRA_BC_THROUGHPUT_BIN="${PROJECT_DIR}/build/apps/ligra/bin/BC_Throughput"
LIGRA_SSSP_THROUGHPUT_BIN="${PROJECT_DIR}/build/apps/ligra/bin/SSSP_Throughput"
LIGRA_MULTISSSP_THROUGHPUT_BIN="${PROJECT_DIR}/build/apps/ligra/bin/MultiSSSP_Throughput"
GUNROCK_BFS_BIN="${PROJECT_DIR}/build/apps/gunrock/bin/bfs"
GUNROCK_BC_BIN="${PROJECT_DIR}/build/apps/gunrock/bin/bc"
GUNROCK_CC_BIN="${PROJECT_DIR}/build/apps/gunrock/bin/cc"
GUNROCK_SSSP_BIN="${PROJECT_DIR}/build/apps/gunrock/bin/sssp"
GUNROCK_MULTISSSP_BIN="${PROJECT_DIR}/build/apps/gunrock/bin/multi_sssp"
GUNROCK_BFS_THROUGHPUT_BIN="${PROJECT_DIR}/build/apps/gunrock/bin/bfs_throughput"
GUNROCK_BC_THROUGHPUT_BIN="${PROJECT_DIR}/build/apps/gunrock/bin/bc_throughput"
GUNROCK_SSSP_THROUGHPUT_BIN="${PROJECT_DIR}/build/apps/gunrock/bin/sssp_throughput"
GUNROCK_MULTISSSP_THROUGHPUT_BIN="${PROJECT_DIR}/build/apps/gunrock/bin/multi_sssp_throughput"

run_python() {
  conda run -n "$CONDA_ENV" python3 "$@"
}

run_ncu() {
  local ncu_bin="${NCU_BIN:-}"
  local timeout_secs="${NCU_TIMEOUT:-300}"
  if [[ -z "$ncu_bin" ]]; then
    ncu_bin="$(command -v ncu || true)"
  fi
  if [[ -z "$ncu_bin" ]]; then
    echo "ERROR: ncu not found. Set NCU_BIN to the Nsight Compute executable." >&2
    exit 1
  fi

  local cmd=("$ncu_bin" "$@")
  if [[ "${NCU_USE_SUDO:-1}" == "1" ]] && sudo -n true 2>/dev/null; then
    if command -v timeout >/dev/null 2>&1 && [[ "$timeout_secs" != "0" ]]; then
      sudo -n timeout --kill-after=10s "$timeout_secs" "$ncu_bin" "$@"
    else
      sudo -n "$ncu_bin" "$@"
    fi
    return
  fi

  if command -v timeout >/dev/null 2>&1 && [[ "$timeout_secs" != "0" ]]; then
    timeout --kill-after=10s "$timeout_secs" "${cmd[@]}"
  else
    "${cmd[@]}"
  fi
}

perf_llc_events() {
  if perf list 2>/dev/null | grep -q 'cpu_core/LLC-load-misses/'; then
    printf '%s\n' 'cpu_core/LLC-load-misses/,cpu_core/LLC-loads/'
  else
    printf '%s\n' 'LLC-load-misses,LLC-loads'
  fi
}

require_executable() {
  local path="$1"
  local label="$2"
  if [[ ! -x "$path" ]]; then
    echo "ERROR: ${label} not found or not executable: ${path}" >&2
    echo "Run 'make build' before running this script." >&2
    exit 1
  fi
}

require_file() {
  local path="$1"
  local label="$2"
  if [[ ! -f "$path" ]]; then
    echo "ERROR: ${label} not found: ${path}" >&2
    echo "Place the raw CSR datasets under data/xb, then run 'make process-datasets' before running this script." >&2
    exit 1
  fi
}

first_source_node() {
  local source
  source="$(source_nodes_from_file "$1" 1)"
  if [[ -z "$source" ]]; then
    echo "ERROR: no source nodes found in $1" >&2
    exit 1
  fi
  printf '%s\n' "$source"
}

source_nodes_from_file() {
  local path="$1"
  local limit="${2:-all}"

  awk -v limit="$limit" '
    /^[[:space:]]*#/ { next }
    {
      sub(/[[:space:]]*#.*/, "")
      for (i = 1; i <= NF; i++) {
        print $i
        count++
        if (limit != "all" && count >= limit) exit
      }
    }
  ' "$path"
}

all_source_nodes() {
  source_nodes_from_file "$1" all
}

source_nodes_csv() {
  local sources
  sources="$(source_nodes_from_file "$1" "${2:-all}" | paste -sd, -)"
  if [[ -z "$sources" ]]; then
    echo "ERROR: no source nodes found in $1" >&2
    exit 1
  fi
  printf '%s\n' "$sources"
}

percent_count() {
  local total="$1"
  local percent="${MULTISSSP_SOURCE_PERCENT:-5}"
  if ((total <= 0)); then
    echo "ERROR: invalid node count: $total" >&2
    exit 1
  fi

  awk -v total="$total" -v percent="$percent" '
    BEGIN {
      raw = total * percent / 100
      count = int(raw)
      if (raw > count) count++
      if (count < 1) count = 1
      if (count > total) count = total
      print count
    }
  '
}

run_xb_dataset() {
  local bin="$1"
  local dataset="$2"
  local rounds="$3"
  local row_offsets="$4"
  local col_indices="$5"
  local path_buffer_ratio="$6"

  "$bin" \
      --dataset="$dataset" \
      --rounds="$rounds" \
      --row_offsets="$row_offsets" \
      --col_indices="$col_indices" \
      --path_buffer_ratio="$path_buffer_ratio"
}

default_xb_pro_threads() {
  local cores_per_socket
  local sockets
  local physical_cores
  local xb_pro_threads

  # Read physical CPU topology directly instead of deriving it from logical CPUs.
  # On aws-cpu: Core(s) per socket = 48, Socket(s) = 1, so physical_cores = 48.
  cores_per_socket="$(lscpu 2>/dev/null | awk -F: '/^Core\(s\) per socket:/ { gsub(/[[:space:]]/, "", $2); print $2; exit }')"
  sockets="$(lscpu 2>/dev/null | awk -F: '/^Socket\(s\):/ { gsub(/[[:space:]]/, "", $2); print $2; exit }')"
  cores_per_socket="${cores_per_socket:-1}"
  sockets="${sockets:-1}"
  physical_cores=$((cores_per_socket * sockets))

  # Policy: use physical cores by default.
  # On aws-cpu this gives 48 XB-Pro worker threads.
  xb_pro_threads=$physical_cores
  if ((xb_pro_threads < 1)); then
    xb_pro_threads=1
  fi

  printf '%s\n' "${xb_pro_threads}"
}

XB_PRO_DATASET_THREADS=(
  "GPlus|16"
  "Twitch|16"
  "Amazon|16"
  "HiggsNets|48"
  "Youtube|48"
  "Hyperlink|48"
  "Wikipedia|48"
  "Stackoverflow|48"
  "Patent|48"
  "Livejournal|48"
)

xb_pro_threads_for_dataset() {
  local dataset="$1"
  local default_threads="${2:-$(default_xb_pro_threads)}"
  local entry thread_dataset thread_count
  for entry in "${XB_PRO_DATASET_THREADS[@]}"; do
    IFS='|' read -r thread_dataset thread_count <<< "$entry"
    if [[ "$thread_dataset" == "$dataset" ]]; then
      printf '%s\n' "$thread_count"
      return
    fi
  done
  printf '%s\n' "$default_threads"
}

selected_dataset() {
  local dataset="$1"
  local selected_datasets="${2:-}"
  [[ -z "$selected_datasets" || " ${selected_datasets} " == *" ${dataset} "* ]]
}

seed_csv_excluding_datasets() {
  local source_csv="$1"
  local dest_csv="$2"
  local excluded_datasets="$3"
  if [[ -n "$excluded_datasets" && -f "$source_csv" ]]; then
    awk -F, -v datasets="$excluded_datasets" '
      BEGIN {
        split(datasets, names, " ")
        for (idx in names) {
          excluded[names[idx]] = 1
        }
      }
      NR == 1 || !($1 in excluded)
    ' "$source_csv" > "$dest_csv"
  fi
}

profile_ncu_repeated() {
  local metric="$1"
  local timing_out="$2"
  local profiling_dir="$3"
  local profile_runs="$4"
  shift 4

  rm -rf "$profiling_dir"
  mkdir -p "$profiling_dir"

  local profile_run profile_id profiling_out
  for profile_run in $(seq 1 "$profile_runs"); do
    printf -v profile_id "%02d" "$profile_run"
    profiling_out="${profiling_dir}/profile_${profile_id}.csv"
    echo "Profile run ${profile_run}/${profile_runs}" | tee -a "$timing_out"
    "$@" | tee -a "$timing_out"
    run_ncu --metrics "$metric" --csv "$@" > "$profiling_out"
  done
}

DATASET_CSR_LIST=(
  "Wikipedia|${PROJECT_DIR}/data/xb/Wikipedia/wiki_rowOffsets.txt|${PROJECT_DIR}/data/xb/Wikipedia/wiki_colIndices.txt|19"
  "Youtube|${PROJECT_DIR}/data/xb/Youtube/youtube_rowOffsets.txt|${PROJECT_DIR}/data/xb/Youtube/youtube_colIndices.txt|20"
  "HiggsNets|${PROJECT_DIR}/data/xb/HiggsNets/higgsnets_rowOffsets.txt|${PROJECT_DIR}/data/xb/HiggsNets/higgsnets_colIndices.txt|1350"
  "Amazon|${PROJECT_DIR}/data/xb/Amazon/amazon_rowOffsets.txt|${PROJECT_DIR}/data/xb/Amazon/amazon_colIndices.txt|20"
  "GPlus|${PROJECT_DIR}/data/xb/Google/gplus_rowOffsets.txt|${PROJECT_DIR}/data/xb/Google/gplus_columnIndices.txt|20000"
  "Twitch|${PROJECT_DIR}/data/xb/Twitch/large_twitch_edges_rowOffsets.txt|${PROJECT_DIR}/data/xb/Twitch/large_twitch_edges_colIndices.txt|1200"
  "Stackoverflow|${PROJECT_DIR}/data/xb/StackOverflow/stackOverflow_rowOffsets.txt|${PROJECT_DIR}/data/xb/StackOverflow/stackOverflow_columnIndices.txt|87"
  "Hyperlink|${PROJECT_DIR}/data/xb/Hyperlink/hyperlink_rowOffsets.txt|${PROJECT_DIR}/data/xb/Hyperlink/hyperlink_colIndices.txt|420"
  "Livejournal|${PROJECT_DIR}/data/xb/LiveJournal/livejournal_rowOffsets.txt|${PROJECT_DIR}/data/xb/LiveJournal/livejournal_colIndices.txt|80"
  "Patent|${PROJECT_DIR}/data/xb/Patent/Patents_rowOffsets.txt|${PROJECT_DIR}/data/xb/Patent/Patents_colIndices.txt|120"
)

DATASET_XB_SCALABILITY_LIST=(
  "Livejournal|${PROJECT_DIR}/data/xb/LiveJournal/livejournal_rowOffsets.txt|${PROJECT_DIR}/data/xb/LiveJournal/livejournal_colIndices.txt|80"
  "Stackoverflow|${PROJECT_DIR}/data/xb/StackOverflow/stackOverflow_rowOffsets.txt|${PROJECT_DIR}/data/xb/StackOverflow/stackOverflow_columnIndices.txt|87"
  "Patent|${PROJECT_DIR}/data/xb/Patent/Patents_rowOffsets.txt|${PROJECT_DIR}/data/xb/Patent/Patents_colIndices.txt|120"
)

DATASET_BFS_LIST=(
  "GPlus|${PROJECT_DIR}/data/ligra/Google/gplus_adj.txt|${PROJECT_DIR}/data/gunrock/Google/gplus.mtx|${PROJECT_DIR}/data/src_nodes/GPlus_src_nodes.txt"
  "Amazon|${PROJECT_DIR}/data/ligra/Amazon/amazon_adj.txt|${PROJECT_DIR}/data/gunrock/Amazon/amazon.mtx|${PROJECT_DIR}/data/src_nodes/Amazon_src_nodes.txt"
  "HiggsNets|${PROJECT_DIR}/data/ligra/HiggsNets/higgsnets_adj.txt|${PROJECT_DIR}/data/gunrock/HiggsNets/higgsnets.mtx|${PROJECT_DIR}/data/src_nodes/HiggsNets_src_nodes.txt"
  "Hyperlink|${PROJECT_DIR}/data/ligra/Hyperlink/hyperlink_adj.txt|${PROJECT_DIR}/data/gunrock/Hyperlink/hyperlink.mtx|${PROJECT_DIR}/data/src_nodes/Hyperlink_src_nodes.txt"
  "Livejournal|${PROJECT_DIR}/data/ligra/LiveJournal/livejournal_adj.txt|${PROJECT_DIR}/data/gunrock/LiveJournal/livejournal.mtx|${PROJECT_DIR}/data/src_nodes/LiveJournal_src_nodes.txt"
  "Patent|${PROJECT_DIR}/data/ligra/Patent/patents_adj.txt|${PROJECT_DIR}/data/gunrock/Patent/patents.mtx|${PROJECT_DIR}/data/src_nodes/Patent_src_nodes.txt"
  "Stackoverflow|${PROJECT_DIR}/data/ligra/StackOverflow/stackoverflow_adj.txt|${PROJECT_DIR}/data/gunrock/StackOverflow/stackoverflow.mtx|${PROJECT_DIR}/data/src_nodes/StackOverflow_src_nodes.txt"
  "Twitch|${PROJECT_DIR}/data/ligra/Twitch/twitch_adj.txt|${PROJECT_DIR}/data/gunrock/Twitch/twitch.mtx|${PROJECT_DIR}/data/src_nodes/Twitch_src_nodes.txt"
  "Wikipedia|${PROJECT_DIR}/data/ligra/Wikipedia/wiki_adj.txt|${PROJECT_DIR}/data/gunrock/Wikipedia/wiki.mtx|${PROJECT_DIR}/data/src_nodes/Wikipedia_src_nodes.txt"
  "Youtube|${PROJECT_DIR}/data/ligra/Youtube/youtube_adj.txt|${PROJECT_DIR}/data/gunrock/Youtube/youtube.mtx|${PROJECT_DIR}/data/src_nodes/Youtube_src_nodes.txt"
)

DATASET_SSSP_LIST=(
  "GPlus|${PROJECT_DIR}/data/ligra_w/Google/gplus_adj.txt|${PROJECT_DIR}/data/gunrock_w/Google/gplus.mtx|${PROJECT_DIR}/data/src_nodes/GPlus_src_nodes.txt"
  "Amazon|${PROJECT_DIR}/data/ligra_w/Amazon/amazon_adj.txt|${PROJECT_DIR}/data/gunrock_w/Amazon/amazon.mtx|${PROJECT_DIR}/data/src_nodes/Amazon_src_nodes.txt"
  "HiggsNets|${PROJECT_DIR}/data/ligra_w/HiggsNets/higgsnets_adj.txt|${PROJECT_DIR}/data/gunrock_w/HiggsNets/higgsnets.mtx|${PROJECT_DIR}/data/src_nodes/HiggsNets_src_nodes.txt"
  "Hyperlink|${PROJECT_DIR}/data/ligra_w/Hyperlink/hyperlink_adj.txt|${PROJECT_DIR}/data/gunrock_w/Hyperlink/hyperlink.mtx|${PROJECT_DIR}/data/src_nodes/Hyperlink_src_nodes.txt"
  "Livejournal|${PROJECT_DIR}/data/ligra_w/LiveJournal/livejournal_adj.txt|${PROJECT_DIR}/data/gunrock_w/LiveJournal/livejournal.mtx|${PROJECT_DIR}/data/src_nodes/LiveJournal_src_nodes.txt"
  "Patent|${PROJECT_DIR}/data/ligra_w/Patent/patents_adj.txt|${PROJECT_DIR}/data/gunrock_w/Patent/patents.mtx|${PROJECT_DIR}/data/src_nodes/Patent_src_nodes.txt"
  "Stackoverflow|${PROJECT_DIR}/data/ligra_w/StackOverflow/stackoverflow_adj.txt|${PROJECT_DIR}/data/gunrock_w/StackOverflow/stackoverflow.mtx|${PROJECT_DIR}/data/src_nodes/StackOverflow_src_nodes.txt"
  "Twitch|${PROJECT_DIR}/data/ligra_w/Twitch/twitch_adj.txt|${PROJECT_DIR}/data/gunrock_w/Twitch/twitch.mtx|${PROJECT_DIR}/data/src_nodes/Twitch_src_nodes.txt"
  "Wikipedia|${PROJECT_DIR}/data/ligra_w/Wikipedia/wiki_adj.txt|${PROJECT_DIR}/data/gunrock_w/Wikipedia/wiki.mtx|${PROJECT_DIR}/data/src_nodes/Wikipedia_src_nodes.txt"
  "Youtube|${PROJECT_DIR}/data/ligra_w/Youtube/youtube_adj.txt|${PROJECT_DIR}/data/gunrock_w/Youtube/youtube.mtx|${PROJECT_DIR}/data/src_nodes/Youtube_src_nodes.txt"
)

DATASET_NODE_COUNT_LIST=(
  "GPlus|107615"
  "Amazon|334864"
  "HiggsNets|456627"
  "Hyperlink|1791490"
  "Livejournal|4847572"
  "Patent|3774769"
  "Stackoverflow|2601978"
  "Twitch|168115"
  "Wikipedia|2394386"
  "Youtube|1134891"
)

DATASET_MULTISSSP_LIST=(
  "GPlus|${PROJECT_DIR}/data/ligra_w/Google/gplus_adj.txt|${PROJECT_DIR}/data/gunrock_w/Google/gplus.mtx|${PROJECT_DIR}/data/src_nodes/GPlus_src_nodes.txt|107615|5381"
  "Amazon|${PROJECT_DIR}/data/ligra_w/Amazon/amazon_adj.txt|${PROJECT_DIR}/data/gunrock_w/Amazon/amazon.mtx|${PROJECT_DIR}/data/src_nodes/Amazon_src_nodes.txt|334864|16744"
  "HiggsNets|${PROJECT_DIR}/data/ligra_w/HiggsNets/higgsnets_adj.txt|${PROJECT_DIR}/data/gunrock_w/HiggsNets/higgsnets.mtx|${PROJECT_DIR}/data/src_nodes/HiggsNets_src_nodes.txt|456627|22832"
  "Hyperlink|${PROJECT_DIR}/data/ligra_w/Hyperlink/hyperlink_adj.txt|${PROJECT_DIR}/data/gunrock_w/Hyperlink/hyperlink.mtx|${PROJECT_DIR}/data/src_nodes/Hyperlink_src_nodes.txt|1791490|89575"
  "Livejournal|${PROJECT_DIR}/data/ligra_w/LiveJournal/livejournal_adj.txt|${PROJECT_DIR}/data/gunrock_w/LiveJournal/livejournal.mtx|${PROJECT_DIR}/data/src_nodes/LiveJournal_src_nodes.txt|4847572|242379"
  "Patent|${PROJECT_DIR}/data/ligra_w/Patent/patents_adj.txt|${PROJECT_DIR}/data/gunrock_w/Patent/patents.mtx|${PROJECT_DIR}/data/src_nodes/Patent_src_nodes.txt|3774769|188739"
  "Stackoverflow|${PROJECT_DIR}/data/ligra_w/StackOverflow/stackoverflow_adj.txt|${PROJECT_DIR}/data/gunrock_w/StackOverflow/stackoverflow.mtx|${PROJECT_DIR}/data/src_nodes/StackOverflow_src_nodes.txt|2601978|130099"
  "Twitch|${PROJECT_DIR}/data/ligra_w/Twitch/twitch_adj.txt|${PROJECT_DIR}/data/gunrock_w/Twitch/twitch.mtx|${PROJECT_DIR}/data/src_nodes/Twitch_src_nodes.txt|168115|8406"
  "Wikipedia|${PROJECT_DIR}/data/ligra_w/Wikipedia/wiki_adj.txt|${PROJECT_DIR}/data/gunrock_w/Wikipedia/wiki.mtx|${PROJECT_DIR}/data/src_nodes/Wikipedia_src_nodes.txt|2394386|119720"
  "Youtube|${PROJECT_DIR}/data/ligra_w/Youtube/youtube_adj.txt|${PROJECT_DIR}/data/gunrock_w/Youtube/youtube.mtx|${PROJECT_DIR}/data/src_nodes/Youtube_src_nodes.txt|1134891|56745"
)
