#include "spe_parser.h"
#include <algorithm>
#include <cstring>
#include <fstream>
#include <limits>
#include <sstream>

namespace pickett {

namespace {
constexpr size_t SPE_HEADER_SIZE = 170;
constexpr size_t SPE_FOOTER_SIZE = 26;
constexpr size_t SPE_INTENSITY_SIZE = 4;
constexpr size_t SPE_MIN_POINTS = 1;
constexpr size_t SPE_MIN_FILE_SIZE =
    SPE_HEADER_SIZE + SPE_FOOTER_SIZE + SPE_INTENSITY_SIZE * SPE_MIN_POINTS;

constexpr size_t COMMENT_SIZE = 72;
constexpr size_t DATETIME_FIELD_SIZE = 2;
constexpr size_t LAMP_SIZE = 6;
constexpr size_t SAMPLE_SIZE = 20;
constexpr size_t SCANSP_SIZE = 6;
constexpr size_t FLOAT_FIELD_SIZE = 4;
constexpr size_t DOUBLE_FIELD_SIZE = 8;
constexpr size_t INT16_FIELD_SIZE = 2;
constexpr size_t EXTENDED_HEADER_PADDING_SIZE = 14;

constexpr int16_t MIN_VALID_DAY = 1;
constexpr int16_t MAX_VALID_DAY = 31;
constexpr int16_t MIN_VALID_MONTH = 1;
constexpr int16_t MAX_VALID_MONTH = 12;
constexpr int16_t MIN_VALID_YEAR = 1980;
constexpr int16_t MAX_VALID_YEAR = 2100;
} // namespace

SpeHeader::SpeHeader()
    : day(0), month(0), year(0), hour(0), minute(0), second(0), vkmst(0.0f),
      vkmend(0.0f), grid(0.0f), sampre(0.0f), gain(0.0f), timec(0.0f),
      phase(0.0f), pps(0.0f), frmod(0.0f), frampl(0.0f) {
  std::memset(comment, 0, sizeof(comment));
  std::memset(lamp, 0, sizeof(lamp));
  std::memset(sample, 0, sizeof(sample));
  std::memset(scansp, 0, sizeof(scansp));
}

SpeParseExpected SpeParser::parse_file(const std::string &filepath) {

  std::ifstream file(filepath, std::ios::binary);
  if (!file.is_open()) {
    return std::unexpected(
        SpeParseErrors{{0, "Failed to open file: " + filepath}});
  }

  // Read entire file
  file.seekg(0, std::ios::end);
  std::streampos end_pos = file.tellg();
  if (end_pos < 0) {
    return std::unexpected(
        SpeParseErrors{{0, "Failed to determine file size: " + filepath}});
  }
  size_t file_size = static_cast<size_t>(end_pos);
  file.seekg(0, std::ios::beg);

  std::vector<uint8_t> buffer(file_size);
  if (!file.read(reinterpret_cast<char *>(buffer.data()), file_size)) {
    return std::unexpected(
        SpeParseErrors{{0, "Failed to read file: " + filepath}});
  }
  file.close();

  return parse_buffer(buffer);
}

SpeParseExpected SpeParser::parse_buffer(const std::vector<uint8_t> &buffer) {
  SpeParseResult result;

  if (buffer.size() < SPE_MIN_FILE_SIZE) {
    return std::unexpected(
        SpeParseErrors{{0, "File too small (minimum " +
                               std::to_string(SPE_MIN_FILE_SIZE) +
                               " bytes)"}});
  }

  // Parse header
  if (!parse_header(buffer, result.header, result.errors)) {
    return std::unexpected(result.errors);
  }

  // Validate header
  if (!validate_header(result.header, result.errors)) {
    // Don't mark as failure - just warnings
  }

  // Parse data section
  if (!parse_data(buffer, result.npts, result.intensities, result.errors)) {
    return std::unexpected(result.errors);
  }

  // Parse footer
  if (!parse_footer(buffer, result.footer, result.errors)) {
    return std::unexpected(result.errors);
  }

  return result;
}

bool SpeParser::parse_header(const std::vector<uint8_t> &data,
                             SpeHeader &header,
                             std::vector<std::pair<int, std::string>> &errors) {
  if (data.size() < SPE_HEADER_SIZE) {
    errors.emplace_back(0, "Not enough data for header (need " +
                              std::to_string(SPE_HEADER_SIZE) + " bytes)");
    return false;
  }

  size_t offset = 0;

  // Comment
  std::memcpy(header.comment, &data[offset], COMMENT_SIZE);
  header.comment[COMMENT_SIZE] = '\0';
  offset += COMMENT_SIZE;

  // Date/time fields
  std::memcpy(&header.day, &data[offset], DATETIME_FIELD_SIZE);
  offset += DATETIME_FIELD_SIZE;
  std::memcpy(&header.month, &data[offset], DATETIME_FIELD_SIZE);
  offset += DATETIME_FIELD_SIZE;
  std::memcpy(&header.year, &data[offset], DATETIME_FIELD_SIZE);
  offset += DATETIME_FIELD_SIZE;
  std::memcpy(&header.hour, &data[offset], DATETIME_FIELD_SIZE);
  offset += DATETIME_FIELD_SIZE;
  std::memcpy(&header.minute, &data[offset], DATETIME_FIELD_SIZE);
  offset += DATETIME_FIELD_SIZE;
  std::memcpy(&header.second, &data[offset], DATETIME_FIELD_SIZE);
  offset += DATETIME_FIELD_SIZE;

  // Lamp
  std::memcpy(header.lamp, &data[offset], LAMP_SIZE);
  header.lamp[LAMP_SIZE] = '\0';
  offset += LAMP_SIZE;

  // Float fields (VKMST, VKMEND, GRID)
  std::memcpy(&header.vkmst, &data[offset], FLOAT_FIELD_SIZE);
  offset += FLOAT_FIELD_SIZE;
  std::memcpy(&header.vkmend, &data[offset], FLOAT_FIELD_SIZE);
  offset += FLOAT_FIELD_SIZE;
  std::memcpy(&header.grid, &data[offset], FLOAT_FIELD_SIZE);
  offset += FLOAT_FIELD_SIZE;

  // Sample
  std::memcpy(header.sample, &data[offset], SAMPLE_SIZE);
  header.sample[SAMPLE_SIZE] = '\0';
  offset += SAMPLE_SIZE;

  // Float fields (SAMPRE, GAIN, TIMEC, PHASE)
  std::memcpy(&header.sampre, &data[offset], FLOAT_FIELD_SIZE);
  offset += FLOAT_FIELD_SIZE;
  std::memcpy(&header.gain, &data[offset], FLOAT_FIELD_SIZE);
  offset += FLOAT_FIELD_SIZE;
  std::memcpy(&header.timec, &data[offset], FLOAT_FIELD_SIZE);
  offset += FLOAT_FIELD_SIZE;
  std::memcpy(&header.phase, &data[offset], FLOAT_FIELD_SIZE);
  offset += FLOAT_FIELD_SIZE;

  // SCANSP
  std::memcpy(header.scansp, &data[offset], SCANSP_SIZE);
  header.scansp[SCANSP_SIZE] = '\0';
  offset += SCANSP_SIZE;

  // Float fields (PPS, FRMOD, FRAMPL)
  std::memcpy(&header.pps, &data[offset], FLOAT_FIELD_SIZE);
  offset += FLOAT_FIELD_SIZE;
  std::memcpy(&header.frmod, &data[offset], FLOAT_FIELD_SIZE);
  offset += FLOAT_FIELD_SIZE;
  std::memcpy(&header.frampl, &data[offset], FLOAT_FIELD_SIZE);
  offset += FLOAT_FIELD_SIZE;

  // Extended format: consume extra 14 bytes (possibly ISMALL/ILARGE or padding)
  // This brings offset from 156 to 170
  offset += EXTENDED_HEADER_PADDING_SIZE;

  // Verify we consumed exactly the header size
  if (offset != SPE_HEADER_SIZE) {
    errors.emplace_back(0, "Header parsing error: offset mismatch");
    return false;
  }

  return true;
}

bool SpeParser::parse_data(const std::vector<uint8_t> &data, int32_t &npts,
                           std::vector<int32_t> &intensities,
                           std::vector<std::pair<int, std::string>> &errors) {
  // Calculate expected NPTS from file size
  // File = header + NPTS * intensity + footer
  if (data.size() < SPE_MIN_FILE_SIZE) {
    errors.emplace_back(0, "File too small for data section");
    return false;
  }

  size_t data_size = data.size() - SPE_HEADER_SIZE - SPE_FOOTER_SIZE;
  if (data_size % SPE_INTENSITY_SIZE != 0) {
    errors.emplace_back(0, "Data section size not divisible by 4");
    return false;
  }

  size_t point_count = data_size / SPE_INTENSITY_SIZE;
  if (point_count > static_cast<size_t>(std::numeric_limits<int32_t>::max())) {
    errors.emplace_back(0, "Data section has too many points");
    return false;
  }

  npts = static_cast<int32_t>(point_count);
  intensities.resize(npts);

  // Read intensities (signed integers, little-endian)
  size_t offset = SPE_HEADER_SIZE;
  for (int32_t i = 0; i < npts; ++i) {
    std::memcpy(&intensities[i], &data[offset], SPE_INTENSITY_SIZE);
    offset += SPE_INTENSITY_SIZE;
  }

  return true;
}

bool SpeParser::parse_footer(const std::vector<uint8_t> &data,
                             SpeFooter &footer,
                             std::vector<std::pair<int, std::string>> &errors) {
  // Footer is fixed-size at the end
  if (data.size() < SPE_FOOTER_SIZE) {
    errors.emplace_back(0, "Not enough data for footer");
    return false;
  }

  size_t footer_offset = data.size() - SPE_FOOTER_SIZE;

  // Read FSTART
  std::memcpy(&footer.fstart, &data[footer_offset], DOUBLE_FIELD_SIZE);
  footer_offset += DOUBLE_FIELD_SIZE;

  // Read FEND
  std::memcpy(&footer.fend, &data[footer_offset], DOUBLE_FIELD_SIZE);
  footer_offset += DOUBLE_FIELD_SIZE;

  // Read FINCR
  std::memcpy(&footer.fincr, &data[footer_offset], DOUBLE_FIELD_SIZE);
  footer_offset += DOUBLE_FIELD_SIZE;

  // Read NCALPT
  std::memcpy(&footer.ncalpt, &data[footer_offset], INT16_FIELD_SIZE);
  footer_offset += INT16_FIELD_SIZE;

  // Verify footer
  if (footer.fstart < 0 || footer.fend < 0 || footer.fincr < 0) {
    errors.emplace_back(static_cast<int>(data.size() - SPE_FOOTER_SIZE),
                        "Invalid frequency values in footer");
    // Don't fail - just warn
  }

  if (footer.fend <= footer.fstart) {
    errors.emplace_back(static_cast<int>(data.size() - SPE_FOOTER_SIZE),
                        "FEND should be greater than FSTART");
    // Don't fail - just warn
  }

  return true;
}

bool SpeParser::validate_header(
    const SpeHeader &header, std::vector<std::pair<int, std::string>> &errors) {
  bool valid = true;

  // Validate date fields
  if (header.day < MIN_VALID_DAY || header.day > MAX_VALID_DAY) {
    errors.emplace_back(72, "Invalid day: " + std::to_string(header.day));
    valid = false;
  }

  if (header.month < MIN_VALID_MONTH || header.month > MAX_VALID_MONTH) {
    errors.emplace_back(74, "Invalid month: " + std::to_string(header.month));
    valid = false;
  }

  if (header.year < MIN_VALID_YEAR || header.year > MAX_VALID_YEAR) {
    errors.emplace_back(76, "Invalid year: " + std::to_string(header.year));
    valid = false;
  }

  return valid;
}

} // namespace pickett
