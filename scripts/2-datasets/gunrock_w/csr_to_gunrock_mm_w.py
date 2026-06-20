#!/usr/bin/env python3
"""
Convert CSR graph files into weighted Matrix Market format for Gunrock.

All edge weights are initialized to 1.0. The output is a symmetric real-valued
Matrix Market file, so Gunrock will load it as a weighted undirected graph.
"""

import argparse
from pathlib import Path


HEADER_TEMPLATE = """%%MatrixMarket matrix coordinate real symmetric
%-------------------------------------------------------------------------------
% Converted from CSR format with unit edge weights
%-------------------------------------------------------------------------------
"""


def read_int_lines(path):
    with open(path, "r") as file:
        return [int(line.strip()) for line in file if line.strip()]


def convert_to_weighted_mtx(row_file, col_file, output_file):
    row_offsets = read_int_lines(row_file)
    col_indices = read_int_lines(col_file)

    n = len(row_offsets) - 1
    m = len(col_indices)

    print(f"Reading: {row_file}")
    print(f"Reading: {col_file}")
    print(f"Vertices (n): {n}")

    edges = set()
    for u in range(n):
        start = row_offsets[u]
        end = row_offsets[u + 1] if u + 1 < n else m
        for i in range(start, end):
            v = col_indices[i]
            if u != v:
                edges.add((min(u + 1, v + 1), max(u + 1, v + 1)))

    Path(output_file).parent.mkdir(parents=True, exist_ok=True)
    with open(output_file, "w") as out:
        out.write(HEADER_TEMPLATE)
        out.write(f"{n} {n} {len(edges)}\n")
        for i, j in sorted(edges):
            out.write(f"{i} {j} 1.0\n")

    print(f"Edges (m): {len(edges)}")
    print(f"Weighted Matrix Market graph saved to: {output_file}\n")


def main():
    parser = argparse.ArgumentParser(
        description="Convert CSR graph files into weighted Matrix Market format."
    )
    parser.add_argument("--row", required=True, help="Path to rowOffsets.txt")
    parser.add_argument("--col", required=True, help="Path to colIndices.txt")
    parser.add_argument("--out", required=True, help="Output Matrix Market file path")
    args = parser.parse_args()

    convert_to_weighted_mtx(args.row, args.col, args.out)


if __name__ == "__main__":
    main()
