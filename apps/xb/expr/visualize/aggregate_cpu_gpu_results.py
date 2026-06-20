import os
import re
import csv
import sys

def parse_result_file(filename):
    """Parse a result file (CPU or GPU) and return dataset, exec_time (ms), throughput value, throughput unit."""
    dataset = None
    exec_time = None
    throughput = None
    unit = None

    with open(filename, "r") as f:
        for line in f:
            line = line.strip()

            m = re.match(r"Dataset:\s*(\S+)", line)
            if m:
                dataset = m.group(1).lower()

            m = re.match(r"Execution Time:\s*([\d\.]+)\s*ms", line)
            if m:
                exec_time = float(m.group(1))

            m = re.match(r"Throughput:\s*([\d\.]+)\s*(\S+)", line)
            if m:
                throughput = float(m.group(1))
                unit = m.group(2)

    if dataset is None or exec_time is None or throughput is None or unit is None:
        raise ValueError(f"Could not parse required fields from {filename}")

    return dataset, exec_time, throughput, unit


def main(results_dir, output_csv):
    cpu_results = {}
    gpu_results = {}

    for fname in os.listdir(results_dir):
        if not fname.endswith("_results.txt"):
            continue
        fullpath = os.path.join(results_dir, fname)
        dataset, exec_time, throughput, unit = parse_result_file(fullpath)
        if fname.startswith("cpu_"):
            cpu_results[dataset] = (exec_time, throughput, unit)
        elif fname.startswith("gpu_"):
            gpu_results[dataset] = (exec_time, throughput, unit)

    datasets = sorted(set(cpu_results.keys()) & set(gpu_results.keys()))

    with open(output_csv, "w", newline="") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow([
            "Dataset",
            "CPU Exec Time (ms)",
            "GPU Exec Time (ms)",
            "Execution Time Speedup (CPU/GPU)",
            "CPU Throughput (GIOPS)",
            "GPU Throughput (TIOPS)",
            "Throughput Speedup (GPU/CPU)"
        ])

        for d in datasets:
            cpu_time, cpu_thr, cpu_unit = cpu_results[d]
            gpu_time, gpu_thr, gpu_unit = gpu_results[d]

            # Normalize throughput: CPU in GIOPS, GPU in TIOPS → convert CPU to TIOPS
            cpu_thr_tiops = cpu_thr / 1000.0 if cpu_unit.upper() == "GIOPS" else cpu_thr
            gpu_thr_tiops = gpu_thr if gpu_unit.upper() == "TIOPS" else gpu_thr / 1000.0

            time_speedup = cpu_time / gpu_time
            throughput_speedup = gpu_thr_tiops / cpu_thr_tiops

            writer.writerow([
                d,
                f"{cpu_time:.3f}",
                f"{gpu_time:.3f}",
                f"{time_speedup:.2f}",
                f"{cpu_thr:.3f} {cpu_unit}",
                f"{gpu_thr:.3f} {gpu_unit}",
                f"{throughput_speedup:.2f}x"
            ])

    print(f"Summary written to {output_csv}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 aggregate_cpu_gpu_results.py <results_dir> <output_csv>")
        sys.exit(1)

    results_dir = sys.argv[1]
    output_csv = sys.argv[2]
    main(results_dir, output_csv)

