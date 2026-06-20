# GitHub Host Key Setup

`0_clone_repo.sh` clones `vm-bootstrap` from GitHub over SSH:

```bash
git clone git@github.com:victorliu-sq/vm-bootstrap.git ~/vm-bootstrap
```

On a fresh VM, `~/.ssh/known_hosts` may not contain GitHub yet. In that case, SSH refuses the clone with:

```text
Host key verification failed.
```

The setup block creates `~/.ssh`, applies safe permissions, checks whether `github.com` is already trusted, and adds GitHub's host key with `ssh-keyscan` only when needed.

## What `ssh-keyscan` Does

```bash
ssh-keyscan -H github.com >> "${HOME}/.ssh/known_hosts"
```

`ssh-keyscan` connects to `github.com` and prints the public SSH host keys advertised by GitHub's SSH server.

Appending that output to `~/.ssh/known_hosts` tells SSH that this VM recognizes GitHub's server identity. Later, when `git clone git@github.com:...` runs, SSH compares GitHub's presented host key with the saved entry. If it matches, the clone can continue without an interactive prompt.

The `-H` option hashes the hostname in `known_hosts`, so the file does not store `github.com` in plain text.

This is different from your personal SSH key. `ssh-keyscan` does not authenticate you to GitHub and does not add GitHub access. It only records the server key used to verify that the VM is connecting to the expected GitHub SSH server.

This prepares the VM for non-interactive GitHub SSH cloning during:

```bash
make gpu-n host=aws-t4
```
