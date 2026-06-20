#!/usr/bin/env python3
import csv
import os
import sys


DISPLAY_NAMES = {
    "Stackoverflow": "StackOverflow",
    "Livejournal": "LiveJournal",
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
    return f"{float(value):.2f}$\\times$"


def reuse_ratio_pct_fmt(reuse_ratio):
    return f"{float(reuse_ratio) * 100.0:.1f}"


def reuse_ratio_pct_ci_only_fmt(ci):
    ci_pct = float(ci) * 100.0
    if ci_pct < 0.1:
        return f"{ci_pct:.2f}"
    return f"{ci_pct:.1f}"


def reuse_ratio_pct_ci_fmt(reuse_ratio, ci):
    return f"{reuse_ratio_pct_fmt(reuse_ratio)} {{\\tiny $\\pm$ {reuse_ratio_pct_ci_only_fmt(ci)}}}"


def make_row(dataset, cpu_row, gpu_row):
    cpu_reuse_ratio = float(cpu_row["ReuseRatio"])
    gpu_reuse_ratio = float(gpu_row["ReuseRatio"])
    return {
        "dataset": dataset,
        "sort_key": (cpu_reuse_ratio + gpu_reuse_ratio) / 2.0,
        "values": [
            DISPLAY_NAMES.get(dataset, dataset),
            runtime_fmt(cpu_row["AvgRuntime_XB(s)"]),
            runtime_fmt(cpu_row["AvgRuntime_XBPro(s)"]),
            speedup_fmt(cpu_row["Speedup"]),
            reuse_ratio_pct_fmt(cpu_row["ReuseRatio"]),
            runtime_fmt(gpu_row["AvgRuntime_XB++NR(s)"]),
            runtime_fmt(gpu_row["AvgRuntime_XB++(s)"]),
            speedup_fmt(gpu_row["Speedup"]),
            reuse_ratio_pct_fmt(gpu_row["ReuseRatio"]),
        ],
    }


def make_ci_row(dataset, cpu_row, gpu_row):
    cpu_reuse_ratio = float(cpu_row["ReuseRatio"])
    gpu_reuse_ratio = float(gpu_row["ReuseRatio"])
    return {
        "dataset": dataset,
        "sort_key": (cpu_reuse_ratio + gpu_reuse_ratio) / 2.0,
        "values": [
            DISPLAY_NAMES.get(dataset, dataset),
            runtime_ci_fmt(cpu_row["AvgRuntime_XB(s)"], cpu_row["CI95_XB(s)"]),
            runtime_ci_fmt(cpu_row["AvgRuntime_XBPro(s)"], cpu_row["CI95_XBPro(s)"]),
            speedup_fmt(cpu_row["Speedup"]),
            reuse_ratio_pct_ci_fmt(cpu_row["ReuseRatio"], cpu_row["CI95_ReuseRatio"]),
            runtime_ci_fmt(gpu_row["AvgRuntime_XB++NR(s)"], gpu_row["CI95_XB++NR(s)"]),
            runtime_ci_fmt(gpu_row["AvgRuntime_XB++(s)"], gpu_row["CI95_XB++(s)"]),
            speedup_fmt(gpu_row["Speedup"]),
            reuse_ratio_pct_ci_fmt(gpu_row["ReuseRatio"], gpu_row["CI95_ReuseRatio"]),
        ],
    }


def write_tex(rows, output_path, include_ci=False):
    table_env = "table*" if include_ci else "table"
    font_size = r" \scriptsize" if include_ci else r" \footnotesize"
    tabcolsep = "3pt" if include_ci else "6pt"
    lines = [
        rf"\begin{{{table_env}}}[h]",
        font_size,
        r" % \small",
        r" \centering",
        rf" \setlength{{\tabcolsep}}{{{tabcolsep}}}",
        r" \renewcommand{\arraystretch}{1.0}",
    ]

    if include_ci:
        lines.append(r" \resizebox{\textwidth}{!}{%")

    lines.extend([
        r" \begin{tabular}{l|cccc|cccc}",
        r" \toprule",
        r"  & \multicolumn{4}{c|}{\textbf{CPU}}",
        r"  & \multicolumn{4}{c}{\textbf{GPU}} \\",
        r" \cmidrule(lr){2-5} \cmidrule(lr){6-9}",
        r" Dataset &",
        r" XB &",
        r" XB-Pro &",
        r" Speedup &",
        r" ReuseRatio (\%) &",
        r" XB-GPU &",
        r" XB++ &",
        r" Speedup &",
        r" ReuseRatio (\%) \\",
        r" \midrule",
    ])

    for row in rows:
        lines.append(" " + " & ".join(row["values"]) + r" \\")

    lines.extend([
        r" \bottomrule",
        r" \end{tabular}",
    ])

    if include_ci:
        lines.append(r" }")

    lines.extend([
        r" \captionsetup{skip=4pt}",
        r" \caption{",
        r" Performance impact of alternating-tree reuse in X-Blossom on CPUs and GPUs.",
        r" All reported runtimes of XB, XB-Pro, XB-GPU, and XB++ are in seconds.",
        r" CPU speedup is computed as XB/XB-Pro; GPU speedup is computed as XB-GPU/XB++.",
        r" ReuseRatio reports the percentage of alternating-tree nodes that are reused rather than reset.",
    ])

    if include_ci:
        lines.append(r" Runtime and ReuseRatio entries are reported as mean $\pm$ 95\% confidence interval over 20 rounds.")

    lines.extend([
        r" }",
        r" \label{tab:reuse}",
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
            "Usage: generate_table_2_tex.py "
            "<table_2_left.csv> <table_2_right.csv> <output.tex>"
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
    rows.sort(key=lambda row: row["sort_key"], reverse=True)

    ci_rows = [
        make_ci_row(dataset, cpu_rows[dataset], gpu_rows[dataset])
        for dataset in cpu_rows
    ]
    ci_rows.sort(key=lambda row: row["sort_key"], reverse=True)
    ci_output_tex = output_tex.replace(".tex", "_ci.tex")

    write_tex(rows, output_tex)
    write_tex(ci_rows, ci_output_tex, include_ci=True)
    print(f"[OK] Wrote LaTeX Table 2 to {output_tex}")
    print(f"[OK] Wrote LaTeX Table 2 with CI to {ci_output_tex}")


if __name__ == "__main__":
    main()
