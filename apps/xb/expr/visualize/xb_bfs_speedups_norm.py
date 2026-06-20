import numpy as np
import matplotlib.pyplot as plt
from matplotlib.ticker import MaxNLocator

# ----------------------------
# Data
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

xb_norm  = [np.ones_like(speedup_xb), 1.0 / speedup_xb]
bfs_norm = [np.ones_like(speedup_bfs), 1.0 / speedup_bfs]

RED_THRESHOLD = 1.25

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
# Figure
# ----------------------------
fig, axes = plt.subplots(
    2, len(datasets),
    figsize=(7.0, 2.1),
    constrained_layout=False
)

fig.subplots_adjust(
    left=0.055,
    right=0.975,
    bottom=0.10,
    top=0.88,
    wspace=0.35,
    hspace=0.30
)

BAR_WIDTH = 0.35
bar_x  = [-0.25, 0.25]   # bars close
tick_x = [-0.35, 0.35]   # labels separated

for i, name in enumerate(datasets):
    # -------- X-Blossom --------
    ax = axes[0, i]
    ax.bar(
        bar_x,
        [1.0, xb_norm[1][i]],
        width=BAR_WIDTH,
        color=[colors["cpu"], colors["gpu"]],
        edgecolor="black",
        linewidth=1.0
    )

    ax.text(
        bar_x[1],
        xb_norm[1][i] + 0.05,
        f"{speedup_xb[i]:.2g}×",
        ha="center",
        va="bottom",
        fontsize=7,
        fontweight="bold" if speedup_xb[i] <= RED_THRESHOLD else "normal",
        color="red" if speedup_xb[i] <= RED_THRESHOLD else "black"
    )

    ax.set_title(name, fontsize=8)
    ax.set_xticks(tick_x, ["XB-Pro", "XB++"])
    ax.tick_params(axis="x", labelsize=6)
    ax.set_xlim(-0.6, 0.6)
    ax.set_ylim(0, max(1.1, xb_norm[1][i] * 1.35))

    # ✅ y-axis ticks: show labels only on first column (avoid clutter)
    ax.yaxis.set_major_locator(MaxNLocator(nbins=3))
    if i == 0:
        ax.tick_params(axis="y", labelsize=6, length=2)
    else:
        ax.tick_params(axis="y", labelleft=False, length=2)
        # ax.spines["left"].set_visible(False)  # optional: remove extra y-axis spine

    ax.grid(axis="y", linestyle=":", linewidth=0.5)

    # -------- BFS --------
    ax = axes[1, i]
    ax.bar(
        bar_x,
        [1.0, bfs_norm[1][i]],
        width=BAR_WIDTH,
        color=[colors["cpu"], colors["gpu"]],
        edgecolor="black",
        linewidth=1.0
    )

    ax.text(
        bar_x[1],
        bfs_norm[1][i] + 0.05,
        f"{speedup_bfs[i]:.2g}×",
        ha="center",
        va="bottom",
        fontsize=7,
        fontweight="bold" if speedup_bfs[i] <= RED_THRESHOLD else "normal",
        color="red" if speedup_bfs[i] <= RED_THRESHOLD else "black"
    )

    ax.set_xticks(tick_x, ["Ligra", "Gunrock"])
    ax.tick_params(axis="x", labelsize=6)
    ax.set_xlim(-0.6, 0.6)
    ax.set_ylim(0, max(1.1, bfs_norm[1][i] * 1.35))

    # ✅ y-axis ticks: show labels only on first column (avoid clutter)
    ax.yaxis.set_major_locator(MaxNLocator(nbins=3))
    if i == 0:
        ax.tick_params(axis="y", labelsize=6, length=2)
    else:
        ax.tick_params(axis="y", labelleft=False, length=2)
        # ax.spines["left"].set_visible(False)  # optional: remove extra y-axis spine

    ax.grid(axis="y", linestyle=":", linewidth=0.5)

# Row labels
fig.text(0.010, 0.69, "X-Blossom", rotation=90, va="center", fontsize=8)
fig.text(0.010, 0.30, "BFS", rotation=90, va="center", fontsize=8)

fig.savefig("xb_bfs_speedup.png", dpi=2400, bbox_inches="tight")
plt.show()
