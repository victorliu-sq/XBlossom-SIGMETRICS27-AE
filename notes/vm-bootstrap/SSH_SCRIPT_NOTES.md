# Why `bash -s` Is Used With SSH

The command:

```bash
ssh "$(host)" 'bash -s' < 0_clone_repo.sh
```

runs the local script `0_clone_repo.sh` on the remote host.

## Why Not Run `./0_clone_repo.sh` Directly?

Running this locally:

```bash
./0_clone_repo.sh
```

would clone the repo on the local machine, not on the VM.

Running this remotely:

```bash
ssh "$(host)" '~/vm-bootstrap/0_clone_repo.sh'
```

does not work on a fresh VM because `~/vm-bootstrap` may not exist yet.

## How `bash -s` Works

`bash -s` tells Bash to read commands from standard input.

The `< 0_clone_repo.sh` part sends the local script file into the remote SSH session.

So this command:

```bash
ssh "$(host)" 'bash -s' < 0_clone_repo.sh
```

means:

1. SSH into the remote host.
2. Start Bash on that host.
3. Feed the local `0_clone_repo.sh` into that remote Bash process.
4. Clone `vm-bootstrap` on the remote host if it is not already there.

After this succeeds, later Makefile commands can safely run:

```bash
ssh "$(host)" 'cd ~/vm-bootstrap && ./1_install_zsh.sh'
```
