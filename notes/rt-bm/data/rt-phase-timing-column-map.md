# General-Purpose RT Phase Timing Map

This file documents the two RT-related timing columns emitted by the benchmark result writers. The goal is to make the final CSVs easy to analyze as a general-purpose RT Core benchmark while preserving the original per-application detailed timing columns.

Standardized columns:

- `bvh_build_ms (...)`: acceleration-structure construction/update/refit time. The parenthesized text describes what bottom-level primitive or AABB source is used to build the BVH/GAS.
- `rt_intersection_ms (...)`: RT traversal/intersection/search/counting launch phase. The parenthesized text names the original application timing source.

| Application | Standard BVH Column | What The BVH Is Built From | Original BVH Timing Source | Standard RT Intersection Column | Original RT Intersection Timing Source | Source Timer Comment Location |
|---|---|---|---|---|---|---|
| `LibRTS` | `bvh_build_ms (geometry_envelope_aabbs)` | Axis-aligned envelopes of input spatial geometries, inserted into `RTSpatial::SpatialIndex`. | `TimeStat.insert_ms`, printed as `Loading Time`; repeated `SpatialIndex::Insert` timing. | `rt_intersection_ms (query_time_ms)` | `TimeStat.query_ms`, printed as `Query Time`; `SpatialIndex::Query` executes the RTSpatial query traversal/intersection phase. | `apps/LibRTS/RTSpatial/benchmark/rtspatial_query_benchmark.cu` |
| `Mochi-DCD` | `bvh_build_ms (particle_aabbs)` | Particle custom-primitive bounds/AABBs for collision detection, plus the world instance acceleration structure. | Numeric log field `build_ms`; initial OWL particle GAS/world IAS build. | `rt_intersection_ms (dcd_ms)` | Numeric log field `dcd_ms`; collision-detection `owlLaunch2D` phase. | `apps/Mochi-DCD/src/s23-3Dparticlesim/hostCode.cu`, `apps/Mochi-DCD/src/s19-3Dparticlesim-rotate/hostCode.cu` |
| `RT-BarnesHut` | `bvh_build_ms (barnes_hut_node_triangles)` | Triangle geometry generated from Barnes-Hut tree nodes, then instanced into the world acceleration structure. | `[Timing] bvh_build_ms`; `sceneBuildTime` around OWL geometry group/world acceleration construction. | `rt_intersection_ms (core_compute_ms)` | `[Timing] core_compute_ms`; `forceCalculationTime` around Barnes-Hut `owlLaunch2D`. | `apps/RT-BarnesHut/samples/cmdline/s01-rtbarneshut/hostCode.cu` |
| `RT-DBSCAN` | `bvh_build_ms (point_sphere_aabbs)` | Custom sphere/point-neighborhood primitives represented by AABBs for DBSCAN neighborhood search. | `Build time` converted from seconds to milliseconds; OWL user geometry/world acceleration build. | `rt_intersection_ms (core_points_time_s)` | `Core points time` converted from seconds to milliseconds; first OWL launch for neighborhood traversal/core-point identification. | `apps/RT-DBSCAN/samples/cmdline/s02-rtdbscan/hostCode.cpp` |
| `RTNN` | `bvh_build_ms (point_aabbs)` | AABB custom primitives generated from indexed points for nearest-neighbor search. | Log phase `time build BVH`; OptiX GAS build for the active point batch. | `rt_intersection_ms (nn_compute_ms)` | Log phase `time search compute`; nearest-neighbor OptiX traversal/search launch. | `apps/RTNN/src/optixNSearch/optix.cpp`, `apps/RTNN/src/optixNSearch/search.cpp` |
| `RTOD` | `bvh_build_ms (sliding_window_point_aabbs)` | Sliding-window point/custom-primitive AABBs used by the outlier-detection GAS update or rebuild. | Log phase `[Time] build BVH`; per-slide GAS update/rebuild path. | `rt_intersection_ms (detect_outlier_ms)` | Log phase `[Time] detect outlier`; OptiX outlier-detection traversal launch. | `apps/RTOD/src/ods/optixScan.cpp` |
| `RTSpMSpM` | `bvh_build_ms (sparse_nonzero_aabbs)` | Custom primitive AABBs representing sparse matrix structure/nonzero-derived intersection primitives. | Timing log key `bvh_build_ms`; OptiX GAS construction for sparse-structure primitives. | `rt_intersection_ms (spmspm_compute_ms)` | Timing log key `spmspm_compute_ms`; OptiX launch for sparse intersection work. | `apps/RTSpMSpM/optixSpMSpM/src/optixSpMSpM/optixSpMSpM.cpp` |
| `RTTC` | `bvh_build_ms (graph_edge_triangles)` | Triangle geometry converted from graph edges for RT-based triangle counting. | Timing CSV phase `Build BVH`; `bvh_building_time_` around OptiX GAS construction. | `rt_intersection_ms (count_triangles_ms)` | Timing CSV phase `Count triangles`; `counting_time_` around the OptiX triangle-counting launch. | `apps/RTTC/tc/rt_tc/rt_base.cpp`, `apps/RTTC/tc/rt_tc/rt_tc.cpp` |
| `RayDB` | `bvh_build_ms (record_predicate_triangles)` | Triangle primitives generated from encoded database records/predicate geometry for RayDB query evaluation. | Log phase `[Time] Build BVH`; strict OptiX acceleration-structure build call, excluding allocation/free and broader `accel_handling_total_ms`. | `rt_compute_ms` | Log phase `[Time] Launch`; strict OptiX query traversal/intersection launch. | `apps/RayDB/src/raydb/raydb.cpp` |
| `RayJoin` | `bvh_build_ms (line_segment_group_aabbs)` | AABBs over one or more line segments from polygon/map edges; grouping/compression may combine multiple segments per AABB. | Timing CSV phase `Build Index`; closest available phase for RT spatial-index construction before edge-intersection launches. | `rt_intersection_ms (intersection_edges_ms)` | Timing CSV phase `Intersection edges`; RayJoin RT edge traversal/intersection phase. | `apps/RayJoin/src/core/run_overlay_native_benchmark.cu`, `apps/RayJoin/src/core/run_overlay_native.cu` |
| `X-HD` | `bvh_build_ms (grid_cell_mbr_aabbs)` | Minimum bounding rectangles/AABBs of grid cells over the second point set for RT Hausdorff-distance search. | JSON metric `BVHBuildTime`; `BuildBVH` for the RT Hausdorff-distance acceleration structure. | `rt_intersection_ms (rt_time_ms)` | JSON metric `RTTime`; accumulated RT traversal work per Hausdorff-distance iteration. | `apps/X-HD/src/hd_impl/hausdorff_distance_rt.h` |

## Timer Source Locator

Paths in this table are relative to the root of each application submodule. Line numbers refer to the source revisions used when this note was written.

| Application | BVH Build Timer Location | RT Compute Timer Location |
|---|---|---|
| `LibRTS` | `RTSpatial/include/rtspatial/spatial_index.cuh:179-187`, `RTSpatial/include/rtspatial/spatial_index.cuh:201`; collected in `RTSpatial/benchmark/rtspatial_query_benchmark.cu:350`, `RTSpatial/benchmark/rtspatial_query_benchmark.cu:416` | `RTSpatial/include/rtspatial/spatial_index.cuh:399-402`, `RTSpatial/include/rtspatial/spatial_index.cuh:462-465`, `RTSpatial/include/rtspatial/spatial_index.cuh:499-502`, `RTSpatial/include/rtspatial/spatial_index.cuh:542-547`, `RTSpatial/include/rtspatial/spatial_index.cuh:593-599`; collected in `RTSpatial/benchmark/rtspatial_query_benchmark.cu:361`, `RTSpatial/benchmark/rtspatial_query_benchmark.cu:428` |
| `Mochi-DCD` | `src/s23-3Dparticlesim/hostCode.cu:261-270`; `src/s19-3Dparticlesim-rotate/hostCode.cu:264-273` | `src/s23-3Dparticlesim/hostCode.cu:441-446`; `src/s19-3Dparticlesim-rotate/hostCode.cu:464-469`, `src/s19-3Dparticlesim-rotate/hostCode.cu:496-501` |
| `RT-BarnesHut` | `samples/cmdline/s01-rtbarneshut/hostCode.cu:429-473` | `samples/cmdline/s01-rtbarneshut/hostCode.cu:552-567` |
| `RT-DBSCAN` | `samples/cmdline/s02-rtdbscan/hostCode.cpp:247-261` | `samples/cmdline/s02-rtdbscan/hostCode.cpp:350-360` |
| `RTNN` | `src/optixNSearch/optix.cpp:307-317` | `src/optixNSearch/optix.cpp:628-650` |
| `RTOD` | `src/ods/optixScan.cpp:1112-1121` | `src/ods/optixScan.cpp:778-787`, called from `src/ods/optixScan.cpp:1123-1127` |
| `RTSpMSpM` | `optixSpMSpM/src/optixSpMSpM/optixSpMSpM.cpp:303-304` | `optixSpMSpM/src/optixSpMSpM/optixSpMSpM.cpp:686-693` |
| `RTTC` | `tc/rt_tc/rt_tc.cpp:32-34`; underlying build in `tc/rt_tc/rt_base.cpp:270` | `tc/rt_tc/rt_tc.cpp:55-68` |
| `RayDB` | `src/raydb/raydb.cpp:430-451` | `src/raydb/raydb.cpp:804-836` |
| `RayJoin` | `src/core/run_overlay_native_benchmark.cu:58-65`; also `src/core/run_overlay_native.cu:81-88` | LSI strict render timer in `src/core/lsi_rt_native.h:56-65`; PIP strict render timer in `src/core/pip_rt_natve.h:67-74`; benchmark phase labels in `src/core/run_overlay_native_benchmark.cu:63-71` |
| `X-HD` | `src/hd_impl/hausdorff_distance_rt.h:455-469`; value recorded at `src/hd_impl/hausdorff_distance_rt.h:200-204` | `src/hd_impl/hausdorff_distance_rt.h:340-348`; value recorded at `src/hd_impl/hausdorff_distance_rt.h:376-379` |

## Ray Semantics

This table records what one launched ray represents in each application. Use this when interpreting ray-throughput columns such as `ray_throughput(krays/s)`, `lsi_ray_throughput(krays/s)`, and `pip_ray_throughput(krays/s)`.

| Application / Mode | One Ray Corresponds To | Purpose Of The Ray |
|---|---|---|
| `LibRTS` point-contains | One query point. | Traverse geometry envelope AABBs to find which indexed geometry contains the point. |
| `LibRTS` range-contains | One query range/window. | Traverse indexed geometry envelopes to find geometries contained by the query range. |
| `LibRTS` range-intersects | One query range/window. | Traverse indexed geometry envelopes to find geometries intersecting the query range. |
| `Mochi-DCD` | One particle or particle-pair probe, depending on the benchmark variant. | Traverse particle AABBs to detect collisions or close-contact candidates. |
| `RT-BarnesHut` | One simulated body/particle. | Traverse Barnes-Hut node geometry to accumulate approximate force contributions. |
| `RT-DBSCAN` | One input point. | Traverse neighboring point-sphere AABBs to count neighbors and decide whether the point is a core point. |
| `RTNN` | One query point. | Traverse point AABBs to search for the nearest neighbor or nearest-neighbor candidates. |
| `RTOD` | One active sliding-window point/query. | Traverse window point AABBs to detect whether the point is an outlier under the configured neighborhood rule. |
| `RTSpMSpM` | One sparse-matrix row/structure query, as launched by the SpMSpM OptiX kernel. | Traverse sparse nonzero AABBs to find structural intersections contributing to sparse matrix multiplication. |
| `RTTC` | One graph edge/triangle-counting query primitive. | Traverse graph-edge triangle geometry to count triangle-closing intersections. |
| `RayDB` | One encoded query predicate probe. | Traverse record/predicate geometry to evaluate database query matches. |
| `RayJoin-LSI` | One line segment from the query map. | Find intersections between that segment and line segments in the other map. |
| `RayJoin-PIP` | One point/vertex from one map. | Locate which polygon in the other map contains that point. |
| `X-HD` | One source-set point/grid-cell query, depending on the active Hausdorff iteration. | Traverse grid-cell MBR AABBs to find nearest-distance candidates for Hausdorff-distance computation. |

## Notes

- `RT-DBSCAN` still stores the original `build_time_s` and `core_points_time_s` columns for compatibility, but the standardized columns are converted to milliseconds.
- `RayJoin` does not currently expose a lower-level strict `optixAccelBuild` timer in the result path. `Build Index` is therefore used as the benchmark-level BVH construction proxy, and the standardized column clarifies that the underlying RT index is built from line-segment-group AABBs.
- `LibRTS` names the build phase `Loading Time` in the original output. In the RTSpatial standalone benchmark this corresponds to repeated `SpatialIndex::Insert` timing over geometry envelope AABBs.
- Detailed non-RT timing columns remain in result CSVs for backward compatibility, but the general-purpose RT Core analysis should use only the two standardized columns.
