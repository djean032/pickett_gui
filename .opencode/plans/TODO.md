# Pickett GUI Improvement TODO List

## HIGH PRIORITY

### Service Layer
- [x] Implement SpectralFileService to encapsulate file operations and parsing
  - Provides synchronous and asynchronous parsing APIs
  - Centralizes error handling and reporting
  - Enables easy mocking for unit tests

### Error Handling
- [x] Define domain-specific error types
  - ParserError enum (FileNotFound, InvalidHeader, etc.)
  - Rich error information with context
- [x] Integrate error handling with service layer
  - Service methods return structured error information
  - UI layer can display meaningful error messages

### Modern C++ Features
- [x] Replace bool success + error vector with std::expected (C++23) or similar
  - Forces error handling at call sites
  - More expressive error types
  - Can include error context
- [x] Use constexpr for compile-time constants
  - Header/footer sizes
  - Mathematical constants
  - Array sizes where applicable

## MEDIUM PRIORITY

### Performance Improvements

#### Parser Throughput
- [x] Optimize CAT parser hot path (reduce allocations, faster numeric parsing)
- [x] Add CAT parser benchmark target (`bench_cat_parser`) and record baseline throughput
- [ ] Validate CAT parser benchmark on x86 hardware and compare against ARM results
- [ ] Reduce parser/service/model data copying for CAT and SPE load paths
  - Avoid redundant transforms between parser records, service DTOs, and model storage
  - Target lower peak memory and faster end-to-end file load latency

Benchmark notes (for x86 follow-up):
- Configure/build benchmark in Release mode:
  - `cmake -S . -B build-bench-release -DCMAKE_BUILD_TYPE=Release -DPICKETT_BUILD_TESTS=ON`
  - `cmake --build build-bench-release --target bench_cat_parser`
- Run benchmark:
  - `./build-bench-release/bench_cat_parser`

#### UI/Render Performance
- [ ] Add per-record metadata cache for catalog readout
  - Cache lightweight numeric metadata for all records (no full per-line `QVariantList`/string blobs)
  - Materialize Qt readout objects on demand (or with small LRU window)
  - Reduce cursor/readout allocation churn in `ViewportModel::lineAtPixel`
- [ ] Replace `std::map` grouping in catalog rendering with fixed small bucket grouping
  - Group by vibrational/state index using contiguous buckets when range is compact
  - Keep deterministic ordering and map fallback for pathological sparse/wide ranges
- [ ] Reuse scenegraph geometry buffers in plot items
  - Minimize per-frame geometry/material churn in spectrum and catalog plot rendering
  - Target smoother interaction and lower CPU/GPU driver overhead during pan/zoom

#### Responsiveness
- [ ] Add async request supersession/cancellation for file loads
  - Stop expensive stale parse jobs when newer requests supersede them
  - Prevent wasted background CPU for rapid repeated load actions

#### SIMD Processing
- [x] Add SIMD intrinsics for intensity data processing (min/max, filtering, statistics)
- [ ] Validate x86 SIMD paths (SSE2/AVX2) on x86 hardware and compare benchmark results
- [x] Target: SSE/AVX2 on x86, NEON on ARM
- [ ] Focus areas:
  - [x] Finding min/max values in intensity arrays
  - Applying filters or transformations
  - Statistical calculations (mean, variance)

Benchmark notes (for x86 follow-up):
- Configure/build benchmark in Release mode:
  - `cmake -S . -B build-bench-release -DCMAKE_BUILD_TYPE=Release -DPICKETT_BUILD_TESTS=ON`
  - `cmake --build build-bench-release --target bench_simd_stats`
- Run benchmark:
  - `./build-bench-release/bench_simd_stats`

### Testing Improvements

#### Fuzz Testing
- [ ] Add fuzz testing for parser robustness
- [ ] Test with random/invalid byte sequences
- [ ] Check for crashes, memory leaks, infinite loops

#### Performance Regression Tests
- [ ] Add benchmarks for parser performance
- [ ] Track performance over time
- [ ] Alert on significant degradations
- [ ] Test memory usage patterns

#### Edge Case Testing
- [ ] Test boundary conditions (exact file sizes)
- [ ] Test corrupted headers/footers
- [ ] Test extreme values in numeric fields
- [ ] Test unusual but valid combinations


## LOW PRIORITY

### Code Quality & Maintainability

#### Documentation
- [ ] Add Doxygen-style comments for all public APIs
- [ ] Document complex algorithms and data structures
- [ ] Add usage examples where appropriate

### Testing Improvements

#### Property-Based Testing
- [ ] Consider property-based testing for mathematical invariants
  - Example: "parse then serialize should preserve data"
  - Libraries: rapidcheck or std::experimental::generate
  - Lower priority due to learning curve and existing robust test suite
