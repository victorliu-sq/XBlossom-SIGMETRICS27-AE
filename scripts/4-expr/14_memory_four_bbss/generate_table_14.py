#!/usr/bin/env python3
import argparse
from pathlib import Path
import sys
import numpy as np
import pandas as pd

sys.path.append(str(Path(__file__).resolve().parents[1]))
from experiment_ci import compact_number

parser = argparse.ArgumentParser(description="Generate memory table for XB plus BFS/MSSP/SSSP")
parser.add_argument("--xb_pro_csv", required=True)
parser.add_argument("--xb_pp_csv", required=True)
parser.add_argument("--bfs_ligra_csv", required=True)
parser.add_argument("--multisssp_ligra_csv", required=True)
parser.add_argument("--sssp_ligra_csv", required=True)
parser.add_argument("--bfs_gunrock_csv", required=True)
parser.add_argument("--multisssp_gunrock_csv", required=True)
parser.add_argument("--sssp_gunrock_csv", required=True)
parser.add_argument("--output", required=True)
parser.add_argument("--tex_output", required=True)
args = parser.parse_args()

def normalize(name):
    return str(name).strip().lower()

def read_llc(path):
    df = pd.read_csv(path)
    result = {}
    for _, row in df.iterrows():
        rate_col = "LLCMissRate(%)" if "LLCMissRate(%)" in df.columns else "AvgLLCMissRate(%)"
        result[normalize(row["Dataset"])] = (
            float(row[rate_col]),
            float(row["LLCMissFreq(GMiss/s)"]),
            float(row.get("LLCMissRateCI(%)", np.nan)),
            float(row.get("LLCMissFreqCI(GMiss/s)", np.nan)),
        )
    return result

def read_bw(path, required=True):
    if not path or not Path(path).exists():
        if required:
            raise FileNotFoundError(path)
        return {}
    df = pd.read_csv(path)
    result = {}
    for _, row in df.iterrows():
        result[normalize(row["Dataset"])] = (
            float(row.iloc[1]),
            float(row.iloc[2]) if len(row) > 2 and "CI" in str(df.columns[2]) else np.nan,
        )
    return result

def llc_arr(map_, datasets, idx):
    return np.array([map_.get(normalize(d), (np.nan, np.nan, np.nan, np.nan))[idx] for d in datasets], dtype=float)

def bw_arr(map_, datasets, idx=0):
    return np.array([map_.get(normalize(d), (np.nan, np.nan))[idx] for d in datasets], dtype=float)

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

def fmt_ci(mean, ci, formatter):
    if not np.isfinite(mean):
        return "NA"
    if not np.isfinite(ci):
        return formatter(mean)
    return f"{formatter(mean)} ± {compact_number(ci)}"

def fmt_tex_value(x, formatter):
    return "NA" if not np.isfinite(x) else formatter(x)

def fmt_tex_value_ci(mean, ci, formatter):
    if not np.isfinite(mean):
        return "NA"
    if not np.isfinite(ci):
        ci = 0.0
    return f"{formatter(mean)} $\\pm$ {compact_number(ci)}"

datasets = [
    "GPlus", "Twitch", "Amazon", "HiggsNets", "Youtube",
    "Hyperlink", "Wikipedia", "Stackoverflow", "Patent", "Livejournal"
]

xb_llc = read_llc(args.xb_pro_csv)
bfs_ligra_llc = read_llc(args.bfs_ligra_csv)
multisssp_ligra_llc = read_llc(args.multisssp_ligra_csv)
sssp_ligra_llc = read_llc(args.sssp_ligra_csv)
xbpp_bw_map = read_bw(args.xb_pp_csv)
bfs_gunrock_bw_map = read_bw(args.bfs_gunrock_csv)
multisssp_gunrock_bw_map = read_bw(args.multisssp_gunrock_csv)
sssp_gunrock_bw_map = read_bw(args.sssp_gunrock_csv)

xb_miss_rate = llc_arr(xb_llc, datasets, 0)
xb_miss_freq = llc_arr(xb_llc, datasets, 1)
xb_miss_rate_ci = llc_arr(xb_llc, datasets, 2)
xb_miss_freq_ci = llc_arr(xb_llc, datasets, 3)
bfs_ligra_rate = llc_arr(bfs_ligra_llc, datasets, 0)
multisssp_ligra_rate = llc_arr(multisssp_ligra_llc, datasets, 0)
sssp_ligra_rate = llc_arr(sssp_ligra_llc, datasets, 0)
bfs_ligra_freq = llc_arr(bfs_ligra_llc, datasets, 1)
multisssp_ligra_freq = llc_arr(multisssp_ligra_llc, datasets, 1)
sssp_ligra_freq = llc_arr(sssp_ligra_llc, datasets, 1)
bfs_ligra_rate_ci = llc_arr(bfs_ligra_llc, datasets, 2)
multisssp_ligra_rate_ci = llc_arr(multisssp_ligra_llc, datasets, 2)
sssp_ligra_rate_ci = llc_arr(sssp_ligra_llc, datasets, 2)
bfs_ligra_freq_ci = llc_arr(bfs_ligra_llc, datasets, 3)
multisssp_ligra_freq_ci = llc_arr(multisssp_ligra_llc, datasets, 3)
sssp_ligra_freq_ci = llc_arr(sssp_ligra_llc, datasets, 3)
xbpp_bw = bw_arr(xbpp_bw_map, datasets)
xbpp_bw_ci = bw_arr(xbpp_bw_map, datasets, 1)
bfs_gunrock_bw = bw_arr(bfs_gunrock_bw_map, datasets)
bfs_gunrock_bw_ci = bw_arr(bfs_gunrock_bw_map, datasets, 1)
multisssp_gunrock_bw = bw_arr(multisssp_gunrock_bw_map, datasets)
multisssp_gunrock_bw_ci = bw_arr(multisssp_gunrock_bw_map, datasets, 1)
sssp_gunrock_bw = bw_arr(sssp_gunrock_bw_map, datasets)
sssp_gunrock_bw_ci = bw_arr(sssp_gunrock_bw_map, datasets, 1)
xb_miss_freq_mill = xb_miss_freq * 1000.0
bfs_ligra_freq_mill = bfs_ligra_freq * 1000.0
multisssp_ligra_freq_mill = multisssp_ligra_freq * 1000.0
sssp_ligra_freq_mill = sssp_ligra_freq * 1000.0
xb_miss_freq_ci_mill = xb_miss_freq_ci * 1000.0
bfs_ligra_freq_ci_mill = bfs_ligra_freq_ci * 1000.0
multisssp_ligra_freq_ci_mill = multisssp_ligra_freq_ci * 1000.0
sssp_ligra_freq_ci_mill = sssp_ligra_freq_ci * 1000.0

table = pd.DataFrame({
    "Dataset": datasets,
    "LLC Miss Rate XB-Pro (%)": xb_miss_rate,
    "LLC Miss Rate BFS-Ligra (%)": bfs_ligra_rate,
    "LLC Miss Rate MSSP-Ligra (%)": multisssp_ligra_rate,
    "LLC Miss Rate SSSP-Ligra (%)": sssp_ligra_rate,
    "LLC Miss Freq XB-Pro": xb_miss_freq,
    "LLC Miss Freq BFS-Ligra": bfs_ligra_freq,
    "LLC Miss Freq MSSP-Ligra": multisssp_ligra_freq,
    "LLC Miss Freq SSSP-Ligra": sssp_ligra_freq,
    "Effective BW XB++ (GB/s)": xbpp_bw,
    "Effective BW BFS-Gunrock (GB/s)": bfs_gunrock_bw,
    "Effective BW MSSP-Gunrock (GB/s)": multisssp_gunrock_bw,
    "Effective BW SSSP-Gunrock (GB/s)": sssp_gunrock_bw,
})

table = append_average_row(table)
for col in table.columns.drop("Dataset"):
    table[col] = table[col].map(fmt6 if "Freq" in col else fmt2)

for idx, dataset in enumerate(datasets):
    table.loc[table["Dataset"] == dataset, "LLC Miss Rate XB-Pro (%)"] = fmt_ci(xb_miss_rate[idx], xb_miss_rate_ci[idx], fmt2)
    table.loc[table["Dataset"] == dataset, "LLC Miss Freq XB-Pro"] = fmt_ci(xb_miss_freq[idx], xb_miss_freq_ci[idx], fmt6)
    table.loc[table["Dataset"] == dataset, "Effective BW XB++ (GB/s)"] = fmt_ci(xbpp_bw[idx], xbpp_bw_ci[idx], fmt2)
    table.loc[table["Dataset"] == dataset, "Effective BW BFS-Gunrock (GB/s)"] = fmt_ci(bfs_gunrock_bw[idx], bfs_gunrock_bw_ci[idx], fmt2)
    table.loc[table["Dataset"] == dataset, "Effective BW MSSP-Gunrock (GB/s)"] = fmt_ci(multisssp_gunrock_bw[idx], multisssp_gunrock_bw_ci[idx], fmt2)
    table.loc[table["Dataset"] == dataset, "Effective BW SSSP-Gunrock (GB/s)"] = fmt_ci(sssp_gunrock_bw[idx], sssp_gunrock_bw_ci[idx], fmt2)

def build_tex(include_ci):
    def value(mean, ci, formatter):
        return fmt_tex_value_ci(mean, ci, formatter) if include_ci else fmt_tex_value(mean, formatter)

    tex_rows = []
    for idx, dataset in enumerate(datasets):
        tex_rows.append(
            f"{dataset:<13} & {value(bfs_ligra_rate[idx], bfs_ligra_rate_ci[idx], fmt2)} "
            f"& {value(sssp_ligra_rate[idx], sssp_ligra_rate_ci[idx], fmt2)} "
            f"& {value(multisssp_ligra_rate[idx], multisssp_ligra_rate_ci[idx], fmt2)} "
            f"& {value(xb_miss_rate[idx], xb_miss_rate_ci[idx], fmt2)} "
            f"& {value(bfs_ligra_freq_mill[idx], bfs_ligra_freq_ci_mill[idx], fmt2)} "
            f"& {value(sssp_ligra_freq_mill[idx], sssp_ligra_freq_ci_mill[idx], fmt2)} "
            f"& {value(multisssp_ligra_freq_mill[idx], multisssp_ligra_freq_ci_mill[idx], fmt2)} "
            f"& {value(xb_miss_freq_mill[idx], xb_miss_freq_ci_mill[idx], fmt2)} "
            f"& {value(bfs_gunrock_bw[idx], bfs_gunrock_bw_ci[idx], fmt2)} "
            f"& {value(sssp_gunrock_bw[idx], sssp_gunrock_bw_ci[idx], fmt2)} "
            f"& {value(multisssp_gunrock_bw[idx], multisssp_gunrock_bw_ci[idx], fmt2)} "
            f"& {value(xbpp_bw[idx], xbpp_bw_ci[idx], fmt2)} \\\\"
        )
    tex_rows.append("\\midrule")
    tex_rows.append(
        f"Average       & {fmt_tex_value(np.nanmean(bfs_ligra_rate), fmt2)} "
        f"& {fmt_tex_value(np.nanmean(sssp_ligra_rate), fmt2)} "
        f"& {fmt_tex_value(np.nanmean(multisssp_ligra_rate), fmt2)} "
        f"& {fmt_tex_value(np.nanmean(xb_miss_rate), fmt2)} "
        f"& {fmt_tex_value(np.nanmean(bfs_ligra_freq_mill), fmt2)} "
        f"& {fmt_tex_value(np.nanmean(sssp_ligra_freq_mill), fmt2)} "
        f"& {fmt_tex_value(np.nanmean(multisssp_ligra_freq_mill), fmt2)} "
        f"& {fmt_tex_value(np.nanmean(xb_miss_freq_mill), fmt2)} "
        f"& {fmt_tex_value(np.nanmean(bfs_gunrock_bw), fmt2)} "
        f"& {fmt_tex_value(np.nanmean(sssp_gunrock_bw), fmt2)} "
        f"& {fmt_tex_value(np.nanmean(multisssp_gunrock_bw), fmt2)} "
        f"& {fmt_tex_value(np.nanmean(xbpp_bw), fmt2)} \\\\"
    )
    ci_sentence = (
        "Values are reported as mean $\\pm$ 95\\% confidence interval over 20 rounds.\n"
        if include_ci else
        ""
    )
    table_label = "tab:memory-ci" if include_ci else "tab:memory"
    placement = "H" if include_ci else "h"

    return "\\begin{table}[" + placement + "]\n" + """\
\\Huge
\\centering
\\setlength{\\tabcolsep}{3pt}
\\renewcommand{\\arraystretch}{1.0}
\\resizebox{\\columnwidth}{!}{%
\\begin{tabular}{l|cccc|cccc|cccc}
\\toprule
 & \\multicolumn{4}{c|}{\\textbf{CPU LLC Miss Rate (\\%)}}
 & \\multicolumn{4}{c|}{\\textbf{CPU LLC Miss Freq. (MillMiss/s)}}
 & \\multicolumn{4}{c}{\\textbf{GPU Effective Memory Bandwidth (GB/s)}} \\\\
\\cmidrule(lr){2-5} \\cmidrule(lr){6-9} \\cmidrule(lr){10-13}
Dataset &
BFS-Ligra &
SSSP-Ligra &
MSSP-Ligra &
XB-Pro &
BFS-Ligra &
SSSP-Ligra &
MSSP-Ligra &
XB-Pro &
BFS-Gunrock &
SSSP-Gunrock &
MSSP-Gunrock &
XB++ \\\\
\\midrule
""" + "\n".join(tex_rows) + """
\\bottomrule
\\end{tabular}
}
\\captionsetup{skip=4pt}
\\caption{
Comparison of CPU cache behavior and GPU memory bandwidth for BFS, SSSP, MSSP, and X-Blossom variants.
CPU metrics report LLC miss rate and LLC miss frequency in million misses per second, while GPU metrics report effective memory bandwidth.
""" + ci_sentence + """Rows follow increasing node count.
}
\\label{""" + table_label + """}
\\vspace{-4pt}
\\end{table}
"""

output = Path(args.output)
output.parent.mkdir(parents=True, exist_ok=True)
table.to_csv(output, index=False)
print(f"Table-14 CSV generated at: {output}")

tex_output = Path(args.tex_output)
tex_output.parent.mkdir(parents=True, exist_ok=True)
tex_output.write_text(build_tex(include_ci=False))
print(f"Table-14 TeX generated at: {tex_output}")

tex_ci_output = tex_output.with_name(f"{tex_output.stem}_ci{tex_output.suffix}")
tex_ci_output.parent.mkdir(parents=True, exist_ok=True)
tex_ci_output.write_text(build_tex(include_ci=True))
print(f"Table-14 CI TeX generated at: {tex_ci_output}")
