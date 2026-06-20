#!/usr/bin/env python3
import csv
import sys
import os

if len(sys.argv) < 3:
    print("Usage: python3 gpu_dram_bytes_read_aggregator.py <ncu_output.csv> <summary_file>")
    sys.exit(1)

filename = sys.argv[1]
summary_file = sys.argv[2]
total_bytes = 0

with open(filename, newline='') as f:
    # Skip everything until the header
    for line in f:
        if line.startswith('"ID","Process ID"'):
            header = [h.strip('"') for h in line.strip().split(",")]
            break

    reader = csv.DictReader(f, fieldnames=header)
    for row in reader:
        metric = row.get("Metric Name", "").strip('"')
        if metric == "dram__bytes_read.sum":
            val = row.get("Metric Value", "0").replace(",", "").replace('"', "")
            try:
                total_bytes += int(val)
            except ValueError:
                pass

dataset_name = os.path.splitext(os.path.basename(filename))[0].replace("gpu_mem_bw_", "")

# Prepare result text
result_text = (
    f"DATASET: {dataset_name}\n"
    f"  Total DRAM Bytes Read: {total_bytes} bytes\n"
    f"  ≈ {total_bytes/1e6:.2f} MB\n"
    f"  ≈ {total_bytes/1e9:.2f} GB\n\n"
)

# Print to console
print(result_text.strip())

# Append to shared summary file
with open(summary_file, "a") as fout:
    fout.write(result_text)
