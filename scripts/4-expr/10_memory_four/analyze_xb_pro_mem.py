#!/usr/bin/env python3
import sys
import csv
import os
import re

# ============================================================
# Extract XB-Pro average runtime (in SECONDS)
# ============================================================

def extract_avg_runtime_seconds(timing_file):
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
# Extract raw LLC-load-misses
# ============================================================

def extract_llc_load_misses(prof_file):
    with open(prof_file) as f:
        for line in f:
            if "LLC-load-misses" in line or "mem_load_retired.l3_miss" in line:
                parts = line.strip().split(',')
                try:
                    return int(parts[0])
                except:
                    return 0
    return 0


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
    l3_miss = None
    l3_hit = None
    with open(prof_file) as f:
        for line in f:
            if "LLC-load-misses" in line:
                parts = line.strip().split(',')
                try:
                    return float(parts[5])  # percent miss rate
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
    raise RuntimeError(f"No LLC miss rate found in {prof_file}")

# ============================================================
# Main
# ============================================================

if len(sys.argv) != 6:
    print("Usage: analyze_xb_pro_all_datasets_intel_inst_llc_count_analysis.py "
          "<dataset> <timing_file> <prof_file> <summary_csv> <rounds>")
    sys.exit(1)

dataset     = sys.argv[1]
timing_file = sys.argv[2]
prof_file   = sys.argv[3]
summary_csv = sys.argv[4]
rounds      = int(sys.argv[5])

# Extract raw metrics
avg_runtime_s      = extract_avg_runtime_seconds(timing_file)
# total_instructions = extract_total_instructions(prof_file)
total_llc_misses   = extract_llc_load_misses(prof_file)
llc_miss_rate      = extract_llc_miss_rate(prof_file)

# Total runtime = avg time per round * number of rounds
total_runtime_s = avg_runtime_s * rounds

# Derived metrics
# inst_exec_rate_gips = (total_instructions / total_runtime_s) / 1e9
avg_llc_misses_per_round = total_llc_misses / rounds
llc_miss_freq = (total_llc_misses) / total_runtime_s / 1e9  # GB/s


# ============================================================
# Write to summary CSV
# ============================================================

write_header = not os.path.exists(summary_csv)

with open(summary_csv, "a", newline="") as f:
    writer = csv.writer(f)
    if write_header:
        writer.writerow([
            "Dataset",
            # "Rounds",
            # "AvgRuntime(s)",
            # "AvgLLCMissesPerRound",
            # "InstructionExecRate(GIPS)",
            "LLCMissRate(%)",
            "LLCMissFreq(GMiss/s)",
        ])

    writer.writerow([
        dataset,
        # rounds,
        # f"{avg_runtime_s:.6f}",
        # f"{avg_llc_misses_per_round:.4f}",
        # f"{inst_exec_rate_gips:.4f}",
        f"{llc_miss_rate:.4f}",
        f"{llc_miss_freq:.4f}",
    ])

print(
    f"[OK] {dataset}: "
    # f"rounds={rounds}, "
    # f"runtime={avg_runtime_s:.6f}s, "
    # f"LLC_misses/round={avg_llc_misses_per_round:.4f}, "
    # f"GIPS={inst_exec_rate_gips:.4f}, "
    f"LLCMissRate={llc_miss_rate:.4f} %"
    f"LLCMissFreq={llc_miss_freq:.4f} GMiss/s"
)
