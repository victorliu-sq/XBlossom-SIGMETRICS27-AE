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
            if "LLC-load-misses" in line or "mem_load_retired.l3_miss" in line:
                parts = line.strip().split(',')
                try:
                    return int(parts[0])
                except:
                    return 0
    return 0


def extract_llc_miss_rate(prof_file):
    """
    Extract LLC miss rate from perf stat output.
    Input line example:
    363672,,cpu_core/LLC-load-misses/,4500178972,100.00,4.19,of all LL-cache accesses
                                                ^^^^^^^ miss rate (%)
    """
    l3_miss = None
    l3_hit = None
    with open(prof_file) as f:
        for line in f:
            if "LLC-load-misses" in line:
                parts = line.strip().split(',')
                try:
                    miss_rate = float(parts[5])  # Column with miss rate
                    return miss_rate
                except:
                    pass
            if "mem_load_retired.l3_miss" in line:
                parts = line.strip().split(',')
                try:
                    l3_miss = int(parts[0])
                except:
                    pass
            if "mem_load_retired.l3_hit" in line:
                parts = line.strip().split(',')
                try:
                    l3_hit = int(parts[0])
                except:
                    pass
    if l3_miss is not None and l3_hit is not None and (l3_miss + l3_hit) > 0:
        return 100.0 * l3_miss / (l3_miss + l3_hit)
    return None

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

all_llc_rates = []
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

# ---- Extract LLC Miss Rate ----
for pfile in prof_files:
    miss_rate = extract_llc_miss_rate(pfile)
    if miss_rate is not None:
        all_llc_rates.append(miss_rate)

if not all_llc_rates:
    raise RuntimeError(f"No LLC miss rates found for dataset {dataset}")

# ============================================================
# Compute final statistics
# ============================================================

avg_runtime_ms = mean(all_runtimes_ms)
avg_runtime_s = avg_runtime_ms / 1000.0
total_runtime_seconds = sum(all_runtimes_ms) / 1000.0
num_rounds = len(all_runtimes_ms)

avg_llc_rate = mean(all_llc_rates)

# Instruction exec rate (GIPS)
inst_exec_rate_gips = (total_instructions / total_runtime_seconds) / 1e9

# Average LLC misses per round
avg_llc_misses_per_round = total_llc_misses / num_rounds

# LLC Miss Frequency (GMiss/s)
llc_miss_freq = total_llc_misses  / total_runtime_seconds / 1e9

# ============================================================
# Write summary CSV
# ============================================================

write_header = not os.path.exists(summary_csv)

with open(summary_csv, "a", newline="") as f:
    writer = csv.writer(f)
    if write_header:
        writer.writerow([
            "Dataset",
            # "AvgRuntime(s)",
            # "AvgLLCMissesPerRound",
            # "InstructionExecRate(GIPS)",
            "AvgLLCMissRate(%)",
            "LLCMissFreq(GMiss/s)",
        ])

    writer.writerow([
        dataset,
        # f"{avg_runtime_s:.4f}",
        # f"{avg_llc_misses_per_round:.4f}",
        # f"{inst_exec_rate_gips:.4f}",
        f"{avg_llc_rate:.4f}",
        f"{llc_miss_freq:.4f}",
    ])

print(
    f"[OK] {dataset}: "
    # f"avg_runtime={avg_runtime_s:.4f} ms, "
    # f"LLC_misses/round={avg_llc_misses_per_round:.4f}, "
    # f"InstRate={inst_exec_rate_gips:.4f} GIPS, "
    f"LLCMissRate={avg_llc_rate:.4f} %",
    f"LoadRate={llc_miss_freq:.4f} GB/s",
)
