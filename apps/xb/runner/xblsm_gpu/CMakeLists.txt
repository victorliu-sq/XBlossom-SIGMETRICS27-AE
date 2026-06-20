file(GLOB_RECURSE XBLSM_GPU_RUNNER_SRC_LIST "${CMAKE_CURRENT_SOURCE_DIR}/*.cu")

foreach (RUNNER_SRC ${XBLSM_GPU_RUNNER_SRC_LIST})
    get_filename_component(RUNNER_EXE_NAME ${RUNNER_SRC} NAME_WE)
    add_executable(${RUNNER_EXE_NAME} ${RUNNER_SRC})
    target_link_libraries(${RUNNER_EXE_NAME} PRIVATE XblsmGpuLib XbRunnerFlags)
endforeach ()
