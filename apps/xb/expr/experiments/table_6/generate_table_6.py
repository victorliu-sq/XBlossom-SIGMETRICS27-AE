#!/usr/bin/env python3

import argparse
import pandas as pd
import numpy as np

# ----------------------------
# Argument parsing
# ----------------------------
parser = argparse.ArgumentParser(description="Generate Table-6 CSV")
parser.add_argument("--xb_pro_csv", required=True)
parser.add_argument("--xb_pp_csv", required=True)
parser.add_argument("--bfs_ligra_csv", required=True)
parser.add_argument("--bfs_gunrock_csv", required=True)
args = parser.parse_args()

# ----------------------------
# Helpers
# ----------------------------
def normalize(name: str) -> str:
    return name.strip().lower()

def read_llc_csv(path):
    """
    Dataset,AvgLLCMissRate(%),LLCMissFreq(GMiss/s)
    """
    df = pd.read_csv(path)
    df.iloc[:, 0] = df.iloc[:, 0].apply(normalize)
    return {
        row[0]: (float(row[1]), float(row[2]))
        for row in df.itertuples(index=False)
    }

def read_bw_csv(path):
    """
    Dataset,EffectiveMemoryBandwidth(GB/s)
    """
    df = pd.read_csv(path)
    df.iloc[:, 0] = df.iloc[:, 0].apply(normalize)
    return {
        row[0]: float(row[1])
        for row in df.itertuples(index=False)
    }

def require(m, k, src):
    if k not in m:
        raise KeyError(f"Dataset '{k}' missing in {src}")
    return m[k]

# ----------------------------
# Canonical dataset order (paper order)
# ----------------------------
datasets = [
    "GPlus",
    "Twitch",
    "Amazon",
    "HiggsNets",
    "Youtube",
    "Hyperlink",
    "Wikipedia",
    "Stackoverflow",
    "Patent",
    "Livejournal",
]
datasets_n = [normalize(d) for d in datasets]

# ----------------------------
# Load CSVs (order-independent)
# ----------------------------
ligra_llc = read_llc_csv(args.bfs_ligra_csv)
xb_llc    = read_llc_csv(args.xb_pro_csv)
gunrock_bw = read_bw_csv(args.bfs_gunrock_csv)
xbpp_bw    = read_bw_csv(args.xb_pp_csv)

# ----------------------------
# Assemble ordered values
# ----------------------------
ligra_miss_rate = np.array([require(ligra_llc, d, args.bfs_ligra_csv)[0] for d in datasets_n])
ligra_miss_freq = np.array([require(ligra_llc, d, args.bfs_ligra_csv)[1] for d in datasets_n])

xb_miss_rate = np.array([require(xb_llc, d, args.xb_pro_csv)[0] for d in datasets_n])
xb_miss_freq = np.array([require(xb_llc, d, args.xb_pro_csv)[1] for d in datasets_n])

gunrock_bw_arr = np.array([require(gunrock_bw, d, args.bfs_gunrock_csv) for d in datasets_n])
xbpp_bw_arr    = np.array([require(xbpp_bw, d, args.xb_pp_csv) for d in datasets_n])

# ----------------------------
# Ratios
# ----------------------------
miss_rate_ratio = xb_miss_rate / ligra_miss_rate
miss_freq_ratio = xb_miss_freq / ligra_miss_freq
bw_ratio        = xbpp_bw_arr / gunrock_bw_arr

# ----------------------------
# Build Table-6
# ----------------------------
table = pd.DataFrame({
    "Dataset": datasets,

    "LLC Miss Rate BFS-Ligra (%)": ligra_miss_rate,
    "LLC Miss Rate XB-Pro (%)": xb_miss_rate,
    "Ratio (×)": miss_rate_ratio,

    "LLC Miss Freq BFS-Ligra": ligra_miss_freq,
    "LLC Miss Freq XB-Pro": xb_miss_freq,
    "Ratio (×) ": miss_freq_ratio,

    "Effective BW BFS-Gunrock (GB/s)": gunrock_bw_arr,
    "Effective BW XB++ (GB/s)": xbpp_bw_arr,
    "Ratio (×)  ": bw_ratio,
})

# ----------------------------
# Formatting (paper style)
# ----------------------------
for col in table.columns[1:]:
    if "Freq" in col:
        table[col] = table[col].map(lambda x: f"{x:.6f}")
    else:
        table[col] = table[col].map(lambda x: f"{x:.2f}")

# ----------------------------
# Output
# ----------------------------
output_path = "data/results/table_6.csv"
table.to_csv(output_path, index=False)

print(f"✅ Table-6 CSV generated at {output_path}")
