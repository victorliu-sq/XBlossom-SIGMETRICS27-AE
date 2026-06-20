#!/usr/bin/env python3
import sys, csv, re, os

if len(sys.argv) != 5:
    print("Usage: analyze_xb_pro_profile_diff.py <dataset> <perf1> <perf50> <timing>")
    sys.exit(1)

dataset, perf1, perf4, timing = sys.argv[1:5]

def read_val(pattern, filename):
    total = 0
    with open(filename) as f:
        for line in f:
            if re.search(pattern, line):
                parts = line.strip().split(',')
                try:
                    total += int(parts[0])
                except ValueError:
                    continue
    return total

# parse perf outputs
instr1 = read_val(r"instructions", perf1)
instr50 = read_val(r"instructions", perf4)
read1 = read_val(r"rdcas_count_freerun", perf1)
read50 = read_val(r"rdcas_count_freerun", perf4)

# parse runtime (seconds)
runtime = 0.0
with open(timing) as f:
    for line in f:
        if "Average runtime" in line:
            runtime = float(line.split(":")[1].strip())
            break

runtime_ms = runtime * 1000.0  # convert seconds → milliseconds

# compute per-round events (difference / (50−1))
round_diff = 3.0
instr_per_round = (instr50 - instr1) / round_diff
reads_per_round = (read50 - read1) / round_diff

# compute rates
instruction_rate = instr_per_round / runtime          # inst/s
instruction_rate_bips = instruction_rate / 1e9        # billions of inst/s
data_load_rate_gb = (reads_per_round * 64) / (runtime * 1e9)

print(f"📊 {dataset}")
print(f"  Runtime:          {runtime_ms:,.3f} ms")
print(f"  Instruction Rate: {instruction_rate_bips:,.3f} BIPS")
print(f"  Data Load Rate:   {data_load_rate_gb:,.3f} GB/s\n")

# write summary CSV
summary_csv = os.path.join(os.path.dirname(perf1), "_xb_pro_summary_diff.csv")
write_header = not os.path.exists(summary_csv)

# with open(summary_csv, "a", newline="") as csvfile:
#     writer = csv.writer(csvfile)
#     if write_header:
#         writer.writerow(["Dataset", "Instruction Rate (BIPS)", "Data Load Rate (GB/s)"])
#     writer.writerow([dataset, f"{instruction_rate_bips:.3f}", f"{data_load_rate_gb:.3f}"])

with open(summary_csv, "a", newline="") as csvfile:
    writer = csv.writer(csvfile)
    if write_header:
        writer.writerow(["Dataset", "Runtime (ms)", "Instruction Rate (BIPS)", "Data Load Rate (GB/s)"])
    writer.writerow([
        dataset,
        f"{runtime_ms:.3f}",
        f"{instruction_rate_bips:.3f}",
        f"{data_load_rate_gb:.3f}"
    ])