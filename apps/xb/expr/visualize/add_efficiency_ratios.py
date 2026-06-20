import csv
import sys

# Peak values
CPU_PEAK_GIOPS = 185.6      # Giga integer ops/sec
GPU_PEAK_TIOPS = 14.5       # Tera integer ops/sec

def main(input_csv, output_csv):
    rows = []
    with open(input_csv, "r") as f:
        reader = csv.reader(f)
        header = next(reader)  # skip header if present
        # If your CSV does not have a header, comment out the line above
        for row in reader:
            if not row or row[0].startswith("#"):
                continue
            dataset = row[0]
            cpu_time = float(row[1])
            gpu_time = float(row[2])
            time_speedup = float(row[3])
            cpu_thr_str = row[4]  # e.g., "2.206 GIOPS"
            gpu_thr_str = row[5]  # e.g., "0.638 TIOPS"
            throughput_speedup = row[6]

            # Extract numeric values
            cpu_thr_val = float(cpu_thr_str.split()[0])   # in GIOPS
            gpu_thr_val = float(gpu_thr_str.split()[0])   # in TIOPS

            # Compute percentages
            cpu_eff_pct = (cpu_thr_val / CPU_PEAK_GIOPS) * 100.0
            gpu_eff_pct = (gpu_thr_val / GPU_PEAK_TIOPS) * 100.0

            rows.append([
                dataset,
                cpu_time,
                gpu_time,
                time_speedup,
                cpu_thr_str,
                gpu_thr_str,
                throughput_speedup,
                f"{cpu_eff_pct:.2f}%",
                f"{gpu_eff_pct:.2f}%"
            ])

    with open(output_csv, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow([
            "Dataset",
            "CPU Exec Time (ms)",
            "GPU Exec Time (ms)",
            "Execution Speedup (CPU/GPU)",
            "CPU Throughput (GIOPS)",
            "GPU Throughput (TIOPS)",
            "Throughput Speedup (GPU/CPU)",
            "CPU Effective/Peak (%)",
            "GPU Effective/Peak (%)"
        ])
        writer.writerows(rows)

    print(f"Augmented CSV written to {output_csv}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 add_efficiency_ratios.py <input_csv> <output_csv>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])
