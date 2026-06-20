#!/usr/bin/env python3
"""
Convert CSR graph files into Ligra weighted adjacency format.

All edge weights are initialized to 1, so SSSP traverses the same topology as
the unweighted graph while using Ligra's weighted edgeMap interface.
"""

import argparse
from pathlib import Path


def read_int_lines(path):
    with open(path, "r") as file:
        return [int(line.strip()) for line in file if line.strip()]


def write_ones(out, n, chunk_size=1_000_000):
    full_chunks, remainder = divmod(n, chunk_size)
    chunk = "1\n" * chunk_size
    for _ in range(full_chunks):
        out.write(chunk)
    if remainder:
        out.write("1\n" * remainder)


def convert_to_weighted_ligra(row_file, col_file, output_file):
    row_offsets = read_int_lines(row_file)
    col_indices = read_int_lines(col_file)

    n = len(row_offsets)
    m = len(col_indices)

    print(f"Reading: {row_file}")
    print(f"Reading: {col_file}")
    print(f"Vertices (n): {n}")
    print(f"Edges (m): {m}")

    Path(output_file).parent.mkdir(parents=True, exist_ok=True)
    with open(output_file, "w") as out:
        out.write("WeightedAdjacencyGraph\n")
        out.write(f"{n}\n")
        out.write(f"{m}\n")
        out.writelines(f"{offset}\n" for offset in row_offsets)
        out.writelines(f"{dst}\n" for dst in col_indices)
        write_ones(out, m)

    print(f"Weighted Ligra graph saved to: {output_file}\n")


def main():
    parser = argparse.ArgumentParser(
        description="Convert CSR graph files into Ligra weighted adjacency format."
    )
    parser.add_argument("--row", required=True, help="Path to rowOffsets.txt")
    parser.add_argument("--col", required=True, help="Path to colIndices.txt")
    parser.add_argument("--out", required=True, help="Output weighted Ligra graph path")
    args = parser.parse_args()

    convert_to_weighted_ligra(args.row, args.col, args.out)


if __name__ == "__main__":
    main()
