#!/usr/bin/env python3
import argparse
from pathlib import Path
import numpy as np
import pandas as pd

parser = argparse.ArgumentParser(description="Generate memory table for XB plus BFS/BC/SSSP")
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

def read_llc(path):
    df = pd.read_csv(path)
    return {normalize(row[0]): (float(row[1]), float(row[2])) for row in df.itertuples(index=False)}

def read_bw(path, required=True):
    if not path or not Path(path).exists():
        if required:
            raise FileNotFoundError(path)
        return {}
    df = pd.read_csv(path)
    return {normalize(row[0]): float(row[1]) for row in df.itertuples(index=False)}

def llc_arr(map_, datasets, idx):
    return np.array([map_.get(normalize(d), (np.nan, np.nan))[idx] for d in datasets], dtype=float)

def bw_arr(map_, datasets):
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

def fmt2(x):
    return "NA" if not np.isfinite(x) else f"{x:.2f}"

def fmt6(x):
    return "NA" if not np.isfinite(x) else f"{x:.6f}"

datasets = [
    "GPlus", "Twitch", "Amazon", "HiggsNets", "Youtube",
    "Hyperlink", "Wikipedia", "Stackoverflow", "Patent", "Livejournal"
]

xb_llc = read_llc(args.xb_pro_csv)
bfs_ligra_llc = read_llc(args.bfs_ligra_csv)
bc_ligra_llc = read_llc(args.bc_ligra_csv)
sssp_ligra_llc = read_llc(args.sssp_ligra_csv)
xbpp_bw_map = read_bw(args.xb_pp_csv)
bfs_gunrock_bw_map = read_bw(args.bfs_gunrock_csv)
bc_gunrock_bw_map = read_bw(args.bc_gunrock_csv)
sssp_gunrock_bw_map = read_bw(args.sssp_gunrock_csv)

xb_miss_rate = llc_arr(xb_llc, datasets, 0)
xb_miss_freq = llc_arr(xb_llc, datasets, 1)
bfs_ligra_rate = llc_arr(bfs_ligra_llc, datasets, 0)
bc_ligra_rate = llc_arr(bc_ligra_llc, datasets, 0)
sssp_ligra_rate = llc_arr(sssp_ligra_llc, datasets, 0)
bfs_ligra_freq = llc_arr(bfs_ligra_llc, datasets, 1)
bc_ligra_freq = llc_arr(bc_ligra_llc, datasets, 1)
sssp_ligra_freq = llc_arr(sssp_ligra_llc, datasets, 1)
xbpp_bw = bw_arr(xbpp_bw_map, datasets)
bfs_gunrock_bw = bw_arr(bfs_gunrock_bw_map, datasets)
bc_gunrock_bw = bw_arr(bc_gunrock_bw_map, datasets)
sssp_gunrock_bw = bw_arr(sssp_gunrock_bw_map, datasets)

table = pd.DataFrame({
    "Dataset": datasets,
    "LLC Miss Rate XB-Pro (%)": xb_miss_rate,
    "LLC Miss Rate BFS-Ligra (%)": bfs_ligra_rate,
    "LLC Miss Rate BC-Ligra (%)": bc_ligra_rate,
    "LLC Miss Rate SSSP-Ligra (%)": sssp_ligra_rate,
    "LLC Miss Freq XB-Pro": xb_miss_freq,
    "LLC Miss Freq BFS-Ligra": bfs_ligra_freq,
    "LLC Miss Freq BC-Ligra": bc_ligra_freq,
    "LLC Miss Freq SSSP-Ligra": sssp_ligra_freq,
    "Effective BW XB++ (GB/s)": xbpp_bw,
    "Effective BW BFS-Gunrock (GB/s)": bfs_gunrock_bw,
    "Effective BW BC-Gunrock (GB/s)": bc_gunrock_bw,
    "Effective BW SSSP-Gunrock (GB/s)": sssp_gunrock_bw,
})

table = append_average_row(table)
for col in table.columns.drop("Dataset"):
    table[col] = table[col].map(fmt6 if "Freq" in col else fmt2)

output = Path(args.output)
output.parent.mkdir(parents=True, exist_ok=True)
table.to_csv(output, index=False)
print(f"Table-10 CSV generated at: {output}")
