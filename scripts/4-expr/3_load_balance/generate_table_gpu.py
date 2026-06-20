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
}


def confidence_interval_95(samples):
    if len(samples) < 2:
        return 0.0
    df = len(samples) - 1
    t_critical = T_CRITICAL_95.get(df, 1.96)
    return t_critical * statistics.stdev(samples) / math.sqrt(len(samples))


def extract_avg_runtime_seconds(timing_file):
    avg_runtime = None
    with open(timing_file) as f:
        for line in f:
            match = re.search(r"Average runtime:\s*([0-9.eE+-]+)", line)
            if match:
                avg_runtime = float(match.group(1))
    if avg_runtime is None:
        raise RuntimeError(f"No 'Average runtime' found in {timing_file}")
    return avg_runtime


def extract_round_runtimes(timing_file):
    runtimes = []
    with open(timing_file) as f:
        for line in f:
            match = re.search(r"Round runtime:\s*([0-9.eE+-]+)", line)
            if match:
                runtimes.append(float(match.group(1)))
    return runtimes


def summarize_runtime(timing_file):
    samples = extract_round_runtimes(timing_file)
    if samples:
        return statistics.mean(samples), confidence_interval_95(samples)
    return extract_avg_runtime_seconds(timing_file), 0.0


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
    if len(sys.argv) != 5:
        print(
            "Usage: generate_table_gpu.py "
            "<dataset> <timing_xbpp> <timing_xbpp_nb> <summary_csv>"
        )
        sys.exit(1)

    dataset = sys.argv[1]
    timing_xbpp = sys.argv[2]
    timing_xbpp_nb = sys.argv[3]
    summary_csv = sys.argv[4]

    avg_xbpp, ci_xbpp = summarize_runtime(timing_xbpp)
    avg_xbpp_nb, ci_xbpp_nb = summarize_runtime(timing_xbpp_nb)
    speedup = avg_xbpp_nb / avg_xbpp if avg_xbpp > 0 else 0.0

    write_header = not os.path.exists(summary_csv)
    with open(summary_csv, "a", newline="") as f:
        writer = csv.writer(f)
        if write_header:
            writer.writerow([
                "Dataset",
                "AvgRuntime_XB++NB(s)",
                "CI95_XB++NB(s)",
                "AvgRuntime_XB++(s)",
                "CI95_XB++(s)",
                "Speedup",
            ])
        writer.writerow([
            dataset,
            f"{avg_xbpp_nb:.6f}",
            f"{ci_xbpp_nb:.6f}",
            f"{avg_xbpp:.6f}",
            f"{ci_xbpp:.6f}",
            f"{speedup:.4f}",
        ])

    sort_summary(summary_csv)
    print(
        f"[OK] {dataset}: "
        f"XB++NB={avg_xbpp_nb:.6f}s +/- {ci_xbpp_nb:.6f}s, "
        f"XB++={avg_xbpp:.6f}s +/- {ci_xbpp:.6f}s, "
        f"Speedup={speedup:.4f}"
    )


if __name__ == "__main__":
    main()
