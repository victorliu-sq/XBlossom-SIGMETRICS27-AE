#!/usr/bin/env python3
import csv
import math
import os
import re
from pathlib import Path

T_95 = {
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


def confidence_interval_95(values):
    values = [float(v) for v in values if math.isfinite(float(v))]
    n = len(values)
    if n == 0:
        return math.nan, math.nan
    mean = sum(values) / n
    if n == 1:
        return mean, 0.0
    variance = sum((v - mean) ** 2 for v in values) / (n - 1)
    t_value = T_95.get(n - 1, 1.96)
    return mean, t_value * math.sqrt(variance / n)


def read_grouped_samples(path, dataset_col="Dataset", value_col="Value"):
    grouped = {}
    if not Path(path).exists():
        return grouped
    with open(path, newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            dataset = row[dataset_col]
            grouped.setdefault(dataset, []).append(float(row[value_col]))
    return grouped


def append_sample(path, headers, row):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    write_header = not os.path.exists(path) or os.path.getsize(path) == 0
    with open(path, "a", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=headers)
        if write_header:
            writer.writeheader()
        writer.writerow(row)


def rewrite_summary_from_samples(sample_csv, summary_csv, metric_name, ci_name=None):
    ci_name = ci_name or f"{metric_name}CI"
    grouped = read_grouped_samples(sample_csv, value_col=metric_name)
    os.makedirs(os.path.dirname(summary_csv), exist_ok=True)
    with open(summary_csv, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["Dataset", metric_name, ci_name, "Samples"])
        for dataset, values in grouped.items():
            mean, ci = confidence_interval_95(values)
            writer.writerow([dataset, f"{mean:.6f}", f"{ci:.6f}", len(values)])


def extract_average_runtime_seconds(timing_file):
    with open(timing_file) as f:
        for line in f:
            match = re.search(r"Average runtime:\s*([0-9.eE+-]+)", line)
            if match:
                return float(match.group(1))
    raise RuntimeError(f"No 'Average runtime' found in {timing_file}")


def extract_round_runtimes_seconds(timing_file):
    values = []
    with open(timing_file) as f:
        for line in f:
            match = re.search(r"Round runtime:\s*([0-9.eE+-]+)", line)
            if match:
                values.append(float(match.group(1)))
    return values


def grouped_runtime_sums(round_runtimes, groups=20):
    if not round_runtimes:
        return []
    groups = min(groups, len(round_runtimes))
    base = len(round_runtimes) // groups
    extra = len(round_runtimes) % groups
    samples = []
    start = 0
    for group in range(groups):
        size = base + (1 if group < extra else 0)
        end = start + size
        samples.append(sum(round_runtimes[start:end]))
        start = end
    return samples


def extract_metric_values(timing_file, label):
    pattern = re.compile(rf"{re.escape(label)}:\s*([0-9.eE+-]+)")
    values = []
    with open(timing_file) as f:
        for line in f:
            match = pattern.search(line)
            if match:
                values.append(float(match.group(1)))
    if not values:
        raise RuntimeError(f"No '{label}' found in {timing_file}")
    return values


def compact_number(value):
    value = float(value)
    if not math.isfinite(value):
        return "NA"
    if value == 0:
        return "0"
    abs_value = abs(value)
    if abs_value >= 100:
        return f"{value:.1f}"
    if abs_value >= 10:
        return f"{value:.2f}"
    if abs_value >= 1:
        return f"{value:.3f}"
    if abs_value >= 0.01:
        return f"{value:.4f}"
    if abs_value >= 0.0001:
        return f"{value:.6f}"
    return f"{value:.8f}"


def latex_mean_ci(mean, ci):
    return f"{compact_number(mean)} {{\\tiny $\\pm$ {compact_number(ci)}}}"
