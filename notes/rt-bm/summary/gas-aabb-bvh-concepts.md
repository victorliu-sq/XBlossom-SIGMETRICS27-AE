# GAS, AABB, and BVH

In OptiX benchmark notes and result columns, these terms are related but not identical.

`AABB` means axis-aligned bounding box. For custom primitives, the application provides OptiX with one AABB per primitive. For example, RTNN represents points as point-centered AABBs, while some other applications use triangle or segment bounds.

`BVH` means bounding-volume hierarchy. It is the general acceleration-structure concept: a tree of bounding volumes used to skip most primitives during ray traversal.

`GAS` means Geometry Acceleration Structure. It is OptiX's concrete geometry-level acceleration-structure object, created by `optixAccelBuild(...)`. Internally, it is BVH-like and is built over the provided geometry, such as triangles or custom primitive AABBs.

Relationship:

```text
primitives -> AABBs or triangles -> optixAccelBuild(...) -> GAS
                                                       ~= BVH over those primitives
```

For benchmark naming, using `bvh_build_ms` for GAS construction is reasonable because the measured phase is the construction of the OptiX acceleration structure used for BVH-style traversal. The parenthetical part should name the primitive type, for example:

```text
bvh_build_ms (point_aabbs)
bvh_build_ms (graph_edge_triangles)
bvh_build_ms (line_segment_group_aabbs)
```


In OptiX, a GAS is an OptiX acceleration structure for geometry. Internally, it is typically a BVH-like structure built over primitives such as triangles, curves, or custom primitive AABBs.

GAS is not exactly “one type of BVH” in the algorithmic sense; it is an OptiX API object