# GACGE

This repository builds and runs the graph CPU/GPU evaluation experiments.

## Quick Start

Run these commands from the repository root.

### 0. Clone the repository

```bash
git clone --recursive git@github.com:victorliu-sq/Graph-Algorithm-CPU-GPU-Evaluation.git GACGE
cd GACGE
```

If you already cloned the repository without `--recursive`, or if you need to
pull later changes for the submodules, run:

```bash
make update
```

You can also run the equivalent git commands directly:

```bash
git pull --recurse-submodules
git submodule update --init --recursive --remote
```

### 1. Build the project

```bash
make build
```

This installs the required third-party dependencies and builds all configured
targets for X-Blossom-GPU, Ligra, and Gunrock.

### 2. Download and prepare datasets

```bash
make datasets
```

This downloads the datasets used by the experiments and generates the BFS
source lists.

### 3. Run experiments

To run every experiment:

```bash
make all
```

Individual experiment targets are listed in
[`make/README.md`](make/README.md).

## Command Reference

The Makefile target reference and AWS workflow details live in
[`make/README.md`](make/README.md).
