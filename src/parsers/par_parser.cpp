#include "par_parser.h"
#include "utils.h"
#include <cctype>
#include <cstdio>
#include <fstream>
#include <iomanip>
#include <limits>
#include <sstream>

namespace pickett {

bool ParParser::is_valid_chr(char c) {
  return c == 'a' || c == 'g' || c == 's';
}

bool ParParser::parse_header_line(const std::string &line, ParHeader &header,
                                  std::string &error) {
  std::istringstream iss(line);

  if (!(iss >> header.npar)) {
    error = "Failed to parse NPAR";
    return false;
  }
  if (!(iss >> header.nline)) {
    error = "Failed to parse NLINE";
    return false;
  }
  if (!(iss >> header.nitr)) {
    error = "Failed to parse NITR";
    return false;
  }
  if (!(iss >> header.nxpar)) {
    error = "Failed to parse NXPAR";
    return false;
  }
  if (!(iss >> header.thresh)) {
    error = "Failed to parse THRESH";
    return false;
  }
  if (!(iss >> header.errtst)) {
    error = "Failed to parse ERRTST";
    return false;
  }
  if (!(iss >> header.frac)) {
    error = "Failed to parse FRAC";
    return false;
  }
  if (!(iss >> header.cal)) {
    error = "Failed to parse CAL";
    return false;
  }

  return true;
}

bool ParParser::parse_option_line(const std::string &line, ParOptionLine &opt,
                                  bool is_first_line, std::string &error) {
  // Parse CHR (first non-whitespace character)
  size_t pos = line.find_first_not_of(" \t");
  if (pos == std::string::npos) {
    error = "Empty option line";
    return false;
  }

  opt.chr = line[pos];
  pos++;

  // Validate CHR on first line only
  if (is_first_line && !is_valid_chr(opt.chr)) {
    error = std::string("Invalid CHR value: ") + opt.chr +
            " (must be 'a', 'g', or 's')";
    return false;
  }

  // Get remaining text after CHR
  std::string remaining = line.substr(pos);

  // Split by commas - this gives us space-separated groups at the start
  std::vector<std::string> comma_parts;
  size_t comma_pos = 0;
  std::string str = remaining;
  while ((comma_pos = str.find(',')) != std::string::npos) {
    comma_parts.push_back(trim(str.substr(0, comma_pos)));
    str = str.substr(comma_pos + 1);
  }
  comma_parts.push_back(trim(str));

  // The first comma_part contains the first few space-separated values
  // Typically SPINO and NVIB, but can include more in some formats
  // We parse them sequentially and assign to fields
  if (comma_parts.size() > 0 && !comma_parts[0].empty()) {
    std::istringstream iss(comma_parts[0]);
    std::vector<int> first_values;
    int val;
    while (iss >> val) {
      first_values.push_back(val);
    }

    // Assign in order: SPINO, NVIB, KNMIN, KNMAX, IXX, IAX, WTPL, WTMN, VSYM
    // (not all may be present, remaining fields come from subsequent
    // comma_parts)
    size_t idx = 0;
    if (idx < first_values.size())
      opt.spino = first_values[idx++];
    if (idx < first_values.size())
      opt.nvib = first_values[idx++];
    if (idx < first_values.size())
      opt.knmin = first_values[idx++];
    if (idx < first_values.size())
      opt.knmax = first_values[idx++];
    if (idx < first_values.size())
      opt.ixx = first_values[idx++];
    if (idx < first_values.size())
      opt.iax = first_values[idx++];
    if (idx < first_values.size())
      opt.wtpl = first_values[idx++];
    if (idx < first_values.size())
      opt.wtmn = first_values[idx++];
    if (idx < first_values.size())
      opt.vsym = first_values[idx++];
    if (idx < first_values.size())
      opt.ewt = first_values[idx++];
    if (idx < first_values.size())
      opt.diag = first_values[idx++];
    if (idx < first_values.size())
      opt.xopt = first_values[idx++];
  }

  // Remaining comma_parts are individual fields (may be empty)
  // We only set values if not already set from the first part
  // Fields in order: KNMIN, KNMAX, IXX, IAX, WTPL, WTMN, VSYM, EWT, DIAG, XOPT
  // But we need to account for how many were already parsed from first part
  // The first part has CHR + values up to some point, then commas start
  // comma_parts[1] is the first field AFTER the comma

  // Actually, let's think about this differently:
  // The format is: CHR SPINO NVIB [space sep vals] , [comma sep vals]
  // Where the comma-separated values start after however many space values
  //
  // For simplicity, we just overwrite if the comma part has a value
  // This handles the case where values are split across both formats

  // Track which fields we've set so we don't overwrite
  size_t field_idx =
      1; // Start after first comma_part (which we already processed)

  if (comma_parts.size() > field_idx && !comma_parts[field_idx].empty()) {
    auto r = parse_int_safe(comma_parts[field_idx]);
    if (r.second.empty())
      opt.knmin = r.first;
  }
  field_idx++;

  if (comma_parts.size() > field_idx && !comma_parts[field_idx].empty()) {
    auto r = parse_int_safe(comma_parts[field_idx]);
    if (r.second.empty())
      opt.knmax = r.first;
  }
  field_idx++;

  if (comma_parts.size() > field_idx && !comma_parts[field_idx].empty()) {
    auto r = parse_int_safe(comma_parts[field_idx]);
    if (r.second.empty())
      opt.ixx = r.first;
  }
  field_idx++;

  if (comma_parts.size() > field_idx && !comma_parts[field_idx].empty()) {
    auto r = parse_int_safe(comma_parts[field_idx]);
    if (r.second.empty())
      opt.iax = r.first;
  }
  field_idx++;

  if (comma_parts.size() > field_idx && !comma_parts[field_idx].empty()) {
    auto r = parse_int_safe(comma_parts[field_idx]);
    if (r.second.empty())
      opt.wtpl = r.first;
  }
  field_idx++;

  if (comma_parts.size() > field_idx && !comma_parts[field_idx].empty()) {
    auto r = parse_int_safe(comma_parts[field_idx]);
    if (r.second.empty())
      opt.wtmn = r.first;
  }
  field_idx++;

  // VSYM - if not already set from first part, try to get from comma parts
  if (comma_parts.size() > field_idx && !comma_parts[field_idx].empty()) {
    auto r = parse_int_safe(comma_parts[field_idx]);
    if (r.second.empty())
      opt.vsym = r.first;
  }
  field_idx++;

  if (comma_parts.size() > field_idx && !comma_parts[field_idx].empty()) {
    auto r = parse_int_safe(comma_parts[field_idx]);
    if (r.second.empty())
      opt.ewt = r.first;
  }
  field_idx++;

  if (comma_parts.size() > field_idx && !comma_parts[field_idx].empty()) {
    auto r = parse_int_safe(comma_parts[field_idx]);
    if (r.second.empty())
      opt.diag = r.first;
  }
  field_idx++;

  if (comma_parts.size() > field_idx && !comma_parts[field_idx].empty()) {
    auto r = parse_int_safe(comma_parts[field_idx]);
    if (r.second.empty())
      opt.xopt = r.first;
  }

  return true;
}

bool ParParser::parse_parameter_line(const std::string &line,
                                     ParParameter &param, std::string &error) {
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

  // Parse IDPAR, PAR, ERPAR from values_part
  std::istringstream iss(values_part);

  if (!(iss >> param.idpar)) {
    error = "Failed to parse IDPAR";
    return false;
  }

  if (!(iss >> param.par)) {
    error = "Failed to parse PAR";
    return false;
  }

  // ERPAR is optional (may not be present)
  if (!(iss >> param.erpar)) {
    param.erpar = 0.0; // Default as requested
  }

  // Trim label
  param.label = trim(label_part);

  return true;
}

ParParseExpected ParParser::parse_file(const std::string &filepath) {
  ParParseResult result;
  std::ifstream file(filepath);

  if (!file.is_open()) {
    return std::unexpected(ParParseErrors{{0, "Failed to open file: " + filepath}});
  }

  std::string line;
  int line_num = 0;

  // Line 1: Title
  if (std::getline(file, line)) {
    line_num++;
    // Remove carriage return for Windows line endings
    if (!line.empty() && line.back() == '\r') {
      line.pop_back();
    }
    result.header.title = line;
  } else {
    return std::unexpected(
        ParParseErrors{{line_num, "Empty file or failed to read title line"}});
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
    return std::unexpected(ParParseErrors{{line_num, "Missing header line"}});
  }

  // Line 3+: Option lines
  bool is_first_option_line = true;
  bool more_option_lines = true;

  while (more_option_lines && std::getline(file, line)) {
    line_num++;
    if (!line.empty() && line.back() == '\r') {
      line.pop_back();
    }

    // Skip empty lines
    if (trim(line).empty()) {
      continue;
    }

    // Check for comment marker line (just !)
    std::string trimmed = trim(line);
    if (trimmed == "!") {
      // This marks the start of comment section - preserve the ! line
      result.comments.push_back(line);
      more_option_lines = false;
      break;
    }

    ParOptionLine opt;
    std::string error;

    if (!parse_option_line(line, opt, is_first_option_line, error)) {
      result.errors.push_back({line_num, error});
      // Continue to try to find more option lines
    } else {
      result.options.push_back(opt);

      // Check if more option lines follow (vsym < 0)
      // If vsym is not set, or vsym >= 0, stop reading option lines
      if (!opt.vsym.has_value() || *opt.vsym >= 0) {
        more_option_lines = false;
      }
    }

    is_first_option_line = false;
  }

  // Remaining lines: Parameters (until we hit a ! comment marker)
  bool in_comment_section = false;
  while (std::getline(file, line)) {
    line_num++;
    if (!line.empty() && line.back() == '\r') {
      line.pop_back();
    }

    // Skip empty lines in parameter section (preserve in comments)
    if (trim(line).empty()) {
      if (in_comment_section) {
        result.comments.push_back(line);
      }
      continue;
    }

    // Check for comment marker line (just !)
    if (trim(line) == "!") {
      in_comment_section = true;
      result.comments.push_back(line);
      continue;
    }

    // If in comment section, preserve everything
    if (in_comment_section) {
      result.comments.push_back(line);
      continue;
    }

    ParParameter param;
    std::string error;

    if (!parse_parameter_line(line, param, error)) {
      result.errors.push_back({line_num, error});
      continue;
    }

    result.parameters.push_back(param);
  }

  // Check parameter count
  if (result.parameters.size() != static_cast<size_t>(result.header.npar)) {
    result.errors.push_back({0, "Warning: Expected " +
                                    std::to_string(result.header.npar) +
                                    " parameters, found " +
                                    std::to_string(result.parameters.size())});
  }

  return result;
}

// Encode CHR field - determine from options or default to 'g'
char ParParser::encode_chr(const std::vector<ParOptionLine> &options) {
  // Default to 'g' (ground state)
  char chr = 'g';

  // Check first option line for CHR value
  if (!options.empty()) {
    char first_chr = options[0].chr;
    if (is_valid_chr(first_chr)) {
      chr = first_chr;
    }
  }

  return chr;
}

// Use format_scientific_upper from utils.h for PAR file format

bool ParParser::write(std::ostream &os, const ParParseResult &data,
                      std::string &error) {
  // Check if data is valid
  if (data.parameters.empty()) {
    error = "No valid parameters to write";
    return false;
  }

  try {
    // Line 1: Title
    os << data.header.title << "\n";

    // Line 2: NPAR NLINE NITR NXPAR THRESH ERRTST FRAC CAL
    os << std::setw(4) << data.header.npar;
    os << std::setw(5) << data.header.nline;
    os << std::setw(5) << data.header.nitr;
    os << std::setw(5) << data.header.nxpar;
    os << "   " << format_scientific_upper(data.header.thresh, 4);
    os << "    " << format_scientific_upper(data.header.errtst, 4);
    os << "    " << format_scientific_upper(data.header.frac, 4);
    os << " " << std::fixed << std::setprecision(10) << data.header.cal;
    os << "\n";

    // Option line(s)
    if (!data.options.empty()) {
      char chr = encode_chr(data.options);
      const auto &opt = data.options[0];

      // Format: CHR SPINO NVIB [comma-separated optional values]
      // Commas allow skipping values (e.g., set option 8 without setting 4-7)
      os << chr;
      if (opt.spino.has_value()) {
        os << std::setw(4) << opt.spino.value();
      }
      if (opt.nvib.has_value()) {
        os << std::setw(4) << opt.nvib.value();
      }

      // Add comma-separated values - consecutive commas represent empty/skipped
      // values
      auto write_optional = [&os](const std::optional<int> &val) {
        if (val.has_value()) {
          os << "," << val.value();
        } else {
          os << ",";
        }
      };

      write_optional(opt.knmin);
      write_optional(opt.knmax);
      write_optional(opt.ixx);
      write_optional(opt.iax);
      write_optional(opt.wtpl);
      write_optional(opt.wtmn);
      write_optional(opt.vsym);
      write_optional(opt.ewt);
      write_optional(opt.diag);
      write_optional(opt.xopt);
      // Trailing commas to complete the format
      os << ",,,";
      os << "\n";
    }

    // Parameter lines: IDPAR PAR ERPAR /LABEL
    for (const auto &param : data.parameters) {
      // IDPAR - right-justified to 10 chars
      os << std::setw(10) << param.idpar;

      // PAR - scientific notation with column alignment
      // Negative numbers: 1 space before '-', Positive: 2 spaces before first
      // digit
      if (param.par < 0) {
        os << " " << format_scientific_upper(param.par, 15);
      } else {
        os << "  " << format_scientific_upper(param.par, 15);
      }

      // ERPAR - scientific notation with column alignment
      if (param.erpar < 0) {
        os << " " << format_scientific_upper(param.erpar, 8);
      } else {
        os << "  " << format_scientific_upper(param.erpar, 8);
      }

      // Label
      if (!param.label.empty()) {
        os << " /" << param.label;
      } else {
        os << " /";
      }
      os << "\n";

      if (!os.good()) {
        error = "Failed to write parameter to stream";
        return false;
      }
    }

    // Write preserved comments (everything after ! line)
    for (const auto &comment : data.comments) {
      os << comment << "\n";
    }

    return true;
  } catch (const std::exception &e) {
    error = std::string("Exception during write: ") + e.what();
    return false;
  }
}

bool ParParser::write_file(const std::string &filepath,
                           const ParParseResult &data, std::string &error) {
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
