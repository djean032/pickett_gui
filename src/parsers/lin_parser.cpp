#include "lin_parser.h"
#include <cctype>
#include <cstdio>
#include <fstream>
#include <iomanip>
#include <limits>
#include <sstream>

namespace pickett {

std::pair<int, std::string> LinParser::parse_int_safe(const std::string &s) {
  if (s.empty()) {
    return {0, "Empty string"};
  }

  // Check for valid characters (digits, optional leading space, optional leading -)
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

std::pair<double, std::string> LinParser::parse_double_safe(const std::string &s) {
  if (s.empty()) {
    return {0.0, "Empty string"};
  }

  // Manual check for valid characters before calling stod
  bool has_digit = false;
  bool has_dot = false;
  bool has_exp = false;

  for (size_t i = 0; i < s.size(); ++i) {
    char c = s[i];
    if (std::isdigit(c)) {
      has_digit = true;
    } else if (c == '.' && !has_dot && !has_exp) {
      has_dot = true;
    } else if ((c == 'e' || c == 'E') && !has_exp && has_digit) {
      has_exp = true;
      // Check for sign after e/E
      if (i + 1 < s.size() && (s[i + 1] == '+' || s[i + 1] == '-')) {
        i++;
      }
    } else if (c == '+' || c == '-') {
      // Allow at start or after e/E
      if (i != 0 && !(has_exp && (s[i - 1] == 'e' || s[i - 1] == 'E'))) {
        return {0.0, "Invalid sign position"};
      }
    } else if (std::isspace(c)) {
      // Allow leading/trailing spaces
      if (has_digit && i < s.size() - 1) {
        // Space in middle after digits - check if rest is just spaces
        for (size_t j = i + 1; j < s.size(); ++j) {
          if (!std::isspace(s[j])) {
            return {0.0, "Invalid character: space in middle"};
          }
        }
        break;
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

LinParseResult LinParser::parse_file(const std::string &filepath) {
  LinParseResult result;
  std::ifstream file(filepath);

  if (!file.is_open()) {
    result.success = false;
    result.errors.push_back({0, "Failed to open file: " + filepath});
    return result;
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
    if (line.length() < 36) {
      result.errors.push_back({line_num, "Line too short (< 36 chars)"});
      continue;
    }

    LinRecord record;
    std::vector<std::string> line_errors;

    // Parse 12 quantum numbers (3 characters each, positions 0-35)
    for (int i = 0; i < 12; ++i) {
      size_t start_pos = i * 3;
      std::string qn_str = line.substr(start_pos, 3);

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
          line_errors.push_back("QN[" + std::to_string(i) + "]: " + qn_result.second);
        } else {
          record.qn[i] = qn_result.first;
        }
      } else {
        record.qn[i] = 0;
      }
    }

    // Parse FREQ, ERR, WT from column 36 onwards (freeform)
    std::string remainder = line.substr(36);

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
  char buf[4];
  if (qn >= -99 && qn <= 999) {
    snprintf(buf, sizeof(buf), "%3d", qn);
  } else {
    // Out of range - use ** or similar (as per spinv.txt)
    snprintf(buf, sizeof(buf), " **");
  }
  return std::string(buf, 3);
}

// Format double for LIN file (FREQ/ERR/WT in freeform)
std::string LinParser::format_double(double value, int precision) {
  // Use appropriate formatting based on magnitude
  std::ostringstream oss;
  oss << std::setprecision(precision);
  
  if (std::abs(value) < 0.01 || std::abs(value) >= 1e6) {
    // Use scientific notation for very small or large values
    oss << std::scientific << value;
  } else {
    // Use fixed for normal ranges
    oss << std::fixed << value;
  }
  
  return oss.str();
}

bool LinParser::write(std::ostream& os, const LinParseResult& data, std::string& error) {
  // Check if data is valid
  if (!data.success && data.records.empty()) {
    error = "No valid records to write";
    return false;
  }
  
  try {
    for (const auto& record : data.records) {
      // Write 12 quantum numbers in I3 format (positions 1-36)
      for (int i = 0; i < 12; ++i) {
        os << format_qn(record.qn[i]);
      }
      
      // Write space + FREQ, ERR, WT (freeform, space-separated)
      os << "   " << format_double(record.freq, 10);
      os << "     " << format_double(record.err, 6);
      os << "  " << format_double(record.wt, 6);
      os << "\n";
      
      if (!os.good()) {
        error = "Failed to write record to stream";
        return false;
      }
    }
    
    return true;
  } catch (const std::exception& e) {
    error = std::string("Exception during write: ") + e.what();
    return false;
  }
}

bool LinParser::write_file(const std::string& filepath, const LinParseResult& data, 
                           std::string& error) {
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
