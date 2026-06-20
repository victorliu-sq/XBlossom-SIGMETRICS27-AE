#ifndef BLOSSOM_PRO_H
#define BLOSSOM_PRO_H

#include "graph/xgraph.h"
#include <thread>
#include <queue>

namespace xblossom {
  // -------------------------------- XBlossom Pro 1 ------------------------------------------------
  // Edge-Level Parallelism
  void testParBlossom_pro_1(Graph &G, std::vector<int> &M, int &threshold);

  void parFindMaximumMatchingNoRecursionUpdatePathTable_pro_1(Graph &G, std::vector<int> &M, bool &valid_M,
                                                              int &threshold);

  void parFindAugmentingPathNoRecursionUpdatePathTable_pro_1(Graph &G, std::vector<int> &M,
                                                             std::vector<std::vector<int> > &path_collection,
                                                             std::vector<std::vector<int> > &path_table_vector);




  // Precompute (v,w) endpoints for each edge in the frontier
  // static inline void build_edge_endpoints(const std::vector<int> &rowOffsets,
  //                                         const std::vector<int> &columnIndices,
  //                                         const std::vector<int> &nodes_vector,
  //                                         const std::vector<int> &edge_offsets,
  //                                         std::vector<int> &v_vector,
  //                                         std::vector<int> &w_vector) {
  //   int total_edges = edge_offsets.back();
  //   v_vector.resize(total_edges);
  //   w_vector.resize(total_edges);
  //
  //   for (size_t i = 0; i < nodes_vector.size(); i++) {
  //     int v = nodes_vector[i];
  //     int start = edge_offsets[i];
  //     int end = edge_offsets[i + 1];
  //
  //     for (int eid = start; eid < end; eid++) {
  //       int offset_in_v = eid - start;
  //       int w = columnIndices[rowOffsets[v] + offset_in_v];
  //       v_vector[eid] = v;
  //       w_vector[eid] = w;
  //     }
  //   }
  // }
  void parAugmentingPath_pro_edges(const std::vector<int> &v_vector,
                                   const std::vector<int> &w_vector,
                                   int start_edge, int end_edge,
                                   std::vector<int> &is_even,
                                   std::vector<int> &belongs,
                                   std::vector<std::vector<int> > &path_table_vector,
                                   std::vector<std::atomic<int> > &select_tree,
                                   std::vector<std::vector<int> > &path_collection);

  void parExpand_pro_edges(const std::vector<int> &v_vector,
                           const std::vector<int> &w_vector,
                           int start_edge, int end_edge,
                           std::vector<int> &is_even,
                           std::vector<int> &belongs,
                           std::vector<std::vector<int> > &path_table_vector,
                           std::vector<int> &vector_1,
                           std::vector<std::atomic<int> > &select_match,
                           std::vector<int> &M);

  void parBlossom_pro_edges(const std::vector<int> &v_vector,
                            const std::vector<int> &w_vector,
                            int start_edge, int end_edge,
                            std::vector<int> &is_even,
                            std::vector<int> &belongs,
                            std::vector<std::vector<int> > &path_table_vector,
                            std::vector<int> &vector_2,
                            std::vector<std::atomic<int> > &select_blossom,
                            std::vector<int> &blossom_to_base,
                            std::vector<int> &M);


  void parAugmentingPath_pro_edges_na(const std::vector<int> &v_vector,
                                   const std::vector<int> &w_vector,
                                   int start_edge, int end_edge,
                                   std::vector<int> &is_even,
                                   std::vector<int> &belongs,
                                   std::vector<std::vector<int> > &path_table_vector,
                                   std::vector<std::atomic<int> > &select_tree,
                                   std::vector<std::vector<int> > &path_collection);

  void parExpand_pro_edges_na(const std::vector<int> &v_vector,
                           const std::vector<int> &w_vector,
                           int start_edge, int end_edge,
                           std::vector<int> &is_even,
                           std::vector<int> &belongs,
                           std::vector<std::vector<int> > &path_table_vector,
                           std::vector<int> &vector_1,
                           std::vector<std::atomic<int> > &select_match,
                           std::vector<int> &M);

  void parBlossom_pro_edges_na(const std::vector<int> &v_vector,
                            const std::vector<int> &w_vector,
                            int start_edge, int end_edge,
                            std::vector<int> &is_even,
                            std::vector<int> &belongs,
                            std::vector<std::vector<int> > &path_table_vector,
                            std::vector<int> &vector_2,
                            std::vector<std::atomic<int> > &select_blossom,
                            std::vector<int> &blossom_to_base,
                            std::vector<int> &M);

  // -------------------------------- XBlossom Pro 2 ------------------------------------------------
  // Reuse alternating trees
  void testParBlossom_pro_2(Graph &G, std::vector<int> &M, int &threshold);

  void parFindMaximumMatchingNoRecursionUpdatePathTable_pro_2(Graph &G, std::vector<int> &M, bool &valid_M,
                                                              int &threshold);

  // void parFindAugmentingPathNoRecursionUpdatePathTable_pro_2(Graph &G, std::vector<int> &M,
  //                                                          std::vector<std::vector<int> > &path_collection,
  //                                                          std::vector<std::vector<int> > &path_table_vector);

  void parFindAugmentingPathNoRecursionUpdatePathTable_pro_2(Graph &G,
                                                             std::vector<int> &M,
                                                             std::vector<std::vector<int> > &path_collection,
                                                             std::vector<std::vector<int> > &path_table_vector,
                                                             std::vector<int> &is_even,
                                                             std::vector<int> &belongs);

  // -------------------------------- XBlossom Pro 3 ------------------------------------------------
  // On-the-flay Blossom Base Detection
  void testParBlossom_pro_3(Graph &G,
                            std::vector<int> &M,
                            int &threshold);

  void parFindMaximumMatchingNoRecursionUpdatePathTable_pro_3(Graph &G,
                                                              std::vector<int> &M, bool &valid_M,
                                                              int &threshold);

  void parFindAugmentingPathNoRecursionUpdatePathTable_pro_3(Graph &G,
                                                             std::vector<int> &M,
                                                             std::vector<std::vector<int> > &path_collection,
                                                             std::vector<std::vector<int> > &path_table_vector);

  // -------------------------------- XBlossom Pro All / Per Node ------------------------------------------------
  // 2 + 3: Reuse Alternating Trees + On the Fly Detection
  void testParBlossom_pro_pernode(Graph &G,
                                  std::vector<int> &M,
                                  int threshold);

  void parFindMaximumMatchingNoRecursionUpdatePathTable_pro_pernode(Graph &G,
                                                                    std::vector<int> &M,
                                                                    bool &valid_M,
                                                                    int threshold);

  void parFindAugmentingPathNoRecursionUpdatePathTable_pernode(Graph &G,
                                                                std::vector<int> &M,
                                                                std::vector<std::vector<int> > &path_collection,
                                                                std::vector<std::vector<int> > &path_table_vector,
                                                                std::vector<int> &is_even,
                                                                std::vector<int> &belongs);

  // -------------------------------- XBlossom Pro PerNode-NoBlossom -----------------------------
  // pernode + no blossom
  void testParBlossom_pro_pernode_nb(Graph &G,
                                  std::vector<int> &M,
                                  int threshold);

  void parFindMaximumMatchingNoRecursionUpdatePathTable_pro_pernode_nb(Graph &G,
                                                                    std::vector<int> &M,
                                                                    bool &valid_M,
                                                                    int threshold);

  void parFindAugmentingPathNoRecursionUpdatePathTable_pernode_nb(Graph &G,
                                                                std::vector<int> &M,
                                                                std::vector<std::vector<int> > &path_collection,
                                                                std::vector<std::vector<int> > &path_table_vector,
                                                                std::vector<int> &is_even,
                                                                std::vector<int> &belongs);



  // -------------------------------- XBlossom Pro PerNode-NoAtomic-----------------------------
  // pernode + no blossom
  void testParBlossom_pro_pernode_na(Graph &G,
                                  std::vector<int> &M,
                                  int threshold);

  void parFindMaximumMatchingNoRecursionUpdatePathTable_pro_pernode_na(Graph &G,
                                                                    std::vector<int> &M,
                                                                    bool &valid_M,
                                                                    int threshold);

  void parFindAugmentingPathNoRecursionUpdatePathTable_pernode_na(Graph &G,
                                                                std::vector<int> &M,
                                                                std::vector<std::vector<int> > &path_collection,
                                                                std::vector<std::vector<int> > &path_table_vector,
                                                                std::vector<int> &is_even,
                                                                std::vector<int> &belongs);

  // -------------------------------- XBlossom Pro PerNode-NoAtomic NoBlossom ---------------------------
  // pernode + no blossom
  void testParBlossom_pro_pernode_nab(Graph &G,
                                  std::vector<int> &M,
                                  int threshold);

  void parFindMaximumMatchingNoRecursionUpdatePathTable_pro_pernode_nab(Graph &G,
                                                                    std::vector<int> &M,
                                                                    bool &valid_M,
                                                                    int threshold);

  void parFindAugmentingPathNoRecursionUpdatePathTable_pernode_nab(Graph &G,
                                                                std::vector<int> &M,
                                                                std::vector<std::vector<int> > &path_collection,
                                                                std::vector<std::vector<int> > &path_table_vector,
                                                                std::vector<int> &is_even,
                                                                std::vector<int> &belongs);

  // -------------------------------- XBlossom Pro All Per Edge ------------------------------------------------
  void testParBlossom_pro_peredge(Graph &G,
                                  std::vector<int> &M,
                                  int &threshold);

  void parFindMaximumMatchingNoRecursionUpdatePathTable_pro_peredge(Graph &G,
                                                                    std::vector<int> &M,
                                                                    bool &valid_M,
                                                                    int &threshold);

  void parFindAugmentingPathNoRecursionUpdatePathTable_pro_peredge(Graph &G,
                                                                   std::vector<int> &M,
                                                                   std::vector<std::vector<int> > &path_collection,
                                                                   std::vector<std::vector<int> > &path_table_vector,
                                                                   std::vector<int> &is_even,
                                                                   std::vector<int> &belongs);

  // -------------------------------- XBlossom Pro All Per Edge No Atomic ------------------------------------
  void testParBlossom_pro_peredge_na(Graph &G,
                                  std::vector<int> &M,
                                  int &threshold);

  void parFindMaximumMatchingNoRecursionUpdatePathTable_pro_peredge_na(Graph &G,
                                                                    std::vector<int> &M,
                                                                    bool &valid_M,
                                                                    int &threshold);

  void parFindAugmentingPathNoRecursionUpdatePathTable_pro_peredge_na(Graph &G,
                                                                   std::vector<int> &M,
                                                                   std::vector<std::vector<int> > &path_collection,
                                                                   std::vector<std::vector<int> > &path_table_vector,
                                                                   std::vector<int> &is_even,
                                                                   std::vector<int> &belongs);


  // -------------------------------- XBlossom Pro All Per Edge Blossom------------------------------------
  void testParBlossom_pro_peredge_nb(Graph &G,
                                  std::vector<int> &M,
                                  int &threshold);

  void parFindMaximumMatchingNoRecursionUpdatePathTable_pro_peredge_nb(Graph &G,
                                                                    std::vector<int> &M,
                                                                    bool &valid_M,
                                                                    int &threshold);

  void parFindAugmentingPathNoRecursionUpdatePathTable_pro_peredge_nb(Graph &G,
                                                                   std::vector<int> &M,
                                                                   std::vector<std::vector<int> > &path_collection,
                                                                   std::vector<std::vector<int> > &path_table_vector,
                                                                   std::vector<int> &is_even,
                                                                   std::vector<int> &belongs);

  // -------------------------------- XBlossom Pro All Atomic ------------------------------------------------
  // use atomicEx => no effectiveness
  void testParBlossom_pro_all_atomic(Graph &G,
                                     std::vector<int> &M,
                                     int threshold);

  void parFindMaximumMatchingNoRecursionUpdatePathTable_pro_all_atomic(Graph &G,
                                                                       std::vector<int> &M,
                                                                       bool &valid_M,
                                                                       int threshold);

  void parFindAugmentingPathNoRecursionUpdatePathTable_pro_all_atomic(Graph &G,
                                                                      std::vector<int> &M,
                                                                      std::vector<std::vector<int> > &path_collection,
                                                                      std::vector<std::vector<int> > &path_table_vector,
                                                                      std::vector<int> &is_even,
                                                                      std::vector<int> &belongs);
}

#endif //BLOSSOM_PRO_H
