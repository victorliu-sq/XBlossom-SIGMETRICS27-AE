#!/usr/bin/env python3
import csv
import os
import sys


DISPLAY_NAMES = {
    "Stackoverflow": "StackOverflow",
    "Livejournal": "LiveJournal",
}

DATASET_ORDER = {
    name.lower(): idx
    for idx, name in enumerate([
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
    ])
}


def read_csv_by_dataset(path):
    with open(path, newline="") as f:
        return {
            row["Dataset"].strip(): row
            for row in csv.DictReader(f)
        }


def runtime_fmt(value):
    value = float(value)
    if value < 0.1:
        return f"{value:.4f}"
    if value < 1.0:
        return f"{value:.3f}"
    if value < 10.0:
        return f"{value:.2f}"
    return f"{value:.1f}"


def runtime_ci_fmt(value, ci):
    return f"{runtime_fmt(value)} {{\\tiny $\\pm$ {runtime_fmt(ci)}}}"


def speedup_fmt(value):
    return f"{float(value):.3g}$\\times$"


def make_row(dataset, cpu_row, gpu_row, include_ci=False):
    if include_ci:
        cpu_node = runtime_ci_fmt(cpu_row["AvgRuntime_XB(s)"], cpu_row["CI95_XB(s)"])
        cpu_edge = runtime_ci_fmt(
            cpu_row["AvgRuntime_XBPro(s)"], cpu_row["CI95_XBPro(s)"]
        )
        gpu_node = runtime_ci_fmt(
            gpu_row["AvgRuntime_XB++NB(s)"], gpu_row["CI95_XB++NB(s)"]
        )
        gpu_edge = runtime_ci_fmt(
            gpu_row["AvgRuntime_XB++(s)"], gpu_row["CI95_XB++(s)"]
        )
    else:
        cpu_node = runtime_fmt(cpu_row["AvgRuntime_XB(s)"])
        cpu_edge = runtime_fmt(cpu_row["AvgRuntime_XBPro(s)"])
        gpu_node = runtime_fmt(gpu_row["AvgRuntime_XB++NB(s)"])
        gpu_edge = runtime_fmt(gpu_row["AvgRuntime_XB++(s)"])

    return {
        "dataset": dataset,
        "sort_key": DATASET_ORDER.get(dataset.strip().lower(), len(DATASET_ORDER)),
        "values": [
            DISPLAY_NAMES.get(dataset, dataset),
            cpu_node,
            cpu_edge,
            speedup_fmt(cpu_row["Speedup"]),
            gpu_node,
            gpu_edge,
            speedup_fmt(gpu_row["Speedup"]),
        ],
    }


def write_tex(rows, output_path, include_ci=False):
    table_env = "table"
    font_size = r" \scriptsize" if include_ci else r" \footnotesize"
    tabcolsep = "5pt" if include_ci else "7pt"
    arraystretch = "0.88" if include_ci else "1.0"
    placement = "H" if include_ci else "h"
    lines = [
        rf"\begin{{{table_env}}}[{placement}]",
        font_size,
        r" \centering",
        rf" \setlength{{\tabcolsep}}{{{tabcolsep}}}",
        rf" \renewcommand{{\arraystretch}}{{{arraystretch}}}",
    ]

    lines.extend([
        r" \begin{tabular}{l|rrr|rrr}",
        r" \toprule",
        r"  & \multicolumn{3}{c|}{\textbf{X-Blossom-Pro}}",
        r"  & \multicolumn{3}{c}{\textbf{X-Blossom++}} \\",
        r" \cmidrule(lr){2-4} \cmidrule(lr){5-7}",
        r" Dataset &",
        r" Node-Level &",
        r" Edge-Level &",
        r" Speedup &",
        r" Node-Level &",
        r" Edge-Level &",
        r" Speedup \\",
        r" \midrule",
    ])

    for row in rows:
        lines.append(" " + " & ".join(row["values"]) + r" \\")

    lines.extend([
        r" \bottomrule",
        r" \end{tabular}",
    ])

    lines.extend([
        r" \captionsetup{skip=4pt}",
        r" \caption{",
        r" All reported runtimes are in seconds.",
        r" Runtime comparison of X-Blossom-Pro and X-Blossom++ under node-level and edge-level load-balancing strategies.",
        r" Speedup is computed as node-level runtime divided by edge-level runtime.",
    ])

    if include_ci:
        lines.append(r" Runtime entries are reported as mean $\pm$ 95\% confidence interval over 20 rounds.")

    table_label = "tab:load-balance-ci" if include_ci else "tab:load-balance"
    lines.extend([
        r" }",
        rf" \label{{{table_label}}}",
        r"\vspace{-4pt}",
        rf"\end{{{table_env}}}",
        "",
    ])

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w") as f:
        f.write("\n".join(lines))


def main():
    if len(sys.argv) != 4:
        print(
            "Usage: generate_table_3_tex.py "
            "<table_3_left.csv> <table_3_right.csv> <output.tex>"
        )
        sys.exit(1)

    cpu_csv, gpu_csv, output_tex = sys.argv[1:]
    cpu_rows = read_csv_by_dataset(cpu_csv)
    gpu_rows = read_csv_by_dataset(gpu_csv)

    missing = sorted(set(cpu_rows) ^ set(gpu_rows))
    if missing:
        raise RuntimeError(f"CPU/GPU table dataset mismatch: {missing}")

    rows = [
        make_row(dataset, cpu_rows[dataset], gpu_rows[dataset])
        for dataset in cpu_rows
    ]
    rows.sort(key=lambda row: row["sort_key"])

    ci_rows = [
        make_row(dataset, cpu_rows[dataset], gpu_rows[dataset], include_ci=True)
        for dataset in cpu_rows
    ]
    ci_rows.sort(key=lambda row: row["sort_key"])
    ci_output_tex = output_tex.replace(".tex", "_ci.tex")

    write_tex(rows, output_tex)
    write_tex(ci_rows, ci_output_tex, include_ci=True)
    print(f"[OK] Wrote LaTeX Table 3 to {output_tex}")
    print(f"[OK] Wrote LaTeX Table 3 with CI to {ci_output_tex}")


if __name__ == "__main__":
    main()
