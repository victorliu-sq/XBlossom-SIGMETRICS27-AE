import numpy as np
import matplotlib.pyplot as plt
from matplotlib.ticker import LogLocator, FuncFormatter
from matplotlib.lines import Line2D

# ----------------------------
# Data (seconds)
# ----------------------------
datasets = [
    "GPlus", "Twitch", "Amazon", "HiggsNets", "Youtube",
    "Hyperlink", "Wikipedia", "Stackoverflow", "Patent", "Livejournal"
]

xb_pro = np.array([0.997, 0.276, 0.392, 0.437, 0.298, 3.3, 0.395, 1.05, 4.43, 8.37])
xb_pp  = np.array([0.246, 0.0911, 0.108, 0.105, 0.0224, 0.27, 0.0239, 0.0458, 0.196, 0.357])

ligra   = np.array([1.32, 2.0, 9.79, 3.36, 8.19, 11.91, 11.69, 15.64, 36.18, 35.4])
gunrock = np.array([18.23, 4.44, 2.8, 15.28, 3.444, 11.69, 9.35, 18.96, 4.43, 10.69])

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
# Style
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
# Shared log limits
# ----------------------------
xb_min = min(xb_pro.min(), xb_pp.min()) * 0.8
xb_max = max(xb_pro.max(), xb_pp.max()) * 1.8

bfs_min = min(ligra.min(), gunrock.min()) * 0.8
bfs_max = max(ligra.max(), gunrock.max()) * 1.8

# ----------------------------
# Figure
# ----------------------------
fig, axes = plt.subplots(2, len(datasets), figsize=(7.0, 2.1))

fig.subplots_adjust(
    left=0.055, right=0.955, bottom=0.08, top=0.90,
    wspace=0.35, hspace=0.30
)

BAR_WIDTH = 0.35
bar_x = [-0.25, 0.25]
tick_x = [-0.35, 0.35]

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
# Row labels
# ----------------------------
fig.text(0.975, 0.75, "X-Blossom",
         rotation=90, va="center", ha="left",
         fontsize=8, fontweight="bold")

fig.text(0.975, 0.25, "BFS",
         rotation=90, va="center", ha="left",
         fontsize=8, fontweight="bold")

# ----------------------------
# Horizontal separator
# ----------------------------
# fig.lines.append(
#     Line2D([0.075, 0.955], [0.47, 0.47],
#            transform=fig.transFigure,
#            color="black", linewidth=1.2)
# )

fig.savefig("xb_bfs_runtime.png", dpi=2400, bbox_inches="tight")
plt.show()
