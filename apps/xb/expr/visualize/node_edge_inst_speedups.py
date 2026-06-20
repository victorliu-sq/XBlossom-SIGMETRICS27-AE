import numpy as np
import matplotlib.pyplot as plt
from matplotlib.ticker import LogLocator, FuncFormatter

# ----------------------------
# Data (XB-Pro instruction rates)
# ----------------------------
datasets = [
    "Amazon", "GPlus", "HiggsNets", "Hyperlink", "LiveJournal",
    "Patent", "StackOverflow", "Twitch", "Wikipedia", "YouTube"
]

instr_node = np.array([
    13.8447, 39.6431, 12.9226, 14.1869,  9.0197,
    7.5162, 10.6091, 22.5051, 12.1539,  9.6311
])

instr_edge = np.array([
    31.2040, 52.8390, 39.9702, 37.0964, 29.8026,
    25.0857, 36.1665, 47.0584, 31.0884, 23.3336
])

ratio = instr_edge / instr_node

# ----------------------------
# Robust decimal log formatter
# ----------------------------
def log_decimal_formatter(y, _):
    if y <= 0:
        return ""
    exp = np.log10(y)
    if abs(exp - round(exp)) < 1e-6:
        return f"{y:g}"   # 0.1, 1, 10
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

    # Bars (real values, no normalization)
    ax.bar(
        bar_x,
        [instr_node[i], instr_edge[i]],
        width=BAR_WIDTH,
        color=[colors["node"], colors["edge"]],
        edgecolor="black",
        linewidth=1.0
    )

    # Ratio annotation
    ax.text(
        bar_x[1],
        instr_edge[i] * 1.25,
        f"{ratio[i]:.2f}×",
        ha="center",
        va="bottom",
        fontsize=6,
        fontweight="bold",
        color="black"
    )

    ax.set_title(name, fontsize=7)

    ax.set_xticks(tick_x, ["Node", "Edge"])
    ax.tick_params(axis="x", labelsize=5, pad=1)

    ax.set_xlim(-0.6, 0.6)

    # ---- LOG SCALE ----
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

# Row label
# fig.text(
#     0.010, 0.50,
#     "XB-Pro Instr. Rate (GIPS)",
#     rotation=90,
#     va="center",
#     fontsize=6,
#     fontweight="bold"
# )

fig.savefig("xb_pro_instr_rate.png", dpi=2400, bbox_inches="tight")
plt.show()
