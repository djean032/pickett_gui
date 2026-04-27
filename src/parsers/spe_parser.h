#ifndef SPE_PARSER_H
#define SPE_PARSER_H

#include <cstdint>
#include <string>
#include <utility>
#include <vector>

namespace pickett {

// Header structure for binary spectral files (170 bytes)
struct SpeHeader {
  char comment[73]; // 72 bytes + null terminator
  int16_t day;      // Day (1-31)
  int16_t month;    // Month (1-12)
  int16_t year;     // Year
  int16_t hour;     // Hour
  int16_t minute;   // Minute
  int16_t second;   // Second
  char lamp[7];     // 6 bytes + null terminator
  float vkmst;      // Starting wavenumber (4 bytes) - often unused
  float vkmend;     // Ending wavenumber (4 bytes) - often unused
  float grid;       // Grid spacing (4 bytes)
  char sample[21];  // 20 bytes + null terminator
  float sampre;     // Sample pressure (4 bytes)
  float gain;       // Gain setting (4 bytes)
  float timec;      // Time constant (4 bytes)
  float phase;      // Phase (4 bytes)
  char scansp[7];   // 6 bytes + null terminator
  float pps;        // Points per second (4 bytes)
  float frmod;      // Frequency modulation (4 bytes)
  float frampl;     // Frequency amplitude (4 bytes)

  SpeHeader();
};

// Footer structure (26 bytes)
struct SpeFooter {
  double fstart;  // Start frequency in MHz (8 bytes)
  double fend;    // End frequency in MHz (8 bytes)
  double fincr;   // Frequency increment in MHz (8 bytes)
  int16_t ncalpt; // Calibration points (2 bytes)

  SpeFooter() : fstart(0.0), fend(0.0), fincr(0.0), ncalpt(0) {}
};

// Parsed spectral data result
struct SpeParseResult {
  SpeHeader header;
  int32_t npts;                     // Number of data points
  std::vector<int32_t> intensities; // 4-byte signed integer intensities
  SpeFooter footer;
  std::vector<std::pair<int, std::string>> errors;
  bool success;

  // Computed properties (all frequencies in MHz)
  double get_fstart_mhz() const { return footer.fstart; }
  double get_fend_mhz() const { return footer.fend; }
  double get_fincr_mhz() const { return footer.fincr; }
  double get_span_mhz() const { return footer.fend - footer.fstart; }

  SpeParseResult() : npts(0), success(true) {}
};

class SpeParser {
public:
  // Parse a binary spectral file
  static SpeParseResult parse_file(const std::string &filepath);

  // Parse from memory buffer (for testing or embedded data)
  static SpeParseResult parse_buffer(const std::vector<uint8_t> &buffer);

private:
  static bool parse_header(const std::vector<uint8_t> &data, SpeHeader &header,
                           std::vector<std::pair<int, std::string>> &errors);
  static bool parse_data(const std::vector<uint8_t> &data, int32_t &npts,
                         std::vector<int32_t> &intensities,
                         std::vector<std::pair<int, std::string>> &errors);
  static bool parse_footer(const std::vector<uint8_t> &data, SpeFooter &footer,
                           std::vector<std::pair<int, std::string>> &errors);
  static bool validate_header(const SpeHeader &header,
                              std::vector<std::pair<int, std::string>> &errors);
};

} // namespace pickett

#endif // SPE_PARSER_H
