#include "simd_stats.h"

#include <algorithm>

#if defined(__AVX2__) || defined(__SSE2__)
#include <immintrin.h>
#endif

#if defined(__aarch64__) || defined(__ARM_NEON)
#include <arm_neon.h>
#endif

namespace simdstats {
namespace {

MinMax minMaxScalar(const double *data, size_t n) {
  if (n == 0) {
    return {0.0, 0.0};
  }

  double minValue = data[0];
  double maxValue = data[0];
  for (size_t i = 1; i < n; ++i) {
    minValue = std::min(minValue, data[i]);
    maxValue = std::max(maxValue, data[i]);
  }

  return {minValue, maxValue};
}

#if defined(__AVX2__)
MinMax minMaxAvx2(const double *data, size_t n) {
  if (n < 4) {
    return minMaxScalar(data, n);
  }

  size_t i = 0;
  __m256d vmin = _mm256_loadu_pd(data);
  __m256d vmax = vmin;
  i += 4;

  for (; i + 3 < n; i += 4) {
    const __m256d v = _mm256_loadu_pd(data + i);
    vmin = _mm256_min_pd(vmin, v);
    vmax = _mm256_max_pd(vmax, v);
  }

  alignas(32) double minBuf[4];
  alignas(32) double maxBuf[4];
  _mm256_store_pd(minBuf, vmin);
  _mm256_store_pd(maxBuf, vmax);

  double minValue = minBuf[0];
  double maxValue = maxBuf[0];
  for (int k = 1; k < 4; ++k) {
    minValue = std::min(minValue, minBuf[k]);
    maxValue = std::max(maxValue, maxBuf[k]);
  }

  for (; i < n; ++i) {
    minValue = std::min(minValue, data[i]);
    maxValue = std::max(maxValue, data[i]);
  }

  return {minValue, maxValue};
}
#endif

#if defined(__SSE2__) && !defined(__AVX2__)
MinMax minMaxSse2(const double *data, size_t n) {
  if (n < 2) {
    return minMaxScalar(data, n);
  }

  size_t i = 0;
  __m128d vmin = _mm_loadu_pd(data);
  __m128d vmax = vmin;
  i += 2;

  for (; i + 1 < n; i += 2) {
    const __m128d v = _mm_loadu_pd(data + i);
    vmin = _mm_min_pd(vmin, v);
    vmax = _mm_max_pd(vmax, v);
  }

  alignas(16) double minBuf[2];
  alignas(16) double maxBuf[2];
  _mm_store_pd(minBuf, vmin);
  _mm_store_pd(maxBuf, vmax);

  double minValue = std::min(minBuf[0], minBuf[1]);
  double maxValue = std::max(maxBuf[0], maxBuf[1]);

  for (; i < n; ++i) {
    minValue = std::min(minValue, data[i]);
    maxValue = std::max(maxValue, data[i]);
  }

  return {minValue, maxValue};
}
#endif

#if defined(__aarch64__) || defined(__ARM_NEON)
MinMax minMaxNeon(const double *data, size_t n) {
  if (n < 2) {
    return minMaxScalar(data, n);
  }

  size_t i = 0;
  float64x2_t vmin = vld1q_f64(data);
  float64x2_t vmax = vmin;
  i += 2;

  for (; i + 1 < n; i += 2) {
    const float64x2_t v = vld1q_f64(data + i);
    vmin = vminq_f64(vmin, v);
    vmax = vmaxq_f64(vmax, v);
  }

  const double min0 = vgetq_lane_f64(vmin, 0);
  const double min1 = vgetq_lane_f64(vmin, 1);
  const double max0 = vgetq_lane_f64(vmax, 0);
  const double max1 = vgetq_lane_f64(vmax, 1);

  double minValue = std::min(min0, min1);
  double maxValue = std::max(max0, max1);

  for (; i < n; ++i) {
    minValue = std::min(minValue, data[i]);
    maxValue = std::max(maxValue, data[i]);
  }

  return {minValue, maxValue};
}
#endif

} // namespace

MinMax findMinMax(const double *data, size_t n) {
  if (n == 0) {
    return {0.0, 0.0};
  }

#if defined(__AVX2__)
  return minMaxAvx2(data, n);
#elif defined(__SSE2__)
  return minMaxSse2(data, n);
#elif defined(__aarch64__) || defined(__ARM_NEON)
  return minMaxNeon(data, n);
#else
  return minMaxScalar(data, n);
#endif
}

MinMaxIndex findMinMaxIndex(const double *data, size_t n) {
  if (n == 0) {
    return {0.0, 0.0, 0, 0};
  }

  const MinMax minMax = findMinMax(data, n);

  const double *begin = data;
  const double *end = data + n;
  const auto minIt = std::find(begin, end, minMax.min);
  const auto maxIt = std::find(begin, end, minMax.max);

  if (minIt == end || maxIt == end) {
    const MinMax scalarMinMax = minMaxScalar(data, n);
    const auto scalarMinIt = std::find(begin, end, scalarMinMax.min);
    const auto scalarMaxIt = std::find(begin, end, scalarMinMax.max);
    return {scalarMinMax.min, scalarMinMax.max,
            static_cast<size_t>(std::distance(begin, scalarMinIt)),
            static_cast<size_t>(std::distance(begin, scalarMaxIt))};
  }

  return {minMax.min, minMax.max,
          static_cast<size_t>(std::distance(begin, minIt)),
          static_cast<size_t>(std::distance(begin, maxIt))};
}

} // namespace simdstats
