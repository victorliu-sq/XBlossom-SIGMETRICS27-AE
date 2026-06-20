#!/usr/bin/env python3
import argparse
from pathlib import Path
import sys
import numpy as np
import pandas as pd

sys.path.append(str(Path(__file__).resolve().parents[1]))
from experiment_ci import compact_number

parser = argparse.ArgumentParser(description="Generate instruction-rate table for XB plus BFS/MSSP/SSSP")
parser.add_argument("--xb_pro_csv", required=True)
parser.add_argument("--xb_pp_csv", required=True)
parser.add_argument("--bfs_ligra_csv", required=True)
parser.add_argument("--multisssp_ligra_csv", required=True)
parser.add_argument("--sssp_ligra_csv", required=True)
parser.add_argument("--bfs_gunrock_csv", required=True)
parser.add_argument("--multisssp_gunrock_csv", required=True)
parser.add_argument("--sssp_gunrock_csv", required=True)
parser.add_argument("--output", required=True)
parser.add_argument("--ci_output", required=True)
parser.add_argument("--tex_output", required=True)
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

def read_value_ci_map(path, value_col, ci_col=None):
    df = pd.read_csv(path)
    values = {}
    for _, row in df.iterrows():
        values[normalize(row["Dataset"])] = (
            parse_value(row.get(value_col)),
            parse_value(row.get(ci_col)) if ci_col and ci_col in df.columns else np.nan,
        )
    return values

def arr(map_, datasets):
    return np.array([map_.get(normalize(d), np.nan) for d in datasets], dtype=float)

def arr_pair(map_, datasets, idx):
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

def fmt(x):
    return "NA" if not np.isfinite(x) else f"{x:.2f}"

def fmt_tex_value(x):
    return "NA" if not np.isfinite(x) else f"{x:.2f}"

def fmt_tex_value_ci(mean, ci):
    if not np.isfinite(mean):
        return "NA"
    if not np.isfinite(ci):
        ci = 0.0
    return f"{mean:.2f} $\\pm$ {compact_number(ci)}"

def fmt_tex_speedup(x):
    return "NA" if not np.isfinite(x) else f"{x:.2f}$\\times$"

def fmt_ci_only(x):
    return compact_number(0.0 if not np.isfinite(x) else x)

def latex_escape(text):
    return str(text).replace("_", "\\_")

datasets = [
    "GPlus", "Twitch", "Amazon", "HiggsNets", "Youtube",
    "Hyperlink", "Wikipedia", "Stackoverflow", "Patent", "Livejournal"
]

xb_pro_map = read_value_ci_map(args.xb_pro_csv, "InstructionExecRate(GIPS)", "InstructionExecRateCI(GIPS)")
xb_pp_map = read_value_ci_map(args.xb_pp_csv, "InstructionRate(GIPS)", "InstructionRateCI(GIPS)")
xb_pro = arr_pair(xb_pro_map, datasets, 0)
xb_pro_ci = arr_pair(xb_pro_map, datasets, 1)
xb_pp = arr_pair(xb_pp_map, datasets, 0)
xb_pp_ci = arr_pair(xb_pp_map, datasets, 1)
bfs_ligra_map = read_value_ci_map(args.bfs_ligra_csv, "InstructionExecRate(GIPS)", "InstructionExecRateCI(GIPS)")
multisssp_ligra_map = read_value_ci_map(args.multisssp_ligra_csv, "InstructionExecRate(GIPS)", "InstructionExecRateCI(GIPS)")
sssp_ligra_map = read_value_ci_map(args.sssp_ligra_csv, "InstructionExecRate(GIPS)", "InstructionExecRateCI(GIPS)")
bfs_gunrock_map = read_value_ci_map(args.bfs_gunrock_csv, "InstructionRate(GIPS)", "InstructionRateCI(GIPS)")
multisssp_gunrock_map = read_value_ci_map(args.multisssp_gunrock_csv, "InstructionRate(GIPS)", "InstructionRateCI(GIPS)")
sssp_gunrock_map = read_value_ci_map(args.sssp_gunrock_csv, "InstructionRate(GIPS)", "InstructionRateCI(GIPS)")
bfs_ligra = arr_pair(bfs_ligra_map, datasets, 0)
bfs_ligra_ci = arr_pair(bfs_ligra_map, datasets, 1)
multisssp_ligra = arr_pair(multisssp_ligra_map, datasets, 0)
multisssp_ligra_ci = arr_pair(multisssp_ligra_map, datasets, 1)
sssp_ligra = arr_pair(sssp_ligra_map, datasets, 0)
sssp_ligra_ci = arr_pair(sssp_ligra_map, datasets, 1)
bfs_gunrock = arr_pair(bfs_gunrock_map, datasets, 0)
bfs_gunrock_ci = arr_pair(bfs_gunrock_map, datasets, 1)
multisssp_gunrock = arr_pair(multisssp_gunrock_map, datasets, 0)
multisssp_gunrock_ci = arr_pair(multisssp_gunrock_map, datasets, 1)
sssp_gunrock = arr_pair(sssp_gunrock_map, datasets, 0)
sssp_gunrock_ci = arr_pair(sssp_gunrock_map, datasets, 1)

table = pd.DataFrame({
    "Dataset": datasets,
    "XB-Pro": xb_pro,
    "BFS-Ligra": bfs_ligra,
    "MSSP-Ligra": multisssp_ligra,
    "SSSP-Ligra": sssp_ligra,
    "XB++": xb_pp,
    "BFS-Gunrock": bfs_gunrock,
    "MSSP-Gunrock": multisssp_gunrock,
    "SSSP-Gunrock": sssp_gunrock,
    "BFS Scaling (x)": ratio(bfs_gunrock, bfs_ligra),
    "MSSP Scaling (x)": ratio(multisssp_gunrock, multisssp_ligra),
    "SSSP Scaling (x)": ratio(sssp_gunrock, sssp_ligra),
    "XB Scaling (x)": ratio(xb_pp, xb_pro),
})

table = append_average_row(table)
table_for_csv = table.copy()
for col in table_for_csv.columns.drop("Dataset"):
    table_for_csv[col] = table_for_csv[col].map(fmt)

ci_table = pd.DataFrame({
    "Dataset": datasets,
    "XB-Pro CI": xb_pro_ci,
    "BFS-Ligra CI": bfs_ligra_ci,
    "MSSP-Ligra CI": multisssp_ligra_ci,
    "SSSP-Ligra CI": sssp_ligra_ci,
    "XB++ CI": xb_pp_ci,
    "BFS-Gunrock CI": bfs_gunrock_ci,
    "MSSP-Gunrock CI": multisssp_gunrock_ci,
    "SSSP-Gunrock CI": sssp_gunrock_ci,
})
for col in ci_table.columns.drop("Dataset"):
    ci_table[col] = ci_table[col].map(fmt_ci_only)

bfs_scaling = ratio(bfs_gunrock, bfs_ligra)
sssp_scaling = ratio(sssp_gunrock, sssp_ligra)
mssp_scaling = ratio(multisssp_gunrock, multisssp_ligra)
xb_scaling = ratio(xb_pp, xb_pro)
def build_tex(include_ci):
    def value(mean, ci):
        return fmt_tex_value_ci(mean, ci) if include_ci else fmt_tex_value(mean)

    tex_rows = []
    for idx, dataset in enumerate(datasets):
        tex_rows.append(
            f"{dataset:<13} & {value(bfs_ligra[idx], bfs_ligra_ci[idx])} "
            f"& {value(sssp_ligra[idx], sssp_ligra_ci[idx])} "
            f"& {value(multisssp_ligra[idx], multisssp_ligra_ci[idx])} "
            f"& {value(xb_pro[idx], xb_pro_ci[idx])} "
            f"& {value(bfs_gunrock[idx], bfs_gunrock_ci[idx])} "
            f"& {value(sssp_gunrock[idx], sssp_gunrock_ci[idx])} "
            f"& {value(multisssp_gunrock[idx], multisssp_gunrock_ci[idx])} "
            f"& {value(xb_pp[idx], xb_pp_ci[idx])} "
            f"& {fmt_tex_speedup(bfs_scaling[idx])} & {fmt_tex_speedup(sssp_scaling[idx])} "
            f"& {fmt_tex_speedup(mssp_scaling[idx])} & {fmt_tex_speedup(xb_scaling[idx])} \\\\"
        )
    tex_rows.append("\\midrule")
    tex_rows.append(
        f"Average       & {fmt_tex_value(np.nanmean(bfs_ligra))} "
        f"& {fmt_tex_value(np.nanmean(sssp_ligra))} "
        f"& {fmt_tex_value(np.nanmean(multisssp_ligra))} "
        f"& {fmt_tex_value(np.nanmean(xb_pro))} "
        f"& {fmt_tex_value(np.nanmean(bfs_gunrock))} "
        f"& {fmt_tex_value(np.nanmean(sssp_gunrock))} "
        f"& {fmt_tex_value(np.nanmean(multisssp_gunrock))} "
        f"& {fmt_tex_value(np.nanmean(xb_pp))} "
        f"& {fmt_tex_speedup(np.nanmean(bfs_scaling))} "
        f"& {fmt_tex_speedup(np.nanmean(sssp_scaling))} "
        f"& {fmt_tex_speedup(np.nanmean(mssp_scaling))} "
        f"& {fmt_tex_speedup(np.nanmean(xb_scaling))} \\\\"
    )
    ci_sentence = (
        "Instruction execution rates are reported in GIPS as mean $\\pm$ 95\\% confidence interval over 20 rounds.\n"
        if include_ci else
        "Instruction execution rates are reported in GIPS.\n"
    )
    table_label = "tab:pe-ci" if include_ci else "tab:pe"
    placement = "H" if include_ci else "h"

    return "\\begin{table}[" + placement + "]\n" + """\
\\Huge
\\centering
\\setlength{\\tabcolsep}{3pt}
\\renewcommand{\\arraystretch}{1.0}
\\resizebox{\\columnwidth}{!}{%
\\begin{tabular}{l|cccc|cccc|cccc}
\\toprule
 & \\multicolumn{4}{c|}{\\textbf{CPU}}
 & \\multicolumn{4}{c|}{\\textbf{GPU}}
 & \\multicolumn{4}{c}{\\textbf{CPU--GPU Scaling}} \\\\
\\cmidrule(lr){2-5} \\cmidrule(lr){6-9} \\cmidrule(lr){10-13}
Dataset &
BFS-Ligra &
SSSP-Ligra &
MSSP-Ligra &
XB-Pro &
BFS-Gunrock &
SSSP-Gunrock &
MSSP-Gunrock &
XB++ &
BFS ($\\times$) &
SSSP ($\\times$) &
MSSP ($\\times$) &
XB ($\\times$) \\\\
\\midrule
""" + "\n".join(tex_rows) + """
\\bottomrule
\\end{tabular}
}
\\captionsetup{skip=4pt}
\\caption{
Comparison of instruction execution rates for BFS, SSSP, MSSP, and X-Blossom variants on CPUs and GPUs.
""" + ci_sentence + """CPU--GPU scaling reports the instruction throughput improvement when migrating execution from CPU to GPU.
Rows follow increasing node count.
}
\\label{""" + table_label + """}
\\vspace{-4pt}
\\end{table}
"""

output = Path(args.output)
output.parent.mkdir(parents=True, exist_ok=True)
table_for_csv.to_csv(output, index=False)
print(f"Table-13 CSV generated at: {output}")

ci_output = Path(args.ci_output)
ci_output.parent.mkdir(parents=True, exist_ok=True)
ci_table.to_csv(ci_output, index=False)
print(f"Table-13 CI CSV generated at: {ci_output}")

tex_output = Path(args.tex_output)
tex_output.parent.mkdir(parents=True, exist_ok=True)
tex_output.write_text(build_tex(include_ci=False))
print(f"Table-13 TeX generated at: {tex_output}")

tex_ci_output = tex_output.with_name(f"{tex_output.stem}_ci{tex_output.suffix}")
tex_ci_output.parent.mkdir(parents=True, exist_ok=True)
tex_ci_output.write_text(build_tex(include_ci=True))
print(f"Table-13 CI TeX generated at: {tex_ci_output}")
