Prompt to determine how to compute # of processed edges:

```shell
For this , can you explain where does it access next level nodes via edges and where and how did you determine whether an edges is processed or not 
```

## Ligra-BFS

File: `apps/ligra/apps/BFS_Throughput.C`

Ligra-BFS accesses next-level nodes through Ligra's `edgeMap` primitive:

```cpp
vertexSubset output = edgeMap(GA, Frontier, BFS_F(Parents));
```

`Frontier` is the current BFS level. `edgeMap` scans outgoing edges from
vertices in `Frontier`. For each edge `(s, d)`, it applies `BFS_F`.

The destination node `d` becomes part of the next level when it has not been
visited yet:

```cpp
inline bool cond (uintE d) { return (Parents[d] == UINT_E_MAX); }

inline bool update (uintE s, uintE d) {
  if(Parents[d] == UINT_E_MAX) { Parents[d] = s; return 1; }
  else return 0;
}

inline bool updateAtomic (uintE s, uintE d) {
  return (CAS(&Parents[d], UINT_E_MAX, s));
}
```

`Parents[d] == UINT_E_MAX` means `d` has not been reached. The update records
`s` as `d`'s parent and returns `true`, so `edgeMap` places `d` in `output`.
Then `output` becomes the next frontier:

```cpp
Frontier = output;
```

The throughput counter counts every outgoing edge scanned from the current
frontier before `edgeMap` runs:

```cpp
edges_processed += CountFrontierEdges(GA, Frontier);
```

`CountFrontierEdges` sums the out-degree of every vertex in the current
frontier. In dense mode, it checks every vertex with `Frontier.isIn(i)` and
adds `GA.V[i].getOutDegree()` for frontier vertices. In sparse mode, it
iterates over explicit frontier entries with `Frontier.vtx(i)` and adds each
vertex's out-degree.

Therefore, for Ligra-BFS:

```text
processed edges = sum of outgoing edges of all vertices in every BFS frontier
```

An edge is counted as processed if its source vertex is in the current
frontier. The edge is counted even if its destination was already visited and
does not become part of the next frontier, because BFS still inspected that
edge during the frontier expansion.
