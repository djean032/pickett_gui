#include "cat_parser.h"
#include <cctype>
#include <fstream>
#include <limits>

namespace pickett {

// All known QFMT codes and their labels (from spinv.txt documentation)
static const std::vector<std::string> QFMT_LABELS_0; // Atom - empty
static const std::vector<std::string> QFMT_LABELS_1 = {
    "N", "v"}; // Linear S-state (2)
static const std::vector<std::string> QFMT_LABELS_2 = {
    "N", "K"}; // Linear other / Symmetric top (2)
static const std::vector<std::string> QFMT_LABELS_3 = {
    "N", "Ka", "Kc"}; // Asymmetric top (3)
static const std::vector<std::string> QFMT_LABELS_4 = {
    "N", "Ka", "Kc", "v"}; // Asymmetric top (4)
static const std::vector<std::string> QFMT_LABELS_11 = {
    "N", "v", "J", "F1", "F"}; // Linear with spins (5)
static const std::vector<std::string> QFMT_LABELS_12 = {
    "N", "v", "J", "F1", "F2", "F"}; // Linear more spins (6)
static const std::vector<std::string> QFMT_LABELS_13 = {
    "N", "K", "v", "J", "F1", "F"}; // Symmetric top with spins (6)
static const std::vector<std::string> QFMT_LABELS_14 = {
    "N", "Ka", "Kc", "v", "J", "F"}; // Asymmetric top with spins (6)
// Additional codes from documentation can be added here

std::vector<std::string> CatParser::get_qn_labels(int qnfmt) {
  int q = qnfmt / 100;
  switch (q) {
  case 0:
    return QFMT_LABELS_0;
  case 1:
    return QFMT_LABELS_1;
  case 2:
    return QFMT_LABELS_2;
  case 3:
    return QFMT_LABELS_3;
  case 4:
    return QFMT_LABELS_4;
  case 11:
    return QFMT_LABELS_11;
  case 12:
    return QFMT_LABELS_12;
  case 13:
    return QFMT_LABELS_13;
  case 14:
    return QFMT_LABELS_14;
  default:
    return {}; // Unknown - caller should check for empty
  }
}

QNFormat CatParser::decode_qnfmt(int qnfmt) {
  return {
      qnfmt / 100,       // Q: base format code
      (qnfmt / 10) % 10, // H: half-integer flags
      qnfmt % 10         // NQN: number of quanta per state
  };
}

std::pair<int, std::string> CatParser::parse_int_safe(const std::string &s) {
  if (s.empty()) {
    return {0, "Empty string"};
  }

  // Check for valid characters (digits, optional leading space, optional
  // leading -)
  size_t start = 0;
  bool negative = false;

  // Skip leading spaces
  while (start < s.size() && std::isspace(s[start])) {
    start++;
  }

  if (start >= s.size()) {
    return {0, "Only whitespace"};
  }

  // Check for negative sign
  if (s[start] == '-') {
    negative = true;
    start++;
  }

  // Parse digits
  long long result = 0;
  bool has_digits = false;

  for (size_t i = start; i < s.size(); ++i) {
    if (std::isdigit(s[i])) {
      result = result * 10 + (s[i] - '0');
      has_digits = true;
    } else if (std::isspace(s[i])) {
      // Allow trailing spaces
      continue;
    } else {
      return {0, "Invalid character: " + std::string(1, s[i])};
    }
  }

  if (!has_digits) {
    return {0, "No digits found"};
  }

  if (negative) {
    result = -result;
  }

  // Check for overflow
  if (result < std::numeric_limits<int>::min() ||
      result > std::numeric_limits<int>::max()) {
    return {0, "Integer overflow"};
  }

  return {static_cast<int>(result), ""};
}

std::pair<double, std::string>
CatParser::parse_double_safe(const std::string &s) {
  if (s.empty()) {
    return {0.0, "Empty string"};
  }

  // Manual check for valid characters before calling stod
  bool has_digit = false;
  bool has_dot = false;
  bool has_exp = false;
  bool has_sign = false;
  bool in_leading_ws = true;

  for (size_t i = 0; i < s.size(); ++i) {
    char c = s[i];
    if (std::isdigit(c)) {
      has_digit = true;
      in_leading_ws = false;
    } else if (c == '.' && !has_dot && !has_exp) {
      // Dot allowed before exponent, regardless of whether we've seen sign or
      // digits
      has_dot = true;
      in_leading_ws = false;
    } else if ((c == 'e' || c == 'E') && !has_exp && has_digit) {
      has_exp = true;
      in_leading_ws = false; // After e/E, we're in the exponent
      // Check for sign after e/E
      if (i + 1 < s.size() && (s[i + 1] == '+' || s[i + 1] == '-')) {
        i++;
      }
    } else if (c == '+' || c == '-') {
      // Allow at start (including after leading whitespace) or after e/E
      if (in_leading_ws) {
        // Sign after leading whitespace - this is OK
        has_sign = true;
        in_leading_ws = false;
      } else if (has_exp && i > 0 && (s[i - 1] == 'e' || s[i - 1] == 'E')) {
        // Sign in exponent - already handled above
        in_leading_ws = false;
      } else if (!has_digit && !has_sign) {
        // Sign at start of number (after any leading whitespace)
        has_sign = true;
      } else {
        return {0.0, "Invalid sign position"};
      }
    } else if (std::isspace(c)) {
      if (in_leading_ws) {
        // Still in leading whitespace - OK
      } else if (has_digit) {
        // Trailing whitespace after digits - check rest is just spaces
        for (size_t j = i + 1; j < s.size(); ++j) {
          if (!std::isspace(s[j])) {
            return {0.0, "Invalid character: space in middle"};
          }
        }
        break;
      } else {
        // Whitespace between sign and digits - not valid
        return {0.0, "Invalid character: space between sign and number"};
      }
    } else {
      return {0.0, "Invalid character: " + std::string(1, c)};
    }
  }

  if (!has_digit) {
    return {0.0, "No digits found"};
  }

  try {
    size_t pos;
    double result = std::stod(s, &pos);
    return {result, ""};
  } catch (...) {
    return {0.0, "Double conversion failed"};
  }
}

std::pair<int, std::string> CatParser::decode_qn(const std::string &s) {
  if (s.size() != 2) {
    return {0, "QN field must be exactly 2 characters"};
  }

  // Check for overflow marker
  if (s == "**") {
    return {std::numeric_limits<int>::max(), ""};
  }

  // Check for blank
  if (s == "  " || s == "  ") {
    return {0, ""};
  }

  char c = s[0];
  char d = s[1];

  auto is_digit = [](char ch) { return ch >= '0' && ch <= '9'; };

  // Negative: a-i (lowercase) for -10 to -99
  if (c >= 'a' && c <= 'i') {
    if (!is_digit(d)) {
      return {0, "Malformed QN: digit expected after lowercase letter '" +
                     std::string(1, c) + "', got '" + std::string(1, d) + "'"};
    }
    int ntens = c - 'a' + 1; // a=1, b=2, ..., i=9
    int digit = d - '0';
    return {-(digit + 10 * ntens), ""};
  }

  // Positive: A-N (uppercase) for 100-240
  if (c >= 'A' && c <= 'N') {
    if (!is_digit(d)) {
      return {0, "Malformed QN: digit expected after uppercase letter '" +
                     std::string(1, c) + "', got '" + std::string(1, d) + "'"};
    }
    int ntens = c - 'A' + 1; // A=1, B=2, ..., N=14
    int digit = d - '0';
    return {digit + (9 + ntens) * 10, ""};
  }

  // Regular number: use safe int parsing
  // stoi handles leading spaces correctly (e.g., " 4" → 4)
  auto result = parse_int_safe(s);
  return result;
}

CatParseResult CatParser::parse_file(const std::string &filepath) {
  CatParseResult result;
  std::ifstream file(filepath);

  if (!file.is_open()) {
    result.success = false;
    result.errors.push_back({0, "Failed to open file: " + filepath});
    return result;
  }

  std::string line;
  int line_num = 0;
  bool has_valid_qnfmt = false;
  int detected_qnfmt = -1;
  int qnfmt_error_count = 0;

  while (std::getline(file, line)) {
    line_num++;

    // Remove carriage return for Windows line endings
    if (!line.empty() && line.back() == '\r') {
      line.pop_back();
    }

    // Skip empty lines
    if (line.empty()) {
      continue;
    }

    // Skip lines that are too short (need at least 55 chars for QNFMT and QN
    // fields)
    if (line.length() < 55) {
      result.errors.push_back({line_num, "Line too short (< 55 chars)"});
      continue;
    }

    CatRecord record;
    std::vector<std::string> line_errors;

    // Parse fixed-width fields
    // FREQ: positions 0-12 (13 chars)
    auto freq_result = parse_double_safe(line.substr(0, 13));
    if (!freq_result.second.empty()) {
      line_errors.push_back("FREQ: " + freq_result.second);
    } else {
      record.freq = freq_result.first;
    }

    // ERR: positions 13-20 (8 chars)
    auto err_result = parse_double_safe(line.substr(13, 8));
    if (!err_result.second.empty()) {
      line_errors.push_back("ERR: " + err_result.second);
    } else {
      record.err = err_result.first;
    }

    // LGINT: positions 21-28 (8 chars)
    auto lgint_result = parse_double_safe(line.substr(21, 8));
    if (!lgint_result.second.empty()) {
      line_errors.push_back("LGINT: " + lgint_result.second);
    } else {
      record.lgint = lgint_result.first;
    }

    // DR: positions 29-30 (2 chars)
    auto dr_result = parse_int_safe(line.substr(29, 2));
    if (!dr_result.second.empty()) {
      line_errors.push_back("DR: " + dr_result.second);
    } else {
      record.dr = dr_result.first;
    }

    // ELO: positions 31-40 (10 chars)
    auto elo_result = parse_double_safe(line.substr(31, 10));
    if (!elo_result.second.empty()) {
      line_errors.push_back("ELO: " + elo_result.second);
    } else {
      record.elo = elo_result.first;
    }

    // GUP: positions 41-43 (3 chars)
    auto gup_result = parse_int_safe(line.substr(41, 3));
    if (!gup_result.second.empty()) {
      line_errors.push_back("GUP: " + gup_result.second);
    } else {
      record.gup = gup_result.first;
    }

    // TAG: positions 44-50 (7 chars)
    auto tag_result = parse_int_safe(line.substr(44, 7));
    if (!tag_result.second.empty()) {
      line_errors.push_back("TAG: " + tag_result.second);
    } else {
      record.tag = tag_result.first;
    }

    // QNFMT: positions 51-54 (4 chars)
    auto qnfmt_result = parse_int_safe(line.substr(51, 4));
    if (!qnfmt_result.second.empty()) {
      line_errors.push_back("QNFMT: " + qnfmt_result.second);
    } else {
      record.qnfmt = qnfmt_result.first;

      // Check QFMT validity on first line
      if (detected_qnfmt == -1) {
        detected_qnfmt = record.qnfmt;
        auto labels = get_qn_labels(record.qnfmt);
        if (labels.empty()) {
          // Unknown QFMT - this is an error on first line
          result.success = false;
          result.errors.push_back(
              {line_num, "Unknown QFMT code: " + std::to_string(record.qnfmt)});
          return result;
        }
        has_valid_qnfmt = true;
      } else if (record.qnfmt != detected_qnfmt) {
        // Inconsistent QFMT - error
        line_errors.push_back("Inconsistent QFMT: expected " +
                              std::to_string(detected_qnfmt) + ", got " +
                              std::to_string(record.qnfmt));
      }
    }

    // QN: positions 55-78 (24 chars = 12×2)
    std::string qn_field = line.substr(55, 24);
    for (int i = 0; i < 12; ++i) {
      std::string qn_str = qn_field.substr(i * 2, 2);
      auto qn_result = decode_qn(qn_str);
      if (!qn_result.second.empty()) {
        line_errors.push_back("QN[" + std::to_string(i) +
                              "]: " + qn_result.second);
      }
      record.qn[i] = qn_result.first;
    }

    // If there were any errors on this line, log them and skip the line
    if (!line_errors.empty()) {
      for (const auto &err : line_errors) {
        result.errors.push_back({line_num, err});
      }
      continue;
    }

    // Line parsed successfully
    result.records.push_back(record);
  }

  // Check if we have any valid QFMT
  if (!has_valid_qnfmt && result.records.empty()) {
    result.success = false;
    result.errors.push_back(
        {0, "No valid records found (all lines had errors or unknown QFMT)"});
  }

  return result;
}

} // namespace pickett
