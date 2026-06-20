# X-HD Paper Figure Coverage

`expr/benchmark/X-HD/run_benchmark.sh` currently runs a narrow geospatial-only X-HD benchmark. It does not yet cover the full Figure 5 evaluation from the X-HD paper.

## Figure 5 Coverage

The paper's Figure 5 compares overall Hausdorff Distance performance across three dataset categories:

- Figure 5(a): BraTS MRI datasets
- Figure 5(b): Geospatial datasets
- Figure 5(c): Graphics datasets

For this benchmark suite, Figure 5(b) and Figure 5(c) are the better targets. They cover geospatial and graphics inputs, stress the RT-core path with larger and more compute-intensive workloads, and are more useful for comparing RT-based acceleration behavior.

Figure 5(a) can be excluded from the default benchmark. In the paper it is a runtime distribution over randomly sampled BraTS image pairs, not a single workload selected by an input percentage. A single BraTS pair is therefore not representative of the figure, and the reported X-HD runtimes are very small, with even the slowest cases under roughly 1 ms. That makes BraTS a weak benchmark candidate for stressing RT-core computation resources in this project.

## Current Coverage

The current script only runs geospatial WKT pairs with:

- `variant=rt`
- `execution=gpu`
- `input_type=wkt`
- `n_dims=2`

This is closest to Figure 5(b), but it is still incomplete because it does not run the exact full geospatial set from the paper and does not include baseline methods.

## Missing Coverage

The benchmark still needs:

- Graphics runs for Figure 5(c), using PLY model pairs such as Dragon, Asian Dragon, Buddha, and Thai Statuette.
- Full geospatial pairs for Figure 5(b), including USCounty-USZipcode, USWater-USCensus, and OSMLakes-OSMParks.
- Baseline methods if the goal is to reproduce the full paper figure, not just the X-HD data points.

The immediate target for benchmark coverage should be to add one clear workflow for Figure 5(b) and Figure 5(c), with results separated by dataset category. BraTS can be revisited only if we later need distribution-style validation rather than RT-core stress benchmarking.
