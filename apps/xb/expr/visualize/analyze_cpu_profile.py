import re
import sys
import os

def parse_profiling_file(prof_file):
    """
    Parse perf stat profiling file.
    Returns integer_instr, total_instr, branches, loads, stores.
    """
    total_instr = branches = loads = stores = None
    with open(prof_file, "r") as f:
        for line in f:
            line = line.strip()
            m = re.match(r"([\d,]+)\s+(\S+)", line)
            if not m:
                continue
            value_str, event = m.groups()
            value = int(value_str.replace(",", ""))

            if event.startswith("cpu_core/instructions"):
                total_instr = value
            elif event.startswith("cpu_core/branches"):
                branches = value
            elif event.startswith("cpu_core/mem_inst_retired.all_stores"):
                stores = value
            elif event.startswith("cpu_core/mem_inst_retired.all_loads"):
                loads = value

    if None in (total_instr, branches, loads, stores):
        raise ValueError("Could not parse all counters from profiling file")

    integer_instr = total_instr - branches - stores - loads
    return integer_instr, total_instr, branches, loads, stores


def parse_timing_file(timing_file):
    """
    Parse CPU timing file to extract total execution time in milliseconds.
    """
    total_time_ms = None
    with open(timing_file, "r") as f:
        for line in f:
            m = re.search(r"The average computation taken:\s*([\d\.]+)\s*milliseconds", line)
            if m:
                total_time_ms = float(m.group(1))
                break

    if total_time_ms is None:
        raise ValueError("Could not find 'The average computation taken' in timing file")

    return total_time_ms


def main(dataset_name, prof_file, timing_file):
    integer_instr, total_instr, branches, loads, stores = parse_profiling_file(prof_file)
    total_time_ms = parse_timing_file(timing_file)

    total_time_s = total_time_ms / 1000.0
    giops = integer_instr / total_time_s / 1e9

    # auto-generate output filename in same dir as profiling file
    out_dir = os.path.dirname(prof_file)
    if out_dir == "":
        out_dir = ".."
    output_file = os.path.join(out_dir, f"cpu_{dataset_name}_results.txt")

    with open(output_file, "w") as out:
        out.write(f"Dataset: {dataset_name}\n")
        out.write(f"Executed Integer Ops: {integer_instr:,}\n")
        out.write(f"Execution Time: {total_time_ms:.3f} ms\n")
        out.write(f"Throughput: {giops:.3f} GIOPS\n")

    print(f"Results written to {output_file}")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python3 analyze_cpu_profile.py <dataset_name> <prof_file> <timing_file>")
        sys.exit(1)

    dataset_name = sys.argv[1]
    prof_file = sys.argv[2]
    timing_file = sys.argv[3]

    main(dataset_name, prof_file, timing_file)
