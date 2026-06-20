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
    Lines: "Running time : 0.0097"
    Return runtimes in milliseconds.
    """
    runtimes = []
    with open(timing_file) as f:
        for line in f:
            m = re.search(r"Running time\s*:\s*([0-9.]+)", line)
            if m:
                sec = float(m.group(1))
                runtimes.append(sec * 1000.0)
    return runtimes


def extract_llc_miss_rate(prof_file):
    """
    Extract LLC miss rate (%) from perf stat output.
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
    Sum up instruction counts for:
      cpu_core/instructions
      cpu_atom/instructions
      instructions (generic)
    """
    total = 0
    with open(prof_file) as f:
        for line in f:
            if "instructions" in line and "LLC" not in line:
                parts = line.strip().split(',')
                try:
                    total += int(parts[0])
                except:
                    pass
    return total


def extract_total_lock_loads(prof_file):
    """
    Extract lock loads from:
      cpu_core/mem_inst_retired.lock_loads/
    """
    total = 0
    with open(prof_file) as f:
        for line in f:
            if "mem_inst_retired.lock_loads" in line:
                parts = line.strip().split(',')
                try:
                    total += int(parts[0])
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

# Containers
all_runtimes_ms = []
all_llc_rates = []
total_instructions = 0
total_lock_loads = 0

# ---- Extract runtimes ----
for tfile in timing_files:
    all_runtimes_ms.extend(extract_runtimes_ms(tfile))

# ---- Extract LLC miss rates ----
for pfile in prof_files:
    rate = extract_llc_miss_rate(pfile)
    if rate is not None:
        all_llc_rates.append(rate)

# ---- Extract instruction and lock-load counts ----
for pfile in prof_files:
    total_instructions += extract_total_instructions(pfile)
    total_lock_loads  += extract_total_lock_loads(pfile)

if not all_runtimes_ms:
    raise RuntimeError(f"No runtimes found for dataset {dataset}")
if not all_llc_rates:
    raise RuntimeError(f"No LLC miss rates found for dataset {dataset}")

# ============================================================
# Compute statistics
# ============================================================

avg_runtime_ms = mean(all_runtimes_ms)
total_runtime_seconds = sum(all_runtimes_ms) / 1000.0

inst_exec_rate_gips = (total_instructions / total_runtime_seconds) / 1e9
lock_load_rate_ms    = (total_lock_loads / total_runtime_seconds) / 1e6

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
            "InstructionExecRate(GIPS)",
            "LockLoadExecRate(Mlock/s)"
        ])

    writer.writerow([
        dataset,
        f"{avg_runtime_ms:.2f}",
        f"{avg_llc_rate:.2f}",
        f"{inst_exec_rate_gips:.2f}",
        f"{lock_load_rate_ms:.2f}",
    ])

print(
    f"[OK] {dataset}: "
    f"avg_runtime={avg_runtime_ms:.2f} ms, "
    f"LLC miss rate={avg_llc_rate:.2f} %, "
    f"InstrRate={inst_exec_rate_gips:.2f} GIPS, "
    f"LockLoadRate={lock_load_rate_ms:.2f} Mlock/s"
)
