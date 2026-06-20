#!/usr/bin/env python3
import argparse
from pathlib import Path

import numpy as np
import pandas as pd


parser = argparse.ArgumentParser(description="Generate XB throughput table")
parser.add_argument("--xb_pro_csv", required=True)
parser.add_argument("--xb_pp_csv", required=True)
parser.add_argument("--bfs_ligra_csv", required=True)
parser.add_argument("--bfs_gunrock_csv", required=True)
parser.add_argument("--multisssp_ligra_csv", required=True)
parser.add_argument("--multisssp_gunrock_csv", required=True)
parser.add_argument("--sssp_ligra_csv", required=True)
parser.add_argument("--sssp_gunrock_csv", required=True)
parser.add_argument("--output", required=True)
args = parser.parse_args()


def normalize(name):
    return str(name).strip().lower()


def read_table(path):
    df = pd.read_csv(path)
    return {normalize(row["Dataset"]): row for _, row in df.iterrows()}


def value(table, dataset, column):
    row = table.get(normalize(dataset))
    if row is None:
        return np.nan
    try:
        return float(row[column])
    except (TypeError, ValueError):
        return np.nan


def ratio(num, den):
    if not np.isfinite(num) or not np.isfinite(den) or den == 0:
        return np.nan
    return num / den


def fmt(x):
    return "NA" if not np.isfinite(x) else f"{x:.2f}"


def fmt6(x):
    return "NA" if not np.isfinite(x) else f"{x:.6f}"


datasets = [
    "GPlus", "Twitch", "Amazon", "HiggsNets", "Youtube",
    "Hyperlink", "Wikipedia", "Stackoverflow", "Patent", "Livejournal"
]

xb_pro = read_table(args.xb_pro_csv)
xb_pp = read_table(args.xb_pp_csv)
bfs_ligra = read_table(args.bfs_ligra_csv)
bfs_gunrock = read_table(args.bfs_gunrock_csv)
multisssp_ligra = read_table(args.multisssp_ligra_csv)
multisssp_gunrock = read_table(args.multisssp_gunrock_csv)
sssp_ligra = read_table(args.sssp_ligra_csv)
sssp_gunrock = read_table(args.sssp_gunrock_csv)


def append_algorithm_columns(row, label, cpu_name, gpu_name, cpu_table, gpu_table, dataset):
    cpu_edges = value(cpu_table, dataset, "TraversedEdges(M)")
    cpu_runtime = value(cpu_table, dataset, "Runtime(s)")
    cpu_throughput = value(cpu_table, dataset, "Throughput(MEdges/s)")
    gpu_edges = value(gpu_table, dataset, "TraversedEdges(M)")
    gpu_runtime = value(gpu_table, dataset, "Runtime(s)")
    gpu_throughput = value(gpu_table, dataset, "Throughput(MEdges/s)")

    row[f"{cpu_name} Traversed Edges (M)"] = fmt6(cpu_edges)
    row[f"{cpu_name} Runtime (s)"] = fmt6(cpu_runtime)
    row[f"{cpu_name} Throughput (MEdges/s)"] = fmt6(cpu_throughput)
    row[f"{gpu_name} Traversed Edges (M)"] = fmt6(gpu_edges)
    row[f"{gpu_name} Runtime (s)"] = fmt6(gpu_runtime)
    row[f"{gpu_name} Throughput (MEdges/s)"] = fmt6(gpu_throughput)
    row[f"{label} GPU/CPU Throughput Ratio (x)"] = fmt(ratio(gpu_throughput, cpu_throughput))

rows = []
for dataset in datasets:
    cpu_edges = value(xb_pro, dataset, "TraversedEdges(M)")
    cpu_runtime = value(xb_pro, dataset, "Runtime(s)")
    cpu_throughput = value(xb_pro, dataset, "Throughput(MEdges/s)")
    gpu_edges = value(xb_pp, dataset, "TraversedEdges(M)")
    gpu_runtime = value(xb_pp, dataset, "Runtime(s)")
    gpu_throughput = value(xb_pp, dataset, "Throughput(MEdges/s)")
    row = {
        "Dataset": dataset,
        "XB-Pro Traversed Edges (M)": fmt6(cpu_edges),
        "XB-Pro Runtime (s)": fmt6(cpu_runtime),
        "XB-Pro Throughput (MEdges/s)": fmt6(cpu_throughput),
        "XB++ Traversed Edges (M)": fmt6(gpu_edges),
        "XB++ Runtime (s)": fmt6(gpu_runtime),
        "XB++ Throughput (MEdges/s)": fmt6(gpu_throughput),
        "XB GPU/CPU Throughput Ratio (x)": fmt(ratio(gpu_throughput, cpu_throughput)),
    }
    append_algorithm_columns(row, "BFS", "BFS-Ligra", "BFS-Gunrock", bfs_ligra, bfs_gunrock, dataset)
    append_algorithm_columns(row, "SSSP", "SSSP-Ligra", "SSSP-Gunrock", sssp_ligra, sssp_gunrock, dataset)
    append_algorithm_columns(row, "MSSP", "MSSP-Ligra", "MSSP-Gunrock", multisssp_ligra, multisssp_gunrock, dataset)
    rows.append(row)

output = Path(args.output)
output.parent.mkdir(parents=True, exist_ok=True)
pd.DataFrame(rows).to_csv(output, index=False)
print(f"Table-15 CSV generated at: {output}")
