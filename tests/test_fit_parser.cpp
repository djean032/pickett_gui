#include <catch2/catch_test_macros.hpp>
#include <catch2/catch_approx.hpp>
#include <filesystem>
#include <fstream>
#include <string>

#include "parsers/fit_parser.h"

using namespace pickett;
namespace fs = std::filesystem;

std::string get_test_data_path(const std::string &filename) {
  return (fs::path(TEST_DATA_DIR) / filename).string();
}

TEST_CASE("Fit parser header parsing", "[fit]") {
  SECTION("Parse actual fit file header") {
    auto result = FitParser::parse_file(get_test_data_path("cyanomethcycloprop.fit"));
    
    REQUIRE(result.success);
    REQUIRE(result.errors.empty());
    
    // Title includes molecule name and timestamp, check it starts with expected text
    CHECK(result.header.title.find("(3-Cyano)Methylenecyclopropane") == 0);
    CHECK(result.header.lines_requested == 2446);
    CHECK(result.header.num_parameters == 207);
    CHECK(result.header.num_iterations == 15);
    CHECK(result.header.marquardt_param == Catch::Approx(0.0));
    CHECK(result.header.max_obs_calc_error == Catch::Approx(1.0e6));
  }
}

TEST_CASE("Fit parser parameter parsing", "[fit]") {
  SECTION("Parse first few parameters") {
    auto result = FitParser::parse_file(get_test_data_path("cyanomethcycloprop.fit"));
    
    REQUIRE(result.success);
    REQUIRE(result.parameters.size() == 207);
    
    // Check first parameter (A_gs)
    CHECK(result.parameters[0].index == 1);
    CHECK(result.parameters[0].copy == 1);
    CHECK(result.parameters[0].idpar == 1000000);
    CHECK(result.parameters[0].value == Catch::Approx(7.7805592632577E+003));
    CHECK(result.parameters[0].label == "A_gs");
    
    // Check second parameter (B_gs)
    CHECK(result.parameters[1].index == 2);
    CHECK(result.parameters[1].idpar == 2000000);
    CHECK(result.parameters[1].label == "B_gs");
    
    // Check a vibrationally excited state parameter (A_27)
    CHECK(result.parameters[24].index == 25);
    CHECK(result.parameters[24].idpar == 1000101);
    CHECK(result.parameters[24].label == "A_27");
  }
}

TEST_CASE("Fit parser line record parsing", "[fit]") {
  SECTION("Parse line records including blends") {
    auto result = FitParser::parse_file(get_test_data_path("cyanomethcycloprop.fit"));
    
    REQUIRE(result.success);
    REQUIRE(result.lines.size() > 0);
    
    // Check first line (should be a blend master)
    // This molecule has 4 QNs per state (N, Ka, Kc, v), 2 states = 8 total QNs
    CHECK(result.lines[0].seq_number == 1);
    CHECK(result.lines[0].qn[0] == 68);  // N upper
    CHECK(result.lines[0].qn[1] == 4);   // Ka upper
    CHECK(result.lines[0].qn[2] == 64);  // Kc upper
    CHECK(result.lines[0].qn[3] == 1);   // v upper
    CHECK(result.lines[0].qn[4] == 67);  // N lower
    CHECK(result.lines[0].qn[5] == 5);   // Ka lower
    CHECK(result.lines[0].qn[6] == 63);  // Kc lower
    CHECK(result.lines[0].qn[7] == 1);   // v lower
    // QNs 8-11 are unused (0) for this molecule
    CHECK(result.lines[0].exp_freq == Catch::Approx(303733.72784));
    CHECK(result.lines[0].calc_freq == Catch::Approx(303733.73623));
    CHECK(result.lines[0].diff == Catch::Approx(-0.00839));
    CHECK(result.lines[0].exp_err == Catch::Approx(0.05000));
    CHECK(result.lines[0].est_err == Catch::Approx(0.00000));
    
    // Check blend fields on first line
    REQUIRE(result.lines[0].avg_calc_freq.has_value());
    CHECK(result.lines[0].avg_calc_freq.value() == Catch::Approx(303733.73742));
    REQUIRE(result.lines[0].avg_diff.has_value());
    CHECK(result.lines[0].avg_diff.value() == Catch::Approx(-0.00958));
    REQUIRE(result.lines[0].wt.has_value());
    CHECK(result.lines[0].wt.value() == Catch::Approx(0.0558));
    CHECK(result.lines[0].is_blend == true);
    CHECK(result.lines[0].blend_master_line == 1);
    
    // Check second line (blend component)
    CHECK(result.lines[1].seq_number == 2);
    CHECK(result.lines[1].exp_freq == Catch::Approx(303733.72784)); // Same frequency
    CHECK(result.lines[1].is_blend == true);
    CHECK(result.lines[1].blend_master_line == 1); // Points to line 1
    
    // Check line 9 (non-blended)
    if (result.lines.size() > 8) {
      CHECK(result.lines[8].seq_number == 9);
      CHECK(result.lines[8].exp_freq == Catch::Approx(304245.44667));
      CHECK(result.lines[8].is_blend == false);
      CHECK(!result.lines[8].avg_calc_freq.has_value());
      CHECK(!result.lines[8].avg_diff.has_value());
      CHECK(!result.lines[8].wt.has_value());
      CHECK(result.lines[8].blend_master_line == -1);
    }
  }
}

TEST_CASE("Fit parser correlation matrix parsing", "[fit]") {
  SECTION("Parse correlation matrix") {
    auto result = FitParser::parse_file(get_test_data_path("cyanomethcycloprop.fit"));
    
    REQUIRE(result.success);
    
    // For 207 parameters, correlation matrix should have entries
    // It's a lower triangle: 207 * 206 / 2 = 21,321 entries
    CHECK(result.correlations.size() > 0);
    
    // All correlations should have valid row/col indices
    for (const auto& corr : result.correlations) {
      CHECK(corr.row >= 1);
      CHECK(corr.row <= 207);
      CHECK(corr.col >= 1);
      CHECK(corr.col <= 207);
    }
    
    // Check that we got the expected number of correlation entries
    // For 207 params, full off-diagonal (excluding diagonal) has 207×207 - 207 = 42,642 entries
    CHECK(result.correlations.size() == 42642);
    
    // Check that we have the expected approximate number of entries
    // (allowing some tolerance since the file may have sparse entries)
    CHECK(result.correlations.size() >= 10000); // Should have at least many entries
  }
}

TEST_CASE("Fit parser integration - full file", "[fit]") {
  SECTION("Parse complete fit file and validate counts") {
    auto result = FitParser::parse_file(get_test_data_path("cyanomethcycloprop.fit"));
    
    REQUIRE(result.success);
    
    // Validate parameter count from header
    CHECK(result.parameters.size() == result.header.num_parameters);
    
    // Validate lines are present
    CHECK(result.lines.size() > 2000); // Should have many lines
    
    // Check that line sequence numbers are mostly sequential
    int sequential_count = 0;
    for (size_t i = 1; i < result.lines.size(); i++) {
      if (result.lines[i].seq_number == result.lines[i-1].seq_number + 1) {
        sequential_count++;
      }
    }
    // Most should be sequential (allowing for some blends which share numbers)
    CHECK(sequential_count > static_cast<int>(result.lines.size() * 0.9));
  }
}

TEST_CASE("Fit parser error handling", "[fit]") {
  SECTION("Non-existent file") {
    auto result = FitParser::parse_file("nonexistent.fit");
    
    CHECK(!result.success);
    CHECK(!result.errors.empty());
    CHECK(result.errors[0].first == 0); // Line 0 for file-level errors
  }
}

TEST_CASE("Fit parser parameter IDPAR values", "[fit]") {
  SECTION("Verify IDPAR values are stored correctly") {
    auto result = FitParser::parse_file(get_test_data_path("cyanomethcycloprop.fit"));
    
    REQUIRE(result.success);
    REQUIRE(result.parameters.size() == 207);
    
    // Check some known IDPAR values from the file
    // Ground state rotational constants
    CHECK(result.parameters[0].idpar == 1000000);  // A_gs
    CHECK(result.parameters[1].idpar == 2000000);  // B_gs
    CHECK(result.parameters[2].idpar == 3000000);  // C_gs
    
    // Quartic distortion constants
    CHECK(result.parameters[3].idpar == 20000);    // DJ_gs
    CHECK(result.parameters[4].idpar == 110000);   // DJK_gs
    
    // Excited vibrational state constants
    CHECK(result.parameters[24].idpar == 1000101); // A_27
    CHECK(result.parameters[25].idpar == 2000101); // B_27
  }
}

TEST_CASE("Fit parser blend detection", "[fit]") {
  SECTION("Count blend groups and components") {
    auto result = FitParser::parse_file(get_test_data_path("cyanomethcycloprop.fit"));
    
    REQUIRE(result.success);
    
    int blend_masters = 0;
    int blend_components = 0;
    int non_blends = 0;
    
    for (const auto& line : result.lines) {
      if (line.is_blend) {
        if (line.blend_master_line == line.seq_number) {
          blend_masters++;
        } else {
          blend_components++;
        }
      } else {
        non_blends++;
      }
    }
    
    // There should be many blends in this file
    CHECK(blend_masters > 100);
    CHECK(blend_components > 100);
    CHECK(non_blends > 100);
    
    // Total should add up
    CHECK(blend_masters + blend_components + non_blends == 
          static_cast<int>(result.lines.size()));
  }
}

TEST_CASE("Fit parser updated parameters", "[fit]") {
  SECTION("Parse updated parameters from cyanomethcycloprop.fit NEW PARAMETER section") {
    auto result = FitParser::parse_file(get_test_data_path("cyanomethcycloprop.fit"));
    
    REQUIRE(result.success);
    
    // Should have 207 updated parameters
    REQUIRE(result.updated_parameters.size() == 207);
    
    // Check first updated parameter (A_gs)
    CHECK(result.updated_parameters[0].index == 1);
    CHECK(result.updated_parameters[0].idpar == 1000000);
    CHECK(result.updated_parameters[0].label == "A_gs");
    // Value should be close to 7780.559263258 (from NEW PARAMETER section)
    CHECK(result.updated_parameters[0].value == Catch::Approx(7780.559263258));
    
    // Check second updated parameter (B_gs)
    CHECK(result.updated_parameters[1].index == 2);
    CHECK(result.updated_parameters[1].idpar == 2000000);
    CHECK(result.updated_parameters[1].label == "B_gs");
    CHECK(result.updated_parameters[1].value == Catch::Approx(2566.811880943));
    
    // Check a few more updated parameters
    CHECK(result.updated_parameters[2].label == "C_gs");
    CHECK(result.updated_parameters[3].label == "-DJ_gs");
    CHECK(result.updated_parameters[24].label == "A_27");
    
    // Updated parameters should be different from initial parameters
    // (the fit should have converged to slightly different values)
    CHECK(result.parameters[0].value != result.updated_parameters[0].value);
  }
  
  SECTION("Parse CH3CN_gs.fit file") {
    auto result = FitParser::parse_file(get_test_data_path("CH3CN_gs.fit"));
    
    REQUIRE(result.success);
    
    // Header checks
    CHECK(result.header.title.find("CH3CN") == 0);
    CHECK(result.header.lines_requested == 254);
    CHECK(result.header.num_parameters == 30);
    CHECK(result.header.num_iterations == 5);
    
    // Should have 30 initial parameters
    REQUIRE(result.parameters.size() == 30);
    
    // Check first parameter (A-B)
    CHECK(result.parameters[0].index == 1);
    CHECK(result.parameters[0].idpar == 1099);
    CHECK(result.parameters[0].label == "A-B");
    CHECK(result.parameters[0].value == Catch::Approx(1.4890007449653E+005));
    
    // Should have 254 line records
    REQUIRE(result.lines.size() == 254);
    
    // Check first line record (CH3CN has 8 QNs: 4 per state for symmetric top)
    // Format: J, K, ?, F for upper and lower states
    CHECK(result.lines[0].seq_number == 1);
    CHECK(result.lines[0].qn[0] == 1);   // J upper
    CHECK(result.lines[0].qn[1] == 0);   // K upper  
    CHECK(result.lines[0].qn[2] == 1);   // (unused/placeholder)
    CHECK(result.lines[0].qn[3] == 1);   // F upper
    CHECK(result.lines[0].qn[4] == 0);   // J lower
    CHECK(result.lines[0].qn[5] == 0);   // K lower
    CHECK(result.lines[0].qn[6] == 1);   // (unused/placeholder)
    CHECK(result.lines[0].qn[7] == 1);   // F lower
    CHECK(result.lines[0].exp_freq == Catch::Approx(18396.72530));
    
    // Should have 18 updated parameters (only independent ones listed)
    // The NEW PARAMETER section in this file lists only 18 parameters
    REQUIRE(result.updated_parameters.size() == 18);
    
    // Check first updated parameter
    CHECK(result.updated_parameters[0].index == 1);
    CHECK(result.updated_parameters[0].idpar == 1099);
    CHECK(result.updated_parameters[0].label == "A-B");
    CHECK(result.updated_parameters[0].value == Catch::Approx(148900.074));
    
    // Should have correlation entries (18 params = 18*17 = 306 off-diagonal)
    CHECK(result.correlations.size() > 0);
    CHECK(result.correlations.size() == 18 * 17);  // 306 entries
    
    // Verify all correlations have valid row/col indices
    for (const auto& corr : result.correlations) {
      CHECK(corr.row >= 1);
      CHECK(corr.row <= 18);
      CHECK(corr.col >= 1);
      CHECK(corr.col <= 18);
      CHECK(corr.row != corr.col);
    }
  }
}
