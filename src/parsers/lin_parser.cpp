#include "lin_parser.h"
#include "utils.h"
#include <cctype>
#include <cstdio>
#include <fstream>
#include <iomanip>
#include <sstream>

namespace pickett {

// parse_int_safe and parse_double_safe now come from utils.h

namespace {
constexpr size_t LIN_QN_COUNT = 12;
constexpr size_t LIN_QN_WIDTH = 3;
constexpr size_t LIN_QN_BLOCK_WIDTH = LIN_QN_COUNT * LIN_QN_WIDTH;
constexpr int LIN_QN_MIN = -99;
constexpr int LIN_QN_MAX = 999;
constexpr size_t LIN_QN_BUFFER_SIZE = 4;
constexpr int LIN_SCIENTIFIC_SIG_FIGS = 2;
constexpr int LIN_FIXED_PRECISION = 6;
} // namespace

LinParseExpected LinParser::parse_file(const std::string &filepath) {
  LinParseResult result;
  std::ifstream file(filepath);

  if (!file.is_open()) {
    return std::unexpected(LinParseErrors{{0, "Failed to open file: " + filepath}});
  }

  std::string line;
  int line_num = 0;

  while (std::getline(file, line)) {
    line_num++;

    // Skip empty lines
    if (line.empty())
      continue;

    // Skip comment lines (starting with !)
    if (line[0] == '!')
      continue;

    // Skip lines that are too short for QN fields
    if (line.length() < LIN_QN_BLOCK_WIDTH) {
      result.errors.push_back({line_num, "Line too short (< 36 chars)"});
      continue;
    }

    LinRecord record;
    std::vector<std::string> line_errors;

    // Parse 12 quantum numbers (3 characters each, positions 0-35)
    for (size_t i = 0; i < LIN_QN_COUNT; ++i) {
      size_t start_pos = i * LIN_QN_WIDTH;
      std::string qn_str = line.substr(start_pos, LIN_QN_WIDTH);

      // Trim whitespace
      size_t first = qn_str.find_first_not_of(" \t");
      size_t last = qn_str.find_last_not_of(" \t");
      if (first != std::string::npos && last != std::string::npos) {
        qn_str = qn_str.substr(first, last - first + 1);
      } else {
        qn_str = "";
      }

      if (!qn_str.empty()) {
        auto qn_result = parse_int_safe(qn_str);
        if (!qn_result.second.empty()) {
          line_errors.push_back("QN[" + std::to_string(i) +
                                "]: " + qn_result.second);
        } else {
          record.qn[i] = qn_result.first;
        }
      } else {
        record.qn[i] = 0;
      }
    }

    // Parse FREQ, ERR, WT from column 36 onwards (freeform)
    std::string remainder = line.substr(LIN_QN_BLOCK_WIDTH);

    // Parse FREQ
    size_t pos = 0;
    while (pos < remainder.size() && std::isspace(remainder[pos]))
      pos++;
    size_t end = pos;
    while (end < remainder.size() && !std::isspace(remainder[end]))
      end++;

    if (pos >= remainder.size()) {
      line_errors.push_back("FREQ: No value found");
    } else {
      std::string freq_str = remainder.substr(pos, end - pos);
      auto freq_result = parse_double_safe(freq_str);
      if (!freq_result.second.empty()) {
        line_errors.push_back("FREQ: " + freq_result.second);
      } else {
        record.freq = freq_result.first;
      }
      pos = end;
    }

    // Parse ERR
    while (pos < remainder.size() && std::isspace(remainder[pos]))
      pos++;
    end = pos;
    while (end < remainder.size() && !std::isspace(remainder[end]))
      end++;

    if (pos < remainder.size()) {
      std::string err_str = remainder.substr(pos, end - pos);
      auto err_result = parse_double_safe(err_str);
      if (!err_result.second.empty()) {
        line_errors.push_back("ERR: " + err_result.second);
      } else {
        record.err = err_result.first;
      }
      pos = end;
    } else {
      record.err = 0.0;
    }

    // Parse WT
    while (pos < remainder.size() && std::isspace(remainder[pos]))
      pos++;
    end = pos;
    while (end < remainder.size() && !std::isspace(remainder[end]))
      end++;

    if (pos < remainder.size()) {
      std::string wt_str = remainder.substr(pos, end - pos);
      auto wt_result = parse_double_safe(wt_str);
      if (!wt_result.second.empty()) {
        line_errors.push_back("WT: " + wt_result.second);
      } else {
        record.wt = wt_result.first;
      }
    } else {
      record.wt = 0.0;
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

  return result;
}

// Format quantum number in I3 format (3 chars, right-justified, space-padded)
std::string LinParser::format_qn(int qn) {
  // I3 format: 3 characters, right-justified, space-padded
  // For values -99 to 999
  char buf[LIN_QN_BUFFER_SIZE];
  if (qn >= LIN_QN_MIN && qn <= LIN_QN_MAX) {
    snprintf(buf, sizeof(buf), "%3d", qn);
  } else {
    // Out of range - use ** or similar (as per spinv.txt)
    snprintf(buf, sizeof(buf), " **");
  }
  return std::string(buf, LIN_QN_WIDTH);
}

// Format double for LIN file (FREQ/ERR/WT in freeform)
// Format value for LIN files with SPFIT-compatible format
// Frequency: fixed notation with 6 decimal places
// Error/Weight: scientific notation with uppercase E, 2 sig figs, 2-digit
// exponent
std::string LinParser::format_double(double value, bool is_scientific) {
  if (is_scientific) {
    // Use common utility for scientific notation with 2 sig figs, 2-digit
    // exponent
    return format_scientific_lin(value, LIN_SCIENTIFIC_SIG_FIGS);
  } else {
    // Fixed notation for frequency/error - 6 decimal places
    std::ostringstream oss;
    oss << std::fixed << std::setprecision(LIN_FIXED_PRECISION) << value;
    return oss.str();
  }
}

bool LinParser::write(std::ostream &os, const LinParseResult &data,
                      std::string &error) {
  // Check if data is valid
  if (data.records.empty()) {
    error = "No valid records to write";
    return false;
  }

  try {
    for (const auto &record : data.records) {
      // Write 12 quantum numbers in I3 format (positions 1-36)
      for (size_t i = 0; i < LIN_QN_COUNT; ++i) {
        os << format_qn(record.qn[i]);
      }

      // Write space + FREQ, ERR, WT (freeform, space-separated)
      // FREQ: fixed with 6 decimal places
      // ERR: fixed with 6 decimal places (like original format)
      // WT: scientific with 2 sig figs, uppercase E, 3-digit exponent
      os << "   "
         << format_double(record.freq, false); // false = fixed notation
      os << "     "
         << format_double(record.err, false);       // false = fixed notation
      os << "  " << format_double(record.wt, true); // true = scientific
      os << "\n";

      if (!os.good()) {
        error = "Failed to write record to stream";
        return false;
      }
    }

    return true;
  } catch (const std::exception &e) {
    error = std::string("Exception during write: ") + e.what();
    return false;
  }
}

bool LinParser::write_file(const std::string &filepath,
                           const LinParseResult &data, std::string &error) {
  std::ofstream file(filepath);
  if (!file.is_open()) {
    error = "Failed to open file for writing: " + filepath;
    return false;
  }

  bool result = write(file, data, error);
  file.close();
  return result;
}

} // namespace pickett
