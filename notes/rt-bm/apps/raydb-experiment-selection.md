# RayDB Experiment Selection

For RT-Benchmark, start with **Figure 12(c): RayDB query execution time on SSB flat, SF=20**.

## Why Figure 12(c)

Our current packaged RayDB dataset is generated at **SF=20** only:

```text
data/RayDB/ssb_data
```

It contains the 13 SSB-flat query inputs used by RayDB:

```text
q11 q12 q13
q21 q22 q23
q31 q32 q33 q34
q41 q42 q43
```

These map to:

```text
q1dot1 q1dot2 q1dot3
q2dot1 q2dot2 q2dot3
q3dot1 q3dot2 q3dot3 q3dot4
q4dot1 q4dot2 q4dot3
```

Figures 12(a) and 12(b) require SF=1 and SF=10 datasets, which we do not currently package.

## Meaning of SF

`SF` means **scale factor** in Star Schema Benchmark.

It controls dataset size:

```text
SF=1   small dataset
SF=10  about 10x SF=1
SF=20  about 20x SF=1
```

In the RayDB paper, SF=20 produces about 120 million tuples in the flattened SSB table.

## Figure 15

Figure 15 reports BVH construction time.

We do not need a separate run for this if RayDB logs both query and BVH timings during each query run. The current binary prints timing lines such as:

```text
[Time] Build BVH: ...
[Time] Launch(Prepare included): ...
[Time] Launch: ...
```

So one run over the 13 SF=20 queries can collect both Figure 12(c)-style query timing and Figure 15-style BVH build timing.
