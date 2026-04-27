# Pickett GUI Agent Guidelines

## Build Commands

### Standard Build
```bash
# Configure and build in release mode
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build

# Configure and build in debug mode
cmake -S . -B build-debug -DCMAKE_BUILD_TYPE=Debug
cmake --build build-debug
```

### Building with Tests
```bash
# Enable tests during configuration
cmake -S . -B build-tests -DPICKETT_BUILD_TESTS=ON
cmake --build build-tests
```

### Clean Build
```bash
rm -rf build build-debug build-tests
```

## Lint/Formatting Commands

### Clang Format
```bash
# Format all C++ files according to .clang-format
find . -name "*.cpp" -o -name "*.h" -o -name "*.hpp" | xargs clang-format -i

# Check formatting without modifying files
find . -name "*.cpp" -o -name "*.h" -o -name "*.hpp" | xargs clang-format --dry-run --Werror
```

## Test Commands

### Running All Tests
```bash
# With CTest (when tests are enabled in build)
cd build-tests && ctest --output-on-failure

# Or run test executable directly
./build-tests/test_parsers
```

### Running Single Test
```bash
# Run a specific test case using Catch2 syntax
./build-tests/test_parsers "[spe]"

# Run a specific test section
./build-tests/test_parsers "[spe][Parse cyanomethylenecyclopropane_235-500GHz_bin.spe]"

# Run test with verbose output
./build-tests/test_parsers -v "[spe]"
```

### Available Test Executables
- `test_parsers` - Contains all parser tests (SPE, PAR, LIN, INT, FIT, CAT)

## Code Style Guidelines

### General Formatting
- Follow `.clang-format` configuration (2-space indentation, 80 column limit)
- Use spaces, not tabs (`UseTab: Never`)
- Pointer alignment: Right (`PointerAlignment: Right`)
- Brace style: Attach (`BreakBeforeBraces: Attach`)
- Include categories prioritized: system/Qt first, then third-party, then local

### Imports/Includes
- Standard library includes first, then Qt, then project includes
- Use angle brackets for system/Qt includes: `#include <QString>`
- Use quotes for project includes: `#include "parsers/spe_parser.h"`
- Group includes with blank lines between categories
- Sort includes lexicographically within each category

### Naming Conventions
- Classes and structs: PascalCase (e.g., `SpeParser`, `SpectrumData`)
- Functions and methods: camelCase (e.g., `parse_file()`, `get_fstart_mhz()`)
- Variables: camelCase (e.g., `npts`, `intensities`)
- Constants and enums: UPPER_SNAKE_CASE (e.g., `MAX_BUFFER_SIZE`)
- Member variables: camelCase with `m_` prefix (e.g., `m_npts`)
- Namespaces: lowercase (e.g., `pickett`)

### Types
- Use fixed-width integers from `<cstdint>` for specific sizes (e.g., `int32_t`, `uint8_t`)
- Prefer `auto` for complex template types when the type is obvious
- Use `size_t` for sizes and counts
- Use `double` for floating-point values unless precision requirements specify otherwise
- Qt types: Use appropriate Qt equivalents (e.g., `QString` for strings in Qt context)

### Error Handling
- Parser functions return a result struct with `success` boolean and `errors` vector
- Check `success` flag before using parsed data
- Errors contain line number and descriptive message
- In tests: Verify `REQUIRE(result.success)` for critical failures, `CHECK()` for validations
- File operations: Check for file existence and readable/ writable permissions
- Buffer operations: Validate size limits before processing

### Comments
- Use Doxygen-style comments for public APIs: `/** ... */`
- Section comments in tests using `SECTION()` blocks
- Inline comments for complex logic explanations
- TODO comments for future work: `// TODO: implement frequency calibration`

### Qt/QML Specific
- QML files: Use 2-space indentation, consistent with C++
- Component IDs: camelCase (e.g., `spectrumPlot`, `viewportModel`)
- Properties: camelCase with clear, descriptive names
- Signals and slots: Follow Qt naming conventions
- Use Qt containers when interacting with Qt APIs, STL otherwise

## Project Structure
```
src/
├─ parsers/      # File parser implementations
├─ models/       # Data models (SpectrumData, CatalogData, etc.)
├─ plot/         # QML plotting components
┃
tests/           # Unit tests using Catch2
test_data/       # Sample data files for testing
qml/             # QML UI files
```

## Additional Notes
- Tests are disabled by default; enable with `PICKETT_BUILD_TESTS=ON`
- Test data directory is available via `TEST_DATA_DIR` macro in tests
- The project uses Qt6 Quick module for QML-based UI
- C++17 is required (`set(CMAKE_CXX_STANDARD 17)`)