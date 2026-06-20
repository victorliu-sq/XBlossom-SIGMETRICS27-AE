add_library(XbRunnerFlags STATIC flag/flag.cc)
target_link_libraries(XbRunnerFlags PUBLIC gflags)
target_include_directories(XbRunnerFlags PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include")

if (USE_CPU)
    message(STATUS "Building xblsm_cpu for XB-Pro")
    add_subdirectory(xblsm_cpu)
endif ()

if (USE_GPU)
    message(STATUS "Building xblsm_gpu for XB++")
    add_subdirectory(xblsm_gpu)
endif ()
