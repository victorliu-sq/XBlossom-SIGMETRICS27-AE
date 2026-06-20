include(FetchContent)
set(FETCHCONTENT_QUIET ON)

message(STATUS "Using External Project: RapidJSON")
set(FC_SOURCE_BASE "${PROJECT_DEPS_DIR}")
set(FC_BUILD_BASE "${PROJECT_DEPS_BUILD_DIR}")
set(FETCHCONTENT_BASE_DIR "${FC_BUILD_BASE}")

FetchContent_Declare(
  rapidjson
    GIT_REPOSITORY https://github.com/Tencent/rapidjson
    GIT_TAG        master
    SOURCE_DIR     "${FC_SOURCE_BASE}/rapidjson-src"
    BINARY_DIR     "${FC_BUILD_BASE}/rapidjson-build"
    SUBBUILD_DIR   "${FC_BUILD_BASE}/rapidjson-subbuild"
    UPDATE_DISCONNECTED TRUE
)

FetchContent_GetProperties(rapidjson)
if(NOT rapidjson_POPULATED)
  FetchContent_MakeAvailable(
    rapidjson
  )
endif()
set(RAPIDJSON_INCLUDE_DIR "${rapidjson_SOURCE_DIR}/include")
