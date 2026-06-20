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
    Expects perf stat -x, CSV-like lines.
    """
    total = 0
    with open(prof_file) as f:
        for line in f:
            if "instructions" in line:
                parts = line.strip().split(',')
                try:
                    total += int(parts[0])
                except Exception:
                    # Skip lines where the value is not an integer
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
                except Exception:
                    return 0
    return 0


def extract_total_cycles(prof_file):
    """
    Sum all 'cpu_core/cycles/' counters.
    This matches the event name you used in perf:
        -e cpu_core/cycles/
    """
    total = 0
    with open(prof_file) as f:
        for line in f:
            if "cpu_core/cycles/" in line:
                parts = line.strip().split(',')
                try:
                    total += int(parts[0])
                except Exception:
                    pass
    return total


def extract_l3_stall_cycles(prof_file):
    """
    Sum all 'cycle_activity.stalls_l3_miss' counters.
    This matches the event name you used in perf:
        -e cycle_activity.stalls_l3_miss
    """
    total = 0
    with open(prof_file) as f:
        for line in f:
            if "cycle_activity.stalls_l3_miss" in line:
                parts = line.strip().split(',')
                try:
                    total += int(parts[0])
                except Exception:
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
total_cycles = 0
total_l3_stall_cycles = 0

# ---- Extract runtimes ----
for tfile in timing_files:
    r = extract_runtimes_ms(tfile)
    if r:
        all_runtimes_ms.extend(r)

# ---- Extract instruction counts, LLC misses, cycles, L3-stall cycles ----
for pfile in prof_files:
    total_instructions += extract_total_instructions(pfile)
    total_llc_misses += extract_llc_load_misses(pfile)
    total_cycles += extract_total_cycles(pfile)
    total_l3_stall_cycles += extract_l3_stall_cycles(pfile)

if not all_runtimes_ms:
    raise RuntimeError(f"No runtimes found for dataset {dataset}")

# ============================================================
# Compute final statistics
# ============================================================

avg_runtime_ms = mean(all_runtimes_ms)
total_runtime_seconds = sum(all_runtimes_ms) / 1000.0
num_rounds = len(all_runtimes_ms)

# Instruction exec rate (GIPS)
inst_exec_rate_gips = (total_instructions / total_runtime_seconds) / 1e9

# Average LLC misses per round
avg_llc_misses_per_round = total_llc_misses / num_rounds

# Data load rate (GB/s), assuming 64-byte cache line
data_load_rate_gbps = (total_llc_misses * 64) / total_runtime_seconds / 1e9

# L3 stall cycle ratio
if total_cycles > 0:
    l3_stall_cycle_ratio = total_l3_stall_cycles / total_cycles
else:
    l3_stall_cycle_ratio = 0.0

# ============================================================
# Write summary CSV
# ============================================================

write_header = not os.path.exists(summary_csv)

with open(summary_csv, "a", newline="") as f:
    writer = csv.writer(f)
    if write_header:
        writer.writerow([
            "Dataset",
            "AvgRuntime(ms)",
            "AvgLLCMissesPerRound",
            "InstructionExecRate(GIPS)",
            "DataLoadRate(GBps)",
            "TotalCycles",
            "L3StallCyclesRatio"
        ])

    writer.writerow([
        dataset,
        f"{avg_runtime_ms:.4f}",
        f"{avg_llc_misses_per_round:.4f}",
        f"{inst_exec_rate_gips:.4f}",
        f"{data_load_rate_gbps:.4f}",
        str(total_cycles),
        f"{l3_stall_cycle_ratio:.6f}",
    ])

print(
    f"[OK] {dataset}: "
    f"avg_runtime={avg_runtime_ms:.4f} ms, "
    f"LLC_misses/round={avg_llc_misses_per_round:.4f}, "
    f"InstRate={inst_exec_rate_gips:.4f} GIPS, "
    f"LoadRate={data_load_rate_gbps:.4f} GB/s, "
    f"TotalCycles={total_cycles}, "
    f"L3StallRatio={l3_stall_cycle_ratio:.6f}"
)
