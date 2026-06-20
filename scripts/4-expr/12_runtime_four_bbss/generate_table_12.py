#!/usr/bin/env python3
import argparse
import csv
import re
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[1]))
from experiment_ci import confidence_interval_95, latex_mean_ci


DATASETS = [
    "GPlus", "Twitch", "Amazon", "HiggsNets", "Youtube",
    "Hyperlink", "Wikipedia", "Stackoverflow", "Patent", "Livejournal"
]

ALGORITHMS = [
    ("bfs", "BFS", "bfs_ligra", "bfs_gunrock"),
    ("sssp", "SSSP", "sssp_ligra", "sssp_gunrock"),
    ("multisssp", "MSSP", "multisssp_ligra", "multisssp_gunrock"),
]


def read_rows(path):
    with open(path, newline="") as f:
        return {row["Dataset"]: row for row in csv.DictReader(f)}


def as_float(row, *names):
    for name in names:
        if name in row and row[name] != "":
            return float(row[name])
    return 0.0


def read_sample_csv(samples_root, stem, dataset, value_cols):
    path = samples_root / f"figure_12_{stem}_samples.csv"
    if not path.exists():
        return []
    samples = []
    with open(path, newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row.get("Dataset") != dataset:
                continue
            for col in value_cols:
                if col in row and row[col] != "":
                    samples.append(float(row[col]))
                    break
    return samples


def read_ligra_samples(metrics_root, subdir, dataset):
    samples = []
    for path in sorted((metrics_root / subdir).glob(f"ligra_{dataset}_*_timing.txt")):
        with open(path) as f:
            for line in f:
                match = re.search(r"Running time\s*:\s*([0-9.eE+-]+)", line)
                if match:
                    samples.append(float(match.group(1)))
    return samples


def read_gunrock_samples(metrics_root, subdir, algorithm, dataset):
    path = metrics_root / subdir / f"{algorithm}_gunrock_timing_{dataset}.txt"
    if not path.exists():
        return []
    samples = []
    with open(path) as f:
        for line in f:
            match = re.search(r"GPU Elapsed Time\s*:\s*([0-9.eE+-]+)\s*\(ms\)", line)
            if match:
                samples.append(float(match.group(1)) / 1000.0)
    return samples


def summarize(samples):
    mean, ci = confidence_interval_95(samples)
    if mean != mean:
        return 0.0, 0.0
    return mean, ci


def build_algorithm_rows(metrics_root, samples_root, algorithm, ligra_dir, gunrock_dir):
    rows = []
    for dataset in DATASETS:
        ligra_samples = read_sample_csv(samples_root, ligra_dir, dataset, ["AvgRuntime(s)", "Runtime(s)"])
        if not ligra_samples:
            ligra_samples = read_ligra_samples(metrics_root, ligra_dir, dataset)
        gunrock_samples = read_sample_csv(samples_root, gunrock_dir, dataset, ["Runtime(s)", "AvgRuntime(s)"])
        if not gunrock_samples:
            gunrock_samples = read_gunrock_samples(metrics_root, gunrock_dir, algorithm, dataset)
        ligra_mean, ligra_ci = summarize(ligra_samples)
        gunrock_mean, gunrock_ci = summarize(gunrock_samples)
        rows.append({
            "Dataset": dataset,
            "Ligra Runtime(s)": ligra_mean,
            "Ligra CI(s)": ligra_ci,
            "Gunrock Runtime(s)": gunrock_mean,
            "Gunrock CI(s)": gunrock_ci,
        })
    return rows


def build_xb_rows(xb_pro_csv, xb_pp_csv, samples_root):
    xb_pro = read_rows(xb_pro_csv)
    xb_pp = read_rows(xb_pp_csv)
    rows = []
    for dataset in DATASETS:
        pro = xb_pro.get(dataset, {})
        pp = xb_pp.get(dataset, {})
        xb_pro_samples = read_sample_csv(samples_root, "xb_pro", dataset, ["AvgRuntime(s)"])
        xb_pp_samples = read_sample_csv(samples_root, "xb_pp", dataset, ["AvgRuntime_XB++(s)", "AvgRuntime(s)"])
        xb_pro_mean, xb_pro_ci = summarize(xb_pro_samples) if xb_pro_samples else (
            as_float(pro, "AvgRuntime(s)"),
            as_float(pro, "AvgRuntimeCI(s)"),
        )
        xb_pp_mean, xb_pp_ci = summarize(xb_pp_samples) if xb_pp_samples else (
            as_float(pp, "AvgRuntime_XB++(s)"),
            as_float(pp, "AvgRuntimeCI_XB++(s)"),
        )
        rows.append({
            "Dataset": dataset,
            "XB-Pro Runtime(s)": xb_pro_mean,
            "XB-Pro CI(s)": xb_pro_ci,
            "XB++ Runtime(s)": xb_pp_mean,
            "XB++ CI(s)": xb_pp_ci,
        })
    return rows


def write_csv(path, tables):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["Algorithm", "Dataset", "Implementation", "Runtime(s)", "RuntimeCI(s)"])
        for algorithm, _, rows, columns in tables:
            for row in rows:
                for impl, mean_col, ci_col in columns:
                    writer.writerow([
                        algorithm,
                        row["Dataset"],
                        impl,
                        f"{row[mean_col]:.6f}",
                        f"{row[ci_col]:.6f}",
                    ])


def tex_table(tables):
    lines = [
        r"\begin{table}[H]",
        r"\footnotesize",
        r"\centering",
        r"\setlength{\tabcolsep}{3pt}",
        r"\renewcommand{\arraystretch}{1.0}",
        r"\resizebox{\columnwidth}{!}{%",
        r"\begin{tabular}{l|cc|cc|cc|cc}",
        r"\toprule",
        " & " + " & ".join(
            rf"\multicolumn{{2}}{{c{'|' if idx < len(tables) - 1 else ''}}}{{\textbf{{{title}}}}}"
            for idx, (_, title, _, _) in enumerate(tables)
        ) + r" \\",
        r"\cmidrule(lr){2-3} \cmidrule(lr){4-5} \cmidrule(lr){6-7} \cmidrule(lr){8-9}",
        "Dataset & " + " & ".join(
            impl
            for _, _, _, columns in tables
            for impl, _, _ in columns
        ) + r" \\",
        r"\midrule",
    ]
    rows_by_table = [
        {row["Dataset"]: row for row in rows}
        for _, _, rows, _ in tables
    ]
    for dataset in DATASETS:
        values = [
            latex_mean_ci(
                rows_by_table[table_idx][dataset][mean_col],
                rows_by_table[table_idx][dataset][ci_col],
            )
            for table_idx, (_, _, _, columns) in enumerate(tables)
            for _, mean_col, ci_col in columns
        ]
        lines.append(dataset + " & " + " & ".join(values) + r" \\")
    lines.extend([
        r"\bottomrule",
        r"\end{tabular}",
        r"}",
        r"\captionsetup{skip=4pt}",
        r"\caption{Runtime comparison for BFS, SSSP, MSSP, and X-Blossom variants. "
        r"Runtime entries are reported as mean $\pm$ 95\% confidence interval over 20 rounds.}",
        r"\label{tab:runtime-four-ci}",
        r"\vspace{-4pt}",
        r"\end{table}",
    ])
    return "\n".join(lines)


def write_tex(path, tables):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(tex_table(tables) + "\n")


def parse_args():
    parser = argparse.ArgumentParser(description="Generate Figure 12 runtime CI tables")
    parser.add_argument("--metrics_root", required=True)
    parser.add_argument("--samples_root", required=True)
    parser.add_argument("--xb_pro_csv", required=True)
    parser.add_argument("--xb_pp_csv", required=True)
    parser.add_argument("--csv_output", required=True)
    parser.add_argument("--tex_output", required=True)
    return parser.parse_args()


def main():
    args = parse_args()
    metrics_root = Path(args.metrics_root)
    samples_root = Path(args.samples_root)

    algorithm_tables = []
    for algorithm, title, ligra_dir, gunrock_dir in ALGORITHMS:
        rows = build_algorithm_rows(metrics_root, samples_root, algorithm, ligra_dir, gunrock_dir)
        columns = [
            ("Ligra", "Ligra Runtime(s)", "Ligra CI(s)"),
            ("Gunrock", "Gunrock Runtime(s)", "Gunrock CI(s)"),
        ]
        algorithm_tables.append((algorithm, title, rows, columns))

    xb_rows = build_xb_rows(args.xb_pro_csv, args.xb_pp_csv, samples_root)
    xb_columns = [
        ("XB-Pro", "XB-Pro Runtime(s)", "XB-Pro CI(s)"),
        ("XB++", "XB++ Runtime(s)", "XB++ CI(s)"),
    ]
    algorithm_tables.append(("xb", "XB", xb_rows, xb_columns))

    write_csv(Path(args.csv_output), algorithm_tables)
    write_tex(Path(args.tex_output), algorithm_tables)
    print(f"Generated {args.csv_output} and {args.tex_output}")


if __name__ == "__main__":
    main()
