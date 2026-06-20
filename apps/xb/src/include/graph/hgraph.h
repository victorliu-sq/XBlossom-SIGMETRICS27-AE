#ifndef X_BLOSSOM_HOST_GRAPH_H
#define X_BLOSSOM_HOST_GRAPH_H

#include <fstream>
#include "common/utils_cpu.h"
#include "utils/utils_cpu.h"
#include "graph/adjlists.h"

namespace zblossom {
  // Interface for HostGraph
  struct AbsCsrGraph {
    size_t nnodes, nedges;
    index_t* col_indices;
    index_t* row_offsets;

    // Default Constructor
    AbsCsrGraph() : nnodes(0), nedges(0), col_indices(nullptr), row_offsets(nullptr) {}

    AbsCsrGraph(size_t nnodes, size_t nedges, index_t* col_indices, index_t* row_offsets) : nnodes(nnodes),
      nedges(nedges),
      col_indices(col_indices),
      row_offsets(row_offsets) {}
  };

  // RAII Wrapper for HGraph
  class HGraph : public AbsCsrGraph {
  public:
    HGraph() = default;

    // Init From Synthetic Datasets
    explicit HGraph(AdjLists& adjLists) {
      adjLists.BuildCSR(this->nnodes, this->nedges, this->col_indices_vector, this->row_offsets_vector);
      this->BindPointers();
    }

    // Init From RealWorld Datasets
    HGraph(const std::string& filepath_row_offsets, const std::string& filepath_col_indices) {
      this->col_indices_vector.clear();
      this->row_offsets_vector.clear();

      this->col_indices_vector = ReadFileIntoHVector(filepath_col_indices);
      this->row_offsets_vector = ReadFileIntoHVector(filepath_row_offsets);

      this->nnodes = row_offsets_vector.size() - 1;
      this->nedges = col_indices_vector.size() / 2;

      this->BindPointers();
    }

    // Delete Copy Constructor
    HGraph(const HGraph& graph) = delete;

    // Delete Copy Assignment
    HGraph& operator=(const HGraph& graph) = delete;

    // Move Constructor
    HGraph(HGraph&& graph) noexcept {
      if (this != &graph) {
        nnodes = graph.nnodes;
        nedges = graph.nedges;

        col_indices_vector = std::move(graph.col_indices_vector);
        row_offsets_vector = std::move(graph.row_offsets_vector);

        BindPointers();
      }
    }

    // Move Assignment
    HGraph& operator=(HGraph&& graph) noexcept {
      if (this != &graph) {
        nnodes = graph.nnodes;
        nedges = graph.nedges;

        col_indices_vector = std::move(graph.col_indices_vector);
        row_offsets_vector = std::move(graph.row_offsets_vector);

        BindPointers();
      }
      return *this;
    }

    friend std::ostream& operator<<(std::ostream& os, const HGraph& graph);

    const HVector<index_t>& GetColIndicesVector() const { return col_indices_vector; }
    const HVector<index_t>& GetRowOffsetsVector() const { return row_offsets_vector; }

  private:
    HVector<index_t> col_indices_vector;
    HVector<index_t> row_offsets_vector;


    void BindPointers() {
      col_indices = col_indices_vector.data();
      row_offsets = row_offsets_vector.data();
    }
  };

  inline std::ostream& operator<<(std::ostream& os, const HGraph& graph) {
    os << "HGraph Summary:\n";
    os << "  Nodes: " << graph.nnodes << "\n";
    os << "  Edges: " << graph.nedges << "\n";
    os << "  Row Offsets (" << graph.row_offsets_vector.size() << "): [";
    for (size_t i = 0; i < graph.row_offsets_vector.size(); ++i) {
      os << graph.row_offsets_vector[i];
      if (i + 1 < graph.row_offsets_vector.size()) os << ", ";
    }
    os << "]\n";

    os << "  Column Indices (" << graph.col_indices_vector.size() << "): [";
    for (size_t i = 0; i < graph.col_indices_vector.size(); ++i) {
      os << graph.col_indices_vector[i];
      if (i + 1 < graph.col_indices_vector.size()) os << ", ";
    }
    os << "]\n";

    return os;
  }
}

#endif //X_BLOSSOM_HOST_GRAPH_H
