#!/usr/bin/env python3
import sys, csv, os, re

# ============================================================
# Usage
# ============================================================
if len(sys.argv) != 7:
    print("Usage: xb_pp_profile_analyzer.py "
          "<dataset> <timing_file> <profiling_file_1> <profiling_file_2> <profiling_file_3> <summary_out>")
    sys.exit(1)

dataset          = sys.argv[1]
timing_file      = sys.argv[2]
profiling_file_1 = sys.argv[3]   # DRAM bytes
profiling_file_2 = sys.argv[4]   # Instructions
profiling_file_3 = sys.argv[5]   # smsp__average_warp_latency_issue_stalled_long_scoreboard
summary_out      = sys.argv[6]

# ============================================================
# Helper: sum "Metric Value" from Nsight CSV
# ============================================================
def aggregate_metric_sum(filename):
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
                try:
                    total += float(val_str)
                except ValueError:
                    continue
    return total

# ============================================================
# Helper: average "Metric Value" from Nsight CSV
# ============================================================
def aggregate_metric_avg(filename):
    values = []
    header = None
    with open(filename, newline='') as f:
        # Seek Nsight header
        for line in f:
            if line.startswith('"ID","Process ID"') or line.startswith("ID,Process ID"):
                header = [h.strip('"') for h in line.strip().split(",")]
                break
        if not header:
            print(f"[Warning] Could not find Nsight header in {filename}")
            return 0.0

        reader = csv.DictReader(f, fieldnames=header)
        for row in reader:
            val_str = row.get("Metric Value", "0").replace(",", "").replace('"', "")
            try:
                values.append(float(val_str))
            except ValueError:
                continue

    if not values:
        return 0.0
    return sum(values) / len(values)

# ============================================================
# Parse runtime (seconds)
# ============================================================
runtime = 0.0
with open(timing_file) as f:
    for line in f:
        if "Total Time" in line:
            try:
                runtime = float(line.split(":")[1].strip())
            except ValueError:
                pass
            break

runtime_ms = runtime * 1000.0

# ============================================================
# Aggregate metrics
# ============================================================
total_bytes = aggregate_metric_sum(profiling_file_1)  # raw dram bytes
total_insts = aggregate_metric_sum(profiling_file_2)
avg_long_scoreboard_latency = aggregate_metric_avg(profiling_file_3)

total_bytes_gb = total_bytes / 1e9

# ============================================================
# Compute rates
# ============================================================
instruction_rate_bips = total_insts / runtime / 1e9 if runtime > 0 else 0.0  # Billion inst per sec
data_load_rate_gbps   = total_bytes / runtime / 1e9 if runtime > 0 else 0.0  # GB/s

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
            "TotalDRAMReadGB",
            "Runtime(ms)",
            "InstructionRate(BIPS)",
            "DataLoadRate(GB/s)",
            "AvgLongScoreboardLatency"
        ])
    writer.writerow([
        dataset,
        f"{total_bytes_gb:.3f}",
        f"{runtime_ms:.3f}",
        f"{instruction_rate_bips:.3f}",
        f"{data_load_rate_gbps:.3f}",
        f"{avg_long_scoreboard_latency:.3f}"
    ])

# ============================================================
# Print summary
# ============================================================
print(f"📊 {dataset}")
print(f"  Total DRAM Bytes:               {total_bytes_gb:.3f} GB")
print(f"  Runtime:                        {runtime_ms:.3f} ms")
print(f"  Instruction Rate:               {instruction_rate_bips:.3f} BIPS")
print(f"  Data Load Rate:                 {data_load_rate_gbps:.3f} GB/s")
print(f"  Avg Long Scoreboard Latency:    {avg_long_scoreboard_latency:.3f} cycles (warp-level)")
print()
