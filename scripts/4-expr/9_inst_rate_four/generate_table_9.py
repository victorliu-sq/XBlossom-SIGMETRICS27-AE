#!/usr/bin/env python3
import argparse
from pathlib import Path
import numpy as np
import pandas as pd

parser = argparse.ArgumentParser(description="Generate instruction-rate table for XB plus BFS/BC/SSSP")
parser.add_argument("--xb_pro_csv", required=True)
parser.add_argument("--xb_pp_csv", required=True)
parser.add_argument("--bfs_ligra_csv", required=True)
parser.add_argument("--bc_ligra_csv", required=True)
parser.add_argument("--sssp_ligra_csv", required=True)
parser.add_argument("--bfs_gunrock_csv", required=True)
parser.add_argument("--bc_gunrock_csv", required=True)
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

def arr(map_, datasets):
    return np.array([map_.get(normalize(d), np.nan) for d in datasets], dtype=float)

def ratio(num, den):
    return np.divide(num, den, out=np.full_like(num, np.nan, dtype=float), where=np.isfinite(den) & (den != 0))

def append_average_row(table):
    avg = {"Dataset": "Average"}
    for col in table.columns.drop("Dataset"):
        values = pd.to_numeric(table[col], errors="coerce").to_numpy(dtype=float)
        finite = values[np.isfinite(values)]
        avg[col] = np.nan if finite.size == 0 else float(np.mean(finite))
    return pd.concat([table, pd.DataFrame([avg])], ignore_index=True)

def fmt(x):
    return "NA" if not np.isfinite(x) else f"{x:.2f}"

datasets = [
    "GPlus", "Twitch", "Amazon", "HiggsNets", "Youtube",
    "Hyperlink", "Wikipedia", "Stackoverflow", "Patent", "Livejournal"
]

xb_pro = arr(read_csv_value_map(args.xb_pro_csv), datasets)
xb_pp = arr(read_csv_value_map(args.xb_pp_csv), datasets)
bfs_ligra = arr(read_csv_value_map(args.bfs_ligra_csv), datasets)
bc_ligra = arr(read_csv_value_map(args.bc_ligra_csv), datasets)
sssp_ligra = arr(read_csv_value_map(args.sssp_ligra_csv), datasets)
bfs_gunrock = arr(read_csv_value_map(args.bfs_gunrock_csv), datasets)
bc_gunrock = arr(read_csv_value_map(args.bc_gunrock_csv), datasets)
sssp_gunrock = arr(read_csv_value_map(args.sssp_gunrock_csv), datasets)

table = pd.DataFrame({
    "Dataset": datasets,
    "XB-Pro": xb_pro,
    "BFS-Ligra": bfs_ligra,
    "BC-Ligra": bc_ligra,
    "SSSP-Ligra": sssp_ligra,
    "XB++": xb_pp,
    "BFS-Gunrock": bfs_gunrock,
    "BC-Gunrock": bc_gunrock,
    "SSSP-Gunrock": sssp_gunrock,
    "BFS Scaling (x)": ratio(bfs_gunrock, bfs_ligra),
    "BC Scaling (x)": ratio(bc_gunrock, bc_ligra),
    "SSSP Scaling (x)": ratio(sssp_gunrock, sssp_ligra),
    "XB Scaling (x)": ratio(xb_pp, xb_pro),
})

table = append_average_row(table)
for col in table.columns.drop("Dataset"):
    table[col] = table[col].map(fmt)

output = Path(args.output)
output.parent.mkdir(parents=True, exist_ok=True)
table.to_csv(output, index=False)
print(f"Table-9 CSV generated at: {output}")
