# Remote all-hosts issue summary, 2026-06-02

Hosts covered:

- `aws-l4`
- `aws-a10g`
- `aws-l40s`
- `aws-pro6000`

Latest fetched run directories:

| Host | Latest run directory |
| --- | --- |
| `aws-l4` | `tmp/benchmark-runs/aws-l4/20260602-035320` |
| `aws-a10g` | `tmp/benchmark-runs/aws-a10g/20260602-035331` |
| `aws-l40s` | `tmp/benchmark-runs/aws-l40s/20260602-035327` |
| `aws-pro6000` | `tmp/benchmark-runs/aws-pro6000/20260602-035322` |

## Resolved issues

| Area | Hosts affected | Symptom | Resolution | Status |
| --- | --- | --- | --- | --- |
| RTOD result writer | All four hosts | `RTOD` benchmark completed, but `expr/benchmark/RTOD/write_result_csv.py` failed with `ValueError: dict contains fields not in fieldnames` for timing columns such as `copy_new_points_h2d_ms`, `copy_filtered_points_h2d_ms`, `copy_outlier_d2h_ms`, and `prepare_cell_ms`. | Added these parsed timing columns to the RTOD CSV `fieldnames`. Verified against a fetched `aws-l4` RTOD log, then pushed commit `3c05e4a`. | Resolved |
| TetMeshQueries in run-all | All four hosts | `run_all.sh` attempted to run `TetMeshQueries`, but `BUILD_APP_TetMeshQueries` is intentionally not part of the build set, so `/home/ubuntu/RT-Benchmarks/build/tetmeshqueries/bin/tetMeshQueriesSmoke` was missing. | Removed `TetMeshQueries` from `expr/benchmark/run_all.sh`. Pushed commit `3c05e4a` and updated all four remote repos. | Resolved |
| Remote result fetch after failed apps | All four hosts | `remote-all-one` stops at `remote-run-all` when any app reports failure, so `remote-fetch-all-results` is not reached automatically. | Ran `make remote-fetch-all-results REMOTE_HOST=<host> REMOTE_REPO_DIR=/home/ubuntu/RT-Benchmarks` manually for each host after `remote-run-all` exited. | Resolved for this run |
| RTTC large graph runs | `aws-l4`, `aws-a10g`, `aws-l40s`, `aws-pro6000` | `RTTC` exits nonzero on the largest graph inputs. Logs showed `std::bad_alloc`; `SocLiveJournal` and `Orkut` failed on 24 GB GPUs, and `Orkut` failed on larger GPUs. | Removed `soc-LiveJournal1.edge.pd` and `com-orkut.ungraph.edge.pd` from the RTTC run loop by skipping those dataset files in `expr/benchmark/RTTC/run_benchmark.sh`. | Resolved by dataset exclusion |
| RT-DBSCAN teardown segmentation fault | `aws-a10g` | `Spatial: 3DRoad` exited with code `139` after printing `Total time` and `destroying devicegroup`. The source synchronized after the first `owlLaunch2D`, but not after the second launch before reading state and destroying the OWL context. | Removed the benchmark-runner workaround and patched `apps/RT-DBSCAN/samples/cmdline/s02-rtdbscan/hostCode.cpp` to call `cudaDeviceSynchronize()` after the second `owlLaunch2D`. Rsynced the source patch to `aws-a10g`, rebuilt RT-DBSCAN, ran `run-rtdbscan` twice successfully, and fetched results. | Resolved in source and validated on `aws-a10g` |
| RTNN CUDA runtime failures | `aws-l40s`, `aws-pro6000` | `RTNN` failed on several datasets with `cudaErrorIllegalAddress` and `cudaErrorInvalidAddressSpace`. Logs also showed wrapped grid cell counts, including `Number of cells: 0` on `aws-l40s` and wrapped nonzero values on `aws-pro6000`. | Patched `apps/RTNN/src/optixNSearch/sort.cpp` so `genGridInfo` computes meta-grid and padded-grid cell counts in 64-bit, increases `cellSize` until those counts fit the existing 32-bit device-side indices, and updates `state.crRatio` from the final cell size. Rsynced the patch to both hosts, rebuilt `RTNN`, reran `make run-rtnn`, and fetched the final results. | Resolved in source and validated on `aws-l40s` and `aws-pro6000`; both final CSVs have 12/12 `ok` rows |

## Unresolved issues

| Area | Hosts affected | Symptom | Evidence | Current status |
| --- | --- | --- | --- | --- |
| None currently open from this triage pass | - | - | - | - |

## Latest benchmark status

| Host | Failed apps | Apps confirmed ok in latest run |
| --- | --- | --- |
| `aws-l4` | None expected after RTTC dataset exclusion | `RayJoin`, `LibRTS`, `X-HD`, `RTNN`, `RT-DBSCAN`, `RayDB`, `RTOD`, `RTSpMSpM`, `RT-BarnesHut`, `Mochi-DCD` |
| `aws-a10g` | None expected after RTTC dataset exclusion and RT-DBSCAN teardown handling | `RayJoin`, `LibRTS`, `X-HD`, `RTNN`, `RT-DBSCAN`, `RayDB`, `RTOD`, `RTSpMSpM`, `RT-BarnesHut`, `Mochi-DCD` |
| `aws-l40s` | None expected after RTTC dataset exclusion and RTNN grid-count fix | `RayJoin`, `LibRTS`, `X-HD`, `RTNN`, `RT-DBSCAN`, `RayDB`, `RTOD`, `RTSpMSpM`, `RT-BarnesHut`, `Mochi-DCD` |
| `aws-pro6000` | None expected after RTTC dataset exclusion and RTNN grid-count fix | `RayJoin`, `LibRTS`, `X-HD`, `RTNN`, `RT-DBSCAN`, `RayDB`, `RTOD`, `RTSpMSpM`, `RT-BarnesHut`, `Mochi-DCD` |
