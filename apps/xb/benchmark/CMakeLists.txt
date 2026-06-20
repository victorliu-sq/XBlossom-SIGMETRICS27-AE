set(XBLSM_BM_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/include")
message("XBLSM_BM_INCLUDE_DIR is ${XBLSM_BM_INCLUDE_DIR}")

if (USE_GPU)
    add_subdirectory(xblsm_gpu)
endif ()

if (USE_CPU)
    add_subdirectory(xblsm_cpu)
endif ()
