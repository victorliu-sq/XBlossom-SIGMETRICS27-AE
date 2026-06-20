# X-Blossom SIGMETRICS27 Artifact

This artifact contains the X-Blossom source code, local build targets, dataset
processing scripts, and local experiment targets. It does not include dataset
download scripts.

## Requirements

- Linux with `bash`, `git`, CMake 3.25+, GCC 13+, and Conda with Python 3.11.
- CUDA 12.8+ and an NVIDIA GPU for GPU targets.
- Linux `perf` and NVIDIA Nsight Compute (`ncu`) for profiling targets.

## Dataset Setup

Download raw graph datasets from public sources such as SNAP, Network
Repository, SuiteSparse, KONECT, or LAW WebGraph. Convert each graph to CSR text
files and place them under `data/xb`:

```text
data/xb/
  Amazon/amazon_rowOffsets.txt
  Amazon/amazon_colIndices.txt
  Google/gplus_rowOffsets.txt
  Google/gplus_columnIndices.txt
  HiggsNets/higgsnets_rowOffsets.txt
  HiggsNets/higgsnets_colIndices.txt
  Hyperlink/hyperlink_rowOffsets.txt
  Hyperlink/hyperlink_colIndices.txt
  LiveJournal/livejournal_rowOffsets.txt
  LiveJournal/livejournal_colIndices.txt
  Patent/Patents_rowOffsets.txt
  Patent/Patents_colIndices.txt
  StackOverflow/stackOverflow_rowOffsets.txt
  StackOverflow/stackOverflow_columnIndices.txt
  Twitch/large_twitch_edges_rowOffsets.txt
  Twitch/large_twitch_edges_colIndices.txt
  Wikipedia/wiki_rowOffsets.txt
  Wikipedia/wiki_colIndices.txt
  Youtube/youtube_rowOffsets.txt
  Youtube/youtube_colIndices.txt
```

Then generate the derived inputs used by Ligra, Gunrock, and source-node runs:

```bash
make process-datasets
```

## Build

```bash
make deps
make build
```

Use `make deps-cpu && make build-cpu` or `make deps-gpu && make build-gpu` for
CPU-only or GPU-only setup.

## Local Experiment Targets

Run all local experiments:

```bash
make all
```

Run one target at a time:

```bash
make 1_graph_metrics
make 2_reuse
make 3_load_balance
make 4_xb_pro_inst
make 5_runtime_four_bbss
make 6_inst_rate_four_bbss
make 7_memory_four_bbss
make 8_scalability_test
```

Logs and generated outputs are written under `tmp/` and `results/`.
