The build directory is independent of the top-level CMakeLists.txt location. As long as the top-level CMakeLists.txt can successfully configure and build the application, an external benchmark project can build it from any working directory by providing the appropriate source path to CMake.

```bash
cmake -S "$Anywhere" -B build
```

How to create symbol links for apps to link deps
`ln -s` means symbol link, followed by target and linkname
```bash
rm apps/RTNN/deps
rm apps/RTNN/dep_setup

ln -s ../../dep_setup apps/RTNN/dep_setup

ln -s ../../dep_setup apps/RayJoin/dep_setup

ln -s ../../dep_setup apps/X-HD/dep_setup

ln -s ../../dep_setup apps/LibRTS/dep_setup
```

How to resolve the issue `undefined reference to cuCtxGetCurrent'?
link against
```cmake
CUDA::cuda_driver
```

### GPU Compute Capability
GPU Compute Capability(CC) is an NVIDIA version number (e.g., \(8.6\) or \(8.9\)) that indicates the hardware architecture features, which indicate which optimizations compiler can use. It is a contract between software and hardware to perform code optimization.

In CMake, you control the targeted compute architectures by setting the CMAKE_CUDA_ARCHITECTURES variable or the CUDA_ARCHITECTURES target property.

You can tell CMake to automatically detect the local GPU's compute capability
```cmake
set(CMAKE_CUDA_ARCHITECTURES native)
```
or you can set  on a specific target
```cmake
add_executable(my_cuda_app main.cu)
set_target_properties(my_cuda_app PROPERTIES
    CUDA_ARCHITECTURES "86"
)
```

### CMAKE directory
`CMAKE_SOURCE_DIR`
The absolute path to the source directory that contains the top-level CMakeLists.txt.

`CMAKE_CURRENT_SOURCE_DIR`
The absolute path to the source directory containing the CMakeLists.txt file currently being processed.

`PROJECT_SOURCE_DIR`
The absolute path to the source directory of the current logical project, as defined by the nearest relevant project() command.

Use `CMAKE_SOURCE_DIR` when referring to the top-level CMakeLists.txt.

Use `CMAKE_CURRENT_SOURCE_DIR` when referring to the directory of the currently processed CMakeLists.txt.

Use `PROJECT_SOURCE_DIR` when referring to the root directory of the current logical project.