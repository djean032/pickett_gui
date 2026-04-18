#ifndef LIN_PARSER_H
#define LIN_PARSER_H

#include <string>
#include <vector>
#include <istream>

namespace pickett {

struct LinRecord {
    int qn[12];          // 12 quantum numbers (3 chars each, positions 1-36)
    double freq;         // Frequency (MHz)
    double err;          // Error
    double wt;           // Weight
    
    LinRecord() : freq(0.0), err(0.0), wt(0.0) {
        for (int i = 0; i < 12; ++i) qn[i] = 0;
    }
};

class LinParser {
public:
    std::vector<LinRecord> parse(std::istream& input);
    std::vector<LinRecord> parse_file(const std::string& filepath);
};

} // namespace pickett

#endif // LIN_PARSER_H
