#!/usr/bin/env python3
import sys
import csv
import os
import re

import numpy as np
import powerlaw


# ============================================================
# Minimal metric extractor (single-pattern)
# ============================================================

def extract_metric(lines, metric_name, cast_type):
    pattern = metric_name + r":\s*([0-9.eE+-]+)"
    for line in lines:
        m = re.search(pattern, line)
        if m:
            return cast_type(m.group(1))
    raise RuntimeError(f"No metric matched pattern: {pattern}")

# ============================================================
# Degree skew (Gini coefficient) from CSR rowOffsets
# ============================================================

def compute_degree_skew(row_offsets_path):
    """
    Compute power-law exponent (alpha) of degree distribution
    using the powerlaw package.
    """
    row_offsets = np.loadtxt(row_offsets_path, dtype=np.int64)
    degrees = row_offsets[1:] - row_offsets[:-1]

    # Power-law requires strictly positive values
    degrees = degrees[degrees > 0]

     # Print total number of edges
    total_edges = degrees.sum() / 2
    print(f"Sum of degrees: {total_edges}")

    fit = powerlaw.Fit(degrees, discrete=True, verbose=False)
    return fit.alpha

# ============================================================
# Main
# ============================================================

# if len(sys.argv) != 4:
#     print("Usage: RUN_graph_metrics_analyze.py <dataset> <metrics_file> <summary_csv>")
#     sys.exit(1)

if len(sys.argv) != 6:
    print(
        "Usage: RUN_graph_metrics_analyze.py "
        "<dataset> <metrics_file> <summary_csv> <rowOffsets> <colIndices>"
    )
    sys.exit(1)

dataset = sys.argv[1]
metrics_file = sys.argv[2]
summary_csv = sys.argv[3]
row_offsets_path = sys.argv[4]
col_indices_path = sys.argv[5]  # parsed, unused for now


with open(metrics_file) as f:
    lines = [line.strip() for line in f]

degree_skew = compute_degree_skew(row_offsets_path)
degree_skew_rounded = round(degree_skew, 2)
print(f"Degree Skew: {degree_skew_rounded:.2f}")

# -------------------------------
# Basic graph size
# -------------------------------
num_nodes = extract_metric(lines, r"Num of Nodes", int)
num_edges = extract_metric(lines, r"Num of Edges", int)
max_edges_per_node = extract_metric(lines, r"Max Degree", float)
avg_edges_per_node = extract_metric(lines, r"Avg Degree", float)

# -------------------------------
# Blossom counts & rates
# -------------------------------
num_blossoms = extract_metric(lines, r"Number of Blossoms", int)

blossoms_milli_per_sec = extract_metric(
    lines, r"blossoms\(Milli\) per Second", float
)

blossoms_milli_per_sec_per_node = extract_metric(
    lines, r"blossoms\(Milli\) per Second per Node", float
)

# -------------------------------
# Blossom ratios
# -------------------------------
avg_blossoms_per_node = extract_metric(
    lines, r"Avg blossoms per Node", float
)

avg_blossoms_per_edge = extract_metric(
    lines, r"Avg blossoms per Edge", float
)

avg_blossoms_per_node_per_edge = extract_metric(
    lines, r"Avg blossoms per Node per Edge", float
)

avg_blossoms_per_max_edge = extract_metric(
    lines, r"Avg blossoms per \(Max\) Edge", float
)

# -------------------------------
# Iteration metrics
# -------------------------------
num_processed_edges = extract_metric(
    lines, r"Number of Processed Edges", int
)

num_iterations = extract_metric(
    lines, r"Number of Iterations", int
)

max_edges_per_iteration = extract_metric(
    lines, r"Max Edges per Iteration", float
)

avg_edges_per_iteration = extract_metric(
    lines, r"Avg Edges per Iteration", float
)

avg_blossoms_per_iteration = extract_metric(
    lines, r"Avg blossoms per Iteration", float
)

product_edges_blossoms_per_iter = extract_metric(
    lines,
    r"Product of Avg Edges\(PerIter\) \* Avg blossom\(PerIter\)",
    float
)

avg_million_edges_per_sec = extract_metric(
    lines, r"Avg Million Edges per Second", float
)

avg_blossoms_per_processed_edge = extract_metric(
    lines, r"Avg blossoms per Processed Edge", float
)

# ============================================================
# Write CSV
# ============================================================

write_header = not os.path.exists(summary_csv)

with open(summary_csv, "a", newline="") as f:
    writer = csv.writer(f)

    if write_header:
        writer.writerow([
            "Dataset",
            "NumNodes",
            "NumEdges",
            "MaxDegree",
            "AvgDegree",
            "SkewDegree",
            "NumBlossoms",
            # "BlossomsMilliPerSec",
            # "BlossomsMilliPerSecPerNode",
            "AvgBlossomsPerNode"
            # "AvgBlossomsPerEdge",
            # "AvgBlossomsPerNodePerEdge",
            # "AvgBlossomsPerMaxEdge",
            # "Iterations",
            # "ProcessedEdges",
            # "MaxEdgesPerIteration",
            # "AvgEdgesPerIteration",
            # "AvgBlossomsPerIteration",
            # "ProductEdgesBlossomsPerIter",
            # "AvgMillionEdgesPerSec",
            # "AvgBlossomsPerProcessedEdge",
        ])

    writer.writerow([
        dataset,
        num_nodes,
        num_edges,
        max_edges_per_node,
        avg_edges_per_node,
        degree_skew_rounded,  # TWO DECIMALS
        num_blossoms,
        # blossoms_milli_per_sec,
        # blossoms_milli_per_sec_per_node,
        avg_blossoms_per_node
        # avg_blossoms_per_edge,
        # avg_blossoms_per_node_per_edge,
        # avg_blossoms_per_max_edge,
        # num_iterations,
        # num_processed_edges,
        # max_edges_per_iteration,
        # avg_edges_per_iteration,
        # avg_blossoms_per_iteration,
        # product_edges_blossoms_per_iter,
        # avg_million_edges_per_sec,
        # avg_blossoms_per_processed_edge,
    ])

print(
    f"[OK] {dataset}: "
    f"Nodes={num_nodes}, "
    f"Edges={num_edges}, "
    f"MaxDegree={max_edges_per_node}, "
    f"AvgDegree={avg_edges_per_node}, "
    f"SkewDegree{degree_skew_rounded}",  # TWO DECIMALS
    f"Blossoms={num_blossoms}, "
    # f"BlossomsMilliPerSec={blossoms_milli_per_sec}, "
    # f"BlossomsMilliPerSecPerNode={blossoms_milli_per_sec_per_node}, "
    # f"Iterations={num_iterations}, "
    # f"ProcessedEdges={num_processed_edges}"
)
