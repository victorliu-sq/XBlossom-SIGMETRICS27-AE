#ifndef X_BLOSSOM_DEVICE_GRAPH_H
#define X_BLOSSOM_DEVICE_GRAPH_H

#include "hgraph_gpu.h"
#include "common/utils_gpu.h"
#include "utils/utils_gpu.h"
#include "adjlists.h"

namespace zblossom {
  // Interface
  struct DGraphView {
    size_t nnodes, nedges;
    index_t* col_indices;
    index_t* row_offsets;
  };

  // Wrapper
  struct DGraph {
    size_t nnodes = 0;
    size_t nedges = 0;
    DVector<index_t> device_col_indices_vector;
    DVector<index_t> device_row_offsets_vector;

    DGraph() = delete;

    // Init DGraph from Adjacent Lists (Synthetic Datasets)
    explicit DGraph(const AdjLists& adjLists) {
      HVector<index_t> col_indices_vector;
      HVector<index_t> row_offsets_vector;
      adjLists.BuildCSR(nnodes, nedges, col_indices_vector, row_offsets_vector);
      device_col_indices_vector = col_indices_vector;
      device_row_offsets_vector = row_offsets_vector;
    }

    // Init DGraph from Files (Realworld Datasets)
    explicit DGraph(const std::string& filepath_row_offsets, const std::string& filepath_col_indices) {
      HVector<index_t> col_indices_vector;
      HVector<index_t> row_offsets_vector;
      col_indices_vector.clear();
      row_offsets_vector.clear();

      col_indices_vector = ReadFileIntoHVector(filepath_col_indices);
      row_offsets_vector = ReadFileIntoHVector(filepath_row_offsets);

      this->nnodes = row_offsets_vector.size() - 1;
      this->nedges = col_indices_vector.size() / 2;
    }

    // Constructor From Host Graph
    DGraph(const HGraph& host_graph) {
      // Initialize the base struct
      nnodes = host_graph.nnodes;
      nedges = host_graph.nedges;

      device_col_indices_vector.resize(nedges);
      device_row_offsets_vector.resize(nnodes + 1);

      // Explicit copy from host (CPU) to device (GPU)
      // device_col_indices_vector = host_graph.col_indices_vector;
      // device_row_offsets_vector = host_graph.row_offsets_vector;
      device_col_indices_vector = host_graph.GetColIndicesVector();
      device_row_offsets_vector = host_graph.GetRowOffsetsVector();
    }

    DGraphView DeviceView() {
      return DGraphView{
        nnodes, nedges, device_col_indices_vector.data().get(), device_row_offsets_vector.data().get()
      };
    }

    // Copy From Host Graph
    DGraph(HGraph&& host_graph) = delete;

    // remove Copy Constructor
    DGraph(const DGraph& graph) = delete;
    DGraph& operator=(const DGraph& graph) = delete;

    // Move Constructor
    DGraph(DGraph&& graph) noexcept {
      if (this != &graph) {
        nnodes = graph.nnodes;
        nedges = graph.nedges;

        device_col_indices_vector = std::move(graph.device_col_indices_vector);
        device_row_offsets_vector = std::move(graph.device_row_offsets_vector);
      }
    }

    // Move Assignment Operator
    DGraph& operator=(DGraph&& graph) noexcept {
      if (this != &graph) {
        nnodes = graph.nnodes;
        nedges = graph.nedges;

        device_col_indices_vector = std::move(graph.device_col_indices_vector);
        device_row_offsets_vector = std::move(graph.device_row_offsets_vector);
      }
      return *this;
    }
  };
}

#endif //X_BLOSSOM_DEVICE_GRAPH_H
