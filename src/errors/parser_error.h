#ifndef PARSER_ERROR_H
#define PARSER_ERROR_H

#include <QMetaType>
#include <QString>

enum class ParserErrorCode {
  InvalidPath,
  FileNotFound,
  FileOpenFailed,
  FileReadFailed,
  InvalidHeader,
  InvalidFooter,
  InvalidRecord,
  InvalidQuantumNumber,
  InconsistentFormat,
  InvalidFormat,
  EmptyData,
  ParseFailed,
  UnsupportedFormat,
  InternalError
};

enum class ParserDomain {
  Spe,
  Cat,
  Lin,
  Common
};

struct ParserError {
  ParserErrorCode code = ParserErrorCode::InternalError;
  ParserDomain domain = ParserDomain::Common;
  QString message;
  int line = 0;
  QString field;
  QString sourcePath;
  bool isFatal = true;
};

Q_DECLARE_METATYPE(ParserErrorCode)
Q_DECLARE_METATYPE(ParserDomain)
Q_DECLARE_METATYPE(ParserError)

#endif // PARSER_ERROR_H
