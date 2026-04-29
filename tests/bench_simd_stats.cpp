#include "models/simd_stats.h"

#include <chrono>
#include <cstdint>
#include <iomanip>
#include <iostream>
#include <random>
#include <vector>

namespace {

using Clock = std::chrono::steady_clock;

struct ScalarMinMax {
  double min;
  double max;
};

ScalarMinMax scalarMinMax(const double *data, size_t n) {
  if (n == 0) {
    return {0.0, 0.0};
  }

  double minValue = data[0];
  double maxValue = data[0];
  for (size_t i = 1; i < n; ++i) {
    if (data[i] < minValue) {
      minValue = data[i];
    }
    if (data[i] > maxValue) {
      maxValue = data[i];
    }
  }

  return {minValue, maxValue};
}

template <typename Fn>
double runTimingNs(Fn fn, int iterations) {
  volatile double sink = 0.0;
  const auto start = Clock::now();
  for (int i = 0; i < iterations; ++i) {
    const auto r = fn();
    sink += r.min + r.max;
  }
  const auto end = Clock::now();
  (void)sink;

  const auto elapsedNs =
      std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();
  return static_cast<double>(elapsedNs) / static_cast<double>(iterations);
}

void runCase(size_t n, int iterations, std::mt19937_64 &rng) {
  std::uniform_real_distribution<double> dist(-1.0e9, 1.0e9);
  std::vector<double> values(n);
  for (double &v : values) {
    v = dist(rng);
  }

  const auto ref = scalarMinMax(values.data(), values.size());
  const auto simd = simdstats::findMinMax(values.data(), values.size());
  if (ref.min != simd.min || ref.max != simd.max) {
    std::cerr << "Correctness check failed for n=" << n << '\n';
    std::exit(1);
  }

  const double scalarNs = runTimingNs(
      [&]() {
        const auto r = scalarMinMax(values.data(), values.size());
        return simdstats::MinMax{r.min, r.max};
      },
      iterations);

  const double simdNs = runTimingNs(
      [&]() { return simdstats::findMinMax(values.data(), values.size()); },
      iterations);

  const double speedup = scalarNs / simdNs;

  std::cout << std::setw(10) << n << "  " << std::setw(14) << std::fixed
            << std::setprecision(2) << scalarNs << "  " << std::setw(14)
            << simdNs << "  " << std::setw(8) << std::setprecision(2)
            << speedup << "x\n";
}

} // namespace

int main() {
  std::mt19937_64 rng(0xBADC0FFEEULL);

  std::cout << "SIMD min/max benchmark (avg ns per call)\n";
  std::cout << "backend: " << simdstats::backendName() << "\n";
  std::cout << "array_size    scalar_ns/call   simd_ns/call   speedup\n";

  runCase(1024, 30000, rng);
  runCase(16384, 6000, rng);
  runCase(262144, 700, rng);
  runCase(1048576, 180, rng);

  return 0;
}
