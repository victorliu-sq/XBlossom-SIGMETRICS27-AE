# Throughput Edge Counts

## Why Ligra and Gunrock Have the Same Traversed Edges

For BFS, SSSP, and BC, we count the same unit in both systems: original graph
edges touched during traversal.

Ligra and Gunrock execute differently, but they start from the same source node
and traverse the same reachable part of the graph. Therefore, their traversed
edge counts should match for the same algorithm.

## Why SSSP Matches BFS

All SSSP edge weights are set to `1`.

With unit weights, SSSP explores the graph like BFS: shortest path distance is
the same as hop count. Because BFS and SSSP visit the same graph region, they
touch the same number of original graph edges.

## Why BC Is About 2x BFS

BC has two traversal passes:

- a forward pass, similar to BFS, to discover levels and shortest paths
- a backward pass to propagate dependency scores

So BC touches roughly the same edges once forward and once backward. That is why
its traversed-edge count is about `2x` BFS.
