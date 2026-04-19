#include "fit_parser.h"
#include <algorithm>
#include <cctype>
#include <cmath>
#include <fstream>
#include <iomanip>
#include <sstream>

namespace pickett {

FitParseResult FitParser::parse_file(const std::string &filepath) {
  FitParseResult result;
  std::ifstream file(filepath);

  if (!file.is_open()) {
    result.errors.emplace_back(0, "Failed to open file: " + filepath);
    result.success = false;
    return result;
  }

  std::string line;
  int line_num = 0;
  int phase = 0; // 0=header, 1=parameters, 2=metadata, 3=lines, 4=correlation
  double prev_exp_freq = 0.0;
  int prev_blend_master = -1;
  bool found_exp_freq_header = false;

  // Parse header (4 lines)
  while (phase == 0 && std::getline(file, line)) {
    line_num++;
    // Remove carriage returns from Windows line endings
    line.erase(std::remove(line.begin(), line.end(), '\r'), line.end());
    
    if (line_num <= 4) {
      parse_header_line(line, result.header, line_num, result.errors);
      if (line_num == 4)
        phase = 1;
    }
  }

  // Parse parameters until we hit "parameters read" line
  while (phase == 1 && std::getline(file, line)) {
    line_num++;
    // Remove carriage returns
    line.erase(std::remove(line.begin(), line.end(), '\r'), line.end());
    
    // Check for end of parameters
    if (line.find("parameters read") != std::string::npos ||
        line.find("parameters") != std::string::npos) {
      phase = 2;
      continue;
    }

    // Skip empty lines
    if (trim(line).empty())
      continue;

    FitParameter param;
    std::string error;
    if (parse_parameter_line(line, param, error)) {
      result.parameters.push_back(param);
    } else {
      result.errors.emplace_back(line_num, error);
    }
  }

  // Skip metadata until we find the line data header
  while (phase == 2 && std::getline(file, line)) {
    line_num++;
    line.erase(std::remove(line.begin(), line.end(), '\r'), line.end());
    if (line.find("EXP.FREQ.") != std::string::npos) {
      found_exp_freq_header = true;
      continue;
    }
    if (found_exp_freq_header && !trim(line).empty() && line.find(':') != std::string::npos) {
      // This is the first data line, put it back by parsing it now
      phase = 3;
      // Parse this line as the first line record
      FitLineRecord record;
      std::string error;
      if (parse_line_record(line, record, prev_exp_freq, prev_blend_master, error)) {
        result.lines.push_back(record);
        prev_exp_freq = record.exp_freq;
        if (record.is_blend && record.blend_master_line == record.seq_number)
          prev_blend_master = record.seq_number;
      } else {
        result.errors.emplace_back(line_num, error);
      }
      break;
    }
  }

  // Parse line records
  while (phase == 3 && std::getline(file, line)) {
    line_num++;
    line.erase(std::remove(line.begin(), line.end(), '\r'), line.end());

    // Check for end of lines section
    // Lines end when we see "NORMALIZED DIAGONAL:" or "NEW PARAMETER"
    if (line.find("NORMALIZED DIAGONAL:") != std::string::npos ||
        line.find("NEW PARAMETER") != std::string::npos) {
      phase = 4;  // Move to updated parameters phase
      // Don't continue - we need to process this line for phase 4 below
    } else {
      // Parse as line record
      
      // Skip empty lines
      if (trim(line).empty())
        continue;

      // Skip lines that don't look like data lines (must have colon for seq number)
      if (line.find(':') == std::string::npos)
        continue;
      
      // Skip section headers that contain colons (like "NORMALIZED DIAGONAL:")
      // A valid line record should have the colon within the first 6 characters
      size_t colon_pos = line.find(':');
      if (colon_pos > 6 || colon_pos == std::string::npos)
        continue;

      FitLineRecord record;
      std::string error;
      if (parse_line_record(line, record, prev_exp_freq, prev_blend_master, error)) {
        result.lines.push_back(record);
        prev_exp_freq = record.exp_freq;
        if (record.is_blend && record.blend_master_line == record.seq_number)
          prev_blend_master = record.seq_number;
        else if (!record.is_blend)
          prev_blend_master = -1;
      } else {
        result.errors.emplace_back(line_num, error);
      }
      continue;  // Skip the phase 4 processing below, get next line
    }
    
    // Phase 4: Parse updated parameters (NEW PARAMETER section)
    // At this point, line contains either "NORMALIZED DIAGONAL:" or "NEW PARAMETER"
    if (phase == 4) {
      // Skip "NORMALIZED DIAGONAL:" section lines until we hit "NEW PARAMETER"
      if (line.find("NORMALIZED DIAGONAL:") != std::string::npos ||
          line.find("1.00000E+000") != std::string::npos) {
        // Continue reading until we find "NEW PARAMETER"
        while (std::getline(file, line)) {
          line_num++;
          line.erase(std::remove(line.begin(), line.end(), '\r'), line.end());
          
          if (line.find("NEW PARAMETER") != std::string::npos) {
            break;  // Found it, will be handled below
          }
        }
      }
      
      // Now line should be "NEW PARAMETER" header or we need to check
      if (line.find("NEW PARAMETER") == std::string::npos) {
        // Didn't find NEW PARAMETER, something is wrong - skip to correlation
        phase = 5;
        continue;
      }
      
      // Parse updated parameter lines until we hit "END OF ITERATION"
      while (std::getline(file, line)) {
        line_num++;
        line.erase(std::remove(line.begin(), line.end(), '\r'), line.end());
        
        // Check for end of parameter section
        if (line.find("END OF ITERATION") != std::string::npos ||
            line.find("MARQUARDT PARAMETER") != std::string::npos) {
          phase = 5;  // Move to correlation phase
          break;
        }
        
        // Skip empty lines
        if (trim(line).empty())
          continue;
        
        // Try to parse as a parameter
        FitParameter param;
        std::string error;
        if (parse_updated_parameter_line(line, param, error)) {
          result.updated_parameters.push_back(param);
        }
        // If it doesn't parse, might be the end of parameters - that's OK
      }
    }
  }

  // Parse correlation matrix (phase 5)
  // Note: The correlation section may be preceded by other sections.
  // We need to skip those until we find actual correlation entries.
  bool correlation_started = false;
  
  while (phase == 5 && std::getline(file, line)) {
    line_num++;
    line.erase(std::remove(line.begin(), line.end(), '\r'), line.end());

    // Skip empty lines
    if (trim(line).empty())
      continue;

    // Check for file ending or new section (title line indicates file wrap)
    if (line.find("(3-Cyano)") != std::string::npos || 
        line.find("Methylenecyclopropane") != std::string::npos)
      break;

    // Skip lines that don't look like correlation data (must be long enough)
    if (line.size() < 16)
      continue;

    std::string error;
    std::vector<FitCorrelationEntry> entries;
    if (parse_correlation_line(line, entries, error)) {
      result.correlations.insert(result.correlations.end(), entries.begin(), entries.end());
      correlation_started = true;
    } else if (correlation_started) {
      // If correlation parsing failed after we've started, it might be the end
      // But only break if we're seeing a clear non-correlation pattern
      if (line.size() < 32)  // Correlation lines should be quite long (128+ chars for 8 entries)
        continue;  // Skip short lines
    }
    // If correlation hasn't started yet, keep trying lines (skip non-correlation sections)
  }

  file.close();
  return result;
}

// Helper function to extract integer value after a pattern
static bool extract_int_after_pattern(const std::string& line, const std::string& pattern, int& result) {
  size_t pos = line.find(pattern);
  if (pos == std::string::npos) return false;
  
  pos += pattern.length();
  // Skip whitespace
  while (pos < line.size() && std::isspace(static_cast<unsigned char>(line[pos]))) pos++;
  
  // Parse integer
  if (pos >= line.size() || !std::isdigit(static_cast<unsigned char>(line[pos]))) return false;
  
  size_t end_pos = pos;
  while (end_pos < line.size() && std::isdigit(static_cast<unsigned char>(line[end_pos]))) end_pos++;
  
  try {
    result = std::stoi(line.substr(pos, end_pos - pos));
    return true;
  } catch (...) {
    return false;
  }
}

// Helper function to extract double value after a pattern
static bool extract_double_after_pattern(const std::string& line, const std::string& pattern, double& result) {
  size_t pos = line.find(pattern);
  if (pos == std::string::npos) return false;
  
  pos += pattern.length();
  // Skip whitespace
  while (pos < line.size() && std::isspace(static_cast<unsigned char>(line[pos]))) pos++;
  
  // Parse number (including scientific notation)
  if (pos >= line.size()) return false;
  
  size_t end_pos = pos;
  while (end_pos < line.size() && 
         (std::isdigit(static_cast<unsigned char>(line[end_pos])) || 
          line[end_pos] == '.' || 
          line[end_pos] == 'E' || 
          line[end_pos] == 'e' ||
          line[end_pos] == '+' ||
          line[end_pos] == '-')) {
    end_pos++;
  }
  
  std::string num_str = line.substr(pos, end_pos - pos);
  if (num_str.empty()) return false;
  
  try {
    result = std::stod(num_str);
    return true;
  } catch (...) {
    return false;
  }
}

bool FitParser::parse_header_line(const std::string &line, FitHeader &header,
                                   int line_num,
                                   std::vector<std::pair<int, std::string>> &errors) {
  switch (line_num) {
  case 1:
    header.title = trim(line);
    break;
  case 2: {
    // Parse: LINES REQUESTED= 2446 NUMBER OF PARAMETERS=207 NUMBER OF ITERATIONS= 15
    extract_int_after_pattern(line, "LINES REQUESTED=", header.lines_requested);
    extract_int_after_pattern(line, "NUMBER OF PARAMETERS=", header.num_parameters);
    extract_int_after_pattern(line, "NUMBER OF ITERATIONS=", header.num_iterations);
    break;
  }
  case 3: {
    // Parse: MARQUARDT PARAMETER =0.0000E+000 max (OBS-CALC)/ERROR =1.0000E+006
    extract_double_after_pattern(line, "MARQUARDT PARAMETER =", header.marquardt_param);
    extract_double_after_pattern(line, "max (OBS-CALC)/ERROR =", header.max_obs_calc_error);
    break;
  }
  case 4:
    // Line 4 is "PARAMETERS - A.PRIORI ERROR" - no parsing needed
    break;
  }
  return true;
}

bool FitParser::parse_parameter_line(const std::string &line, FitParameter &param,
                                      std::string &error) {
  // Parameter format is whitespace-separated, not fixed-width
  // Example: "     1      1         1000000  7.7805592632577E+003   1.000000E-037 A_gs"
  // Fields: index, copy, idpar, value, error, label
  
  try {
    std::istringstream iss(line);
    
    // Read index
    if (!(iss >> param.index)) {
      error = "Failed to parse index";
      return false;
    }
    
    // Read copy
    if (!(iss >> param.copy)) {
      error = "Failed to parse copy";
      return false;
    }
    
    // Read IDPAR (can be large, up to 10 digits)
    long long idpar_val;
    if (!(iss >> idpar_val)) {
      error = "Failed to parse IDPAR";
      return false;
    }
    param.idpar = static_cast<int>(idpar_val);
    
    // Read value
    if (!(iss >> param.value)) {
      error = "Failed to parse value";
      return false;
    }
    
    // Read error
    if (!(iss >> param.error)) {
      error = "Failed to parse error";
      return false;
    }
    
    // Read label (rest of line)
    std::string label;
    if (iss >> label) {
      // Remove leading '/' if present
      if (!label.empty() && label[0] == '/') {
        label = label.substr(1);
      }
      param.label = label;
    } else {
      param.label = "";
    }
    
    return true;
  } catch (const std::exception &e) {
    error = std::string("Exception parsing parameter: ") + e.what();
    return false;
  }
}

bool FitParser::parse_line_record(const std::string &line, FitLineRecord &record,
                                   double prev_exp_freq, int prev_blend_master,
                                   std::string &error) {
  // Format from CALFIT.C FMT_xbgnMW: "%5d: %s%14.5f%14.5f %10.5f %10.5f %9.5f"
  // Where %s is the QN string (36 chars from qnfmt2: 12 QNs x 3 chars each)
  // 
  // Layout:
  // Pos 1-6:  Seq + colon (e.g., "    1:") - 6 chars
  // Pos 7-42: QN field (36 chars, 12 x I3) 
  // Pos 43+:  Numeric fields
  
  if (line.size() < 50) {
    error = "Line record too short";
    return false;
  }

  try {
    // Find the colon to get sequence number
    size_t colon_pos = line.find(':');
    if (colon_pos == std::string::npos || colon_pos > 6) {
      error = "Cannot find sequence number colon";
      return false;
    }
    
    // Parse sequence number (positions 1-5, right-justified in %5d format)
    auto seq = parse_int_safe(line.substr(0, colon_pos));
    if (!seq.second.empty()) {
      error = "Failed to parse sequence number: " + seq.second;
      return false;
    }
    record.seq_number = seq.first;
    
    // QN field starts at colon+2 (after ": "), is 36 characters
    // From qnfmt2: 12 QNs printed as %3d, each taking 3 characters
    size_t qn_start = colon_pos + 2;
    if (qn_start + 36 > line.size()) {
      error = "Line too short for QN field";
      return false;
    }
    
    std::string qn_str = line.substr(qn_start, 36);
    
    // Parse 12 quantum numbers, each 3 characters (I3 format with leading spaces)
    for (int i = 0; i < 12; i++) {
      std::string qn_sub = qn_str.substr(i * 3, 3);
      auto qn_val = parse_int_safe(qn_sub);
      if (qn_val.second.empty()) {
        record.qn[i] = qn_val.first;
      } else {
        record.qn[i] = 0;
      }
    }
    
    // Numeric fields start at position qn_start + 36
    size_t data_start = qn_start + 36;
    if (data_start >= line.size()) {
      error = "Line too short for numeric fields";
      return false;
    }
    
    std::string data_str = line.substr(data_start);
    std::istringstream iss(data_str);
    
    // Read the 5 base numeric fields
    // Format: %14.5f %14.5f %10.5f %10.5f %9.5f
    if (!(iss >> record.exp_freq >> record.calc_freq >> record.diff >> 
          record.exp_err >> record.est_err)) {
      error = "Failed to parse base numeric fields";
      return false;
    }
    
    // Try to read blend fields (FMT_xblnMW: "%14.5f %10.5f %6.4f")
    double avg_calc, avg_diff, wt;
    if (iss >> avg_calc >> avg_diff >> wt) {
      record.avg_calc_freq = avg_calc;
      record.avg_diff = avg_diff;
      record.wt = wt;
      record.is_blend = true;
      
      // Determine blend master
      if (std::abs(record.exp_freq - prev_exp_freq) < 0.0001) {
        // Same frequency as previous, part of existing blend
        record.blend_master_line = prev_blend_master;
      } else {
        // New blend starts here
        record.blend_master_line = record.seq_number;
      }
    } else {
      // No blend fields
      record.avg_calc_freq = std::nullopt;
      record.avg_diff = std::nullopt;
      record.wt = std::nullopt;
      record.is_blend = false;
      record.blend_master_line = -1;
    }
    
    return true;
  } catch (const std::exception &e) {
    error = std::string("Exception parsing line record: ") + e.what();
    return false;
  }
}

bool FitParser::parse_updated_parameter_line(const std::string &line,
                                              FitParameter &param,
                                              std::string &error) {
  // Updated parameter format from NEW PARAMETER section:
  // "   1         1000000       A_gs   7780.559263258(  0)      0.000000000    "
  // Format: index(4), idpar(10), label, value(error), error_value
  // The value format is special: it includes the error in parentheses
  
  std::istringstream iss(line);
  
  // Read index
  if (!(iss >> param.index)) {
    error = "Failed to parse index";
    return false;
  }
  
  // Read IDPAR
  long long idpar_val;
  if (!(iss >> idpar_val)) {
    error = "Failed to parse IDPAR";
    return false;
  }
  param.idpar = static_cast<int>(idpar_val);
  
  // Read label
  if (!(iss >> param.label)) {
    error = "Failed to parse label";
    return false;
  }
  
  // Read value with error in parentheses (e.g., "7780.559263258(  0)")
  // This is a complex format - the number is followed by error in parens
  std::string value_str;
  if (!(iss >> value_str)) {
    error = "Failed to parse value";
    return false;
  }
  
  // Parse the value (extract number before parentheses)
  size_t paren_open = value_str.find('(');
  if (paren_open != std::string::npos) {
    std::string num_str = value_str.substr(0, paren_open);
    auto val_result = parse_double_safe(num_str);
    if (val_result.second.empty()) {
      param.value = val_result.first;
    } else {
      // Try without the suffix
      auto val_result2 = parse_double_safe(value_str);
      if (val_result2.second.empty()) {
        param.value = val_result2.first;
      } else {
        error = "Failed to parse value: " + val_result2.second;
        return false;
      }
    }
    
    // Extract error from parentheses
    size_t paren_close = value_str.find(')', paren_open);
    if (paren_close != std::string::npos) {
      std::string err_str = value_str.substr(paren_open + 1, paren_close - paren_open - 1);
      auto err_result = parse_double_safe(err_str);
      if (err_result.second.empty()) {
        param.error = err_result.first;
      } else {
        param.error = 0.0;  // Default if can't parse
      }
    }
  } else {
    // No parentheses - just parse as regular number
    auto val_result = parse_double_safe(value_str);
    if (val_result.second.empty()) {
      param.value = val_result.first;
    } else {
      error = "Failed to parse value: " + val_result.second;
      return false;
    }
    
    // Read error value separately if present
    std::string err_str;
    if (iss >> err_str) {
      // Might be error value or exponent part
      auto err_result = parse_double_safe(err_str);
      if (err_result.second.empty()) {
        param.error = err_result.first;
      } else {
        param.error = 0.0;
      }
    } else {
      param.error = 0.0;
    }
  }
  
  // Read the second error field if present (after the value)
  // Skip the exponent part if it was separate (e.g., "E-03")
  std::string extra;
  while (iss >> extra) {
    if (extra[0] == 'E' || extra[0] == 'e' || extra[0] == '-' || 
        (extra[0] >= '0' && extra[0] <= '9')) {
      // This might be the exponent or error value
      auto extra_result = parse_double_safe(extra);
      if (extra_result.second.empty() && param.error == 0.0) {
        param.error = extra_result.first;
      }
    }
  }
  
  // Set copy to 1 (not specified in this format, assume 1)
  param.copy = 1;
  
  return true;
}

bool FitParser::parse_correlation_line(const std::string &line,
                                         std::vector<FitCorrelationEntry> &entries,
                                         std::string &error) {
  // Correlation format from prcorr() in CALFIT: "%3d%3d%10.6f"
  // 3 chars for row (I3), 3 chars for col (I3), 10 chars for value (F10.6)
  // Total 16 chars per entry, packed 8 per line
  
  if (line.size() < 16) {
    error = "Correlation line too short";
    return false;
  }
  
  // Parse entries at 16-character intervals
  // Each entry: row (3 chars), col (3 chars), value (10 chars)
  size_t pos = 0;
  const int entry_width = 16;
  bool found_any = false;
  
  while (pos + entry_width <= line.size()) {
    std::string entry = line.substr(pos, entry_width);
    
    // Extract components
    std::string row_str = entry.substr(0, 3);
    std::string col_str = entry.substr(3, 3);
    std::string val_str = entry.substr(6, 10);
    
    // Parse row and column
    auto row = parse_int_safe(row_str);
    auto col = parse_int_safe(col_str);
    auto val = parse_double_safe(val_str);
    
    // Validate: row and col must be positive integers with valid range
    // For this file format, parameters are typically 1-500
    if (row.second.empty() && col.second.empty() && val.second.empty() &&
        row.first > 0 && col.first > 0 && 
        row.first <= 500 && col.first <= 500 &&  // Reasonable upper limit
        row.first != col.first) {
      FitCorrelationEntry ce;
      ce.row = row.first;
      ce.col = col.first;
      ce.value = val.first;
      entries.push_back(ce);
      found_any = true;
    } else if (found_any) {
      // If we found valid entries before and now find invalid ones,
      // this might be the end of correlation data on this line
      break;
    }
    // If no valid entries found yet, keep trying (skip leading garbage)
    
    pos += entry_width;
  }
  
  return found_any;
}

std::pair<double, std::string> FitParser::parse_double_safe(const std::string &s) {
  std::string trimmed = trim(s);
  if (trimmed.empty())
    return {0.0, "Empty string"};

  try {
    size_t pos;
    double val = std::stod(trimmed, &pos);
    if (pos != trimmed.size()) {
      return {val, "Extra characters after number"};
    }
    return {val, ""};
  } catch (const std::invalid_argument &) {
    return {0.0, "Invalid number format"};
  } catch (const std::out_of_range &) {
    return {0.0, "Number out of range"};
  }
}

std::pair<int, std::string> FitParser::parse_int_safe(const std::string &s) {
  std::string trimmed = trim(s);
  if (trimmed.empty())
    return {0, "Empty string"};

  try {
    size_t pos;
    long val = std::stol(trimmed, &pos);
    if (pos != trimmed.size()) {
      return {static_cast<int>(val), "Extra characters after number"};
    }
    return {static_cast<int>(val), ""};
  } catch (const std::invalid_argument &) {
    return {0, "Invalid integer format"};
  } catch (const std::out_of_range &) {
    return {0, "Integer out of range"};
  }
}

std::string FitParser::trim(const std::string &s) {
  auto start = std::find_if_not(s.begin(), s.end(), [](unsigned char c) { return std::isspace(c); });
  auto end = std::find_if_not(s.rbegin(), s.rend(), [](unsigned char c) { return std::isspace(c); }).base();
  if (start >= end)
    return "";
  return std::string(start, end);
}

} // namespace pickett
