file(GLOB_RECURSE XBLSM_CPU_RUNNER_SRC_LIST "${CMAKE_CURRENT_SOURCE_DIR}/*.cu")
set_source_files_properties(${XBLSM_CPU_RUNNER_SRC_LIST} PROPERTIES LANGUAGE CXX)

foreach (RUNNER_SRC ${XBLSM_CPU_RUNNER_SRC_LIST})
    get_filename_component(RUNNER_EXE_NAME ${RUNNER_SRC} NAME_WE)
    add_executable(${RUNNER_EXE_NAME} ${RUNNER_SRC})
    target_link_libraries(${RUNNER_EXE_NAME} PRIVATE XblsmLib XbRunnerFlags)
endforeach ()
