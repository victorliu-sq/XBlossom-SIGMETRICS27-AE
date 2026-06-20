#!/usr/bin/env python3
import csv
import os
import sys


DISPLAY_NAMES = {
    "Stackoverflow": "StackOverflow",
    "Livejournal": "LiveJournal",
}


def int_fmt(value):
    return f"{float(value):,.0f}"


def degree_fmt(value):
    value = float(value)
    if value >= 100:
        return f"{value:.0f}"
    if value >= 10:
        return f"{value:.1f}"
    return f"{value:.2f}"


def blossoms_per_node_fmt(value):
    value = float(value)
    if value == 0.0:
        return "0"
    if value >= 10:
        return f"{value:.1f}"
    if value >= 1:
        return f"{value:.2f}"
    if value >= 0.01:
        return f"{value:.3f}"
    return f"{value:.6f}"


def ci_fmt(value, ci, value_formatter, ci_formatter=None):
    if ci_formatter is None:
        ci_formatter = value_formatter
    return f"{value_formatter(value)} {{\\tiny $\\pm$ {ci_formatter(ci)}}}"


def read_rows(path):
    with open(path, newline="") as f:
        return list(csv.DictReader(f))


def make_row(row, include_ci=False):
    values = [
        DISPLAY_NAMES.get(row["Dataset"], row["Dataset"]),
        int_fmt(row["NumNodes"]),
        int_fmt(row["NumEdges"]),
        degree_fmt(row["MaxDegree"]),
        degree_fmt(row["AvgDegree"]),
    ]

    if include_ci:
        values.extend([
            ci_fmt(
                row["AvgBlossomsPerNode"],
                row["CI95_AvgBlossomsPerNode"],
                blossoms_per_node_fmt,
            ),
        ])
    else:
        values.extend([
            blossoms_per_node_fmt(row["AvgBlossomsPerNode"]),
        ])

    return values


def write_tex(rows, output_path, include_ci=False):
    table_env = "table*" if include_ci else "table"
    font_size = r" \footnotesize" if include_ci else r" \small"
    tabcolsep = "9pt" if include_ci else "3pt"
    begin_tabular = (
        r" \begin{tabular*}{\textwidth}{@{\extracolsep{\fill}}c|rrrcc}"
        if include_ci else
        r" \begin{tabular}{l|rrrrr}"
    )
    end_tabular = r" \end{tabular*}" if include_ci else r" \end{tabular}"

    lines = [
        rf"\begin{{{table_env}}}[h]",
        font_size,
        r" \centering",
        rf" \setlength{{\tabcolsep}}{{{tabcolsep}}}",
        r" \renewcommand{\arraystretch}{1.0}",
    ]

    lines.extend([
        begin_tabular,
        r" \toprule",
        r" Dataset &",
        r" $|V|$ &",
        r" $|E|$ &",
        r" Max Deg. &",
        r" Avg Deg. &",
        r" Avg~Blossoms \\",
        r" \midrule",
    ])

    for row in rows:
        lines.append(" " + " & ".join(make_row(row, include_ci)) + r" \\")

    lines.extend([
        r" \bottomrule",
        end_tabular,
    ])

    lines.extend([
        r" \captionsetup{skip=4pt}",
        r" \caption{",
        r" Graph structural metrics and blossom statistics for the evaluated datasets.",
    ])

    if include_ci:
        lines.append(r" Avg~Blossoms entries are reported as mean $\pm$ 95\% confidence interval over 50 rounds.")

    lines.extend([
        r" }",
        r" \label{tab:graph-metrics}",
        r"\vspace{-4pt}",
        rf"\end{{{table_env}}}",
        "",
    ])

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w") as f:
        f.write("\n".join(lines))


def main():
    if len(sys.argv) != 3:
        print("Usage: generate_table_1_tex.py <graph_metrics.csv> <output.tex>")
        sys.exit(1)

    input_csv, output_tex = sys.argv[1:]
    rows = read_rows(input_csv)
    ci_output_tex = output_tex.replace(".tex", "_ci.tex")

    write_tex(rows, output_tex)
    write_tex(rows, ci_output_tex, include_ci=True)

    print(f"[OK] Wrote LaTeX Table 1 to {output_tex}")
    print(f"[OK] Wrote LaTeX Table 1 with CI to {ci_output_tex}")


if __name__ == "__main__":
    main()
