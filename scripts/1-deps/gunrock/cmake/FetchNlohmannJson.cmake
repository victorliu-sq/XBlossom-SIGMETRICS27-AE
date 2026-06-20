include(FetchContent)
set(FETCHCONTENT_QUIET ON)

message(STATUS "Using External Project: NLohmannJson")
set(FC_SOURCE_BASE "${PROJECT_DEPS_DIR}")
set(FC_BUILD_BASE "${PROJECT_DEPS_BUILD_DIR}")
set(FETCHCONTENT_BASE_DIR "${FC_BUILD_BASE}")

FetchContent_Declare(
  json
    GIT_REPOSITORY https://github.com/nlohmann/json.git
    GIT_TAG        develop
    SOURCE_DIR     "${FC_SOURCE_BASE}/json-src"
    BINARY_DIR     "${FC_BUILD_BASE}/json-build"
    SUBBUILD_DIR   "${FC_BUILD_BASE}/json-subbuild"
    UPDATE_DISCONNECTED TRUE
)

FetchContent_GetProperties(json)
if(NOT json_POPULATED)
  FetchContent_MakeAvailable(
    json
  )
endif()
set(NHLOMANN_JSON_INCLUDE_DIR "${json_SOURCE_DIR}/include")
