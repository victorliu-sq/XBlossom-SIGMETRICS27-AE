if (USE_CPU)
    add_subdirectory(xblsm_cpu)
endif ()

if (USE_GPU)
    add_subdirectory(xblsm_gpu)
endif ()
