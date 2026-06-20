# AWS T4 Remote Setup Run - 2026-05-26

Targets run from the local repo:

- `make remote-deps-aws-t4`
- `make remote-datasets-aws-t4`
- `make remote-build-aws-t4`

Remote repo path: `/home/ubuntu/RT-Benchmarks`

| Phase | Target | Error / symptom | Resolution | Status |
| --- | --- | --- | --- | --- |
| deps | `make remote-deps-aws-t4` | Boost builds were taking too long after earlier partial builds. | Cleaned partial remote dependency builds and changed the Boost installers to build only the libraries used by the apps: `serialization,system,filesystem,program_options,iostreams`. | Resolved |
| deps | `make remote-deps-aws-t4` | MPFR configure failed because `gmp.h` was missing. | Added a LibRTS GMP installer, wired it before MPFR in `install_all.sh`, and configured MPFR with the repo dependency prefix. | Resolved |
| deps | `make remote-deps-aws-t4` | GMP configure failed with `No usable m4 in $PATH`. | Installed `m4` on `aws-t4` and added a prerequisite check in the GMP installer. | Resolved |
| deps | `make remote-deps-aws-t4` | CGAL install failed because `unzip` was missing. | Installed `unzip` on `aws-t4` and added a prerequisite check in the CGAL installer. | Resolved |
| datasets | `make remote-datasets-aws-t4` | LibRTS failed with `EnvironmentLocationNotFound` for `ppopp-ae-python`. | Updated the LibRTS dataset script to use `CONDA_ENV_NAME`, defaulting to `rtbm-env`. | Resolved |
| datasets | `make remote-datasets-aws-t4` | X-HD, RayDB, RTTC, RTNN, RTDBSCAN, RTOD, and RT-BarnesHut scripts used stale `rt-benchmark-env` defaults or fell back to Python without `onedrivedownloader`. | Updated those dataset and preprocess scripts to default to `rtbm-env`, then copied the patched scripts to `aws-t4`. | Resolved |
| datasets | `make remote-datasets-aws-t4` | RayDB extraction failed with `No space left on device` because the 22 GB archive plus extracted data exceeded root disk headroom. | Mounted the unformatted 116 GB NVMe device at `/mnt/rtbm-stage`, staged the RayDB archive there, retried extraction, removed the staged archive, then moved final RayDB data to `/mnt/rtbm-stage/data/RayDB` and symlinked `data/RayDB` back into the repo. | Resolved |
| datasets | `make remote-datasets-aws-t4` | RT-BarnesHut extraction later failed with `No space left on device`. | Removed the failed partial extraction and reran after RayDB was moved to NVMe. | Resolved |
| build | `make remote-build-aws-t4` | RT-DBSCAN configure failed because OpenGL development headers/libraries were missing. | Installed `libgl-dev`, `libglx-dev`, and `libopengl-dev` on `aws-t4`. | Resolved |
| build | `make remote-build-aws-t4` | GLFW configure failed because X RandR headers were missing. | Installed `libxrandr-dev`, `libxinerama-dev`, `libxcursor-dev`, and `libxi-dev` on `aws-t4`. | Resolved |

Final result:

- `make remote-deps-aws-t4` completed.
- `make remote-datasets-aws-t4` completed.
- `make remote-build-aws-t4` completed.

Current storage layout on `aws-t4`:

- `/home/ubuntu/RT-Benchmarks/data/RayDB` is a symlink to `/mnt/rtbm-stage/data/RayDB`.
- Root filesystem had about 92 GB free after the successful build.
- `/mnt/rtbm-stage` held RayDB and had about 9.4 GB free.
