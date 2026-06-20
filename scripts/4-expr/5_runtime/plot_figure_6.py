import argparse
from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import LogLocator, FuncFormatter
from matplotlib.lines import Line2D

# ----------------------------
# Argument parsing (NEW)
# ----------------------------
parser = argparse.ArgumentParser(
    description="Plot XB and BFS runtimes (CSV-driven, original style)"
)
parser.add_argument("--xb_pro_csv", required=True)
parser.add_argument("--xb_pp_csv", required=True)
parser.add_argument("--bfs_ligra_csv", required=True)
parser.add_argument("--bfs_gunrock_csv", required=True)

args = parser.parse_args()

# ----------------------------
# Helper functions (NEW)
# ----------------------------
def normalize(name: str) -> str:
    return name.strip().lower()

def read_csv_value_map(path: str) -> dict:
    """
    Reads CSV assuming:
      col 0 = dataset name
      col 1 = value
    Returns: dict[dataset -> value]
    """
    df = pd.read_csv(path)
    if df.shape[1] < 2:
        raise ValueError(f"{path} must have at least 2 columns")

    return {
        normalize(row[0]): float(row[1])
        for row in df.iloc[:, :2].itertuples(index=False)
    }

# ----------------------------
# Dataset order (UNCHANGED)
# ----------------------------
datasets = [
    "GPlus", "Twitch", "Amazon", "HiggsNets", "Youtube",
    "Hyperlink", "Wikipedia", "Stackoverflow", "Patent", "Livejournal"
]

datasets_norm = [normalize(d) for d in datasets]

# ----------------------------
# Load data from CSVs (REPLACED)
# ----------------------------
xb_pro_map = read_csv_value_map(args.xb_pro_csv)
xb_pp_map = read_csv_value_map(args.xb_pp_csv)
ligra_map = read_csv_value_map(args.bfs_ligra_csv)
gunrock_map = read_csv_value_map(args.bfs_gunrock_csv)

xb_pro = np.array([xb_pro_map[d] for d in datasets_norm])
xb_pp  = np.array([xb_pp_map[d]  for d in datasets_norm])
ligra  = np.array([ligra_map[d]  for d in datasets_norm])
gunrock = np.array([gunrock_map[d] for d in datasets_norm])

# ----------------------------
# Speedups (UNCHANGED)
# ----------------------------
speedup_xb  = xb_pro / xb_pp
speedup_bfs = ligra / gunrock

RED_THRESHOLD = 1.25

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
# Style (UNCHANGED)
# ----------------------------
plt.rcParams.update({
    "font.size": 7,
    "axes.linewidth": 1.0,
})

colors = {
    "cpu": "#c7c7c7",
    "gpu": "#636363",
}

# ----------------------------
# Shared log limits (UNCHANGED)
# ----------------------------
xb_min = min(xb_pro.min(), xb_pp.min()) * 0.8
xb_max = max(xb_pro.max(), xb_pp.max()) * 1.8

bfs_min = min(ligra.min(), gunrock.min()) * 0.8
bfs_max = max(ligra.max(), gunrock.max()) * 1.8

# ----------------------------
# Figure (UNCHANGED)
# ----------------------------
fig, axes = plt.subplots(2, len(datasets), figsize=(7.0, 2.1))

fig.subplots_adjust(
    left=0.055, right=0.955, bottom=0.08, top=0.90,
    wspace=0.35, hspace=0.30
)

BAR_WIDTH = 0.35
bar_x = [-0.25, 0.25]
tick_x = [-0.35, 0.35]

# ----------------------------
# Plot loop (UNCHANGED)
# ----------------------------
for i, name in enumerate(datasets):

    # -------- X-Blossom --------
    ax = axes[0, i]
    ax.bar(bar_x, [xb_pro[i], xb_pp[i]],
           width=BAR_WIDTH,
           color=[colors["cpu"], colors["gpu"]],
           edgecolor="black")

    ax.text(
        bar_x[1], xb_pp[i] * 1.35,
        f"{speedup_xb[i]:.2g}×",
        ha="center", va="bottom",
        fontsize=6,
        color="red" if speedup_xb[i] <= RED_THRESHOLD else "black",
        fontweight="bold" if speedup_xb[i] <= RED_THRESHOLD else "normal"
    )

    ax.set_title(name, fontsize=7)
    ax.set_xticks(tick_x, ["XB-Pro", "XB++"])
    ax.tick_params(axis="x", labelsize=5, pad=1)
    ax.set_xlim(-0.6, 0.6)

    ax.set_yscale("log")
    ax.set_ylim(xb_min, xb_max)
    ax.yaxis.set_major_locator(LogLocator(base=10))
    ax.yaxis.set_major_formatter(FuncFormatter(log_decimal_formatter))

    if i == 0:
        ax.set_ylabel("Runtime (s)", fontsize=6, labelpad=2)
        ax.tick_params(axis="y", labelsize=6, pad=1)
    else:
        ax.set_yticklabels([])

    ax.grid(axis="y", which="major", linestyle=":", linewidth=0.4)

    # -------- BFS --------
    ax = axes[1, i]
    ax.bar(bar_x, [ligra[i], gunrock[i]],
           width=BAR_WIDTH,
           color=[colors["cpu"], colors["gpu"]],
           edgecolor="black")

    ax.text(
        bar_x[1], gunrock[i] * 1.35,
        f"{speedup_bfs[i]:.2g}×",
        ha="center", va="bottom",
        fontsize=6,
        color="red" if speedup_bfs[i] <= RED_THRESHOLD else "black",
        fontweight="bold" if speedup_bfs[i] <= RED_THRESHOLD else "normal"
    )

    ax.set_xticks(tick_x, ["Ligra", "Gunrock"])
    ax.tick_params(axis="x", labelsize=5, pad=1)
    ax.set_xlim(-0.6, 0.6)

    ax.set_yscale("log")
    ax.set_ylim(bfs_min, bfs_max)
    ax.yaxis.set_major_locator(LogLocator(base=10))
    ax.yaxis.set_major_formatter(FuncFormatter(log_decimal_formatter))

    if i == 0:
        ax.set_ylabel("Runtime (s)", fontsize=6, labelpad=2)
        ax.tick_params(axis="y", labelsize=6, pad=1)
    else:
        ax.set_yticklabels([])

    ax.grid(axis="y", which="major", linestyle=":", linewidth=0.4)

# ----------------------------
# Row labels (UNCHANGED)
# ----------------------------
fig.text(0.975, 0.75, "X-Blossom",
         rotation=90, va="center", ha="left",
         fontsize=8, fontweight="bold")

fig.text(0.975, 0.25, "BFS",
         rotation=90, va="center", ha="left",
         fontsize=8, fontweight="bold")

# ----------------------------
# Save (UNCHANGED)
# ----------------------------
output_path = Path(__file__).resolve().parents[3] / "results/5_runtime/figure_6.png"
output_path.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(output_path, dpi=2400, bbox_inches="tight")
# plt.show()
