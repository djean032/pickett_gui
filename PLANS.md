# Redundant Data Conversion Reduction Plan

## Objective

Reduce end-to-end file load latency and peak memory by removing unnecessary
data remapping between parser outputs, service DTOs, and model storage,
starting with CAT and SPE paths.

## Container Boundary Policy

- Use STL containers in parser/core/internal compute paths.
- Use Qt-friendly types at QObject/QML boundaries.
- Convert once at the boundary; avoid repeated container reshaping.

## Execution Checklist

### Commit 1: CAT native service plumbing

- [x] Add `CatalogNativeResult` and `CatalogNativeLoadExpected` to
      `src/services/spectralfileservice.h`.
  - Fields:
    - `quint64 requestId`
    - `QString sourcePath`
    - `std::vector<pickett::CatRecord> records`
    - `QVector<ParserError> errors`
- [x] Add CAT native service APIs in `src/services/spectralfileservice.h`:
  - `CatalogNativeLoadExpected loadCatNative(const QString &filePath) const`
  - `quint64 loadCatNativeAsync(const QString &filePath)`
- [x] Add new signal in `src/services/spectralfileservice.h`:
  - `void catNativeLoaded(const SpectralFileService::CatalogNativeResult &)`
- [x] Implement `loadCatNative` in `src/services/spectralfileservice.cpp`.
  - Reuse existing validation and parser error mapping logic.
  - On success, move parser records directly:
    `result.records = std::move(parsedValue.records)`.
  - Do not create intermediate `CatalogLine` objects.
- [x] Implement `loadCatNativeAsync` in
      `src/services/spectralfileservice.cpp`.
  - Mirror existing watcher/requestId patterns.
- [x] Register any needed metatypes alongside existing registrations.
- [x] Build and run tests:
  - `cmake --build build-tests --target test_parsers`
  - `ctest --test-dir build-tests --output-on-failure`

### Commit 2: Switch CatalogData to CAT native path

- [x] Update `CatalogData` connection in `src/models/catalogdata.cpp`:
  - connect/disconnect using `catNativeLoaded`.
- [x] Update slot signature in `src/models/catalogdata.h/.cpp`:
  - `onCatLoaded(const SpectralFileService::CatalogNativeResult &result)`
- [x] Replace per-field CAT remap loop in `CatalogData::onCatLoaded` with
      direct assignment/move into `m_records`.
  - Remove `CatalogLine` -> `CatRecord` reconstruction loop.
- [x] Keep sorting, normalization, and error/warning behavior unchanged.
- [x] Build and run tests.

### Commit 3: SPE native service plumbing

- [x] Add `SpectrumNativeResult` and `SpectrumNativeLoadExpected` to
      `src/services/spectralfileservice.h`.
  - Fields:
    - `quint64 requestId`
    - `QString sourcePath`
    - `double fStartMHz`
    - `double fEndMHz`
    - `double fIncrMHz`
    - `std::vector<int32_t> intensities`
    - `QVector<ParserError> errors`
- [x] Add SPE native service APIs in `src/services/spectralfileservice.h`:
  - `SpectrumNativeLoadExpected loadSpeNative(const QString &filePath) const`
  - `quint64 loadSpeNativeAsync(const QString &filePath)`
- [x] Add new signal in `src/services/spectralfileservice.h`:
  - `void speNativeLoaded(const SpectralFileService::SpectrumNativeResult &)`
- [x] Implement `loadSpeNative` in `src/services/spectralfileservice.cpp`.
  - Reuse existing validation and error mapping.
  - Move intensities directly from parser result.
  - Do not build intermediate `QVector<SpectrumPoint>` for native path.
- [x] Implement `loadSpeNativeAsync` with existing requestId semantics.
- [x] Register any new metatypes required.
- [x] Build and run tests.

### Commit 4: Switch SpectrumData to SPE native path

- [x] Update `SpectrumData` connection in `src/models/spectrumdata.cpp`:
  - connect/disconnect using `speNativeLoaded`.
- [x] Update slot signature in `src/models/spectrumdata.h/.cpp`:
  - `onSpeLoaded(const SpectralFileService::SpectrumNativeResult &result)`
- [x] Replace `result.points` conversion in
      `SpectrumData::onSpeLoaded` with one-pass materialization from
      native payload:
  - `freq[i] = fStartMHz + i * fIncrMHz`
  - `intensity[i] = static_cast<double>(rawIntensity[i])`
- [x] Keep decimation behavior and min/max calculations unchanged.
- [x] Preserve error/warning/fatal handling behavior.
- [x] Build and run tests.

### Commit 5: Tests for native paths

- [x] Extend `tests/test_spectral_file_service.cpp`:
  - Add sync/async success and failure cases for `loadCatNative`.
  - Add sync/async success and failure cases for `loadSpeNative`.
  - Validate domain/error-code parity with existing paths.
- [x] Extend model tests as needed:
  - Ensure `CatalogData` and `SpectrumData` behavior unchanged for UI-facing
    states (loading, error, warning, data available).
- [x] Run full tests and confirm no regressions.

### Commit 6: Baseline and perf verification

- [x] Add lightweight timing probes (temporary or guarded) around:
  - `SpectralFileService::loadCat`/`loadCatNative`
  - `SpectralFileService::loadSpe`/`loadSpeNative`
  - `CatalogData::onCatLoaded`
  - `SpectrumData::onSpeLoaded`
- [x] Record before/after metrics for representative large CAT and SPE files.
- [x] Verify improvements or no regressions in:
  - total load latency
  - peak memory usage
  - async behavior correctness
- [ ] Remove temporary probes if not intended for permanent diagnostics.

### Commit 7: Native payload cache serialization

- [ ] Add cache wire formats (versioned headers + fixed-width payloads) for CAT
      and SPE native payloads.
  - Header fields should include at least:
    - magic
    - format version
    - record count/size
    - source fingerprint (size + mtime)
    - payload checksum
- [ ] Implement CAT cache serialization/deserialization.
  - Payload: `std::vector<pickett::CatRecord>`
- [ ] Implement SPE cache serialization/deserialization.
  - Payload: `fStartMHz`, `fEndMHz`, `fIncrMHz`,
    `std::vector<int32_t> intensities`
- [ ] Add roundtrip unit tests for CAT and SPE cache I/O.
  - Write -> read -> field-by-field equality checks.
  - Include invalid/corrupt cache cases (bad magic/version/truncated payload).
- [ ] Integrate cache path into native loaders:
  - `loadCatNative`: try valid cache first, else parse and write cache.
  - `loadSpeNative`: try valid cache first, else parse and write cache.
  - Cache miss/invalid cache must fall back safely to parser path.
- [ ] Add integration tests for cache behavior in service layer.
  - First load builds cache from source.
  - Second load uses cache with output parity to parser path.
  - Source file metadata change invalidates cache and triggers reparse.
- [ ] Re-run timing benchmarks with cold/warm runs and compare medians.
  - Report CAT and SPE service load times separately for parser vs cache path.

### Commit 8: COLBEE-style transition classification for Loomis-Wood

- [ ] Add derived transition classification model for CAT records.
  - Keep parser `CatRecord` raw; store derived class metadata in a parallel
    structure for serialization/cache compatibility.
  - Suggested derived fields:
    - dipole type (`a`/`b`/`c`/unknown)
    - branch class (`P`/`Q`/`R`/other via `deltaJ`)
    - `deltaJ`, `deltaKMinus`, `deltaKPlus`
    - optional lower-state keys (`J''`, `Ka''`, `Kc''`) for fast filtering
- [ ] Compute classification once when CAT native payload is accepted.
  - Build and store classification cache aligned 1:1 with records.
  - Recompute only when records are reloaded/changed.
- [ ] Add query/filter helpers for transition selection.
  - Start with predicate-based filtering (`std::copy_if`/ranges views).
  - Support filter keys for dipole, branch, `Ka''`, frequency window,
    intensity threshold.
- [ ] Add series extraction continuity pass for ladder selection.
  - Sort filtered candidates by progression key (`J''` then frequency).
  - Split into contiguous runs (`J''` stepwise continuity), with configurable
    minimum run length and optional gap tolerance.
- [ ] Add unit tests for classification and continuity behavior.
  - Validate known a/b/c + P/Q/R mappings.
  - Validate continuity run extraction and short-fragment rejection.

## Rollout Notes

- Keep legacy `loadCat`/`loadSpe` and existing signals during rollout to
  minimize risk.
- Use native paths for model consumers first.
- Consider deprecating old conversion-heavy paths only after stable perf
  validation.
