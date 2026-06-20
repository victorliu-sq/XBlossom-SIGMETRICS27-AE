#include "xblsm_cpu/xblsm_cpu.h"
#include "graph/xgraph.h"
#include <glog/logging.h>
#include "xblsm_cpu/xblsm_cpu_pro.h"
#include "xblsm_cpu/xblsm_cpu_config.h"

namespace xblossom {
  void testParBlossom_pro_pernode(Graph &G, std::vector<int> &M, int threshold) {
    duration_prepare = std::chrono::microseconds::zero();
    duration_blossom = std::chrono::microseconds::zero();
    duration_augmenting_path = std::chrono::microseconds::zero();
    duration_expand = std::chrono::microseconds::zero();
    duration_total = std::chrono::microseconds::zero();

    int iteration = 1;
    count = 0;
    int valid_iteration = iteration;

    for (int i = 0; i < iteration; i++) {
      bool valid_M = true;

      auto start_total_f = std::chrono::high_resolution_clock::now();
      auto pre_1 = duration_prepare;
      auto pre_2 = duration_blossom;
      auto pre_3 = duration_augmenting_path;
      auto pre_4 = duration_expand;

      parFindMaximumMatchingNoRecursionUpdatePathTable_pro_pernode(G, M, valid_M, threshold);

      if (!valid_M) {
        duration_prepare = pre_1;
        duration_blossom = pre_2;
        duration_augmenting_path = pre_3;
        duration_expand = pre_4;
        valid_iteration--;
        continue;
      }

      auto end_total_f = std::chrono::high_resolution_clock::now();
      auto period_f = std::chrono::duration_cast<std::chrono::microseconds>(end_total_f - start_total_f);
      duration_total = period_f + duration_total;


      if (i == iteration - 1 || stop_immediately) {
        break;
      }
      M = std::vector<int>(nodes, -1);
    }

    testMatching(M);
  }
}
