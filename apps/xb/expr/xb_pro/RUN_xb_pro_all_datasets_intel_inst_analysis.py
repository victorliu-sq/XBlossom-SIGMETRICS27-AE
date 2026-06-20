#!/usr/bin/env python3
import sys
import csv
import os
import re

# ============================================================
# Extract XB-Pro average runtime (in SECONDS)
# ============================================================

def extract_avg_runtime_seconds(timing_file):
    """
    Extract 'Average runtime: X.XXXX' from XB-Pro timing output.
    XB-Pro reports runtime in seconds.
    """
    with open(timing_file) as f:
        for line in f:       # <-- FIXED
            m = re.search(r"Average runtime:\s*([0-9.]+)", line)
            if m:
                return float(m.group(1))
    raise RuntimeError(f"No 'Average runtime' found in {timing_file}")


# ============================================================
# Extract LLC miss rate (%)
# ============================================================

def extract_llc_miss_rate(prof_file):
    with open(prof_file) as f:
        for line in f:       # <-- FIXED
            if "LLC-load-misses" in line:
                parts = line.strip().split(',')
                try:
                    return float(parts[5])
                except:
                    pass
    raise RuntimeError(f"No LLC miss rate found in {prof_file}")


# ============================================================
# Extract total instructions (core + atom + generic)
# ============================================================

def extract_total_instructions(prof_file):
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


# ============================================================
# NEW: Extract raw LLC-load-misses count
# ============================================================

def extract_llc_load_misses(prof_file):
    """
    Extract integer count from the LLC-load-misses counter.
    Format example:
      1504578,,cpu_core/LLC-load-misses/,25525428922,...
      parts[0] = miss count
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

if len(sys.argv) != 5:
    print("Usage: RUN_xb_pro_all_datasets_intel_inst_analysis.py "
          "<dataset> <timing_file> <prof_file> <summary_csv>")
    sys.exit(1)

dataset     = sys.argv[1]
timing_file = sys.argv[2]
prof_file   = sys.argv[3]
summary_csv = sys.argv[4]

# Extract metrics
avg_runtime_s      = extract_avg_runtime_seconds(timing_file)
llc_rate           = extract_llc_miss_rate(prof_file)
total_instructions = extract_total_instructions(prof_file)
total_llc_misses   = extract_llc_load_misses(prof_file)

# XB-Pro executed ROUNDS=10 runs → total runtime
total_runtime_s = avg_runtime_s * 10

# Compute derived metrics
inst_exec_rate_gips = (total_instructions / total_runtime_s) / 1e9
data_load_rate_gbps = (total_llc_misses * 64) / total_runtime_s / 1e9  # GB/s

# ============================================================
# Write to summary CSV
# ============================================================

write_header = not os.path.exists(summary_csv)

with open(summary_csv, "a", newline="") as f:
    writer = csv.writer(f)
    if write_header:
        writer.writerow([
            "Dataset",
            "AvgRuntime(s)",
            "LLCMissRate(%)",
            "InstructionExecRate(GIPS)",
            "DataLoadRate(GBps)"
        ])

    writer.writerow([
        dataset,
        f"{avg_runtime_s:.6f}",
        f"{llc_rate:.4f}",
        f"{inst_exec_rate_gips:.4f}",
        f"{data_load_rate_gbps:.4f}",
    ])

print(
    f"[OK] {dataset}: "
    f"runtime={avg_runtime_s:.6f}s, "
    f"LLC={llc_rate:.4f}%, "
    f"GIPS={inst_exec_rate_gips:.4f}, "
    f"LoadRate={data_load_rate_gbps:.4f} GB/s"
)