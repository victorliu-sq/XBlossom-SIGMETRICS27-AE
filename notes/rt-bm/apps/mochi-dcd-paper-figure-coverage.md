# Mochi-DCD Dataset To Paper Figure Mapping

This note maps the datasets in `expr/benchmark/Mochi-DCD/run_benchmark.sh` to the Mochi-DCD paper figures they correspond to.

The benchmark script runs both Mochi-DCD samples for every dataset:

- `sample23-3Dparticlesim`: freefall
- `sample19-3Dparticlesim-rotate`: rotating gravity in the XZ plane

Therefore, a dataset can correspond to different paper figures depending on which motion/sample is used.

| Script dataset | Paper dataset meaning | Freefall mapping | Rotating-gravity mapping |
|---|---|---|---|
| `FirstDataset\|freefall-5M-r0.0005-0.0006` | First dataset: particles in a unit cube, radii uniformly distributed in `0.0005-0.0006`, density `500` | Figure 7a/7b: freefall DEM simulation, particles varying from 1M to 5M | Figure 8a/8b: rotating-gravity DEM simulation, particles varying from 1M to 5M |
| `SecondDataset\|freefall-1M-r0.0005-0.0006` | Second dataset: 1M particles in a 16-unit cube, radii `0.0005-0.0006` | Not the primary direct target in our current paper mapping | Figure 5: rotating-gravity DCD kernel comparison across radius ranges |
| `SecondDataset\|freefall-1M-r0.0005-0.006` | Second dataset: 1M particles in a 16-unit cube, radii `0.0005-0.006`, max/min radius ratio 12 | Not the primary direct target in our current paper mapping | Figure 5 and Figure 9a/9b: rotating gravity with irregular radii |
| `SecondDataset\|freefall-1M-r0.0005-0.06` | Second dataset: 1M particles in a 16-unit cube, radii `0.0005-0.06`, max/min radius ratio 120 | Figure 4: freefall DCD kernel comparison at up to 1M particles | Figure 5 and Figure 9a/9b: rotating gravity with irregular radii |

Most direct correspondence for the current benchmark rows:

| Dataset and motion | Paper figure/subfigure |
|---|---|
| `5M r0.0005-0.0006` + freefall | Figure 7b |
| `5M r0.0005-0.0006` + rotating gravity | Figure 8b |
| `1M r0.0005-0.0006` + rotating gravity | Figure 5 |
| `1M r0.0005-0.006` + rotating gravity | Figure 5 and Figure 9b |
| `1M r0.0005-0.06` + freefall | Figure 4 |
| `1M r0.0005-0.06` + rotating gravity | Figure 5 and Figure 9b |

Notes:

- Figure 4 varies particle count from 10K to 1M using the second dataset with radii `0.0005-0.06` under freefall. Our current dataset covers the 1M endpoint.
- Figure 5 uses the second dataset with 1M particles under rotating gravity and compares radii ranges `0.0005-0.0006`, `0.0005-0.006`, and `0.0005-0.06`.
- Figure 7 uses the first dataset under freefall and varies particle count from 1M to 5M. Our current first-dataset entry covers the 5M endpoint.
- Figure 8 uses the first dataset under rotating gravity and varies particle count from 1M to 5M. Our current first-dataset entry covers the 5M endpoint.
- Figure 9 uses the second dataset under rotating gravity for irregular radii, specifically `0.0005-0.006` and `0.0005-0.06`.
