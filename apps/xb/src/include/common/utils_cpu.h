#ifndef X_BLOSSOM_UTILS_CPU_H
#define X_BLOSSOM_UTILS_CPU_H
#include <fstream>
#include <string>

#include "utils/types_cpu.h"
#include "utils/utils_cpu.h"

static auto ReadFileIntoHVector(const std::string& filename) -> HVector<index_t> {
  std::vector<index_t> vec;
  std::ifstream file(filename);
  if (!file) {
    std::cerr << "Error opening file: " << filename << std::endl;
  }
  else {
    index_t value;
    while (file >> value) {
      vec.push_back(value);
    }
    file.close();
  }
  return vec;
}

#endif //X_BLOSSOM_UTILS_CPU_H
