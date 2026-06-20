# AWS Five-GPU RT Core Architecture Analysis, 2026-06-02

This note analyzes phase-level RT benchmark results under:

- `expr/results/aws-t4`
- `expr/results/aws-a10g`
- `expr/results/aws-l4`
- `expr/results/aws-l40s`
- `expr/results/aws-pro6000`
- `expr/results/azure-v710` for AMD/Azure context only

The focus is on the columns added for RT phase analysis:

- `bvh_build_ms (...)`: acceleration-structure build time for the primitive representation used by each application.
- `rt_compute_ms` or phase-specific RT compute columns: measured OptiX launch or render/traversal phase time.
- `ray_throughput(krays/s)` or phase-specific ray-throughput columns: rays processed per RT compute time, reported in thousand rays per second.

RayJoin is split into `RayJoin-LSI` and `RayJoin-PIP` because they represent different query workloads: LSI casts rays for line-segment intersection, while PIP casts rays for point-in-polygon location. They share the same RayJoin BVH build measurement, but use separate RT compute and ray-throughput columns.

## GPU Context

AWS rows use the closest single-GPU AWS EC2 instance mapping, Linux On-Demand pricing, and `aws-t4` as the price baseline. `azure-v710` is included as AMD/Azure context for A-app comparisons only; it is not part of the AWS price-normalized ratios below.

| Host | GPU class | Cloud instance used for price/context | Architecture family | RT Core generation | L1 cache (per SM/CU) | L2 cache | L3 / Infinity Cache | RT cores / ray accelerators | Price ($/hr) | Price ratio vs T4 | Benchmark role |
| --- | --- | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `aws-t4` | T4 | `g4dn.xlarge` | Turing | 1st gen | 64 KB | 4 MB | n/a | 40 | 0.5260 | 1.00x | Price baseline. |
| `aws-a10g` | A10G / A10 class | `g5.xlarge` | Ampere | 2nd gen | 128 KB | 6 MB | n/a | 72 | 1.0060 | 1.91x | More RT resources than T4, older than Ada. |
| `aws-l4` | L4 | `g6.xlarge` | Ada Lovelace | 3rd gen | 128 KB | 48 MB | n/a | 58 | 0.8048 | 1.53x | Newer RT cores, smaller server GPU. |
| `aws-l40s` | L40S | `g6e.xlarge` | Ada Lovelace | 3rd gen | 128 KB | 96 MB | n/a | 142 | 1.8610 | 3.54x | Large Ada GPU with much higher RT/SM capacity. |
| `aws-pro6000` | RTX PRO 6000 Blackwell class | `g7e.2xlarge` | Blackwell | 4th gen | 128 KB | 128 MB | n/a | 188 | 3.3631 | 6.39x | Largest and newest GPU in this set. |
| `azure-v710` | Radeon PRO V710 MxGPU | `Standard_NV24ads_V710_v5` (`eastus`) | AMD RDNA 3 (`gfx1101`) | AMD RDNA 3 ray accelerator | 256 KiB graphics L1 | 4 MiB | 54-56 MiB Infinity Cache | 54 | 2.0000 | 3.80x | Azure A-app comparison host; ROCm reports 25.1 GiB visible VRAM and driver 6.16.13. |

L1 cache is reported as the per-SM unified L1/shared-memory block for NVIDIA rows; L2 cache is GPU-wide. Cache and RT-core counts are based on NVIDIA architecture material for Turing, Ampere GA102, Ada, and RTX PRO Blackwell. For `azure-v710`, the Azure VM size, region, ROCm driver, visible VRAM, `gfx1101` target, and 54 CUs were checked on the live host. The V710 architecture and ray-accelerator count are cross-checked against AMD's Radeon PRO V710 specification page. The V710 cache values use ROCm's Radeon PRO GPU hardware specification row: 256 KiB graphics L1 cache, 4 MiB L2 cache, and 56 MiB Infinity Cache. AMD's product page and Azure announcement list 54 MB AMD Infinity Cache Technology, so the table uses `54-56 MiB` for the Infinity Cache column and keeps the conventional L2 value separate.

Turing uses a very fat BVH. You can get from the root node to a triangle node in just three hops. 
The way Nsight Graphics presents the BVH suggests it’s an extremely wide tree. Expanding the top node immediately reveals thousands of bounding boxes, each of which points to a BLAS.
Each BLAS then contains anywhere from a few dozen to thousands of primitives. That makes Nvidia’s implementation far less sensitive to cache and memory latency.
This approach demands a lot more intersection test throughput. That’s actually a wise choice, because GPUs are designed to take advantage of tons of explicit parallelism.
Turing is optimized to take advantage of explicit parallelism in order to hide latency and feed a lot of vector execution units. 

Nvidia’s Pascal architecture supports raytracing, but doesn’t have any specialized hardware to assist with raytracing. Instead, raytracing is done completely with compute shaders, using the same vector ALUs used to do traditional rasterization. 

GPU also has high math throughput and high cache latency. If anything, RT hardware would tilt the balance even further towards a fat BVH, because hardware acceleration for intersection tests would increase math throughput.

RT hardware would cut down on all of these stall reasons. Dedicated intersection test hardware would require fewer instructions to do the same work, reducing instruction footprint and instruction miss.

Increasing intersection test throughput could let Nvidia make the BVH even fatter, reducing its dependency on cache latency.

Ada SM count jumps to 142 from 72.


Price references were checked against public AWS Pricing API mirror pages for `us-east-2`: [`g4dn.xlarge`](https://aws-pricing.com/g4dn.xlarge.html), [`g5.xlarge`](https://aws-pricing.com/g5.xlarge.html), [`g6.xlarge`](https://aws-pricing.com/g6.xlarge.html), [`g6e.xlarge`](https://aws-pricing.com/g6e.xlarge.html), and [`g7e.2xlarge`](https://aws-pricing.com/g7e.2xlarge.html). RT-core counts come from NVIDIA datasheets and architecture material for [T4](https://www.nvidia.com/content/dam/en-zz/Solutions/design-visualization/solutions/resources/documents1/Datasheet_NVIDIA_T4_Virtualization.pdf), [A10](https://www.nvidia.com/content/dam/en-zz/Solutions/Data-Center/a10/pdf/datasheet-new/nvidia-a10-datasheet.pdf), [L4](https://images.nvidia.com/aem-dam/Solutions/Data-Center/l4/nvidia-ada-gpu-architecture-whitepaper-V2.02.pdf), [L40S](https://www.nvidia.com/en-us/data-center/l40s/), and [RTX PRO 6000 Blackwell](https://www.nvidia.com/content/dam/en-zz/Solutions/design-visualization/quadro-product-literature/pdf/NVIDIA-RTX-Blackwell-PRO-GPU-Architecture-v1_1.pdf). Azure context comes from the live `azure-v710` host metadata plus Microsoft's [NVads V710 v5-series](https://learn.microsoft.com/en-us/azure/virtual-machines/sizes/gpu-accelerated/nvadsv710-v5-series) page, AMD's [Radeon PRO V710](https://www.amd.com/en/products/accelerators/radeon-pro/amd-radeon-pro-v710.html) page, and ROCm's [GPU hardware specifications](https://rocm.docs.amd.com/en/latest/reference/gpu-arch-specs.html). The `azure-v710` hourly price uses the provided `$2.00/hr` rate, giving `2.0000 / 0.5260 = 3.80x` versus `aws-t4`.

The architectural distinction that matters most: RT cores accelerate BVH traversal and primitive intersection during the RT launch phase. BVH/GAS construction, ray generation, data loading, sorting, compaction, filtering, reductions, and result copies still run through CUDA cores, memory hierarchy, driver/runtime setup, or host-side code. The benchmark results strongly reflect this split.

### Chips and Cheese Architecture Reading Map

The following Chips and Cheese posts provide architectural context for interpreting RT-core and BVH-traversal results. They are background references for this note, not benchmark inputs.

| Architecture family | Hosts in this note | Chips and Cheese post | RT-core / BVH relevance | How it informs this note |
| --- | --- | --- | --- | --- |
| Turing / pre-RT Pascal comparison | `aws-t4` | [Raytracing on AMD's RDNA 2/3, and Nvidia's Turing and Pascal](https://old.chipsandcheese.com/2023/03/22/raytracing-on-amds-rdna-2-3-and-nvidias-turing-and-pascal/) | Explains BVH traversal concepts, box/leaf nodes, and vendor differences in raytracing acceleration, with Nvidia Turing/Pascal comparison context. | Frames T4 as the first-generation RT-core baseline and explains why BVH structure and traversal behavior matter separately from shader throughput. |
| AMD RDNA 3 | `azure-v710` | [Raytracing on AMD's RDNA 2/3, and Nvidia's Turing and Pascal](https://old.chipsandcheese.com/2023/03/22/raytracing-on-amds-rdna-2-3-and-nvidias-turing-and-pascal/) plus AMD technical material: [RDNA3 ISA Reference Guide](https://docs.amd.com/v/u/en-US/rdna3-shader-instruction-set-architecture-feb-2023_0), [RDNA 3: Beyond the Current Gen](https://gpuopen.com/download/RDNA3_Beyond-the-current-gen-v4.pdf), [Radeon PRO V710](https://www.amd.com/en/products/accelerators/radeon-pro/amd-radeon-pro-v710.html), [AMD V710 on Azure](https://www.amd.com/en/blogs/2024/amd-introduces-the-radeon-pro-v710-to-microsoft-az.html), and [ROCm GPU hardware specifications](https://rocm.docs.amd.com/en/latest/reference/gpu-arch-specs.html). | RDNA 3 uses AMD ray accelerators rather than NVIDIA RT cores. GPUOpen describes RDNA 2/3 ray tracing as shader-based traversal plus an intersection accelerator, and AMD lists 54 ray accelerators on V710. | Frames V710 as the AMD comparison point: cache hierarchy and RT acceleration are not directly equivalent to NVIDIA RT-core generations, so benchmark interpretation should separate AMD ray-accelerator behavior from CUDA/OptiX RT-core behavior. |
| Ampere | `aws-a10g` | [Measuring GPU Memory Latency](https://old.chipsandcheese.com/2021/04/16/measuring-gpu-memory-latency/) and [A New Year and New Tests: GPU L1 Cache Bandwidth](https://old.chipsandcheese.com/2024/01/01/a-new-year-and-new-tests-gpu-l1-cache-bandwidth/) | These are not RT-core-specific posts, but they cover Ampere cache, local/shared-memory, and SM memory behavior. Those paths matter for traversal stacks, ray payloads, and surrounding CUDA work. | Helps explain why A10G can be close to L4 in some rows even though their RT-core generations differ: memory hierarchy, SM count, occupancy, and non-RT work remain important. |
| Ada Lovelace | `aws-l4`, `aws-l40s` | [Nvidia's RTX 4090 Launch: A Strong Ray-Tracing Focus](https://old.chipsandcheese.com/2022/09/22/nvidias-rtx-4090-launch-a-strong-ray-tracing-focus/), [Microbenchmarking Nvidia's RTX 4090](https://chipsandcheese.com/p/microbenchmarking-nvidias-rtx-4090), and [Shader Execution Reordering: Nvidia Tackles Divergence](https://old.chipsandcheese.com/2023/05/16/shader-execution-reordering-nvidia-tackles-divergence/) | Covers Ada's raytracing focus, larger AD102 scale, cache/local-memory improvements, and shader execution reordering as a response to raytracing divergence. | Helps explain why L4 and L40S ray throughput can improve more than BVH build, and why workload divergence and cache behavior can limit scaling even with newer RT cores. |
| Blackwell | `aws-pro6000` | [Blackwell: Nvidia's Massive GPU](https://chipsandcheese.com/p/blackwell-nvidias-massive-gpu) | Discusses GB202 scale and notes that Blackwell doubles per-SM ray-triangle intersection test rate while also supporting opacity micromaps like Ada. | Helps explain why PRO6000 is usually the absolute throughput winner, but not always the price-normalized winner: work distribution, memory behavior, build/setup phases, and non-RT work can become bottlenecks. |

### RT-Core Generation Relationship

The generation trend is incremental rather than a simple "newer is always faster" rule. Each generation improves the fixed-function RT path, but the application still has to feed rays, build or reuse acceleration structures, manage payload code, and avoid divergence or memory bottlenecks.

| Generation | Architecture family | Host examples | What was added or improved | Why it is more advanced than the previous generation | Benchmark interpretation |
| --- | --- | --- | --- | --- | --- |
| 1st gen RT Core | Turing | `aws-t4` | Turing introduced Nvidia's hardware RT-core path for BVH traversal and ray-triangle intersection. The Turing whitepaper describes RT cores as handling BVH traversal and ray-triangle testing after the SM launches a ray probe. Chips and Cheese's Turing/Pascal article also frames the BVH as box nodes plus leaf/triangle nodes. Links: [Turing whitepaper](https://www.nvidia.com/content/dam/en-zz/Solutions/design-visualization/technologies/turing-architecture/NVIDIA-Turing-Architecture-Whitepaper.pdf), [Chips and Cheese Turing/Pascal RT](https://old.chipsandcheese.com/2023/03/22/raytracing-on-amds-rdna-2-3-and-nvidias-turing-and-pascal/). | This is the first dedicated RT hardware baseline. Compared with Pascal-style shader-only traversal, the SM can offload traversal/intersection work to RT hardware. | T4 is the right price/performance baseline because it has real RT cores, but it lacks later improvements in intersection throughput, scheduling support, cache scale, and memory subsystem capacity. |
| AMD RDNA 3 ray accelerator | AMD RDNA 3 | `azure-v710` | V710 exposes 54 RDNA 3 compute units and 54 ray accelerators. AMD's product page identifies the GPU as RDNA 3 with hardware raytracing, and the AMD Azure announcement identifies 54 CUs, 28 GB VRAM, 448 GB/s memory bandwidth, and 54 MB L3 AMD Infinity Cache. ROCm's hardware table identifies V710 as `gfx1101` and lists 256 KiB graphics L1, 4 MiB L2, and 56 MiB Infinity Cache. Links: [Radeon PRO V710](https://www.amd.com/en/products/accelerators/radeon-pro/amd-radeon-pro-v710.html), [AMD V710 on Azure](https://www.amd.com/en/blogs/2024/amd-introduces-the-radeon-pro-v710-to-microsoft-az.html), [Microsoft NVads V710 v5](https://learn.microsoft.com/en-us/azure/virtual-machines/sizes/gpu-accelerated/nvadsv710-v5-series), [ROCm GPU hardware specifications](https://rocm.docs.amd.com/en/latest/reference/gpu-arch-specs.html), [RDNA3 ISA Reference Guide](https://docs.amd.com/v/u/en-US/rdna3-shader-instruction-set-architecture-feb-2023_0), and [RDNA 3: Beyond the Current Gen](https://gpuopen.com/download/RDNA3_Beyond-the-current-gen-v4.pdf). | This row is not part of NVIDIA's numbered RT-core generations. RDNA 3 uses AMD ray accelerators and a different traversal/cache/software stack, so it is an architectural peer comparison rather than a 1st/2nd/3rd/4th-gen NVIDIA RT-core step. | V710 results should be read as AMD RDNA 3 behavior under the Azure/ROCm/HIPRT stack. Its 4 MiB conventional L2 is paired with a much larger Infinity Cache, so direct cache-size comparisons against NVIDIA L2-only rows can be misleading. |
| 2nd gen RT Core | Ampere | `aws-a10g` | Ampere's second-generation RT cores improve ray/triangle intersection throughput and support concurrent ray tracing with shading/compute. NVIDIA describes Ampere RT cores as up to 2x throughput over the previous generation and able to run ray tracing concurrently with shading or denoising. Chips and Cheese's Ampere cache/local-memory posts show why SM/cache behavior still matters around the RT core. Links: [Ampere architecture page](https://www.nvidia.com/en-eu/technologies/ampere-architecture/), [Ampere GA102 whitepaper](https://www.nvidia.com/content/PDF/nvidia-ampere-ga-102-gpu-architecture-whitepaper-v2.1.pdf), [GPU memory latency](https://old.chipsandcheese.com/2021/04/16/measuring-gpu-memory-latency/), [GPU L1 bandwidth](https://old.chipsandcheese.com/2024/01/01/a-new-year-and-new-tests-gpu-l1-cache-bandwidth/). | Ampere improves raw RT throughput and overlap behavior relative to Turing, so the RT phase can become shorter without forcing all shader-side work to wait behind RT traversal. | A10G often gives strong speedup over T4, but it is not always better than L4 because Ada has newer RT cores and a better cache/memory balance even when the GPU is smaller. |
| 3rd gen RT Core | Ada Lovelace | `aws-l4`, `aws-l40s` | Ada adds third-generation RT cores, larger cache-scale improvements, Shader Execution Reordering (SER), and RT-core support blocks such as Opacity Micromap and Displaced Micro-Mesh engines. Chips and Cheese emphasizes Ada's raytracing focus, cache/local-memory improvements, and SER as a response to raytracing divergence. Links: [NVIDIA Ada architecture](https://www.nvidia.com/en-us/geforce/ada-lovelace-architecture/), [Ada whitepaper](https://images.nvidia.com/aem-dam/Solutions/Data-Center/l4/nvidia-ada-gpu-architecture-whitepaper-v2.1.pdf), [RTX 4090 launch RT focus](https://old.chipsandcheese.com/2022/09/22/nvidias-rtx-4090-launch-a-strong-ray-tracing-focus/), [RTX 4090 microbenchmark](https://chipsandcheese.com/p/microbenchmarking-nvidias-rtx-4090), [SER article](https://old.chipsandcheese.com/2023/05/16/shader-execution-reordering-nvidia-tackles-divergence/). | Ada does not just make the RT core faster; it adds mechanisms for denser geometry/alpha-heavy scenes and for reducing divergence costs. It also improves the memory hierarchy that feeds traversal and payload work. | L4 can be price-efficient because it combines newer RT-core behavior with lower hourly price. L40S shows the larger Ada tier: much more RT throughput than L4/A10G, but still not always enough to justify all cost if BVH build/setup dominates. |
| 4th gen RT Core | Blackwell | `aws-pro6000` | Blackwell further scales GB202 and adds fourth-generation RT cores. Chips and Cheese notes Blackwell doubles per-SM ray-triangle intersection test rate while keeping Ada features such as opacity micromaps. NVIDIA's Blackwell architecture material also describes fourth-generation RT cores and doubled ray-triangle intersection testing over Ada. Links: [Chips and Cheese Blackwell](https://chipsandcheese.com/p/blackwell-nvidias-massive-gpu), [NVIDIA RTX Blackwell architecture whitepaper](https://images.nvidia.com/aem-dam/Solutions/geforce/blackwell/nvidia-rtx-blackwell-gpu-architecture.pdf), [NVIDIA RTX PRO Blackwell architecture whitepaper](https://www.nvidia.com/content/dam/en-zz/Solutions/design-visualization/quadro-product-literature/NVIDIA-RTX-Blackwell-PRO-GPU-Architecture-v1.0.pdf). | Blackwell is more advanced than Ada in per-SM triangle intersection throughput and total GPU scale. It is best positioned for ray-heavy workloads that keep the traversal/intersection hardware fed. | PRO6000 is usually the absolute throughput winner, but not always the best price-normalized choice. Once RT launch time shrinks, BVH build, data movement, ray setup, payload code, and output handling can dominate. |

## Method

For each application, rows were matched across the five host result directories by position after verifying equal row counts. RayJoin is represented as two application entries, `RayJoin-LSI` and `RayJoin-PIP`, using their separate RT compute and throughput columns.

For time metrics, speedup is `T4 time / host time`. For throughput, speedup is `host throughput / T4 throughput`.

## Price-Normalized Check

The ratio check uses `aws-t4` as baseline. A value above `1.00` means the measured speedup is at least as large as the price increase over T4 for that application and phase. Rows marked `n/a` did not have a valid timing value on the baseline host or comparison host, usually because that dataset row failed or OOMed. LibRTS is split into point-contains, range-contains, and range-intersects because those are different query workloads.

| Host | Price ratio vs T4 | BVH build apps with median speedup >= price | Ray throughput apps with median speedup >= price | Read |
| --- | ---: | ---: | ---: | --- |
| `aws-a10g` | 1.91x | 9 / 14 | 12 / 14 | Often clears the T4 price ratio for ray throughput, but less consistently for BVH build. |
| `aws-l4` | 1.53x | 9 / 14 | 13 / 14 | The strongest low-cost upgrade over T4 for this suite. |
| `aws-l40s` | 3.54x | 7 / 14 | 11 / 14 | Usually clears the T4 price ratio for ray throughput, especially RT-heavy workloads. |
| `aws-pro6000` | 6.39x | 3 / 14 | 6 / 14 | Fastest absolute GPU, but the price ratio is high enough that it is cost-justified mainly on the most RT-heavy rows. |

### Median Per-Application Price Efficiency

Per-application efficiency ratio is `median speedup vs T4 / price ratio vs T4`. Higher than `1.00` means the price increase is matched by the median phase speedup for that application.

| Application | A10G BVH | A10G rays | L4 BVH | L4 rays | L40S BVH | L40S rays | PRO6000 BVH | PRO6000 rays |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| RayJoin-LSI | 1.44 | 1.26 | 1.26 | 1.25 | 1.23 | 1.72 | 1.24 | 1.10 |
| RayJoin-PIP | 1.44 | 1.08 | 1.26 | 1.16 | 1.23 | 1.52 | 1.24 | 0.99 |
| LibRTS-point-contains | 1.43 | 1.34 | 1.51 | 1.46 | 1.26 | 1.12 | 0.86 | 0.64 |
| LibRTS-range-contains | 1.42 | 1.42 | 1.55 | 1.58 | 1.22 | 1.21 | 0.88 | 0.68 |
| LibRTS-range-intersects | 1.41 | 1.09 | 1.64 | 1.20 | 1.23 | 1.12 | 0.82 | 0.68 |
| X-HD | 0.59 | 0.94 | 0.87 | 1.21 | 0.41 | 0.54 | 0.40 | 0.44 |
| RTTC | 1.51 | 1.97 | 1.91 | 2.13 | 1.26 | 2.24 | 0.65 | 1.57 |
| RTNN | 1.20 | 1.46 | 0.95 | 1.37 | 0.84 | 1.98 | 0.55 | 1.34 |
| RT-DBSCAN | 1.16 | 1.26 | 1.11 | 1.79 | 0.95 | 1.87 | 0.84 | 1.15 |
| RayDB | 1.52 | 1.52 | 1.24 | 1.53 | 1.33 | 1.56 | 1.45 | 0.95 |
| RTOD | 0.60 | 0.68 | 0.86 | 0.86 | 0.43 | 0.52 | 0.21 | 0.25 |
| RTSpMSpM | 0.75 | 1.36 | 1.05 | 1.57 | 0.51 | 0.99 | 0.56 | 0.88 |
| RT-BarnesHut | 0.72 | 1.26 | 0.92 | 3.88 | 0.41 | 4.49 | 0.29 | 3.85 |
| Mochi-DCD | 0.70 | 1.61 | 0.89 | 1.57 | 0.49 | 1.88 | 0.84 | 1.24 |

### Dataset-Level Price Efficiency

The table below uses the same efficiency ratio for every matched dataset/query row instead of only the per-application median.

| Application | Dataset / query | A10G BVH | A10G rays | L4 BVH | L4 rays | L40S BVH | L40S rays | PRO6000 BVH | PRO6000 rays |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| RayJoin-LSI | Aquifers / County | 1.38 | 1.48 | 1.34 | 1.64 | 1.17 | 1.50 | 0.98 | 0.67 |
| RayJoin-LSI | Park / ZIPCode | 1.46 | 1.64 | 1.31 | 1.69 | 1.24 | 2.28 | 1.24 | 1.51 |
| RayJoin-LSI | Block / Water | 1.39 | 1.15 | 1.20 | 1.17 | 1.20 | 1.62 | 1.23 | 1.06 |
| RayJoin-LSI | Block / Aquifers | 1.65 | 1.99 | 1.46 | 1.95 | 1.44 | 2.78 | 1.43 | 1.86 |
| RayJoin-LSI | Water / Aquifers | 1.45 | 1.36 | 1.26 | 1.44 | 1.25 | 1.89 | 1.22 | 1.27 |
| RayJoin-LSI | Block / County | 1.44 | 1.16 | 1.26 | 1.22 | 1.23 | 1.63 | 1.22 | 1.10 |
| RayJoin-LSI | Water / County | 1.46 | 1.23 | 1.28 | 1.25 | 1.26 | 1.72 | 1.25 | 1.15 |
| RayJoin-LSI | Block / Park | 1.42 | 1.26 | 1.26 | 1.25 | 1.22 | 1.72 | 1.23 | 1.07 |
| RayJoin-LSI | Water / Park | 1.51 | 1.85 | 1.34 | 1.85 | 1.31 | 2.59 | 1.30 | 1.68 |
| RayJoin-LSI | Block / ZIPCode | 1.40 | 1.14 | 1.24 | 1.20 | 1.21 | 1.60 | 1.25 | 1.06 |
| RayJoin-LSI | Water / ZIPCode | 1.42 | 1.15 | 1.24 | 1.14 | 1.23 | 1.61 | 1.26 | 1.08 |
| RayJoin-PIP | Aquifers / County | 1.38 | 1.69 | 1.34 | 1.82 | 1.17 | 2.28 | 0.98 | 1.42 |
| RayJoin-PIP | Park / ZIPCode | 1.46 | 1.21 | 1.31 | 1.29 | 1.24 | 1.69 | 1.24 | 1.07 |
| RayJoin-PIP | Block / Water | 1.39 | 1.07 | 1.20 | 1.14 | 1.20 | 1.50 | 1.23 | 0.96 |
| RayJoin-PIP | Block / Aquifers | 1.65 | 1.20 | 1.46 | 1.26 | 1.44 | 1.66 | 1.43 | 1.06 |
| RayJoin-PIP | Water / Aquifers | 1.45 | 1.11 | 1.26 | 1.19 | 1.25 | 1.54 | 1.22 | 1.00 |
| RayJoin-PIP | Block / County | 1.44 | 1.07 | 1.26 | 1.15 | 1.23 | 1.50 | 1.22 | 0.99 |
| RayJoin-PIP | Water / County | 1.46 | 1.08 | 1.28 | 1.16 | 1.26 | 1.51 | 1.25 | 0.96 |
| RayJoin-PIP | Block / Park | 1.42 | 1.17 | 1.26 | 1.25 | 1.22 | 1.64 | 1.23 | 1.04 |
| RayJoin-PIP | Water / Park | 1.51 | 1.08 | 1.34 | 1.15 | 1.31 | 1.50 | 1.30 | 0.95 |
| RayJoin-PIP | Block / ZIPCode | 1.40 | 1.07 | 1.24 | 1.14 | 1.21 | 1.50 | 1.25 | 0.96 |
| RayJoin-PIP | Water / ZIPCode | 1.42 | 1.08 | 1.24 | 1.16 | 1.23 | 1.52 | 1.26 | 0.97 |
| LibRTS-point-contains | County | 1.06 | 1.38 | 1.53 | 1.61 | 0.76 | 1.00 | 0.36 | 0.64 |
| LibRTS-point-contains | Block | 1.52 | 1.32 | 1.94 | 1.55 | 1.29 | 0.99 | 0.68 | 0.64 |
| LibRTS-point-contains | Water | 1.44 | 1.36 | 1.96 | 1.90 | 1.50 | 1.27 | 0.73 | 0.65 |
| LibRTS-point-contains | EuropePark | 1.42 | 1.28 | 1.48 | 1.30 | 1.64 | 1.16 | 1.06 | 0.59 |
| LibRTS-point-contains | Lake | 1.43 | 1.42 | 1.10 | 1.38 | 1.20 | 1.28 | 0.99 | 0.68 |
| LibRTS-point-contains | Park | 1.49 | 1.26 | 1.10 | 1.17 | 1.22 | 1.08 | 1.01 | 0.60 |
| LibRTS-range-contains | County | 1.17 | 1.44 | 1.70 | 1.68 | 0.84 | 1.17 | 0.40 | 0.67 |
| LibRTS-range-contains | Block | 1.26 | 1.21 | 1.65 | 1.41 | 1.09 | 0.87 | 0.58 | 0.62 |
| LibRTS-range-contains | Water | 1.49 | 1.54 | 2.05 | 2.06 | 1.53 | 1.36 | 0.78 | 0.87 |
| LibRTS-range-contains | EuropePark | 1.40 | 1.40 | 1.46 | 1.53 | 1.63 | 1.24 | 1.03 | 0.62 |
| LibRTS-range-contains | Lake | 1.44 | 1.51 | 1.11 | 1.63 | 1.21 | 1.41 | 0.99 | 0.79 |
| LibRTS-range-contains | Park | 1.50 | 1.29 | 1.12 | 1.22 | 1.23 | 1.17 | 1.02 | 0.70 |
| LibRTS-range-intersects | County | 1.25 | 1.34 | 1.81 | 1.89 | 0.89 | 1.00 | 0.42 | 0.46 |
| LibRTS-range-intersects | Block | 1.39 | 1.35 | 1.84 | 1.67 | 1.23 | 1.42 | 0.64 | 0.74 |
| LibRTS-range-intersects | Water | 1.28 | 1.30 | 1.78 | 1.47 | 1.32 | 1.47 | 0.65 | 0.82 |
| LibRTS-range-intersects | EuropePark | 1.44 | 0.83 | 1.51 | 0.86 | 1.67 | 1.06 | 1.08 | 0.63 |
| LibRTS-range-intersects | Lake | 1.44 | 0.89 | 1.11 | 0.92 | 1.21 | 1.16 | 0.99 | 0.71 |
| LibRTS-range-intersects | Park | 1.49 | 0.82 | 1.10 | 0.86 | 1.23 | 1.08 | 1.01 | 0.65 |
| X-HD | geospatial / County / ZIPCode | 1.55 | 1.53 | 2.40 | 1.72 | 1.65 | 1.35 | 0.97 | 0.89 |
| X-HD | geospatial / Water / Block | 1.12 | 1.39 | 1.61 | 1.72 | 0.97 | 1.32 | 0.61 | 0.82 |
| X-HD | geospatial / Lake / Park | 0.35 | 0.94 | 0.85 | 1.21 | 0.17 | 1.21 | 0.40 | 0.70 |
| X-HD | graphics / Dragon / AsianDragon | 0.59 | 0.43 | 0.80 | 0.88 | 0.40 | 0.41 | 0.20 | 0.26 |
| X-HD | graphics / Dragon / Buddha | 0.55 | 0.40 | 0.86 | 0.78 | 0.38 | 0.19 | 0.21 | 0.14 |
| X-HD | graphics / Thai / AsianDragon | 1.20 | 0.99 | 1.75 | 1.71 | 0.84 | 0.54 | 0.43 | 0.44 |
| X-HD | graphics / Thai / Buddha | 0.53 | 0.77 | 0.87 | 1.01 | 0.41 | 0.53 | 0.20 | 0.38 |
| RTTC | DBLP | 1.51 | 1.97 | 2.08 | 2.13 | 1.26 | 2.24 | 0.65 | 1.57 |
| RTTC | YouTube | 1.57 | 2.48 | 1.91 | 2.62 | 1.31 | 3.26 | 0.70 | 2.06 |
| RTTC | Patents | 1.36 | 2.70 | 1.41 | 2.83 | 0.97 | 3.58 | 0.64 | 2.26 |
| RTTC | WikiTalk | 1.62 | 1.42 | 1.93 | 1.52 | 1.37 | 1.92 | 0.75 | 1.22 |
| RTTC | LiveJournal | 1.37 | 1.59 | 1.37 | 1.44 | 0.95 | 2.13 | 0.63 | 1.34 |
| RTNN | Model / Bunny | 0.64 | 0.45 | 0.69 | 0.92 | 0.31 | 0.65 | 0.16 | 0.29 |
| RTNN | Model / Dragon | 0.71 | 0.68 | 0.86 | 1.02 | 0.32 | 0.54 | 0.26 | 0.27 |
| RTNN | Model / Happy | 0.61 | 0.50 | 0.71 | 0.76 | 0.45 | 0.42 | 0.34 | 0.27 |
| RTNN | NBody / NBody6M | 1.27 | 1.67 | 1.13 | 1.57 | 1.06 | 2.24 | 0.51 | 1.41 |
| RTNN | NBody / NBody11M | 1.23 | 1.58 | 0.98 | 1.45 | 0.95 | 2.16 | 0.59 | 1.41 |
| RTNN | NBody / NBody16M | 1.33 | 1.54 | 1.04 | 1.40 | 1.04 | 2.09 | 0.66 | 1.39 |
| RTNN | NBody / NBody21M | 1.38 | 1.48 | 1.07 | 1.34 | 1.13 | 2.03 | 0.75 | 1.36 |
| RTNN | NBody / NBody25M | 1.41 | 1.41 | 1.10 | 1.34 | 1.10 | 1.94 | 0.76 | 1.32 |
| RTNN | KITTI / KITTI0048 | 0.64 | 1.44 | 0.73 | 2.11 | 0.40 | 1.61 | 0.50 | 0.87 |
| RTNN | KITTI / KITTI0026 | 1.17 | 1.77 | 0.91 | 2.14 | 0.73 | 3.60 | 0.70 | 2.00 |
| RTNN | KITTI / KITTI0096 | n/a | n/a | n/a | n/a | n/a | n/a | n/a | n/a |
| RTNN | KITTI / KITTI0071 | n/a | n/a | n/a | n/a | n/a | n/a | n/a | n/a |
| RT-DBSCAN | 3DRoad | 0.83 | 1.87 | 1.15 | 1.79 | 0.56 | 1.87 | 0.61 | 1.15 |
| RT-DBSCAN | NGSIM | 1.24 | 1.21 | 1.03 | 0.96 | 0.95 | 1.03 | 0.84 | 0.77 |
| RT-DBSCAN | 3DIono | 1.16 | 1.26 | 1.11 | 3.43 | 1.00 | 2.80 | 0.95 | 2.24 |
| RayDB | Figure 12(c) / q11 / Q1 / q1dot1 | 1.51 | 0.62 | 1.12 | 0.88 | 1.20 | 1.11 | 1.33 | 0.80 |
| RayDB | Figure 12(c) / q12 / Q1 / q1dot2 | 1.51 | 0.74 | 1.23 | 1.85 | 1.30 | 1.29 | 1.45 | 0.74 |
| RayDB | Figure 12(c) / q13 / Q1 / q1dot3 | 1.52 | 0.93 | 1.25 | 1.53 | 1.33 | 0.95 | 1.48 | 0.59 |
| RayDB | Figure 12(c) / q21 / Q2 / q2dot1 | 1.48 | 1.67 | 1.27 | 2.34 | 1.32 | 3.05 | 1.42 | 2.09 |
| RayDB | Figure 12(c) / q22 / Q2 / q2dot2 | 1.53 | 1.56 | 1.22 | 2.09 | 1.33 | 2.39 | 1.42 | 1.51 |
| RayDB | Figure 12(c) / q23 / Q2 / q2dot3 | 1.51 | 1.41 | 1.23 | 1.34 | 1.32 | 1.57 | 1.42 | 0.91 |
| RayDB | Figure 12(c) / q31 / Q3 / q3dot1 | 1.55 | 1.84 | 1.25 | 3.06 | 1.36 | 4.17 | 1.47 | 3.39 |
| RayDB | Figure 12(c) / q32 / Q3 / q3dot2 | 1.53 | 1.78 | 1.24 | 1.76 | 1.35 | 2.05 | 1.45 | 1.42 |
| RayDB | Figure 12(c) / q33 / Q3 / q3dot3 | 1.54 | 1.30 | 1.22 | 1.47 | 1.32 | 1.00 | 1.42 | 0.66 |
| RayDB | Figure 12(c) / q34 / Q3 / q3dot4 | 1.55 | 1.05 | 1.28 | 1.24 | 1.39 | 0.79 | 1.52 | 0.42 |
| RayDB | Figure 12(c) / q41 / Q4 / q4dot1 | 1.53 | 2.47 | 1.24 | 2.44 | 1.35 | 3.19 | 1.45 | 2.65 |
| RayDB | Figure 12(c) / q42 / Q4 / q4dot2 | 1.52 | 1.52 | 1.25 | 1.28 | 1.33 | 1.56 | 1.44 | 1.22 |
| RayDB | Figure 12(c) / q43 / Q4 / q4dot3 | 1.50 | 1.52 | 1.27 | 1.00 | 1.35 | 1.24 | 1.47 | 0.95 |
| RTOD | Gaussian | 0.62 | 0.81 | 0.89 | 0.93 | 0.44 | 0.81 | 0.21 | 0.49 |
| RTOD | Stock | 0.60 | 0.68 | 0.86 | 0.86 | 0.43 | 0.52 | 0.20 | 0.25 |
| RTOD | TAO | 0.60 | 0.60 | 0.86 | 0.85 | 0.43 | 0.44 | 0.21 | 0.21 |
| RTSpMSpM | p2p-Gnutella31_small | 0.76 | 1.37 | 0.99 | 1.59 | 0.30 | 0.90 | 2.83 | 0.71 |
| RTSpMSpM | roadNet-CA_small | 0.69 | 1.33 | 0.99 | 1.31 | 0.48 | 0.88 | 0.44 | 0.84 |
| RTSpMSpM | webbase-1M_small | 0.74 | 0.93 | 1.05 | 1.28 | 0.50 | 0.67 | 0.50 | 0.32 |
| RTSpMSpM | mario002_small | 0.67 | 1.35 | 0.99 | 1.30 | 0.45 | 0.94 | 0.46 | 0.80 |
| RTSpMSpM | web-Google_small | 0.51 | 0.85 | 0.71 | 1.29 | 0.31 | 0.60 | 0.47 | 0.68 |
| RTSpMSpM | scircuit_small | 0.73 | 0.89 | 1.06 | 1.16 | 0.53 | 0.71 | 0.51 | 0.45 |
| RTSpMSpM | amazon0312_small | 0.55 | 1.11 | 0.77 | 1.15 | 0.37 | 0.90 | 0.36 | 0.85 |
| RTSpMSpM | ca-CondMat | 0.59 | 0.94 | 0.89 | 1.19 | 0.39 | 0.77 | 0.44 | 0.91 |
| RTSpMSpM | email-Enron | 0.85 | 1.55 | 1.21 | 1.94 | 0.60 | 1.60 | 0.61 | 1.33 |
| RTSpMSpM | wiki-Vote | 0.63 | 1.11 | 0.94 | 1.75 | 0.41 | 1.05 | 0.41 | 0.52 |
| RTSpMSpM | cage12_small | 0.98 | 1.97 | 1.42 | 1.91 | 0.74 | 1.51 | 0.79 | 1.75 |
| RTSpMSpM | 2cubes_sphere_small | 0.81 | 1.56 | 1.20 | 1.63 | 0.64 | 1.74 | 0.63 | 1.29 |
| RTSpMSpM | offshore_small | 0.81 | 1.47 | 1.12 | 1.54 | 0.63 | 1.62 | 0.65 | 1.32 |
| RTSpMSpM | cop20k_A_small | 0.81 | 1.65 | 1.18 | 1.86 | 0.62 | 1.72 | 0.61 | 1.38 |
| RTSpMSpM | filter3D_small | 0.81 | 1.74 | 1.14 | 2.20 | 0.67 | 2.36 | 0.68 | 1.58 |
| RTSpMSpM | poisson3Da | 0.93 | 1.95 | 1.34 | 2.09 | 0.72 | 2.01 | 0.75 | 1.75 |
| RT-BarnesHut | synthetic-10M | 0.61 | 1.26 | 0.84 | 3.86 | 0.36 | 4.45 | 0.31 | 3.75 |
| RT-BarnesHut | synthetic-25M | 0.72 | 1.26 | 0.92 | 3.77 | 0.41 | 4.44 | 0.31 | 3.80 |
| RT-BarnesHut | synthetic-100M | 0.74 | 1.27 | 0.94 | 3.90 | 0.42 | 4.53 | 0.28 | 3.97 |
| RT-BarnesHut | dwarf-4M | 0.66 | 1.31 | 0.90 | 4.10 | 0.39 | 4.65 | 0.40 | 3.90 |
| RT-BarnesHut | dwarf-50M | 0.72 | 1.21 | 0.92 | 4.07 | 0.41 | 4.58 | 0.28 | 4.07 |
| RT-BarnesHut | lambb-80M | 0.72 | 1.22 | 0.92 | 3.60 | 0.41 | 4.29 | 0.27 | 3.70 |
| Mochi-DCD | FirstDataset / freefall-5M-r0.0005-0.0006 / freefall | 0.84 | 1.52 | 0.88 | 1.46 | 0.48 | 1.91 | 0.73 | 1.25 |
| Mochi-DCD | FirstDataset / freefall-5M-r0.0005-0.0006 / rotating_gravity | 0.88 | 1.88 | 0.87 | 1.62 | 0.54 | 2.11 | 0.88 | 1.43 |
| Mochi-DCD | SecondDataset / freefall-1M-r0.0005-0.0006 / freefall | 0.67 | 1.54 | 0.89 | 1.53 | 0.45 | 1.78 | 0.87 | 1.21 |
| Mochi-DCD | SecondDataset / freefall-1M-r0.0005-0.0006 / rotating_gravity | 0.67 | 1.60 | 0.93 | 1.62 | 0.50 | 1.81 | 0.84 | 1.23 |
| Mochi-DCD | SecondDataset / freefall-1M-r0.0005-0.006 / freefall | 0.65 | 1.52 | 0.85 | 1.50 | 0.44 | 1.77 | 0.81 | 1.15 |
| Mochi-DCD | SecondDataset / freefall-1M-r0.0005-0.006 / rotating_gravity | 0.69 | 1.64 | 0.94 | 1.63 | 0.52 | 1.85 | 0.84 | 1.23 |
| Mochi-DCD | SecondDataset / freefall-1M-r0.0005-0.06 / freefall | 0.71 | 1.61 | 0.88 | 1.53 | 0.48 | 1.92 | 0.73 | 1.35 |
| Mochi-DCD | SecondDataset / freefall-1M-r0.0005-0.06 / rotating_gravity | 0.76 | 1.70 | 0.98 | 1.60 | 0.58 | 2.02 | 0.83 | 1.38 |

The important result is not the cross-application median. It is where the price ratio is beaten dataset by dataset. With T4 as the price baseline, L4 is the most broadly price-efficient low-cost upgrade, while L40S is frequently justified for ray-throughput-heavy rows. PRO6000 is the absolute fastest, but its 6.39x price ratio over T4 means it is cost-justified mainly for very RT-heavy rows such as RT-BarnesHut, RTTC, RayDB, and Mochi-DCD ray throughput rather than as a universal price/performance upgrade.

## Per-Application Phase Speedups

All values are median speedups over T4. Higher is better. LibRTS is split by query type.

| Application | Rows | Metric | A10G | L4 | L40S | PRO6000 |
| --- | ---: | --- | ---: | ---: | ---: | ---: |
| RayJoin-LSI | 11 | BVH build | 2.74x | 1.93x | 4.35x | 7.92x |
| RayJoin-LSI | 11 | Ray throughput | 2.41x | 1.92x | 6.08x | 7.04x |
| RayJoin-PIP | 11 | BVH build | 2.74x | 1.93x | 4.35x | 7.92x |
| RayJoin-PIP | 11 | Ray throughput | 2.06x | 1.77x | 5.38x | 6.32x |
| LibRTS-point-contains | 6 | BVH build | 2.74x | 2.31x | 4.45x | 5.49x |
| LibRTS-point-contains | 6 | Ray throughput | 2.56x | 2.24x | 3.96x | 4.10x |
| LibRTS-range-contains | 6 | BVH build | 2.71x | 2.38x | 4.33x | 5.65x |
| LibRTS-range-contains | 6 | Ray throughput | 2.71x | 2.42x | 4.27x | 4.36x |
| LibRTS-range-intersects | 6 | BVH build | 2.70x | 2.51x | 4.35x | 5.24x |
| LibRTS-range-intersects | 6 | Ray throughput | 2.09x | 1.83x | 3.97x | 4.35x |
| X-HD | 7 | BVH build | 1.12x | 1.33x | 1.47x | 2.56x |
| X-HD | 7 | Ray throughput | 1.79x | 1.85x | 1.92x | 2.79x |
| RTTC | 5 | BVH build | 2.88x | 2.92x | 4.47x | 4.18x |
| RTTC | 5 | Ray throughput | 3.76x | 3.25x | 7.92x | 10.05x |
| RTNN | 12 | BVH build | 2.29x | 1.45x | 2.97x | 3.52x |
| RTNN | 12 | Ray throughput | 2.79x | 2.10x | 7.01x | 8.58x |
| RT-DBSCAN | 3 | BVH build | 2.22x | 1.70x | 3.35x | 5.36x |
| RT-DBSCAN | 3 | Ray throughput | 2.41x | 2.74x | 6.62x | 7.36x |
| RayDB | 13 | BVH build | 2.91x | 1.90x | 4.71x | 9.28x |
| RayDB | 13 | Ray throughput | 2.90x | 2.34x | 5.51x | 6.06x |
| RTOD | 3 | BVH build | 1.15x | 1.32x | 1.51x | 1.33x |
| RTOD | 3 | Ray throughput | 1.31x | 1.32x | 1.85x | 1.61x |
| RTSpMSpM | 16 | BVH build | 1.44x | 1.61x | 1.81x | 3.59x |
| RTSpMSpM | 16 | Ray throughput | 2.60x | 2.40x | 3.52x | 5.63x |
| RT-BarnesHut | 6 | BVH build | 1.37x | 1.40x | 1.45x | 1.88x |
| RT-BarnesHut | 6 | Ray throughput | 2.41x | 5.93x | 15.89x | 24.62x |
| Mochi-DCD | 8 | BVH build | 1.34x | 1.35x | 1.73x | 5.35x |
| Mochi-DCD | 8 | Ray throughput | 3.07x | 2.40x | 6.65x | 7.94x |

## Architecture Insights

### Ray throughput scales more like RT hardware than BVH build does

This is the expected architectural split. RT traversal/intersection benefits directly from newer and more numerous RT cores. BVH/GAS construction is more dependent on CUDA-side parallel build kernels, memory bandwidth, allocation behavior, and OptiX build implementation. It improves on larger GPUs, but it is not the same scaling path as RT traversal.

Ray throughput is the clearest architecture-facing metric here because the number of rays per matched row is fixed. When throughput improves by 6x, the same ray workload completed in about one sixth of the RT launch time.

The best throughput signals are:

- RT-BarnesHut: PRO6000 reaches 24.71x T4 throughput.
- RTTC: PRO6000 reaches 10.50x T4 throughput.
- Mochi-DCD: PRO6000 reaches 8.16x T4 throughput.
- RT-DBSCAN: PRO6000 reaches 8.05x T4 throughput.
- RayJoin-LSI reaches 7.59x and RayJoin-PIP reaches 6.58x on PRO6000; RayDB reaches 7.13x.

### A10G and L4 are close overall

A10G and L4 are the middle-tier comparison. A10G often has more raw RT/SM resources; L4 has newer Ada-generation RT cores and a newer memory/cache design. Their application-level throughput results are mixed: A10G is better on RayJoin-LSI, RayJoin-PIP, the three LibRTS query groups, RTTC, RTNN, RayDB, and Mochi-DCD; L4 is better on X-HD, RT-DBSCAN, RTOD, RTSpMSpM, and especially RT-BarnesHut. This means RT Core generation alone is not enough to predict performance; RT-core count, SM count, memory bandwidth, clocks, and workload structure all matter.

### L40S is the first clearly large RT-core tier

L40S separates strongly from A10G/L4 in ray throughput. Relative to T4 pricing, it clears its price ratio for most ray-throughput-heavy workloads.

For many workloads, L40S is the point where there are enough Ada RT resources to expose strong RT scaling without the additional Blackwell capacity of PRO6000.

### PRO6000 is fastest, but not always by its raw hardware ratio

PRO6000 is usually the fastest host in absolute throughput, but it is not uniformly far ahead of L40S. For example:

- LibRTS query groups: PRO6000 and L40S are close in ray throughput, with median PRO6000 speedups of 4.10x to 4.36x versus L40S speedups of 3.96x to 4.27x.
- RTNN ray throughput: 5.39x vs T4 on PRO6000, 5.03x on L40S.
- RayJoin-LSI ray throughput: 7.59x vs T4 on PRO6000, 6.59x on L40S.
- RayJoin-PIP ray throughput: 6.58x vs T4 on PRO6000, 5.70x on L40S.
- Mochi-DCD ray throughput: 8.16x vs T4 on PRO6000, 6.70x on L40S.

The reason is architectural saturation. Once traversal becomes short, the limiting work shifts to ray setup, payload code, memory traffic, output writes, host/runtime overhead, or the acceleration-structure build. Additional RT cores cannot improve those phases directly.

### BVH build speedup is workload-specific and less generational

BVH build speedups vary more irregularly than ray-throughput speedups:

- RT-BarnesHut build barely scales: PRO6000 is only 1.95x over T4 while ray throughput is 24.71x.
- RTOD build barely scales: PRO6000 is 1.32x over T4 while ray throughput is 1.89x.
- RayDB build scales strongly: PRO6000 is 9.22x over T4.
- RayJoin build also scales strongly: PRO6000 is 7.88x over T4. This build value is shared by RayJoin-LSI and RayJoin-PIP because they use the same index construction.

This suggests different build workloads stress different parts of the system. Small or low-complexity AABB sets are dominated by fixed overhead. Large or irregular builds benefit more from memory bandwidth, parallelism, and newer GPU-side build implementation.

### The RT launch to BVH build ratio decides whether RT cores dominate

Median `rt_compute_ms / bvh_build_ms` gives a useful architectural classification:

| Application | T4 median RT/build ratio | PRO6000 median RT/build ratio | Interpretation |
| --- | ---: | ---: | --- |
| RT-BarnesHut | 144.53 | 10.37 | RT traversal dominates on T4 and remains important on PRO6000. Strong RT-core benchmark. |
| X-HD | 21.74 | 16.21 | RT phase remains large relative to build, but non-RT CUDA phases also matter. |
| RayJoin-LSI | 0.83 | 0.83 | LSI RT traversal is material, but build is still a large part of the pipeline. |
| RayJoin-PIP | 1.61 | 1.86 | PIP has more RT work relative to the shared build than LSI. |
| RT-DBSCAN | 1.44 | 0.61 | PRO6000 makes RT traversal short enough that build/setup becomes more visible. |
| RTOD | 1.25 | 0.59 | Weak RT-scaling signal; small per-slide overheads matter. |
| RTSpMSpM | 0.79 | 0.41 | BVH build and sparse workflow overhead can dominate over RT traversal. |
| RTNN | 0.76 | 1.74 | RT phase remains material, but build and OptiX setup are also important. |
| Mochi-DCD | 0.33 | 0.19 | BVH build/update is a major bottleneck. |
| RTTC | 0.30 | 0.13 | Ray generation and build dominate more than the RT triangle-count phase. |
| LibRTS query groups | 0.06 | 0.06 | Per-query RT phase is small relative to build for these rows. |
| RayDB | 0.001 | 0.001 | RT launch is tiny relative to build/data loading in the measured pipeline. |

This table explains why reporting only end-to-end time is misleading. A GPU can deliver excellent RT throughput while the total application remains limited by build or data movement.

## Application Insights

### RayJoin-LSI

RayJoin-LSI casts one ray per line segment to find line-segment intersections against the other map. PRO6000 improves the shared BVH build by 7.88x and the LSI ray throughput by 7.59x over T4. L40S is also strong at 6.59x.

Architectural implication: LSI is a good RT traversal workload, but its median RT/build ratio is only about 0.83 on both T4 and PRO6000. That means shared index construction is at least as important as traversal for this phase. Reusing the RayJoin BVH across LSI and PIP is important for end-to-end efficiency.

### RayJoin-PIP

RayJoin-PIP casts rays for point-in-polygon location. PRO6000 improves the shared BVH build by 7.88x and PIP ray throughput by 6.58x over T4. PIP scales slightly less than LSI in ray throughput, but has a larger RT/build ratio: 1.61 on T4 and 1.86 on PRO6000.

Architectural implication: PIP is more RT-phase-heavy than LSI relative to the shared build, so it exposes RT throughput more directly once the BVH is already built. The lower raw RT speedup compared with LSI suggests more payload/control-flow or point-query overhead in the PIP kernel.

### LibRTS Query Groups

LibRTS is split into point-contains, range-contains, and range-intersects. All three improve consistently but not dramatically on the high-end GPUs. PRO6000 gives 5.49x, 5.65x, and 5.24x median BVH-build speedups for the three groups, while median ray-throughput speedups are 4.10x, 4.36x, and 4.35x over T4. The median RT/build ratio is only about 0.06 on both T4 and PRO6000, so the measured query RT launch is much smaller than the geometry build in these runs.

Architectural implication: the LibRTS query groups are not purely RT-core-bound. Reusing BVHs across many queries is important; otherwise build amortization dominates the benefit of faster RT traversal.

### X-HD

X-HD has modest RT scaling: PRO6000 is 2.81x over T4 in ray throughput. Build scaling is also modest at 2.35x. Its RT/build ratio is high, but the broader X-HD pipeline includes CUDA and adjustment phases that limit architectural interpretation.

Architectural implication: X-HD is a mixed GPU workload. RT cores help, but CUDA-side nearest-neighbor/grid logic and BVH adjustment remain important.

### RTTC

RTTC has excellent ray-throughput scaling: PRO6000 is 10.50x over T4. BVH build is only 4.31x faster, and the RT/build ratio falls from 0.30 on T4 to 0.13 on PRO6000.

Architectural implication: the RT triangle-count phase maps well to RT cores, but the application is increasingly dominated by ray generation, graph conversion, and build work on faster GPUs. RTTC is a strong phase-level RT example but a weaker end-to-end RT-core benchmark.

### RTNN

RTNN shows healthy ray-throughput scaling: PRO6000 is 5.39x over T4 and L40S is 5.03x. BVH build improves less, at 3.03x on PRO6000.

Architectural implication: RTNN benefits from newer RT cores, but build, sorting, query preparation, and OptiX setup remain relevant. PRO6000 and L40S being close suggests this benchmark can become limited by non-traversal work once RT traversal is accelerated.

### RT-DBSCAN

RT-DBSCAN scales well in ray throughput: PRO6000 is 8.05x and L40S is 6.20x over T4. Build scaling is weaker: 5.02x and 2.87x respectively.

Architectural implication: point-neighborhood traversal is a good RT-core target, but the cluster construction and build/setup path still shape end-to-end performance. The small number of result rows also means per-dataset effects can be large.

### RayDB

RayDB has strong build and ray-throughput speedups: PRO6000 is 9.22x faster for BVH build and 7.13x faster for ray throughput. However, the RT/build ratio is extremely small, around 0.001.

Architectural implication: the measured OptiX launch is very fast relative to data loading, predicate expansion, and acceleration-structure management. RayDB proves the RT launch can be accelerated, but the application architecture must reduce data movement and setup overhead to expose RT Core throughput end-to-end.

### RTOD

RTOD is the weakest RT-core scaling signal in this set. PRO6000 is only 1.89x over T4 in ray throughput, and L40S is slightly better at 2.03x. BVH build scaling is also low.

Architectural implication: RTOD appears limited by small per-slide work, update overhead, data transfer, or synchronization rather than raw RT traversal. It is not a clean benchmark for RT-core generation comparisons.

### RTSpMSpM

RTSpMSpM has good ray-throughput scaling but weak build scaling. PRO6000 is 5.91x over T4 in ray throughput but only 3.83x in BVH build, and the RT/build ratio falls on faster GPUs.

Architectural implication: RT cores can accelerate sparse nonzero intersection, but sparse matrix setup, dense result handling, and build overhead can dominate. This application needs algorithmic pipeline work to exploit high-end RT hardware fully.

### RT-BarnesHut

RT-BarnesHut is the clearest RT-core scaling benchmark. PRO6000 reaches 24.71x T4 ray-throughput speedup, and L40S reaches 15.88x. BVH build barely scales by comparison: only 1.95x on PRO6000.

Architectural implication: the core Barnes-Hut traversal is highly RT-bound and maps very well to newer/larger RT hardware. This benchmark best demonstrates the difference between RT Core generations and GPU tiers.

### Mochi-DCD

Mochi-DCD shows strong ray-throughput scaling: PRO6000 is 8.16x over T4, L40S is 6.70x, and A10G is 3.10x. Build scaling is weaker except on PRO6000.

Architectural implication: collision detection traversal benefits from RT cores, but dynamic particle workloads spend substantial time building/updating acceleration structures. On faster GPUs, BVH build/update becomes the main optimization target.

## Architectural Conclusions

1. RT cores provide clear value for non-graphics workloads that can be expressed as BVH traversal and intersection.
2. Phase-level timing is necessary. End-to-end time can hide strong RT throughput when build, setup, or I/O dominates.
3. BVH build and RT traversal are separate architectural paths. Build scales with memory, SM-side work, and OptiX build behavior; traversal scales more directly with RT cores.
4. A10G and L4 are close overall: more older RT resources and fewer newer RT resources produce similar aggregate RT throughput on this suite.
5. L40S is the first large jump in RT throughput because it combines Ada RT cores with a much larger GPU.
6. PRO6000 is the fastest overall, especially on RT-BarnesHut, RTTC, Mochi-DCD, RT-DBSCAN, RayJoin-LSI, RayJoin-PIP, and RayDB, but many applications are already bottlenecked outside RT traversal before they can fully exploit the extra hardware.
7. Future optimization should target BVH reuse/refit, batched query execution, reduced host/device transfers, and better separation of build/setup/RT/output phases in scripts and CSVs.
