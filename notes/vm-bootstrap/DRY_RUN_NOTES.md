# Notes On `-n`

`-n` means different things depending on the command.

## `bash -n`

```bash
bash -n 0_clone_repo.sh
```

Checks shell syntax without running the script.

Use it to catch syntax errors before execution.

It does not verify runtime behavior, such as whether SSH keys work or whether a URL exists.

## `make -n`

```bash
make -n cpu host=aws-cpu
```

Prints the commands Make would run, without actually running them.

Use it to preview a Make target before executing it.

It does not validate that the remote host is reachable or that the commands will succeed.
