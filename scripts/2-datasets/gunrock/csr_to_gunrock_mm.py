#!/usr/bin/env python3
"""
Convert CSR graph (rowOffsets.txt + colIndices.txt)
into Matrix Market (.mtx) format for undirected graphs.

Usage:
    python3 to_matrix_market.py \
        --row data/Amazon/amazon_rowOffsets.txt \
        --col data/Amazon/amazon_colIndices.txt \
        --out data/Amazon/amazon_graph.mtx
"""

import argparse
from pathlib import Path

HEADER_TEMPLATE = """%%MatrixMarket matrix coordinate pattern symmetric
%-------------------------------------------------------------------------------
% Converted from CSR format
%-------------------------------------------------------------------------------
"""

def convert_to_mtx(row_file, col_file, output_file):
    # Read row offsets
    with open(row_file, 'r') as f:
        row_offsets = [int(line.strip()) for line in f if line.strip()]
    # Read column indices
    with open(col_file, 'r') as f:
        col_indices = [int(line.strip()) for line in f if line.strip()]

    n = len(row_offsets) - 1  # number of vertices
    print(f"📘 Reading: {row_file}")
    print(f"📘 Reading: {col_file}")
    print(f"Vertices (n): {n}")

    edges = set()
    for u in range(n):
        for i in range(row_offsets[u], row_offsets[u + 1]):
            v = col_indices[i]
            if u != v:  # skip self-loops
                # store (min,max) since it's undirected
                edges.add((min(u + 1, v + 1), max(u + 1, v + 1)))

    m = len(edges)
    print(f"Edges (m): {m}")

    # Ensure output directory exists
    Path(output_file).parent.mkdir(parents=True, exist_ok=True)

    # Write MatrixMarket file
    with open(output_file, 'w') as out:
        out.write(HEADER_TEMPLATE)
        out.write(f"{n} {n} {m}\n")
        for (i, j) in sorted(edges):
            out.write(f"{i} {j}\n")

    print(f"✅ Matrix Market graph saved to: {output_file}\n")


def main():
    parser = argparse.ArgumentParser(
        description="Convert CSR graph files into Matrix Market (.mtx) format."
    )
    parser.add_argument("--row", required=True, help="Path to rowOffsets.txt")
    parser.add_argument("--col", required=True, help="Path to colIndices.txt")
    parser.add_argument("--out", required=True, help="Output Matrix Market file path")
    args = parser.parse_args()

    convert_to_mtx(args.row, args.col, args.out)


if __name__ == "__main__":
    main()
