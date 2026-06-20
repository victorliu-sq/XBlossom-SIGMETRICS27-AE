#!/usr/bin/env python3
import sys
import csv
import os
import re
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[1]))
from experiment_ci import (
    append_sample,
    confidence_interval_95,
    extract_round_runtimes_seconds,
)

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
round_runtimes_s   = extract_round_runtimes_seconds(timing_file)
total_instructions = extract_total_instructions(prof_file)
total_llc_misses   = extract_llc_load_misses(prof_file)

# Total runtime = avg time per round * number of rounds
total_runtime_s = avg_runtime_s * rounds

# Derived metrics
inst_exec_rate_gips = (total_instructions / total_runtime_s) / 1e9
avg_llc_misses_per_round = total_llc_misses / rounds
data_load_rate_gbps = (total_llc_misses * 64) / total_runtime_s / 1e9  # GB/s

samples_csv = f"{os.path.splitext(summary_csv)[0]}_samples.csv"
for idx, runtime_s in enumerate(round_runtimes_s, start=1):
    append_sample(
        samples_csv,
        ["Dataset", "Round", "AvgRuntime(s)"],
        {"Dataset": dataset, "Round": idx, "AvgRuntime(s)": f"{runtime_s:.9f}"},
    )

ci_runtime_s = 0.0
if round_runtimes_s:
    avg_runtime_s, ci_runtime_s = confidence_interval_95(round_runtimes_s)

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
            "AvgRuntime(s)",
            "AvgRuntimeCI(s)",
            # "AvgLLCMissesPerRound",
            # "InstructionExecRate(GIPS)",
            # "DataLoadRate(GBps)"
        ])

    writer.writerow([
        dataset,
        # rounds,
        f"{avg_runtime_s:.6f}",
        f"{ci_runtime_s:.6f}",
        # f"{avg_llc_misses_per_round:.4f}",
        # f"{inst_exec_rate_gips:.4f}",
        # f"{data_load_rate_gbps:.4f}",
    ])

print(
    f"[OK] {dataset}: "
    # f"rounds={rounds}, "
    f"runtime={avg_runtime_s:.6f}s, "
    # f"LLC_misses/round={avg_llc_misses_per_round:.4f}, "
    # f"GIPS={inst_exec_rate_gips:.4f}, "
    # f"LoadRate={data_load_rate_gbps:.4f} GB/s"
)
