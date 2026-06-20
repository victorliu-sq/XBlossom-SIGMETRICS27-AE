#!/usr/bin/env python3
import sys, csv, os, re
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[1]))
from experiment_ci import append_sample, rewrite_summary_from_samples

# ============================================================
# Usage
# ============================================================
if len(sys.argv) != 5:
    print("Usage: analyze_gunrock_mem.py <dataset> <timing_file> <profiling_file_or_dir> <summary_out>")
    sys.exit(1)

dataset          = sys.argv[1]
timing_file      = sys.argv[2]
profiling_file_1 = sys.argv[3]   # DRAM bytes
# profiling_file_2 = sys.argv[3]   # Instructions
summary_out      = sys.argv[4]

# ============================================================
# Helper: sum "Metric Value" from Nsight CSV
# ============================================================
def aggregate_metric(filename):
    total = 0
    header = None
    with open(filename, newline='') as f:
        for line in f:
            if line.startswith('"ID","Process ID"') or line.startswith("ID,Process ID"):
                header = [h.strip('"') for h in line.strip().split(",")]
                break
        if not header:
            print(f"[Warning] Could not find Nsight header in {filename}")
            return 0

        reader = csv.DictReader(f, fieldnames=header)
        for row in reader:
            val_str = row.get("Metric Value", "0").replace(",", "").replace('"', "")
            try:
                total += int(val_str)
            except ValueError:
                continue
    return total


def profile_files(path):
    profile_path = Path(path)
    if profile_path.is_dir():
        return sorted(profile_path.glob("*.csv"))
    return [profile_path]

# ============================================================
# Parse runtimes (seconds)
# ============================================================
runtimes = []
with open(timing_file) as f:
    for line in f:
        if "GPU Elapsed Time" in line:
            match = re.search(r"([0-9.]+)\s*\(ms\)", line)
            if match:
                ms_value = float(match.group(1))
                runtimes.append(ms_value / 1e3)

if not runtimes:
    raise RuntimeError(f"No GPU elapsed time found in {timing_file}")

profiles = profile_files(profiling_file_1)
if not profiles:
    raise RuntimeError(f"No profiling files found in {profiling_file_1}")
if len(runtimes) < len(profiles):
    raise RuntimeError(
        f"Not enough GPU elapsed times in {timing_file}: {len(runtimes)} for {len(profiles)} profiling files"
    )

# ============================================================
# Aggregate metrics
# ============================================================
sample_rates = []
for idx, profile in enumerate(profiles):
    runtime_s = runtimes[idx]
    if runtime_s <= 0:
        continue
    total_bytes = aggregate_metric(profile)
    sample_rates.append(total_bytes / runtime_s / 1e9)

# ============================================================
# Write summary CSV
# ============================================================
samples_csv = f"{os.path.splitext(summary_out)[0]}_samples.csv"
for sample_rate in sample_rates:
    append_sample(
        samples_csv,
        ["Dataset", "EffectiveMemoryBandwidth(GB/s)"],
        {"Dataset": dataset, "EffectiveMemoryBandwidth(GB/s)": f"{sample_rate:.9f}"},
    )
rewrite_summary_from_samples(
    samples_csv,
    summary_out,
    "EffectiveMemoryBandwidth(GB/s)",
    "EffectiveMemoryBandwidthCI(GB/s)",
)

# ============================================================
# Print summary
# ============================================================
print(f"📊 {dataset}")
# print(f"  Total DRAM Bytes: {total_bytes_gb:.3f} GB")
# print(f"  Runtime:          {runtime_ms:.3f} ms")
# print(f"  Instruction Rate: {instruction_rate_bips:.3f} GIPS")
if sample_rates:
    print(f"  Effective Memory Bandwidth:   {sum(sample_rates) / len(sample_rates):.3f} GB/s\n")
