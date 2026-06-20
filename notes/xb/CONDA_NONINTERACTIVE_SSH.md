# Non-Interactive SSH Conda PATH Issue

Remote scripts can fail with:

```bash
conda: command not found
```

even when Conda works after manually logging into the server.

Example failure:

```bash
ssh aws-cpu 'cd /home/ubuntu/GACGE && ./expr/remote/analysis-aws-m7i/.../RUN_xxx.sh'
```

## Root Cause

Conda was installed and initialized mainly through interactive shell startup files such as `~/.zshrc` or `~/.bashrc`.

Commands like this:

```bash
ssh aws-cpu 'conda --version'
```

run through a non-interactive SSH shell, which does not reliably source `~/.zshrc`, `~/.bashrc`, or `~/.profile`.

So this may work:

```bash
ssh aws-cpu
conda --version
```

while this may fail:

```bash
ssh aws-cpu 'conda --version'
```

Another issue was that the old Miniconda install script exited early when `miniconda_done` already existed, so later PATH fixes were not applied to machines that had already installed Conda.

## Permanent Fix

Update `scripts/install_miniconda.sh` so it:

- Installs Miniconda in batch mode under `~/miniconda3`.
- Does not exit early just because `miniconda_done` exists.
- Re-applies Conda shell initialization on every run.
- Adds Conda setup blocks to:
  - `~/.zshrc`
  - `~/.zshenv`
  - `~/.bashrc`
  - `~/.profile`
- Creates system PATH symlinks:
  - `/usr/local/bin/conda -> ~/miniconda3/bin/conda`
  - `/usr/local/bin/conda-env -> ~/miniconda3/bin/conda-env`

The `/usr/local/bin/conda` symlink is the important patch for non-interactive SSH, because `/usr/local/bin` is normally already on `PATH` even when shell startup files are not loaded.

## Verification

After applying the patch, these commands should work:

```bash
ssh aws-cpu 'command -v conda && conda --version'
ssh aws-gpu 'command -v conda && conda --version'
```

Expected output:

```bash
conda
conda 26.3.2
```
