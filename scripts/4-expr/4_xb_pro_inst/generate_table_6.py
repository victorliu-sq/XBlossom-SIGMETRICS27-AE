#!/usr/bin/env python3
import argparse
import csv
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[1]))
from experiment_ci import latex_mean_ci


def read_rows(path):
    with open(path, newline="") as f:
        return {row["Dataset"]: row for row in csv.DictReader(f)}


def val(row, name):
    try:
        return float(row.get(name, 0.0))
    except (TypeError, ValueError):
        return 0.0


parser = argparse.ArgumentParser(description="Generate XB-Pro node/edge instruction CI table")
parser.add_argument("--node_csv", required=True)
parser.add_argument("--edge_csv", required=True)
parser.add_argument("--csv_output", required=True)
parser.add_argument("--tex_output", required=True)
args = parser.parse_args()

datasets = [
    "GPlus", "Twitch", "Amazon", "HiggsNets", "Youtube",
    "Hyperlink", "Wikipedia", "Stackoverflow", "Patent", "Livejournal"
]
node = read_rows(args.node_csv)
edge = read_rows(args.edge_csv)

Path(args.csv_output).parent.mkdir(parents=True, exist_ok=True)
with open(args.csv_output, "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["Dataset", "Node GIPS", "Node CI", "Edge GIPS", "Edge CI"])
    for dataset in datasets:
        nrow = node.get(dataset, {})
        erow = edge.get(dataset, {})
        writer.writerow([
            dataset,
            f"{val(nrow, 'InstructionExecRate(GIPS)'):.6f}",
            f"{val(nrow, 'InstructionExecRateCI(GIPS)'):.6f}",
            f"{val(erow, 'InstructionExecRate(GIPS)'):.6f}",
            f"{val(erow, 'InstructionExecRateCI(GIPS)'):.6f}",
        ])

def tex_row(label, rows):
    values = [
        latex_mean_ci(
            val(rows.get(dataset, {}), "InstructionExecRate(GIPS)"),
            val(rows.get(dataset, {}), "InstructionExecRateCI(GIPS)"),
        )
        for dataset in datasets
    ]
    return label + " & " + " & ".join(values) + r" \\"


lines = [
    r"\begin{table}[H]",
    r"\footnotesize",
    r"\centering",
    r"\setlength{\tabcolsep}{3pt}",
    r"\renewcommand{\arraystretch}{1.0}",
    r"\resizebox{\columnwidth}{!}{%",
    r"\begin{tabular}{l|" + "c" * len(datasets) + "}",
    r"\toprule",
    "Level & " + " & ".join(datasets) + r" \\",
    r"\midrule",
    tex_row("Node-Level", node),
    tex_row("Edge-Level", edge),
    r"\bottomrule",
    r"\end{tabular}",
    r"}",
    r"\captionsetup{skip=4pt}",
    r"\caption{XB-Pro instruction execution rate under node-level and edge-level scheduling. "
    r"Entries are reported as mean $\pm$ 95\% confidence interval over 20 rounds.}",
    r"\label{tab:xb-pro-inst-ci}",
    r"\vspace{-4pt}",
    r"\end{table}",
]
Path(args.tex_output).write_text("\n".join(lines) + "\n")
print(f"Generated {args.csv_output} and {args.tex_output}")
