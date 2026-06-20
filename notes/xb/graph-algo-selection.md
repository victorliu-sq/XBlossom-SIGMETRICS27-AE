# Traversal-based and iterative-based graph algorithms 
The key difference is the main control structure.

`Traversal-based algorithms` are driven by visiting order: “Which node do I visit next?” They usually care about whether a node has been discovered, visited, or fully processed.

Common examples are BFS,DFS, and SSSP

`Iterative-based algorithms` are driven by value updates: “How do I update the current estimate?” They may revisit the same nodes many times, refining distances, ranks, labels, or probabilities.

Examples include PageRank, Bellman-Ford,

In simple terms:

Traversal-based algorithms move through the graph.

Iterative-based algorithms update information over the graph repeatedly.

## BC
Betweenness centrality is usually best classified as traversal-based, not purely iterative-based.

Betweenness centrality measures how often a node lies on shortest paths between other pairs of nodes. To compute it exactly, the standard approach repeatedly runs shortest-path searches from each source node.

For an unweighted graph, this is usually done with BFS from every node.

## SSSP
Single-source shortest path, is usually best described as traversal-based, but the exact answer depends on which SSSP algorithm you mean.

SSSP is the problem of finding the shortest path distances from one source node to every other reachable node.

For an unweighted graph, SSSP is solved with BFS, so it is clearly traversal-based. BFS explores the graph outward from the source level by level, and the first time it reaches a node, it has found that node’s shortest distance.

For a graph with nonnegative edge weights, SSSP is often solved with Dijkstra’s algorithm. This is also commonly treated as traversal-based because it expands nodes outward from the source in increasing-distance order. It “visits” or finalizes nodes one at a time based on the current shortest known distance.