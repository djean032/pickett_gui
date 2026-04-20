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
    auto result = SpeParser::parse_file(
        get_test_data_path("cyanomethylenecyclopropane_235-500GHz_bin.spe"));

    if (!result.success) {
      for (const auto &error : result.errors) {
        std::cout << "Error at " << error.first << ": " << error.second << std::endl;
      }
    }
    REQUIRE(result.success);

    // Check header (trim trailing spaces from comment)
    std::string comment(result.header.comment);
    comment.erase(comment.find_last_not_of(' ') + 1);
    CHECK(comment == "!");
    CHECK(result.header.day == 4);
    CHECK(result.header.month == 10);
    CHECK(result.header.year == 2022);
    CHECK(result.header.hour == 19);
    CHECK(result.header.minute == 45);
    CHECK(result.header.second == 16);

    // Check data section
    CHECK(result.npts == 5889108);
    CHECK(result.intensities.size() == 5889108);

    // Check first and last intensity values
    CHECK(result.intensities[0] == 743811770);
    CHECK(result.intensities[1] == 743973043);
    CHECK(result.intensities[99] == 745039550);

    // Check some values in the middle
    CHECK(result.intensities[2944554] == 754495152);
    CHECK(result.intensities[2944555] == 749831119);

    // Check last few values
    CHECK(result.intensities[5889107] == 747664146);

    // Check footer (frequency info in MHz)
    using Catch::Matchers::WithinAbs;
    CHECK_THAT(result.footer.fstart, WithinAbs(234839.325, 0.001));  // MHz
    CHECK_THAT(result.footer.fend, WithinAbs(499997.100, 0.001));  // MHz
    CHECK_THAT(result.footer.fincr, WithinAbs(0.045025, 0.000001)); // MHz
    CHECK(result.footer.ncalpt == 0);

    // Check computed properties (all in MHz)
    CHECK_THAT(result.get_fstart_mhz(), WithinAbs(234839.325, 0.001));
    CHECK_THAT(result.get_fend_mhz(), WithinAbs(499997.100, 0.001));
    CHECK_THAT(result.get_span_mhz(), WithinAbs(265157.775, 0.001));
  }

  SECTION("Frequency range validation") {
    auto result = SpeParser::parse_file(
        get_test_data_path("cyanomethylenecyclopropane_235-500GHz_bin.spe"));

    REQUIRE(result.success);

    // Validate frequency span matches filename (in MHz: 235-500 GHz = 265,000 MHz span)
    double span_mhz = result.get_span_mhz();
    CHECK(span_mhz > 260000.0);  // Should be ~265,000 MHz
    CHECK(span_mhz < 270000.0);

    // Validate FSTART/FEND order
    CHECK(result.footer.fend > result.footer.fstart);

    // Validate NPTS makes sense with FINCR
    double expected_span_mhz = result.footer.fincr * (result.npts - 1);
    double actual_span_mhz = result.footer.fend - result.footer.fstart;
    CHECK_THAT(expected_span_mhz, WithinAbs(actual_span_mhz, 0.1));  // Within 0.1 MHz
  }

  SECTION("Intensity value range") {
    auto result = SpeParser::parse_file(
        get_test_data_path("cyanomethylenecyclopropane_235-500GHz_bin.spe"));

    REQUIRE(result.success);

    // Find min and max intensities
    auto minmax = std::minmax_element(result.intensities.begin(),
                                      result.intensities.end());
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
    auto result = SpeParser::parse_file("nonexistent_file.spe");

    CHECK(!result.success);
    CHECK(!result.errors.empty());
    CHECK(result.errors[0].second.find("Failed to open") != std::string::npos);
  }

  SECTION("Too small file error") {
    // Create a minimal invalid buffer
    std::vector<uint8_t> tiny_buffer(10, 0);
    auto result = SpeParser::parse_buffer(tiny_buffer);

    CHECK(!result.success);
    CHECK(!result.errors.empty());
  }
}
