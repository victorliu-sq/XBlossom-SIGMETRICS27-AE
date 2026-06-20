# Remote All Hosts Run - 2026-06-01

Hosts:

- `aws-l4`
- `aws-a10g`
- `aws-l40s`
- `aws-pro6000`

Command:

```bash
make remote-all-hosts REMOTE_HOSTS="aws-l4 aws-a10g aws-l40s aws-pro6000"
```

## Issues And Solutions

### Missing fresh-image prerequisites

Issue: The first fresh run failed during `make deps` while installing LibRTS GMP because `m4` was missing on the new hosts.

Solution: Installed the known fresh-image prerequisites on all four hosts:

```bash
sudo apt-get update
sudo apt-get install -y m4 unzip libgl-dev libglx-dev libopengl-dev libxrandr-dev libxinerama-dev libxcursor-dev libxi-dev rsync
```

This covers the observed GMP `m4` failure plus the `unzip`, OpenGL, GLFW/X11, and remote rsync prerequisites that were previously required on `aws-t4`.

### Cleanup command deleted while traversing

Issue: The first `remote-clean-deps` implementation used recursive `find ... -exec rm -rf` under `deps/`. While deleting parent directories, `find` continued trying to traverse children that no longer existed and returned nonzero.

Solution: Changed the generated dependency and data cleanup commands to delete only direct children with `-mindepth 1 -maxdepth 1`, preserving workflow script directories while avoiding recursive traversal races.

Follow-up: The first failed cleanup had already emptied `deps/_scripts` on the four hosts. Updated `remote-clean-deps` and `remote-clean-data` to restore the tracked script directories with `git restore --source=HEAD -- ...` before removing generated outputs.

### Transient dependency download reset

Issue: During the post-clean rerun, `aws-pro6000` failed in `make deps` with `curl: (35) Recv failure: Connection reset by peer`.

Solution: Treated it as a transient network/download failure and reran the host workflow for `aws-pro6000` separately after confirming no previous process was still active on that host.

### RayJoin OptiX PTX on Blackwell

Issue: On `aws-pro6000`, RayJoin failed in `build-rayjoin` when generating OptiX PTX for `compute_120`; `ptxas` reported unknown OptiX intrinsic symbols such as `_optix_get_payload` and `_optix_trace_typed_32`.

Solution: Capped only RayJoin's OptiX PTX module generation architecture at `compute_89` while leaving normal CUDA application targets on the detected GPU architecture.

### TetMeshQueries build target missing

Issue: `build-tetmeshqueries` configured the repository root, where the TetMeshQueries subdirectory is commented out, so `cmake --build ... --target tetMeshQueriesSmoke` failed with `No rule to make target 'tetMeshQueriesSmoke'`.

Solution: Changed the TetMeshQueries build script to configure `apps/TetMeshQueries` directly.

Follow-up: The first failed TetMeshQueries configure left a stale cache in `build/tetmeshqueries`; removed that build directory before retrying. The direct app configure also needed `-DOptiX_INSTALL_DIR="${REPO_DIR}/deps/optix"` because it no longer inherited repository-root OptiX settings.

### X-HD OptiX PTX on Blackwell

Issue: After the RayJoin Blackwell fix, `aws-pro6000` hit the same `ptxas` OptiX intrinsic failure while generating X-HD OptiX PTX for `compute_120`.

Solution: Applied the same OptiX PTX module architecture cap to X-HD shader generation.
