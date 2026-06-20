include(FetchContent)
set(FETCHCONTENT_QUIET ON)

message(STATUS "Using External Project: CXXOPTS")
set(FC_SOURCE_BASE "${PROJECT_DEPS_DIR}")
set(FC_BUILD_BASE "${PROJECT_DEPS_BUILD_DIR}")
set(FETCHCONTENT_BASE_DIR "${FC_BUILD_BASE}")

FetchContent_Declare(
  cxxopts
    GIT_REPOSITORY https://github.com/jarro2783/cxxopts.git
    GIT_TAG        v3.0.0
    SOURCE_DIR     "${FC_SOURCE_BASE}/cxxopts-src"
    BINARY_DIR     "${FC_BUILD_BASE}/cxxopts-build"
    SUBBUILD_DIR   "${FC_BUILD_BASE}/cxxopts-subbuild"
    UPDATE_DISCONNECTED TRUE
)

FetchContent_GetProperties(cxxopts)
if(NOT cxxopts_POPULATED)
  FetchContent_MakeAvailable(
    cxxopts
  )
endif()
set(CXXOPTS_INCLUDE_DIR "${cxxopts_SOURCE_DIR}/include")
