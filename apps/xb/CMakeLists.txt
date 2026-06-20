cmake_minimum_required(VERSION 3.25)
project(X-Blossom LANGUAGES C CXX)

option(USE_CPU "Enable XB-Pro CPU components" ON)
option(USE_GPU "Enable XB++ GPU components" ON)

if (NOT USE_CPU AND NOT USE_GPU)
    message(FATAL_ERROR "apps/xb requires at least one of USE_CPU or USE_GPU")
endif ()

message(STATUS "XB USE_CPU=${USE_CPU}")
message(STATUS "XB USE_GPU=${USE_GPU}")
if (USE_CPU)
    message(STATUS "XB-Pro CPU library/runners enabled")
else ()
    message(STATUS "XB-Pro CPU library/runners disabled")
endif ()
if (USE_GPU)
    message(STATUS "XB++ GPU library/runners enabled")
else ()
    message(STATUS "XB++ GPU library/runners disabled")
endif ()

# ================== Default CMake Variables ======================
# Set default build type to Release if not specified
if (NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build (Debug or Release)" FORCE)
endif ()

# ================== Targets Output Directory ======================
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/lib") # output directory of static libraries
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/bin") # output directory of shared libraries
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/bin") # output directory of executables

# ================== C++ Compiling Flags ======================
# set c++ standard
set(CMAKE_CXX_STANDARD 17)
# Threads flag for C++
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread")
# Optimization flags for C++
set(CMAKE_CXX_FLAGS_RELEASE "-w -O3")
set(CMAKE_CXX_FLAGS_DEBUG "-g -Wall -Wextra -O0")

if (USE_GPU)
    enable_language(CUDA)

    # ================== CUDA Compiling Flags ======================
    if (NOT CMAKE_CUDA_ARCHITECTURES)
        message(FATAL_ERROR "USE_GPU=ON but CMAKE_CUDA_ARCHITECTURES is not set")
    endif ()
    message(STATUS "XB++ CUDA architectures: ${CMAKE_CUDA_ARCHITECTURES}")
    # Device Lambda flag for CUDA
    set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} --extended-lambda -pthread")
    # Optimization flags for CUDA
    set(CMAKE_CUDA_FLAGS_RELEASE "-w -Wno-deprecated-gpu-targets -O3")
    set(CMAKE_CUDA_FLAGS_DEBUG "-G -g -Wall -Wextra -O0")
endif ()

# ================== Third Party Dependencies ======================
#set(CMAKE_PREFIX_PATH "${CMAKE_SOURCE_DIR}/third_party")
list(APPEND CMAKE_PREFIX_PATH "${CMAKE_SOURCE_DIR}/third_party")

# ------------------------------------------------------------------
# JIAXIN: Application Shared dependency setup
# ------------------------------------------------------------------
if(DEFINED DEPS_SCRIPTS_DIR AND NOT "${DEPS_SCRIPTS_DIR}" STREQUAL "")
  message(STATUS "DEPS_SCRIPTS_DIR is already set to ${DEPS_SCRIPTS_DIR}")
  message(STATUS "DEPS_SCRIPTS_DIR is available at ${DEPS_SCRIPTS_DIR}")
else ()
  set(DEPS_SCRIPTS_DIR "${PROJECT_SOURCE_DIR}/../../deps/_scripts")
  message(STATUS "DEPS_SCRIPTS_DIR was not set; defaulting to ${DEPS_SCRIPTS_DIR}")
endif ()

if(DEFINED XB_DEPS_DIR AND NOT "${XB_DEPS_DIR}" STREQUAL "")
  message(STATUS "XB_DEPS_DIR is already set to ${XB_DEPS_DIR}")
else ()
  set(XB_DEPS_DIR "${PROJECT_SOURCE_DIR}/../../deps/xb")
  message(STATUS "XB_DEPS_DIR was not set; defaulting to ${XB_DEPS_DIR}")
endif ()

list(PREPEND CMAKE_MODULE_PATH
    "${DEPS_SCRIPTS_DIR}/cmake/modules"
    "${DEPS_SCRIPTS_DIR}/cmake/scripts"
)

list(PREPEND CMAKE_PREFIX_PATH
    "${XB_DEPS_DIR}"
)
# ------------------------------------------------------------------

if (USE_GPU)
    find_package(CUDAToolkit REQUIRED)
endif ()
find_package(gflags 2.2.2 REQUIRED)
find_package(glog 0.6.0 REQUIRED)

set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--disable-new-dtags")  # this line of code allows cmake to search library path
set(CMAKE_BUILD_RPATH "${CMAKE_SOURCE_DIR}/third_party/lib")
set(CMAKE_INSTALL_RPATH "${CMAKE_SOURCE_DIR}/third_party/lib")
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

# ================== Build XBlossom Libraries ======================
add_subdirectory(src)

# ================== Optional Build Targets ======================
option(XBLSM_BUILD_RUNNER "Build dataset runner executables" OFF)
option(XBLSM_BUILD_TEST "Build test executables" OFF)
option(XBLSM_BUILD_BENCHMARK "Build benchmark executables" OFF)

if (XBLSM_BUILD_RUNNER)
    add_subdirectory(runner)
endif ()

if (XBLSM_BUILD_TEST)
    find_package(GTest 1.17.0 REQUIRED) # Notice the GT
    add_subdirectory(test)
endif ()

if (XBLSM_BUILD_BENCHMARK)
    find_package(benchmark 1.9.4 REQUIRED)
    add_subdirectory(benchmark)
endif ()
