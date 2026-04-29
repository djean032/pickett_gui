#include "parsers/cat_parser.h"

#include <chrono>
#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <string>

namespace {

using Clock = std::chrono::steady_clock;

double runOne(const std::string &path, int iterations) {
  size_t totalRecords = 0;
  const auto start = Clock::now();
  for (int i = 0; i < iterations; ++i) {
    const auto parsed = pickett::CatParser::parse_file(path);
    if (!parsed.has_value()) {
      std::cerr << "Parse failed at iteration " << i << "\n";
      std::exit(1);
    }
    totalRecords += parsed->records.size();
  }
  const auto end = Clock::now();
  const auto elapsedNs =
      std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();

  if (totalRecords == 0) {
    std::cerr << "No records parsed\n";
    std::exit(1);
  }

  return static_cast<double>(elapsedNs) / static_cast<double>(iterations);
}

} // namespace

int main(int argc, char **argv) {
  std::string path = std::string(TEST_DATA_DIR) + "/cyanomethcycloprop.cat";
  if (argc > 1) {
    path = argv[1];
  }

  const auto warmup = pickett::CatParser::parse_file(path);
  if (!warmup.has_value()) {
    std::cerr << "Warmup parse failed\n";
    return 1;
  }

  const size_t records = warmup->records.size();
  const int iterations = 5;
  const double avgNs = runOne(path, iterations);
  const double avgMs = avgNs / 1.0e6;
  const double recordsPerSecond =
      static_cast<double>(records) / (avgNs / 1.0e9);

  std::cout << "CAT parser benchmark\n";
  std::cout << "file: " << path << "\n";
  std::cout << "records: " << records << "\n";
  std::cout << "iterations: " << iterations << "\n";
  std::cout << "avg parse time: " << std::fixed << std::setprecision(2) << avgMs
            << " ms\n";
  std::cout << "throughput: " << std::fixed << std::setprecision(0)
            << recordsPerSecond << " records/s\n";

  return 0;
}
