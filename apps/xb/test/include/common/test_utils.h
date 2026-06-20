#ifndef X_BLOSSOM_TEST_UTILS_H
#define X_BLOSSOM_TEST_UTILS_H

#include "utils/cpp_types.h"
#include "utils/utils_gpu.h"

// Helper methods
static bool ValidateMatchingGPU(Vector<index_t>& M) {
  bool is_valid = true;
  for (int i = 0; i < M.size(); i++) {
    int k = M[i];
    if (k != M.size() && M[k] != i) {
      ADD_FAILURE() << "Mismatch at node " << i << "and " << k << std::endl;
      is_valid = false;
    }
  }

  return is_valid;
}

static bool ValidateMatchingCPU(Vector<index_t>& M) {
  bool is_valid = true;
  for (int i = 0; i < M.size(); i++) {
    int k = M[i];
    if (k != -1 && M[k] != i) {
      ADD_FAILURE() << "Mismatch at node " << i << "and " << k << std::endl;
      is_valid = false;
    }
  }

  return is_valid;
}

// Helper static methods
static size_t GetActualMatchingSizeGPU(Vector<index_t>& M) {
  // Calculate the size of matching
  std::set<std::pair<index_t, index_t>> M_set;
  for (index_t i = 0; i < M.size(); i++) {
    if (M[i] != M.size()) {
      M_set.insert({std::min(i, M[i]), std::max(i, M[i])});
    }
  }
  return M_set.size();
}

static size_t GetActualMatchingSizeCPU(Vector<index_t>& M) {
  // Calculate the size of matching
  std::set<std::pair<index_t, index_t>> M_set;
  for (index_t i = 0; i < M.size(); i++) {
    if (M[i] != -1) {
      M_set.insert({std::min(i, M[i]), std::max(i, M[i])});
    }
  }
  return M_set.size();
}

#endif //X_BLOSSOM_TEST_UTILS_H