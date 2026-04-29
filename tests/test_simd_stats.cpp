#include <catch2/catch_test_macros.hpp>

#include "models/simd_stats.h"

#include <random>
#include <vector>

namespace {

simdstats::MinMax scalarMinMax(const std::vector<double> &values) {
  if (values.empty()) {
    return {0.0, 0.0};
  }

  double minValue = values[0];
  double maxValue = values[0];
  for (size_t i = 1; i < values.size(); ++i) {
    if (values[i] < minValue) {
      minValue = values[i];
    }
    if (values[i] > maxValue) {
      maxValue = values[i];
    }
  }

  return {minValue, maxValue};
}

simdstats::MinMaxIndex scalarMinMaxIndex(const std::vector<double> &values) {
  if (values.empty()) {
    return {0.0, 0.0, 0, 0};
  }

  double minValue = values[0];
  double maxValue = values[0];
  size_t minIndex = 0;
  size_t maxIndex = 0;

  for (size_t i = 1; i < values.size(); ++i) {
    if (values[i] < minValue) {
      minValue = values[i];
      minIndex = i;
    }
    if (values[i] > maxValue) {
      maxValue = values[i];
      maxIndex = i;
    }
  }

  return {minValue, maxValue, minIndex, maxIndex};
}

} // namespace

TEST_CASE("simdstats min/max handles small arrays", "[simd]") {
  SECTION("Empty array") {
    const std::vector<double> values;
    const auto minMax = simdstats::findMinMax(values.data(), values.size());
    const auto minMaxIndex =
        simdstats::findMinMaxIndex(values.data(), values.size());
    CHECK(minMax.min == 0.0);
    CHECK(minMax.max == 0.0);
    CHECK(minMaxIndex.minIndex == 0);
    CHECK(minMaxIndex.maxIndex == 0);
  }

  SECTION("Single value") {
    const std::vector<double> values{42.5};
    const auto minMax = simdstats::findMinMax(values.data(), values.size());
    const auto minMaxIndex =
        simdstats::findMinMaxIndex(values.data(), values.size());
    CHECK(minMax.min == 42.5);
    CHECK(minMax.max == 42.5);
    CHECK(minMaxIndex.minIndex == 0);
    CHECK(minMaxIndex.maxIndex == 0);
  }
}

TEST_CASE("simdstats matches scalar reference", "[simd]") {
  SECTION("Deterministic input") {
    const std::vector<double> values{3.0, -2.0, 5.5, -2.0, 5.5, 1.0, 4.0};
    const auto expected = scalarMinMax(values);
    const auto expectedIndex = scalarMinMaxIndex(values);
    const auto actual = simdstats::findMinMax(values.data(), values.size());
    const auto actualIndex =
        simdstats::findMinMaxIndex(values.data(), values.size());

    CHECK(actual.min == expected.min);
    CHECK(actual.max == expected.max);
    CHECK(actualIndex.minIndex == expectedIndex.minIndex);
    CHECK(actualIndex.maxIndex == expectedIndex.maxIndex);
  }

  SECTION("All equal values preserve first index") {
    const std::vector<double> values(33, 7.25);
    const auto actual = simdstats::findMinMax(values.data(), values.size());
    const auto actualIndex =
        simdstats::findMinMaxIndex(values.data(), values.size());

    CHECK(actual.min == 7.25);
    CHECK(actual.max == 7.25);
    CHECK(actualIndex.minIndex == 0);
    CHECK(actualIndex.maxIndex == 0);
  }

  SECTION("Randomized finite vectors") {
    std::mt19937_64 rng(0xC0FFEE);
    std::uniform_real_distribution<double> dist(-1.0e9, 1.0e9);

    for (size_t n = 1; n <= 1024; ++n) {
      std::vector<double> values(n);
      for (double &value : values) {
        value = dist(rng);
      }

      const auto expected = scalarMinMax(values);
      const auto expectedIndex = scalarMinMaxIndex(values);
      const auto actual = simdstats::findMinMax(values.data(), values.size());
      const auto actualIndex =
          simdstats::findMinMaxIndex(values.data(), values.size());

      CHECK(actual.min == expected.min);
      CHECK(actual.max == expected.max);
      CHECK(actualIndex.minIndex == expectedIndex.minIndex);
      CHECK(actualIndex.maxIndex == expectedIndex.maxIndex);
    }
  }
}
