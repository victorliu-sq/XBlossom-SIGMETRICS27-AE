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
    Extract LLC miss rate from perf stat output.
    Input line example:
    363672,,cpu_core/LLC-load-misses/,4500178972,100.00,4.19,of all LL-cache accesses
                                                ^^^^^^^ miss rate (%)
    """
    with open(prof_file) as f:
        for line in f:
            if "LLC-load-misses" in line:
                parts = line.strip().split(',')
                try:
                    miss_rate = float(parts[5])  # Column with miss rate
                    return miss_rate
                except:
                    pass
    return None


# ============================================================
# Main
# ============================================================

if len(sys.argv) != 4:
    print("Usage: analyze_ligra_profile_rand_src.py <dataset> <metrics_dir> <summary_csv>")
    sys.exit(1)

dataset = sys.argv[1]
metrics_dir = sys.argv[2]
summary_csv = sys.argv[3]

# All files: ligra_<dataset>_srcXXX_timing.txt
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

all_runtimes = []
all_llc_rates = []

for tfile in timing_files:
    runtimes = extract_runtimes_ms(tfile)
    if runtimes:
        all_runtimes.extend(runtimes)

for pfile in prof_files:
    miss_rate = extract_llc_miss_rate(pfile)
    if miss_rate is not None:
        all_llc_rates.append(miss_rate)

if not all_runtimes:
    raise RuntimeError(f"No runtimes found for dataset {dataset}")

if not all_llc_rates:
    raise RuntimeError(f"No LLC miss rates found for dataset {dataset}")

avg_runtime = mean(all_runtimes)
avg_llc_rate = mean(all_llc_rates)

# Append a summary row
write_header = not os.path.exists(summary_csv)

with open(summary_csv, "a", newline="") as f:
    writer = csv.writer(f)
    if write_header:
        writer.writerow(["Dataset", "AvgRuntime(ms)", "AvgLLCMissRate(%)"])

    writer.writerow([
        dataset,
        f"{avg_runtime:.2f}",
        f"{avg_llc_rate:.2f}",
    ])

print(f"[OK] Dataset={dataset}: avg_runtime={avg_runtime:.4f} ms, avg_llc_miss_rate={avg_llc_rate:.4f}%")
