#!/usr/bin/env python3
import argparse
import math
import os
import re
import statistics


DATASET_ORDER = {
    "livejournal": 0,
    "stackoverflow": 1,
    "patent": 2,
}

DISPLAY_NAMES = {
    "Livejournal": "LiveJournal",
    "Stackoverflow": "StackOverflow",
}

T_CRITICAL_95 = {
    1: 12.706,
    2: 4.303,
    3: 3.182,
    4: 2.776,
    5: 2.571,
    6: 2.447,
    7: 2.365,
    8: 2.306,
    9: 2.262,
    10: 2.228,
    11: 2.201,
    12: 2.179,
    13: 2.160,
    14: 2.145,
    15: 2.131,
    16: 2.120,
    17: 2.110,
    18: 2.101,
    19: 2.093,
    20: 2.086,
}


def confidence_interval_95(samples):
    if len(samples) < 2:
        return 0.0
    df = len(samples) - 1
    t_critical = T_CRITICAL_95.get(df, 1.96)
    return t_critical * statistics.stdev(samples) / math.sqrt(len(samples))


def extract_round_runtimes(path):
    values = []
    with open(path) as f:
        for line in f:
            match = re.search(r"Round runtime:\s*([0-9.eE+-]+)", line)
            if match:
                values.append(float(match.group(1)))
    return values


def extract_average_runtime(path):
    value = None
    with open(path) as f:
        for line in f:
            match = re.search(r"Average runtime:\s*([0-9.eE+-]+)", line)
            if match:
                value = float(match.group(1))
    if value is None:
        raise RuntimeError(f"No runtime found in {path}")
    return value


def summarize_runtime(path):
    samples = extract_round_runtimes(path)
    if samples:
        return statistics.mean(samples), confidence_interval_95(samples)
    return extract_average_runtime(path), 0.0


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


def read_table(metric_dir, datasets, configs, prefix, suffix):
    rows = []
    for dataset in datasets:
        row = [DISPLAY_NAMES.get(dataset, dataset)]
        for config in configs:
            path = os.path.join(metric_dir, f"{prefix}_{dataset}_{config}{suffix}.txt")
            avg, ci = summarize_runtime(path)
            row.append(runtime_ci_fmt(avg, ci))
        rows.append((DATASET_ORDER.get(dataset.lower(), len(DATASET_ORDER)), row))
    rows.sort(key=lambda item: item[0])
    return [row for _, row in rows]


def write_tex(rows, configs, output_path, title, config_label, header_label, tabcolsep):
    tex = build_tex(rows, configs, output_path, title, config_label, header_label, tabcolsep)
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w") as f:
        f.write(tex)


def build_tex(rows, configs, output_path, title, config_label, header_label, tabcolsep):
    column_spec = "l|" + "c" * len(configs)
    lines = [
        r"\begin{table}[H]",
        r" \scriptsize",
        r" \centering",
        rf" \setlength{{\tabcolsep}}{{{tabcolsep}}}",
        r" \renewcommand{\arraystretch}{1.0}",
        r" \resizebox{\columnwidth}{!}{%",
        rf" \begin{{tabular}}{{{column_spec}}}",
        r" \toprule",
        f" {header_label} & " + " & ".join(str(config) for config in configs) + r" \\",
        r" \midrule",
    ]

    for row in rows:
        lines.append(" " + " & ".join(row) + r" \\")

    lines.extend([
        r" \bottomrule",
        r" \end{tabular}",
        r" }",
        r" \captionsetup{skip=4pt}",
        r" \caption{",
        rf" {title}. Columns report {config_label}.",
        r" Runtime entries are reported as mean $\pm$ 95\% confidence interval over 20 rounds.",
        r" }",
        r" \label{tab:" + output_label(output_path) + r"}",
        r"\vspace{-4pt}",
        r"\end{table}",
        "",
    ])

    return "\n".join(lines)


def output_label(path):
    name = os.path.splitext(os.path.basename(path))[0]
    if name.startswith("tab_"):
        name = name[4:]
    return name.replace("_", "-")


def parse_args():
    parser = argparse.ArgumentParser(description="Generate scalability CI table.")
    parser.add_argument("--metrics-dir", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--datasets", nargs="+", required=True)
    parser.add_argument("--configs", nargs="+", required=True)
    parser.add_argument("--prefix", required=True)
    parser.add_argument("--suffix", required=True)
    parser.add_argument("--title", required=True)
    parser.add_argument("--config-label", required=True)
    parser.add_argument("--header-label", default="Dataset")
    parser.add_argument("--tabcolsep", default="3pt")
    return parser.parse_args()


def main():
    args = parse_args()
    rows = read_table(
        args.metrics_dir,
        args.datasets,
        args.configs,
        args.prefix,
        args.suffix,
    )
    write_tex(
        rows,
        args.configs,
        args.output,
        args.title,
        args.config_label,
        args.header_label,
        args.tabcolsep,
    )
    print(f"[OK] Wrote {args.output}")


if __name__ == "__main__":
    main()
