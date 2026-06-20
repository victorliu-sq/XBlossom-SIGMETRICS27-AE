#!/usr/bin/env python3
import argparse
import csv
from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
from matplotlib.ticker import FixedLocator, FixedFormatter


DATASET_ORDER = {
    "Livejournal": 0,
    "Stackoverflow": 1,
    "Patent": 2,
}


def read_rows(path):
    with path.open(newline="") as f:
        return list(csv.DictReader(f))


def format_x(value, unit):
    int_value = int(round(value))
    suffix = unit if int_value == 1 else f"{unit}s"
    return f"{int_value} {suffix}"


def include_row(row, x_key, x_upper):
    if row["Dataset"] not in DATASET_ORDER:
        return False
    if x_upper is not None and float(row[x_key]) > x_upper:
        return False
    return True


def group_by_dataset(rows, x_key, x_upper):
    grouped = {}
    for row in rows:
        if not include_row(row, x_key, x_upper):
            continue
        grouped.setdefault(row["Dataset"], []).append(row)
    return grouped


def add_axis_arrows(ax):
    for side in ("top", "right", "bottom", "left"):
        ax.spines[side].set_visible(False)
    ax.tick_params(axis="both", length=0)
    ax.annotate(
        "",
        xy=(1.035, 0),
        xytext=(0, 0),
        xycoords="axes fraction",
        arrowprops=dict(arrowstyle="-|>", lw=1.8, color="black"),
        annotation_clip=False,
    )
    ax.annotate(
        "",
        xy=(0, 1.045),
        xytext=(0, 0),
        xycoords="axes fraction",
        arrowprops=dict(arrowstyle="-|>", lw=1.8, color="black"),
        annotation_clip=False,
    )


def concrete_ticks(y_max):
    candidates = [10, 50, 150]
    return [tick for tick in candidates if tick <= y_max]


def plot_panel(ax, rows, x_key, title, xlabel, x_unit, ylabel, y_upper, x_upper=None):
    grouped = group_by_dataset(rows, x_key, x_upper)
    all_x_values = sorted({
        float(row[x_key])
        for row in rows
        if include_row(row, x_key, x_upper)
    })
    x_positions_by_value = {value: idx for idx, value in enumerate(all_x_values)}
    colors = {
        "Livejournal": "#111111",
        "Stackoverflow": "#4a4a4a",
        "Patent": "#777777",
    }
    markers = {
        "Livejournal": "o",
        "Stackoverflow": "s",
        "Patent": "^",
    }
    linestyles = {
        "Livejournal": "-",
        "Stackoverflow": "--",
        "Patent": "-.",
    }

    for dataset, dataset_rows in sorted(grouped.items(), key=lambda item: DATASET_ORDER[item[0]]):
        ordered = sorted(dataset_rows, key=lambda r: float(r[x_key]))
        x_values = [float(r[x_key]) for r in ordered]
        y_values = [float(r["Speedup"]) for r in ordered]
        x_positions = [x_positions_by_value[value] for value in x_values]
        line_color = colors.get(dataset, "#8b0000")
        marker = markers.get(dataset, "o")
        linestyle = linestyles.get(dataset, "-")
        ax.plot(
            x_positions,
            y_values,
            marker=marker,
            linestyle=linestyle,
            linewidth=1.8,
            markersize=5.8,
            color=line_color,
            markerfacecolor="white",
            markeredgecolor=line_color,
            markeredgewidth=1.4,
            label=dataset,
        )

    y_ticks = concrete_ticks(y_upper)
    ax.set_yscale("log")
    ax.set_ylim(1, y_upper)
    ax.yaxis.set_major_locator(FixedLocator(y_ticks))
    ax.yaxis.set_major_formatter(FixedFormatter([str(tick) for tick in y_ticks]))
    ax.grid(True, axis="y", which="major", linewidth=0.7, alpha=0.28)
    ax.grid(True, axis="x", which="major", linewidth=0.7, alpha=0.28)
    ax.set_xlim(-0.45, len(all_x_values) - 0.55)
    ax.set_xticks(list(range(len(all_x_values))))
    ax.set_xticklabels([str(int(round(value))) for value in all_x_values], rotation=0)
    ax.set_xlabel(xlabel, fontsize=12, labelpad=8)
    ax.set_ylabel(ylabel, fontsize=12, labelpad=1)
    ax.set_title(title, fontsize=13, fontweight="bold", pad=13)
    ax.tick_params(axis="both", labelsize=10)
    ax.legend(
        loc="upper left",
        ncol=1,
        frameon=True,
        edgecolor="black",
        fancybox=False,
        fontsize=8,
        handlelength=1.8,
        borderpad=0.35,
        labelspacing=0.25,
    )
    add_axis_arrows(ax)


def main():
    parser = argparse.ArgumentParser(description="Plot XB scalability results.")
    parser.add_argument(
        "--results-dir",
        default="results/16_scalability_test",
        help="Directory containing scalability CSV files",
    )
    parser.add_argument(
        "--output",
        default="results/16_scalability_test/plot_scalability.png",
        help="Output figure path",
    )
    args = parser.parse_args()

    results_dir = Path(args.results_dir)
    panels = [
        (
            results_dir / "xb_pro_node_cpu_scalability.csv",
            "Threads",
            "XB-Pro Node-Level",
            "CPU threads",
            "thread",
            "Speedup Over 1 CPU Thread",
            500,
            48,
        ),
        (
            results_dir / "xb_pro_edge_cpu_scalability.csv",
            "Threads",
            "XB-Pro Edge-Level",
            "CPU threads",
            "thread",
            "",
            500,
            48,
        ),
        (
            results_dir / "xb_pp_node_gpu_sm_scalability.csv",
            "MaxCUDASMs",
            "XB++ Node-Level",
            "Max GPU SMs",
            "SM",
            "Speedup Over 1 GPU SM",
            500,
            None,
        ),
        (
            results_dir / "xb_pp_edge_gpu_sm_scalability.csv",
            "MaxCUDASMs",
            "XB++ Edge-Level",
            "Max GPU SMs",
            "SM",
            "",
            500,
            None,
        ),
    ]

    panel_rows = []
    for csv_path, *_ in panels:
        if not csv_path.exists():
            raise FileNotFoundError(csv_path)
        panel_rows.append(read_rows(csv_path))

    plt.rcParams.update({
        "font.size": 14,
        "axes.spines.top": False,
        "axes.spines.right": False,
    })

    fig = plt.figure(figsize=(14, 3.25), constrained_layout=False)
    grid = fig.add_gridspec(
        1,
        5,
        left=0.065,
        right=0.99,
        top=0.78,
        bottom=0.10,
        width_ratios=[1, 1, 0.12, 1, 1],
        wspace=0.14,
    )
    axes = [fig.add_subplot(grid[0, idx]) for idx in (0, 1, 3, 4)]

    for ax, rows, panel in zip(axes, panel_rows, panels):
        _, x_key, title, xlabel, x_unit, ylabel, y_upper, x_upper = panel
        plot_panel(ax, rows, x_key, title, xlabel, x_unit, ylabel, y_upper, x_upper)

    separator_box = grid[0, 2].get_position(fig)
    separator_x = separator_box.x0
    plot_bottom = min(ax.get_position().y0 for ax in axes)
    plot_top = max(ax.get_position().y1 for ax in axes) + 0.04
    fig.add_artist(Line2D(
        [separator_x, separator_x],
        [plot_bottom, plot_top],
        transform=fig.transFigure,
        color="black",
        linewidth=2.4,
        linestyle="--",
        alpha=0.9,
    ))

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output, dpi=300, bbox_inches="tight", pad_inches=0.12)
    print(f"Saved {output}")


if __name__ == "__main__":
    main()
