#ifndef FIT_PARSER_H
#define FIT_PARSER_H

#include <expected>
#include <optional>
#include <string>
#include <utility>
#include <vector>

namespace pickett {

struct FitHeader {
  std::string title;
  int lines_requested;
  int num_parameters;
  int num_iterations;
  double marquardt_param;
  double max_obs_calc_error;

  FitHeader()
      : lines_requested(0), num_parameters(0), num_iterations(0),
        marquardt_param(0.0), max_obs_calc_error(0.0) {}
};

struct FitParameter {
  int index;
  int copy;
  int idpar;
  double value;
  double error;
  std::string label;

  FitParameter() : index(0), copy(0), idpar(0), value(0.0), error(0.0) {}
};

struct FitLineRecord {
  int seq_number;
  int qn[12]; // 12 quantum numbers (36 chars / 3 = 12 from qnfmt2)
  double exp_freq;
  double calc_freq;
  double diff;
  double exp_err;
  double est_err;
  std::optional<double> avg_calc_freq;
  std::optional<double> avg_diff;
  std::optional<double> wt;
  bool is_blend;
  int blend_master_line;
  bool rejected; // True if line was rejected from fit (marked with ***** NEXT
                 // LINE NOT USED IN FIT)

  FitLineRecord()
      : seq_number(0), exp_freq(0.0), calc_freq(0.0), diff(0.0), exp_err(0.0),
        est_err(0.0), is_blend(false), blend_master_line(-1), rejected(false) {
    for (int i = 0; i < 12; ++i)
      qn[i] = 0;
  }
};

struct FitCorrelationEntry {
  int row;
  int col;
  double value;

  FitCorrelationEntry() : row(0), col(0), value(0.0) {}
};

struct FitParseResult {
  FitHeader header;
  std::vector<FitParameter> parameters;
  std::vector<FitParameter> updated_parameters;
  std::vector<FitLineRecord> lines;
  std::vector<FitCorrelationEntry> correlations;
  std::vector<std::pair<int, std::string>> errors;
  int rejected_line_count; // Count of rejected lines/blends (SPFIT counts
                           // blends as 1)

  FitParseResult() : rejected_line_count(0) {}
};

using FitParseErrors = std::vector<std::pair<int, std::string>>;
using FitParseExpected = std::expected<FitParseResult, FitParseErrors>;

class FitParser {
public:
  static FitParseExpected parse_file(const std::string &filepath);

private:
  static bool
  parse_header_line(const std::string &line, FitHeader &header, int line_num,
                    std::vector<std::pair<int, std::string>> &errors);
  static bool parse_parameter_line(const std::string &line, FitParameter &param,
                                   std::string &error);
  static bool parse_line_record(const std::string &line, FitLineRecord &record,
                                double prev_exp_freq, int prev_blend_master,
                                std::string &error);
  static bool parse_correlation_line(const std::string &line,
                                     std::vector<FitCorrelationEntry> &entries,
                                     std::string &error);
  static bool parse_updated_parameter_line(const std::string &line,
                                           FitParameter &param,
                                           std::string &error);
};

} // namespace pickett

#endif // FIT_PARSER_H
