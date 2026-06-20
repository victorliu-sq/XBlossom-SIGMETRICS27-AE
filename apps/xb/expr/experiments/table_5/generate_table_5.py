#!/usr/bin/env python3

import argparse
import pandas as pd
import numpy as np

# ----------------------------
# Argument parsing
# ----------------------------
parser = argparse.ArgumentParser(
    description="Generate Table-5 instruction-rate comparison CSV"
)
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

def read_csv_value_map(path: str) -> dict:
    """
    Reads CSV assuming:
      col 0 = Dataset
      col 1 = Instruction rate (GIPS)
    Returns: dict[normalized_dataset -> value]
    """
    df = pd.read_csv(path)
    if df.shape[1] < 2:
        raise ValueError(f"{path} must have at least two columns")

    return {
        normalize(row[0]): float(row[1])
        for row in df.iloc[:, :2].itertuples(index=False)
    }

def require(map_, key, source):
    if key not in map_:
        raise KeyError(f"Dataset '{key}' missing in {source}")
    return map_[key]

# ----------------------------
# Dataset order (fixed)
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

datasets_norm = [normalize(d) for d in datasets]

# ----------------------------
# Load CSVs
# ----------------------------
xb_pro_map     = read_csv_value_map(args.xb_pro_csv)
xb_pp_map      = read_csv_value_map(args.xb_pp_csv)
ligra_map      = read_csv_value_map(args.bfs_ligra_csv)
gunrock_map    = read_csv_value_map(args.bfs_gunrock_csv)

# ----------------------------
# Assemble arrays (ordered)
# ----------------------------
xb_pro   = np.array([require(xb_pro_map, d, args.xb_pro_csv) for d in datasets_norm])
xb_pp    = np.array([require(xb_pp_map, d, args.xb_pp_csv) for d in datasets_norm])
ligra    = np.array([require(ligra_map, d, args.bfs_ligra_csv) for d in datasets_norm])
gunrock  = np.array([require(gunrock_map, d, args.bfs_gunrock_csv) for d in datasets_norm])

# ----------------------------
# Compute metrics
# ----------------------------
cpu_ratio   = xb_pro / ligra
gpu_ratio   = xb_pp / gunrock
bfs_scaling = gunrock / ligra
xb_scaling  = xb_pp / xb_pro

# ----------------------------
# Build output table
# ----------------------------
table = pd.DataFrame({
    "Dataset": datasets,
    "BFS-Ligra": ligra,
    "XB-Pro": xb_pro,
    "Ratio (×)": cpu_ratio,
    "BFS-Gunrock": gunrock,
    "XB++": xb_pp,
    "Ratio (×) ": gpu_ratio,
    "BFS Scaling (×)": bfs_scaling,
    "XB Scaling (×)": xb_scaling,
})

# ----------------------------
# Formatting (Table-5 style)
# ----------------------------
float_cols = table.columns.drop("Dataset")
table[float_cols] = table[float_cols].applymap(lambda x: f"{x:.2f}")

# ----------------------------
# Write CSV
# ----------------------------
output_path = "data/results/table_5.csv"
table.to_csv(output_path, index=False)

print(f"✅ Table-5 CSV generated at: {output_path}")
