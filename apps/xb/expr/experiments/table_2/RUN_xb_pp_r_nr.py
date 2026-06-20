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

if len(sys.argv) != 5:
    print("Usage: RUN_xb_and_xb_pro_analysis.py "
          "<dataset> <timing_xb> <timing_xb_pro> <summary_csv>")
    sys.exit(1)

dataset        = sys.argv[1]
timing_xb_pp_nr      = sys.argv[2]
timing_xb_pp  = sys.argv[3]
summary_csv    = sys.argv[4]

# Extract runtimes
avg_xb_pp_nr = extract_avg_runtime_seconds(timing_xb_pp_nr)
avg_xb_pp = extract_avg_runtime_seconds(timing_xb_pp)

# Calculate speedup: XB / XB-Pro
speedup = avg_xb_pp_nr / avg_xb_pp if avg_xb_pp > 0 else 0.0

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
            "AvgRuntime_XB++NR(s)",
            "AvgRuntime_XB++(s)",
            "Speedup"
        ])

    writer.writerow([
        dataset,
        f"{avg_xb_pp_nr:.6f}",
        f"{avg_xb_pp:.6f}",
        f"{speedup:.4f}"
    ])

print(
    f"[OK] {dataset}: "
    f"XB++NR={avg_xb_pp_nr:.6f}s, "
    f"XB++={avg_xb_pp:.6f}s, "
    f"Speedup={speedup:.4f}"
)
