#ifndef SIMD_STATS_H
#define SIMD_STATS_H

#include <cstddef>

namespace simdstats {

struct MinMax {
  double min;
  double max;
};

struct MinMaxIndex {
  double min;
  double max;
  size_t minIndex;
  size_t maxIndex;
};

MinMax findMinMax(const double *data, size_t n);
MinMaxIndex findMinMaxIndex(const double *data, size_t n);
const char *backendName();

} // namespace simdstats

#endif // SIMD_STATS_H
