#ifndef LIN_PARSER_H
#define LIN_PARSER_H

#include <expected>
#include <string>
#include <utility>
#include <vector>

namespace pickett {

struct LinRecord {
  int qn[12];  // 12 quantum numbers (3 chars each, positions 1-36)
  double freq; // Frequency (MHz)
  double err;  // Error
  double wt;   // Weight

  LinRecord() : freq(0.0), err(0.0), wt(0.0) {
    for (int i = 0; i < 12; ++i)
      qn[i] = 0;
  }
};

struct LinParseResult {
  std::vector<LinRecord> records;
  std::vector<std::pair<int, std::string>> errors; // line_number, message
};

using LinParseErrors = std::vector<std::pair<int, std::string>>;
using LinParseExpected = std::expected<LinParseResult, LinParseErrors>;

class LinParser {
public:
  // Parse .lin file, returns result with records and any errors
  static LinParseExpected parseFile(const std::string &filepath);

  // Write .lin file from parsed data
  // Returns true on success, false on failure with error message
  static bool write(std::ostream &os, const LinParseResult &data,
                    std::string &error);
  static bool writeFile(const std::string &filepath,
                        const LinParseResult &data, std::string &error);

private:
  // Format quantum number in I3 format (3 chars, right-justified, space-padded)
  static std::string format_qn(int qn);
  // Format double for LIN file (FREQ/ERR/WT in freeform)
  static std::string format_double(double value, bool is_scientific);
};

} // namespace pickett

#endif // LIN_PARSER_H
