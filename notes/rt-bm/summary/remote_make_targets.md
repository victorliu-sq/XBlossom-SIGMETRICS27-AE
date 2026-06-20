# RT-Benchmarks Remote Make Targets

The RT-Benchmarks root `Makefile` includes shared remote workflow targets from
`make/remote.mk`.

Default remote settings are:

```makefile
REMOTE_HOST ?= aws-t4
REMOTE_HOSTS ?= aws-t4
REMOTE_REPO_DIR ?= /home/ubuntu/RT-Benchmarks
REPO_URL ?= git@github.com:victorliu-sq/RT-Benchmarks.git
```

Generic remote targets:

```shell
make remote-clone
make remote-update
make remote-sync
make remote-datasets
make remote-deps
make remote-build
make remote-all
```

`remote-sync` is the lightweight clone/update workflow:

```makefile
remote-sync: remote-clone remote-update
```

It clones the repository on `REMOTE_HOST` if it is missing, then force-updates
the remote checkout and initializes submodules to the commits recorded by the
main repository.

Run the default T4 sync:

```shell
make remote-sync
```

Equivalent explicit host form:

```shell
make remote-sync REMOTE_HOST=aws-t4
```

Future instances can reuse the same targets by passing another SSH config host
name through `REMOTE_HOST` or by listing multiple hosts in `REMOTE_HOSTS` for
`remote-all-hosts`:

```shell
make remote-sync REMOTE_HOST=aws-h100
make remote-all-hosts REMOTE_HOSTS="aws-t4 aws-h100"
```

Use `make -n` before running remote targets to preview commands:

```shell
make -n remote-sync REMOTE_HOST=aws-t4
make -n remote-sync REMOTE_HOST=aws-h100
```

When a recursive clone fails with a missing submodule commit, check whether the
parent repo records a submodule commit that has not been pushed to that
submodule's remote:

```shell
git submodule status --recursive
git ls-remote <submodule-url> <submodule-sha>
```
