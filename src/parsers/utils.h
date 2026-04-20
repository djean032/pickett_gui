#ifndef PICKETT_UTILS_H
#define PICKETT_UTILS_H

#include <string>
#include <utility>

namespace pickett {

// String trimming
std::string trim(const std::string &s);

// Safe numeric parsing with error handling
std::pair<int, std::string> parse_int_safe(const std::string &s);
std::pair<double, std::string> parse_double_safe(const std::string &s);

// Scientific notation formatting for SPFIT/SPCAT compatibility
// format: uppercase E with 3-digit exponent (e.g., 1.23E+003, 1.0E-037)
std::string format_scientific_upper(double value, int precision = 15,
                                    int exponent_digits = 3);

// Scientific notation for LIN files (2-digit exponent)
// format: uppercase E with 2-digit exponent (e.g., 2.50E-05)
std::string format_scientific_lin(double value, int sig_figs = 2);

} // namespace pickett

#endif // PICKETT_UTILS_H
