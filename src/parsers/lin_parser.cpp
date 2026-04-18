#include "lin_parser.h"
#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <fstream>
#include <sstream>

namespace pickett {

std::vector<LinRecord> LinParser::parse(std::istream &input) {
  std::vector<LinRecord> records;
  std::string line;

  while (std::getline(input, line)) {
    // Skip empty lines
    if (line.empty())
      continue;

    // Skip comment lines (starting with !)
    if (line[0] == '!')
      continue;

    // Skip lines that are too short for QN fields
    if (line.length() < 36)
      continue;

    LinRecord record;

    // Parse 12 quantum numbers (3 characters each, positions 1-36)
    for (int i = 0; i < 12; ++i) {
      size_t start_pos = i * 3;
      std::string qn_str = line.substr(start_pos, 3);

      // Trim whitespace
      qn_str.erase(0, qn_str.find_first_not_of(" \t"));
      qn_str.erase(qn_str.find_last_not_of(" \t") + 1);

      if (!qn_str.empty()) {
        record.qn[i] = std::stoi(qn_str);
      } else {
        record.qn[i] = 0;
      }
    }

    // Parse FREQ, ERR, WT from column 37 onwards (freeform)
    std::string remainder = line.substr(36);
    std::istringstream iss(remainder);

    if (!(iss >> record.freq)) {
      continue; // Skip malformed lines
    }
    if (!(iss >> record.err)) {
      record.err = 0.0;
    }
    if (!(iss >> record.wt)) {
      record.wt = 0.0;
    }

    records.push_back(record);
  }

  return records;
}

std::vector<LinRecord> LinParser::parse_file(const std::string &filepath) {
  std::ifstream file(filepath);
  if (!file.is_open()) {
    return std::vector<LinRecord>();
  }
  return parse(file);
}

} // namespace pickett
