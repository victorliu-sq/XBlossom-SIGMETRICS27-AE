# XB-Pro Instruction Rate

## Why XB-Pro Has Low Instruction Rate

XB-Pro is not a simple graph traversal kernel.

Ligra BFS, SSSP, and BC mostly scan frontiers, read edges, update arrays, and
move to the next frontier. This keeps CPU cores retiring instructions steadily.

XB-Pro has more irregular matching logic:

- alternating tree updates
- path table updates
- matching updates
- blossom handling
- shared-state synchronization
- atomic/CAS operations and locks

Because of this, many CPU cycles are spent waiting on synchronization, memory
dependencies, cache-line movement, or unbalanced work. During these waits, cores
retire fewer instructions per second, so XB-Pro has much lower GIPS than Ligra
traversal algorithms.

## Why More Threads Can Reduce XB-Pro Instruction Rate

Increasing the thread count does not always increase useful work.

For XB-Pro, more threads can create more contention:

- more races on shared matching/tree state
- more atomic/CAS conflicts
- more lock contention
- more cache-line bouncing
- more scheduling and coordination overhead
- more idle time from load imbalance

So using more threads, such as increasing from `8` to `48`, can reduce the
instruction rate. The bottleneck is not raw CPU compute capacity; it is
coordination, synchronization, and irregular memory access.
