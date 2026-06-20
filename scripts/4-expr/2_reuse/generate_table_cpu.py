#!/usr/bin/env python3
import sys
import csv
import os
import re
import math
import statistics

DATASET_ORDER = {
    name.lower(): idx
    for idx, name in enumerate([
        "GPlus", "Twitch", "Amazon", "HiggsNets", "Youtube",
        "Hyperlink", "Wikipedia", "Stackoverflow", "Patent", "Livejournal"
    ])
}


def sort_summary_by_node_count(summary_csv):
    with open(summary_csv, newline="") as f:
        rows = list(csv.DictReader(f))

    if not rows:
        return

    fieldnames = rows[0].keys()
    rows.sort(key=lambda row: DATASET_ORDER.get(row["Dataset"].strip().lower(), len(DATASET_ORDER)))

    with open(summary_csv, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


# ============================================================
# Extract runtime statistics (seconds)
# ============================================================

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
}


def confidence_interval_95(samples):
    if len(samples) < 2:
        return 0.0

    df = len(samples) - 1
    t_critical = T_CRITICAL_95.get(df, 1.96)
    sample_std = statistics.stdev(samples)
    return t_critical * sample_std / math.sqrt(len(samples))


def extract_runtime_stats_seconds(timing_file):
    """
    Extract all "Round runtime: X.XXXX" samples and compute mean and 95% CI.
    Falls back to "Average runtime: X.XXXX" for older timing files.
    """
    round_runtimes = []
    avg_runtime = None
    with open(timing_file) as f:
        for line in f:
            m = re.search(r"Round runtime:\s*([0-9.eE+-]+)", line)
            if m:
                round_runtimes.append(float(m.group(1)))

            m = re.search(r"Average runtime:\s*([0-9.]+)", line)
            if m:
                avg_runtime = float(m.group(1))

    if round_runtimes:
        return statistics.mean(round_runtimes), confidence_interval_95(round_runtimes)

    if avg_runtime is not None:
        return avg_runtime, 0.0

    raise RuntimeError(f"[ERROR] No 'Average runtime' found in: {timing_file}")


def extract_reused_tree_nodes_per_second(timing_file, avg_runtime):
    reused_tree_nodes = None
    with open(timing_file) as f:
      for line in f:
        m = re.search(r"ReusedTreeNodes/s:\s*([0-9.eE+-]+)", line)
        if m:
            return float(m.group(1))

        m = re.search(r"Number of Reused Tree Nodes:\s*([0-9.eE+-]+)", line)
        if m:
            reused_tree_nodes = float(m.group(1))

        m = re.search(r"Number of Saved Tree Nodes:\s*([0-9.eE+-]+)", line)
        if m:
            reused_tree_nodes = float(m.group(1))

    if reused_tree_nodes is not None and avg_runtime > 0:
        return reused_tree_nodes / avg_runtime

    return 0.0


def extract_tree_reuse_metrics(timing_file, avg_runtime):
    reused_tree_nodes = None
    reset_tree_nodes = None
    reused_tree_nodes_per_second = None
    reset_tree_nodes_per_second = None
    reuse_ratio = None
    round_reuse_ratios = []

    with open(timing_file) as f:
      for line in f:
        m = re.search(r"Round ReuseRatio:\s*([0-9.eE+-]+)", line)
        if m:
            round_reuse_ratios.append(float(m.group(1)))

        m = re.search(r"ReusedTreeNodes/s:\s*([0-9.eE+-]+)", line)
        if m:
            reused_tree_nodes_per_second = float(m.group(1))

        m = re.search(r"ResetTreeNodes/s:\s*([0-9.eE+-]+)", line)
        if m:
            reset_tree_nodes_per_second = float(m.group(1))

        m = re.search(r"ReuseRatio:\s*([0-9.eE+-]+)", line)
        if m:
            reuse_ratio = float(m.group(1))

        m = re.search(r"Number of Reused Tree Nodes:\s*([0-9.eE+-]+)", line)
        if m:
            reused_tree_nodes = float(m.group(1))

        m = re.search(r"Number of Saved Tree Nodes:\s*([0-9.eE+-]+)", line)
        if m:
            reused_tree_nodes = float(m.group(1))

        m = re.search(r"Number of Reset Tree Nodes:\s*([0-9.eE+-]+)", line)
        if m:
            reset_tree_nodes = float(m.group(1))

    if reused_tree_nodes_per_second is None:
        reused_tree_nodes_per_second = (
            reused_tree_nodes / avg_runtime
            if reused_tree_nodes is not None and avg_runtime > 0
            else 0.0
        )

    if reset_tree_nodes_per_second is None:
        reset_tree_nodes_per_second = (
            reset_tree_nodes / avg_runtime
            if reset_tree_nodes is not None and avg_runtime > 0
            else 0.0
        )

    if round_reuse_ratios:
        reuse_ratio = statistics.mean(round_reuse_ratios)
        reuse_ratio_ci = confidence_interval_95(round_reuse_ratios)
    else:
        reuse_ratio_ci = 0.0

    if reuse_ratio is None:
        reused = reused_tree_nodes if reused_tree_nodes is not None else 0.0
        reset = reset_tree_nodes if reset_tree_nodes is not None else 0.0
        denom = reused + reset
        reuse_ratio = reused / denom if denom > 0 else 0.0

    return reused_tree_nodes_per_second, reset_tree_nodes_per_second, reuse_ratio, reuse_ratio_ci


# ============================================================
# Main
# ============================================================

if len(sys.argv) != 5:
    print("Usage: generate_table_cpu.py "
          "<dataset> <timing_xb> <timing_xb_pro> <summary_csv>")
    sys.exit(1)

dataset        = sys.argv[1]
timing_xb      = sys.argv[2]
timing_xb_pro  = sys.argv[3]
summary_csv    = sys.argv[4]

# Extract runtimes
avg_xb, ci_xb = extract_runtime_stats_seconds(timing_xb)
avg_xb_pro, ci_xb_pro = extract_runtime_stats_seconds(timing_xb_pro)
reused_tree_nodes_per_second, reset_tree_nodes_per_second, reuse_ratio, reuse_ratio_ci = extract_tree_reuse_metrics(
    timing_xb_pro, avg_xb_pro
)

# Calculate speedup: XB / XB-Pro
speedup = avg_xb / avg_xb_pro if avg_xb_pro > 0 else 0.0

# ============================================================
# Write CSV
# ============================================================

write_header = not os.path.exists(summary_csv)

with open(summary_csv, "a", newline="") as f:
    writer = csv.writer(f)

    # header only once
    if write_header:
        writer.writerow([
            "Dataset",
            "AvgRuntime_XB(s)",
            "CI95_XB(s)",
            "AvgRuntime_XBPro(s)",
            "CI95_XBPro(s)",
            "Speedup",
            "ReuseRatio",
            "CI95_ReuseRatio"
        ])

    writer.writerow([
        dataset,
        f"{avg_xb:.6f}",
        f"{ci_xb:.6f}",
        f"{avg_xb_pro:.6f}",
        f"{ci_xb_pro:.6f}",
        f"{speedup:.4f}",
        f"{reuse_ratio:.4f}",
        f"{reuse_ratio_ci:.4f}"
    ])

sort_summary_by_node_count(summary_csv)

print(
    f"[OK] {dataset}: "
    f"XB={avg_xb:.6f}s ± {ci_xb:.6f}s, "
    f"XB-Pro={avg_xb_pro:.6f}s ± {ci_xb_pro:.6f}s, "
    f"Speedup={speedup:.4f}, "
    f"ReusedTreeNodes/s={reused_tree_nodes_per_second:.2f}, "
    f"ResetTreeNodes/s={reset_tree_nodes_per_second:.2f}, "
    f"ReuseRatio={reuse_ratio:.4f} ± {reuse_ratio_ci:.4f}"
)
