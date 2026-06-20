#!/usr/bin/env python3
import csv
import math
import os
import re
import statistics
import sys


DATASET_ORDER = {
    name.lower(): idx
    for idx, name in enumerate([
        "GPlus", "Twitch", "Amazon", "HiggsNets", "Youtube",
        "Hyperlink", "Wikipedia", "Stackoverflow", "Patent", "Livejournal"
    ])
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
    21: 2.080,
    22: 2.074,
    23: 2.069,
    24: 2.064,
    25: 2.060,
    26: 2.056,
    27: 2.052,
    28: 2.048,
    29: 2.045,
    30: 2.042,
    31: 2.040,
    32: 2.037,
    33: 2.035,
    34: 2.032,
    35: 2.030,
    36: 2.028,
    37: 2.026,
    38: 2.024,
    39: 2.023,
    40: 2.021,
    41: 2.020,
    42: 2.018,
    43: 2.017,
    44: 2.015,
    45: 2.014,
    46: 2.013,
    47: 2.012,
    48: 2.011,
    49: 2.010,
    50: 2.009,
}


def confidence_interval_95(samples):
    if len(samples) < 2:
        return 0.0
    df = len(samples) - 1
    t_critical = T_CRITICAL_95.get(df, 1.96)
    return t_critical * statistics.stdev(samples) / math.sqrt(len(samples))


def extract_metric(lines, metric_name, cast_type):
    pattern = metric_name + r":\s*([0-9.eE+-]+)"
    for line in lines:
        match = re.search(pattern, line)
        if match:
            return cast_type(match.group(1))
    raise RuntimeError(f"No metric matched pattern: {pattern}")


def extract_all(lines, metric_name, cast_type):
    pattern = metric_name + r":\s*([0-9.eE+-]+)"
    values = []
    for line in lines:
        match = re.search(pattern, line)
        if match:
            values.append(cast_type(match.group(1)))
    return values


def sort_summary(summary_csv):
    with open(summary_csv, newline="") as f:
        rows = list(csv.DictReader(f))

    if not rows:
        return

    fieldnames = rows[0].keys()
    rows.sort(key=lambda row: DATASET_ORDER.get(
        row["Dataset"].strip().lower(), len(DATASET_ORDER)
    ))

    with open(summary_csv, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def main():
    if len(sys.argv) != 4:
        print(
            "Usage: generate_table_csv.py "
            "<dataset> <metrics_file> <summary_csv>"
        )
        sys.exit(1)

    dataset = sys.argv[1]
    metrics_file = sys.argv[2]
    summary_csv = sys.argv[3]

    with open(metrics_file) as f:
        lines = [line.strip() for line in f]

    num_nodes = extract_metric(lines, r"Num of Nodes", int)
    num_edges = extract_metric(lines, r"Num of Edges", int)
    max_degree = extract_metric(lines, r"Max Degree", float)
    avg_degree = extract_metric(lines, r"Avg Degree", float)
    num_blossoms = extract_metric(lines, r"Number of Blossoms", float)
    avg_blossoms_per_node = extract_metric(lines, r"Avg blossoms per Node", float)

    round_blossoms = extract_all(lines, r"Round Number of Blossoms", float)
    if round_blossoms:
        num_blossoms = statistics.mean(round_blossoms)
        ci_num_blossoms = confidence_interval_95(round_blossoms)
        ci_avg_blossoms_per_node = ci_num_blossoms / num_nodes
    else:
        ci_num_blossoms = 0.0
        ci_avg_blossoms_per_node = 0.0

    write_header = not os.path.exists(summary_csv)
    with open(summary_csv, "a", newline="") as f:
        writer = csv.writer(f)
        if write_header:
            writer.writerow([
                "Dataset",
                "NumNodes",
                "NumEdges",
                "MaxDegree",
                "AvgDegree",
                "NumBlossoms",
                "CI95_NumBlossoms",
                "AvgBlossomsPerNode",
                "CI95_AvgBlossomsPerNode",
            ])

        writer.writerow([
            dataset,
            num_nodes,
            num_edges,
            f"{max_degree:.6f}",
            f"{avg_degree:.6f}",
            f"{num_blossoms:.6f}",
            f"{ci_num_blossoms:.6f}",
            f"{avg_blossoms_per_node:.9f}",
            f"{ci_avg_blossoms_per_node:.9f}",
        ])

    sort_summary(summary_csv)

    print(
        f"[OK] {dataset}: "
        f"Nodes={num_nodes}, "
        f"Edges={num_edges}, "
        f"MaxDegree={max_degree}, "
        f"AvgDegree={avg_degree}, "
        f"Blossoms={num_blossoms:.6f}, "
        f"CI95_Blossoms={ci_num_blossoms:.6f}"
    )


if __name__ == "__main__":
    main()
