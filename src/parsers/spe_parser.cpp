#include "spe_parser.h"
#include <algorithm>
#include <cstring>
#include <fstream>
#include <sstream>

namespace pickett {

SpeHeader::SpeHeader()
    : day(0), month(0), year(0), hour(0), minute(0), second(0),
      vkmst(0.0f), vkmend(0.0f), grid(0.0f), sampre(0.0f), gain(0.0f),
      timec(0.0f), phase(0.0f), pps(0.0f), frmod(0.0f), frampl(0.0f) {
  std::memset(comment, 0, sizeof(comment));
  std::memset(lamp, 0, sizeof(lamp));
  std::memset(sample, 0, sizeof(sample));
  std::memset(scansp, 0, sizeof(scansp));
}

SpeParseResult SpeParser::parse_file(const std::string &filepath) {
  SpeParseResult result;

  std::ifstream file(filepath, std::ios::binary);
  if (!file.is_open()) {
    result.errors.emplace_back(0, "Failed to open file: " + filepath);
    result.success = false;
    return result;
  }

  // Read entire file
  file.seekg(0, std::ios::end);
  size_t file_size = file.tellg();
  file.seekg(0, std::ios::beg);

  std::vector<uint8_t> buffer(file_size);
  if (!file.read(reinterpret_cast<char *>(buffer.data()), file_size)) {
    result.errors.emplace_back(0, "Failed to read file: " + filepath);
    result.success = false;
    return result;
  }
  file.close();

  return parse_buffer(buffer);
}

SpeParseResult SpeParser::parse_buffer(const std::vector<uint8_t> &buffer) {
  SpeParseResult result;

  // Minimum file size: header (170) + at least 1 data point (4) + footer (26) = 200
  if (buffer.size() < 200) {
    result.errors.emplace_back(0, "File too small (minimum 200 bytes)");
    result.success = false;
    return result;
  }

  // Parse header (170 bytes)
  if (!parse_header(buffer, result.header, result.errors)) {
    result.success = false;
    return result;
  }

  // Validate header
  if (!validate_header(result.header, result.errors)) {
    // Don't mark as failure - just warnings
  }

  // Parse data section
  if (!parse_data(buffer, result.npts, result.intensities, result.errors)) {
    result.success = false;
    return result;
  }

  // Parse footer
  if (!parse_footer(buffer, result.footer, result.errors)) {
    result.success = false;
    return result;
  }

  return result;
}

bool SpeParser::parse_header(const std::vector<uint8_t> &data, SpeHeader &header,
                             std::vector<std::pair<int, std::string>> &errors) {
  if (data.size() < 170) {
    errors.emplace_back(0, "Not enough data for header (need 170 bytes)");
    return false;
  }

  size_t offset = 0;

  // Comment (72 bytes)
  std::memcpy(header.comment, &data[offset], 72);
  header.comment[72] = '\0';
  offset += 72;

  // Date/time fields (6 × 2 bytes = 12 bytes)
  std::memcpy(&header.day, &data[offset], 2);
  offset += 2;
  std::memcpy(&header.month, &data[offset], 2);
  offset += 2;
  std::memcpy(&header.year, &data[offset], 2);
  offset += 2;
  std::memcpy(&header.hour, &data[offset], 2);
  offset += 2;
  std::memcpy(&header.minute, &data[offset], 2);
  offset += 2;
  std::memcpy(&header.second, &data[offset], 2);
  offset += 2;

  // Lamp (6 bytes)
  std::memcpy(header.lamp, &data[offset], 6);
  header.lamp[6] = '\0';
  offset += 6;

  // Float fields (VKMST, VKMEND, GRID)
  std::memcpy(&header.vkmst, &data[offset], 4);
  offset += 4;
  std::memcpy(&header.vkmend, &data[offset], 4);
  offset += 4;
  std::memcpy(&header.grid, &data[offset], 4);
  offset += 4;

  // Sample (20 bytes)
  std::memcpy(header.sample, &data[offset], 20);
  header.sample[20] = '\0';
  offset += 20;

  // Float fields (SAMPRE, GAIN, TIMEC, PHASE)
  std::memcpy(&header.sampre, &data[offset], 4);
  offset += 4;
  std::memcpy(&header.gain, &data[offset], 4);
  offset += 4;
  std::memcpy(&header.timec, &data[offset], 4);
  offset += 4;
  std::memcpy(&header.phase, &data[offset], 4);
  offset += 4;

  // SCANSP (6 bytes)
  std::memcpy(header.scansp, &data[offset], 6);
  header.scansp[6] = '\0';
  offset += 6;

  // Float fields (PPS, FRMOD, FRAMPL)
  std::memcpy(&header.pps, &data[offset], 4);
  offset += 4;
  std::memcpy(&header.frmod, &data[offset], 4);
  offset += 4;
  std::memcpy(&header.frampl, &data[offset], 4);
  offset += 4;

  // Extended format: consume extra 14 bytes (possibly ISMALL/ILARGE or padding)
  // This brings offset from 156 to 170
  offset += 14;

  // Verify we consumed exactly 170 bytes (header size)
  if (offset != 170) {
    errors.emplace_back(0, "Header parsing error: offset mismatch");
    return false;
  }

  return true;
}

bool SpeParser::parse_data(const std::vector<uint8_t> &data, int32_t &npts,
                           std::vector<int32_t> &intensities,
                           std::vector<std::pair<int, std::string>> &errors) {
  // Calculate expected NPTS from file size
  // File = 170 (header) + NPTS * 4 (data) + 26 (footer)
  if (data.size() < 200) {
    errors.emplace_back(0, "File too small for data section");
    return false;
  }

  size_t data_size = data.size() - 170 - 26;
  if (data_size % 4 != 0) {
    errors.emplace_back(0, "Data section size not divisible by 4");
    return false;
  }

  npts = static_cast<int32_t>(data_size / 4);
  intensities.resize(npts);

  // Read intensities (4-byte signed integers, little-endian)
  size_t offset = 170;
  for (int32_t i = 0; i < npts; ++i) {
    std::memcpy(&intensities[i], &data[offset], 4);
    offset += 4;
  }

  return true;
}

bool SpeParser::parse_footer(const std::vector<uint8_t> &data, SpeFooter &footer,
                             std::vector<std::pair<int, std::string>> &errors) {
  // Footer is 26 bytes at the end
  if (data.size() < 26) {
    errors.emplace_back(0, "Not enough data for footer");
    return false;
  }

  size_t footer_offset = data.size() - 26;

  // Read FSTART (8 bytes, double)
  std::memcpy(&footer.fstart, &data[footer_offset], 8);
  footer_offset += 8;

  // Read FEND (8 bytes, double)
  std::memcpy(&footer.fend, &data[footer_offset], 8);
  footer_offset += 8;

  // Read FINCR (8 bytes, double)
  std::memcpy(&footer.fincr, &data[footer_offset], 8);
  footer_offset += 8;

  // Read NCALPT (2 bytes, int16)
  std::memcpy(&footer.ncalpt, &data[footer_offset], 2);
  footer_offset += 2;

  // Verify footer
  if (footer.fstart < 0 || footer.fend < 0 || footer.fincr < 0) {
    errors.emplace_back(static_cast<int>(data.size() - 26),
                        "Invalid frequency values in footer");
    // Don't fail - just warn
  }

  if (footer.fend <= footer.fstart) {
    errors.emplace_back(static_cast<int>(data.size() - 26),
                        "FEND should be greater than FSTART");
    // Don't fail - just warn
  }

  return true;
}

bool SpeParser::validate_header(const SpeHeader &header,
                                std::vector<std::pair<int, std::string>> &errors) {
  bool valid = true;

  // Validate date fields
  if (header.day < 1 || header.day > 31) {
    errors.emplace_back(72, "Invalid day: " + std::to_string(header.day));
    valid = false;
  }

  if (header.month < 1 || header.month > 12) {
    errors.emplace_back(74, "Invalid month: " + std::to_string(header.month));
    valid = false;
  }

  if (header.year < 1980 || header.year > 2100) {
    errors.emplace_back(76, "Invalid year: " + std::to_string(header.year));
    valid = false;
  }

  return valid;
}

} // namespace pickett
