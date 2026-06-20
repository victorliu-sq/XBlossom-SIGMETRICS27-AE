cmake_minimum_required(VERSION 3.24)

project(gunrock_dependencies LANGUAGES C CXX CUDA)

set(FETCHCONTENT_QUIET OFF)
set(FETCHCONTENT_UPDATES_DISCONNECTED ON CACHE BOOL
    "Do not contact remotes to update already-populated Gunrock dependencies" FORCE)

if(NOT DEFINED PROJECT_ROOT_DIR)
    get_filename_component(PROJECT_ROOT_DIR "${PROJECT_SOURCE_DIR}/../../.." ABSOLUTE)
endif()

if(NOT DEFINED PROJECT_DEPS_DIR)
    set(PROJECT_DEPS_DIR "${PROJECT_ROOT_DIR}/deps/gunrock")
endif()

get_filename_component(PROJECT_DEPS_DIR "${PROJECT_DEPS_DIR}" ABSOLUTE)
set(PROJECT_DEPS_BUILD_DIR "${PROJECT_DEPS_DIR}")

message(STATUS "Gunrock dependency source directory: ${PROJECT_DEPS_DIR}")
message(STATUS "Gunrock dependency build directory: ${PROJECT_DEPS_BUILD_DIR}")

file(MAKE_DIRECTORY "${PROJECT_DEPS_DIR}" "${PROJECT_DEPS_BUILD_DIR}")

include(${PROJECT_SOURCE_DIR}/cmake/FetchCCCL.cmake)
include(${PROJECT_SOURCE_DIR}/cmake/FetchModernGPU.cmake)
include(${PROJECT_SOURCE_DIR}/cmake/FetchCXXOpts.cmake)
include(${PROJECT_SOURCE_DIR}/cmake/FetchNlohmannJson.cmake)
include(${PROJECT_SOURCE_DIR}/cmake/FetchCMakeModules.cmake)
include(${PROJECT_SOURCE_DIR}/cmake/FetchGoogleTest.cmake)
include(${PROJECT_SOURCE_DIR}/cmake/FetchThreads.cmake)
