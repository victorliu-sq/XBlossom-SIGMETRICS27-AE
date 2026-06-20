file(GLOB_RECURSE TEST_SRC_LIST "${CMAKE_CURRENT_SOURCE_DIR}/*.cu")

foreach (TEST_SRC ${TEST_SRC_LIST})
    get_filename_component(TEST_EXE_NAME ${TEST_SRC} NAME_WE)
    add_executable(${TEST_EXE_NAME} ${TEST_SRC})
    target_link_libraries(${TEST_EXE_NAME} PRIVATE XblsmLib benchmark::benchmark)
    target_include_directories(${TEST_EXE_NAME} PRIVATE "${XBLSM_BM_INCLUDE_DIR}")
endforeach ()
