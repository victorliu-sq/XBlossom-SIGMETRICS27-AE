#!/usr/bin/env python3
import sys
import csv
import os
import re
from statistics import mean
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[1]))
from experiment_ci import append_sample, confidence_interval_95, read_grouped_samples

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

sample_rows = []
for idx, (tfile, pfile) in enumerate(zip(timing_files, prof_files), start=1):
    runtimes_ms = extract_runtimes_ms(tfile)
    if not runtimes_ms:
        continue
    runtime_s = sum(runtimes_ms) / 1000.0
    llc_misses = extract_llc_load_misses(pfile)
    llc_rate = extract_llc_miss_rate(pfile)
    if llc_rate is None:
        continue
    sample_rows.append({
        "Iteration": idx,
        "Runtime(s)": runtime_s,
        "LLCMissRate(%)": llc_rate,
        "LLCMissFreq(GMiss/s)": llc_misses / runtime_s / 1e9 if runtime_s > 0 else 0.0,
    })

all_runtimes_ms = []
for tfile in timing_files:
    all_runtimes_ms.extend(extract_runtimes_ms(tfile))

if not all_runtimes_ms:
    raise RuntimeError(f"No runtimes found for dataset {dataset}")
if not sample_rows:
    raise RuntimeError(f"No LLC miss rates found for dataset {dataset}")

# ============================================================
# Compute final statistics
# ============================================================

rates = [row["LLCMissRate(%)"] for row in sample_rows]
freqs = [row["LLCMissFreq(GMiss/s)"] for row in sample_rows]
avg_llc_rate, llc_rate_ci = confidence_interval_95(rates)
llc_miss_freq, llc_miss_freq_ci = confidence_interval_95(freqs)

# ============================================================
# Write summary CSV
# ============================================================

samples_csv = f"{os.path.splitext(summary_csv)[0]}_samples.csv"
for row in sample_rows:
    append_sample(
        samples_csv,
        ["Dataset", "Iteration", "Runtime(s)", "LLCMissRate(%)", "LLCMissFreq(GMiss/s)"],
        {
            "Dataset": dataset,
            "Iteration": row["Iteration"],
            "Runtime(s)": f"{row['Runtime(s)']:.9f}",
            "LLCMissRate(%)": f"{row['LLCMissRate(%)']:.9f}",
            "LLCMissFreq(GMiss/s)": f"{row['LLCMissFreq(GMiss/s)']:.9f}",
        },
    )

rate_groups = read_grouped_samples(samples_csv, value_col="LLCMissRate(%)")
freq_groups = read_grouped_samples(samples_csv, value_col="LLCMissFreq(GMiss/s)")
with open(summary_csv, "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow([
        "Dataset",
        "AvgLLCMissRate(%)",
        "LLCMissRateCI(%)",
        "LLCMissFreq(GMiss/s)",
        "LLCMissFreqCI(GMiss/s)",
        "Samples",
    ])
    for sample_dataset, rate_values in rate_groups.items():
        rate_mean, rate_ci = confidence_interval_95(rate_values)
        freq_mean, freq_ci = confidence_interval_95(freq_groups.get(sample_dataset, []))
        writer.writerow([
            sample_dataset,
            f"{rate_mean:.6f}",
            f"{rate_ci:.6f}",
            f"{freq_mean:.6f}",
            f"{freq_ci:.6f}",
            len(rate_values),
        ])

print(
    f"[OK] {dataset}: "
    f"LLCMissRate={avg_llc_rate:.4f} %",
    f"LLCMissFreq={llc_miss_freq:.4f} GMiss/s",
)
