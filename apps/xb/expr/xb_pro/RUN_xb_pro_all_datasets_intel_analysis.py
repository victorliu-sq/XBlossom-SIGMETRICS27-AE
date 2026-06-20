#!/usr/bin/env python3
import sys
import csv
import os
import re

# ============================================================
# Extract XB-Pro average runtime (in seconds)
# ============================================================

def extract_avg_runtime_seconds(timing_file):
    """
    Extract "Average runtime: X.XXXX" from timing output.
    XB-Pro reports runtime in SECONDS.
    """
    with open(timing_file) as f:
        for line in f:
            m = re.search(r"Average runtime:\s*([0-9.]+)", line)
            if m:
                return float(m.group(1))  # seconds
    raise RuntimeError(f"No 'Average runtime' found in {timing_file}")


# ============================================================
# Extract LLC miss rate (%) from perf stat
# ============================================================

def extract_llc_miss_rate(prof_file):
    """
    Extract LLC miss rate (%) from perf stat output.
    Expected format:
    363672,,cpu_core/LLC-load-misses/,4500178972,100.00,4.19,...
                                                    ^ miss rate
    """
    with open(prof_file) as f:
        for line in f:
            if "LLC-load-misses" in line:
                parts = line.strip().split(',')
                try:
                    return float(parts[5])  # percent miss rate
                except:
                    pass
    raise RuntimeError(f"No LLC miss rate found in {prof_file}")


# ============================================================
# Main
# ============================================================

if len(sys.argv) != 5:
    print("Usage: analyze_xb_pro_profile_simple.py <dataset> <timing_file> <prof_file> <summary_csv>")
    sys.exit(1)

dataset     = sys.argv[1]
timing_file = sys.argv[2]
prof_file   = sys.argv[3]
summary_csv = sys.argv[4]

avg_runtime_s = extract_avg_runtime_seconds(timing_file)
llc_rate      = extract_llc_miss_rate(prof_file)

# Append to summary CSV
write_header = not os.path.exists(summary_csv)

with open(summary_csv, "a", newline="") as f:
    writer = csv.writer(f)
    if write_header:
        writer.writerow(["Dataset", "AvgRuntime(s)", "LLCMissRate(%)"])

    writer.writerow([
        dataset,
        f"{avg_runtime_s:.6f}",
        f"{llc_rate:.4f}",
    ])

print(f"[OK] {dataset}: avg_runtime={avg_runtime_s:.6f} s, llc_rate={llc_rate:.4f}% → {summary_csv}")
