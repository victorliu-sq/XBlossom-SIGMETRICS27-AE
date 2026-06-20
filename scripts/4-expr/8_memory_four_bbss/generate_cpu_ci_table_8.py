#!/usr/bin/env python3
import argparse
import csv
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[1]))
from experiment_ci import latex_mean_ci


DATASETS = [
    "GPlus", "Twitch", "Amazon", "HiggsNets", "Youtube",
    "Hyperlink", "Wikipedia", "Stackoverflow", "Patent", "Livejournal"
]


def read_rows(path):
    with open(path, newline="") as f:
        return {row["Dataset"]: row for row in csv.DictReader(f)}


def value(row, *names):
    for name in names:
        try:
            return float(row.get(name, 0.0))
        except (TypeError, ValueError):
            continue
    return 0.0


parser = argparse.ArgumentParser(description="Generate CPU cache-miss CI table for expr-14")
parser.add_argument("--xb_pro_csv", required=True)
parser.add_argument("--bfs_ligra_csv", required=True)
parser.add_argument("--sssp_ligra_csv", required=True)
parser.add_argument("--mssp_ligra_csv", required=True)
parser.add_argument("--csv_output", required=True)
parser.add_argument("--tex_output", required=True)
args = parser.parse_args()

columns = [
    ("XB-Pro", read_rows(args.xb_pro_csv)),
    ("BFS-Ligra", read_rows(args.bfs_ligra_csv)),
    ("SSSP-Ligra", read_rows(args.sssp_ligra_csv)),
    ("MSSP-Ligra", read_rows(args.mssp_ligra_csv)),
]

csv_output = Path(args.csv_output)
csv_output.parent.mkdir(parents=True, exist_ok=True)
with open(csv_output, "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow([
        "Dataset", "Algorithm",
        "LLCMissRate(%)", "LLCMissRateCI(%)",
        "LLCMissFreq(GMiss/s)", "LLCMissFreqCI(GMiss/s)",
    ])
    for dataset in DATASETS:
        for algorithm, rows in columns:
            row = rows.get(dataset, {})
            writer.writerow([
                dataset,
                algorithm,
                f"{value(row, 'AvgLLCMissRate(%)', 'LLCMissRate(%)'):.6f}",
                f"{value(row, 'LLCMissRateCI(%)'):.6f}",
                f"{value(row, 'LLCMissFreq(GMiss/s)'):.6f}",
                f"{value(row, 'LLCMissFreqCI(GMiss/s)'):.6f}",
            ])

lines = [
    r"\begin{table}[h]",
    r"\Huge",
    r"\centering",
    r"\setlength{\tabcolsep}{3pt}",
    r"\renewcommand{\arraystretch}{1.15}",
    r"\resizebox{\columnwidth}{!}{%",
    r"\begin{tabular}{l|cccc|cccc}",
    r"\toprule",
    r" & \multicolumn{4}{c|}{CPU LLC Miss Rate (\%)} & \multicolumn{4}{c}{CPU LLC Miss Freq. (GMiss/s)} \\",
    r"\cmidrule(lr){2-5} \cmidrule(lr){6-9}",
    r"Dataset & XB-Pro & BFS-Ligra & SSSP-Ligra & MSSP-Ligra & XB-Pro & BFS-Ligra & SSSP-Ligra & MSSP-Ligra \\",
    r"\midrule",
]
for dataset in DATASETS:
    rate_cells = []
    freq_cells = []
    for _algorithm, rows in columns:
        row = rows.get(dataset, {})
        rate_cells.append(latex_mean_ci(value(row, "AvgLLCMissRate(%)", "LLCMissRate(%)"), value(row, "LLCMissRateCI(%)")))
        freq_cells.append(latex_mean_ci(value(row, "LLCMissFreq(GMiss/s)"), value(row, "LLCMissFreqCI(GMiss/s)")))
    lines.append(" & ".join([dataset] + rate_cells + freq_cells) + r" \\")
lines.extend([
    r"\bottomrule",
    r"\end{tabular}",
    r"}",
    r"\caption{CPU LLC miss rate and miss frequency for XB-Pro, BFS-Ligra, SSSP-Ligra, and MSSP-Ligra. Entries are mean $\pm$ 95\% CI over five profiling iterations using the configured round count per run.}",
    r"\label{tab:expr14-cpu-memory-ci}",
    r"\end{table}",
])

tex_output = Path(args.tex_output)
tex_output.parent.mkdir(parents=True, exist_ok=True)
tex_output.write_text("\n".join(lines) + "\n")
print(f"Generated {csv_output} and {tex_output}")
