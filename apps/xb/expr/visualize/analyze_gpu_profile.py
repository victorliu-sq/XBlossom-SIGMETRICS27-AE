import pandas as pd
import re
import sys

def analyze(dataset_name, profiler_csv, timing_file, output_file):
    # --- Step 1: Sum integer instructions from profiler CSV ---
    df = pd.read_csv(profiler_csv, skiprows=2)
    df["Metric Value"] = df["Metric Value"].astype(str).str.replace(",", "")
    df["Metric Value"] = df["Metric Value"].astype(int)
    total_integer_ops = df["Metric Value"].sum()

    # --- Step 2: Extract total time (ms) from timing file ---
    total_time_ms = None
    with open(timing_file, "r") as f:
        for line in f:
            match = re.search(r"Total Time:\s*([\d\.]+)\s*ms", line)
            if match:
                total_time_ms = float(match.group(1))
                break
    if total_time_ms is None:
        raise ValueError("Could not find 'Total Time' in timing file")

    # --- Step 3: Compute throughput (TIOPS) ---
    total_time_s = total_time_ms / 1000.0
    tiops = total_integer_ops / total_time_s / 1e12

    # --- Step 4: Write output ---
    with open(output_file, "w") as out:
        out.write(f"Dataset: {dataset_name}\n")
        out.write(f"Executed Integer Ops: {total_integer_ops:,}\n")
        out.write(f"Execution Time: {total_time_ms:.4f} ms\n")
        out.write(f"Throughput: {tiops:.4f} TIOPS\n")

    print(f"Results written to {output_file}")

if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("Usage: python3 analyze_gpu_profile.py <dataset_name> <profiler_csv> <timing_file> <output_file>")
        sys.exit(1)

    dataset_name = sys.argv[1]
    profiler_csv = sys.argv[2]
    timing_file = sys.argv[3]
    output_file = sys.argv[4]

    analyze(dataset_name, profiler_csv, timing_file, output_file)