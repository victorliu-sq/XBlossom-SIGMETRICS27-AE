#!/usr/bin/env python3
import argparse
from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import LogLocator, FuncFormatter

parser = argparse.ArgumentParser(description="Plot runtime for XB plus BFS/MSSP/SSSP")
parser.add_argument("--xb_pro_csv", required=True)
parser.add_argument("--xb_pp_csv", required=True)
parser.add_argument("--bfs_ligra_csv", required=True)
parser.add_argument("--multisssp_ligra_csv", required=True)
parser.add_argument("--sssp_ligra_csv", required=True)
parser.add_argument("--bfs_gunrock_csv", required=True)
parser.add_argument("--multisssp_gunrock_csv", required=True)
parser.add_argument("--sssp_gunrock_csv", required=True)
parser.add_argument("--output", required=True)
args = parser.parse_args()

def normalize(name):
    return str(name).strip().lower()

def parse_value(value):
    try:
        return float(value)
    except (TypeError, ValueError):
        return np.nan

def read_csv_value_map(path, required=True):
    if not path or not Path(path).exists():
        if required:
            raise FileNotFoundError(path)
        return {}
    df = pd.read_csv(path)
    return {normalize(row[0]): parse_value(row[1]) for row in df.iloc[:, :2].itertuples(index=False)}

def values(map_, names):
    return np.array([map_.get(normalize(d), np.nan) for d in names], dtype=float)

def positive_min(*arrays):
    vals = np.concatenate([a[np.isfinite(a) & (a > 0)] for a in arrays])
    return vals.min() if vals.size else 1.0

def positive_max(*arrays):
    vals = np.concatenate([a[np.isfinite(a) & (a > 0)] for a in arrays])
    return vals.max() if vals.size else 10.0

def log_decimal_formatter(y, _):
    if y <= 0:
        return ""
    exp = np.log10(y)
    if abs(exp - round(exp)) < 1e-6:
        return f"{y:g}"
    return ""

datasets = [
    "GPlus", "Twitch", "Amazon", "HiggsNets", "Youtube",
    "Hyperlink", "Wikipedia", "Stackoverflow", "Patent", "Livejournal"
]

xb_pro = values(read_csv_value_map(args.xb_pro_csv), datasets)
xb_pp = values(read_csv_value_map(args.xb_pp_csv), datasets)
pairs = [
    ("X-Blossom", "XB-Pro", "XB++", xb_pro, xb_pp),
    ("BFS", "Ligra", "Gunrock", values(read_csv_value_map(args.bfs_ligra_csv), datasets), values(read_csv_value_map(args.bfs_gunrock_csv), datasets)),
    ("SSSP", "Ligra", "Gunrock", values(read_csv_value_map(args.sssp_ligra_csv), datasets), values(read_csv_value_map(args.sssp_gunrock_csv), datasets)),
    ("MSSP", "Ligra", "Gunrock", values(read_csv_value_map(args.multisssp_ligra_csv), datasets), values(read_csv_value_map(args.multisssp_gunrock_csv), datasets)),
]

plt.rcParams.update({"font.size": 7, "axes.linewidth": 1.0})
fig, axes = plt.subplots(len(pairs), len(datasets), figsize=(7.0, 3.7))
fig.subplots_adjust(left=0.055, right=0.955, bottom=0.07, top=0.92, wspace=0.35, hspace=0.42)

colors = ["#c7c7c7", "#636363"]
bar_x = [-0.25, 0.25]
tick_x = [-0.35, 0.35]
bar_width = 0.35
red_threshold = 1.0

for row, (row_label, cpu_label, gpu_label, cpu, gpu) in enumerate(pairs):
    ymin = positive_min(cpu, gpu) * 0.8
    ymax_scale = 3.0 if row_label == "BFS" else 1.8
    ymax = positive_max(cpu, gpu) * ymax_scale
    for col, dataset in enumerate(datasets):
        ax = axes[row, col]
        vals = [cpu[col], gpu[col]]
        ax.bar(bar_x, vals, width=bar_width, color=colors, edgecolor="black")
        if np.isfinite(vals[0]) and np.isfinite(vals[1]) and vals[1] > 0:
            ratio = vals[0] / vals[1]
            ax.text(bar_x[1], vals[1] * 1.35, f"{ratio:.2g}x",
                    ha="center", va="bottom", fontsize=6,
                    color="red" if ratio < red_threshold else "black",
                    fontweight="bold" if ratio < red_threshold else "normal")
        elif not np.isfinite(vals[1]):
            ax.text(bar_x[1], ymin * 1.2, "n/a", ha="center", va="bottom", fontsize=6)

        if row == 0:
            ax.set_title(dataset, fontsize=7)
        ax.set_xticks(tick_x, [cpu_label, gpu_label])
        ax.tick_params(axis="x", labelsize=5, pad=1)
        ax.set_xlim(-0.6, 0.6)
        ax.set_yscale("log")
        ax.set_ylim(ymin, ymax)
        ax.yaxis.set_major_locator(LogLocator(base=10))
        ax.yaxis.set_major_formatter(FuncFormatter(log_decimal_formatter))
        if col == 0:
            ax.set_ylabel("Runtime (s)", fontsize=6, labelpad=2)
            ax.tick_params(axis="y", labelsize=6, pad=1)
        else:
            ax.set_yticklabels([])
        ax.grid(axis="y", which="major", linestyle=":", linewidth=0.4)
    row_bbox = axes[row, -1].get_position()
    row_center = (row_bbox.y0 + row_bbox.y1) / 2
    fig.text(0.975, row_center, row_label,
             rotation=90, va="center", ha="left", fontsize=8, fontweight="bold")

output = Path(args.output)
output.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(output, dpi=2400, bbox_inches="tight")
