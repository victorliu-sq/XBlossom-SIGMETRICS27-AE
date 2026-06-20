# Reviewer Items 6 and 8-11 Response Draft

This note drafts paper additions and appendix responses for the remaining reviewer questions numbered 6, 8, 9, 10, and 11 in the resubmission appendix. The original reviewer wording is taken from the HotCRP review PDF.

## Item 6: Execution Phases

**Original reviewer sentence**

- Resubmission list: "Include details about execution phases."
- Reviewer E: "Lack of details of execution phases: how much portion is sequential, how much can be run in parallel? This would help in understanding the parallel efficiency of your method. Currently, for some workloads, e.g., Wikipedia and Youtube, the CPU->GPU performance speedup can go beyond 10x, but for some workloads like GPlus, HiggsNets, the CPU->GPU performance speedup is around 4x (table 2). This does not match the growth of thread count from CPU to GPU. Clarifying the parallel vs sequential portion might help with this concern."

**Paper addition**

Revise the two explanatory paragraphs in Section 4.2.2 that discuss why X-Blossom++ may not always outperform X-Blossom-Pro under node-level load balancing and why edge-level load balancing improves X-Blossom++ on some datasets. This location is better than Section 5.2 because these paragraphs already discuss the parallel and sequential parts of the XB++ execution and connect them to the load-balancing results.

Suggested text:

> Under an inappropriate load-balancing strategy, X-Blossom++ may not always outperform X-Blossom-Pro. On the GPlus dataset, X-Blossom-Pro with the node-level strategy (1.00 s) outperforms X-Blossom++ under the same strategy (1.28 s). This result is consistent with the graph metrics reported in Table~\ref{tab:graphs} that GPlus has the highest average number of blossoms. This illustrates that CPUs are better suited to handling control- and memory-intensive blossom-related operations, thereby delivering superior single-thread performance. CPUs employ deep pipelines with advanced features (e.g., out-of-order execution, branch prediction, speculative execution) and large last-level caches to optimize single-thread performance and reduce memory-access latency. GPUs instead favor throughput, using simpler pipelines and more hardware threads for massive parallelism, along with relatively shallow caches tuned for bandwidth over latency. \textcolor{red}{In X-Blossom++, the expensive sequential work mainly comes from blossom-related path-table operations, such as following paths, materializing blossoms, checking duplicates, and copying path segments. These operations use irregular memory accesses and variable-length loops inside each GPU task, so they limit parallel efficiency when blossom work dominates.} This creates a mismatch between GPU architectures and sequential blossom handling, which instead favors CPU single-thread efficiency. As a result, X-Blossom-Pro finishes sooner on GPlus.
>
> Although GPUs are ill-suited to the sequential blossom work, their massive parallelism can still amortize blossom-related overheads when sufficient independent work is available. \textcolor{red}{X-Blossom++ exposes this parallelism through an edge-level strategy in its three major search phases: frontier edges are processed in parallel to detect augmenting paths, to grow alternating trees, and to identify same-tree even-edge pairs that form discovered blossoms.} On GPUs, the edge-level approach exposes finer-grained tasks, enabling many blossom-related operations to execute concurrently and thereby reducing their effective cost relative to the node-level variant. This behavior is reflected in the relationship between each dataset's Avg Blossoms metric, which captures blossom density and the amount of blossom work available for parallel execution, and the X-Blossom++ edge-over-node speedup. Accordingly, on GPlus, X-Blossom++ with the edge-level strategy delivers the largest improvement over its node-level counterpart (5.32×), consistent with GPlus's very high Avg Blossoms (109.73). In contrast, for Wikipedia (Avg Blossoms = 0.00048) and StackOverflow (Avg Blossoms = 0.00049), X-Blossom++ using the edge-level strategy provides no benefit and is slightly slower than node-level (0.940× and 0.948×, respectively) because the blossom workload is too small to expose enough parallelism to exploit. Some datasets, such as Amazon, have a higher Avg Blossoms (7.49) yet see only a modest X-Blossom++ edge-over-node speedup (1.08×), which we attribute to the graph's sparsity (Max Deg = 549, Avg Deg = 2.76) limiting the amount of exploitable GPU parallelism. \textcolor{red}{Thus, XB++ performance is governed by the balance between edge-level parallel work and serial blossom/path-table work, rather than by the GPU thread count alone.}

**Appendix response**

> We revised the last two paragraphs of the load-balancing discussion in Subsubsection~\ref{tab:load_balance} to clarify which parts of X-Blossom++ are parallel and which parts remain sequential or expensive. The revised text explains why the best load-balancing strategy is architecture-dependent from the perspective of execution pattern.

## Item 8: Small Ratios in Table 5

**Original reviewer sentence**

- Resubmission list: "Explain why the ratio is small (close to 1) for some of the larger graphs in Table 5 (column 6) if enough parallel work is available under XB++."
- Reviewer D: "It would be good to explain why the ratio is small (close to 1) for some of the larger graphs in Table 5 (column 6) if enough parallel work is available under XB++?"

**Paper addition**

Add this in Section 5.2.1 immediately after introducing the GPU-side instruction-rate ratios in Table 5.

Suggested text:

> \textcolor{red}{After moving the experiments to the RTX PRO 6000 Blackwell GPU, X-Blossom++ achieves a higher instruction issue rate than BFS-Gunrock on all evaluated graphs. This is consistent with our conclusion that X-Blossom++ exposes more exploitable GPU parallelism through fine-grained edge-level work, allowing the newer GPU platform to better utilize its SM-level execution resources.}

Evidence for response:

- NVIDIA's A100 architecture whitepaper states that the A100 Tensor Core GPU has 108 SMs: <https://images.nvidia.com/aem-dam/en-zz/Solutions/data-center/nvidia-ampere-architecture-whitepaper.pdf>
- NVIDIA's RTX PRO Blackwell GPU architecture document lists 188 SMs for the RTX PRO 6000 Blackwell: <https://www.nvidia.com/content/dam/en-zz/Solutions/design-visualization/quadro-product-literature/NVIDIA-RTX-Blackwell-PRO-GPU-Architecture-v1.0.pdf>

**Appendix response**

> This issue no longer appears after moving the experiments from the previous A100 platform to the RTX PRO 6000 Blackwell platform. The A100 exposes 108 SMs, whereas the RTX PRO 6000 Blackwell exposes 188 SMs, providing substantially more SM-level execution resources. With the revised platform, XB++ achieves a higher instruction issue rate than BFS-Gunrock on all evaluated graphs, which is consistent with our conclusion that XB++ exposes more GPU parallelism through fine-grained edge-level work. We added one sentence in Section 5.2.1 to explicitly state this observation and connect it to the parallelism-exploitation conclusion.

## Item 9: Variability in Table 2 Speedups

**Original reviewer sentence**

- Resubmission list: "Comment on the variability in the improvement of the speed up across different graphs in Table 2."
- Reviewer D: "It would be nice to comment on the variability in the improvement of the speedup across different graphs in Table 2"

**Paper addition**

Add this after Table 2 in Section 4.2.1, following the current sentence that summarizes the CPU and GPU speedup ranges.

Suggested text:

> \textcolor{red}{To explain this variability, Table~\ref{tab:reuse} also reports ReuseRatio, defined as the percentage of alternating-tree nodes preserved by the reuse mechanism rather than reset during the alternating-forest update. A higher ReuseRatio means that more previously constructed search state can be carried across iterations, reducing repeated tree reconstruction. This metric tracks the observed speedups: Amazon has the highest ReuseRatio on both CPU and GPU and also achieves the largest reuse speedups, while Patent and LiveJournal also have relatively high ReuseRatio values and strong speedups. In contrast, Wikipedia has the lowest ReuseRatio on both platforms and correspondingly shows the smallest benefit from reuse.}

**Appendix response**

> We added ReuseRatio to Table 2 and used it to explain the variability in reuse speedups across graphs. ReuseRatio measures the percentage of alternating-tree nodes preserved by the reuse mechanism rather than reset, so it directly captures the internal behavior that alternating-tree reuse is designed to exploit. The revised discussion shows that datasets with higher ReuseRatio generally obtain larger speedups: Amazon has the highest ReuseRatio and the largest speedup on both CPU and GPU, while Patent and LiveJournal also have relatively high ReuseRatio values and strong speedups. Conversely, Wikipedia has the lowest ReuseRatio and correspondingly shows the smallest benefit from reuse.

## Item 10: SIMT and Massive Concurrency

**Original reviewer sentence**

- Resubmission list: "Expand a bit on how SIMT execution helps to keep up massive concurrency."
- Reviewer D: "It would be nice to expand a bit on how SIMT execution helps to keep up massive concurrency (I am not very familiar with this area)"

**Paper addition**

Add this in Section 4.2.2 after the current sentence that says GPUs leverage SIMT execution and massive concurrency to keep many warps in flight. A shorter version can also be added in Section 5.2.1 where high occupancy and warp-level multithreading are discussed.

Suggested text:

> In SIMT execution, GPU threads are grouped into warps that execute the same instruction stream in lockstep. A streaming multiprocessor can keep many warps resident at the same time and rapidly switch among ready warps when some warps stall on memory accesses or branch-dependent work. This hardware scheduling allows lightweight CUDA threads to tolerate latency through concurrency rather than by optimizing the latency of a single thread. For X-Blossom++, edge-level load balancing creates many fine-grained tasks, which gives the SIMT scheduler enough warps to keep the GPU occupied and helps amortize indexing, synchronization, and memory-access overheads.

**Appendix response**

> We expanded the explanation of SIMT execution. The revised text explains that CUDA threads are grouped into warps, many warps can reside on each streaming multiprocessor, and hardware scheduling switches among ready warps when others stall. This allows XB++ to hide memory and control-flow latency through massive concurrency, especially when edge-level load balancing exposes enough fine-grained tasks.

## Item 11: Small Working Set

**Original reviewer sentence**

- Resubmission list: "Explain small working set a bit more on Page 17: is it related to the amount of memory needed to store required data in cache?"
- Reviewer D: "Can you please explain small working set a bit more on Page 17: is it related to the amount of memory needed to store required data in cache"

**Paper addition**

Add this in Section 5.1 immediately after the sentence "Data movement effectiveness describes how quickly a traversal brings its working set to the compute cores through the memory hierarchy." and before the sentence beginning "On the other hand".

Suggested text:

> \textcolor{red}{Here, the working set refers to the amount of memory that a process requires to finish its execution, including graph data, frontier data, and algorithm-specific state.}

**Appendix response**

> We added a definition of working set in Section 5.1 before introducing parallelism exploitation. The revised text clarifies that working set refers to the amount of memory that a process requires to finish its execution, including graph data, frontier data, and algorithm-specific state.
