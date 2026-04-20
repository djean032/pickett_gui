#include "utils.h"
#include <cctype>
#include <iomanip>
#include <sstream>

namespace pickett {

std::string trim(const std::string &s) {
  size_t start = 0;
  while (start < s.size() && std::isspace(s[start]))
    start++;

  size_t end = s.size();
  while (end > start && std::isspace(s[end - 1]))
    end--;

  return s.substr(start, end - start);
}

std::pair<int, std::string> parse_int_safe(const std::string &s) {
  std::string trimmed = trim(s);
  if (trimmed.empty()) {
    return {0, "Empty string"};
  }

  try {
    size_t pos = 0;
    int result = std::stoi(trimmed, &pos);
    if (pos != trimmed.size()) {
      return {0, "Invalid characters after number"};
    }
    return {result, ""};
  } catch (const std::invalid_argument &) {
    return {0, "Not a valid integer"};
  } catch (const std::out_of_range &) {
    return {0, "Number out of range"};
  }
}

std::pair<double, std::string> parse_double_safe(const std::string &s) {
  std::string trimmed = trim(s);
  if (trimmed.empty()) {
    return {0.0, "Empty string"};
  }

  // Validate format - allow: digits, ., e/E, +-, but must have valid structure
  bool has_digit = false;
  bool has_dot = false;
  bool has_exp = false;
  bool has_sign = false;
  bool in_leading_ws = true;

  for (size_t i = 0; i < trimmed.size(); ++i) {
    char c = trimmed[i];
    if (std::isdigit(c)) {
      has_digit = true;
      in_leading_ws = false;
    } else if (c == '.' && !has_dot && !has_exp) {
      has_dot = true;
      in_leading_ws = false;
    } else if ((c == 'e' || c == 'E') && !has_exp && has_digit) {
      has_exp = true;
      in_leading_ws = false;
      has_sign = false; // reset for exponent sign
    } else if (c == '+' || c == '-') {
      // Allow sign at start (in_leading_ws) or in exponent
      if (has_exp && !has_sign && i > 0 &&
          (trimmed[i - 1] == 'e' || trimmed[i - 1] == 'E')) {
        has_sign = true;
        in_leading_ws = false;
      } else if (!has_exp && !has_sign && in_leading_ws) {
        // Sign at start of number
        has_sign = true;
        in_leading_ws = false;
      } else {
        return {0.0, "Invalid sign placement"};
      }
    } else if (std::isspace(c)) {
      return {0.0, "Unexpected whitespace"};
    } else {
      return {0.0, "Invalid character: " + std::string(1, c)};
    }
  }

  if (!has_digit) {
    return {0.0, "No digits found"};
  }

  try {
    size_t pos = 0;
    double result = std::stod(trimmed, &pos);
    if (pos != trimmed.size()) {
      return {0.0, "Invalid characters after number"};
    }
    return {result, ""};
  } catch (const std::invalid_argument &) {
    return {0.0, "Not a valid number"};
  } catch (const std::out_of_range &) {
    return {0.0, "Number out of range"};
  }
}

std::string format_scientific_upper(double value, int precision,
                                    int exponent_digits) {
  std::ostringstream oss;
  oss << std::uppercase << std::scientific << std::setprecision(precision)
      << value;
  std::string result = oss.str();

  // Convert exponent to specified digit width with leading zeros
  size_t e_pos = result.find('E');
  if (e_pos != std::string::npos && e_pos + 2 < result.size()) {
    size_t sign_pos = e_pos + 1;
    if (result[sign_pos] == '+' || result[sign_pos] == '-') {
      size_t digits_pos = sign_pos + 1;
      std::string exp_digits = result.substr(digits_pos);

      // Pad with leading zeros
      while (static_cast<int>(exp_digits.length()) < exponent_digits) {
        exp_digits = "0" + exp_digits;
      }

      result = result.substr(0, digits_pos) + exp_digits;
    }
  }

  return result;
}

std::string format_scientific_lin(double value, int sig_figs) {
  std::ostringstream oss;
  oss << std::uppercase << std::scientific << std::setprecision(sig_figs)
      << value;
  std::string result = oss.str();

  // Pad exponent to 2 digits for LIN format (e.g., E-05 not E-005)
  size_t e_pos = result.find('E');
  if (e_pos != std::string::npos && e_pos + 2 < result.size()) {
    size_t sign_pos = e_pos + 1;
    if (result[sign_pos] == '+' || result[sign_pos] == '-') {
      size_t digits_pos = sign_pos + 1;
      std::string exp_digits = result.substr(digits_pos);

      // Pad to 2 digits for LIN format
      while (exp_digits.length() < 2) {
        exp_digits = "0" + exp_digits;
      }

      result = result.substr(0, digits_pos) + exp_digits;
    }
  }

  return result;
}

} // namespace pickett
