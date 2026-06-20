set(XBLSM_TEST_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/include")

if (USE_GPU)
    add_subdirectory(device)
endif ()

add_subdirectory(graph)

if (USE_GPU)
    add_subdirectory(xblsm_gpu)
endif ()

if (USE_CPU)
    add_subdirectory(xblsm_cpu)
endif ()
