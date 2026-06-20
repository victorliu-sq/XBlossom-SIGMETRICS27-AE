#!/usr/bin/env python3
import sys
import csv
import os
import re
from statistics import mean

# ============================================================
# Helper Functions
# ============================================================

def extract_runtimes_ms(timing_file):
    """
    Extract all runtimes from a timing file.
    Lines look like: "Running time : 0.0097"
    Returns a list of runtimes in milliseconds.
    """
    runtimes = []
    with open(timing_file) as f:
        for line in f:
            m = re.search(r"Running time\s*:\s*([0-9.]+)", line)
            if m:
                sec = float(m.group(1))
                runtimes.append(sec * 1000.0)  # convert to ms
    return runtimes


def extract_llc_miss_rate(prof_file):
    """
    Extract LLC miss rate (%) from perf stat output.
    Format example:
      8800223,,cpu_core/LLC-load-misses/,90296300827,100.00,3.91,...
                                                   ^^^^^^^ miss rate (%)
    """
    with open(prof_file) as f:
        for line in f:
            if "LLC-load-misses" in line:
                parts = line.strip().split(',')
                try:
                    return float(parts[5])
                except:
                    pass
    return None


def extract_total_instructions(prof_file):
    """
    Extract cpu_core/instructions + cpu_atom/instructions.
    Example lines:

    93135669323,,cpu_atom/instructions/,90296365649,100.00,,
    97516442171,,cpu_core/instructions/,90296330861,100.00,,

    We sum both.
    """
    total = 0
    with open(prof_file) as f:
        for line in f:
            if "instructions" in line:
                parts = line.strip().split(',')
                try:
                    val = int(parts[0])
                    total += val
                except:
                    pass
    return total


# ============================================================
# Main
# ============================================================

if len(sys.argv) != 4:
    print("Usage: analyze.py <dataset> <metrics_dir> <summary_csv>")
    sys.exit(1)

dataset = sys.argv[1]
metrics_dir = sys.argv[2]
summary_csv = sys.argv[3]

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
all_llc_rates = []
total_instructions = 0

# ---- Extract runtime ----
for tfile in timing_files:
    r = extract_runtimes_ms(tfile)
    if r:
        all_runtimes_ms.extend(r)

# ---- Extract LLC miss rate ----
for pfile in prof_files:
    miss_rate = extract_llc_miss_rate(pfile)
    if miss_rate is not None:
        all_llc_rates.append(miss_rate)

# ---- Extract instruction counts ----
for pfile in prof_files:
    total_instructions += extract_total_instructions(pfile)

if not all_runtimes_ms:
    raise RuntimeError(f"No runtimes found for dataset {dataset}")
if not all_llc_rates:
    raise RuntimeError(f"No LLC miss rates found for dataset {dataset}")

# ============================================================
# Compute final statistics
# ============================================================

avg_runtime_ms = mean(all_runtimes_ms)

# Total runtime in seconds (for GIPS)
total_runtime_seconds = sum(all_runtimes_ms) / 1000.0

# Instruction execution rate in billions per second
inst_exec_rate_gips = (total_instructions / total_runtime_seconds) / 1e9

avg_llc_rate = mean(all_llc_rates)

# ============================================================
# Write to summary CSV
# ============================================================

write_header = not os.path.exists(summary_csv)

with open(summary_csv, "a", newline="") as f:
    writer = csv.writer(f)
    if write_header:
        writer.writerow([
            "Dataset",
            "AvgRuntime(ms)",
            "AvgLLCMissRate(%)",
            "InstructionExecRate(GIPS)"
        ])

    writer.writerow([
        dataset,
        f"{avg_runtime_ms:.4f}",
        f"{avg_llc_rate:.4f}",
        f"{inst_exec_rate_gips:.4f}",
    ])

print(
    f"[OK] {dataset}: "
    f"avg_runtime={avg_runtime_ms:.4f} ms, "
    f"LLC rate={avg_llc_rate:.4f} %, "
    f"InstRate={inst_exec_rate_gips:.4f} GIPS"
)
