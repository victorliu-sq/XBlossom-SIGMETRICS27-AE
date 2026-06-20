#ifndef MM_TYPES_GPU_H
#define MM_TYPES_GPU_H

#include "cpp_types.h"
#include "graph/hgraph_gpu.h"
#include "graph/xgraph.h"
#include "graph/dgraph.h"

using Matching = Vector<index_t>;
using AugPath = Vector<index_t>;
using AtomicLock = std::atomic<bool>;

struct VWPair {
  index_t v;
  index_t w;
};

using xgraph_t = xblossom::Graph;
using zgraph_t = zblossom::HGraph;
using host_graph_t = zblossom::HGraph;
using device_graph_t = zblossom::DGraph;

#endif //MM_TYPES_GPU_H
