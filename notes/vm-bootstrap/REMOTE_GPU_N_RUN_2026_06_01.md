# Remote GPU-N Bootstrap Run - 2026-06-01

Hosts:

- `aws-a10g`
- `aws-l4`
- `aws-l40s`
- `aws-pro6000`

Command pattern:

```bash
make -C vm-bootstrap remote-gpu-n host=<host>
```

Parallel run command:

```bash
make -C vm-bootstrap remote-gpu-n aws-l4 aws-a10g aws-l40s aws-pro6000
```

Run log:

- `notes/vm-bootstrap/remote-gpu-n-parallel-2026-06-01.log`

Outcome:

- Completed successfully on all four hosts.
- The log contains four `All stack checks passed` results.
- Verified GPUs reported by `nvidia-smi`: NVIDIA L4, NVIDIA A10G, NVIDIA L40S, and NVIDIA RTX PRO 6000.

## Issues And Solutions

### Local log redirection path

Issue: The first parallel launch attempt redirected logs to `../notes/vm-bootstrap/...` while the shell was already running from the repository root. The shell failed before Make started because that parent-relative path did not exist.

Solution: Use repository-root-relative log paths, e.g. `notes/vm-bootstrap/remote-gpu-n-aws-a10g-2026-06-01.log`.

### Remote host execution was serial

Issue: `make -C vm-bootstrap remote-gpu-n aws-l4 aws-a10g aws-l40s aws-pro6000` accepted the shorthand host list, but `remote-gpu-n` iterated over `REMOTE_WORKFLOW_HOSTS` in a single shell loop. Each host had to finish before the next host started.

Solution: Updated `vm-bootstrap/make/remote.mk` so remote workflow targets start one background subshell per host, collect PIDs, wait for all hosts, and return nonzero if any host fails. The per-host steps still run in order: clone/pull, ensure `make` exists, then invoke the requested remote target.

### Remote `make` missing on fresh hosts

Issue: Fresh Ubuntu hosts had the `~/vm-bootstrap` repo, but `make` was not installed yet. The wrapper failed at `cd ~/vm-bootstrap && make gpu-n` before the bootstrap could reach its `build-essential` install step.

Solution: Added `vm-bootstrap/workflow/0_ensure_make.sh` and call it from `vm-bootstrap/make/remote.mk` before invoking the remote Make target. The script installs `make` with `sudo apt-get update && sudo apt-get install -y make` when `command -v make` fails.

### Parallel `remote-gpu-n` run

Issue: No new blocking issue was encountered during the parallel run on `aws-l4`, `aws-a10g`, `aws-l40s`, and `aws-pro6000`.

Solution: No runtime fix was needed. The previous fixes for parallel host execution and remote `make` preflight were sufficient.
