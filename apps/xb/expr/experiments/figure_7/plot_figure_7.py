import argparse
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import LogLocator, FuncFormatter

# ----------------------------
# Argument parsing
# ----------------------------
parser = argparse.ArgumentParser(
    description="Plot XB-Pro instruction rate from node and edge CSV files"
)
parser.add_argument(
    "--node_csv",
    required=True,
    help="Path to node instruction rate CSV file"
)
parser.add_argument(
    "--edge_csv",
    required=True,
    help="Path to edge instruction rate CSV file"
)

args = parser.parse_args()

# ----------------------------
# Load data from CSV files
# ----------------------------
df_node = pd.read_csv(args.node_csv)
df_edge = pd.read_csv(args.edge_csv)

# Normalize dataset names
df_node["Dataset"] = df_node["Dataset"].str.strip()
df_edge["Dataset"] = df_edge["Dataset"].str.strip()

# Merge to ensure alignment
df = pd.merge(
    df_node,
    df_edge,
    on="Dataset",
    suffixes=("_node", "_edge")
)

datasets = df["Dataset"].tolist()
instr_node = df["InstructionExecRate(GIPS)_node"].to_numpy()
instr_edge = df["InstructionExecRate(GIPS)_edge"].to_numpy()

ratio = instr_edge / instr_node

# ----------------------------
# Robust decimal log formatter
# ----------------------------
def log_decimal_formatter(y, _):
    if y <= 0:
        return ""
    exp = np.log10(y)
    if abs(exp - round(exp)) < 1e-6:
        return f"{y:g}"
    return ""

# ----------------------------
# Style
# ----------------------------
plt.rcParams.update({
    "font.size": 7,
    "axes.linewidth": 1.0,
})

colors = {
    "node": "#c7c7c7",
    "edge": "#636363",
}

# ----------------------------
# Shared log limits
# ----------------------------
y_min = min(instr_node.min(), instr_edge.min()) * 0.7
y_max = max(instr_node.max(), instr_edge.max()) * 1.8

# ----------------------------
# Figure (one row, mini-panels)
# ----------------------------
fig, axes = plt.subplots(
    1, len(datasets),
    figsize=(7.0, 1.2),
    constrained_layout=False
)

fig.subplots_adjust(
    left=0.055,
    right=0.975,
    bottom=0.12,
    top=0.83,
    wspace=0.35,
    hspace=0.0
)

BAR_WIDTH = 0.35
bar_x  = [-0.25, 0.25]
tick_x = [-0.35, 0.35]

for i, name in enumerate(datasets):
    ax = axes[i]

    ax.bar(
        bar_x,
        [instr_node[i], instr_edge[i]],
        width=BAR_WIDTH,
        color=[colors["node"], colors["edge"]],
        edgecolor="black",
        linewidth=1.0
    )

    ax.text(
        bar_x[1],
        instr_edge[i] * 1.25,
        f"{ratio[i]:.2f}×",
        ha="center",
        va="bottom",
        fontsize=6,
        fontweight="bold"
    )

    ax.set_title(name, fontsize=7)

    ax.set_xticks(tick_x, ["Node", "Edge"])
    ax.tick_params(axis="x", labelsize=5, pad=1)
    ax.set_xlim(-0.6, 0.6)

    ax.set_yscale("log")
    ax.set_ylim(y_min, y_max)
    ax.yaxis.set_major_locator(LogLocator(base=10))
    ax.yaxis.set_major_formatter(FuncFormatter(log_decimal_formatter))

    if i == 0:
        ax.set_ylabel("Instr. Rate (GIPS)", fontsize=6, labelpad=2)
        ax.tick_params(axis="y", labelsize=6, pad=1)
    else:
        ax.set_yticklabels([])

    ax.grid(axis="y", which="major", linestyle=":", linewidth=0.4)

# ----------------------------
# Save & show
# ----------------------------
fig.savefig("data/results/figure_7.png", dpi=2400, bbox_inches="tight")
# plt.show()
