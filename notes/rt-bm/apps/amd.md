# AMD A-App Performance Issues

This note tracks known AMD-port performance issues for `A-*` apps and the fixes or current status.

| A-app | Performance issue | Solution or current status |
|---|---|---|
| `A-RayJoin` | Early HIP port had unacceptable PIP performance compared with the NVIDIA RayJoin path; LSI was close, but PIP showed a large gap. | Keep the AMD implementation on HIPRT/RT-core traversal, remove non-RT fallback paths, use the HIPRT custom-intersection shader path, and align AABB grouping logic with RayJoin so Map0/Map1 behavior is balanced. |
| `A-X-HD` | Initial HIPRT version was about `10x+` slower on several graphics datasets because HIPRT custom-intersection callback pressure was much higher than OptiX payload-register traversal. | Use `hiprtGeomCustomTraversalClosestCustomStack`, match X-HD ray extent with `FLT_MIN`, and tune the HIPRT AABB cost model to use a coarser grid (`cycles_aabb = 153600`) to reduce callback pressure. |
| `A-LibRTS` | No resolved AMD-specific performance issue recorded yet. | Needs profiling against `LibRTS` on the A-card/N-card pair before tuning. |
| `A-Mochi-DCD` | No resolved AMD-specific performance issue recorded yet. | Needs profiling against `Mochi-DCD` on the A-card/N-card pair before tuning. |
| `A-RT-BarnesHut` | No resolved AMD-specific performance issue recorded yet. | Needs profiling against `RT-BarnesHut` on the A-card/N-card pair before tuning. |
| `A-RT-DBSCAN` | No resolved AMD-specific performance issue recorded yet. | Needs profiling against `RT-DBSCAN` on the A-card/N-card pair before tuning. |
| `A-RTCollisionDetection` | No resolved AMD-specific performance issue recorded yet. | Needs profiling against `RTCollisionDetection` on the A-card/N-card pair before tuning. |
| `A-RTNN` | No resolved AMD-specific performance issue recorded yet. | Needs profiling against `RTNN` on the A-card/N-card pair before tuning. |
| `A-RTOD` | No resolved AMD-specific performance issue recorded yet. | Needs profiling against `RTOD` on the A-card/N-card pair before tuning. |
| `A-RTSpMSpM` | No resolved AMD-specific performance issue recorded yet. | Needs profiling against `RTSpMSpM` on the A-card/N-card pair before tuning. |
| `A-RTTC` | No resolved AMD-specific performance issue recorded yet. | Needs profiling against `RTTC` on the A-card/N-card pair before tuning; RTTC is already considered weak for the main suite on large datasets. |
| `A-RayDB` | No resolved AMD-specific performance issue recorded yet. | Needs profiling against `RayDB` on the A-card/N-card pair before tuning. |
