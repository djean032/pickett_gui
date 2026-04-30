#ifndef INT_PARSER_H
#define INT_PARSER_H

#include <expected>
#include <optional>
#include <string>
#include <utility>
#include <vector>

namespace pickett {

struct IntHeader {
  std::string title;
  int flags;                         // Raw FLAGS value
  int irflg, outflg, strflg, egyflg; // Decoded from FLAGS
  int tag;
  double qrot;
  int fbgn, fend;
  double str0, str1;
  double fqlim;
  double temp;
  int maxv;

  IntHeader()
      : flags(0), irflg(0), outflg(0), strflg(0), egyflg(0), tag(0), qrot(0.0),
        fbgn(0), fend(0), str0(0.0), str1(0.0), fqlim(0.0), temp(300.0),
        maxv(999) {}
};

struct IDIPInfo {
  int fc;  // 1 digit - Fourier/second digit for TYP=7,8
  int typ; // 1 digit - Dipole type
  int i1;  // 1 digit - Spin identifier (0 = N or null)
  int v2;  // 1-3 digits - Vibrational state 2
  int v1;  // 1-3 digits - Vibrational state 1
  int sym; // 1 digit - Symmetry (0=magnetic, 1=a, 2=b, 3=c)

  IDIPInfo() : fc(0), typ(0), i1(0), v2(0), v1(0), sym(0) {}
};

struct IntDipole {
  int idip; // Raw IDIP
  double dipole;
  std::string label;

  IntDipole() : idip(0), dipole(0.0) {}

  // Decode on demand with nvib context (1, 2, or 3 digits)
  IDIPInfo getIdipInfo(int nvibDigits) const;
};

struct IntParseResult {
  IntHeader header;
  std::vector<IntDipole> dipoles;
  std::vector<std::pair<int, std::string>> errors;
};

using IntParseErrors = std::vector<std::pair<int, std::string>>;
using IntParseExpected = std::expected<IntParseResult, IntParseErrors>;

class IntParser {
public:
  static IntParseExpected parseFile(const std::string &filepath);

  // Write .int file from parsed data
  static bool write(std::ostream &os, const IntParseResult &data,
                    std::string &error);
  static bool writeFile(const std::string &filepath,
                        const IntParseResult &data, std::string &error);

  // FLAGS = IRFLG*1000 + OUTFLG*100 + STRFLG*10 + EGYFLG
  static void decodeFlags(int flags, int &irflg, int &outflg, int &strflg,
                          int &egyflg);

  // Decode IDIP with nvib_digits (1, 2, or 3) from par file
  static IDIPInfo decodeIdip(int idip, int nvibDigits);

  // Encode IDIP from components
  static int encodeIdip(const IDIPInfo &info, int nvibDigits);

private:
  static bool parse_header_line(const std::string &line, IntHeader &header,
                                std::string &error);
  static bool parse_dipole_line(const std::string &line, IntDipole &dipole,
                                std::string &error);
};

} // namespace pickett

#endif // INT_PARSER_H
