# SIGMETIRCS26 Artifact 

## Hardware Requirements

- At least one NVIDIA GPU, with each Streaming Multiprocessor (SM) supporting a block size of at least **1024 threads**.
- A multi-core CPU with at least **32 threads**.
- At least **24 GB** of both host memory and GPU memory.
- At least **10 GB** of free disk space for storing generated synthetic data.

All experiments were conducted on Intel CPUs; profiling tools may fail or produce unsupported results on AMD-based systems.

## Software Requirements

Please ensure your system meets the following minimum software versions (greater than or equal to these values):

- bash
- wget or curl
- perf
- ncu
- git
- CUDA: 12.8
- GCC: 13.2.0
- CMake: 3.25.2
- Conda: 25.9.1
- Python: 3.11

**Note:** `perf` and `ncu` must be installed and accessible in your system's `PATH`. If they are missing, consult your
system administrator or package manager.

---

## Setup & Execution

To reproduce our experimental results, simply execute the following from the project root directory:

```bash
./expr/runme.sh
```

The script will automatically handle dependencies downloads (requires wget or curl), datasets download, restructure, installation, compilation, and
execution of workloads. 

The resulting `figure6`, `figure7`, `table1`, `table2`, `table3`, `table5 `and `table6` will be stored
in the `data/results` directory. The entire experiment may take approximately 4–6 hours to complete, depending on the hardware configuration.
