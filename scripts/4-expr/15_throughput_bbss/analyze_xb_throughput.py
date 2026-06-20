#!/usr/bin/env python3
import csv
import os
import re
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[1]))
from experiment_ci import (
    append_sample,
    confidence_interval_95,
    extract_metric_values,
    extract_round_runtimes_seconds,
)


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
round_runtimes = extract_round_runtimes_seconds(timing_file)
edges = extract_metric(timing_file, "Number of Processed Edges")
aug_path_edges = extract_metric(timing_file, "AugmentingPath Processed Edges")
expand_edges = extract_metric(timing_file, "Expand Processed Edges")
blossom_edges = extract_metric(timing_file, "Blossom Processed Edges")
edges_per_second = extract_metric(timing_file, "Processed Edges per Second")
runtime_ci = 0.0
throughput_ci = 0.0
if round_runtimes:
    runtime_s, runtime_ci = confidence_interval_95(round_runtimes)
    throughput_samples = [edges / rt / 1e6 for rt in round_runtimes if rt > 0]
    throughput_mean, throughput_ci = confidence_interval_95(throughput_samples)
    edges_per_second = throughput_mean * 1e6

samples_csv = f"{os.path.splitext(summary_csv)[0]}_samples.csv"
for idx, runtime_value in enumerate(round_runtimes, start=1):
    append_sample(
        samples_csv,
        ["Dataset", "Round", "Runtime(s)", "Throughput(MEdges/s)"],
        {
            "Dataset": dataset,
            "Round": idx,
            "Runtime(s)": f"{runtime_value:.9f}",
            "Throughput(MEdges/s)": f"{edges / runtime_value / 1e6:.9f}" if runtime_value > 0 else "nan",
        },
    )

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
            "RuntimeCI(s)",
            "Throughput(MEdges/s)",
            "ThroughputCI(MEdges/s)",
        ])
    writer.writerow([
        dataset,
        f"{edges / 1e6:.6f}",
        f"{aug_path_edges / 1e6:.6f}",
        f"{expand_edges / 1e6:.6f}",
        f"{blossom_edges / 1e6:.6f}",
        f"{runtime_s:.6f}",
        f"{runtime_ci:.6f}",
        f"{edges_per_second / 1e6:.6f}",
        f"{throughput_ci:.6f}",
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
