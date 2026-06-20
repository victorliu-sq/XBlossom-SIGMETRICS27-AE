# Gunrock BC First-Source Crash

## Symptom

During the four-algorithm remote GPU runtime experiment, Gunrock BC sometimes
crashed when using the first generated source node from the dataset source list.
The failure looked like this:

```text
terminate called after throwing an instance of 'mgpu::cuda_exception_t'
what(): an illegal memory access was encountered
```

The crash appeared in BC, not in BFS or SSSP.

## Original Root Cause

The crash came from the BC implementation's use of the old `merge_path` advance
load balancer:

```cpp
operators::advance::execute<operators::load_balance_t::merge_path, ...>
```

That path uses the older ModernGPU merge-path implementation and can hit illegal
memory accesses for some BC frontier shapes.

## Earlier Workaround

Use Gunrock's newer `merge_path_v2` advance implementation for both BC forward
and backward advance phases:

```cpp
operators::advance::execute<operators::load_balance_t::merge_path_v2, ...>
```

This kept BC's source-node behavior unchanged while avoiding the failing
ModernGPU path, but it made BC use a different load-balancing strategy from
Gunrock BFS and SSSP.

## Current Fix

BC now uses `block_mapped`, matching Gunrock BFS and SSSP:

```cpp
operators::advance::execute<operators::load_balance_t::block_mapped, ...>
```

The additional fix is in BC's phase transition. The forward phase used to leave
`depth` pointing at the empty frontier that terminates the search. That was
tolerated by `merge_path_v2`, but `block_mapped` tried to launch work for this
empty backward frontier and failed. BC now decrements `depth` when forward
converges, so the backward phase starts from the last non-empty BFS level.

## Source Selection

Do not hide the crash by skipping the first source node or probing multiple
source nodes in the benchmark script. BC, BFS, and SSSP should all use the first
source node selected by:

```bash
SRC="$(first_source_node "$SRC_FILE")"
```

The source-selection logic should stay the same across Gunrock algorithms. The
fix belongs in Gunrock BC's implementation, not in benchmark source selection.

## Validation

After switching BC to `block_mapped` and fixing the backward starting depth,
local Gunrock BC runs completed with the first source node on all benchmark
datasets. `compute-sanitizer --tool memcheck` also reported no errors on
Amazon.
