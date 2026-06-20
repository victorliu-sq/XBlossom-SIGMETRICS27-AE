#!/usr/bin/env python3
import argparse
from pathlib import Path

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import LogLocator, FuncFormatter


DATASETS = [
    "GPlus", "Twitch", "Amazon", "HiggsNets", "Youtube",
    "Hyperlink", "Wikipedia", "Stackoverflow", "Patent", "Livejournal",
]

DISPLAY_NAMES = {
    "Stackoverflow": "StackOverflow",
    "Livejournal": "LiveJournal",
}


def normalize(name: str) -> str:
    return name.strip().lower()


def read_csv_rows(path: str) -> dict:
    df = pd.read_csv(path)
    return {normalize(row["Dataset"]): row for _, row in df.iterrows()}


def values_for(rows: dict, node_col: str, edge_col: str, speedup_col: str):
    node = []
    edge = []
    speedup = []
    for dataset in DATASETS:
        row = rows[normalize(dataset)]
        node.append(float(row[node_col]))
        edge.append(float(row[edge_col]))
        speedup.append(float(row[speedup_col]))
    return np.array(node), np.array(edge), np.array(speedup)


def log_decimal_formatter(y, _):
    if y <= 0:
        return ""
    exp = np.log10(y)
    if abs(exp - round(exp)) < 1e-6:
        return f"{y:g}"
    return ""


def main():
    parser = argparse.ArgumentParser(
        description="Plot X-Blossom load-balancing runtimes."
    )
    parser.add_argument("--cpu_csv", required=True)
    parser.add_argument("--gpu_csv", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    cpu_rows = read_csv_rows(args.cpu_csv)
    gpu_rows = read_csv_rows(args.gpu_csv)

    cpu_node, cpu_edge, cpu_speedup = values_for(
        cpu_rows, "AvgRuntime_XB(s)", "AvgRuntime_XBPro(s)", "Speedup"
    )
    gpu_node, gpu_edge, gpu_speedup = values_for(
        gpu_rows, "AvgRuntime_XB++NB(s)", "AvgRuntime_XB++(s)", "Speedup"
    )

    plt.rcParams.update({
        "font.size": 7,
        "axes.linewidth": 1.0,
    })

    colors = {
        "node": "#c7c7c7",
        "edge": "#636363",
    }

    cpu_min = min(cpu_node.min(), cpu_edge.min()) * 0.8
    cpu_label_max = (cpu_edge * 1.35).max()
    cpu_max = max(cpu_node.max(), cpu_edge.max(), cpu_label_max) * 2.2
    gpu_min = min(gpu_node.min(), gpu_edge.min()) * 0.8
    gpu_label_max = (gpu_edge * 1.35).max()
    gpu_max = max(gpu_node.max(), gpu_edge.max(), gpu_label_max) * 2.0

    fig, axes = plt.subplots(2, len(DATASETS), figsize=(7.0, 1.75))
    fig.subplots_adjust(
        left=0.055, right=0.955, bottom=0.10, top=0.84,
        wspace=0.35, hspace=0.36
    )

    bar_width = 0.35
    bar_x = [-0.25, 0.25]
    tick_x = [-0.35, 0.35]

    for i, dataset in enumerate(DATASETS):
        display_name = DISPLAY_NAMES.get(dataset, dataset)

        ax = axes[0, i]
        ax.bar(
            bar_x, [cpu_node[i], cpu_edge[i]],
            width=bar_width,
            color=[colors["node"], colors["edge"]],
            edgecolor="black",
        )
        ax.text(
            bar_x[1], cpu_edge[i] * 1.35,
            f"{cpu_speedup[i]:.2g}×",
            ha="center", va="bottom",
            fontsize=6,
            color="red" if cpu_speedup[i] < 1.0 else "black",
            fontweight="bold" if cpu_speedup[i] < 1.0 else "normal",
        )
        ax.set_title(display_name, fontsize=7)
        ax.set_xticks(tick_x, ["Node", "Edge"])
        ax.tick_params(axis="x", labelsize=5, pad=1)
        ax.set_xlim(-0.6, 0.6)
        ax.set_yscale("log")
        ax.set_ylim(cpu_min, cpu_max)
        ax.yaxis.set_major_locator(LogLocator(base=10))
        ax.yaxis.set_major_formatter(FuncFormatter(log_decimal_formatter))
        if i == 0:
            ax.set_ylabel("Runtime (s)", fontsize=6, labelpad=2)
            ax.tick_params(axis="y", labelsize=6, pad=1)
        else:
            ax.set_yticklabels([])
        ax.grid(axis="y", which="major", linestyle=":", linewidth=0.4)

        ax = axes[1, i]
        ax.bar(
            bar_x, [gpu_node[i], gpu_edge[i]],
            width=bar_width,
            color=[colors["node"], colors["edge"]],
            edgecolor="black",
        )
        ax.text(
            bar_x[1], gpu_edge[i] * 1.35,
            f"{gpu_speedup[i]:.2g}×",
            ha="center", va="bottom",
            fontsize=6,
            color="red" if gpu_speedup[i] < 1.0 else "black",
            fontweight="bold" if gpu_speedup[i] < 1.0 else "normal",
        )
        ax.set_xticks(tick_x, ["Node", "Edge"])
        ax.tick_params(axis="x", labelsize=5, pad=1)
        ax.set_xlim(-0.6, 0.6)
        ax.set_yscale("log")
        ax.set_ylim(gpu_min, gpu_max)
        ax.yaxis.set_major_locator(LogLocator(base=10))
        ax.yaxis.set_major_formatter(FuncFormatter(log_decimal_formatter))
        if i == 0:
            ax.set_ylabel("Runtime (s)", fontsize=6, labelpad=2)
            ax.tick_params(axis="y", labelsize=6, pad=1)
        else:
            ax.set_yticklabels([])
        ax.grid(axis="y", which="major", linestyle=":", linewidth=0.4)

    cpu_row_pos = axes[0, -1].get_position()
    gpu_row_pos = axes[1, -1].get_position()
    row_label_x = cpu_row_pos.x1 + 0.004

    fig.text(
        row_label_x, (cpu_row_pos.y0 + cpu_row_pos.y1) / 2, "XB-Pro",
        rotation=90, va="center", ha="left",
        fontsize=8, fontweight="bold",
    )
    fig.text(
        row_label_x, (gpu_row_pos.y0 + gpu_row_pos.y1) / 2, "XB++",
        rotation=90, va="center", ha="left",
        fontsize=8, fontweight="bold",
    )

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path, dpi=2400, bbox_inches="tight")


if __name__ == "__main__":
    main()
