#!/usr/bin/env python3
import sys
import os
import json
import csv
import re

CACHE_LINE_SIZE = 64  # bytes

if len(sys.argv) != 6:
    print("Usage: python3 aggregate_cpu_gpu_bw.py <cpu_json> <gpu_json> <cpu_bw_txt> <gpu_bytes_txt> <output_csv>")
    sys.exit(1)

cpu_json_file, gpu_json_file, cpu_bw_txt, gpu_bytes_txt, output_csv = sys.argv[1:]


def load_clean_json(path):
    """Read a file and return the first valid JSON object inside it."""
    with open(path) as f:
        text = f.read()
    start = text.find("{")
    end = text.rfind("}")
    if start == -1 or end == -1:
        raise ValueError(f"No JSON object found in {path}")
    json_str = text[start:end+1]
    return json.loads(json_str)


# ----------- Dataset name normalization -----------
NORMALIZE = {
    "higgnets": "higgsnets",
    "wiki": "wikipedia",
}

def normalize_name(name: str) -> str:
    name = name.lower()
    return NORMALIZE.get(name, name)


# ---------------- CPU JSON (timings) ----------------
cpu_times = {}
cpu_data = load_clean_json(cpu_json_file)
for bm in cpu_data["benchmarks"]:
    m = re.search(r"DatasetType::(\w+)", bm["name"])
    if not m:
        continue
    ds = normalize_name(m.group(1))
    cpu_times[ds] = bm["Total_ms"] / 1000.0  # convert ms → seconds


# ---------------- GPU JSON (timings) ----------------
gpu_times = {}
gpu_data = load_clean_json(gpu_json_file)
for bm in gpu_data["benchmarks"]:
    m = re.search(r"DatasetType::(\w+)", bm["name"])
    if not m:
        continue
    ds = normalize_name(m.group(1))
    gpu_times[ds] = bm["Total_ms"] / 1000.0  # convert ms → seconds


# ---------------- CPU perf (cache misses) ----------------
cpu_misses = {}
with open(cpu_bw_txt) as f:
    current_ds = None
    for line in f:
        line = line.strip()
        if line.startswith("DATASET:"):
            current_ds = normalize_name(line.split(":")[1].strip().lower())
            cpu_misses[current_ds] = 0
        elif current_ds and line and not line.startswith("-"):
            parts = line.split(",")
            if len(parts) >= 3 and ("cache-misses" in parts[2]):
                try:
                    val = int(parts[0])  # first column = event count
                    cpu_misses[current_ds] += val
                except ValueError:
                    pass


# ---------------- GPU dram bytes summary ----------------
gpu_bytes = {}
with open(gpu_bytes_txt) as f:
    current_ds = None
    for line in f:
        line = line.strip()
        if line.startswith("DATASET:"):
            current_ds = normalize_name(line.split(":")[1].strip().lower())
        elif current_ds and line.startswith("Total DRAM Bytes Read:"):
            val = int(line.split(":")[1].split()[0])
            gpu_bytes[current_ds] = val
            current_ds = None


# ---------------- Write CSV ----------------
with open(output_csv, "w", newline="") as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow([
        "dataset",
        "cpu_misses",
        "cpu_bytes_GB", "cpu_time_s", "cpu_bw_GBs",
        "gpu_bytes_GB", "gpu_time_s", "gpu_bw_GBs"
    ])

    all_datasets = set(cpu_times) | set(gpu_times) | set(cpu_misses) | set(gpu_bytes)
    for ds in sorted(all_datasets):
        misses = cpu_misses.get(ds, 0)
        c_bytes = misses * CACHE_LINE_SIZE
        c_bytes_gb = c_bytes / 1e9
        c_time = cpu_times.get(ds, 0.0)
        c_bw = c_bytes_gb / c_time if c_time > 0 else 0

        g_bytes = gpu_bytes.get(ds, 0)
        g_bytes_gb = g_bytes / 1e9
        g_time = gpu_times.get(ds, 0.0)
        g_bw = g_bytes_gb / g_time if g_time > 0 else 0

        writer.writerow([
            ds,
            misses,
            f"{c_bytes_gb:.2f}", f"{c_time:.3f}", f"{c_bw:.2f}",
            f"{g_bytes_gb:.2f}", f"{g_time:.3f}", f"{g_bw:.2f}"
        ])