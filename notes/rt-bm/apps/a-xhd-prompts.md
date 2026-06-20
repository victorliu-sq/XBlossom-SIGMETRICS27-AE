# A-X-HD Conversation Prompts

This note lists the prompts from this conversation that drove the `A-X-HD` implementation, build integration, HIPRT setup, benchmarking, and performance tuning work.

## Prompts

1. Implement `A-RTTC` from `RTTC` and add compare workflow.

> move on to implement apps/A-RTTC based on apps/RTTC
> Again, same orgnaization for src and cmakelists.
> Then provide scripts and targets for this pair of applications to write outputs and compare them in the same way as RayJoin app.
> Then build them on two hsots and run and compare to check correness and fetch performance results back.
> Update until the perofmrance is acceptable like RayJoin

2. Relax exact-result and dataset-coverage requirements for `A-RTTC` comparisons.

> You do not need to make all resutls exacptly the same and you do not need to run on all datasewts to compare results,
> you only need to make sure one or two datasets close enoguht since doble eplision is normal

3. Update A-X-HD ignore rules.

> update gitignore of A-X-HD to ignore log files

4. Remove CI-related files from the AMD HD app.

> for A-HD, remove all related to CI

5. Confirm CI removal.

> yes

6. Commit A-X-HD implementation and related grouped changes.

> commit all changes in different groups

7. Ask about HIPRT package discovery and HIP package support.

> it looks like HIPRT 's include directory and library need to use `HIPRT_INCLUDE_DIR` and `HIPRT_LIBRARY`
> is it possible to use find_packges directlry?
> does HIP provide something like CUDA toolkit packge to find directly?

8. Try HIPRT config package linking.

> try to use this first find_package(hiprt REQUIRED CONFIG)
>                       target_link_libraries(my_target PRIVATE hiprt::hiprt)
> and check whether it can compile on remote host

9. Try HIP/HIPRT CMake package style.

> does this work?
> "cmake_minimum_required(VERSION 3.21)
>  project(MyRayTracer VERSION 1.0.0 LANGUAGES CXX HIP)
>  
>  # Locate HIP and HIPRT configurations
>  list(APPEND CMAKE_PREFIX_PATH /opt/rocm /opt/rocm/hip)
>  find_package(hip REQUIRED)
>  find_package(hiprt REQUIRED)
>  
>  # Add your target
>  add_executable(my_raytracer main.cpp)
>  
>  # Link your executable
>  target_link_libraries(my_raytracer PRIVATE hip::device hiprt::hiprt)
> "
> Can you try this style?

10. Try both HIP host/device targets and remove custom Findhiprt module.

> Can you try to use both hip::host and hip::device
> Besides, try to remove apps/A-X-HD/cmake/modules/Findhiprt.cmake and only let the the cmake configure in "
> ```cmake
> "/opt/rocm"
> "/opt/rocm/hip"
> ```
> "
> work for `find_package(hip REQUIRED)` and `find_package(hiprt REQUIRED)`

11. Check ROCm/HIP install paths on Azure.

> Can you check on azure where ROCM or HIP is installed? Maybe we donot provide correct`CMAKE_PREFIX_PATH`?

12. Add HIPRT dependency install script.

> Then let's install HIPRT first in a script by :
> "deps/_scripts"
> create a dir called HIPRT. 
> You can refer to the attached image to install it in deps/hiprt
> And then update deps/_scripts/install_all.sh and corresponding scripts and targets[@ai-chat-attachment-5142661209799359438.png](file:///tmp/ai-chat-attachment-5142661209799359438.png)

13. Add root CMake HIPRT variables for A-apps.

> Then you can upadte CMakeLists.txt right after  
> ```cmake
> set(OptiX_INSTALL_DIR
>         "${CMAKE_SOURCE_DIR}/deps/optix"
>         CACHE PATH "Path to OptiX installed location."
> )
> ```
>  to provide the vairables for hiprt and then let A-Apps use them in thier CMakeListst.txt.
> The hints are too teidous:
> "
> ```cmake
> find_path(HIPRT_INCLUDE_DIR hiprt/hiprt.h HINTS
>   "${HIPRT_ROOT}/include"
>   "${RTBM_DEPS_DIR}/HIPRT/install/include"
>   "$ENV{HIPRT_ROOT}/include"
> )
> find_library(HIPRT_LIBRARY NAMES hiprt0300164 hiprt HINTS
>   "${HIPRT_ROOT}/bin"
>   "${HIPRT_ROOT}/lib"
>   "${RTBM_DEPS_DIR}/HIPRT/install/bin"
>   "${RTBM_DEPS_DIR}/HIPRT/install/lib"
>   "$ENV{HIPRT_ROOT}/bin"
>   "$ENV{HIPRT_ROOT}/lib"
> )
> ```
> "
> Directly use the correct path

14. Encapsulate HIPRT CMake variables and avoid hard-coded HIPRT version number.

> for this:
> "
> ```cmake
> set(HIPRT_LIBRARY
>         "${HIPRT_ROOT}/bin/libhiprt0300164.so"
>         CACHE FILEPATH "Path to HIPRT library."
> )
> 
> ```
> "
> relace number with * or other things so we do not need to provide a concrete number.
> And encapluate in 
> ```cmake
> set(HIPRT_ROOT
>         "${CMAKE_SOURCE_DIR}/deps/hiprt/install"
>         CACHE PATH "Path to HIPRT installed location."
> )
> set(HIPRT_INCLUDE_DIR
>         "${HIPRT_ROOT}/include"
>         CACHE PATH "Path to HIPRT include directory."
> )
> set(HIPRT_LIBRARY
>         "${HIPRT_ROOT}/bin/libhiprt0300164.so"
>         CACHE FILEPATH "Path to HIPRT library."
> )
> ```
> cmake a script s.t. we can use include to encapuslate these things.

15. Commit HIPRT setup changes.

> commit all changes in group

16. Return to A-X-HD performance issue and request close-to-X-HD implementation.

> Back to the performance issue of A-X-HD only smalldatasets work. But the perofmrnace 10x slower than t4 version is unacceptable.
> Fix the perofmrance issue to make it as close to N card as possible>
> Again makesure your code is close the version of X-HD as close as possible.

17. Commit A-X-HD performance changes.

> commit these changes

18. Add AMD app performance issue note.

> add one md file called amd.md under notes/rt-bm/apps and add one table to list performance iss of each A-app and the solution to this perforamance issue.

19. Test whether the AABB cost model helps NVIDIA X-HD on T4.

> I have tone question, for running AABB cost model, can this memthod also improve the perofmrace of x-HD on awt-t4? try it

20. Find an optimal A-X-HD AABB cost value for total time.

> Can you find optinal cost for A-X-HD to let it have optimal total time?

21. Stop the long refinement and use the current best cost.

> enough just use the best or nearly best value currently you have so far. And the nrun it on all datasets to fetch performance resutls back.

22. Commit final A-X-HD tuning changes.

> commit all changes

23. Request this prompt list.

> Can you list all prompts in this conversation that I used for A-XHD in one md file under notes/rt-bm/apps

24. RTTC-targeted implementation and relaxed validation prompt.

> move on to implement apps/A-RTTC based on apps/RTTC
> Again, same orgnaization for src and cmakelists.
> Then provide scripts and targets for this pair of applications to write outputs and compare them in the same way as RayJoin app.
> Then build them on two hsots and run and compare to check correness and fetch performance results back.
> Update until the perofmrance is acceptable like RayJoin
> You do not need to make all resutls exacptly the same and you do not need to run on all datasewts to compare results,
> you only need to make sure one or two datasets close enoguht since doble eplision is normal

25. LibRTS-targeted implementation and relaxed validation prompt.

> move on to implement apps/A-LibRTS based on apps/LibRTS
> Again, same orgnaization for src and cmakelists.
> Then provide scripts and targets for this pair of applications to write outputs and compare them in the same way as RayJoin app.
> Then build them on two hsots and run and compare to check correness and fetch performance results back.
> Update until the perofmrance is acceptable like RayJoin
> You do not need to make all resutls exacptly the same and you do not need to run on all datasewts to compare results,
> you only need to make sure one or two datasets close enoguht since doble eplision is normal

26. Mochi-DCD-targeted implementation and relaxed validation prompt.

> move on to implement apps/A-Mochi-DCD based on apps/Mochi-DCD
> Again, same orgnaization for src and cmakelists.
> Then provide scripts and targets for this pair of applications to write outputs and compare them in the same way as RayJoin app.
> Then build them on two hsots and run and compare to check correness and fetch performance results back.
> Update until the perofmrance is acceptable like RayJoin
> You do not need to make all resutls exacptly the same and you do not need to run on all datasewts to compare results,
> you only need to make sure one or two datasets close enoguht since doble eplision is normal

27. RT-BarnesHut-targeted implementation and relaxed validation prompt.

> move on to implement apps/A-RT-BarnesHut based on apps/RT-BarnesHut
> Again, same orgnaization for src and cmakelists.
> Then provide scripts and targets for this pair of applications to write outputs and compare them in the same way as RayJoin app.
> Then build them on two hsots and run and compare to check correness and fetch performance results back.
> Update until the perofmrance is acceptable like RayJoin
> You do not need to make all resutls exacptly the same and you do not need to run on all datasewts to compare results,
> you only need to make sure one or two datasets close enoguht since doble eplision is normal

28. RT-DBSCAN-targeted implementation and relaxed validation prompt.

> move on to implement apps/A-RT-DBSCAN based on apps/RT-DBSCAN
> Again, same orgnaization for src and cmakelists.
> Then provide scripts and targets for this pair of applications to write outputs and compare them in the same way as RayJoin app.
> Then build them on two hsots and run and compare to check correness and fetch performance results back.
> Update until the perofmrance is acceptable like RayJoin
> You do not need to make all resutls exacptly the same and you do not need to run on all datasewts to compare results,
> you only need to make sure one or two datasets close enoguht since doble eplision is normal

29. RTCollisionDetection-targeted implementation and relaxed validation prompt.

> move on to implement apps/A-RTCollisionDetection based on apps/RTCollisionDetection
> Again, same orgnaization for src and cmakelists.
> Then provide scripts and targets for this pair of applications to write outputs and compare them in the same way as RayJoin app.
> Then build them on two hsots and run and compare to check correness and fetch performance results back.
> Update until the perofmrance is acceptable like RayJoin
> You do not need to make all resutls exacptly the same and you do not need to run on all datasewts to compare results,
> you only need to make sure one or two datasets close enoguht since doble eplision is normal

30. RTNN-targeted implementation and relaxed validation prompt.

> move on to implement apps/A-RTNN based on apps/RTNN
> Again, same orgnaization for src and cmakelists.
> Then provide scripts and targets for this pair of applications to write outputs and compare them in the same way as RayJoin app.
> Then build them on two hsots and run and compare to check correness and fetch performance results back.
> Update until the perofmrance is acceptable like RayJoin
> You do not need to make all resutls exacptly the same and you do not need to run on all datasewts to compare results,
> you only need to make sure one or two datasets close enoguht since doble eplision is normal

31. RTOD-targeted implementation and relaxed validation prompt.

> move on to implement apps/A-RTOD based on apps/RTOD
> Again, same orgnaization for src and cmakelists.
> Then provide scripts and targets for this pair of applications to write outputs and compare them in the same way as RayJoin app.
> Then build them on two hsots and run and compare to check correness and fetch performance results back.
> Update until the perofmrance is acceptable like RayJoin
> You do not need to make all resutls exacptly the same and you do not need to run on all datasewts to compare results,
> you only need to make sure one or two datasets close enoguht since doble eplision is normal

32. RTSpMSpM-targeted implementation and relaxed validation prompt.

> move on to implement apps/A-RTSpMSpM based on apps/RTSpMSpM
> Again, same orgnaization for src and cmakelists.
> Then provide scripts and targets for this pair of applications to write outputs and compare them in the same way as RayJoin app.
> Then build them on two hsots and run and compare to check correness and fetch performance results back.
> Update until the perofmrance is acceptable like RayJoin
> You do not need to make all resutls exacptly the same and you do not need to run on all datasewts to compare results,
> you only need to make sure one or two datasets close enoguht since doble eplision is normal

33. RayDB-targeted implementation and relaxed validation prompt.

> move on to implement apps/A-RayDB based on apps/RayDB
> Again, same orgnaization for src and cmakelists.
> Then provide scripts and targets for this pair of applications to write outputs and compare them in the same way as RayJoin app.
> Then build them on two hsots and run and compare to check correness and fetch performance results back.
> Update until the perofmrance is acceptable like RayJoin
> You do not need to make all resutls exacptly the same and you do not need to run on all datasewts to compare results,
> you only need to make sure one or two datasets close enoguht since doble eplision is normal

34. RayJoin-targeted implementation and relaxed validation prompt.

> move on to implement apps/A-RayJoin based on apps/RayJoin
> Again, same orgnaization for src and cmakelists.
> Then provide scripts and targets for this pair of applications to write outputs and compare them in the same way as RayJoin app.
> Then build them on two hsots and run and compare to check correness and fetch performance results back.
> Update until the perofmrance is acceptable like RayJoin
> You do not need to make all resutls exacptly the same and you do not need to run on all datasewts to compare results,
> you only need to make sure one or two datasets close enoguht since doble eplision is normal
