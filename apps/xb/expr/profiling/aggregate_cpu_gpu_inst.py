#!/usr/bin/env python3
import sys
import os
import json
import csv
import re

if len(sys.argv) != 6:
    print("Usage: python3 aggregate_cpu_gpu_inst.py <cpu_json> <gpu_json> <cpu_inst_txt> <gpu_inst_txt> <output_csv>")
    sys.exit(1)

cpu_json_file, gpu_json_file, cpu_inst_txt, gpu_inst_txt, output_csv = sys.argv[1:]

# ----------- Dataset name normalization -----------
NORMALIZE = {
    "higgnets": "higgsnets",
    "wiki": "wikipedia",
}

def normalize_name(name: str) -> str:
    name = name.lower()
    return NORMALIZE.get(name, name)


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


# ---------------- CPU instructions summary ----------------
cpu_insts = {}
with open(cpu_inst_txt) as f:
    current_ds = None
    for line in f:
        line = line.strip()
        if line.startswith("DATASET:"):
            current_ds = normalize_name(line.split(":")[1].strip().lower())
            cpu_insts[current_ds] = 0
        elif current_ds and line and not line.startswith("-"):
            parts = line.split(",")
            if len(parts) >= 3 and ("instructions" in parts[2]):
                try:
                    val = int(parts[0])  # first col = event count
                    cpu_insts[current_ds] += val
                except ValueError:
                    pass


# ---------------- GPU instructions summary (thread instructions) ----------------
gpu_insts = {}
with open(gpu_inst_txt) as f:
    current_ds = None
    for line in f:
        line = line.strip()
        if line.startswith("DATASET:"):
            current_ds = normalize_name(line.split(":")[1].strip().lower())
        elif current_ds and line.startswith("Total Thread Instructions Executed:"):
            val = int(line.split(":")[1].split()[0])
            gpu_insts[current_ds] = val
            current_ds = None


# ---------------- Write CSV ----------------
with open(output_csv, "w", newline="") as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow([
        "dataset",
        "cpu_insts", "cpu_time_s", "cpu_ops_per_s",
        "gpu_thread_insts", "gpu_time_s", "gpu_thread_ops_per_s"
    ])

    all_datasets = set(cpu_times) | set(gpu_times) | set(cpu_insts) | set(gpu_insts)
    for ds in sorted(all_datasets):
        c_insts = cpu_insts.get(ds, 0)
        c_time = cpu_times.get(ds, 0.0)
        c_ops_per_s = c_insts / c_time if c_time > 0 else 0

        g_thread_insts = gpu_insts.get(ds, 0)
        g_time = gpu_times.get(ds, 0.0)
        # already thread-level instructions → no multiply by 32
        g_ops_per_s = g_thread_insts / g_time if g_time > 0 else 0

        writer.writerow([
            ds,
            c_insts, f"{c_time:.3f}", f"{c_ops_per_s:.2e}",
            g_thread_insts, f"{g_time:.3f}", f"{g_ops_per_s:.2e}"
        ])
