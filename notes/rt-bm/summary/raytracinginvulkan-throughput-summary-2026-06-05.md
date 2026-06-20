# Ray Throughput Summary, 2026-06-05

This note summarizes application-reported RT phase throughput across the five AWS GPU hosts. Each application table uses the same five host rows and reports the number of distinct datasets represented by successful rows, the average ray throughput, the best dataset, and the best observed ray throughput.

RayJoin is split into `RayJoin-LSI` and `RayJoin-PIP` because the CSV reports separate ray-tracing phases for line-segment intersection and point-in-polygon queries. LibRTS is split into `point-contains`, `range-contains`, and `range-intersects` for the same reason: each query type is a different RT workload.

For RayTracingInVulkan, the `aws-t4` row is from the original 10-workload run. The newer `aws-l4`, `aws-l40s`, `aws-a10g`, and `aws-pro6000` rows use the refined cross-host stable subset after removing `WKND` workloads that failed on some hosts at the selected large image size (`3072x3072`, `samples=1`).

## RayTracingInVulkan

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) |
| --- | --- | ---: | ---: | ---: | --- | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 4 | 26065193.51 | `WKND` | 29443538.27 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 3 | 16903045.61 | `CRNVL` | 19022783.76 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 3 | 27049614.71 | `CRNVL` | 30669283.87 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 3 | 21770614.56 | `BATH` | 25340232.37 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 3 | 21009249.14 | `CRNVL` | 23065227.59 |

## RayJoin-LSI

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) |
| --- | --- | ---: | ---: | ---: | --- | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 11 | 206.39 | `Block / Park` | 406.46 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 11 | 552.79 | `Block / Park` | 977.94 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 11 | 450.41 | `Block / Park` | 778.86 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 11 | 1410.07 | `Block / Park` | 2476.14 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 11 | 1660.66 | `Water / Aquifers` | 2837.47 |

## RayJoin-PIP

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) |
| --- | --- | ---: | ---: | ---: | --- | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 11 | 210.85 | `Water / Aquifers` | 296.80 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 11 | 469.91 | `Block / Aquifers` | 678.21 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 11 | 402.11 | `Block / Aquifers` | 570.88 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 11 | 1210.78 | `Block / Aquifers` | 1733.85 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 11 | 1396.59 | `Block / Aquifers` | 2013.13 |

## LibRTS-point-contains

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) |
| --- | --- | ---: | ---: | ---: | --- | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 6 | 573.29 | `County` | 627.35 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 6 | 1463.49 | `County` | 1655.63 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 6 | 1289.19 | `County` | 1547.99 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 6 | 2273.44 | `EuropePark` | 2512.56 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 6 | 2318.65 | `County` | 2577.32 |

## LibRTS-range-contains

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) |
| --- | --- | ---: | ---: | ---: | --- | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 6 | 539.03 | `Block` | 625.78 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 6 | 1426.91 | `County` | 1602.56 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 6 | 1289.11 | `County` | 1492.54 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 6 | 2258.05 | `EuropePark` | 2538.07 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 6 | 2413.88 | `County` | 2487.56 |

## LibRTS-range-intersects

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) |
| --- | --- | ---: | ---: | ---: | --- | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 6 | 598.05 | `Water` | 1308.26 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 6 | 1325.96 | `Water` | 3247.15 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 6 | 1217.38 | `Water` | 2950.47 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 6 | 2791.22 | `Water` | 6794.29 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 6 | 2818.22 | `Water` | 6849.43 |

## X-HD

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) |
| --- | --- | ---: | ---: | ---: | --- | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 7 | 356.37 | `Lake / Park` | 732.26 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 7 | 692.27 | `Lake / Park` | 1313.97 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 7 | 756.99 | `Thai / AsianDragon` | 1377.48 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 7 | 1160.06 | `Lake / Park` | 3125.13 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 7 | 1353.35 | `Lake / Park` | 3275.30 |

## RTTC

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) |
| --- | --- | ---: | ---: | ---: | --- | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 5 | 1550.54 | `WikiTalk` | 2897.26 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 5 | 5822.76 | `WikiTalk` | 7879.95 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 5 | 4909.21 | `WikiTalk` | 6732.13 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 5 | 13939.19 | `WikiTalk` | 19720.57 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 5 | 16222.39 | `WikiTalk` | 22636.89 |

## RTNN

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) |
| --- | --- | ---: | ---: | ---: | --- | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 10 | 65.62 | `NBody / NBody6M` | 187.69 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 11 | 176.69 | `NBody / NBody6M` | 599.03 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 11 | 132.01 | `NBody / NBody6M` | 450.74 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 12 | 407.13 | `NBody / NBody6M` | 1485.53 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 12 | 480.95 | `NBody / NBody6M` | 1689.21 |

## RT-DBSCAN

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) |
| --- | --- | ---: | ---: | ---: | --- | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 3 | 124436.38 | `NGSIM` | 306055.39 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 3 | 291119.35 | `NGSIM` | 710160.90 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 3 | 266307.14 | `NGSIM` | 447517.28 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 3 | 592283.46 | `NGSIM` | 1113404.99 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 3 | 822961.00 | `NGSIM` | 1512071.28 |

## RayDB

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) |
| --- | --- | ---: | ---: | ---: | --- | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 13 | 352946.02 | `Figure 12(c) / q34` | 678345.29 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 13 | 811558.62 | `Figure 12(c) / q33` | 1484186.08 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 13 | 800765.84 | `Figure 12(c) / q12` | 1459551.96 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 13 | 1742497.98 | `Figure 12(c) / q21` | 3314680.41 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 13 | 2106716.62 | `Figure 12(c) / q21` | 4099470.32 |

## RTOD

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) |
| --- | --- | ---: | ---: | ---: | --- | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 3 | 319565.99 | `Stock` | 654411.72 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 3 | 436391.23 | `Stock` | 854029.31 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 3 | 431686.92 | `Stock` | 864797.55 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 3 | 678681.17 | `Stock` | 1210974.82 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 3 | 646434.87 | `Stock` | 1052237.27 |

## RTSpMSpM

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) |
| --- | --- | ---: | ---: | ---: | --- | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 16 | 78030.45 | `mario002` | 186955.01 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 16 | 202613.43 | `mario002` | 481974.55 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 16 | 175889.46 | `mario002` | 371671.91 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 16 | 322257.91 | `mario002` | 622550.46 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 16 | 492240.12 | `roadNet-CA` | 990605.15 |

## RT-BarnesHut

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) |
| --- | --- | ---: | ---: | ---: | --- | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 6 | 1781.29 | `synthetic-10M` | 2568.24 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 6 | 4283.34 | `synthetic-10M` | 6199.28 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 6 | 10503.21 | `synthetic-10M` | 15175.13 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 6 | 28193.65 | `synthetic-10M` | 40416.78 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 6 | 43754.14 | `synthetic-10M` | 61589.25 |

## Mochi-DCD

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) |
| --- | --- | ---: | ---: | ---: | --- | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 4 | 1090739.82 | `SecondDataset / freefall-1M-r0.0005-0.0006` | 1201703.70 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 4 | 3391037.28 | `FirstDataset / freefall-5M-r0.0005-0.0006` | 3874804.82 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 4 | 2609247.20 | `SecondDataset / freefall-1M-r0.0005-0.0006` | 2844285.00 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 4 | 7303061.50 | `FirstDataset / freefall-5M-r0.0005-0.0006` | 8031390.95 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 4 | 8910879.23 | `FirstDataset / freefall-5M-r0.0005-0.0006` | 9868074.27 |

## Interpretation

These tables measure only each application's reported RT compute phase, not dependency installation, dataset download, build time, or full end-to-end runtime. The average is computed over successful rows in each host's result CSV after applying the application split described above.

Throughput does not necessarily increase monotonically with newer or larger GPU architecture. A larger GPU only shows its architectural advantage when the workload keeps enough traversal, shading, and memory activity in flight. Short RT phases can be dominated by launch overhead, synchronization, driver scheduling, clock ramp behavior, scene divergence, and timestamp noise.

For stricter architecture comparisons, use the exact same dataset list on all hosts, include warmup iterations, collect multiple repeats, and report median throughput per dataset before averaging across applications.
