# OptiX Nsight Compute Metrics and Shader-Side Work per Ray

This note summarizes how to interpret Nsight Compute profiling for OptiX
workloads launched through `optixLaunch`, especially when the workload uses
hardware RT cores.

## Short Answer

Yes, Nsight Compute can profile the GPU work submitted by `optixLaunch`, but the
metrics should be interpreted carefully. OptiX ray tracing work includes both
fixed-function RT-core traversal/intersection and programmable CUDA/SM-side
shader execution. Nsight Compute is useful for the programmable side: instruction
counts, memory traffic, cache behavior, occupancy, divergence symptoms, and
partial FLOP-related counters. It does not fully convert RT-core traversal and
intersection work into normal CUDA-core FLOPs.

Therefore, shader-side work per ray is a useful metric for RT-core benchmarks,
but it is not a direct standalone measurement of raw RT-core hardware
performance.

## What `optixLaunch` Submits

`optixLaunch` is a CPU API call that submits OptiX GPU work to a CUDA stream.
Under the hood, the GPU executes kernels and ray tracing pipeline programs such
as:

- Ray-generation programs.
- Traversal and intersection work.
- Miss programs.
- Any-hit and closest-hit programs.
- Custom intersection or application-specific shader logic.
- Payload update and output-write logic.

Nsight Compute can profile the underlying GPU execution, but some OptiX internal
kernels may appear as NVIDIA internal kernels. For those internal kernels, source,
PTX, or SASS mapping may be limited or unavailable.

A typical command is:

```bash
ncu --target-processes all ./your_optix_app
```

For focused collection, use selected metrics rather than collecting everything:

```bash
ncu \
  --target-processes all \
  --metrics \
  dram__bytes_read.sum,dram__bytes_write.sum,lts__t_bytes.sum,l1tex__t_bytes.sum,smsp__inst_executed.sum \
  ./your_optix_app
```

Useful metric discovery commands include:

```bash
ncu --query-metrics | grep -i flop
ncu --query-metrics | grep -i fadd
ncu --query-metrics | grep -i ffma
ncu --query-metrics | grep -i sass_thread_inst
```

## Fixed-Function vs Programmable Work

In RT-core mode, the ray tracing pipeline has two major parts.

Fixed-function RT-core side:

- BVH traversal.
- Ray-box tests.
- Ray-triangle or hardware-supported primitive intersection assistance.

Programmable CUDA/SM side:

- Ray generation.
- Closest-hit, any-hit, miss, and custom shader logic.
- Payload update.
- Material or application-specific computation.
- User-buffer loads and stores.
- Output writes.
- Loop, branch, and control-flow logic.
- Preprocessing and post-processing kernels.

The RT core does not execute arbitrary CUDA code. The SM launches and coordinates
ray work, while the RT core accelerates the traversal/intersection portion. When
programmable logic is needed, execution uses normal SM resources.

## Interpreting the Whitepaper Number

The NVIDIA Turing/Ampere discussion of about `10 TFLOPS / Giga Ray` should be
read as a software ray tracing comparison point for pre-RT-core GPUs such as
Pascal.

The rough conversion is:

```text
10 TFLOPS / 1 Giga Ray/s = about 10,000 FLOPs per ray
```

That means software traversal/intersection on CUDA/shader cores can cost roughly
10,000 FP32-equivalent operations per ray. It includes work such as BVH traversal
logic, ray-box tests, ray-triangle tests, address calculations, branches, and
related control flow.

It should not be interpreted as the CUDA-core cost per ray when using RT cores.
On Turing, Ampere, Ada, and later RTX GPUs, much of that traversal/intersection
work moves into fixed-function RT hardware and no longer appears as ordinary
CUDA-core FP32 instructions.

Correct interpretation:

- Pascal-style software RT: traversal/intersection runs on CUDA cores, so FLOPs
  per ray can approximate software ray tracing cost.
- RT-core hardware RT: traversal/intersection partly runs on RT cores, so
  CUDA-core FLOPs per ray measure only the programmable shader-side cost.

## Why Shader-Side Metrics per Ray Are Useful

Shader-side metrics per ray expose how much ordinary GPU work remains around
each ray query after RT-core acceleration. Useful normalized metrics include:

- Shader instructions per ray.
- FP32/INT instruction counts per ray.
- Shader-side FLOPs per ray, when available.
- L1, L2, and DRAM bytes per ray.
- Cache hit rate and cache traffic per ray.
- Register pressure and occupancy.
- Branch/divergence symptoms.
- SM utilization and achieved occupancy.

These metrics answer practical benchmark questions:

- How much programmable overhead does the workload add around each ray?
- Is the benchmark mostly testing RT traversal, shader logic, or memory traffic?
- Did the algorithmic mapping to ray queries create excessive payload or
  post-processing cost?
- Are hit/miss programs or custom intersection programs too expensive?
- Is the workload likely shader-bound, memory-bound, or traversal-bound?
- Are rays coherent enough to use caches and hardware efficiently?

## Example Interpretations

Workload A:

- High rays/s.
- Low shader instructions per ray.
- Low DRAM bytes per ray.
- Good cache behavior.

Interpretation: likely a clean RT-core-friendly workload with low programmable
overhead.

Workload B:

- Low rays/s.
- High shader instructions per ray.
- High DRAM bytes per ray.
- Heavy application-side processing.

Interpretation: poor performance cannot be blamed on RT cores alone. The
workload is likely dominated by CUDA/SM-side logic, memory traffic, or both.

Workload C:

- Low rays/s.
- Low shader instructions per ray.
- Low CUDA-side FLOPs per ray.
- Low visible shader-side overhead.

Interpretation: the bottleneck may be traversal behavior, ray incoherence, BVH
quality, geometry layout, traversal-memory latency, or RT-core utilization. More
direct RT-core or graphics-profiler counters would be useful if available.

## What These Metrics Cannot Prove

Shader-side counters do not directly measure the full fixed-function RT-core
work. They cannot, by themselves, prove raw RT-core throughput or fully explain
RT traversal cost.

Do not claim:

- CUDA FLOPs per ray equals total ray tracing work in RT-core mode.
- Nsight Compute shader counters fully capture RT-core traversal/intersection.
- Poor rays/s always means weak RT-core hardware.
- High rays/s alone proves good hardware use if shader-side work differs greatly
  across workloads.

The safer claim is that shader-side counters help separate non-RT overhead from
RT traversal behavior.

## Recommended Benchmark Methodology

Use Nsight Systems first to identify the timeline region and OptiX launch that
corresponds to the measured workload. Then use Nsight Compute to collect detailed
per-kernel counters for that region.

Optional NVTX marking:

```cpp
nvtxRangePushA("OptiX launch");
OPTIX_CHECK(optixLaunch(
    pipeline,
    stream,
    d_params,
    sizeof(Params),
    &sbt,
    width,
    height,
    depth));
CUDA_CHECK(cudaStreamSynchronize(stream));
nvtxRangePop();
```

Possible Nsight Compute command:

```bash
ncu --target-processes all --nvtx --nvtx-include "OptiX launch" ./your_optix_app
```

Combine the following metrics in reports:

- Rays/s or queries/s.
- Time per ray/query.
- Speedup over software CUDA traversal, CPU baseline, or non-RT GPU baseline.
- Shader instructions per ray.
- Shader FLOPs or instruction categories per ray, where available.
- L1/L2/DRAM bytes per ray.
- Cache hit rates and memory traffic.
- SM utilization, occupancy, register pressure, and divergence indicators.
- Scene size, BVH/GAS size, geometry layout, and hit/miss behavior.
- RT-core throughput/utilization counters, if exposed by the profiling tool.

Direct RT-core counters are not always exposed through ordinary Nsight Compute
flows. NVIDIA tooling and forum guidance indicate that some RT-core throughput
metrics may require Nsight Graphics Pro or graphics-focused profiling workflows.
Nsight Compute remains useful for OptiX/CUDA-side kernel profiling.

## Practical Conclusion

Shader-side work per ray is useful for general-purpose RT-core workloads because
it measures the residual CUDA/SM-side cost around each ray query. It helps reveal
whether a workload is limited by programmable logic, memory traffic, cache
behavior, occupancy, divergence, or algorithm-mapping overhead.

However, it is not a direct measurement of the full RT-core hardware work. To
evaluate how well the hardware performs the job, combine shader-side metrics with
ray throughput, elapsed time, baseline speedups, memory traffic, workload
structure, and any available RT-core-specific counters.
