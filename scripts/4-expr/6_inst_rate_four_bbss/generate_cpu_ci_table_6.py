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


def value(row, name):
    try:
        return float(row.get(name, 0.0))
    except (TypeError, ValueError):
        return 0.0


parser = argparse.ArgumentParser(description="Generate CPU instruction-rate CI table for expr-13")
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
    writer.writerow(["Dataset", "Algorithm", "InstructionExecRate(GIPS)", "InstructionExecRateCI(GIPS)"])
    for dataset in DATASETS:
        for algorithm, rows in columns:
            row = rows.get(dataset, {})
            writer.writerow([
                dataset,
                algorithm,
                f"{value(row, 'InstructionExecRate(GIPS)'):.6f}",
                f"{value(row, 'InstructionExecRateCI(GIPS)'):.6f}",
            ])

lines = [
    r"\begin{table}[h]",
    r"\Huge",
    r"\centering",
    r"\setlength{\tabcolsep}{4pt}",
    r"\renewcommand{\arraystretch}{1.15}",
    r"\resizebox{\columnwidth}{!}{%",
    r"\begin{tabular}{l|cccc}",
    r"\toprule",
    r"Dataset & XB-Pro & BFS-Ligra & SSSP-Ligra & MSSP-Ligra \\",
    r"\midrule",
]
for dataset in DATASETS:
    cells = [dataset]
    for _algorithm, rows in columns:
        row = rows.get(dataset, {})
        cells.append(latex_mean_ci(value(row, "InstructionExecRate(GIPS)"), value(row, "InstructionExecRateCI(GIPS)")))
    lines.append(" & ".join(cells) + r" \\")
lines.extend([
    r"\bottomrule",
    r"\end{tabular}",
    r"}",
    r"\caption{CPU instruction execution rates for XB-Pro, BFS-Ligra, SSSP-Ligra, and MSSP-Ligra. Entries are GIPS reported as mean $\pm$ 95\% CI over five profiling iterations using the configured round count per run.}",
    r"\label{tab:expr13-cpu-inst-ci}",
    r"\end{table}",
])

tex_output = Path(args.tex_output)
tex_output.parent.mkdir(parents=True, exist_ok=True)
tex_output.write_text("\n".join(lines) + "\n")
print(f"Generated {csv_output} and {tex_output}")
