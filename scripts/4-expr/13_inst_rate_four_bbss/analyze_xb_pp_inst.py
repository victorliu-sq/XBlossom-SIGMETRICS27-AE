#!/usr/bin/env python3
import sys, csv, os, re
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[1]))
from experiment_ci import (
    append_sample,
    extract_average_runtime_seconds,
    extract_round_runtimes_seconds,
    grouped_runtime_sums,
    rewrite_summary_from_samples,
)

# ============================================================
# Usage
# ============================================================
if len(sys.argv) not in (5, 6, 7):
    print("Usage: xb_pp_profile_analyzer.py <dataset> <timing_file> <profiling_file_2> <summary_out> [rounds] [profile_rounds]")
    sys.exit(1)

dataset          = sys.argv[1]
timing_file      = sys.argv[2]
# profiling_file_1 = sys.argv[3]   # DRAM bytes
profiling_file_2 = sys.argv[3]   # Instructions
summary_out      = sys.argv[4]
rounds           = int(sys.argv[5]) if len(sys.argv) >= 6 else 1
profile_rounds   = int(sys.argv[6]) if len(sys.argv) == 7 else rounds

# ============================================================
# Helper: sum "Metric Value" from Nsight CSV
# ============================================================
def aggregate_metric(filename):
    total = 0
    header = None
    with open(filename, newline='') as f:
        # Seek Nsight header
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
# Parse runtime (seconds)
# ============================================================
runtime = extract_average_runtime_seconds(timing_file) * rounds
round_runtimes = extract_round_runtimes_seconds(timing_file)
profiles = profile_files(profiling_file_2)
if not profiles:
    raise RuntimeError(f"No profiling files found in {profiling_file_2}")

# ============================================================
# Aggregate metrics
# ============================================================
# total_bytes = aggregate_metric(profiling_file_1)  # raw dram bytes
if len(profiles) == 1:
    total_insts = aggregate_metric(profiles[0]) * (rounds / profile_rounds)
else:
    total_insts = sum(aggregate_metric(profile) for profile in profiles)

# total_bytes_gb = total_bytes / 1e9

# ============================================================
# Compute rates
# ============================================================
instruction_rate_bips = total_insts / runtime / 1e9  # Billion inst per sec
# data_load_rate_gbps   = total_bytes / runtime / 1e9  # GB/s

# ============================================================
# Write summary CSV
# ============================================================
samples_csv = f"{os.path.splitext(summary_out)[0]}_samples.csv"
runtime_groups = grouped_runtime_sums(round_runtimes, groups=20)
if len(profiles) > 1 and runtime_groups:
    if len(runtime_groups) < len(profiles):
        raise RuntimeError(
            f"Not enough runtime groups in {timing_file}: {len(runtime_groups)} for {len(profiles)} profiling files"
        )
    group_rounds = rounds / len(runtime_groups)
    for profile, runtime_group_s in zip(profiles, runtime_groups):
        group_insts = aggregate_metric(profile) * (group_rounds / profile_rounds)
        append_sample(
            samples_csv,
            ["Dataset", "InstructionRate(GIPS)"],
            {"Dataset": dataset, "InstructionRate(GIPS)": f"{group_insts / runtime_group_s / 1e9:.9f}"},
        )
elif runtime_groups:
    instructions_per_group = total_insts / len(runtime_groups)
    for runtime_group_s in runtime_groups:
        append_sample(
            samples_csv,
            ["Dataset", "InstructionRate(GIPS)"],
            {"Dataset": dataset, "InstructionRate(GIPS)": f"{instructions_per_group / runtime_group_s / 1e9:.9f}"},
        )
else:
    append_sample(
        samples_csv,
        ["Dataset", "InstructionRate(GIPS)"],
        {"Dataset": dataset, "InstructionRate(GIPS)": f"{instruction_rate_bips:.9f}"},
    )
rewrite_summary_from_samples(
    samples_csv,
    summary_out,
    "InstructionRate(GIPS)",
    "InstructionRateCI(GIPS)",
)

# ============================================================
# Print summary
# ============================================================
print(f"📊 {dataset}")
# print(f"  Total DRAM Bytes: {total_bytes_gb:.3f} GB")
# print(f"  Runtime:          {runtime_ms:.3f} ms")
print(f"  Instruction Rate: {instruction_rate_bips:.3f} GIPS")
# print(f"  Data Load Rate:   {data_load_rate_gbps:.3f} GB/s\n")
