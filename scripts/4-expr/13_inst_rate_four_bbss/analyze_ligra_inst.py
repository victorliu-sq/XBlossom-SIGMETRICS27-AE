#!/usr/bin/env python3
import sys
import csv
import os
import re
from statistics import mean
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[1]))
from experiment_ci import append_sample, rewrite_summary_from_samples

# ============================================================
# Helper Functions
# ============================================================

def extract_runtimes_ms(timing_file):
    """
    Extract all runtimes (sec) from a timing file and convert to ms.
    Line format: 'Running time : 0.0097'
    """
    runtimes = []
    with open(timing_file) as f:
        for line in f:
            m = re.search(r"Running time\s*:\s*([0-9.]+)", line)
            if m:
                sec = float(m.group(1))
                runtimes.append(sec * 1000.0)
    return runtimes


def extract_total_instructions(prof_file):
    """
    Sum all 'instructions' counters.
    """
    total = 0
    with open(prof_file) as f:
        for line in f:
            if "instructions" in line:
                parts = line.strip().split(',')
                try:
                    total += int(parts[0])
                except:
                    pass
    return total


def extract_llc_load_misses(prof_file):
    """
    Extract the *raw* LLC-load-misses count (integer).
    """
    with open(prof_file) as f:
        for line in f:
            if "LLC-load-misses" in line:
                parts = line.strip().split(',')
                try:
                    return int(parts[0])
                except:
                    return 0
    return 0


# ============================================================
# Main
# ============================================================

if len(sys.argv) != 4:
    print("Usage: analyze.py <dataset> <metrics_dir> <summary_csv>")
    sys.exit(1)

dataset = sys.argv[1]
metrics_dir = sys.argv[2]
summary_csv = sys.argv[3]

# Timing and profiling files
timing_files = sorted([
    os.path.join(metrics_dir, f)
    for f in os.listdir(metrics_dir)
    if f.startswith(f"ligra_{dataset}_src") and f.endswith("_timing.txt")
])

prof_files = sorted([
    os.path.join(metrics_dir, f)
    for f in os.listdir(metrics_dir)
    if f.startswith(f"ligra_{dataset}_src") and f.endswith("_profiling.txt")
])

if not timing_files or not prof_files:
    print(f"[WARN] No files found for dataset {dataset}. Skipping.")
    sys.exit(0)

all_runtimes_ms = []
total_instructions = 0
total_llc_misses = 0

# ---- Extract runtimes ----
for tfile in timing_files:
    r = extract_runtimes_ms(tfile)
    if r:
        all_runtimes_ms.extend(r)

# ---- Extract instruction counts ----
for pfile in prof_files:
    total_instructions += extract_total_instructions(pfile)

# ---- Extract raw LLC misses ----
for pfile in prof_files:
    total_llc_misses += extract_llc_load_misses(pfile)

if not all_runtimes_ms:
    raise RuntimeError(f"No runtimes found for dataset {dataset}")

# ============================================================
# Compute final statistics and write summary CSV
# ============================================================

total_runtime_seconds = sum(all_runtimes_ms) / 1000.0
num_rounds = len(all_runtimes_ms)
inst_exec_rate_gips = (total_instructions / total_runtime_seconds) / 1e9

samples_csv = f"{os.path.splitext(summary_csv)[0]}_samples.csv"
instructions_per_round = total_instructions / num_rounds
for runtime_ms in all_runtimes_ms:
    runtime_s = runtime_ms / 1000.0
    append_sample(
        samples_csv,
        ["Dataset", "InstructionExecRate(GIPS)"],
        {"Dataset": dataset, "InstructionExecRate(GIPS)": f"{instructions_per_round / runtime_s / 1e9:.9f}"},
    )
rewrite_summary_from_samples(
    samples_csv,
    summary_csv,
    "InstructionExecRate(GIPS)",
    "InstructionExecRateCI(GIPS)",
)

print(
    f"[OK] {dataset}: "
    # f"avg_runtime={avg_runtime_s:.4f} ms, "
    # f"LLC_misses/round={avg_llc_misses_per_round:.4f}, "
    f"InstRate={inst_exec_rate_gips:.4f} GIPS, "
    # f"LoadRate={data_load_rate_gbps:.4f} GB/s"
)
