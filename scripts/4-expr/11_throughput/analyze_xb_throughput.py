#!/usr/bin/env python3
import csv
import os
import re
import sys


def extract_metric(timing_file, label):
    pattern = re.compile(rf"{re.escape(label)}:\s*([0-9.eE+-]+)")
    values = []
    with open(timing_file) as f:
        for line in f:
            match = pattern.search(line)
            if match:
                values.append(float(match.group(1)))
    if values:
        return sum(values) / len(values)
    raise RuntimeError(f"No '{label}' found in {timing_file}")


if len(sys.argv) != 4:
    print("Usage: analyze_xb_throughput.py <dataset> <timing_file> <summary_csv>")
    sys.exit(1)

dataset = sys.argv[1]
timing_file = sys.argv[2]
summary_csv = sys.argv[3]

runtime_s = extract_metric(timing_file, "Average runtime")
edges = extract_metric(timing_file, "Number of Processed Edges")
aug_path_edges = extract_metric(timing_file, "AugmentingPath Processed Edges")
expand_edges = extract_metric(timing_file, "Expand Processed Edges")
blossom_edges = extract_metric(timing_file, "Blossom Processed Edges")
edges_per_second = extract_metric(timing_file, "Processed Edges per Second")

write_header = not os.path.exists(summary_csv)
with open(summary_csv, "a", newline="") as f:
    writer = csv.writer(f)
    if write_header:
        writer.writerow([
            "Dataset",
            "TraversedEdges(M)",
            "AugmentingPathEdges(M)",
            "ExpandEdges(M)",
            "BlossomEdges(M)",
            "Runtime(s)",
            "Throughput(MEdges/s)",
        ])
    writer.writerow([
        dataset,
        f"{edges / 1e6:.6f}",
        f"{aug_path_edges / 1e6:.6f}",
        f"{expand_edges / 1e6:.6f}",
        f"{blossom_edges / 1e6:.6f}",
        f"{runtime_s:.6f}",
        f"{edges_per_second / 1e6:.6f}",
    ])

print(
    f"[OK] {dataset}: "
    f"edges={edges / 1e6:.6f}M, "
    f"aug={aug_path_edges / 1e6:.6f}M, "
    f"expand={expand_edges / 1e6:.6f}M, "
    f"blossom={blossom_edges / 1e6:.6f}M, "
    f"runtime={runtime_s:.6f}s, "
    f"throughput={edges_per_second / 1e6:.6f} MEdges/s"
)
