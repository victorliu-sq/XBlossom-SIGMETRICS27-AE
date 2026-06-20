#!/usr/bin/env python3
"""
Load a graph directly from CSR format (rowOffsets.txt + colIndices.txt),
find the Largest Connected Component (LCC), and sample source nodes.

Generates two output files:
1. An analysis file with graph statistics (*_analysis.txt).
2. A source node file with sampled nodes (*_src_nodes.txt), one node per line.
"""

import argparse
import random
from pathlib import Path
import sys
from collections import deque

def load_csr_graph(row_file, col_file):
    """
    Loads a graph from CSR format files (row_offsets and col_indices).

    Returns: A 3-tuple (N, M, adj_list) on success, or (None, None, None) on failure.
    """
    row_offsets = []
    col_indices = []

    try:
        # Read row offsets (must be N+1 elements)
        with open(row_file, 'r') as f:
            row_offsets = [int(line.strip()) for line in f if line.strip()]

        # Read column indices (must be M elements)
        with open(col_file, 'r') as f:
            col_indices = [int(line.strip()) for line in f if line.strip()]

    except FileNotFoundError as e:
        print(f"❌ Error: Graph file not found: {e}", file=sys.stderr)
        return None, None, None
    except ValueError as e:
        print(f"❌ Error: Non-integer data found in graph files: {e}", file=sys.stderr)
        return None, None, None
    except Exception as e:
        # Catch any unexpected reading errors
        print(f"❌ Unexpected error reading files: {e}", file=sys.stderr)
        return None, None, None

    # CSR Structure Check
    if not row_offsets or not col_indices:
        print("❌ Error: One or both graph files are empty.", file=sys.stderr)
        return None, None, None

    n = len(row_offsets) - 1  # number of vertices (N+1 offsets means N vertices)
    m = len(col_indices)    # number of edges

    if n <= 0:
        print("❌ Error: Row offsets file suggests 0 or fewer vertices.", file=sys.stderr)
        return None, None, None

    # Construct the Adjacency List
    adj_list = {i: [] for i in range(n)}

    # Iterate over vertices 0 to n-1
    for i in range(n):
        # Edges for vertex i are in col_indices from index row_offsets[i]
        start_index = row_offsets[i]
        end_index = row_offsets[i+1]

        # Basic bounds check (important for robust CSR parsing)
        if start_index < 0 or end_index > m or start_index > end_index:
             print(f"❌ Error: Invalid row offset index for vertex {i}. Indices: {start_index} to {end_index} (Max M: {m})", file=sys.stderr)
             return None, None, None

        # Slicing the column indices gives the neighbors for vertex i
        neighbors = col_indices[start_index:end_index]
        adj_list[i].extend(neighbors)

    return n, m, adj_list

def find_connected_components(n, adj_list):
    """
    Finds all Weakly Connected Components (WCC) using Iterative Breadth-First Search (BFS).
    Returns a list of sets, where each set is a connected component.
    """
    visited = set()
    components = []

    # Iterate through all nodes (0 to N-1)
    for start_node in range(n):
        if start_node not in visited:
            # Start a new component discovery (BFS)
            component = set()
            queue = deque([start_node])
            visited.add(start_node)
            component.add(start_node)

            while queue:
                u = queue.popleft()

                # Check neighbors of u (u -> v)
                for v in adj_list.get(u, []):
                    if v not in visited:
                        visited.add(v)
                        component.add(v)
                        queue.append(v)

            components.append(component)

    return components

DEFAULT_NUM_SAMPLES = 1000


def analyze_graph(row_file, col_file, output_base_path, requested_samples):
    print(f"📘 Reading CSR files:")
    print(f"  Row offsets: {row_file}")
    print(f"  Col indices: {col_file}")

    # --- FIX APPLIED HERE: Capture result first for robust error handling ---
    load_result = load_csr_graph(row_file, col_file)

    # Check if the load operation failed. load_csr_graph returns (None, None, None) on error.
    if load_result[0] is None:
        # An error message was already printed inside load_csr_graph
        return

    # Safely unpack the result tuple
    n, m, adj_list = load_result

    # 1. Compute Connected Components (CCs)
    components = find_connected_components(n, adj_list)

    # 2. Extract component sizes and count
    component_sizes = sorted([len(c) for c in components], reverse=True)
    num_components = len(components)

    # 3. Extract the largest connected component (LCC)
    lcc_set = next(iter(c for c in components if len(c) == component_sizes[0]), set()) if component_sizes else set()
    lcc_nodes = list(lcc_set)
    lcc_size = len(lcc_nodes)

    print(f"\n📊 Graph Analysis:")
    print(f"  Total Vertices (N): {n}")
    print(f"  Total Edges (M): {m}")
    print(f"  Total Connected Components: {num_components}")
    print(f"  Size of LCC (# of nodes): {lcc_size}")

    if lcc_size == 0 and n > 0:
        print("⚠️ Warning: Graph has nodes but no components were found.", file=sys.stderr)
        return
    elif n == 0:
        print("⚠️ Warning: Graph is empty.", file=sys.stderr)
        return

    # 4. Randomly pick source nodes from the LCC.
    num_samples = requested_samples
    if lcc_size < num_samples:
        print(f"\n⚠️ Warning: LCC size is only {lcc_size}. Sampling all nodes.", file=sys.stderr)
        num_samples = lcc_size

    random_nodes = random.sample(lcc_nodes, num_samples)
    random_nodes.sort() # Sort for deterministic output display

    # 5. Write Analysis File (Human-readable metadata)
    analysis_file = Path(output_base_path).parent / f"{Path(output_base_path).stem}_analysis.txt"
    Path(analysis_file).parent.mkdir(parents=True, exist_ok=True)

    size_counts = {}
    for size in component_sizes:
        size_counts[size] = size_counts.get(size, 0) + 1

    with open(analysis_file, 'w') as out:
        out.write(f"--- Graph Connectivity Analysis ---\n")
        out.write(f"Source Row File: {row_file}\n")
        out.write(f"Source Col File: {col_file}\n")
        out.write(f"Total Vertices (N): {n}\n")
        out.write(f"Total Edges (M): {m}\n")
        out.write(f"Total Connected Components: {num_components}\n")
        out.write(f"LCC Size: {lcc_size}\n")
        out.write(f"--- Component Size Distribution (Size, Count) ---\n")
        for size, count in sorted(size_counts.items(), reverse=True):
             out.write(f"{size}, {count}\n")
        # Sampled nodes intentionally omitted from analysis file

    print(f"✅ Analysis saved to: {analysis_file}")

    # 6. Write Source Nodes File (Machine-readable list)
    sources_file = Path(output_base_path).parent / f"{Path(output_base_path).stem}_src_nodes.txt"

    with open(sources_file, 'w') as out:
        out.write(f"# {num_samples} Random Source Nodes (0-indexed) from LCC of {Path(output_base_path).stem}\n")
        out.write(f"# Requested Source Nodes: {requested_samples}\n")
        out.write(f"# LCC Size: {lcc_size}\n")
        # Write nodes, one per line, for easy script reading
        for node in random_nodes:
            out.write(f"{node}\n")

    print(f"\n⭐ {num_samples} Random Nodes Sampled from LCC (Saved for script use):")
    print(f"  {random_nodes}")
    print(f"✅ Source nodes saved to: {sources_file}\n")


def main():
    parser = argparse.ArgumentParser(
        description="Load CSR graph, find LCC, and sample source nodes (stdlib only), saving to two separate output files."
    )
    parser.add_argument("--row", required=True, help="Path to rowOffsets.txt")
    parser.add_argument("--col", required=True, help="Path to colIndices.txt")
    parser.add_argument("--base-out", required=True, help="Base output path (e.g., path/to/dataset_name) used to generate *_analysis.txt and *_src_nodes.txt")
    parser.add_argument("--num-samples", type=int, default=DEFAULT_NUM_SAMPLES, help=f"Number of source nodes to sample from the LCC, default: {DEFAULT_NUM_SAMPLES}")
    args = parser.parse_args()

    if args.num_samples <= 0:
        parser.error("--num-samples must be a positive integer")

    analyze_graph(args.row, args.col, args.base_out, args.num_samples)

if __name__ == "__main__":
    main()
