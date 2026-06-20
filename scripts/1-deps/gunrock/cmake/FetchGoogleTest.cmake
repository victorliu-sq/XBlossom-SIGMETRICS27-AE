include(FetchContent)
set(FETCHCONTENT_QUIET ON)

message(STATUS "Using External Project: GoogleTests")
set(FC_SOURCE_BASE "${PROJECT_DEPS_DIR}")
set(FC_BUILD_BASE "${PROJECT_DEPS_BUILD_DIR}")
set(FETCHCONTENT_BASE_DIR "${FC_BUILD_BASE}")

FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG        v1.15.0
    SOURCE_DIR     "${FC_SOURCE_BASE}/googletest-src"
    BINARY_DIR     "${FC_BUILD_BASE}/googletest-build"
    SUBBUILD_DIR   "${FC_BUILD_BASE}/googletest-subbuild"
    UPDATE_DISCONNECTED TRUE
)

# For Windows: Prevent overriding the parent project's compiler/linker settings
if (MSVC)
    set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
endif()

FetchContent_MakeAvailable(googletest)
add_library(gtest::main ALIAS gtest_main)
