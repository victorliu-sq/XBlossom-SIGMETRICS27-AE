#!/usr/bin/env python3
import csv
import sys
import os

if len(sys.argv) != 5:
    print("Usage: python3 analyze_xb_pp_metrics.py <dataset_name> <timing_file> <profiling_file> <summary_out>")
    sys.exit(1)

dataset_name = sys.argv[1]
timing_file = sys.argv[2]
profiling_file = sys.argv[3]
summary_out = sys.argv[4]

# ------------------------------------------------------------
# 1. Parse total runtime (in seconds)
# ------------------------------------------------------------
runtime = 0.0
with open(timing_file) as f:
    for line in f:
        if "Total Time" in line:
            try:
                runtime = float(line.split(":")[1].strip())
            except ValueError:
                pass
            break

if runtime == 0.0:
    print(f"[Warning] Could not find valid runtime in {timing_file}")
    sys.exit(1)

# ------------------------------------------------------------
# 2. Aggregate metrics from the Nsight Compute CSV
# ------------------------------------------------------------
total_bytes = 0
total_insts = 0
header_found = False

# with open(profiling_file, newline='') as f:
#     for line in f:
#         if not header_found and line.startswith("ID,Process ID"):
#             header_found = True
#             header = [h.strip('"') for h in line.strip().split(",")]
#             reader = csv.DictReader(f, fieldnames=header)
#             for row in reader:
#                 metric = row.get("Metric Name", "").strip('"')
#                 val_str = row.get("Metric Value", "0").replace(",", "").replace('"', "")
#                 try:
#                     val = int(val_str)
#                 except ValueError:
#                     continue
#                 if metric == "dram__bytes_read.sum":
#                     total_bytes += val
#                 elif metric == "sm__sass_thread_inst_executed.sum":
#                     total_insts += val
#             break
#
#             total_bytes = 0
# total_insts = 0
# header = None
#
with open(profiling_file, newline='') as f:
    # Skip everything until we reach the header line
    for line in f:
        if line.startswith('"ID","Process ID"') or line.startswith("ID,Process ID"):
            header = [h.strip('"') for h in line.strip().split(",")]
            break

    reader = csv.DictReader(f, fieldnames=header)
    for row in reader:
        metric = row.get("Metric Name", "").strip('"')
        val_str = row.get("Metric Value", "0").replace(",", "").replace('"', "")
        try:
            val = int(val_str)
        except ValueError:
            continue
        if metric == "dram__bytes_read.sum":
            total_bytes += val
        elif metric == "sm__sass_thread_inst_executed.sum":
            total_insts += val

# ------------------------------------------------------------
# 3. Compute rates
# ------------------------------------------------------------
instruction_rate_bips = total_insts / runtime / 1e9  # billion inst/s
data_load_rate_gbps = total_bytes / runtime / 1e9    # GB/s

# ------------------------------------------------------------
# 4. Write to summary CSV
# ------------------------------------------------------------
header_line = "Dataset,Instruction Rate (BIPS),Data Load Rate (GB/s)\n"
new_line = f"{dataset_name},{instruction_rate_bips:.3f},{data_load_rate_gbps:.3f}\n"

file_exists = os.path.exists(summary_out)
with open(summary_out, "a") as fout:
    if not file_exists:
        fout.write(header_line)
    fout.write(new_line)

print(f"[{dataset_name}] Runtime: {runtime:.6f}s, InstRate: {instruction_rate_bips:.3f} BIPS, DataRate: {data_load_rate_gbps:.3f} GB/s")
