# Snake Case Symbol Inventory

Date: 2026-04-30

This inventory captures snake_case parser/public API symbols that should be
considered for staged camelCase migration.

## Scope

- Included: parser and utility APIs in `src/parsers`, plus direct call sites in
  `src/` and `tests/`.
- Excluded for now: local variables, constants/macros, SIMD intrinsics, and
  third-party identifiers.

## Public API Symbols (snake_case)

### `CatParser`

- `parse_file`
- `decode_qnfmt`
- `get_qn_labels`

### `FitParser`

- `parse_file`

### `IntParser` / `IntDipole`

- `parse_file`
- `write_file`
- `decode_flags`
- `decode_idip`
- `encode_idip`
- `get_idip_info`

### `LinParser`

- `parse_file`
- `write_file`

### `ParParser`

- `parse_file`
- `write_file`
- `is_valid_chr`
- `encode_chr`

### `SpeParser` / `SpeParseResult`

- `parse_file`
- `parse_buffer`
- `get_fstart_mhz`
- `get_fend_mhz`
- `get_fincr_mhz`
- `get_span_mhz`

## Internal Helper Symbols (snake_case)

These are implementation details and can be migrated in later phases.

- `parse_header_line`
- `parse_option_line`
- `parse_parameter_line`
- `parse_line_record`
- `parse_correlation_line`
- `parse_updated_parameter_line`
- `parse_dipole_line`
- `parse_header`
- `parse_data`
- `parse_footer`
- `validate_header`
- `decode_qn`
- `format_qn`
- `format_double`
- `parse_int_safe`
- `parse_double_safe`
- `format_scientific_upper`
- `format_scientific_lin`

## Direct Call-Site Hotspots

### Runtime (`src/`)

- `src/services/spectralfileservice.cpp`
  - uses parser `parse_file` methods for SPE/CAT/LIN
- `src/models/viewportmodel.cpp`
  - uses `CatParser::get_qn_labels`

### Tests (`tests/`)

- `tests/test_cat_parser.cpp`
- `tests/test_fit_parser.cpp`
- `tests/test_int_parser.cpp`
- `tests/test_lin_parser.cpp`
- `tests/test_par_parser.cpp`
- `tests/test_spe_parser.cpp`
- `tests/bench_cat_parser.cpp`

## Suggested Migration Order (staged default)

1. Add camelCase aliases/wrappers for public APIs while keeping snake_case.
2. Update runtime call sites in `src/` to camelCase.
3. Update tests/benchmarks to camelCase.
4. Deprecate snake_case APIs.
5. Remove snake_case once compatibility window closes.
