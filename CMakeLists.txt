cmake_minimum_required(VERSION 3.30)

project(graph-cpu-gpu-evaluation)

set(CMAKE_SUPPRESS_DEVELOPER_WARNINGS TRUE CACHE BOOL "Suppress CMake developer warnings" FORCE)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/lib") # output directory of static libraries
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/bin") # output directory of shared libraries
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/bin") # output directory of executables

# ------------------------------------------------------------------
# JIAIXN: Benchmark Shared dependency setup
# ------------------------------------------------------------------
set(DEPS_ROOT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/deps")
set(DEPS_SCRIPTS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/scripts/1-deps")

list(PREPEND CMAKE_MODULE_PATH
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake"
    "${DEPS_SCRIPTS_DIR}/cmake/modules"
    "${DEPS_SCRIPTS_DIR}/cmake/scripts"
)

set(XB_DEPS_DIR "${DEPS_ROOT_DIR}/xb")
list(PREPEND CMAKE_PREFIX_PATH "${XB_DEPS_DIR}")
# ------------------------------------------------------------------
option(USE_CPU "Enable CPU benchmark components: XB-Pro and Ligra" ON)
option(USE_GPU "Enable GPU benchmark components: XB++ and Gunrock" ON)
option(BUILD_APP_XB "Build X-Blossom benchmark components" ON)
option(BUILD_APP_LIGRA "Build Ligra" ${USE_CPU})
option(BUILD_APP_GUNROCK "Build Gunrock" ${USE_GPU})

message(STATUS "USE_CPU=${USE_CPU}")
message(STATUS "USE_GPU=${USE_GPU}")

include(DetectNumericCudaArchitecture)
detect_numeric_cuda_architecture()

if(BUILD_APP_XB)
    message(STATUS "Build Application X-Blossom")
    set(XB_DEPS_DIR "${XB_DEPS_DIR}" CACHE PATH "X-Blossom dependency install prefix" FORCE)
    set(DEPS_SCRIPTS_DIR "${DEPS_SCRIPTS_DIR}" CACHE PATH "Dependency support scripts directory" FORCE)
    set(USE_CPU "${USE_CPU}" CACHE BOOL "Enable XB CPU library/runners" FORCE)
    set(USE_GPU "${USE_GPU}" CACHE BOOL "Enable XB GPU library/runners" FORCE)
    set(XBLSM_BUILD_RUNNER ON CACHE BOOL "Build dataset runner executables" FORCE)
    add_subdirectory(apps/xb "${CMAKE_BINARY_DIR}/apps/xb")
endif ()

if(BUILD_APP_LIGRA)
    message(STATUS "Build Application Ligra")
    add_subdirectory(apps/ligra "${CMAKE_BINARY_DIR}/apps/ligra")
endif ()

if(BUILD_APP_GUNROCK)
    message(STATUS "Build Application Gunrock")
    set(PROJECT_DEPS_DIR "${DEPS_ROOT_DIR}/gunrock")
    add_subdirectory(apps/gunrock "${CMAKE_BINARY_DIR}/apps/gunrock")
endif ()
