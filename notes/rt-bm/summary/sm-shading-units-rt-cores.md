# SMs, Shading Units, and RT Cores in General-Purpose RT Workloads

This note summarizes the relationship between SMs, shading units, tensor cores,
RT cores, and nearby fixed-function units for a GPU configuration like the one
shown in the reference image:

| Resource | Count |
|---|---:|
| Shading units | 10,240 |
| TMUs | 320 |
| ROPs | 112 |
| SMs | 80 |
| Tensor cores | 320 |
| RT cores | 80 |
| L1 cache | 128 KB per SM |
| L2 cache | 6 MB |

## Per-SM Relationship

The important architectural relationship is that the streaming multiprocessor
(SM) is the larger execution block. It is not the same thing as a single CUDA
core or shading unit. An SM contains many smaller execution and scheduling
resources, and the RT core is paired with that SM-level block.

For this configuration:

| Resource | Per-SM ratio |
|---|---:|
| Shading units per SM | 10,240 / 80 = 128 |
| RT cores per SM | 80 / 80 = 1 |
| Tensor cores per SM | 320 / 80 = 4 |
| TMUs per SM | 320 / 80 = 4 |
| L1 cache per SM | 128 KB |

In other words, each SM is the local scheduling and execution block that groups
programmable shading units, tensor cores, texture units, local L1/shared memory
resources, warp schedulers, register files, and load/store paths. In this
configuration, each SM also has one associated RT core. The L2 cache is shared
across the GPU.

## What Each Unit Does

### SM

The SM is the larger unit that schedules and executes groups of CUDA
threads/warps. A simplified SM contains or coordinates:

- Warp schedulers and dispatch logic.
- Register files and shared memory/L1 cache resources.
- Shading units/CUDA cores for ordinary integer and floating-point arithmetic.
- Tensor cores for matrix/tensor operations.
- Load/store units for memory operations.
- Texture units/TMUs for texture or sampled read-only access.
- One associated RT core in this GPU configuration.

For general-purpose RT workloads, the SM is responsible for the ordinary
programmable work around ray tracing:

- Generating rays from input records, pixels, points, graph edges, particles, or
  query objects.
- Running traversal setup code and preparing ray payloads.
- Executing custom intersection, closest-hit, any-hit, miss, or post-processing
  shader logic.
- Performing integer and floating-point math not handled by fixed-function RT
  hardware.
- Managing memory loads/stores, shared memory use, synchronization, and control
  flow.
- Running application-specific filtering, compaction, reduction, aggregation,
  scoring, or output materialization.

The SM is therefore the main programmable container and scheduler. Even in an
RT workload, the RT core does not replace the SM; it is a specialized
accelerator associated with the SM that handles traversal/intersection work
while the SM continues to run the surrounding program logic.

### Shading Units / CUDA Cores

"Shading Units" are GPU cores that do most of the general programmable computation on a GPU.
They execute the normal arithmetic instructions issued by warps.

In CUDA-oriented terminology, these are
the scalar/vector arithmetic lanes inside the SM, often discussed as CUDA cores.
On AMD GPUs, the comparable term is often stream processors.

For general-purpose RT workloads, shading units commonly handle:

- Ray origin and direction computation.
- Bounding-box, vector, matrix, and coordinate math outside the RT core.
- Application-specific predicates and distance/error calculations.
- Payload updates after an intersection result is returned.
- Non-RT fallback kernels, preprocessing kernels, and postprocessing kernels.
- Data structure construction steps that are implemented in CUDA rather than in
  fixed-function hardware.

With 10,240 shading units across 80 SMs, each SM has 128 shading units. This
means throughput depends not only on the number of RT cores, but also on whether
the surrounding programmable math keeps the SM arithmetic lanes occupied.

### RT Cores

RT cores are fixed-function accelerators attached to the SMs. In this
configuration there is one RT core per SM.

For general-purpose RT workloads, RT cores accelerate:

- BVH traversal through acceleration structures.
- Ray-box intersection tests against bounding volumes.
- Ray-triangle intersection tests for triangle geometry.
- Hardware-supported intersection work exposed through APIs such as OptiX,
  Vulkan ray tracing, or DirectX Raytracing.

The RT core is best understood as a specialized helper for the geometric search
part of ray tracing. It does not run arbitrary CUDA code. The SM launches and
coordinates ray tracing work, while the RT core accelerates the expensive
traversal/intersection portion. Once an intersection candidate or hit is found,
programmable shader or CUDA code on the SM usually handles the application
logic.

For RT-based non-graphics workloads, this means the RT core is useful when the
problem can be mapped to ray queries over spatial acceleration structures:

- Point-in-polygon or point-in-polyhedron queries.
- Collision detection and proximity tests.
- Nearest/intersection-style spatial search.
- Sparse or graph problems recast as ray intersections.
- Geometric filtering before a heavier programmable computation.

### Tensor Cores

Tensor cores are also attached to SMs, with 4 tensor cores per SM in this
configuration. They accelerate matrix/tensor math, especially mixed-precision
matrix multiply-accumulate operations.

They are not directly responsible for BVH traversal or ray intersection. In a
general-purpose RT workload, tensor cores are only useful if the surrounding
application includes dense linear algebra, machine learning inference, learned
filters, embedding computations, or other matrix-heavy phases.

### TMUs

Texture mapping units (TMUs) handle texture sampling and related filtering
operations. In graphics ray tracing, they are important for material and texture
lookups.

For general-purpose RT workloads, TMUs are usually less central unless the
application uses texture memory or spatial data encoded as textures. They can
still matter for cached read-only data access patterns, interpolation-style
lookups, or image/grid-backed query data.

### ROPs

Raster operation units (ROPs) are output/fragment-backend units used heavily in
traditional rendering for framebuffer operations. They are generally not the
main performance limiter for compute-style RT benchmarks unless the workload
includes substantial raster output, image writes, or graphics pipeline work.

### L1 and L2 Cache

Each SM has its own local L1 cache, while the L2 cache is shared across the GPU.
For RT workloads, cache behavior matters because traversal and query execution
often touch irregular data:

- BVH nodes and geometry records.
- Ray payloads and result buffers.
- Query input arrays.
- Application-specific indices or metadata.

Good locality can help both the SM-side code and RT-core-fed traversal. Poor
locality can leave shading units and RT cores underutilized because warps wait
on memory.

## Practical Interpretation for RT Benchmarks

For a general-purpose RT benchmark, the performance path is usually split:

1. SM/shading-unit work prepares rays, launches kernels, handles payloads, and
   runs custom logic.
2. RT cores accelerate BVH traversal and ray-geometry intersection.
3. SM/shading-unit work consumes the hit/miss results and performs filtering,
   aggregation, or writes.
4. Memory hierarchy performance determines whether these units stay fed.

The one-RT-core-per-SM relationship is important: scaling RT work is tied to SM
occupancy and scheduling. A workload with many rays but little programmable work
may become RT-core or memory limited. A workload with expensive custom hit
logic, reductions, or data conversion may become SM/shading-unit limited even
though RT cores are present.

So the counts in the image should be read together:

- 80 SMs provide the scheduling and programmable execution footprint.
- 10,240 shading units provide arithmetic throughput for general CUDA/shader
  work.
- 80 RT cores provide one fixed-function ray traversal/intersection accelerator
  per SM.
- 320 tensor cores only help phases that can use matrix/tensor operations.
- Cache and memory behavior often decide how much of the theoretical throughput
  can actually be used.
