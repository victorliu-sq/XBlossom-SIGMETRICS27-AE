#ifndef X_BLOSSOM_ADJLISTS_H
#define X_BLOSSOM_ADJLISTS_H

#include <unordered_map>
#include <unordered_set>
#include <vector>
#include "utils/types_cpu.h"

namespace zblossom {
  class AdjLists {
  public:
    AdjLists() = default;
    // Add an edge
    void AddEdge(int srcLabel, int destLabel) {
      mapping[srcLabel].push_back(destLabel);
      mapping[destLabel].push_back(srcLabel);
    }

    void BuildCSR(size_t& nnodes, size_t& nedges, HVector<index_t>& col_indices, HVector<index_t>& row_offsets) const {
      row_offsets.clear();
      col_indices.clear();
      row_offsets.push_back(0);

      nnodes = mapping.size();
      int edge_offset = 0;
      // for (int i = 0; i < nnodes; ++i) {
      //   if (mapping.find(i) != mapping.end()) {
      //     for (int neighbor : mapping[i]) {
      //       col_indices.push_back(neighbor);
      //       edge_offset++;
      //     }
      //   }
      //   row_offsets.push_back(edge_offset);
      // }
      for (int i = 0; i < static_cast<int>(nnodes); ++i) {
        auto it = mapping.find(i);
        if (it != mapping.end()) {
          for (int neighbor : it->second) {
            col_indices.push_back(neighbor);
            edge_offset++;
          }
        }
        row_offsets.push_back(edge_offset);
      }

      nedges = edge_offset / 2;
    }

  private:
    std::unordered_map<int, std::vector<int>> mapping; // Adjacency lists with label as key
  };

}


#endif //X_BLOSSOM_ADJLISTS_H
