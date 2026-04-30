#include <catch2/catch_test_macros.hpp>
#include <catch2/catch_approx.hpp>
#include <sstream>
#include <fstream>
#include <iostream>
#include "../src/parsers/lin_parser.h"

using namespace pickett;

TEST_CASE("LinParser parses valid record from test data", "[lin_parser]") {
    INFO("Testing single .lin record parsing with fixed-width QN fields");
    
    // First line from cyanomethcycloprop.lin:
    // 68  4 64  1 67  5 63  1  0  0  0  0   303733.727837     0.050000  2.50E-05
    std::string test_file = std::string(TEST_DATA_DIR) + "/test_single.lin";
    {
        std::ofstream f(test_file);
        f << " 68  4 64  1 67  5 63  1  0  0  0  0   303733.727837     0.050000  2.50E-05\n";
    }
    
    auto result = LinParser::parseFile(test_file);
    CHECK(result.has_value());
    REQUIRE(result->records.size() == 1);
    REQUIRE(result->errors.empty());
    
    CHECK(result->records[0].qn[0] == 68);
    CHECK(result->records[0].qn[1] == 4);
    CHECK(result->records[0].qn[2] == 64);
    CHECK(result->records[0].qn[3] == 1);
    CHECK(result->records[0].qn[4] == 67);
    CHECK(result->records[0].qn[5] == 5);
    CHECK(result->records[0].qn[6] == 63);
    CHECK(result->records[0].qn[7] == 1);
    CHECK(result->records[0].qn[8] == 0);
    CHECK(result->records[0].qn[9] == 0);
    CHECK(result->records[0].qn[10] == 0);
    CHECK(result->records[0].qn[11] == 0);
    CHECK(result->records[0].freq == 303733.727837);
    CHECK(result->records[0].err == 0.050000);
    CHECK(result->records[0].wt == 2.50E-05);
    
    std::remove(test_file.c_str());
}

TEST_CASE("LinParser parses multiple records", "[lin_parser]") {
    std::string test_file = std::string(TEST_DATA_DIR) + "/test_multi.lin";
    {
        std::ofstream f(test_file);
        f << " 68  4 64  1 67  5 63  1  0  0  0  0   303733.727837     0.050000  2.50E-05\n";
        f << " 71  0 71  1 70  0 70  1  0  0  0  0   303845.604135     0.050000  2.07E-04\n";
    }
    
    auto result = LinParser::parseFile(test_file);
    CHECK(result.has_value());
    REQUIRE(result->records.size() == 2);
    REQUIRE(result->errors.empty());
    CHECK(result->records[1].freq == 303845.604135);
    
    std::remove(test_file.c_str());
}

TEST_CASE("LinParser skips blank lines and comments", "[lin_parser]") {
    std::string test_file = std::string(TEST_DATA_DIR) + "/test_skip.lin";
    {
        std::ofstream f(test_file);
        f << "! This is a comment\n";
        f << " 68  4 64  1 67  5 63  1  0  0  0  0   303733.727837     0.050000  2.50E-05\n";
        f << "\n";
        f << " 71  0 71  1 70  0 70  1  0  0  0  0   303845.604135     0.050000  2.07E-04\n";
    }
    
    auto result = LinParser::parseFile(test_file);
    CHECK(result.has_value());
    REQUIRE(result->records.size() == 2);
    REQUIRE(result->errors.empty());
    CHECK(result->records[0].freq == 303733.727837);
    CHECK(result->records[1].freq == 303845.604135);
    
    std::remove(test_file.c_str());
}

TEST_CASE("LinParser handles empty file", "[lin_parser]") {
    std::string test_file = std::string(TEST_DATA_DIR) + "/test_empty.lin";
    {
        std::ofstream f(test_file);
        f << "";
    }
    
    auto result = LinParser::parseFile(test_file);
    CHECK(result.has_value());
    CHECK(result->records.empty());
    CHECK(result->errors.empty());
    
    std::remove(test_file.c_str());
}

TEST_CASE("LinParser handles file with only comments", "[lin_parser]") {
    std::string test_file = std::string(TEST_DATA_DIR) + "/test_comments.lin";
    {
        std::ofstream f(test_file);
        f << "! Header comment\n";
        f << "! Another comment\n";
    }
    
    auto result = LinParser::parseFile(test_file);
    CHECK(result.has_value());
    CHECK(result->records.empty());
    CHECK(result->errors.empty());
    
    std::remove(test_file.c_str());
}

TEST_CASE("LinParser handles scientific notation", "[lin_parser]") {
    std::string test_file = std::string(TEST_DATA_DIR) + "/test_sci.lin";
    {
        std::ofstream f(test_file);
        f << " 68  4 64  1 67  5 63  1  0  0  0  0   303733.727837     0.050000  1.99E-04\n";
    }
    
    auto result = LinParser::parseFile(test_file);
    CHECK(result.has_value());
    REQUIRE(result->records.size() == 1);
    REQUIRE(result->errors.empty());
    CHECK(result->records[0].wt == 1.99E-04);
    
    std::remove(test_file.c_str());
}

TEST_CASE("LinParser parses actual test file", "[lin_parser]") {
    auto result = LinParser::parseFile(std::string(TEST_DATA_DIR) + "/cyanomethcycloprop.lin");
    
    INFO("Success: " << result.has_value());
    INFO("Records: " << result->records.size());
    INFO("Errors: " << result->errors.size());
    
    CHECK(result.has_value());
    CHECK(!result->records.empty());
    
    // Known size from inspection - may have some skipped lines
    if (!result->records.empty()) {
        CHECK(result->records.size() == 2506);
        
        // Check first record
        CHECK(result->records[0].qn[0] == 68);
        CHECK(result->records[0].qn[1] == 4);
        CHECK(result->records[0].freq == 303733.727837);
        
        // Check last record
        CHECK(result->records[2505].qn[0] == 61);
        CHECK(result->records[2505].qn[1] == 5);
        CHECK(result->records[2505].freq == 277125.104928);
    }
}

TEST_CASE("LinParser returns error for non-existent file", "[lin_parser]") {
    auto result = LinParser::parseFile("nonexistent_file.lin");
    
    CHECK(!result.has_value());
    REQUIRE(!result.error().empty());
    CHECK(result.error()[0].first == 0);  // Line 0 = file-level error
}

TEST_CASE("LinParser parses all 12 quantum numbers correctly", "[lin_parser]") {
    std::string test_file = std::string(TEST_DATA_DIR) + "/test_all_qn.lin";
    {
        std::ofstream f(test_file);
        f << "  1  2  3  4  5  6  7  8  9 10 11 12  100000.000000     0.010000  1.00E+00\n";
    }
    
    auto result = LinParser::parseFile(test_file);
    CHECK(result.has_value());
    REQUIRE(result->records.size() == 1);
    REQUIRE(result->errors.empty());
    
    INFO("Verifying all 12 QN fields (3 chars each, positions 1-36)");
    for (int i = 0; i < 12; ++i) {
        CAPTURE(i);
        CHECK(result->records[0].qn[i] == i + 1);
    }
    
    std::remove(test_file.c_str());
}

TEST_CASE("LinParser handles negative quantum numbers", "[lin_parser]") {
    std::string test_file = std::string(TEST_DATA_DIR) + "/test_neg.lin";
    {
        std::ofstream f(test_file);
        f << " -1 -2 -3 -4 -5 -6 -7 -8 -9-10-11-12  100000.000000     0.010000  1.00E+00\n";
    }
    
    auto result = LinParser::parseFile(test_file);
    CHECK(result.has_value());
    REQUIRE(result->records.size() == 1);
    
    CHECK(result->records[0].qn[0] == -1);
    CHECK(result->records[0].qn[1] == -2);
    CHECK(result->records[0].qn[11] == -12);
    
    std::remove(test_file.c_str());
}

TEST_CASE("LinParser reports line-level errors", "[lin_parser]") {
    std::string test_file = std::string(TEST_DATA_DIR) + "/test_errors.lin";
    {
        std::ofstream f(test_file);
        f << " 68  4 64  1 67  5 63  1  0  0  0  0   303733.727837     0.050000  2.50E-05\n";
        f << "THIS IS A BAD LINE\n";  // Line 2 - too short
        f << " 71  0 71  1 70  0 70  1  0  0  0  0   303845.604135     0.050000  2.07E-04\n";
    }
    
    auto result = LinParser::parseFile(test_file);
    CHECK(result.has_value());
    REQUIRE(result->records.size() == 2);  // Skip bad line, get 2 good ones
    REQUIRE(result->errors.size() == 1);  // One error reported
    CHECK(result->errors[0].first == 2);  // Error on line 2
    
    std::remove(test_file.c_str());
}

TEST_CASE("LinParser write roundtrip with SPFIT", "[lin_parser]") {
    // Parse original LIN file
    auto original = LinParser::parseFile(std::string(TEST_DATA_DIR) + "/cyanomethcycloprop.lin");
    REQUIRE(original.has_value());
    REQUIRE(original->records.size() > 0);
    
    // Write to _bak.lin file
    std::string bak_file = std::string(TEST_DATA_DIR) + "/cyanomethcycloprop_bak.lin";
    std::string error;
    bool write_ok = LinParser::writeFile(bak_file, original.value(), error);
    CHECK(write_ok);
    
    // Parse the written file and verify it matches
    auto roundtrip = LinParser::parseFile(bak_file);
    CHECK(roundtrip.has_value());
    REQUIRE(roundtrip.has_value());
    CHECK(roundtrip->records.size() == original->records.size());
    
    // Compare first and last records
    if (!roundtrip->records.empty()) {
        CHECK(roundtrip->records[0].qn[0] == original->records[0].qn[0]);
        CHECK(roundtrip->records[0].freq == Catch::Approx(original->records[0].freq));
        CHECK(roundtrip->records.back().qn[0] == original->records.back().qn[0]);
        CHECK(roundtrip->records.back().freq == Catch::Approx(original->records.back().freq));
    }
}
