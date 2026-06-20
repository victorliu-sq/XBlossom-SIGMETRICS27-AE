# Makefile Organization

The repository root `Makefile` is kept as a small entry point. It sets the
default target and includes the target groups from `make/`.

```make
.PHONY: all
.DEFAULT_GOAL := all

include make/deps.mk
include make/datasets.mk
include make/build.mk
include make/expr_all.mk
include make/clean.mk
```

This makes `make` and `make all` behave the same as before, while keeping each
category of commands in a smaller file.

## Top-Level Make Files

| File | Contents |
| --- | --- |
| `make/deps.mk` | Dependency installation targets, including CPU/GPU remote dependency setup. |
| `make/datasets.mk` | Dataset download targets, including CPU/GPU remote dataset setup. |
| `make/build.mk` | Local build targets and remote CPU/GPU build targets. |
| `make/expr_all.mk` | Experiment include index. It does not define the experiment targets directly. |
| `make/clean.mk` | Cleanup targets such as `clean`, `clean_build`, and `clean_deps`. |
| `make/README.md` | Human-readable target reference and workflow notes. |

## Experiment Make Files

Experiment targets are split under `make/expr/`.

```make
include make/expr/expr_local.mk
include make/expr/expr_remote_cpu.mk
include make/expr/expr_remote_gpu.mk
```

| File | Contents |
| --- | --- |
| `make/expr/expr_local.mk` | Local experiment targets, merge targets, shared update helpers, and `remote-all`. |
| `make/expr/expr_remote_cpu.mk` | CPU remote workflow targets and `login-cpu`. |
| `make/expr/expr_remote_gpu.mk` | GPU remote workflow targets and `login-gpu`. |

## Target Groups

Local experiment targets:

```bash
make all
make 1_graph_metrics
make 2_reuse
make 3_load_balance
make 4_runtime
make 5_inst_rate
make 6_xb_pro_inst
make 7_memory
make 8_runtime_four
make 9_inst_rate_four
make 10_memory_four
make 11_throughput
```

Remote CPU experiment targets live in `make/expr/expr_remote_cpu.mk` and use the
`remote-cpu-` prefix:

```bash
make remote-all-cpu
make remote-cpu-1_graph_metrics
make remote-cpu-2_reuse
make remote-cpu-3_load_balance
make remote-cpu-4_runtime
make remote-cpu-5_inst_rate
make remote-cpu-6_xb_pro_inst
make remote-cpu-7_memory
make remote-cpu-8_runtime_four
make remote-cpu-9_inst_rate_four
make remote-cpu-10_memory_four
make remote-cpu-11_throughput
```

Remote GPU experiment targets live in `make/expr/expr_remote_gpu.mk` and use the
`remote-gpu-` prefix:

```bash
make remote-all-gpu
make remote-gpu-1_graph_metrics
make remote-gpu-2_reuse
make remote-gpu-3_load_balance
make remote-gpu-4_runtime
make remote-gpu-5_inst_rate
make remote-gpu-6_xb_pro_inst
make remote-gpu-7_memory
make remote-gpu-8_runtime_four
make remote-gpu-9_inst_rate_four
make remote-gpu-10_memory_four
make remote-gpu-11_throughput
```

Merge targets live in `make/expr/expr_local.mk` because they run locally after
remote CPU/GPU results have been fetched:

```bash
make remote-merge-cpu-gpu
make remote-merge-1_graph_metrics
make remote-merge-2_reuse
make remote-merge-3_load_balance
make remote-merge-4_runtime
make remote-merge-5_inst_rate
make remote-merge-6_xb_pro_inst
make remote-merge-7_memory
make remote-merge-8_runtime_four
make remote-merge-9_inst_rate_four
make remote-merge-10_memory_four
make remote-merge-11_throughput
```

## Rule of Thumb

When adding a new target:

- Put dependency installation in `make/deps.mk`.
- Put dataset download/preparation in `make/datasets.mk`.
- Put build commands in `make/build.mk`.
- Put local experiment execution or merge commands in `make/expr/expr_local.mk`.
- Put AWS CPU experiment commands in `make/expr/expr_remote_cpu.mk`.
- Put AWS GPU experiment commands in `make/expr/expr_remote_gpu.mk`.
- Update `make/README.md` if the target is user-facing.

Use `make -n <target>` to preview a target without running its commands.
