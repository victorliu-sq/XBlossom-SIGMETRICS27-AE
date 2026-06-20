include(FetchContent)
set(FETCHCONTENT_QUIET ON)

message(STATUS "Using External Project: NVBench")
set(FC_SOURCE_BASE "${PROJECT_DEPS_DIR}")
set(FC_BUILD_BASE "${PROJECT_DEPS_BUILD_DIR}")
set(FETCHCONTENT_BASE_DIR "${FC_BUILD_BASE}")

FetchContent_Declare(
    nvbench
    GIT_REPOSITORY https://github.com/NVIDIA/nvbench.git
    GIT_TAG        main
    SOURCE_DIR     "${FC_SOURCE_BASE}/nvbench-src"
    BINARY_DIR     "${FC_BUILD_BASE}/nvbench-build"
    SUBBUILD_DIR   "${FC_BUILD_BASE}/nvbench-subbuild"
    UPDATE_DISCONNECTED TRUE
)

FetchContent_GetProperties(nvbench)
if(NOT nvbench_POPULATED)
  FetchContent_MakeAvailable(
    nvbench
  )
endif()

# Exposing nvbench's source and include directory
set(NVBENCH_INCLUDE_DIR "${nvbench_SOURCE_DIR}")
set(NVBENCH_BUILD_DIR "${nvbench_BINARY_DIR}")

# Add subdirectory ::nvbench
# add_subdirectory(${NVBENCH_INCLUDE_DIR} ${NVBENCH_BUILD_DIR})
