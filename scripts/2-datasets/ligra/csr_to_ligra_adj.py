#!/usr/bin/env python3
"""
Convert CSR graph (rowOffsets.txt + colIndices.txt) to Ligra-compatible adjacency format.

Usage:
    python3 convert_to_ligra_format.py \
        --row Amazon/amazon_rowOffsets.txt \
        --col Amazon/amazon_colIndices.txt \
        --out Amazon/amazon_graph.txt
"""

import argparse
from pathlib import Path

def convert_to_ligra(row_file, col_file, output_file):
    # Read row offsets
    with open(row_file, 'r') as f:
        row_offsets = [int(line.strip()) for line in f if line.strip()]
    # Read column indices
    with open(col_file, 'r') as f:
        col_indices = [int(line.strip()) for line in f if line.strip()]

    n = len(row_offsets)  # number of vertices
    m = len(col_indices)  # number of edges

    print(f"📘 Reading: {row_file}")
    print(f"📘 Reading: {col_file}")
    print(f"Vertices (n): {n}")
    print(f"Edges (m): {m}")

    # Ensure output directory exists
    Path(output_file).parent.mkdir(parents=True, exist_ok=True)

    # Write Ligra-compatible format
    with open(output_file, 'w') as out:
        out.write("AdjacencyGraph\n")
        out.write(f"{n}\n")
        out.write(f"{m}\n")
        for v in row_offsets:
            out.write(f"{v}\n")
        for e in col_indices:
            out.write(f"{e}\n")

    print(f"✅ Ligra graph saved to: {output_file}\n")


def main():
    parser = argparse.ArgumentParser(
        description="Convert CSR graph files into Ligra adjacency format."
    )
    parser.add_argument("--row", required=True, help="Path to rowOffsets.txt")
    parser.add_argument("--col", required=True, help="Path to colIndices.txt")
    parser.add_argument("--out", required=True, help="Output Ligra graph file path")
    args = parser.parse_args()

    convert_to_ligra(args.row, args.col, args.out)


if __name__ == "__main__":
    main()
