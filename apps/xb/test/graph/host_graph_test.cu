#include <gtest/gtest.h>
#include <vector>
#include <iostream>
#include "graph/adjlists.h"
#include "graph/hgraph.h"

using namespace zblossom;

TEST(TestHostGraph, BasicConversionAndIntegrity) {
  // ------------------------------
  // 1. Build a simple undirected graph
  // ------------------------------
  // Graph topology:
  // 0 -- 1 -- 2 -- 3
  // |         /
  // +-------+
  AdjLists adj;
  adj.AddEdge(0, 1);
  adj.AddEdge(1, 2);
  adj.AddEdge(2, 3);
  adj.AddEdge(0, 2);  // diagonal

  // ------------------------------
  // 2. Convert to HostGraph (CSR)
  // ------------------------------
  HGraph hgraph(adj);
  std::cout << hgraph << std::endl;
}
