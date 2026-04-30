#include <catch2/catch_test_macros.hpp>
#include <catch2/matchers/catch_matchers_floating_point.hpp>
#include "parsers/spe_parser.h"
#include <algorithm>
#include <cmath>
#include <iostream>
#include <string>

using namespace pickett;
using Catch::Matchers::WithinAbs;

// Helper to get test data path
static std::string get_test_data_path(const std::string &filename) {
  return std::string(TEST_DATA_DIR) + "/" + filename;
}

TEST_CASE("Spectral file parser", "[spe]") {
  SECTION("Parse cyanomethylenecyclopropane_235-500GHz_bin.spe") {
    auto result = SpeParser::parseFile(
        get_test_data_path("cyanomethylenecyclopropane_235-500GHz_bin.spe"));

    if (!result.has_value()) {
      for (const auto &error : result.error()) {
        std::cout << "Error at " << error.first << ": " << error.second << std::endl;
      }
    }
    REQUIRE(result.has_value());
    const auto &parsed = result.value();

    // Check header (trim trailing spaces from comment)
    std::string comment(parsed.header.comment);
    comment.erase(comment.find_last_not_of(' ') + 1);
    CHECK(comment == "!");
    CHECK(parsed.header.day == 4);
    CHECK(parsed.header.month == 10);
    CHECK(parsed.header.year == 2022);
    CHECK(parsed.header.hour == 19);
    CHECK(parsed.header.minute == 45);
    CHECK(parsed.header.second == 16);

    // Check data section
    CHECK(parsed.npts == 5889108);
    CHECK(parsed.intensities.size() == 5889108);

    // Check first and last intensity values
    CHECK(parsed.intensities[0] == 743811770);
    CHECK(parsed.intensities[1] == 743973043);
    CHECK(parsed.intensities[99] == 745039550);

    // Check some values in the middle
    CHECK(parsed.intensities[2944554] == 754495152);
    CHECK(parsed.intensities[2944555] == 749831119);

    // Check last few values
    CHECK(parsed.intensities[5889107] == 747664146);

    // Check footer (frequency info in MHz)
    using Catch::Matchers::WithinAbs;
    CHECK_THAT(parsed.footer.fstart, WithinAbs(234839.325, 0.001));  // MHz
    CHECK_THAT(parsed.footer.fend, WithinAbs(499997.100, 0.001));  // MHz
    CHECK_THAT(parsed.footer.fincr, WithinAbs(0.045025, 0.000001)); // MHz
    CHECK(parsed.footer.ncalpt == 0);

    // Check computed properties (all in MHz)
    CHECK_THAT(parsed.fstartMHz(), WithinAbs(234839.325, 0.001));
    CHECK_THAT(parsed.fendMHz(), WithinAbs(499997.100, 0.001));
    CHECK_THAT(parsed.spanMHz(), WithinAbs(265157.775, 0.001));
  }

  SECTION("Frequency range validation") {
    auto result = SpeParser::parseFile(
        get_test_data_path("cyanomethylenecyclopropane_235-500GHz_bin.spe"));

    REQUIRE(result.has_value());
    const auto &parsed = result.value();

    // Validate frequency span matches filename (in MHz: 235-500 GHz = 265,000 MHz span)
    double span_mhz = parsed.spanMHz();
    CHECK(span_mhz > 260000.0);  // Should be ~265,000 MHz
    CHECK(span_mhz < 270000.0);

    // Validate FSTART/FEND order
    CHECK(parsed.footer.fend > parsed.footer.fstart);

    // Validate NPTS makes sense with FINCR
    double expected_span_mhz = parsed.footer.fincr * (parsed.npts - 1);
    double actual_span_mhz = parsed.footer.fend - parsed.footer.fstart;
    CHECK_THAT(expected_span_mhz, WithinAbs(actual_span_mhz, 0.1));  // Within 0.1 MHz
  }

  SECTION("Intensity value range") {
    auto result = SpeParser::parseFile(
        get_test_data_path("cyanomethylenecyclopropane_235-500GHz_bin.spe"));

    REQUIRE(result.has_value());
    const auto &parsed = result.value();

    // Find min and max intensities
    auto minmax = std::minmax_element(parsed.intensities.begin(),
                                      parsed.intensities.end());
    int32_t min_val = *minmax.first;
    int32_t max_val = *minmax.second;

    // Values span from approx -1B to +1B (centered around 0 with ~2B range)
    // This indicates ADC data with DC offset removed
    CHECK(min_val > -1000000000);  // Greater than -1B
    CHECK(max_val < 1000000000);   // Less than +1B

    // Check that we have variation (not all same value)
    CHECK(max_val > min_val);
    
    // Check that values span both positive and negative (centered data)
    CHECK(min_val < 0);  // Has negative values
    CHECK(max_val > 0);  // Has positive values
  }

  SECTION("File not found error") {
    auto result = SpeParser::parseFile("nonexistent_file.spe");

    CHECK(!result.has_value());
    CHECK(!result.error().empty());
    CHECK(result.error()[0].second.find("Failed to open") != std::string::npos);
  }

  SECTION("Too small file error") {
    // Create a minimal invalid buffer
    std::vector<uint8_t> tiny_buffer(10, 0);
    auto result = SpeParser::parseBuffer(tiny_buffer);

    CHECK(!result.has_value());
    CHECK(!result.error().empty());
  }
}
