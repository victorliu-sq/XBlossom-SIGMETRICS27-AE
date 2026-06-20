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


def table_lines(title, label, rows):
    lines = [
        r"\begin{table}[h]",
        r"\Huge",
        r"\centering",
        r"\setlength{\tabcolsep}{8pt}",
        r"\renewcommand{\arraystretch}{1.15}",
        r"\begin{tabular}{l|c}",
        r"\toprule",
        r"Dataset & Avg. Runtime (s) \\",
        r"\midrule",
    ]
    for dataset in DATASETS:
        row = rows.get(dataset, {})
        lines.append(
            dataset
            + " & "
            + latex_mean_ci(value(row, "AvgRuntime(s)"), value(row, "AvgRuntimeCI(s)"))
            + r" \\"
        )
    lines.extend([
        r"\bottomrule",
        r"\end{tabular}",
        rf"\caption{{{title}. Entries are mean $\pm$ 95\% CI over 20 rounds.}}",
        rf"\label{{{label}}}",
        r"\end{table}",
    ])
    return lines


parser = argparse.ArgumentParser(description="Generate expr-8 CPU runtime CI tables")
parser.add_argument("--xb_pro_csv", required=True)
parser.add_argument("--bfs_ligra_csv", required=True)
parser.add_argument("--sssp_ligra_csv", required=True)
parser.add_argument("--mssp_ligra_csv", required=True)
parser.add_argument("--csv_output", required=True)
parser.add_argument("--tex_output", required=True)
args = parser.parse_args()

tables = [
    ("XB-Pro Runtime", "tab:expr8-xb-pro-runtime-ci", read_rows(args.xb_pro_csv), "XB-Pro"),
    ("BFS-Ligra Runtime", "tab:expr8-bfs-ligra-runtime-ci", read_rows(args.bfs_ligra_csv), "BFS-Ligra"),
    ("SSSP-Ligra Runtime", "tab:expr8-sssp-ligra-runtime-ci", read_rows(args.sssp_ligra_csv), "SSSP-Ligra"),
    ("MSSP-Ligra Runtime", "tab:expr8-mssp-ligra-runtime-ci", read_rows(args.mssp_ligra_csv), "MSSP-Ligra"),
]

csv_output = Path(args.csv_output)
csv_output.parent.mkdir(parents=True, exist_ok=True)
with open(csv_output, "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["Dataset", "Algorithm", "AvgRuntime(s)", "AvgRuntimeCI(s)"])
    for _title, _label, rows, algorithm in tables:
        for dataset in DATASETS:
            row = rows.get(dataset, {})
            writer.writerow([
                dataset,
                algorithm,
                f"{value(row, 'AvgRuntime(s)'):.6f}",
                f"{value(row, 'AvgRuntimeCI(s)'):.6f}",
            ])

tex_lines = []
for title, label, rows, _algorithm in tables:
    if tex_lines:
        tex_lines.append("")
    tex_lines.extend(table_lines(title, label, rows))

tex_output = Path(args.tex_output)
tex_output.parent.mkdir(parents=True, exist_ok=True)
tex_output.write_text("\n".join(tex_lines) + "\n")
print(f"Generated {csv_output} and {tex_output}")
