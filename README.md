# X-Blossom SIGMETRICS27 Artifact

This repository contains the source code, build targets, dataset processing scripts,
and experiment drivers for the SIGMETRICS27 X-Blossom artifact.

The repository intentionally does not include dataset download scripts. The original
graphs are public datasets and should be downloaded from their source websites. The
conversion and preprocessing scripts used by the experiments are included.

## Hardware Requirements

- NVIDIA GPU with CUDA support.
- Multi-core CPU with at least 32 hardware threads for the CPU experiments.
- At least 24 GB of host memory and 24 GB of GPU memory for the full evaluation.
- Enough local storage for the raw and converted graph datasets.

CPU profiling scripts use `perf` events that were validated on Intel CPUs. Some
events may need adjustment on other CPU vendors or microarchitectures.

## Software Requirements

Install these tools before building or running the artifact:

- bash
- git
- CMake 3.25 or newer
- GCC 13 or newer
- CUDA 12.8 or newer
- Conda with Python 3.11
- Linux `perf`
- NVIDIA Nsight Compute (`ncu`)

The Python environment is created by the dependency scripts. The required Python
packages are listed under `scripts/1-deps/xb/install/requirements.txt`.

## Repository Layout

- `apps/xb`: X-Blossom CPU and GPU implementations.
- `apps/ligra`: Ligra-based CPU traversal baselines.
- `apps/gunrock`: Gunrock-based GPU traversal baselines.
- `scripts/1-deps`: dependency setup scripts.
- `scripts/2-datasets`: dataset conversion and source-node generation scripts.
- `scripts/3-build`: build scripts.
- `scripts/4-expr`: local experiment and analysis scripts.
- `make`: Makefile fragments for common workflows.

## Build

From the repository root:

```bash
make deps
make build
```

`make build` builds the X-Blossom, Ligra, and Gunrock targets used by the
experiment scripts.

## Datasets

Download raw graph datasets directly from public graph repositories such as:

- SNAP: https://snap.stanford.edu/data/
- Network Repository: https://networkrepository.com/
- SuiteSparse Matrix Collection: https://sparse.tamu.edu/
- KONECT: https://konect.cc/networks/
- LAW WebGraph datasets: https://law.di.unimi.it/datasets.php

The experiment scripts expect CSR text files under `data/xb` with the following
layout:

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

After placing the CSR files, run:

```bash
make process-datasets
```

This generates:

- Ligra adjacency inputs under `data/ligra`, `data/ligra_w`, and
  `data/ligra_hyper_w`.
- Gunrock Matrix Market inputs under `data/gunrock` and `data/gunrock_w`.
- BFS/SSSP source-node lists under `data/src_nodes`.

## Experiments

Run all configured local experiments:

```bash
make all
```

Individual experiment targets are documented in `make/README.md`. Most scripts
write intermediate logs to `tmp/` and final tables/plots or CSV summaries to
`results/`.

## Notes

- Dataset download scripts are deliberately omitted to avoid bundling private
  storage links. Only processing scripts are included.
- If a public dataset uses a different raw format, convert it to the CSR
  `rowOffsets` and `colIndices` text files shown above before running
  `make process-datasets`.
