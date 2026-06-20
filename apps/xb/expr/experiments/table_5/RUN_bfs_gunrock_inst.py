#!/usr/bin/env python3
import sys, csv, os, re

# ============================================================
# Usage
# ============================================================
if len(sys.argv) != 5:
    print("Usage: gunrock_bfs_profile_analyzer_indep.py <dataset> <timing_file> <profiling_file_1> <profiling_file_2> <summary_out>")
    sys.exit(1)

dataset          = sys.argv[1]
timing_file      = sys.argv[2]
# profiling_file_1 = sys.argv[3]   # DRAM bytes
profiling_file_2 = sys.argv[3]   # Instructions
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

# ============================================================
# Parse runtime (seconds)
# ============================================================
runtime = 0.0
with open(timing_file) as f:
    for line in f:
        if "GPU Elapsed Time" in line:
            match = re.search(r"([0-9.]+)\s*\(ms\)", line)
            if match:
                ms_value = float(match.group(1))
                runtime = ms_value / 1e3
            break

runtime_ms = runtime * 1000.0

# ============================================================
# Aggregate metrics
# ============================================================
# total_bytes = aggregate_metric(profiling_file_1)
total_insts = aggregate_metric(profiling_file_2)

# total_bytes_gb = total_bytes / 1e9

# ============================================================
# Compute rates
# ============================================================
instruction_rate_bips = total_insts / runtime / 1e9
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
            # "Runtime(ms)",
            "InstructionRate(GIPS)",
            # "DataLoadRate(GB/s)"
        ])
    writer.writerow([
        dataset,
        # f"{total_bytes_gb:.3f}",
        # f"{runtime_ms:.3f}",
        f"{instruction_rate_bips:.3f}",
        # f"{data_load_rate_gbps:.3f}"
    ])

# ============================================================
# Print summary
# ============================================================
print(f"📊 {dataset}")
# print(f"  Total DRAM Bytes: {total_bytes_gb:.3f} GB")
# print(f"  Runtime:          {runtime_ms:.3f} ms")
print(f"  Instruction Rate: {instruction_rate_bips:.3f} GIPS")
# print(f"  Data Load Rate:   {data_load_rate_gbps:.3f} GB/s\n")
