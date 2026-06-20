# RTTC Benchmark Suite Exclusion

RTTC is not a good fit for the core RT benchmark suite.

The paper result shows that RTTC is only competitive on the smallest triangle-counting dataset. On larger graph datasets, the RT-based method loses its advantage because most time is spent preparing ray-tracing work rather than using RT cores for traversal. In our run on `aws-t4`, the `compute_rays` phase dominates the total time, while the actual RT traversal phase, `count_triangles`, is comparatively small.

RTTC also has poor robustness for a portable benchmark suite. Larger datasets can fail with host memory allocation errors or GPU out-of-memory errors. In the `aws-t4` run, `SocLiveJournal` failed with `std::bad_alloc`, and `Orkut` failed with CUDA out-of-memory. This makes RTTC difficult to run consistently across machines with different CPU memory and GPU memory capacities.

Because the workload is only favorable on small datasets, does not strongly stress RT cores on those datasets, and becomes unstable or inefficient on larger datasets, RTTC should be excluded from the main RT benchmark suite. It can remain as an optional case study for graph triangle counting, but not as a representative benchmark for RT-core efficiency.

Current evidence:

- Paper coverage: RTTC corresponds mainly to Figure 8, where RT-2A1 is only clearly favorable on the smallest dataset.
- Local benchmark output: `expr/results/aws-t4/RTTC/rttc_result.csv`.
- Failure modes observed on `aws-t4`: `SocLiveJournal` failed with `std::bad_alloc`; `Orkut` failed with CUDA out-of-memory.
