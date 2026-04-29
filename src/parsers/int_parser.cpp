#include "int_parser.h"
#include "utils.h"
#include <cstdio>
#include <fstream>
#include <iomanip>
#include <sstream>

namespace pickett {

// trim, parse_int_safe, and parse_double_safe now come from utils.h

namespace {
constexpr int DECIMAL_BASE = 10;
constexpr int FLAGS_THOUSANDS = 1000;
constexpr int FLAGS_HUNDREDS = 100;
constexpr int FLAGS_TENS = 10;
constexpr double DEFAULT_TEMP_K = 300.0;
constexpr int DEFAULT_MAXV = 999;

int pow10_int(int digits) {
  int result = 1;
  for (int i = 0; i < digits; ++i) {
    result *= DECIMAL_BASE;
  }
  return result;
}
} // namespace

void IntParser::decode_flags(int flags, int &irflg, int &outflg, int &strflg,
                             int &egyflg) {
  irflg = flags / FLAGS_THOUSANDS;
  flags %= FLAGS_THOUSANDS;
  outflg = flags / FLAGS_HUNDREDS;
  flags %= FLAGS_HUNDREDS;
  strflg = flags / FLAGS_TENS;
  egyflg = flags % FLAGS_TENS;
}

IDIPInfo IntParser::decode_idip(int idip, int nvib_digits) {
  IDIPInfo info;
  int v_mod = pow10_int(nvib_digits);

  int remaining = std::abs(idip); // Handle negative IDIP

  info.sym = remaining % DECIMAL_BASE;
  remaining /= DECIMAL_BASE;

  info.v1 = remaining % v_mod;
  remaining /= v_mod;

  info.v2 = remaining % v_mod;
  remaining /= v_mod;

  info.i1 = remaining % DECIMAL_BASE;
  remaining /= DECIMAL_BASE;

  info.typ = remaining % DECIMAL_BASE;
  remaining /= DECIMAL_BASE;

  info.fc = remaining; // Remaining digit(s)

  return info;
}

IDIPInfo IntDipole::get_idip_info(int nvib_digits) const {
  return IntParser::decode_idip(idip, nvib_digits);
}

bool IntParser::parse_header_line(const std::string &line, IntHeader &header,
                                  std::string &error) {
  std::istringstream iss(line);

  // Parse FLAGS
  if (!(iss >> header.flags)) {
    error = "Failed to parse FLAGS";
    return false;
  }

  // Decode flags into components
  decode_flags(header.flags, header.irflg, header.outflg, header.strflg,
               header.egyflg);

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
    header.temp = DEFAULT_TEMP_K; // Default per docs
  }

  // Parse MAXV (default 999 if not present)
  if (!(iss >> header.maxv)) {
    header.maxv = DEFAULT_MAXV; // Default per docs
  }

  return true;
}

bool IntParser::parse_dipole_line(const std::string &line, IntDipole &dipole,
                                  std::string &error) {
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

IntParseExpected IntParser::parse_file(const std::string &filepath) {
  IntParseResult result;
  std::ifstream file(filepath);

  if (!file.is_open()) {
    return std::unexpected(IntParseErrors{{0, "Failed to open file: " + filepath}});
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
    return std::unexpected(
        IntParseErrors{{line_num, "Empty file or failed to read title line"}});
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
    return std::unexpected(IntParseErrors{{line_num, "Missing header line"}});
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
int IntParser::encode_idip(const IDIPInfo &info, int nvib_digits) {
  int v_mod = pow10_int(nvib_digits);

  // Build IDIP from components (reverse of decode_idip)
  // Order: FC, TYP, I1, V2, V1, SYM
  int idip = info.fc;
  idip = idip * DECIMAL_BASE + info.typ;
  idip = idip * DECIMAL_BASE + info.i1;
  idip = idip * v_mod + info.v2;
  idip = idip * v_mod + info.v1;
  idip = idip * DECIMAL_BASE + info.sym;

  return idip;
}

// Encode flags from components
static int encode_flags(int irflg, int outflg, int strflg, int egyflg) {
  return irflg * FLAGS_THOUSANDS + outflg * FLAGS_HUNDREDS +
         strflg * FLAGS_TENS + egyflg;
}

bool IntParser::write(std::ostream &os, const IntParseResult &data,
                      std::string &error) {
  // Check if data is valid
  if (data.dipoles.empty()) {
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
    os << std::setw(11) << std::fixed << std::setprecision(1)
       << data.header.qrot;
    os << std::setw(5) << data.header.fbgn;
    os << std::setw(5) << data.header.fend;
    os << std::setw(8) << std::fixed << std::setprecision(1)
       << data.header.str0;
    os << std::setw(8) << std::fixed << std::setprecision(1)
       << data.header.str1;
    os << std::setw(10) << std::fixed << std::setprecision(1)
       << data.header.fqlim;
    os << std::setw(8) << std::fixed << std::setprecision(1)
       << data.header.temp;
    os << std::setw(6) << data.header.maxv;
    os << "\n";

    // Dipole lines: IDIP DIPOLE /LABEL
    for (const auto &dipole : data.dipoles) {
      // Format IDIP with appropriate width (5-6 chars)
      os << std::setw(6) << dipole.idip;

      // Format dipole value
      os << std::setw(12) << std::fixed << std::setprecision(4)
         << dipole.dipole;

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
  } catch (const std::exception &e) {
    error = std::string("Exception during write: ") + e.what();
    return false;
  }
}

bool IntParser::write_file(const std::string &filepath,
                           const IntParseResult &data, std::string &error) {
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
