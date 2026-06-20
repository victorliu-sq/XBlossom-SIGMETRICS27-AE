# RT Core Basics: Ray Concurrency and BVH Memory Access

This note answers three practical questions for RT benchmark interpretation:

1. Are all rays traversing a BVH executed concurrently?
2. During BVH traversal, does the RT core access L1 cache, L2 cache, or global memory for BVH nodes?
3. If an RT core is associated with an SM, does it share cache resources with CUDA/shader execution on that SM?

## Short Answers

No, not all rays execute concurrently. A ray-tracing launch may contain millions of rays, but the GPU executes them in scheduled waves of warps across available SMs. Each SM can keep multiple warps resident, and each SM-associated RT core can accelerate traversal/intersection for work issued by that SM, but the launch is still bounded by SM count, RT-core count, occupancy, registers, stack/payload state, memory bandwidth, and scheduling.

BVH nodes live in GPU memory as part of the acceleration structure. During traversal, the RT hardware must fetch acceleration-structure nodes and primitive data through the GPU memory hierarchy. Public NVIDIA material states that RT cores perform BVH traversal and ray-triangle testing after the SM launches ray work, but it does not fully specify every internal cache path for every architecture. The safe performance model is that traversal data can hit in GPU caches when locality exists, otherwise it is fetched from device memory through L2/global-memory paths.

Do not assume RT cores have a completely separate private memory system. The RT core is attached to, or paired with, the SM-level execution block. Shader/CUDA code and RT traversal share the GPU memory hierarchy at least at L2 and global memory, and they can contend for bandwidth and cache residency. Whether a specific BVH-node lookup is served by the SM L1 on a specific architecture is an implementation detail, not a stable programming contract.

## Ray Concurrency

A ray-tracing API launch is similar to a CUDA kernel launch: it exposes a large amount of parallel work, but hardware schedules only a subset at any instant.

For OptiX-style execution:

- A ray-generation program or CUDA-side launch creates many ray queries.
- Threads are grouped into warps and scheduled on SMs.
- The SM runs programmable shader code and issues ray traversal work.
- The RT core accelerates BVH traversal and supported primitive intersection work.
- When traversal needs programmable logic, such as any-hit, closest-hit, custom intersection, miss, or payload update code, execution returns to programmable SM resources.

So the correct mental model is many rays in flight, not all rays at once.

Example: if a launch traces 100 million rays on a GPU with 58 SMs and 58 RT cores, the launch does not execute 100 million rays simultaneously. It streams those rays through the resident warps on the 58 SMs. Occupancy and scheduling determine how many warps/rays are active enough to hide latency.

## What RT Cores Do During BVH Traversal

NVIDIA's public Turing material describes the division this way: the SM launches a ray probe, then the RT core performs BVH traversal and ray-triangle tests and returns hit/no-hit information to the SM. NVIDIA also describes RT cores as accelerating BVH traversal and ray/triangle intersection.

For benchmark reasoning, this means:

- RT cores accelerate traversal through the acceleration structure.
- RT cores accelerate ray-box and ray-triangle style fixed-function tests.
- RT cores do not build the BVH/GAS.
- RT cores do not execute arbitrary CUDA code.
- Shader-side payload logic, custom primitive logic, filtering, reductions, and result writes still use SM resources.

This is why RT benchmark timing should separate BVH build time from RT traversal/intersection time.

## BVH Node Memory Path

A BVH/GAS is stored in GPU-accessible memory. Traversal needs to read:

- Internal BVH nodes or compressed node representations.
- Child bounding boxes or node metadata.
- Primitive references.
- Triangle data, AABBs, or custom-primitive metadata.
- Ray payload and stack/state data around traversal.

The exact internal path for these reads is not exposed as a portable API-level guarantee. NVIDIA does not document a simple rule such as "all RT-core BVH node reads always use SM L1" or "RT cores bypass L1" for every architecture.

Use this practical model instead:

| Level | Practical interpretation for RT traversal |
|---|---|
| SM L1 / local cache | May help nearby shader-side data and architecture-dependent traversal locality, but should not be treated as a guaranteed RT-core BVH-node cache contract. |
| L2 cache | Shared GPU-wide cache. BVH nodes, geometry, ray data, and output traffic can reuse or contend here. This is the safest cache level to include in a cross-SM RT performance model. |
| Global memory / VRAM | Backing storage for acceleration structures and geometry. Poor BVH locality or very large working sets eventually pressure VRAM bandwidth and latency. |

The important performance point is that traversal is not free just because intersection math is fixed-function. RT cores still need the BVH and geometry data to arrive from memory. If node accesses are irregular and miss cache, RT cores can stall or become underfed.

## Do CUDA Cores and RT Cores Share L1?

The careful answer is: they share the SM neighborhood, but public documentation does not make the SM L1 behavior of RT-core traversal a precise programming contract.

What is safe to say:

- Each SM has local L1/shared-memory resources for normal SM execution.
- Modern NVIDIA RTX GPUs generally have one RT core per SM in the configurations used in these notes.
- The SM launches and coordinates ray work; the RT core accelerates traversal/intersection for that work.
- Shader/CUDA code and RT traversal share the broader memory hierarchy, especially L2 and device memory bandwidth.
- Heavy shader memory traffic can interfere with RT traversal by consuming cache capacity or memory bandwidth.
- Heavy traversal traffic can interfere with shader code for the same reason.

What should not be claimed without architecture-specific evidence:

- That an RT core is just another CUDA execution unit.
- That BVH node reads always use exactly the same L1 path as ordinary CUDA loads.
- That RT cores have a fully independent cache hierarchy isolated from shader memory traffic.
- That increasing RT-core count alone guarantees proportional speedup if the workload is memory-bound or shader-bound.

## Implications for These Benchmarks

For RT benchmark results, model each application as a pipeline:

1. CUDA/SM code prepares inputs and rays.
2. BVH/GAS construction builds the acceleration structure, usually through OptiX/CUDA-side build machinery rather than RT-core traversal hardware.
3. RT cores accelerate traversal and fixed-function intersection during the RT launch.
4. SM code executes programmable hit/miss/custom logic and writes results.
5. L2, memory bandwidth, and cache locality determine whether SMs and RT cores stay fed.

This explains common benchmark patterns:

- Ray throughput often scales better with newer RT cores than BVH build time does.
- BVH build can dominate end-to-end time even on GPUs with many RT cores.
- Workloads with coherent rays and reusable BVHs benefit more from cache and RT-core throughput.
- Workloads with divergent rays, large BVHs, custom intersection code, or heavy post-processing can become memory-bound or SM-bound.
- L1/L2 cache size matters, but it is not a substitute for measuring traversal time, build time, and shader-side overhead separately.

## References

- [NVIDIA Turing Architecture In-Depth](https://developer.nvidia.com/blog/?p=11872): describes Turing RT cores processing BVH traversal and ray-triangle intersection while the SM launches ray work.
- [NVIDIA Turing GPU Architecture Whitepaper](https://images.nvidia.com/aem-dam/Solutions/design-visualization/technologies/turing-architecture/NVIDIA-Turing-Architecture-Whitepaper.pdf): architecture source for the RT-core/SM split.
- [NVIDIA OptiX Programming Guide](https://docs.nvidia.com/gameworks/content/gameworkslibrary/optix/optix_programming_guide.htm): documents the programmable ray tracing model and OptiX abstraction.
- [NVIDIA OptiX Ray Tracing Powered by RTX](https://developer.nvidia.com/blog/nvidia-optix-ray-tracing-powered-rtx/): describes shader callbacks such as closest-hit programs around traversal.
