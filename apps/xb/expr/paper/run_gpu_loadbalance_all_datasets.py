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
    Extracts the last occurrence of:
        "Average runtime: X.XXXX"
    from the timing output.
    """
    avg_runtime = None

    with open(timing_file, "r") as f:
        for line in f:
            match = re.search(r"Average runtime:\s*([0-9.]+)", line)
            if match:
                avg_runtime = float(match.group(1))

    if avg_runtime is None:
        raise RuntimeError(
            f"[ERROR] No 'Average runtime' found in file: {timing_file}"
        )

    return avg_runtime


# ============================================================
# Main
# ============================================================

if len(sys.argv) != 5:
    print(
        "Usage: run_gpu_loadbalance_all_datasets.py "
        "<dataset> <timing_xbpp_peredge> <timing_xbpp_pernode> <summary_csv>"
    )
    sys.exit(1)

dataset              = sys.argv[1]
timing_xbpp_peredge  = sys.argv[2]
timing_xbpp_pernode  = sys.argv[3]
summary_csv          = sys.argv[4]

# ------------------------------------------------------------
# Extract runtimes
# ------------------------------------------------------------
avg_peredge = extract_avg_runtime_seconds(timing_xbpp_peredge)
avg_pernode = extract_avg_runtime_seconds(timing_xbpp_pernode)

# ------------------------------------------------------------
# Speedup: PerEdge over PerNode
# Speedup = PerNode / PerEdge
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
            "AvgRuntime_XBPP_PerEdge(s)",
            "AvgRuntime_XBPP_PerNode(s)",
            "Speedup_PerEdge_vs_PerNode"
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
    f"XB++ PerEdge={avg_peredge:.6f}s, "
    f"XB++ PerNode={avg_pernode:.6f}s, "
    f"Speedup={speedup:.4f}"
)
