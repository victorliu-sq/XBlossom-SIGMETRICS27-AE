include(FetchContent)
set(FETCHCONTENT_QUIET ON)

message(STATUS "Using External Project: ModernGPU")
set(FC_SOURCE_BASE "${PROJECT_DEPS_DIR}")
set(FC_BUILD_BASE "${PROJECT_DEPS_BUILD_DIR}")
set(FETCHCONTENT_BASE_DIR "${FC_BUILD_BASE}")

FetchContent_Declare(
    moderngpu
    GIT_REPOSITORY https://github.com/moderngpu/moderngpu
    GIT_TAG        master
    SOURCE_DIR     "${FC_SOURCE_BASE}/moderngpu-src"
    BINARY_DIR     "${FC_BUILD_BASE}/moderngpu-build"
    SUBBUILD_DIR   "${FC_BUILD_BASE}/moderngpu-subbuild"
    UPDATE_DISCONNECTED TRUE
)

FetchContent_GetProperties(moderngpu)
if(NOT moderngpu_POPULATED)
  FetchContent_Populate(
    moderngpu
  )
endif()
set(MODERNGPU_INCLUDE_DIR "${moderngpu_SOURCE_DIR}/src")
