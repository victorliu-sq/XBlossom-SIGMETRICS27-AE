#!/usr/bin/env python3
import sys, csv, os, re

if len(sys.argv) != 6:
    print("Usage: gunrock_bfs_profile_analyzer_indep.py <dataset> <timing_file> <profiling_file_1> <profiling_file_2> <summary_out>")
    print("Example: python3 gunrock_bfs_profile_analyzer_indep.py Amazon xb_pp_timing_Amazon.txt xb_pp_profile_Amazon_1.csv xb_pp_profile_Amazon_2.csv _xb_pp_summary_Amazon.csv")
    sys.exit(1)

dataset = sys.argv[1]
timing_file = sys.argv[2]
profiling_file_1 = sys.argv[3]
profiling_file_2 = sys.argv[4]
summary_out = sys.argv[5] if len(sys.argv) > 5 else os.path.join(os.path.dirname(profiling_file_1), "_xb_pp_summary.csv")

# ------------------------------------------------------------
# 1. Helper: aggregate a metric value from Nsight CSV
# ------------------------------------------------------------
def aggregate_metric(filename):
    total = 0
    header = None
    with open(filename, newline='') as f:
        # Skip lines until we find the Nsight header
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
                val = int(val_str)
                total += val
            except ValueError:
                continue
    return total

# ------------------------------------------------------------
# 2. Parse runtime (seconds)
# ------------------------------------------------------------
runtime = 0.0
with open(timing_file) as f:
    for line in f:
        # Match the new output line
        if "GPU Elapsed Time" in line:
            match = re.search(r"([0-9.]+)\s*\(ms\)", line)
            if match:
                try:
                    ms_value = float(match.group(1))
                    runtime = ms_value / 1e3  # convert ms → s
                    print(f"[Info] Parsed GPU elapsed time: {ms_value:.4f} ms ({runtime:.6f} s)")
                except ValueError:
                    pass
            break

runtime_ms = runtime * 1000.0  # convert seconds → milliseconds

# ------------------------------------------------------------
# 3. Aggregate metric totals
# ------------------------------------------------------------
total_bytes = aggregate_metric(profiling_file_1)
total_insts = aggregate_metric(profiling_file_2)

# ------------------------------------------------------------
# 4. Compute rates
# ------------------------------------------------------------
instruction_rate_bips = total_insts / runtime / 1e9  # Billion Instructions per Second
data_load_rate_gbps = total_bytes / runtime / 1e9    # GB per Second

# ------------------------------------------------------------
# 5. Write to summary CSV
# ------------------------------------------------------------
os.makedirs(os.path.dirname(summary_out), exist_ok=True)
write_header = not os.path.exists(summary_out)

# with open(summary_out, "a", newline="") as csvfile:
#     writer = csv.writer(csvfile)
#     if write_header:
#         writer.writerow(["Dataset", "Instruction Rate (BIPS)", "Data Load Rate (GB/s)"])
#     writer.writerow([dataset, f"{instruction_rate_bips:.3f}", f"{data_load_rate_gbps:.3f}"])

with open(summary_out, "a", newline="") as csvfile:
    writer = csv.writer(csvfile)
    if write_header:
        writer.writerow(["Dataset", "Runtime (ms)", "Instruction Rate (BIPS)", "Data Load Rate (GB/s)"])
    writer.writerow([
        dataset,
        f"{runtime_ms:.3f}",
        f"{instruction_rate_bips:.3f}",
        f"{data_load_rate_gbps:.3f}"
    ])

# ------------------------------------------------------------
# 6. Print summary
# ------------------------------------------------------------
print(f"📊 {dataset}")
print(f"  Runtime:          {runtime_ms:,.3f} ms")
print(f"  Instruction Rate: {instruction_rate_bips:,.3f} BIPS")
print(f"  Data Load Rate:   {data_load_rate_gbps:,.3f} GB/s\n")