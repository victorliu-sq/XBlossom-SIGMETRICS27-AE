# Slide Talking Points

## Reviewer-Driven Additions to the Evaluation

### Slide 1: Fair Cross-Platform Comparison

- Address the reviewer concern that the original comparison did not fully separate CPU and GPU platform effects.
- Add experiments on a desktop/server GPU platform and a high-end CPU platform.
- Use the CPU platform to represent CPU execution behavior and the GPU platform to represent accelerated execution behavior.
- Make clear that the goal is not to claim identical hardware, but to compare each implementation on the platform it is designed for.

### Slide 2: Why These Platforms Are Appropriate

| `m7i.metal-24xl` CPU platform | `g7e.8xlarge` GPU platform |
| --- | --- |
| **CPU cores:** 48 physical cores / 96 vCPUs | **CUDA cores:** 24,064 CUDA cores on 1 NVIDIA RTX PRO 6000 Blackwell Server Edition GPU |
| **CPU used by instance:** 4th Gen Intel Xeon Scalable, AWS-custom Intel processor | **GPU used by instance:** 1 NVIDIA RTX PRO 6000 Blackwell Server Edition GPU, 96 GiB GPU memory |
| **Instance price:** about `$4.8384/hour` | **Instance price:** about `$5.2682/hour` |

CPU platform detail:

| Local CPU platform | `aws-cpu` platform |
| --- | --- |
| **CPU model:** Intel Core i9-14900HX | **CPU model:** Intel Xeon Platinum 8488C |
| **Cores:** 24 physical cores / 32 logical CPUs | **Cores:** 48 physical cores / 96 logical CPUs |
| **LLC size:** 36 MiB L3 cache | **LLC size:** 105 MiB L3 cache |

Price assumption: `us-east-1`, Linux On-Demand pricing, checked on 2026-06-10. Verify before final slides because cloud pricing can change.

Notes:

- `metal` is used so hardware counters reflect physical hardware behavior more directly.
- This matters for memory-behavior analysis because `perf` counters can be distorted or hidden by virtualization layers.
- The bare-metal CPU instance avoids VM interference when counting cache misses, memory accesses, and related low-level events.

Sources to re-check for final slides:

- AWS M7i instance page: https://aws.amazon.com/ec2/instance-types/m7i/
- AWS G7e instance page: https://aws.amazon.com/ec2/instance-types/g7e/
- AWS EC2 general-purpose instance specs: https://docs.aws.amazon.com/ec2/latest/instancetypes/gp.html
- AWS EC2 accelerated-computing instance specs: https://docs.aws.amazon.com/ec2/latest/instancetypes/ac.html
- NVIDIA RTX PRO 6000 Blackwell Server Edition specs: https://www.nvidia.com/en-us/data-center/rtx-pro-6000-blackwell-server-edition/

### Slide 3: Broader Traversal-Based Graph Algorithms

- Address the reviewer concern that the method should be validated beyond X-Blossom.
- Add BFS, SSSP, and BC as representative traversal-based graph algorithms.
- Use these algorithms to show that the performance-analysis methodology applies to traversal-heavy graph workloads, not only to blossom computation.
- Emphasize that the method body compares memory behavior, traversal intensity, and extra per-edge computation across workloads.

| Algorithm | Source nodes and traversal behavior |
| --- | --- |
| **XB** | **Starting source node:** all exposed even nodes. **Traversal behavior:** explores alternating-tree structures and performs complicated blossom operations in addition to graph traversal. |
| **BFS** | **Starting source node:** single source node. **Traversal behavior:** primarily examines edges to discover reachable vertices level by level. |
| **SSSP** | **Starting source node:** single source node. **Traversal behavior:** examines edges and also performs distance relaxation and priority/worklist updates. |
| **BC** | **Starting source node:** single source node. **Traversal behavior:** examines edges and also performs dependency accumulation and shortest-path bookkeeping. |

## Figure 8: Runtime Across Traversal-Based Algorithms

Figure: `expr/results-remote/8_runtime_four/figure_8.png`

### Slide Takeaways

1. **X-Blossom suits the GPU best, while BFS suits the CPU most.**
   - X-Blossom exposes much more traversal work and more complex parallel work, so the GPU is a better fit.
   - BFS has simpler per-edge work and less computation per traversal step, so CPU execution remains comparatively strong.

2. **BC and SSSP favor the CPU on small datasets but favor the GPU on large datasets.**
   - On small datasets, GPU overhead and limited parallelism can reduce the benefit of acceleration.
   - On large datasets, higher traversal volume exposes enough parallel work for the GPU to outperform the CPU.

3. **The measured performance matches our prediction.**
   - Algorithms with more parallel traversal work and higher edge-processing volume benefit more from the GPU.
   - Algorithms with simpler traversal behavior or smaller workloads show less GPU advantage.

## Figure 11: Examined-Edge Throughput

Figure: `expr/results-remote/11_throughput/figure_11.png`

This is a new figure for the paper. It compares examined-edge throughput across the four traversal-based algorithms: XB, BFS, SSSP, and BC.

### Slide Takeaways

1. **BFS, BC, and SSSP examine a fixed number of edges.**
   - BFS examines `2E` directed edge visits.
   - BC and SSSP examine `4E` directed edge visits.
   - Because the examined-edge count is fixed for these algorithms, edge throughput is the reverse trend of runtime.

2. **X-Blossom traverses far more edges than BFS.**
   - The number of edges traversed by X-Blossom is approximately `100x` the number traversed by BFS.
   - This much larger traversal volume explains why X-Blossom has a stronger need for GPU acceleration.
   - It also shows that X-Blossom exposes far more parallelism than BFS, SSSP, or BC.
   - The throughput figure helps separate raw runtime from the amount of traversal work performed.

## Table 9: Instruction Execution Rate

Table: `Table 9. Instruction Execution Rate (GIPS)`

This table compares instruction execution rate across the CPU and GPU implementations of XB, BFS, SSSP, and BC.

### Slide Takeaways

1. **Across CPU implementations, instruction issue rate is mainly determined by working-set size.**
   - BFS has the smallest working set because it only needs about `1 * N` state to record whether each node has been visited.
   - SSSP and BC require larger per-node state, roughly `k * N`, such as shortest distance, predecessor/path metadata, or dependency values.
   - X-Blossom has the largest working set because it requires path-table-style state that can scale as `N^2`.
   - This explains the CPU-side instruction issue rate trend: `BFS > SSSP / BC > XB`.

2. **Within each CPU algorithm, instruction issue rate is strongly affected by average degree.**
   - Average degree controls how much edge-level parallel work is available when only a limited number of CPU worker threads are active.
   - Higher average degree gives each active thread more traversal work and helps maintain a higher instruction issue rate.
   - Amazon is an outlier because its low average degree limits available parallelism, not because its working set is unusually large.

3. **Across GPU implementations, instruction issue rate is mainly determined by available parallelism.**
   - This is consistent with the edge-throughput discussion from Figure 11.
   - Algorithms and datasets with more traversed edges expose more GPU work and therefore reach higher instruction issue rates.
   - Larger graphs tend to have higher GPU instruction issue rates because they provide enough parallel work to keep many GPU threads active.

4. **Within each GPU algorithm, total edge count is the dominant dataset-level factor once enough threads are active.**
   - When the GPU has sufficient work, the total number of edges largely determines how well the hardware is utilized.
   - This is why larger graphs usually show higher instruction issue rates on GPUs.
   - The GPU trend is therefore different from the CPU trend: CPU performance is more constrained by working-set size and average degree, while GPU performance is more constrained by total exposed parallelism.

## Table 10: Memory Behavior

Table: `Table 10. Memory Behavior`

This table compares CPU cache behavior and GPU effective memory bandwidth across XB, BFS, SSSP, and BC.

### Slide Takeaways

1. **On CPUs, X-Blossom shows strong cache utilization across the four algorithms.**
   - Across the four algorithms, they have comparable cache miss rate and cache miss frequncy. To be more specific, XB has the second-lowest cache miss rate and the lowest cache miss frequency.
   - This indicates that XB has an advantage in cache utilization even though its working set is large.
   - The reason is algorithmic locality: blossom operations repeatedly access and update related matching, tree, label, and path-table state, so the CPU cache can be reused effectively during these operations.

2. **Within each CPU algorithm, larger node counts generally lead to higher cache miss rates.**
   - More nodes increase the working set, making it harder for the active data to remain in cache.
   - As the working set grows beyond cache capacity, miss rate increases.
   - Amazon and YouTube are exceptions because they have low average degree, so each active node touches fewer adjacent edges and creates less edge-neighborhood pressure on the cache.

3. **On GPUs, X-Blossom reaches the highest effective memory bandwidth because it exposes the most parallelism.**
   - The observed trend is `XB > SSSP / BC > BFS`.
   - XB has the most parallelism because it starts from all exposed even nodes and repeatedly expands many alternating trees, producing much more traversal work than a single-source traversal.
   - SSSP and BC have more GPU work than BFS because they do more than simply inspect edges: SSSP performs relaxation and worklist/priority updates, while BC performs shortest-path bookkeeping and dependency accumulation.
   - BFS has the least effective memory bandwidth because its per-edge work is simple and single-source frontier expansion can expose limited parallelism, especially when the frontier is small.

4. **GPlus and Twitch are exceptions for XB GPU bandwidth.**
   - Their effective memory bandwidth is comparable to the other algorithms instead of clearly higher.
   - These graphs have a high average blossom count but a limited number of nodes, so the total amount of GPU-parallel work is not large enough to fully utilize memory bandwidth.
   - In this case, blossom complexity increases work per node, but the graph size still limits total GPU occupancy.

5. **Within each GPU algorithm, larger graphs generally utilize memory bandwidth better.**
   - More nodes and edges expose more parallel memory requests.
   - With enough active GPU threads, memory latency is better hidden and bandwidth utilization increases.
   - Therefore, datasets with larger graphs usually show higher effective memory bandwidth on GPUs.
