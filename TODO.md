# Pickett GUI Improvement TODO List

## Performance Improvements

### SIMD Processing
- [ ] Add SIMD intrinsics for intensity data processing (min/max, filtering, statistics)
- [ ] Target: SSE/AVX2 on x86, NEON on ARM
- [ ] Focus areas: 
  - Finding min/max values in intensity arrays
  - Applying filters or transformations
  - Statistical calculations (mean, variance)

## Code Quality & Maintainability

### Documentation
- [ ] Add Doxygen-style comments for all public APIs
- [ ] Document complex algorithms and data structures
- [ ] Add usage examples where appropriate

### Modern C++ Features
- [ ] Use constexpr for compile-time constants
  - Header/footer sizes
  - Mathematical constants
  - Array sizes where applicable
- [ ] Replace bool success + error vector with std::expected (C++23) or similar
  - Forces error handling at call sites
  - More expressive error types
  - Can include error context

### Service Layer
- [ ] Implement SpectralFileService to encapsulate file operations and parsing
  - Provides synchronous and asynchronous parsing APIs
  - Centralizes error handling and reporting
  - Enables easy mocking for unit tests
  - Example usage:
    ```cpp
    // Async parsing
    QFutureWatcher<SpeParser::ParseResult> *watcher = new QFutureWatcher(this);
    connect(watcher, &QFutureWatcher<SpeParser::ParseResult>::finished,
            this, [this, watcher]() {
        auto result = watcher->result();
        // Update spectrumData with result
        watcher->deleteLater();
    });
    watcher->setFuture(fileService->parseFileAsync(filePath));
    ```

### Error Handling
- [ ] Define domain-specific error types
  - ParserError enum (FileNotFound, InvalidHeader, etc.)
  - Rich error information with context
- [ ] Integrate error handling with service layer
  - Service methods return structured error information
  - UI layer can display meaningful error messages

## Testing Improvements

### Fuzz Testing
- [ ] Add fuzz testing for parser robustness
- [ ] Test with random/invalid byte sequences
- [ ] Check for crashes, memory leaks, infinite loops

### Performance Regression Tests
- [ ] Add benchmarks for parser performance
- [ ] Track performance over time
- [ ] Alert on significant degradations
- [ ] Test memory usage patterns

### Edge Case Testing
- [ ] Test boundary conditions (exact file sizes)
- [ ] Test corrupted headers/footers
- [ ] Test extreme values in numeric fields
- [ ] Test unusual but valid combinations

### Property-Based Testing (Low Priority)
- [ ] Consider property-based testing for mathematical invariants
  - Example: "parse then serialize should preserve data"
  - Libraries: rapidcheck or std::experimental::generate
  - Lower priority due to learning curve and existing robust test suite

## Architecture Considerations

### Parser Consistency
- [ ] Consider CRTP or concepts (C++20) for parser interface
  - Provides consistency without virtual function overhead
  - Enables generic algorithms
  - Reduces code duplication in common parsing logic
  - Lower priority due to no planned new parsers

### Data Access Improvements
- [ ] Evaluate std::span for buffer parameters
  - Non-owning view of contiguous memory
  - Works with vectors, arrays, memory-mapped files
  - Makes read-only intent explicit
  - No performance penalty vs. vector references
  - Lower priority given current std::vector usage

## UI/Rendering
- [ ] Monitor performance with larger datasets
- [ ] Consider level-of-detail rendering for very large spectra
- [ ] Investigate intelligent downsampling that preserves spectral features
- [ ] Ensure responsiveness on lower-end hardware