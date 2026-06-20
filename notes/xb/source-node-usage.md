# Source Node Usage in Gunrock and Ligra

Some benchmark algorithms are single-source graph algorithms. For those
algorithms, our scripts choose one source node from the generated source list
and pass it to the binary. The binary does not read the source-list file itself.

## Gunrock

The source list is used only by the bash scripts. The scripts read one node from
`data/bfs/<Dataset>/<dataset>_sources.txt`, then pass it to Gunrock with `-s`.

| Algorithm | Needs source node? | Command shape |
|---|---:|---|
| Gunrock BFS | Yes | `bfs -s <src> -m <graph.mtx>` |
| Gunrock BC | Yes | `bc -s <src> -m <graph.mtx>` |
| Gunrock SSSP | Yes | `sssp -s <src> -m <graph.mtx>` |
| XB++ | No | `run_xb_pp_by_dataset --row_offsets ... --col_indices ...` |

Gunrock BC in this repo is single-source BC, not all-source BC. It uses the same
first-source selection rule as BFS and SSSP.

Gunrock SSSP is also single-source. It receives one source node with `-s`; it
does not read the source list directly.

## Ligra

Ligra also uses one source node for BFS, BC, and HyperSSSP. The scripts read one
node from the generated source list and pass it with `-r`.

| Algorithm | Needs source node? | Command shape |
|---|---:|---|
| Ligra BFS | Yes | `BFS -rounds <n> -r <src> -s <graph>` |
| Ligra BC | Yes | `BC -rounds <n> -r <src> -s <graph>` |
| Ligra HyperSSSP | Yes | `HyperSSSP -rounds <n> -r <src> <graph>` |
| XB-Pro | No | `run_xb_pro_by_dataset --row_offsets ... --col_indices ...` |

In Ligra, `-r` is the source node. `-s` is not the source node; it tells Ligra to
use the symmetric graph mode for undirected graph inputs.

The relevant Ligra code reads the source node this way:

```cpp
long start = P.getOptionLongValue("-r", 0);
```

This appears in:

- `apps/ligra/apps/BFS.C`
- `apps/ligra/apps/BC.C`
- `apps/ligra/apps/hyper/HyperSSSP.C`

## Script Pattern

The shared pattern in the benchmark scripts is:

```bash
SRC="$(first_source_node "$SRC_FILE")"
"$bin" -s "$SRC" -m "$GUNROCK_GRAPH"
```

for Gunrock, and:

```bash
SRC="$(first_source_node "$SRC_FILE")"
"$bin" -rounds "$ROUNDS" -r "$SRC" -s "$LIGRA_GRAPH"
```

for Ligra BFS/BC.

For Ligra HyperSSSP, the graph is a weighted hypergraph, so the script omits
Ligra's symmetric `-s` option:

```bash
"$bin" -rounds "$ROUNDS" -r "$SRC" "$LIGRA_GRAPH"
```
