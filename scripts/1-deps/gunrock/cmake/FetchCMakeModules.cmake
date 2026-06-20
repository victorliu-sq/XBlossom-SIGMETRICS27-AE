include(FetchContent)
set(FETCHCONTENT_QUIET ON)

message(STATUS "Using External Project: CMake Modules")
set(FC_SOURCE_BASE "${PROJECT_DEPS_DIR}")
set(FC_BUILD_BASE "${PROJECT_DEPS_BUILD_DIR}")
set(FETCHCONTENT_BASE_DIR "${FC_BUILD_BASE}")

FetchContent_Declare(
    cmake_modules
    GIT_REPOSITORY https://github.com/rpavlik/cmake-modules.git
    GIT_TAG        main
    SOURCE_DIR     "${FC_SOURCE_BASE}/cmake_modules-src"
    BINARY_DIR     "${FC_BUILD_BASE}/cmake_modules-build"
    SUBBUILD_DIR   "${FC_BUILD_BASE}/cmake_modules-subbuild"
    UPDATE_DISCONNECTED TRUE
)

FetchContent_GetProperties(cmake_modules)
if(NOT cmake_modules_POPULATED)
  FetchContent_MakeAvailable(
    cmake_modules
  )
endif()
set(CMAKE_MODULES_INCLUDE_DIR "${cmake_modules_SOURCE_DIR}")
