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
- [ ] Replace bool success + error vector with std::expected (C++23) or similar
  - Forces error handling at call sites
  - More expressive error types
  - Can include error context
- [ ] Use constexpr for compile-time constants
  - Header/footer sizes
  - Mathematical constants
  - Array sizes where applicable

## MEDIUM PRIORITY

### Performance Improvements

#### SIMD Processing
- [ ] Add SIMD intrinsics for intensity data processing (min/max, filtering, statistics)
- [ ] Target: SSE/AVX2 on x86, NEON on ARM
- [ ] Focus areas:
  - Finding min/max values in intensity arrays
  - Applying filters or transformations
  - Statistical calculations (mean, variance)

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
