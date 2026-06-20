function(detect_numeric_cuda_architecture)
  if(NOT USE_GPU)
    return()
  endif()

  if(DEFINED CMAKE_CUDA_ARCHITECTURES AND NOT "${CMAKE_CUDA_ARCHITECTURES}" STREQUAL "")
    message(STATUS "CUDA architectures: ${CMAKE_CUDA_ARCHITECTURES}")
    return()
  endif()

  if(DEFINED ENV{CMAKE_CUDA_ARCHITECTURES} AND NOT "$ENV{CMAKE_CUDA_ARCHITECTURES}" STREQUAL "")
    set(CMAKE_CUDA_ARCHITECTURES "$ENV{CMAKE_CUDA_ARCHITECTURES}" CACHE STRING "CUDA architectures" FORCE)
    message(STATUS "CUDA architectures from environment: ${CMAKE_CUDA_ARCHITECTURES}")
    return()
  endif()

  find_program(NVIDIA_SMI_EXECUTABLE nvidia-smi)
  if(NOT NVIDIA_SMI_EXECUTABLE)
    message(FATAL_ERROR
      "USE_GPU=ON but CMAKE_CUDA_ARCHITECTURES is not set and nvidia-smi was not found. "
      "Set CMAKE_CUDA_ARCHITECTURES explicitly, for example -DCMAKE_CUDA_ARCHITECTURES=89.")
  endif()

  execute_process(
    COMMAND "${NVIDIA_SMI_EXECUTABLE}" --query-gpu=compute_cap --format=csv,noheader
    OUTPUT_VARIABLE NVIDIA_SMI_COMPUTE_CAPABILITIES
    ERROR_VARIABLE NVIDIA_SMI_ERROR
    RESULT_VARIABLE NVIDIA_SMI_RESULT
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_STRIP_TRAILING_WHITESPACE
  )

  if(NOT NVIDIA_SMI_RESULT EQUAL 0)
    message(FATAL_ERROR
      "USE_GPU=ON but nvidia-smi failed while detecting CUDA architecture: ${NVIDIA_SMI_ERROR}. "
      "Set CMAKE_CUDA_ARCHITECTURES explicitly, for example -DCMAKE_CUDA_ARCHITECTURES=89.")
  endif()

  string(REGEX MATCH "[0-9]+\\.[0-9]+" CUDA_COMPUTE_CAPABILITY "${NVIDIA_SMI_COMPUTE_CAPABILITIES}")
  if(NOT CUDA_COMPUTE_CAPABILITY)
    message(FATAL_ERROR
      "USE_GPU=ON but nvidia-smi did not report a compute capability. "
      "Set CMAKE_CUDA_ARCHITECTURES explicitly, for example -DCMAKE_CUDA_ARCHITECTURES=89.")
  endif()

  string(REPLACE "." "" CUDA_ARCHITECTURE "${CUDA_COMPUTE_CAPABILITY}")
  set(CMAKE_CUDA_ARCHITECTURES "${CUDA_ARCHITECTURE}" CACHE STRING "CUDA architectures" FORCE)
  message(STATUS "Detected CUDA architectures: ${CMAKE_CUDA_ARCHITECTURES}")
endfunction()
