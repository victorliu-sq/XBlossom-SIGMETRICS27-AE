# LibRTS Paper Figure Coverage

`expr/benchmark/LibRTS/run_benchmark.sh` runs only the standalone RTSpatial/LibRTS measurements for a subset of the paper figures. It does not reproduce full figures because it skips baseline systems such as Boost R-tree, CGAL, cuSpatial, GLIN, and LBVH.

## Covered Measurements

### `run_point_query_contains`

- Query type: `point-contains`
- Query count: `100000`
- Paper mapping: Figure 6(a), query time of 100K point queries
- Scope: only the `rtspatial` series

### `run_range_query_contains`

- Query type: `range-contains`
- Query count: `100000`
- Paper mapping: Figure 7(a), query time of 100K range-contains queries
- Scope: only the `rtspatial` series

### `run_range_query_intersects_selectivity_001`

- Query type: `range-intersects`
- Selectivity: `0.001`
- Query count: `10000`
- Paper mapping: Figure 8(b), range-intersects query time at 0.1% selectivity
- Scope: only the `rtspatial` series

## Not Covered

The current script does not run:

- Figure 8(a), range-intersects at selectivity `0.0001`
- Figure 8(c), range-intersects at selectivity `0.01`
- Figure 8(d), range-intersects with varying query size
- Varying-query-size experiments for Figures 6(b) and 7(b)
- Index construction, update, scalability, PIP, or ray-multicast experiments
- Any baseline systems needed to reproduce full paper figures

## Output Location

The script writes benchmark logs under:

```text
apps/LibRTS/expr/query/logs_rtspatial_standalone/
```

In this benchmark repo, the current LibRTS run should be treated as a partial RTSpatial-only reproduction for Figures 6(a), 7(a), and 8(b).
