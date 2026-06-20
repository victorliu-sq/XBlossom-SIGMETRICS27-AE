# RayJoin one-by-one rerun on aws-t4

Date: 2026-05-26

Remote repo: `/home/ubuntu/RT-Benchmarks`

Run directory: `/home/ubuntu/RT-Benchmarks/tmp/benchmark-runs/rayjoin-one-by-one-20260526-163117`

Summary CSV: `/home/ubuntu/RT-Benchmarks/tmp/benchmark-runs/rayjoin-one-by-one-20260526-163117/summary.csv`

Command shape:

```bash
/home/ubuntu/RT-Benchmarks/build/apps/RayJoin/bin/polyover_exec_native \
  -poly1 data/RayJoin/realworld/<poly1> \
  -poly2 data/RayJoin/realworld/<poly2> \
  -output tmp/RayJoin/results/<name>_result_optix_native.txt \
  -timing_csv tmp/RayJoin/timing/run_optix_native_<id>_timing.csv \
  -mode=rt \
  -serialize=tmp/RayJoin/serialized_maps \
  -ag=2 \
  -xsect_factor=5.0 \
  -warmup=5 \
  -repeat=5 \
  -query=lsi/pip
```

## Issues

| Application | Dataset pair | Phase | Symptom | Resolution |
| --- | --- | --- | --- | --- |
| RayJoin | `USACensusBlockGroupBoundaries.cdb` vs `USADetailedWaterBodies.cdb` | Run | GPU memory allocation failure / OOM, exit 134 | Recorded as OOM and continued with the remaining RayJoin runs. |

## Results

| ID | Name | Dataset 1 | Dataset 2 | Status | Exit | Elapsed (s) | Timing CSV | Log |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| 1 | Aquifers_Cnty | `Aquifers.cdb` | `dtl_cnty.cdb` | ok | 0 | 16.97 | `/home/ubuntu/RT-Benchmarks/tmp/RayJoin/timing/run_optix_native_1_timing.csv` | `/home/ubuntu/RT-Benchmarks/tmp/benchmark-runs/rayjoin-one-by-one-20260526-163117/1_Aquifers_Cnty.log` |
| 2 | Parks_ZIPCode | `Parks.cdb` | `USAZIPCodeArea.cdb` | ok | 0 | 30.04 | `/home/ubuntu/RT-Benchmarks/tmp/RayJoin/timing/run_optix_native_2_timing.csv` | `/home/ubuntu/RT-Benchmarks/tmp/benchmark-runs/rayjoin-one-by-one-20260526-163117/2_Parks_ZIPCode.log` |
| 3 | Block_Water | `USACensusBlockGroupBoundaries.cdb` | `USADetailedWaterBodies.cdb` | oom | 134 | 9.18 | `/home/ubuntu/RT-Benchmarks/tmp/RayJoin/timing/run_optix_native_3_timing.csv` | `/home/ubuntu/RT-Benchmarks/tmp/benchmark-runs/rayjoin-one-by-one-20260526-163117/3_Block_Water.log` |
| 4 | Block_Aquifers | `USACensusBlockGroupBoundaries.cdb` | `Aquifers.cdb` | ok | 0 | 69.27 | `/home/ubuntu/RT-Benchmarks/tmp/RayJoin/timing/run_optix_native_4_timing.csv` | `/home/ubuntu/RT-Benchmarks/tmp/benchmark-runs/rayjoin-one-by-one-20260526-163117/4_Block_Aquifers.log` |
| 5 | Water_Aquifers | `USADetailedWaterBodies.cdb` | `Aquifers.cdb` | ok | 0 | 58.81 | `/home/ubuntu/RT-Benchmarks/tmp/RayJoin/timing/run_optix_native_5_timing.csv` | `/home/ubuntu/RT-Benchmarks/tmp/benchmark-runs/rayjoin-one-by-one-20260526-163117/5_Water_Aquifers.log` |
| 6 | Block_Cnty | `USACensusBlockGroupBoundaries.cdb` | `dtl_cnty.cdb` | ok | 0 | 86.41 | `/home/ubuntu/RT-Benchmarks/tmp/RayJoin/timing/run_optix_native_6_timing.csv` | `/home/ubuntu/RT-Benchmarks/tmp/benchmark-runs/rayjoin-one-by-one-20260526-163117/6_Block_Cnty.log` |
| 7 | Water_Cnty | `USADetailedWaterBodies.cdb` | `dtl_cnty.cdb` | ok | 0 | 66.91 | `/home/ubuntu/RT-Benchmarks/tmp/RayJoin/timing/run_optix_native_7_timing.csv` | `/home/ubuntu/RT-Benchmarks/tmp/benchmark-runs/rayjoin-one-by-one-20260526-163117/7_Water_Cnty.log` |
| 8 | Block_Parks | `USACensusBlockGroupBoundaries.cdb` | `Parks.cdb` | ok | 0 | 27.10 | `/home/ubuntu/RT-Benchmarks/tmp/RayJoin/timing/run_optix_native_8_timing.csv` | `/home/ubuntu/RT-Benchmarks/tmp/benchmark-runs/rayjoin-one-by-one-20260526-163117/8_Block_Parks.log` |
| 9 | Water_Parks | `USADetailedWaterBodies.cdb` | `Parks.cdb` | ok | 0 | 18.36 | `/home/ubuntu/RT-Benchmarks/tmp/RayJoin/timing/run_optix_native_9_timing.csv` | `/home/ubuntu/RT-Benchmarks/tmp/benchmark-runs/rayjoin-one-by-one-20260526-163117/9_Water_Parks.log` |
| 10 | Block_ZIPCode | `USACensusBlockGroupBoundaries.cdb` | `USAZIPCodeArea.cdb` | ok | 0 | 139.48 | `/home/ubuntu/RT-Benchmarks/tmp/RayJoin/timing/run_optix_native_10_timing.csv` | `/home/ubuntu/RT-Benchmarks/tmp/benchmark-runs/rayjoin-one-by-one-20260526-163117/10_Block_ZIPCode.log` |
| 11 | Water_ZIPCode | `USADetailedWaterBodies.cdb` | `USAZIPCodeArea.cdb` | ok | 0 | 72.38 | `/home/ubuntu/RT-Benchmarks/tmp/RayJoin/timing/run_optix_native_11_timing.csv` | `/home/ubuntu/RT-Benchmarks/tmp/benchmark-runs/rayjoin-one-by-one-20260526-163117/11_Water_ZIPCode.log` |
