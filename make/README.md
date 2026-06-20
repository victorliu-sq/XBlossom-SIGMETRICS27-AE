# Makefile Target Reference

The root `Makefile` includes the target definitions from this directory:

```make
include make/1-deps.mk
include make/2-datasets.mk
include make/3-build.mk
include make/4-expr-local.mk
include make/4-expr-remote.mk
include make/0-sync.mk
```

`make/4-expr-local.mk` runs local experiments. `make/4-expr-remote.mk`
runs the same experiment workflows on `aws-cpu` and/or `aws-gpu`, fetches
remote `results/<expr>/` and `tmp/<expr>/` with `rsync`, then runs the
local final plot/table generation step when the local workflow has one.

## File Layout

| File | Purpose |
| --- | --- |
| `make/1-deps.mk` | Install local and remote dependencies. |
| `make/2-datasets.mk` | Download local and remote datasets. |
| `make/3-build.mk` | Build local and remote binaries. |
| `make/4-expr-local.mk` | Local experiment runs. |
| `make/4-expr-remote.mk` | Unified remote experiment orchestration and result fetch. |
| `make/0-sync.mk` | Cleanup, update, log preparation, and remote sync targets. |

## Common Targets

| Target | Description |
| --- | --- |
| `make` or `make all` | Run all local experiment analyses. |
| `make deps` | Install all dependencies. |
| `make deps-cpu` | Install CPU dependencies. |
| `make deps-gpu` | Install GPU dependencies. |
| `make datasets` | Download all datasets and generate source-node lists. |
| `make datasets-ligra-w` | Download only Ligra weighted datasets. |
| `make build` | Install dependencies and build all local targets. |
| `make build-cpu` | Install CPU dependencies and build CPU targets. |
| `make build-gpu` | Install GPU dependencies and build GPU targets. |
| `make clean` | Remove build output and dependency checkouts. |
| `make update` | Pull the main repo and update submodules. |
| `make prepare_logs` | Create `tmp/logs` and `results`. |

## Local Experiment Targets

Each local experiment target depends on `build`, `datasets`, and `prepare_logs`.

| Target | Description |
| --- | --- |
| `make 1_graph_metrics` | Run graph metrics and generate Table 1 CSV/LaTeX outputs. |
| `make 2_reuse` | Run XB/XB-Pro and XB++ reuse scripts. |
| `make 3_load_balance` | Run CPU and GPU load-balance scripts. |
| `make 4_xb_pro_inst` | Run XB-Pro node/edge instruction scripts and Figure 7 plotting. |
| `make 5_runtime` | Run runtime measurements and Figure 6 plotting. |
| `make 6_inst_rate` | Run instruction-rate measurements and Table 5 generation. |
| `make 7_memory` | Run memory measurements and Table 6 generation. |
| `make 8_runtime_four` | Run four-algorithm runtime measurements and Figure 8 plotting. |
| `make 9_inst_rate_four` | Run four-algorithm instruction-rate measurements and Table 9 generation. |
| `make 10_memory_four` | Run four-algorithm memory measurements and Table 10 generation. |
| `make 11_throughput` | Run traversal throughput measurements and Table 11 generation. |
| `make 12_runtime_four_bbss` | Run four-algorithm runtime measurements with MultiSSSP replacing BC and Figure 12 plotting. |
| `make 13_inst_rate_four_bbss` | Run four-algorithm instruction-rate measurements with MultiSSSP replacing BC and Table 13 generation. |
| `make 14_memory_four_bbss` | Run four-algorithm memory measurements with MultiSSSP replacing BC and Table 14 generation. |
| `make 15_throughput_bbss` | Run traversal throughput measurements with MultiSSSP replacing BC and Table 15 generation. |

## Remote Workflow Targets

| Target | Description |
| --- | --- |
| `make remote-all` | Run all unified remote experiment workflows. |
| `make remote-1_graph_metrics` | Run graph metrics on `aws-gpu`, fetch results/tmp, then generate Table 1 CSV/LaTeX outputs locally. |
| `make remote-2_reuse` | Run CPU reuse work on `aws-cpu`, GPU reuse work on `aws-gpu`, then fetch results/tmp. |
| `make remote-3_load_balance` | Run CPU/GPU load-balance work on the matching host, then fetch results/tmp. |
| `make remote-4_xb_pro_inst` | Run XB-Pro instruction work on `aws-cpu`, fetch results/tmp, then generate Figure 7 locally. |
| `make remote-5_runtime` | Run remote runtime parts, fetch results/tmp, then generate Figure 6 locally. |
| `make remote-6_inst_rate` | Run remote instruction-rate parts, fetch results/tmp, then generate Table 5 locally. |
| `make remote-7_memory` | Run remote memory parts, fetch results/tmp, then generate Table 6 locally. |
| `make remote-8_runtime_four` | Run remote four-algorithm runtime parts, fetch results/tmp, then generate Figure 8 locally. |
| `make remote-9_inst_rate_four` | Run remote four-algorithm instruction parts, fetch results/tmp, then generate Table 9 locally. |
| `make remote-10_memory_four` | Run remote four-algorithm memory parts, fetch results/tmp, then generate Table 10 locally. |
| `make remote-11_throughput` | Run remote throughput parts, fetch results/tmp, then generate Table 11 locally. |
| `make remote-12_runtime_four_bbss` | Run remote four-algorithm runtime parts with MultiSSSP replacing BC, fetch results/tmp, then generate Figure 12 locally. |
| `make remote-13_inst_rate_four_bbss` | Run remote four-algorithm instruction parts with MultiSSSP replacing BC, fetch results/tmp, then generate Table 13 locally. |
| `make remote-14_memory_four_bbss` | Run remote four-algorithm memory parts with MultiSSSP replacing BC, fetch results/tmp, then generate Table 14 locally. |
| `make remote-15_throughput_bbss` | Run remote throughput parts with MultiSSSP replacing BC, fetch results/tmp, then generate Table 15 locally. |
| `make remote-perf-list` | Fetch the remote CPU perf event list. |
| `make remote-gpu-counters` | Fetch remote GPU counter information. |

Remote host variables can be overridden, for example:

```bash
make remote-5_runtime REMOTE_CPU_HOST=my-cpu REMOTE_GPU_HOST=my-gpu REMOTE_REPO_DIR=/path/to/GACGE
```

## Remote Setup Targets

| Target | Description |
| --- | --- |
| `make remote-update` | Update the configured remote repo. |
| `make remote-upate` | Backward-compatible alias for `make remote-update`. |
| `make remote-deps-cpu` | Install CPU dependencies on `aws-cpu`. |
| `make remote-deps-gpu` | Install GPU dependencies on `aws-gpu`. |
| `make remote-build` | Build all configured remote targets on `aws-gpu`. |
| `make remote-build-cpu` | Build CPU targets on `aws-cpu`. |
| `make remote-build-gpu` | Build GPU targets on `aws-gpu`. |
| `make remote-datasets-cpu` | Download datasets on `aws-cpu`. |
| `make remote-datasets-gpu` | Download datasets on `aws-gpu`. |
| `make remote-datasets-ligra-w-cpu` | Download Ligra weighted datasets on `aws-cpu`. |

## Notes

Use `make -n <target>` to preview commands without running them. This is useful
for remote targets because they can install dependencies, build code, download
datasets, and start long experiment runs.
