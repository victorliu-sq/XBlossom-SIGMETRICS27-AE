#!/usr/bin/env python3
import sys, csv, os, re
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[1]))
from experiment_ci import append_sample, confidence_interval_95

# ============================================================
# Usage
# ============================================================
if len(sys.argv) != 4:
    print("Usage: gunrock_bfs_profile_analyzer_indep.py <dataset> <timing_file> <profiling_file_1> <profiling_file_2> <summary_out>")
    sys.exit(1)

dataset          = sys.argv[1]
timing_file      = sys.argv[2]
# profiling_file_1 = sys.argv[3]   # DRAM bytes
# profiling_file_2 = sys.argv[4]   # Instructions
summary_out      = sys.argv[3]

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

# ============================================================
# Parse runtimes (seconds)
# ============================================================
runtimes = []
with open(timing_file) as f:
    for line in f:
        if "GPU Elapsed Time" in line:
            match = re.search(r"([0-9.eE+-]+)\s*\(ms\)", line)
            if match:
                runtimes.append(float(match.group(1)) / 1e3)

if not runtimes:
    raise RuntimeError(f"No GPU elapsed times found in {timing_file}")

runtime, runtime_ci = confidence_interval_95(runtimes)

samples_out = f"{os.path.splitext(summary_out)[0]}_samples.csv"
for idx, sample in enumerate(runtimes, start=1):
    append_sample(
        samples_out,
        ["Dataset", "Round", "Runtime(s)"],
        {"Dataset": dataset, "Round": idx, "Runtime(s)": f"{sample:.9f}"},
    )

# runtime_ms = runtime * 1000.0

# ============================================================
# Aggregate metrics
# ============================================================
# total_bytes = aggregate_metric(profiling_file_1)
# total_insts = aggregate_metric(profiling_file_2)

# total_bytes_gb = total_bytes / 1e9

# ============================================================
# Compute rates
# ============================================================
# instruction_rate_bips = total_insts / runtime / 1e9
# data_load_rate_gbps   = total_bytes / runtime / 1e9

# ============================================================
# Write summary CSV
# ============================================================
os.makedirs(os.path.dirname(summary_out), exist_ok=True)
write_header = not os.path.exists(summary_out)

with open(summary_out, "a", newline="") as csvfile:
    writer = csv.writer(csvfile)
    if write_header:
        writer.writerow([
            "Dataset",
            # "TotalDRAMReadGB",
            "Runtime(s)",
            "RuntimeCI(s)",
            "Samples",
            # "InstructionRate(BIPS)",
            # "DataLoadRate(GB/s)"
        ])
    writer.writerow([
        dataset,
        # f"{total_bytes_gb:.3f}",
        f"{runtime:.6f}",
        f"{runtime_ci:.6f}",
        len(runtimes),
        # f"{instruction_rate_bips:.3f}",
        # f"{data_load_rate_gbps:.3f}"
    ])

# ============================================================
# Print summary
# ============================================================
print(f"📊 {dataset}")
# print(f"  Total DRAM Bytes: {total_bytes_gb:.3f} GB")
print(f"  Runtime:          {runtime:.6f} s")
print(f"  Runtime CI:       {runtime_ci:.6f} s")
print(f"  Samples:          {len(runtimes)}")
# print(f"  Instruction Rate: {instruction_rate_bips:.3f} BIPS")
# print(f"  Data Load Rate:   {data_load_rate_gbps:.3f} GB/s\n")
