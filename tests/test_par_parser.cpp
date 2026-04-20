#include <catch2/catch_test_macros.hpp>
#include <catch2/catch_approx.hpp>
#include <iostream>
#include <fstream>
#include "../src/parsers/par_parser.h"

using namespace pickett;

TEST_CASE("ParParser parses actual test file", "[par_parser]") {
    auto result = ParParser::parse_file(std::string(TEST_DATA_DIR) + "/cyanomethcycloprop.par");
    
    INFO("Success: " << result.success);
    INFO("Title: " << result.header.title);
    INFO("NPAR: " << result.header.npar);
    INFO("Options: " << result.options.size());
    INFO("Parameters: " << result.parameters.size());
    INFO("Errors: " << result.errors.size());
    
    CHECK(result.success);
    CHECK(!result.header.title.empty());
    CHECK(result.header.npar > 0);
    CHECK(!result.options.empty());
    CHECK(!result.parameters.empty());
}

TEST_CASE("ParParser validates CHR field", "[par_parser]") {
    // Test invalid CHR
    std::string test_file = std::string(TEST_DATA_DIR) + "/test_invalid_chr.par";
    {
        std::ofstream f(test_file);
        f << "Test Title\n";
        f << "100 1000 10 0 0.0 0.0 1.0 1.0\n";
        f << "x   1   18  ,    ,  , ,    ,     ,     ,     ,    ,,,,\n";  // Invalid CHR 'x'
    }
    
    auto result = ParParser::parse_file(test_file);
    
    // Should have an error about invalid CHR
    bool found_chr_error = false;
    for (const auto& err : result.errors) {
        if (err.second.find("Invalid CHR") != std::string::npos) {
            found_chr_error = true;
            break;
        }
    }
    CHECK(found_chr_error);
    
    std::remove(test_file.c_str());
}

TEST_CASE("ParParser is_valid_chr", "[par_parser]") {
    CHECK(ParParser::is_valid_chr('a'));
    CHECK(ParParser::is_valid_chr('g'));
    CHECK(ParParser::is_valid_chr('s'));
    CHECK(!ParParser::is_valid_chr('x'));
    CHECK(!ParParser::is_valid_chr('A'));
    CHECK(!ParParser::is_valid_chr('1'));
}

TEST_CASE("ParParser warns on parameter count mismatch", "[par_parser]") {
    std::string test_file = std::string(TEST_DATA_DIR) + "/test_npar.par";
    {
        std::ofstream f(test_file);
        f << "Test Title\n";
        f << "5 1000 10 0 0.0 0.0 1.0 1.0\n";  // NPAR = 5
        f << "a   1   18  ,    ,  , ,    ,     ,     ,     ,    ,,,,\n";
        f << "1000000  1.0  0.1 /A\n";
        f << "2000000  2.0  0.2 /B\n";  // Only 2 params, not 5
    }
    
    auto result = ParParser::parse_file(test_file);
    CHECK(result.success);
    CHECK(result.parameters.size() == 2);
    
    // Should have warning about mismatch
    bool found_warning = false;
    for (const auto& err : result.errors) {
        if (err.second.find("Expected 5 parameters") != std::string::npos) {
            found_warning = true;
            break;
        }
    }
    CHECK(found_warning);
    
    std::remove(test_file.c_str());
}

TEST_CASE("ParParser skips comment lines", "[par_parser]") {
    std::string test_file = std::string(TEST_DATA_DIR) + "/test_comment.par";
    {
        std::ofstream f(test_file);
        f << "Test Title\n";
        f << "2 1000 10 0 0.0 0.0 1.0 1.0\n";
        f << "a   1   18  ,    ,  , ,    ,     ,     ,     ,    ,,,,\n";
        f << "1000000  1.0  0.1 /A\n";
        f << "! This is a comment\n";
        f << "2000000  2.0  0.2 /B\n";
    }
    
    auto result = ParParser::parse_file(test_file);
    CHECK(result.success);
    CHECK(result.parameters.size() == 2);
    
    std::remove(test_file.c_str());
}

TEST_CASE("ParParser handles missing erpar", "[par_parser]") {
    std::string test_file = std::string(TEST_DATA_DIR) + "/test_no_erpar.par";
    {
        std::ofstream f(test_file);
        f << "Test Title\n";
        f << "1 1000 10 0 0.0 0.0 1.0 1.0\n";
        f << "a   1   18  ,    ,  , ,    ,     ,     ,     ,    ,,,,\n";
        f << "1000000  1.0 /A\n";  // Missing erpar
    }
    
    auto result = ParParser::parse_file(test_file);
    CHECK(result.success);
    REQUIRE(result.parameters.size() == 1);
    CHECK(result.parameters[0].par == 1.0);
    CHECK(result.parameters[0].erpar == 0.0);  // Default
    CHECK(result.parameters[0].label == "A");
    
    std::remove(test_file.c_str());
}

TEST_CASE("ParParser handles file not found", "[par_parser]") {
    auto result = ParParser::parse_file("nonexistent_file.par");
    
    CHECK(!result.success);
    CHECK(result.parameters.empty());
    REQUIRE(!result.errors.empty());
    CHECK(result.errors[0].first == 0);
}

TEST_CASE("ParParser extracts header fields correctly", "[par_parser]") {
    std::string test_file = std::string(TEST_DATA_DIR) + "/test_header.par";
    {
        std::ofstream f(test_file);
        f << "Test Molecule Title\n";
        f << "900 9258 15 0 1.0 10.0 1.0 1.0\n";
        f << "a   1   18  ,    ,  , ,    ,     ,     ,     ,    ,,,,\n";
        f << "1000000  1.0  0.1 /A\n";
    }
    
    auto result = ParParser::parse_file(test_file);
    CHECK(result.success);
    CHECK(result.header.title == "Test Molecule Title");
    CHECK(result.header.npar == 900);
    CHECK(result.header.nline == 9258);
    CHECK(result.header.nitr == 15);
    CHECK(result.header.nxpar == 0);
    CHECK(result.header.thresh == 1.0);
    CHECK(result.header.errtst == 10.0);
    CHECK(result.header.frac == 1.0);
    CHECK(result.header.cal == 1.0);
    
    std::remove(test_file.c_str());
}

TEST_CASE("ParParser extracts option fields correctly", "[par_parser]") {
    std::string test_file = std::string(TEST_DATA_DIR) + "/test_options.par";
    {
        std::ofstream f(test_file);
        f << "Test Title\n";
        f << "1 1000 10 0 0.0 0.0 1.0 1.0\n";
        f << "a   1   18  0    0  0 0    1     2     100   0    0,0,0\n";
        f << "1000000  1.0  0.1 /A\n";
    }
    
    auto result = ParParser::parse_file(test_file);
    CHECK(result.success);
    REQUIRE(result.options.size() == 1);
    
    const auto& opt = result.options[0];
    CHECK(opt.chr == 'a');
    CHECK(opt.spino == 1);
    CHECK(opt.nvib == 18);
    CHECK(opt.knmin == 0);
    CHECK(opt.knmax == 0);
    CHECK(opt.ixx == 0);
    CHECK(opt.iax == 0);
    CHECK(opt.wtpl == 1);
    CHECK(opt.wtmn == 2);
    CHECK(opt.vsym == 100);
    CHECK(opt.ewt == 0);
    CHECK(opt.diag == 0);
    CHECK(opt.xopt.value_or(0) == 0);
    
    std::remove(test_file.c_str());
}

TEST_CASE("ParParser handles optional values correctly", "[par_parser]") {
    std::string test_file = std::string(TEST_DATA_DIR) + "/test_optional.par";
    {
        std::ofstream f(test_file);
        f << "Test Title\n";
        f << "1 1000 10 0 0.0 0.0 1.0 1.0\n";
        f << "a   1   18  ,    ,  , ,    ,     ,     ,     ,    ,,,,\n";  // Many commas = optional
        f << "1000000  1.0  0.1 /A\n";
    }
    
    auto result = ParParser::parse_file(test_file);
    CHECK(result.success);
    REQUIRE(result.options.size() == 1);
    
    const auto& opt = result.options[0];
    CHECK(opt.chr == 'a');
    CHECK(opt.spino == 1);
    CHECK(opt.nvib == 18);
    CHECK(!opt.knmin.has_value());  // Missing = std::nullopt
    CHECK(!opt.knmax.has_value());
    CHECK(!opt.vsym.has_value());  // VSYM not provided = nullopt
    
    std::remove(test_file.c_str());
}

TEST_CASE("ParParser extracts parameter with label", "[par_parser]") {
    std::string test_file = std::string(TEST_DATA_DIR) + "/test_param_label.par";
    {
        std::ofstream f(test_file);
        f << "Test Title\n";
        f << "1 1000 10 0 0.0 0.0 1.0 1.0\n";
        f << "a   1   18  ,    ,  , ,    ,     ,     ,     ,    ,,,,\n";
        f << "1000000  7.780559263257653E+003  1.00000000E-037 /A_gs\n";
    }
    
    auto result = ParParser::parse_file(test_file);
    CHECK(result.success);
    REQUIRE(result.parameters.size() == 1);
    
    const auto& p = result.parameters[0];
    CHECK(p.idpar == 1000000);
    CHECK(p.par == 7780.559263257653);
    CHECK(p.erpar == 1.0e-037);
    CHECK(p.label == "A_gs");
    
    std::remove(test_file.c_str());
}

TEST_CASE("ParParser handles negative IDPAR", "[par_parser]") {
    std::string test_file = std::string(TEST_DATA_DIR) + "/test_neg_idpar.par";
    {
        std::ofstream f(test_file);
        f << "Test Title\n";
        f << "2 1000 10 0 0.0 0.0 1.0 1.0\n";
        f << "a   1   18  ,    ,  , ,    ,     ,     ,     ,    ,,,,\n";
        f << "1000000  1.0  0.1 /Base\n";
        f << "-1000000  1.5  0.1 /Constrained\n";  // Negative = constrained ratio
    }
    
    auto result = ParParser::parse_file(test_file);
    CHECK(result.success);
    REQUIRE(result.parameters.size() == 2);
    CHECK(result.parameters[0].idpar == 1000000);
    CHECK(result.parameters[1].idpar == -1000000);
    
    std::remove(test_file.c_str());
}

TEST_CASE("ParParser handles Watson S set CHR", "[par_parser]") {
    auto result = ParParser::parse_file(std::string(TEST_DATA_DIR) + "/diethylether.par");
    
    INFO("Success: " << result.success);
    INFO("Title: " << result.header.title);
    INFO("NPAR: " << result.header.npar);
    INFO("Options: " << result.options.size());
    INFO("Parameters: " << result.parameters.size());
    
    CHECK(result.success);
    CHECK(!result.header.title.empty());
    CHECK(result.header.npar == 14);
    CHECK(result.options.size() == 1);
    CHECK(result.parameters.size() == 14);
    CHECK(result.errors.empty());
    
    // Verify Watson S set
    CHECK(result.options[0].chr == 's');
    CHECK(result.options[0].spino == 1);
    CHECK(result.options[0].nvib == 1);
}

TEST_CASE("ParParser write roundtrip with SPFIT", "[par_parser]") {
    // Parse original PAR file
    auto original = ParParser::parse_file(std::string(TEST_DATA_DIR) + "/cyanomethcycloprop.par");
    REQUIRE(original.success);
    REQUIRE(original.parameters.size() > 0);
    
    // Write to _bak.par file
    std::string bak_file = std::string(TEST_DATA_DIR) + "/cyanomethcycloprop_bak.par";
    std::string error;
    bool write_ok = ParParser::write_file(bak_file, original, error);
    CHECK(write_ok);
    
    // Parse the written file and verify it matches
    auto roundtrip = ParParser::parse_file(bak_file);
    CHECK(roundtrip.success);
    CHECK(roundtrip.parameters.size() == original.parameters.size());
    
    // Compare first few parameters
    if (roundtrip.parameters.size() >= 3) {
        CHECK(roundtrip.parameters[0].idpar == original.parameters[0].idpar);
        CHECK(roundtrip.parameters[0].par == Catch::Approx(original.parameters[0].par));
        CHECK(roundtrip.parameters[1].idpar == original.parameters[1].idpar);
        CHECK(roundtrip.parameters[1].par == Catch::Approx(original.parameters[1].par));
    }
}

TEST_CASE("ParParser comprehensive data roundtrip", "[par_parser]") {
    // Parse original PAR file
    auto original = ParParser::parse_file(std::string(TEST_DATA_DIR) + "/cyanomethcycloprop.par");
    REQUIRE(original.success);
    REQUIRE(original.parameters.size() > 0);
    
    // Write to _bak.par file
    std::string bak_file = std::string(TEST_DATA_DIR) + "/cyanomethcycloprop_bak.par";
    std::string error;
    bool write_ok = ParParser::write_file(bak_file, original, error);
    CHECK(write_ok);
    
    // Parse the written file
    auto roundtrip = ParParser::parse_file(bak_file);
    CHECK(roundtrip.success);
    
    // Compare headers
    CHECK(roundtrip.header.title == original.header.title);
    CHECK(roundtrip.header.npar == original.header.npar);
    CHECK(roundtrip.header.nline == original.header.nline);
    CHECK(roundtrip.header.nitr == original.header.nitr);
    CHECK(roundtrip.header.nxpar == original.header.nxpar);
    CHECK(roundtrip.header.thresh == Catch::Approx(original.header.thresh));
    CHECK(roundtrip.header.errtst == Catch::Approx(original.header.errtst));
    CHECK(roundtrip.header.frac == Catch::Approx(original.header.frac));
    CHECK(roundtrip.header.cal == Catch::Approx(original.header.cal));
    
    // Compare option lines
    REQUIRE(roundtrip.options.size() == original.options.size());
    for (size_t i = 0; i < original.options.size(); ++i) {
        const auto& orig_opt = original.options[i];
        const auto& rt_opt = roundtrip.options[i];
        
        CHECK(rt_opt.chr == orig_opt.chr);
        CHECK(rt_opt.spino == orig_opt.spino);
        CHECK(rt_opt.nvib == orig_opt.nvib);
        CHECK(rt_opt.knmin == orig_opt.knmin);
        CHECK(rt_opt.knmax == orig_opt.knmax);
        CHECK(rt_opt.ixx == orig_opt.ixx);
        CHECK(rt_opt.iax == orig_opt.iax);
        CHECK(rt_opt.wtpl == orig_opt.wtpl);
        CHECK(rt_opt.wtmn == orig_opt.wtmn);
        CHECK(rt_opt.vsym == orig_opt.vsym);
        CHECK(rt_opt.ewt == orig_opt.ewt);
        CHECK(rt_opt.diag == orig_opt.diag);
        CHECK(rt_opt.xopt == orig_opt.xopt);
    }
    
    // Compare all parameters
    REQUIRE(roundtrip.parameters.size() == original.parameters.size());
    for (size_t i = 0; i < original.parameters.size(); ++i) {
        const auto& orig_param = original.parameters[i];
        const auto& rt_param = roundtrip.parameters[i];
        
        CHECK(rt_param.idpar == orig_param.idpar);
        CHECK(rt_param.par == Catch::Approx(orig_param.par));
        CHECK(rt_param.erpar == Catch::Approx(orig_param.erpar));
        CHECK(rt_param.label == orig_param.label);
    }
    
    // Verify comments are preserved (lines after ! marker)
    CHECK(roundtrip.comments.size() == original.comments.size());
    for (size_t i = 0; i < original.comments.size(); ++i) {
        CHECK(roundtrip.comments[i] == original.comments[i]);
    }
}
