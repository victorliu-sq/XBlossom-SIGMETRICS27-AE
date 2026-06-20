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
    Extracts:
        "Average runtime: X.XXXX"
    from the given timing file.
    """
    with open(timing_file, "r") as f:
        for line in f:
            match = re.search(r"Average runtime:\s*([0-9.]+)", line)
            if match:
                return float(match.group(1))

    raise RuntimeError(
        f"[ERROR] No 'Average runtime' found in file: {timing_file}"
    )


# ============================================================
# Main
# ============================================================

if len(sys.argv) != 5:
    print(
        "Usage: run_gpu_loadbalance_all_datasets.py "
        "<dataset> <timing_peredge> <timing_pernode> <summary_csv>"
    )
    sys.exit(1)

dataset        = sys.argv[1]
timing_peredge = sys.argv[2]
timing_pernode = sys.argv[3]
summary_csv    = sys.argv[4]

# ------------------------------------------------------------
# Extract runtimes
# ------------------------------------------------------------
avg_peredge = extract_avg_runtime_seconds(timing_peredge)
avg_pernode = extract_avg_runtime_seconds(timing_pernode)

# ------------------------------------------------------------
# Compute metrics
# ------------------------------------------------------------
speedup = avg_pernode / avg_peredge if avg_peredge > 0 else 0.0

# ------------------------------------------------------------
# Write CSV
# ------------------------------------------------------------
write_header = not os.path.exists(summary_csv)

with open(summary_csv, "a", newline="") as f:
    writer = csv.writer(f)

    if write_header:
        writer.writerow([
            "Dataset",
            "AvgRuntime_PerEdge(s)",
            "AvgRuntime_PerNode(s)",
            "Speedup_PerEdge_over_PerNode"
        ])

    writer.writerow([
        dataset,
        f"{avg_peredge:.6f}",
        f"{avg_pernode:.6f}",
        f"{speedup:.4f}"
    ])

# ------------------------------------------------------------
# Console output
# ------------------------------------------------------------
print(
    f"[OK] {dataset}: "
    f"PerEdge={avg_peredge:.6f}s, "
    f"PerNode={avg_pernode:.6f}s, "
    f"Speedup={speedup:.2f}×"
)
