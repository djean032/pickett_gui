#ifndef SERVICE_FAILURE_H
#define SERVICE_FAILURE_H

#include "parser_error.h"

#include <expected>

#include <QString>
#include <QVector>

struct ServiceFailure {
  QVector<ParserError> errors;
  ParserDomain domain = ParserDomain::Common;
  QString sourcePath;
};

inline bool hasFatalError(const ServiceFailure &failure) {
  for (const auto &error : failure.errors) {
    if (error.isFatal) {
      return true;
    }
  }
  return false;
}

inline QString firstFatalMessage(const ServiceFailure &failure) {
  for (const auto &error : failure.errors) {
    if (error.isFatal) {
      return error.message;
    }
  }
  return QString();
}

inline QString firstWarningMessage(const ServiceFailure &failure) {
  for (const auto &error : failure.errors) {
    if (!error.isFatal) {
      return error.message;
    }
  }
  return QString();
}

template <typename T>
using ServiceExpected = std::expected<T, ServiceFailure>;

#endif // SERVICE_FAILURE_H
