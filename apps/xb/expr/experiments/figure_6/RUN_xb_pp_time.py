#!/usr/bin/env python3
import sys
import csv
import os
import re

# ============================================================
# Extract average runtime (seconds)
# ============================================================

def extract_avg_runtime_seconds(timing_file):
    """
    Extract:  "Average runtime: X.XXXX"
    Works for XB and XB-Pro timing outputs.
    """
    with open(timing_file) as f:
        for line in f:
            m = re.search(r"Average runtime:\s*([0-9.]+)", line)
            if m:
                return float(m.group(1))

    raise RuntimeError(f"[ERROR] No 'Average runtime' found in: {timing_file}")


# ============================================================
# Main
# ============================================================

if len(sys.argv) != 4:
    print("Usage: RUN_xb_pp.py "
          "<dataset> <timing_xb_pp> <summary_csv>")
    sys.exit(1)

dataset        = sys.argv[1]
timing_xb_pp  = sys.argv[2]
summary_csv    = sys.argv[3]

# Extract runtimes
avg_xb_pp = extract_avg_runtime_seconds(timing_xb_pp)

# ============================================================
# Write CSV
# ============================================================

write_header = not os.path.exists(summary_csv)

with open(summary_csv, "a", newline="") as f:
    writer = csv.writer(f)

    # header only once
    if write_header:
        writer.writerow([
            "Dataset",
            "AvgRuntime_XB++(s)",
        ])

    writer.writerow([
        dataset,
        f"{avg_xb_pp:.6f}",
    ])

print(
    f"[OK] {dataset}: "
    f"XB++={avg_xb_pp:.6f}s, "
)
