#include <catch2/catch_test_macros.hpp>
#include <sstream>
#include <fstream>
#include <iostream>
#include "../src/parsers/lin_parser.h"

using namespace pickett;

TEST_CASE("LinParser parses valid record from test data", "[lin_parser]") {
    INFO("Testing single .lin record parsing with fixed-width QN fields");
    
    // First line from cyanomethcycloprop.lin:
    // 68  4 64  1 67  5 63  1  0  0  0  0   303733.727837     0.050000  2.50E-05
    std::istringstream input(" 68  4 64  1 67  5 63  1  0  0  0  0   303733.727837     0.050000  2.50E-05");
    
    LinParser parser;
    auto records = parser.parse(input);
    
    CAPTURE(records.size());
    REQUIRE(records.size() == 1);
    
    INFO("Checking quantum numbers (fixed-width positions 1-36)");
    for (int i = 0; i < 12; ++i) {
        CAPTURE(i, records[0].qn[i]);
    }
    CHECK(records[0].qn[0] == 68);
    CHECK(records[0].qn[1] == 4);
    CHECK(records[0].qn[2] == 64);
    CHECK(records[0].qn[3] == 1);
    CHECK(records[0].qn[4] == 67);
    CHECK(records[0].qn[5] == 5);
    CHECK(records[0].qn[6] == 63);
    CHECK(records[0].qn[7] == 1);
    CHECK(records[0].qn[8] == 0);
    CHECK(records[0].qn[9] == 0);
    CHECK(records[0].qn[10] == 0);
    CHECK(records[0].qn[11] == 0);
    
    INFO("Checking frequency, error, and weight values");
    CAPTURE(records[0].freq);
    CAPTURE(records[0].err);
    CAPTURE(records[0].wt);
    CHECK(records[0].freq == 303733.727837);
    CHECK(records[0].err == 0.050000);
    CHECK(records[0].wt == 2.50E-05);
}

TEST_CASE("LinParser parses multiple records", "[lin_parser]") {
    std::istringstream input(R"( 68  4 64  1 67  5 63  1  0  0  0  0   303733.727837     0.050000  2.50E-05
 71  0 71  1 70  0 70  1  0  0  0  0   303845.604135     0.050000  2.07E-04)");
    
    LinParser parser;
    auto records = parser.parse(input);
    
    INFO("Parsed " << records.size() << " records from 2-line input");
    REQUIRE(records.size() == 2);
    
    INFO("Checking second record frequency");
    CAPTURE(records[1].freq);
    CHECK(records[1].freq == 303845.604135);
}

TEST_CASE("LinParser skips blank lines and comments", "[lin_parser]") {
    std::istringstream input(R"(! This is a comment
 68  4 64  1 67  5 63  1  0  0  0  0   303733.727837     0.050000  2.50E-05

 71  0 71  1 70  0 70  1  0  0  0  0   303845.604135     0.050000  2.07E-04)");
    
    LinParser parser;
    auto records = parser.parse(input);
    
    INFO("Should parse 2 records, skipping comment (!) and blank lines");
    REQUIRE(records.size() == 2);
    CHECK(records[0].freq == 303733.727837);
    CHECK(records[1].freq == 303845.604135);
}

TEST_CASE("LinParser handles empty file", "[lin_parser]") {
    std::istringstream input("");
    
    LinParser parser;
    auto records = parser.parse(input);
    
    INFO("Empty file should produce empty records vector");
    REQUIRE(records.empty());
}

TEST_CASE("LinParser handles file with only comments", "[lin_parser]") {
    std::istringstream input(R"(! Header comment
! Another comment)");
    
    LinParser parser;
    auto records = parser.parse(input);
    
    INFO("Comment-only file should produce empty records vector");
    REQUIRE(records.empty());
}

TEST_CASE("LinParser handles scientific notation", "[lin_parser]") {
    std::istringstream input(" 68  4 64  1 67  5 63  1  0  0  0  0   303733.727837     0.050000  1.99E-04");
    
    LinParser parser;
    auto records = parser.parse(input);
    
    INFO("Testing scientific notation parsing in WT field (1.99E-04)");
    REQUIRE(records.size() == 1);
    CAPTURE(records[0].wt);
    CHECK(records[0].wt == 1.99E-04);
}

TEST_CASE("LinParser parses actual test file", "[lin_parser]") {
    std::string test_file = std::string(TEST_DATA_DIR) + "/cyanomethcycloprop.lin";
    INFO("Reading test file: " << test_file);
    
    LinParser parser;
    auto records = parser.parse_file(test_file);
    
    CAPTURE(records.size());
    REQUIRE(!records.empty());
    CHECK(records.size() == 2506);
    
    INFO("Checking first record (line 1)");
    CAPTURE(records[0].qn[0], records[0].qn[1], records[0].qn[2], records[0].qn[3]);
    CAPTURE(records[0].freq);
    CHECK(records[0].qn[0] == 68);
    CHECK(records[0].qn[1] == 4);
    CHECK(records[0].freq == 303733.727837);
    
    INFO("Checking last record (line 2506)");
    CAPTURE(records[2505].qn[0], records[2505].qn[1]);
    CAPTURE(records[2505].freq);
    CHECK(records[2505].qn[0] == 61);
    CHECK(records[2505].qn[1] == 5);
    CHECK(records[2505].freq == 277125.104928);
    
    INFO("Test file parsed successfully with " << records.size() << " records");
}

TEST_CASE("LinParser parses all 12 quantum numbers correctly", "[lin_parser]") {
    // Explicit test that all 12 QN positions are parsed
    std::istringstream input("  1  2  3  4  5  6  7  8  9 10 11 12  100000.000000     0.010000  1.00E+00");
    
    LinParser parser;
    auto records = parser.parse(input);
    
    REQUIRE(records.size() == 1);
    
    INFO("Verifying all 12 QN fields (3 chars each, positions 1-36)");
    for (int i = 0; i < 12; ++i) {
        CAPTURE(i);
        CHECK(records[0].qn[i] == i + 1);  // Expect 1, 2, 3, ... 12
    }
    
    INFO("Verifying QN positions map correctly to input columns");
    CHECK(records[0].qn[0] == 1);   // Pos 1-3
    CHECK(records[0].qn[11] == 12); // Pos 34-36
    CHECK(records[0].freq == 100000.0);
}

TEST_CASE("LinParser handles negative quantum numbers", "[lin_parser]") {
    // Test that negative QN values parse correctly
    std::istringstream input(" -1 -2 -3 -4 -5 -6 -7 -8 -9-10-11-12  100000.000000     0.010000  1.00E+00");
    
    LinParser parser;
    auto records = parser.parse(input);
    
    REQUIRE(records.size() == 1);
    CHECK(records[0].qn[0] == -1);
    CHECK(records[0].qn[1] == -2);
    CHECK(records[0].qn[11] == -12);
}

TEST_CASE("LinParser returns empty for non-existent file", "[lin_parser]") {
    LinParser parser;
    auto records = parser.parse_file("nonexistent_file.lin");
    
    INFO("Non-existent file should return empty vector, not throw");
    REQUIRE(records.empty());
}
