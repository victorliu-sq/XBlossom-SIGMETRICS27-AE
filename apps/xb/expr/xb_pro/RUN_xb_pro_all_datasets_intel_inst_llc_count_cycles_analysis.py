#!/usr/bin/env python3
import sys
import csv
import os
import re

# ============================================================
# Extract XB-Pro average runtime (in SECONDS, per round)
# ============================================================

def extract_avg_runtime_seconds(timing_file):
    """
    Extract 'Average runtime' (in seconds) from timing_file.

    Expected line format (example):
        Average runtime: 0.001234
    """
    with open(timing_file) as f:
        for line in f:
            m = re.search(r"Average runtime:\s*([0-9.]+)", line)
            if m:
                return float(m.group(1))
    raise RuntimeError(f"No 'Average runtime' found in {timing_file}")


# ============================================================
# Extract total instructions
# ============================================================

def extract_total_instructions(prof_file):
    """
    Sum all 'instructions' counters (both cpu_atom and cpu_core),
    ignoring LLC lines just in case.
    Assumes perf stat -x, CSV lines.
    """
    total = 0
    with open(prof_file) as f:
        for line in f:
            if "instructions" in line and "LLC" not in line:
                parts = line.strip().split(',')
                try:
                    total += int(parts[0])
                except Exception:
                    pass
    return total


# ============================================================
# Extract raw LLC-load-misses
# ============================================================

def extract_llc_load_misses(prof_file):
    """
    Extract the *raw* LLC-load-misses count (integer) for cpu_core.
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


# ============================================================
# Extract L3-miss stall cycles (cpu_core)
# ============================================================

def extract_l3_miss_stall_cycles(prof_file):
    """
    Extract the total cycles stalled due to L3 misses on cpu_core:
        cycle_activity.stalls_l3_miss
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
# Extract total core cycles (cpu_core/cycles/)
# ============================================================

def extract_total_cycles(prof_file):
    """
    Sum all cpu_core/cycles/ counters.
    This matches the perf event:
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


# ============================================================
# Main
# ============================================================

if len(sys.argv) != 6:
    print("Usage: RUN_xb_pro_all_datasets_intel_inst_llc_count_analysis.py "
          "<dataset> <timing_file> <prof_file> <summary_csv> <rounds>")
    sys.exit(1)

dataset     = sys.argv[1]
timing_file = sys.argv[2]
prof_file   = sys.argv[3]
summary_csv = sys.argv[4]
rounds      = int(sys.argv[5])

# Extract raw metrics
avg_runtime_s          = extract_avg_runtime_seconds(timing_file)   # per round (s)
total_instructions     = extract_total_instructions(prof_file)
total_llc_misses       = extract_llc_load_misses(prof_file)
total_l3_stall_cycles  = extract_l3_miss_stall_cycles(prof_file)
total_cycles           = extract_total_cycles(prof_file)

# Total runtime = avg time per round * number of rounds
total_runtime_s = avg_runtime_s * rounds if rounds > 0 else 0.0

# Derived metrics (matching the Ligra BFS CSV format)
avg_runtime_ms = avg_runtime_s * 1000.0  # per round, ms

inst_exec_rate_gips = (
    (total_instructions / total_runtime_s) / 1e9
    if total_runtime_s > 0 else 0.0
)

avg_llc_misses_per_round = (
    total_llc_misses / rounds
    if rounds > 0 else 0.0
)

# Data load rate (GB/s), assuming 64-byte cache line
data_load_rate_gbps = (
    (total_llc_misses * 64) / total_runtime_s / 1e9
    if total_runtime_s > 0 else 0.0
)

# L3 stall cycle ratio
if total_cycles > 0:
    l3_stall_cycle_ratio = total_l3_stall_cycles / total_cycles
else:
    l3_stall_cycle_ratio = 0.0

# ============================================================
# Write to summary CSV
#   Same format as Ligra BFS summary:
#   Dataset, AvgRuntime(ms), AvgLLCMissesPerRound,
#   InstructionExecRate(GIPS), DataLoadRate(GBps),
#   TotalCycles, L3StallCyclesRatio
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
            "L3StallCyclesRatio",
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
    f"rounds={rounds}, "
    f"avg_runtime={avg_runtime_ms:.4f} ms, "
    f"LLC_misses/round={avg_llc_misses_per_round:.4f}, "
    f"GIPS={inst_exec_rate_gips:.4f}, "
    f"LoadRate={data_load_rate_gbps:.4f} GB/s, "
    f"TotalCycles={total_cycles}, "
    f"L3StallRatio={l3_stall_cycle_ratio:.6f}"
)
