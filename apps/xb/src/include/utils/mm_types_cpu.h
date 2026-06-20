#ifndef MM_TYPES_CPU_H
#define MM_TYPES_CPU_H

#include "cpp_types.h"
#include "graph/hgraph.h"
#include "graph/xgraph.h"

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

#endif //MM_TYPES_CPU_H
