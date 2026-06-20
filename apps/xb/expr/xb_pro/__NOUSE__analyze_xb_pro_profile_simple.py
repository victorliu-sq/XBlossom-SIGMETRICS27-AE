#!/usr/bin/env python3
import sys
import csv
import re
import os

# ============================================================
# Helper Functions
# ============================================================

def read_val(pattern, filename):
    total = 0
    with open(filename) as f:
        for line in f:
            if re.search(pattern, line):
                parts = line.strip().split(',')
                try:
                    total += int(parts[0])
                except ValueError:
                    continue
    return total


def read_runtime_ms(timing_file):
    """
    Extract runtime from timing file.
    Example line:
      Average runtime: 1.08697
    """
    with open(timing_file) as f:
        for line in f:
            m = re.search(r"Average runtime:\s*([0-9.]+)", line)
            if m:
                sec = float(m.group(1))
                return sec * 1000.0  # → ms
    raise RuntimeError(f"Runtime not found in {timing_file}")


# ============================================================
# Main
# ============================================================

if len(sys.argv) != 5:
    print("Usage: analyze_xb_pro_profile_simple.py <dataset> <profiling_file> <timing_file> <summary_csv>")
    sys.exit(1)

dataset      = sys.argv[1]
profiling    = sys.argv[2]
timing_file  = sys.argv[3]
summary_csv  = sys.argv[4]

# Extract metrics
instructions = read_val(r"instructions", profiling)
l3_misses    = read_val(r"l3_misses", profiling)
runtime_ms   = read_runtime_ms(timing_file)
runtime_sec  = runtime_ms / 1000.0

# Compute performance metrics
instruction_rate_bips = (instructions / runtime_sec) / 1e9
data_load_rate_gb     = (l3_misses * 64 / runtime_sec) / 1e9

# Append to summary CSV
write_header = not os.path.exists(summary_csv)

with open(summary_csv, "a", newline="") as f:
    writer = csv.writer(f)
    if write_header:
        writer.writerow(["Dataset", "Runtime (ms)", "Instruction Rate (BIPS)", "Data Load Rate (GB/s)"])

    writer.writerow([
        dataset,
        f"{runtime_ms:.3f}",
        f"{instruction_rate_bips:.6f}",
        f"{data_load_rate_gb:.6f}",
    ])

print(f"[OK] Added summary for {dataset} → {summary_csv}")
