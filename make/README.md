# Local Make Targets

The root `Makefile` includes local-only targets from:

- `make/1-deps.mk`
- `make/2-datasets.mk`
- `make/3-build.mk`
- `make/4-expr-local.mk`
- `make/0-utils.mk`

## Setup

| Target | Description |
| --- | --- |
| `make deps` | Install CPU and GPU dependencies. |
| `make deps-cpu` | Install CPU dependencies. |
| `make deps-gpu` | Install GPU dependencies. |
| `make process-datasets` | Convert staged CSR datasets and generate source-node lists. |
| `make build` | Build all local targets. |
| `make build-cpu` | Build CPU targets. |
| `make build-gpu` | Build GPU targets. |
| `make clean` | Remove build output and dependency checkouts. |
| `make prepare_logs` | Create `tmp/logs` and `results`. |

## Experiments

Each experiment target runs locally and depends on `build`, `process-datasets`,
and `prepare_logs`.

| Target | Description |
| --- | --- |
| `make all` | Run all local experiments. |
| `make 1_graph_metrics` | Graph metrics and Table 1 outputs. |
| `make 2_reuse` | Reuse experiments. |
| `make 3_load_balance` | CPU/GPU load-balance experiments. |
| `make 4_xb_pro_inst` | XB-Pro instruction experiments. |
| `make 5_runtime_four_bbss` | MultiSSSP runtime experiments. |
| `make 6_inst_rate_four_bbss` | MultiSSSP instruction-rate experiments. |
| `make 7_memory_four_bbss` | MultiSSSP memory experiments. |
| `make 8_scalability_test` | Scalability experiments. |

Use `make -n <target>` to preview commands without running them.
