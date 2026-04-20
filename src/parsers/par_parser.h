#ifndef PAR_PARSER_H
#define PAR_PARSER_H

#include <optional>
#include <string>
#include <utility>
#include <vector>

namespace pickett {

struct ParHeader {
  std::string title; // Line 1 - freeform
  int npar;          // Max parameters
  int nline;         // Max lines
  int nitr;          // Max iterations
  int nxpar;         // Exclude params
  double thresh;     // Marquardt parameter
  double errtst;     // Max [(obs-calc)/error]
  double frac;       // Variance importance
  double cal;        // IR scaling

  ParHeader()
      : npar(0), nline(0), nitr(0), nxpar(0), thresh(0.0), errtst(0.0),
        frac(0.0), cal(0.0) {}
};

struct ParOptionLine {
  char chr;                        // Always set on first line
  std::optional<int> spino;        // spin degeneracy + rotor type
  std::optional<int> nvib;         // vibronic states
  std::optional<int> knmin, knmax; // K limits
  std::optional<int> ixx;          // Interaction flags
  std::optional<int> iax;          // Statistical weight axis
  std::optional<int> wtpl, wtmn;   // Statistical weights
  std::optional<int> vsym;         // Vibrational symmetry
  std::optional<int> ewt;          // E-symmetry weights
  std::optional<int> diag;         // Diagonalization mode
  std::optional<int> xopt;         // Phase/ordering options

  ParOptionLine() : chr('\0') {}
};

struct ParParameter {
  int idpar;         // Raw IDPAR as-is
  double par;        // Parameter value
  double erpar;      // Uncertainty
  std::string label; // After / (may be empty)

  ParParameter() : idpar(0), par(0.0), erpar(0.0) {}
};

struct ParParseResult {
  ParHeader header;
  std::vector<ParOptionLine> options;
  std::vector<ParParameter> parameters;
  std::vector<std::string> comments; // Lines starting with ! (preserved as-is)
  std::vector<std::pair<int, std::string>> errors; // line_number, message
  bool success;

  ParParseResult() : success(true) {}
};

class ParParser {
public:
  static ParParseResult parse_file(const std::string &filepath);

  // Write .par file from parsed data
  static bool write(std::ostream &os, const ParParseResult &data,
                    std::string &error);
  static bool write_file(const std::string &filepath,
                         const ParParseResult &data, std::string &error);

  // Validate CHR field
  static bool is_valid_chr(char c);

  // Encode CHR field ('a', 'g', or 's')
  static char encode_chr(const std::vector<ParOptionLine> &options);

private:
  static bool parse_header_line(const std::string &line, ParHeader &header,
                                std::string &error);
  static bool parse_option_line(const std::string &line, ParOptionLine &opt,
                                bool is_first_line, std::string &error);
  static bool parse_parameter_line(const std::string &line, ParParameter &param,
                                   std::string &error);
};

} // namespace pickett

#endif // PAR_PARSER_H
