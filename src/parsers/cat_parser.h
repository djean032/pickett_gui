#ifndef CAT_PARSER_H
#define CAT_PARSER_H

#include <string>
#include <utility>
#include <vector>

namespace pickett {

struct CatRecord {
  double freq;  // Frequency in MHz (F13.4)
  double err;   // Estimated error (F8.4)
  double lgint; // Log10 integrated intensity (F8.4)
  double elo;   // Lower state energy (F10.4)
  int dr;       // Degeneracy (I2)
  int gup;      // Upper state degeneracy (I3)
  int tag;      // Species tag (I7)
  int qnfmt;    // Quantum number format (I4)
  int qn[12];   // 12 decoded quantum numbers

  CatRecord()
      : freq(0.0), err(0.0), lgint(0.0), elo(0.0), dr(0), gup(0), tag(0),
        qnfmt(0) {
    for (int i = 0; i < 12; ++i)
      qn[i] = 0;
  }
};

struct CatParseResult {
  std::vector<CatRecord> records;
  std::vector<std::pair<int, std::string>> errors; // line_number, message
  bool success; // false if critical error (file not found, all bad QFMT)

  CatParseResult() : success(true) {}
};

struct QNFormat {
  int q;   // Base format code (QNFMT / 100)
  int h;   // Half-integer flags ((QNFMT / 10) % 10)
  int nqn; // Number of quanta per state (QNFMT % 10)
};

class CatParser {
public:
  // Parse .cat file, returns result with records and any errors
  static CatParseResult parse_file(const std::string &filepath);

  // Decode QNFMT into components
  static QNFormat decode_qnfmt(int qnfmt);

  // Get text labels for quantum numbers based on QFMT code
  // Returns fixed set regardless of actual values (zeros will be apparent)
  static std::vector<std::string> get_qn_labels(int qnfmt);

private:
  // Decode 2-char quantum number string to integer
  // Returns error message if malformed, empty string on success
  static std::pair<int, std::string> decode_qn(const std::string &s);
};

} // namespace pickett

#endif // CAT_PARSER_H
