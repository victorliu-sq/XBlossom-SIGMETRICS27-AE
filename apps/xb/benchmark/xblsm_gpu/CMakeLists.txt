file(GLOB_RECURSE BM_GPU_SRC_LIST "${CMAKE_CURRENT_SOURCE_DIR}/*.cu")

foreach (BM_GPU_SRC ${BM_GPU_SRC_LIST})
    get_filename_component(BM_GPU ${BM_GPU_SRC} NAME_WE)
    add_executable(${BM_GPU} ${BM_GPU_SRC})
    target_link_libraries(${BM_GPU} PRIVATE XblsmGpuLib benchmark::benchmark)
    target_include_directories(${BM_GPU} PRIVATE ${XBLSM_BM_INCLUDE_DIR})
endforeach ()