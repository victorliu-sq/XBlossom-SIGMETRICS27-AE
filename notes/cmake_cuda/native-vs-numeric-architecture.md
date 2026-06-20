# CMake CUDA `native` vs Numeric Architecture

## Summary

`CMAKE_CUDA_ARCHITECTURES=native` is a CMake keyword. It tells CMake to detect the CUDA architecture of the host GPU and generate the matching compiler flags.

This project cannot pass `native` through unchanged because the Gunrock integration also uses `CMAKE_CUDA_ARCHITECTURES` as a C++ preprocessor value:

```cmake
target_compile_definitions(essentials
  INTERFACE
    SM_TARGET=${CMAKE_CUDA_ARCHITECTURES}
)
```

Gunrock expects `SM_TARGET` to be a numeric compute capability such as `89`, `90`, or `120`, not a CMake keyword string.

## Why `native` Fails Here

For CMake itself, this is valid:

```bash
-DCMAKE_CUDA_ARCHITECTURES=native
```

CMake can translate `native` into CUDA compiler flags when it generates the build.

But this project also forwards the same value to Gunrock as:

```cpp
#define SM_TARGET native
```

Gunrock code expects a number:

```cpp
constexpr compute_capability_t fetch_compute_capability() {
  return make_compute_capability(SM_TARGET);
}
```

and it also uses `SM_TARGET` to construct architecture-specific launch flags:

```cpp
#define SM_TARGET_FLAG _SM_FLAG_WRAPPER(SM_TARGET)
#define _SM_FLAG_WRAPPER(ver) _SM_FLAG(ver)
#define _SM_FLAG(ver) sm_##ver
```

With `SM_TARGET=120`, this becomes `sm_120`, which matches Gunrock's `sm_flag_t` enum.

With `SM_TARGET=native`, this becomes `sm_native`, which is not a valid Gunrock architecture flag. That can produce compile-time failures.

## Blackwell Example

Blackwell RTX 50-series GPUs report compute capability `12.0`.

Gunrock wants that as the numeric architecture:

```text
12.0 -> 120
```

So the project should pass:

```bash
-DCMAKE_CUDA_ARCHITECTURES=120
```

or let the project detect and set `120` automatically.

## Role of `cmake/DetectNumericCudaArchitecture.cmake`

`cmake/DetectNumericCudaArchitecture.cmake` exists to produce the numeric value Gunrock needs.

Its behavior is:

1. If `USE_GPU=OFF`, do nothing.
2. If `CMAKE_CUDA_ARCHITECTURES` is already set, keep the user-provided value.
3. If the environment variable `CMAKE_CUDA_ARCHITECTURES` is set, use it.
4. Otherwise, run:

```bash
nvidia-smi --query-gpu=compute_cap --format=csv,noheader
```

5. Convert the reported compute capability into CMake's numeric architecture format:

```text
8.9  -> 89
12.0 -> 120
```

6. Store that value in `CMAKE_CUDA_ARCHITECTURES`.

The top-level `CMakeLists.txt` uses it as:

```cmake
include(DetectNumericCudaArchitecture)
detect_numeric_cuda_architecture()
```

## Why Not Rely on CMake's Internal Detection?

CMake can resolve `native` internally for CUDA compiler flags, but it does not provide a stable public variable that means "the resolved numeric architecture from `native`".

Some generated CMake files may contain internal values such as:

```cmake
CMAKE_CUDA_ARCHITECTURES_NATIVE
```

but this is not a documented project API and may include CMake-specific suffixes such as `-real`. Relying on it would be brittle.

## Practical Rule

Use `native` only when the value stays inside CMake's CUDA architecture machinery.

When the value is also consumed by C++ code, such as Gunrock's `SM_TARGET`, pass or detect a numeric architecture instead.
