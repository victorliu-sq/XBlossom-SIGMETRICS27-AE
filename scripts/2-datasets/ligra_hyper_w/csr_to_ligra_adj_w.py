#!/usr/bin/env python3
"""
Convert CSR graph files into Ligra weighted hypergraph format for HyperSSSP.

Each CSR edge becomes one directed hyperedge:

  source vertex -> hyperedge -> destination vertex

All incidence weights are initialized to 1. This gives HyperSSSP a unit-weight
traversal workload over the same graph topology.
"""

import argparse
from pathlib import Path


def read_int_lines(path):
    with open(path, "r") as file:
        return [int(line.strip()) for line in file if line.strip()]


def write_ints(out, values):
    out.writelines(f"{value}\n" for value in values)


def write_range(out, n, chunk_size=1_000_000):
    start = 0
    while start < n:
        end = min(start + chunk_size, n)
        out.writelines(f"{value}\n" for value in range(start, end))
        start = end


def write_ones(out, n, chunk_size=1_000_000):
    chunk = "1\n" * min(chunk_size, n)
    full_chunks, remainder = divmod(n, chunk_size)
    for _ in range(full_chunks):
        out.write(chunk)
    if remainder:
        out.write("1\n" * remainder)


def convert_to_weighted_ligra_hypergraph(row_file, col_file, output_file):
    row_offsets = read_int_lines(row_file)
    col_indices = read_int_lines(col_file)

    nv = len(row_offsets)
    mv = len(col_indices)
    nh = mv
    mh = mv

    print(f"Reading: {row_file}")
    print(f"Reading: {col_file}")
    print(f"Vertices (nv): {nv}")
    print(f"Vertex incidences (mv): {mv}")
    print(f"Hyperedges (nh): {nh}")
    print(f"Hyperedge incidences (mh): {mh}")

    Path(output_file).parent.mkdir(parents=True, exist_ok=True)
    with open(output_file, "w") as out:
        out.write("WeightedAdjacencyHypergraph\n")
        out.write(f"{nv}\n")
        out.write(f"{mv}\n")
        out.write(f"{nh}\n")
        out.write(f"{mh}\n")

        # Vertex side: each original CSR edge becomes one incident hyperedge.
        write_ints(out, row_offsets)
        write_range(out, mv)
        write_ones(out, mv)

        # Hyperedge side: each directed hyperedge points to one destination.
        write_range(out, mh)
        write_ints(out, col_indices)
        write_ones(out, mh)

    print(f"Weighted Ligra hypergraph saved to: {output_file}\n")


def main():
    parser = argparse.ArgumentParser(
        description="Convert CSR graph files into Ligra weighted hypergraph format."
    )
    parser.add_argument("--row", required=True, help="Path to rowOffsets.txt")
    parser.add_argument("--col", required=True, help="Path to colIndices.txt")
    parser.add_argument("--out", required=True, help="Output Ligra weighted hypergraph path")
    args = parser.parse_args()

    convert_to_weighted_ligra_hypergraph(args.row, args.col, args.out)


if __name__ == "__main__":
    main()
