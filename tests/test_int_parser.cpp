#include <catch2/catch_test_macros.hpp>
#include <catch2/catch_approx.hpp>
#include <iostream>
#include <cmath>
#include "../src/parsers/int_parser.h"
#include "../src/parsers/par_parser.h"

using namespace pickett;

TEST_CASE("IntParser parses actual test file", "[int_parser]") {
    auto result = IntParser::parseFile(std::string(TEST_DATA_DIR) + "/cyanomethcycloprop.int");

    INFO("Success: " << result.has_value());
    INFO("Title: " << result->header.title);
    INFO("FLAGS: " << result->header.flags);
    INFO("IRFLG: " << result->header.irflg);
    INFO("OUTFLG: " << result->header.outflg);
    INFO("STRFLG: " << result->header.strflg);
    INFO("EGYFLG: " << result->header.egyflg);
    INFO("Dipoles: " << result->dipoles.size());
    INFO("Errors: " << (result.has_value() ? result->errors.size() : result.error().size()));

    CHECK(result.has_value());
    CHECK(!result->header.title.empty());
    CHECK(result->dipoles.size() == 24);  // 26 lines - 2 non-dipole lines = 24 dipoles

    // Check first dipole
    if (!result->dipoles.empty()) {
        CHECK(result->dipoles[0].idip == 1);  // a dipole, ground state
        CHECK(result->dipoles[0].dipole == 3.6924);
        CHECK(result->dipoles[0].label == "a dipole moment gs");
    }
}

TEST_CASE("IntParser decodes header flags correctly", "[int_parser]") {
    // Test with example from docs
    int flags = 101;  // IRFLG=0, OUTFLG=1, STRFLG=0, EGYFLG=1
    int irflg, outflg, strflg, egyflg;

    IntParser::decodeFlags(flags, irflg, outflg, strflg, egyflg);

    CHECK(irflg == 0);
    CHECK(outflg == 1);
    CHECK(strflg == 0);
    CHECK(egyflg == 1);
}

TEST_CASE("IntParser decodes IDIP correctly", "[int_parser]") {
    // Test IDIP decoding with nvib_digits=2 (from par file: NVIB=18)
    // IDIP = 1011 from cyanomethcycloprop.int line 6
    // Decodes to: fc=0, typ=0, i1=0, v2=1, v1=1, sym=1
    // v1=1, v2=1 means transition within vibrational state v=1

    int idip = 1011;
    int nvib_digits = 2;  // NVIB=18 > 9, so 2 digits

    auto info = IntParser::decodeIdip(idip, nvib_digits);

    CHECK(info.fc == 0);
    CHECK(info.typ == 0);  // Basic dipole (not Herman-Wallis)
    CHECK(info.i1 == 0);
    CHECK(info.v2 == 1);
    CHECK(info.v1 == 1);   // Both v1 and v2 are 1 (same vibrational state)
    CHECK(info.sym == 1);  // a-type

    // Also test with IntDipole::getIdipInfo()
    IntDipole dipole;
    dipole.idip = idip;
    auto info2 = dipole.getIdipInfo(nvib_digits);

    CHECK(info2.fc == 0);
    CHECK(info2.typ == 0);
    CHECK(info2.sym == 1);
}

TEST_CASE("IntParser handles negative IDIP", "[int_parser]") {
    // Negative IDIP means grouped with previous dipole
    // Test decoding works correctly

    int idip = -1011;
    int nvib_digits = 2;

    auto info = IntParser::decodeIdip(idip, nvib_digits);

    // Values should be same as positive, just the sign indicates grouping
    CHECK(info.fc == 0);
    CHECK(info.typ == 0);
    CHECK(info.i1 == 0);
    CHECK(info.v2 == 1);
    CHECK(info.v1 == 1);  // Both v1 and v2 are 1
    CHECK(info.sym == 1);
}

TEST_CASE("IntParser handles file not found", "[int_parser]") {
    auto result = IntParser::parseFile("nonexistent_file.int");

    CHECK(!result.has_value());
    REQUIRE(!result.error().empty());
    CHECK(result.error()[0].first == 0);
}

TEST_CASE("IntParser extracts dipole labels", "[int_parser]") {
    auto result = IntParser::parseFile(std::string(TEST_DATA_DIR) + "/cyanomethcycloprop.int");

    CHECK(result.has_value());
    REQUIRE(result->dipoles.size() >= 6);

    // Check first 6 dipole labels from the file
    CHECK(result->dipoles[0].label == "a dipole moment gs");
    CHECK(result->dipoles[1].label == "b dipole moment gs");
    CHECK(result->dipoles[2].label == "c dipole moment gs");
    CHECK(result->dipoles[3].label == "a dipole moment 27");
    CHECK(result->dipoles[4].label == "b dipole moment 27");
    CHECK(result->dipoles[5].label == "c dipole moment 27");
}

TEST_CASE("IntParser integration with ParParser for nvib_digits", "[int_parser]") {
    // Load par file to get nvib context
    auto par_result = ParParser::parseFile(std::string(TEST_DATA_DIR) + "/cyanomethcycloprop.var");
    CHECK(par_result.has_value());
    REQUIRE(par_result.has_value());
    REQUIRE(!par_result->options.empty());

    int nvib = par_result->options[0].nvib.value_or(0);
    CHECK(nvib == 18);
    int nvib_digits = (nvib <= 9) ? 1 : (nvib <= 99) ? 2 : 3;
    CHECK(nvib_digits == 2);

    // Load int file
    auto int_result = IntParser::parseFile(std::string(TEST_DATA_DIR) + "/cyanomethcycloprop.int");
    CHECK(int_result.has_value());

    // Check some IDIPs
    if (int_result->dipoles.size() > 5) {
        // IDIP 1: ground state, a-type (IDIP=1)
        auto info0 = int_result->dipoles[0].getIdipInfo(nvib_digits);
        CHECK(info0.v1 == 0);
        CHECK(info0.v2 == 0);
        CHECK(info0.typ == 0);  // Basic dipole
        CHECK(info0.sym == 1);  // a-type

        // IDIP 1011: transition in v=1, a-type (decodes to v1=1, v2=1)
        auto info3 = int_result->dipoles[3].getIdipInfo(nvib_digits);
        CHECK(info3.v1 == 1);   // Both v1 and v2 are 1 (same vibrational state)
        CHECK(info3.v2 == 1);
        CHECK(info3.typ == 0);  // Basic dipole
        CHECK(info3.sym == 1);  // a-type
    }
}

TEST_CASE("IntParser parses dipole values", "[int_parser]") {
    auto result = IntParser::parseFile(std::string(TEST_DATA_DIR) + "/cyanomethcycloprop.int");

    CHECK(result.has_value());

    // Check that ground state dipoles are 0.0
    if (result->dipoles.size() >= 3) {
        CHECK(result->dipoles[0].dipole == 3.6924);  // gs a
        CHECK(result->dipoles[1].dipole == 1.4958);  // gs b
        CHECK(result->dipoles[2].dipole == 0.9398);  // gs c
    }

    // Check non-zero dipole for v=27
    if (result->dipoles.size() > 5) {
        CHECK(result->dipoles[3].dipole == 3.6924);  // 27 a
        CHECK(result->dipoles[4].dipole == 1.4958);  // 27 b
        CHECK(result->dipoles[5].dipole == 0.9398);  // 27 c
    }
}

TEST_CASE("IntParser extracts header fields", "[int_parser]") {
    auto result = IntParser::parseFile(std::string(TEST_DATA_DIR) + "/cyanomethcycloprop.int");

    CHECK(result.has_value());

    // Check header fields from line 2: 0 00005 267816. 0 120 -8. -8. 750.0 292.
    CHECK(result->header.flags == 0);
    CHECK(result->header.irflg == 0);
    CHECK(result->header.outflg == 0);
    CHECK(result->header.strflg == 0);
    CHECK(result->header.egyflg == 0);
    CHECK(result->header.tag == 00005);  // Species tag
    CHECK(result->header.qrot == 267816.0);  // Partition function
    CHECK(result->header.fbgn == 0);  // Beginning F
    CHECK(result->header.fend == 120);  // Ending F
    CHECK(std::fabs(result->header.str0 - (-8.0)) < 0.001);  // Log strength cutoff 0
    CHECK(std::fabs(result->header.str1 - (-8.0)) < 0.001);  // Log strength cutoff 1
    CHECK(result->header.fqlim == 750.0);  // Frequency limit (GHz)
    CHECK(result->header.temp == 292.0);  // Temperature (K)
    // maxv defaults to 999 if not in file
}

TEST_CASE("IntParser write roundtrip with SPCAT", "[int_parser]") {
    // Parse original INT file
    auto original = IntParser::parseFile(std::string(TEST_DATA_DIR) + "/cyanomethcycloprop.int");
    REQUIRE(original.has_value());
    REQUIRE(original->dipoles.size() > 0);
    
    // Write to _bak.int file
    std::string bak_file = std::string(TEST_DATA_DIR) + "/cyanomethcycloprop_bak.int";
    std::string error;
    bool write_ok = IntParser::writeFile(bak_file, original.value(), error);
    CHECK(write_ok);
    
    // Parse the written file and verify it matches
    auto roundtrip = IntParser::parseFile(bak_file);
    CHECK(roundtrip.has_value());
    REQUIRE(roundtrip.has_value());
    CHECK(roundtrip->dipoles.size() == original->dipoles.size());
    
    // Compare first few dipoles
    if (roundtrip->dipoles.size() >= 3) {
        CHECK(roundtrip->dipoles[0].idip == original->dipoles[0].idip);
        CHECK(roundtrip->dipoles[0].dipole == Catch::Approx(original->dipoles[0].dipole));
        CHECK(roundtrip->dipoles[1].idip == original->dipoles[1].idip);
        CHECK(roundtrip->dipoles[1].dipole == Catch::Approx(original->dipoles[1].dipole));
        CHECK(roundtrip->dipoles[2].idip == original->dipoles[2].idip);
        CHECK(roundtrip->dipoles[2].dipole == Catch::Approx(original->dipoles[2].dipole));
    }
}
