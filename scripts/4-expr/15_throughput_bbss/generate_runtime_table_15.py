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


parser = argparse.ArgumentParser(description="Generate throughput experiment runtime CI table")
parser.add_argument("--xb_pro_csv", required=True)
parser.add_argument("--xb_pp_csv", required=True)
parser.add_argument("--csv_output", required=True)
parser.add_argument("--tex_output", required=True)
args = parser.parse_args()

datasets = [
    "GPlus", "Twitch", "Amazon", "HiggsNets", "Youtube",
    "Hyperlink", "Wikipedia", "Stackoverflow", "Patent", "Livejournal"
]
xb_pro = read_rows(args.xb_pro_csv)
xb_pp = read_rows(args.xb_pp_csv)

Path(args.csv_output).parent.mkdir(parents=True, exist_ok=True)
with open(args.csv_output, "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["Dataset", "XB-Pro Runtime(s)", "XB-Pro CI(s)", "XB++ Runtime(s)", "XB++ CI(s)"])
    for dataset in datasets:
        pro = xb_pro.get(dataset, {})
        pp = xb_pp.get(dataset, {})
        writer.writerow([
            dataset,
            f"{val(pro, 'Runtime(s)'):.6f}",
            f"{val(pro, 'RuntimeCI(s)'):.6f}",
            f"{val(pp, 'Runtime(s)'):.6f}",
            f"{val(pp, 'RuntimeCI(s)'):.6f}",
        ])

lines = [
    r"\begin{table*}[h]",
    r" \small",
    r" \centering",
    r" \setlength{\tabcolsep}{7pt}",
    r" \renewcommand{\arraystretch}{1.0}",
    r" \begin{tabular}{l|cc}",
    r" \toprule",
    r" Dataset & XB-Pro & XB++ \\",
    r" \midrule",
]
for dataset in datasets:
    pro = xb_pro.get(dataset, {})
    pp = xb_pp.get(dataset, {})
    lines.append(
        " "
        + " & ".join([
            dataset,
            latex_mean_ci(val(pro, "Runtime(s)"), val(pro, "RuntimeCI(s)")),
            latex_mean_ci(val(pp, "Runtime(s)"), val(pp, "RuntimeCI(s)")),
        ])
        + r" \\"
    )
lines.extend([
    r" \bottomrule",
    r" \end{tabular}",
    r" \caption{XB-Pro and XB++ runtimes for the BBSS throughput workload. Runtime entries are reported as mean $\pm$ 95\% confidence interval over 20 rounds.}",
    r" \label{tab:throughput-four-bbss-runtime-ci}",
    r"\end{table*}",
])
Path(args.tex_output).write_text("\n".join(lines) + "\n")
print(f"Generated {args.csv_output} and {args.tex_output}")
