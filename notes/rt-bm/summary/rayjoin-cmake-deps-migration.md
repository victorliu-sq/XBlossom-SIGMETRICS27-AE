# RayJoin CMake Dependency Migration Notes

Use these RayJoin changes as the pattern for moving other benchmark applications from `dep_setup` to the top-level `deps/` organization.

1. Keep shared dependency setup in the top-level benchmark `CMakeLists.txt`.
   - Define `RTBM_DEPS_DIR` once at the benchmark root.
   - Add only shared/common packages to the top-level `CMAKE_PREFIX_PATH`, such as `deps/google`.
   - Set shared non-prefix package hints at the top level, such as `OptiX_INSTALL_DIR` pointing to `deps/optix`.
   - Do not add app-private dependency folders to the top-level `CMAKE_PREFIX_PATH`.

2. Move app CMake helper modules into the app tree.
   - RayJoin now uses app-local CMake support under:
     - `apps/RayJoin/cmake/modules`
     - `apps/RayJoin/cmake/scripts`
   - The app prepends these paths to `CMAKE_MODULE_PATH`.
   - This keeps app-specific find scripts and helper scripts invisible to other applications.

3. Keep app-private dependency discovery inside the app `CMakeLists.txt`.
   - RayJoin checks whether `RTBM_DEPS_DIR` was provided by the benchmark root.
   - When `RTBM_DEPS_DIR` is available, RayJoin prepends only its private dependency roots:
     - `${RTBM_DEPS_DIR}/RayJoin`
     - `${RTBM_DEPS_DIR}/RayJoin/vulkansdk/x86_64`
   - This makes RayJoin-specific packages discoverable only while configuring RayJoin.

4. Define app-private dependency variables in the app `CMakeLists.txt`.
   - RayJoin sets `RAYJOIN_LBVH_DIR` inside the `RTBM_DEPS_DIR` branch:
     - `${RTBM_DEPS_DIR}/RayJoin/lbvh`
   - RayJoin sets `SLANGC` in the same place:
     - `${RTBM_DEPS_DIR}/RayJoin/slang/bin/slangc`
   - Lower-level files such as `apps/RayJoin/src/CMakeLists.txt` should consume these variables and should not know about `RTBM_DEPS_DIR`.

5. Keep shared packages out of app-private prefix paths.
   - RayJoin does not add `deps/google` itself; that comes from the benchmark root.
   - RayJoin does not add `deps/optix` to `CMAKE_PREFIX_PATH`; OptiX is found through `OptiX_INSTALL_DIR`.
   - This separates shared dependency discovery from application-specific dependency discovery.

6. Update lower-level CMake files to consume app variables only.
   - RayJoin `src/CMakeLists.txt` uses `${RAYJOIN_LBVH_DIR}` for LBVH includes.
   - RayJoin `src/CMakeLists.txt` uses `${SLANGC}` for shader compilation commands.
   - It no longer constructs paths from `RTBM_DEPS_DIR` directly.

7. Fix app-relative source paths after moving under the benchmark root.
   - RayJoin shader source directories now use `${PROJECT_SOURCE_DIR}` so they resolve relative to `apps/RayJoin`.
   - This avoids accidentally resolving shader paths against the benchmark root.

8. Keep backend options explicit.
   - RayJoin keeps `RAYJOIN_BUILD_OPTIX` and `RAYJOIN_BUILD_VULKAN` as app options.
   - CUDA is enabled only when `RAYJOIN_BUILD_OPTIX=ON`.
   - Set `CMAKE_CUDA_ARCHITECTURES` to `native` at the app level for CUDA targets.
   - Lower-level CUDA targets should use `${CMAKE_CUDA_ARCHITECTURES}` instead of hard-coded SM values.
   - PTX or OptiX custom shader compilation may keep a separate numeric `compute_XX` value when the helper command requires one.
   - Vulkan packages are found only when `RAYJOIN_BUILD_VULKAN=ON`.

9. Update benchmark build wrappers to use the real top-level app option.
   - RayJoin's benchmark build script now passes:
     - `-DBUILD_APP_RayJoin=ON`
   - Do not use stale option names that are not consumed by the top-level benchmark `CMakeLists.txt`.

10. Keep runtime scripts aligned with shared dependency names.
    - RayJoin dataset scripts now default to the renamed Conda environment:
      - `rtbm-env`
    - This matches the shared `deps/_scripts/conda_env` setup.

11. Add app-private dependency installers under `deps/_scripts/<App>`.
    - Each application gets its own installer folder:
      - `deps/_scripts/<App>/install_all.sh`
      - `deps/_scripts/<App>/install/installer_<dependency>.sh`
    - App-private installers install into:
      - `${TOP_DEPS_DIR}/<App>`
    - The top-level `deps/_scripts/install_all.sh` should call each app installer after shared installers.
    - Do not install shared packages again inside app installers. Keep google packages, OptiX, and the Conda environment shared.
    - Use stamp files under the app dependency folder, such as `${DEPS_DIR}/.stamp-<dependency>`, so repeated installs are idempotent.

For the next application, repeat the same split:

1. Common dependencies stay in top-level benchmark CMake.
2. App CMake helpers move under `apps/<App>/cmake`.
3. App-private dependency paths are added only inside `apps/<App>/CMakeLists.txt`.
4. Lower-level app CMake files use app-defined variables, not `RTBM_DEPS_DIR`.
5. Build wrapper scripts pass the correct top-level `BUILD_APP_<App>` option.
6. CUDA apps set `CMAKE_CUDA_ARCHITECTURES` to `native` and targets consume that variable.
7. App-private dependencies are installed by `deps/_scripts/<App>/install_all.sh` into `deps/<App>`.
