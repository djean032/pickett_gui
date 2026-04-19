#include "int_parser.h"
#include <cctype>
#include <cmath>
#include <cstdio>
#include <fstream>
#include <iomanip>
#include <limits>
#include <sstream>

namespace pickett {

std::string IntParser::trim(const std::string& s) {
    size_t start = s.find_first_not_of(" \t\r\n");
    if (start == std::string::npos) return "";
    size_t end = s.find_last_not_of(" \t\r\n");
    return s.substr(start, end - start + 1);
}

std::pair<int, std::string> IntParser::parse_int_safe(const std::string& s) {
    if (s.empty()) {
        return {0, "Empty string"};
    }

    size_t start = 0;
    bool negative = false;

    // Skip leading whitespace
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
    } else if (s[start] == '+') {
        start++;
    }

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

    if (result < std::numeric_limits<int>::min() ||
        result > std::numeric_limits<int>::max()) {
        return {0, "Integer overflow"};
    }

    return {static_cast<int>(result), ""};
}

std::pair<double, std::string> IntParser::parse_double_safe(const std::string& s) {
    if (s.empty()) {
        return {0.0, "Empty string"};
    }

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
            has_dot = true;
            in_leading_ws = false;
        } else if ((c == 'e' || c == 'E') && !has_exp && has_digit) {
            has_exp = true;
            in_leading_ws = false;
            if (i + 1 < s.size() && (s[i+1] == '+' || s[i+1] == '-')) {
                i++;
            }
        } else if (c == '+' || c == '-') {
            if (in_leading_ws) {
                has_sign = true;
                in_leading_ws = false;
            } else if (has_exp && i > 0 && (s[i-1] == 'e' || s[i-1] == 'E')) {
                in_leading_ws = false;
            } else if (!has_digit && !has_sign) {
                has_sign = true;
            } else {
                return {0.0, "Invalid sign position"};
            }
        } else if (std::isspace(c)) {
            if (in_leading_ws) {
                // Still in leading whitespace
            } else if (has_digit) {
                for (size_t j = i + 1; j < s.size(); ++j) {
                    if (!std::isspace(s[j])) {
                        return {0.0, "Invalid character: space in middle"};
                    }
                }
                break;
            } else {
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

void IntParser::decode_flags(int flags, int& irflg, int& outflg,
                            int& strflg, int& egyflg) {
    irflg = flags / 1000;
    flags %= 1000;
    outflg = flags / 100;
    flags %= 100;
    strflg = flags / 10;
    egyflg = flags % 10;
}

IDIPInfo IntParser::decode_idip(int idip, int nvib_digits) {
    IDIPInfo info;
    int v_mod = static_cast<int>(std::pow(10, nvib_digits));  // 10, 100, or 1000
    int v_divisor = v_mod;   // Same as v_mod for shifting

    int remaining = std::abs(idip);  // Handle negative IDIP

    info.sym = remaining % 10;
    remaining /= 10;

    info.v1 = remaining % v_mod;
    remaining /= v_divisor;

    info.v2 = remaining % v_mod;
    remaining /= v_divisor;

    info.i1 = remaining % 10;
    remaining /= 10;

    info.typ = remaining % 10;
    remaining /= 10;

    info.fc = remaining;  // Remaining digit(s)

    return info;
}

IDIPInfo IntDipole::get_idip_info(int nvib_digits) const {
    return IntParser::decode_idip(idip, nvib_digits);
}

bool IntParser::parse_header_line(const std::string& line, IntHeader& header,
                                  std::string& error) {
    std::istringstream iss(line);

    // Parse FLAGS
    if (!(iss >> header.flags)) {
        error = "Failed to parse FLAGS";
        return false;
    }

    // Decode flags into components
    decode_flags(header.flags, header.irflg, header.outflg,
                 header.strflg, header.egyflg);

    // Parse TAG
    if (!(iss >> header.tag)) {
        error = "Failed to parse TAG";
        return false;
    }

    // Parse QROT
    if (!(iss >> header.qrot)) {
        error = "Failed to parse QROT";
        return false;
    }

    // Parse FBGN
    if (!(iss >> header.fbgn)) {
        error = "Failed to parse FBGN";
        return false;
    }

    // Parse FEND
    if (!(iss >> header.fend)) {
        error = "Failed to parse FEND";
        return false;
    }

    // Parse STR0
    if (!(iss >> header.str0)) {
        error = "Failed to parse STR0";
        return false;
    }

    // Parse STR1
    if (!(iss >> header.str1)) {
        error = "Failed to parse STR1";
        return false;
    }

    // Parse FQLIM
    if (!(iss >> header.fqlim)) {
        error = "Failed to parse FQLIM";
        return false;
    }

    // Parse TEMP (default 300K if not present)
    if (!(iss >> header.temp)) {
        header.temp = 300.0;  // Default per docs
    }

    // Parse MAXV (default 999 if not present)
    if (!(iss >> header.maxv)) {
        header.maxv = 999;  // Default per docs
    }

    return true;
}

bool IntParser::parse_dipole_line(const std::string& line, IntDipole& dipole,
                                  std::string& error) {
    // Split on '/' to separate values from label
    size_t slash_pos = line.find('/');
    std::string values_part;
    std::string label_part;

    if (slash_pos == std::string::npos) {
        values_part = line;
    } else {
        values_part = line.substr(0, slash_pos);
        label_part = line.substr(slash_pos + 1);
    }

    // Parse IDIP and DIPOLE from values_part
    std::istringstream iss(values_part);

    if (!(iss >> dipole.idip)) {
        error = "Failed to parse IDIP";
        return false;
    }

    if (!(iss >> dipole.dipole)) {
        error = "Failed to parse DIPOLE";
        return false;
    }

    // Trim label
    dipole.label = trim(label_part);

    return true;
}

IntParseResult IntParser::parse_file(const std::string& filepath) {
    IntParseResult result;
    std::ifstream file(filepath);

    if (!file.is_open()) {
        result.success = false;
        result.errors.push_back({0, "Failed to open file: " + filepath});
        return result;
    }

    std::string line;
    int line_num = 0;

    // Line 1: Title
    if (std::getline(file, line)) {
        line_num++;
        if (!line.empty() && line.back() == '\r') {
            line.pop_back();
        }
        result.header.title = line;
    } else {
        result.success = false;
        result.errors.push_back({line_num, "Empty file or failed to read title line"});
        return result;
    }

    // Line 2: Header parameters
    if (std::getline(file, line)) {
        line_num++;
        if (!line.empty() && line.back() == '\r') {
            line.pop_back();
        }

        std::string error;
        if (!parse_header_line(line, result.header, error)) {
            result.errors.push_back({line_num, error});
            // Continue anyway - might be recoverable
        }
    } else {
        result.success = false;
        result.errors.push_back({line_num, "Missing header line"});
        return result;
    }

    // Line 3+: Dipole lines
    while (std::getline(file, line)) {
        line_num++;
        if (!line.empty() && line.back() == '\r') {
            line.pop_back();
        }

        // Skip empty lines
        if (trim(line).empty()) {
            continue;
        }

        // Skip comment lines (starting with !)
        size_t first_non_space = line.find_first_not_of(" \t");
        if (first_non_space != std::string::npos && line[first_non_space] == '!') {
            continue;
        }

        IntDipole dipole;
        std::string error;

        if (!parse_dipole_line(line, dipole, error)) {
            result.errors.push_back({line_num, error});
            continue;
        }

        result.dipoles.push_back(dipole);
    }

    return result;
}

// Encode IDIP from components
int IntParser::encode_idip(const IDIPInfo& info, int nvib_digits) {
    int v_mod = static_cast<int>(std::pow(10, nvib_digits));
    
    // Build IDIP from components (reverse of decode_idip)
    // Order: FC, TYP, I1, V2, V1, SYM
    int idip = info.fc;
    idip = idip * 10 + info.typ;
    idip = idip * 10 + info.i1;
    idip = idip * v_mod + info.v2;
    idip = idip * v_mod + info.v1;
    idip = idip * 10 + info.sym;
    
    return idip;
}

// Encode flags from components
static int encode_flags(int irflg, int outflg, int strflg, int egyflg) {
    return irflg * 1000 + outflg * 100 + strflg * 10 + egyflg;
}

bool IntParser::write(std::ostream& os, const IntParseResult& data, std::string& error) {
  // Check if data is valid
  if (!data.success && data.dipoles.empty()) {
    error = "No valid dipoles to write";
    return false;
  }
  
  try {
    // Line 1: Title
    os << data.header.title << "\n";
    
    // Line 2: FLAGS TAG QROT FBGN FEND STR0 STR1 FQLIM TEMP MAXV
    // Reconstruct FLAGS from components
    int flags = encode_flags(data.header.irflg, data.header.outflg, 
                             data.header.strflg, data.header.egyflg);
    os << std::setw(5) << flags;
    os << std::setw(7) << data.header.tag;
    os << std::setw(11) << std::fixed << std::setprecision(1) << data.header.qrot;
    os << std::setw(5) << data.header.fbgn;
    os << std::setw(5) << data.header.fend;
    os << std::setw(8) << std::fixed << std::setprecision(1) << data.header.str0;
    os << std::setw(8) << std::fixed << std::setprecision(1) << data.header.str1;
    os << std::setw(10) << std::fixed << std::setprecision(1) << data.header.fqlim;
    os << std::setw(8) << std::fixed << std::setprecision(1) << data.header.temp;
    os << std::setw(6) << data.header.maxv;
    os << "\n";
    
    // Dipole lines: IDIP DIPOLE /LABEL
    for (const auto& dipole : data.dipoles) {
      // Format IDIP with appropriate width (5-6 chars)
      os << std::setw(6) << dipole.idip;
      
      // Format dipole value
      os << std::setw(12) << std::fixed << std::setprecision(4) << dipole.dipole;
      
      // Add label if present
      if (!dipole.label.empty()) {
        os << "      / " << dipole.label;
      }
      os << "\n";
      
      if (!os.good()) {
        error = "Failed to write dipole to stream";
        return false;
      }
    }
    
    return true;
  } catch (const std::exception& e) {
    error = std::string("Exception during write: ") + e.what();
    return false;
  }
}

bool IntParser::write_file(const std::string& filepath, const IntParseResult& data,
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
