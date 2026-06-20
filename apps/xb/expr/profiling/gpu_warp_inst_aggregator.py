#!/usr/bin/env python3
import csv
import sys
import os

if len(sys.argv) < 3:
    print("Usage: python3 gpu_inst_executed_aggregator.py <ncu_output.csv> <summary_file>")
    sys.exit(1)

filename = sys.argv[1]
summary_file = sys.argv[2]
total_insts = 0

with open(filename, newline='') as f:
    # Skip everything until header line
    for line in f:
        if line.startswith('"ID","Process ID"'):
            header = [h.strip('"') for h in line.strip().split(",")]
            break

    reader = csv.DictReader(f, fieldnames=header)
    for row in reader:
        metric = row.get("Metric Name", "").strip('"')
        if metric == "sm__inst_executed.sum":
            val = row.get("Metric Value", "0").replace(",", "").replace('"', "")
            try:
                total_insts += int(val)
            except ValueError:
                pass

dataset_name = os.path.splitext(os.path.basename(filename))[0].replace("gpu_inst_", "")

# Prepare result text
result_text = (
    f"DATASET: {dataset_name}\n"
    f"  Total Instructions Executed: {total_insts}\n"
    f"  ≈ {total_insts/1e6:.2f} M\n"
    f"  ≈ {total_insts/1e9:.2f} B\n\n"
)

# Print to console
print(result_text.strip())

# Append to shared summary file
with open(summary_file, "a") as fout:
    fout.write(result_text)
