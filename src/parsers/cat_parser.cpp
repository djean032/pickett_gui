#include "cat_parser.h"
#include "utils.h"
#include <fstream>
#include <limits>

namespace pickett {

// parse_int_safe and parse_double_safe now come from utils.h

namespace {
constexpr int QNFMT_Q_DIVISOR = 100;
constexpr int QNFMT_H_DIVISOR = 10;
constexpr int QNFMT_H_MOD = 10;

constexpr size_t CAT_MIN_LINE_LEN = 55;
constexpr size_t FREQ_START = 0;
constexpr size_t FREQ_WIDTH = 13;
constexpr size_t ERR_START = 13;
constexpr size_t ERR_WIDTH = 8;
constexpr size_t LGINT_START = 21;
constexpr size_t LGINT_WIDTH = 8;
constexpr size_t DR_START = 29;
constexpr size_t DR_WIDTH = 2;
constexpr size_t ELO_START = 31;
constexpr size_t ELO_WIDTH = 10;
constexpr size_t GUP_START = 41;
constexpr size_t GUP_WIDTH = 3;
constexpr size_t TAG_START = 44;
constexpr size_t TAG_WIDTH = 7;
constexpr size_t QNFMT_START = 51;
constexpr size_t QNFMT_WIDTH = 4;
constexpr size_t QN_FIELD_START = 55;
constexpr size_t QN_FIELD_WIDTH = 24;
constexpr size_t QN_COUNT = 12;
constexpr size_t QN_TOKEN_WIDTH = 2;

constexpr size_t QN_STR_SIZE = 2;
constexpr char QN_OVERFLOW_MARKER[] = "**";
constexpr char QN_BLANK[] = "  ";
constexpr char QN_NEG_PREFIX_MIN = 'a';
constexpr char QN_NEG_PREFIX_MAX = 'z';
constexpr char QN_POS_PREFIX_MIN = 'A';
constexpr char QN_POS_PREFIX_MAX = 'Z';
constexpr int QN_ALPHA_OFFSET = 1;
constexpr int QN_TENS_MULTIPLIER = 10;
constexpr int QN_POS_BASE_TENS_OFFSET = 9;
} // namespace

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
  int q = qnfmt / QNFMT_Q_DIVISOR;
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
      qnfmt / QNFMT_Q_DIVISOR,                  // Q: base format code
      (qnfmt / QNFMT_H_DIVISOR) % QNFMT_H_MOD, // H: half-integer flags
      qnfmt % QNFMT_H_MOD                      // NQN: number of quanta per
                                               // state
  };
}

std::pair<int, std::string> CatParser::decode_qn(const std::string &s) {
  if (s.size() != QN_STR_SIZE) {
    return {0, "QN field must be exactly 2 characters"};
  }

  // Check for overflow marker
  if (s == QN_OVERFLOW_MARKER) {
    return {std::numeric_limits<int>::max(), ""};
  }

  // Check for blank
  if (s == QN_BLANK) {
    return {0, ""};
  }

  char c = s[0];
  char d = s[1];

  auto is_digit = [](char ch) { return ch >= '0' && ch <= '9'; };

  // Negative: a-z (lowercase)
  if (c >= QN_NEG_PREFIX_MIN && c <= QN_NEG_PREFIX_MAX) {
    if (!is_digit(d)) {
      return {0, "Malformed QN: digit expected after lowercase letter '" +
                     std::string(1, c) + "', got '" + std::string(1, d) + "'"};
    }
    int ntens = c - QN_NEG_PREFIX_MIN + QN_ALPHA_OFFSET; // a=1,...,z=26
    int digit = d - '0';
    return {-(digit + QN_TENS_MULTIPLIER * ntens), ""};
  }

  // Positive: A-Z (uppercase)
  if (c >= QN_POS_PREFIX_MIN && c <= QN_POS_PREFIX_MAX) {
    if (!is_digit(d)) {
      return {0, "Malformed QN: digit expected after uppercase letter '" +
                     std::string(1, c) + "', got '" + std::string(1, d) + "'"};
    }
    int ntens = c - QN_POS_PREFIX_MIN + QN_ALPHA_OFFSET; // A=1,...,Z=26
    int digit = d - '0';
    return {digit + (QN_POS_BASE_TENS_OFFSET + ntens) * QN_TENS_MULTIPLIER,
            ""};
  }

  // Regular number: use safe int parsing
  // stoi handles leading spaces correctly (e.g., " 4" → 4)
  auto result = parse_int_safe(s);
  return result;
}

CatParseExpected CatParser::parse_file(const std::string &filepath) {
  CatParseResult result;
  std::ifstream file(filepath);

  if (!file.is_open()) {
    return std::unexpected(CatParseErrors{{0, "Failed to open file: " + filepath}});
  }

  std::string line;
  int line_num = 0;
  bool has_valid_qnfmt = false;
  int detected_qnfmt = -1;

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
    if (line.length() < CAT_MIN_LINE_LEN) {
      result.errors.push_back({line_num, "Line too short (< 55 chars)"});
      continue;
    }

    CatRecord record;
    std::vector<std::string> line_errors;

    // Parse fixed-width fields
    // FREQ: positions 0-12 (13 chars)
    auto freq_result = parse_double_safe(line.substr(FREQ_START, FREQ_WIDTH));
    if (!freq_result.second.empty()) {
      line_errors.push_back("FREQ: " + freq_result.second);
    } else {
      record.freq = freq_result.first;
    }

    // ERR: positions 13-20 (8 chars)
    auto err_result = parse_double_safe(line.substr(ERR_START, ERR_WIDTH));
    if (!err_result.second.empty()) {
      line_errors.push_back("ERR: " + err_result.second);
    } else {
      record.err = err_result.first;
    }

    // LGINT: positions 21-28 (8 chars)
    auto lgint_result = parse_double_safe(line.substr(LGINT_START, LGINT_WIDTH));
    if (!lgint_result.second.empty()) {
      line_errors.push_back("LGINT: " + lgint_result.second);
    } else {
      record.lgint = lgint_result.first;
    }

    // DR: positions 29-30 (2 chars)
    auto dr_result = parse_int_safe(line.substr(DR_START, DR_WIDTH));
    if (!dr_result.second.empty()) {
      line_errors.push_back("DR: " + dr_result.second);
    } else {
      record.dr = dr_result.first;
    }

    // ELO: positions 31-40 (10 chars)
    auto elo_result = parse_double_safe(line.substr(ELO_START, ELO_WIDTH));
    if (!elo_result.second.empty()) {
      line_errors.push_back("ELO: " + elo_result.second);
    } else {
      record.elo = elo_result.first;
    }

    // GUP: positions 41-43 (3 chars)
    auto gup_result = parse_int_safe(line.substr(GUP_START, GUP_WIDTH));
    if (!gup_result.second.empty()) {
      line_errors.push_back("GUP: " + gup_result.second);
    } else {
      record.gup = gup_result.first;
    }

    // TAG: positions 44-50 (7 chars)
    auto tag_result = parse_int_safe(line.substr(TAG_START, TAG_WIDTH));
    if (!tag_result.second.empty()) {
      line_errors.push_back("TAG: " + tag_result.second);
    } else {
      record.tag = tag_result.first;
    }

    // QNFMT: positions 51-54 (4 chars)
    auto qnfmt_result = parse_int_safe(line.substr(QNFMT_START, QNFMT_WIDTH));
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
          return std::unexpected(CatParseErrors{
              {line_num, "Unknown QFMT code: " + std::to_string(record.qnfmt)}});
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
    std::string qn_field = line.substr(QN_FIELD_START, QN_FIELD_WIDTH);
    for (size_t i = 0; i < QN_COUNT; ++i) {
      std::string qn_str = qn_field.substr(i * QN_TOKEN_WIDTH, QN_TOKEN_WIDTH);
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
    return std::unexpected(CatParseErrors{
        {0, "No valid records found (all lines had errors or unknown QFMT)"}});
  }

  return result;
}

} // namespace pickett
