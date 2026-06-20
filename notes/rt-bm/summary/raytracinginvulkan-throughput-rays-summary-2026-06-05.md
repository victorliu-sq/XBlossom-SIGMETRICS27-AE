# Ray Throughput Summary, 2026-06-05

This note summarizes application-reported RT phase throughput across the five AWS GPU hosts. Each application table uses the same five host rows and reports the number of distinct datasets represented by successful rows, the average ray throughput, the best dataset, and the best observed ray throughput.

The ray-volume columns are reported in Giga Rays. For RayTracingInVulkan, `Rays (Giga Rays)` comes from the explicit `rt_compute_rays` CSV column. For the other applications, `Avg Rays` and `Max Rays` are derived from `ray_throughput(krays/s) * rt_compute_ms` for the selected RT phase.

RayJoin is split into `RayJoin-LSI` and `RayJoin-PIP` because the CSV reports separate ray-tracing phases for line-segment intersection and point-in-polygon queries. LibRTS is split into `point-contains`, `range-contains`, and `range-intersects` for the same reason: each query type is a different RT workload.

For RayTracingInVulkan, the `aws-t4` row is from the original 10-workload run. The newer `aws-l4`, `aws-l40s`, `aws-a10g`, and `aws-pro6000` rows use the refined cross-host stable subset after removing `WKND` workloads that failed on some hosts at the selected large image size (`3072x3072`, `samples=1`).

## RayTracingInVulkan

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) | Rays (Giga Rays) |
| --- | --- | ---: | ---: | ---: | --- | ---: | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 4 | 26065193.51 | `WKND` | 29443538.27 | 0.009437184 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 3 | 16903045.61 | `CRNVL` | 19022783.76 | 0.009437184 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 3 | 27049614.71 | `CRNVL` | 30669283.87 | 0.009437184 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 3 | 21770614.56 | `BATH` | 25340232.37 | 0.009437184 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 3 | 21009249.14 | `CRNVL` | 23065227.59 | 0.009437184 |

## RayJoin-LSI

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) | Avg Rays (Giga Rays) | Max Rays (Giga Rays) |
| --- | --- | ---: | ---: | ---: | --- | ---: | ---: | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 11 | 206.39 | `Block / Park` | 406.46 | 0.000023005 | 0.000028474 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 11 | 552.79 | `Block / Park` | 977.94 | 0.000023005 | 0.000028474 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 11 | 450.41 | `Block / Park` | 778.86 | 0.000023005 | 0.000028474 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 11 | 1410.07 | `Block / Park` | 2476.14 | 0.000023005 | 0.000028473 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 11 | 1660.66 | `Water / Aquifers` | 2837.47 | 0.000023005 | 0.000028473 |

## RayJoin-PIP

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) | Avg Rays (Giga Rays) | Max Rays (Giga Rays) |
| --- | --- | ---: | ---: | ---: | --- | ---: | ---: | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 11 | 210.85 | `Water / Aquifers` | 296.80 | 0.000036979 | 0.000057355 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 11 | 469.91 | `Block / Aquifers` | 678.21 | 0.000036979 | 0.000057354 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 11 | 402.11 | `Block / Aquifers` | 570.88 | 0.000036978 | 0.000057353 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 11 | 1210.78 | `Block / Aquifers` | 1733.85 | 0.000036979 | 0.000057354 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 11 | 1396.59 | `Block / Aquifers` | 2013.13 | 0.000036979 | 0.000057354 |

## LibRTS-point-contains

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) | Avg Rays (Giga Rays) | Max Rays (Giga Rays) |
| --- | --- | ---: | ---: | ---: | --- | ---: | ---: | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 6 | 573.29 | `County` | 627.35 | 0.000000100 | 0.000000100 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 6 | 1463.49 | `County` | 1655.63 | 0.000000100 | 0.000000100 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 6 | 1289.19 | `County` | 1547.99 | 0.000000100 | 0.000000100 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 6 | 2273.44 | `EuropePark` | 2512.56 | 0.000000100 | 0.000000100 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 6 | 2318.65 | `County` | 2577.32 | 0.000000100 | 0.000000100 |

## LibRTS-range-contains

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) | Avg Rays (Giga Rays) | Max Rays (Giga Rays) |
| --- | --- | ---: | ---: | ---: | --- | ---: | ---: | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 6 | 539.03 | `Block` | 625.78 | 0.000000100 | 0.000000100 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 6 | 1426.91 | `County` | 1602.56 | 0.000000100 | 0.000000100 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 6 | 1289.11 | `County` | 1492.54 | 0.000000100 | 0.000000100 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 6 | 2258.05 | `EuropePark` | 2538.07 | 0.000000100 | 0.000000100 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 6 | 2413.88 | `County` | 2487.56 | 0.000000100 | 0.000000100 |

## LibRTS-range-intersects

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) | Avg Rays (Giga Rays) | Max Rays (Giga Rays) |
| --- | --- | ---: | ---: | ---: | --- | ---: | ---: | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 6 | 598.05 | `Water` | 1308.26 | 0.000019870 | 0.000046644 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 6 | 1325.96 | `Water` | 3247.15 | 0.000019870 | 0.000046644 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 6 | 1217.38 | `Water` | 2950.47 | 0.000019870 | 0.000046644 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 6 | 2791.22 | `Water` | 6794.29 | 0.000019870 | 0.000046644 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 6 | 2818.22 | `Water` | 6849.43 | 0.000019870 | 0.000046644 |

## X-HD

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) | Avg Rays (Giga Rays) | Max Rays (Giga Rays) |
| --- | --- | ---: | ---: | ---: | --- | ---: | ---: | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 7 | 356.37 | `Lake / Park` | 732.26 | 0.000060952 | 0.000377079 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 7 | 692.27 | `Lake / Park` | 1313.97 | 0.000061839 | 0.000382851 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 7 | 756.99 | `Thai / AsianDragon` | 1377.48 | 0.000060950 | 0.000377058 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 7 | 1160.06 | `Lake / Park` | 3125.13 | 0.000060927 | 0.000376903 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 7 | 1353.35 | `Lake / Park` | 3275.30 | 0.000060921 | 0.000376738 |

## RTTC

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) | Avg Rays (Giga Rays) | Max Rays (Giga Rays) |
| --- | --- | ---: | ---: | ---: | --- | ---: | ---: | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 5 | 1550.54 | `WikiTalk` | 2897.26 | 0.000060286 | 0.000100000 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 5 | 5822.76 | `WikiTalk` | 7879.95 | 0.000060286 | 0.000100000 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 5 | 4909.21 | `WikiTalk` | 6732.13 | 0.000060286 | 0.000100000 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 5 | 13939.19 | `WikiTalk` | 19720.57 | 0.000060286 | 0.000100000 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 5 | 16222.39 | `WikiTalk` | 22636.89 | 0.000060286 | 0.000100000 |

## RTNN

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) | Avg Rays (Giga Rays) | Max Rays (Giga Rays) |
| --- | --- | ---: | ---: | ---: | --- | ---: | ---: | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 10 | 65.62 | `NBody / NBody6M` | 187.69 | 0.000010251 | 0.000025294 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 11 | 176.69 | `NBody / NBody6M` | 599.03 | 0.000014579 | 0.000057817 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 11 | 132.01 | `NBody / NBody6M` | 450.74 | 0.000014595 | 0.000057950 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 12 | 407.13 | `NBody / NBody6M` | 1485.53 | 0.000024081 | 0.000128866 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 12 | 480.95 | `NBody / NBody6M` | 1689.21 | 0.000024112 | 0.000129252 |

## RT-DBSCAN

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) | Avg Rays (Giga Rays) | Max Rays (Giga Rays) |
| --- | --- | ---: | ---: | ---: | --- | ---: | ---: | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 3 | 124436.38 | `NGSIM` | 306055.39 | 0.005672472 | 0.011850526 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 3 | 291119.35 | `NGSIM` | 710160.90 | 0.005672472 | 0.011850526 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 3 | 266307.14 | `NGSIM` | 447517.28 | 0.005672473 | 0.011850526 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 3 | 592283.46 | `NGSIM` | 1113404.99 | 0.005672473 | 0.011850526 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 3 | 822961.00 | `NGSIM` | 1512071.28 | 0.005672473 | 0.011850526 |

## RayDB

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) | Avg Rays (Giga Rays) | Max Rays (Giga Rays) |
| --- | --- | ---: | ---: | ---: | --- | ---: | ---: | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 13 | 352946.02 | `Figure 12(c) / q34` | 678345.29 | 0.001164801 | 0.005202432 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 13 | 811558.62 | `Figure 12(c) / q33` | 1484186.08 | 0.001164801 | 0.005202432 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 13 | 800765.84 | `Figure 12(c) / q12` | 1459551.96 | 0.001164801 | 0.005202432 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 13 | 1742497.98 | `Figure 12(c) / q21` | 3314680.41 | 0.001164801 | 0.005202432 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 13 | 2106716.62 | `Figure 12(c) / q21` | 4099470.32 | 0.001164801 | 0.005202432 |

## RTOD

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) | Avg Rays (Giga Rays) | Max Rays (Giga Rays) |
| --- | --- | ---: | ---: | ---: | --- | ---: | ---: | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 3 | 319565.99 | `Stock` | 654411.72 | 0.000070000 | 0.000100000 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 3 | 436391.23 | `Stock` | 854029.31 | 0.000070000 | 0.000100000 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 3 | 431686.92 | `Stock` | 864797.55 | 0.000070000 | 0.000100000 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 3 | 678681.17 | `Stock` | 1210974.82 | 0.000070000 | 0.000100000 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 3 | 646434.87 | `Stock` | 1052237.27 | 0.000070000 | 0.000100000 |

## RTSpMSpM

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) | Avg Rays (Giga Rays) | Max Rays (Giga Rays) |
| --- | --- | ---: | ---: | ---: | --- | ---: | ---: | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 16 | 78030.45 | `mario002` | 186955.01 | 0.000226880 | 0.000694109 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 16 | 202613.43 | `mario002` | 481974.55 | 0.000226880 | 0.000694109 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 16 | 175889.46 | `mario002` | 371671.91 | 0.000226880 | 0.000694109 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 16 | 322257.91 | `mario002` | 622550.46 | 0.000226880 | 0.000694109 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 16 | 492240.12 | `roadNet-CA` | 990605.15 | 0.000226880 | 0.000694109 |

## RT-BarnesHut

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) | Avg Rays (Giga Rays) | Max Rays (Giga Rays) |
| --- | --- | ---: | ---: | ---: | --- | ---: | ---: | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 6 | 1781.29 | `synthetic-10M` | 2568.24 | 0.045398745 | 0.099999827 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 6 | 4283.34 | `synthetic-10M` | 6199.28 | 0.045398794 | 0.099999980 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 6 | 10503.21 | `synthetic-10M` | 15175.13 | 0.045398816 | 0.099999965 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 6 | 28193.65 | `synthetic-10M` | 40416.78 | 0.045398815 | 0.099999990 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 6 | 43754.14 | `synthetic-10M` | 61589.25 | 0.045398824 | 0.100000001 |

## Mochi-DCD

| Host | Generation | RT cores | Datasets | Average ray throughput (kRays/s) | Best dataset | Best ray throughput (kRays/s) | Avg Rays (Giga Rays) | Max Rays (Giga Rays) |
| --- | --- | ---: | ---: | ---: | --- | ---: | ---: | ---: |
| `aws-t4` | Turing / 1st gen RT Core | 40 | 4 | 1090739.82 | `SecondDataset / freefall-1M-r0.0005-0.0006` | 1201703.70 | 6.000000002 | 20.000000051 |
| `aws-a10g` | Ampere / 2nd gen RT Core | 72 | 4 | 3391037.28 | `FirstDataset / freefall-5M-r0.0005-0.0006` | 3874804.82 | 5.999999999 | 20.000000020 |
| `aws-l4` | Ada / 3rd gen RT Core | 58 | 4 | 2609247.20 | `SecondDataset / freefall-1M-r0.0005-0.0006` | 2844285.00 | 5.999999999 | 19.999999996 |
| `aws-l40s` | Ada / 3rd gen RT Core | 142 | 4 | 7303061.50 | `FirstDataset / freefall-5M-r0.0005-0.0006` | 8031390.95 | 6.000000001 | 20.000000012 |
| `aws-pro6000` | Blackwell / 4th gen RT Core | 188 | 4 | 8910879.23 | `FirstDataset / freefall-5M-r0.0005-0.0006` | 9868074.27 | 6.000000000 | 20.000000005 |

## Interpretation

These tables measure only each application's reported RT compute phase, not dependency installation, dataset download, build time, or full end-to-end runtime. The average is computed over successful rows in each host's result CSV after applying the application split described above.

Throughput does not necessarily increase monotonically with newer or larger GPU architecture. A larger GPU only shows its architectural advantage when the workload keeps enough traversal, shading, and memory activity in flight. Short RT phases can be dominated by launch overhead, synchronization, driver scheduling, clock ramp behavior, scene divergence, and timestamp noise.

For stricter architecture comparisons, use the exact same dataset list on all hosts, include warmup iterations, collect multiple repeats, and report median throughput per dataset before averaging across applications.