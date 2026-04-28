#include "spectralfileservice.h"

#include "parsers/cat_parser.h"
#include "parsers/lin_parser.h"
#include "parsers/spe_parser.h"

#include <QFileInfo>
#include <QFutureWatcher>
#include <QMetaType>
#include <QUrl>
#include <QtConcurrent/QtConcurrentRun>

#include <atomic>

namespace {

using ErrorCode = ParserErrorCode;
using Domain = ParserDomain;
using ServiceError = ParserError;

ServiceError makeError(ErrorCode code, const QString &message,
                       Domain domain, const QString &field,
                       const QString &sourcePath, int line, bool isFatal) {
  ServiceError error;
  error.code = code;
  error.domain = domain;
  error.message = message;
  error.field = field;
  error.sourcePath = sourcePath;
  error.line = line;
  error.isFatal = isFatal;
  return error;
}

QString normalizePath(const QString &inputPath) {
  QUrl url(inputPath);
  if (url.isLocalFile()) {
    return url.toLocalFile();
  }
  return inputPath;
}

bool validateReadablePath(const QString &path, QVector<ServiceError> &errors) {
  if (path.trimmed().isEmpty()) {
    errors.push_back(makeError(ErrorCode::InvalidPath, "Path is empty",
                               Domain::Common, "path", path, 0, true));
    return false;
  }

  QFileInfo fileInfo(path);
  if (!fileInfo.exists()) {
    errors.push_back(makeError(ErrorCode::FileNotFound,
                               "File does not exist: " + path,
                               Domain::Common, "path", path, 0, true));
    return false;
  }

  if (!fileInfo.isFile()) {
    errors.push_back(makeError(ErrorCode::InvalidPath,
                               "Path is not a file: " + path,
                               Domain::Common, "path", path, 0, true));
    return false;
  }

  if (!fileInfo.isReadable()) {
    errors.push_back(makeError(ErrorCode::FileOpenFailed,
                               "File is not readable: " + path,
                               Domain::Common, "path", path, 0, true));
    return false;
  }

  return true;
}

ErrorCode mapCommonError(const QString &lowered) {
  if (lowered.contains("failed to open file")) {
    return ErrorCode::FileOpenFailed;
  }
  if (lowered.contains("failed to read file")) {
    return ErrorCode::FileReadFailed;
  }
  if (lowered.contains("file too small")) {
    return ErrorCode::InvalidFormat;
  }
  if (lowered.contains("empty")) {
    return ErrorCode::EmptyData;
  }
  return ErrorCode::ParseFailed;
}

ErrorCode mapSpeError(const QString &message) {
  const QString lowered = message.toLower();
  if (lowered.contains("header")) {
    return ErrorCode::InvalidHeader;
  }
  if (lowered.contains("footer") || lowered.contains("fend") ||
      lowered.contains("fstart") || lowered.contains("frequency")) {
    return ErrorCode::InvalidFooter;
  }
  if (lowered.contains("data section") || lowered.contains("npts")) {
    return ErrorCode::InvalidRecord;
  }
  if (lowered.contains("invalid") || lowered.contains("malformed")) {
    return ErrorCode::InvalidFormat;
  }
  const ErrorCode common = mapCommonError(lowered);
  if (common != ErrorCode::ParseFailed) {
    return common;
  }
  return ErrorCode::ParseFailed;
}

ErrorCode mapCatError(const QString &message) {
  const QString lowered = message.toLower();
  if (lowered.contains("unknown qfmt")) {
    return ErrorCode::UnsupportedFormat;
  }
  if (lowered.contains("inconsistent qfmt")) {
    return ErrorCode::InconsistentFormat;
  }
  if (lowered.contains("qn[") || lowered.contains("malformed qn") ||
      lowered.contains("qn field")) {
    return ErrorCode::InvalidQuantumNumber;
  }
  if (lowered.contains("line too short") || lowered.contains("freq:") ||
      lowered.contains("err:") || lowered.contains("lgint:") ||
      lowered.contains("dr:") || lowered.contains("elo:") ||
      lowered.contains("gup:") || lowered.contains("tag:")) {
    return ErrorCode::InvalidRecord;
  }
  if (lowered.contains("invalid") || lowered.contains("malformed")) {
    return ErrorCode::InvalidFormat;
  }
  const ErrorCode common = mapCommonError(lowered);
  if (common != ErrorCode::ParseFailed) {
    return common;
  }
  return ErrorCode::ParseFailed;
}

ErrorCode mapLinError(const QString &message) {
  const QString lowered = message.toLower();
  if (lowered.contains("qn[") || lowered.contains("quantum")) {
    return ErrorCode::InvalidQuantumNumber;
  }
  if (lowered.contains("line too short") || lowered.contains("freq:") ||
      lowered.contains("err:") || lowered.contains("wt:")) {
    return ErrorCode::InvalidRecord;
  }
  if (lowered.contains("invalid") || lowered.contains("malformed")) {
    return ErrorCode::InvalidFormat;
  }
  const ErrorCode common = mapCommonError(lowered);
  if (common != ErrorCode::ParseFailed) {
    return common;
  }
  return ErrorCode::ParseFailed;
}

bool isFatalErrorCode(ErrorCode code, Domain domain, bool parserSuccess) {
  if (!parserSuccess) {
    return true;
  }

  if (domain == Domain::Spe) {
    if (code == ErrorCode::InvalidHeader || code == ErrorCode::InvalidFooter ||
        code == ErrorCode::ParseFailed) {
      return false;
    }
  }

  if (domain == Domain::Cat || domain == Domain::Lin) {
    if (code == ErrorCode::InvalidRecord ||
        code == ErrorCode::InvalidQuantumNumber ||
        code == ErrorCode::InconsistentFormat ||
        code == ErrorCode::ParseFailed) {
      return false;
    }
  }

  return false;
}

void appendParserErrors(const std::vector<std::pair<int, std::string>> &source,
                        QVector<ServiceError> &target, Domain domain,
                        const QString &sourcePath, bool parserSuccess) {
  for (const auto &entry : source) {
    const QString message = QString::fromStdString(entry.second);
    ErrorCode code = ErrorCode::ParseFailed;
    QString field = "parser";
    if (domain == Domain::Spe) {
      code = mapSpeError(message);
      field = "spe";
    } else if (domain == Domain::Cat) {
      code = mapCatError(message);
      field = "cat";
    } else if (domain == Domain::Lin) {
      code = mapLinError(message);
      field = "lin";
    }
    target.push_back(
        makeError(code, message, domain, field, sourcePath, entry.first,
                  isFatalErrorCode(code, domain, parserSuccess)));
  }
}

QVector<int> toQnVector(const int qn[12]) {
  QVector<int> values;
  values.reserve(12);
  for (int i = 0; i < 12; ++i) {
    values.push_back(qn[i]);
  }
  return values;
}

} // namespace

SpectralFileService::SpectralFileService(QObject *parent) : QObject(parent) {
  qRegisterMetaType<ParserError>("ParserError");
  qRegisterMetaType<SpectralFileService::SpectrumPoint>(
      "SpectralFileService::SpectrumPoint");
  qRegisterMetaType<SpectralFileService::SpectrumResult>(
      "SpectralFileService::SpectrumResult");
  qRegisterMetaType<SpectralFileService::CatalogLine>(
      "SpectralFileService::CatalogLine");
  qRegisterMetaType<SpectralFileService::CatalogResult>(
      "SpectralFileService::CatalogResult");
  qRegisterMetaType<SpectralFileService::LinLine>(
      "SpectralFileService::LinLine");
  qRegisterMetaType<SpectralFileService::LinResult>(
      "SpectralFileService::LinResult");
}

namespace {

ServiceFailure toFailure(const QVector<ServiceError> &errors, Domain domain,
                         const QString &sourcePath) {
  ServiceFailure failure;
  failure.errors = errors;
  failure.domain = domain;
  failure.sourcePath = sourcePath;
  return failure;
}

SpectralFileService::SpectrumResult
toLegacySpectrumResult(const SpectralFileService::SpectrumLoadExpected &expected) {
  SpectralFileService::SpectrumResult result;
  if (expected.has_value()) {
    result = expected.value();
    return result;
  }

  const ServiceFailure &failure = expected.error();
  result.sourcePath = failure.sourcePath;
  result.errors = failure.errors;
  return result;
}

SpectralFileService::CatalogResult
toLegacyCatalogResult(const SpectralFileService::CatalogLoadExpected &expected) {
  SpectralFileService::CatalogResult result;
  if (expected.has_value()) {
    result = expected.value();
    return result;
  }

  const ServiceFailure &failure = expected.error();
  result.sourcePath = failure.sourcePath;
  result.errors = failure.errors;
  return result;
}

SpectralFileService::LinResult
toLegacyLinResult(const SpectralFileService::LinLoadExpected &expected) {
  SpectralFileService::LinResult result;
  if (expected.has_value()) {
    result = expected.value();
    return result;
  }

  const ServiceFailure &failure = expected.error();
  result.sourcePath = failure.sourcePath;
  result.errors = failure.errors;
  return result;
}

} // namespace

SpectralFileService::SpectrumLoadExpected
SpectralFileService::loadSpe(const QString &filePath) const {
  SpectrumResult result;
  result.sourcePath = normalizePath(filePath);

  if (!validateReadablePath(result.sourcePath, result.errors)) {
    return std::unexpected(toFailure(result.errors, Domain::Common,
                                     result.sourcePath));
  }

  const auto parsed =
      pickett::SpeParser::parse_file(result.sourcePath.toStdString());
  if (!parsed.has_value()) {
    appendParserErrors(parsed.error(), result.errors, Domain::Spe,
                       result.sourcePath, false);
    if (result.errors.isEmpty()) {
      result.errors.push_back(
          makeError(ErrorCode::ParseFailed, "SPE parsing failed", Domain::Spe,
                    "spe", result.sourcePath, 0, true));
    }
    return std::unexpected(toFailure(result.errors, Domain::Spe,
                                     result.sourcePath));
  }

  const auto &parsedValue = parsed.value();
  appendParserErrors(parsedValue.errors, result.errors, Domain::Spe,
                     result.sourcePath, true);

  if (parsedValue.npts <= 0 || parsedValue.intensities.empty()) {
    if (result.errors.isEmpty()) {
      result.errors.push_back(
          makeError(ErrorCode::EmptyData, "No spectral data points found",
                    Domain::Spe, "spe", result.sourcePath, 0, true));
    }
    return std::unexpected(toFailure(result.errors, Domain::Spe,
                                     result.sourcePath));
  }

  result.points.reserve(parsedValue.npts);
  for (int i = 0; i < parsedValue.npts; ++i) {
    SpectrumPoint point;
    point.frequencyMHz = parsedValue.footer.fstart + i * parsedValue.footer.fincr;
    point.intensity = static_cast<double>(parsedValue.intensities[i]);
    result.points.push_back(point);
  }

  result.fStartMHz = parsedValue.footer.fstart;
  result.fEndMHz = parsedValue.footer.fend;
  result.fIncrMHz = parsedValue.footer.fincr;
  return result;
}

SpectralFileService::CatalogLoadExpected
SpectralFileService::loadCat(const QString &filePath) const {
  CatalogResult result;
  result.sourcePath = normalizePath(filePath);

  if (!validateReadablePath(result.sourcePath, result.errors)) {
    return std::unexpected(toFailure(result.errors, Domain::Common,
                                     result.sourcePath));
  }

  const auto parsed =
      pickett::CatParser::parse_file(result.sourcePath.toStdString());
  if (!parsed.has_value()) {
    appendParserErrors(parsed.error(), result.errors, Domain::Cat,
                       result.sourcePath, false);
    if (result.errors.isEmpty()) {
      result.errors.push_back(makeError(ErrorCode::ParseFailed,
                                        "CAT parsing failed", Domain::Cat,
                                        "cat", result.sourcePath, 0, true));
    }
    return std::unexpected(toFailure(result.errors, Domain::Cat,
                                     result.sourcePath));
  }

  const auto &parsedValue = parsed.value();
  appendParserErrors(parsedValue.errors, result.errors, Domain::Cat,
                     result.sourcePath, true);

  if (parsedValue.records.empty()) {
    if (result.errors.isEmpty()) {
      result.errors.push_back(
          makeError(ErrorCode::EmptyData, "No catalog lines found", Domain::Cat,
                    "cat", result.sourcePath, 0, true));
    }
    return std::unexpected(toFailure(result.errors, Domain::Cat,
                                     result.sourcePath));
  }

  result.lines.reserve(static_cast<int>(parsedValue.records.size()));
  for (const auto &record : parsedValue.records) {
    CatalogLine line;
    line.freq = record.freq;
    line.err = record.err;
    line.lgint = record.lgint;
    line.elo = record.elo;
    line.dr = record.dr;
    line.gup = record.gup;
    line.tag = record.tag;
    line.qnfmt = record.qnfmt;
    line.qn = toQnVector(record.qn);
    result.lines.push_back(line);
  }

  return result;
}

SpectralFileService::LinLoadExpected
SpectralFileService::loadLin(const QString &filePath) const {
  LinResult result;
  result.sourcePath = normalizePath(filePath);

  if (!validateReadablePath(result.sourcePath, result.errors)) {
    return std::unexpected(toFailure(result.errors, Domain::Common,
                                     result.sourcePath));
  }

  const auto parsed =
      pickett::LinParser::parse_file(result.sourcePath.toStdString());
  if (!parsed.has_value()) {
    appendParserErrors(parsed.error(), result.errors, Domain::Lin,
                       result.sourcePath, false);
    if (result.errors.isEmpty()) {
      result.errors.push_back(makeError(ErrorCode::ParseFailed,
                                        "LIN parsing failed", Domain::Lin,
                                        "lin", result.sourcePath, 0, true));
    }
    return std::unexpected(toFailure(result.errors, Domain::Lin,
                                     result.sourcePath));
  }

  const auto &parsedValue = parsed.value();
  appendParserErrors(parsedValue.errors, result.errors, Domain::Lin,
                     result.sourcePath, true);

  if (parsedValue.records.empty()) {
    if (result.errors.isEmpty()) {
      result.errors.push_back(
          makeError(ErrorCode::EmptyData, "No LIN entries found", Domain::Lin,
                    "lin", result.sourcePath, 0, true));
    }
    return std::unexpected(toFailure(result.errors, Domain::Lin,
                                     result.sourcePath));
  }

  result.lines.reserve(static_cast<int>(parsedValue.records.size()));
  for (const auto &record : parsedValue.records) {
    LinLine line;
    line.qn = toQnVector(record.qn);
    line.freq = record.freq;
    line.err = record.err;
    line.wt = record.wt;
    result.lines.push_back(line);
  }

  return result;
}

quint64 SpectralFileService::loadSpeAsync(const QString &filePath) {
  const quint64 requestId = nextRequestId();

  auto *watcher = new QFutureWatcher<SpectrumResult>(this);
  connect(watcher, &QFutureWatcher<SpectrumResult>::finished, this,
          [this, watcher, requestId]() {
            SpectrumResult result = watcher->result();
            result.requestId = requestId;
            emit speLoaded(result);
            watcher->deleteLater();
          });

  watcher->setFuture(QtConcurrent::run([this, filePath]() {
    return toLegacySpectrumResult(loadSpe(filePath));
  }));

  return requestId;
}

quint64 SpectralFileService::loadCatAsync(const QString &filePath) {
  const quint64 requestId = nextRequestId();

  auto *watcher = new QFutureWatcher<CatalogResult>(this);
  connect(watcher, &QFutureWatcher<CatalogResult>::finished, this,
          [this, watcher, requestId]() {
            CatalogResult result = watcher->result();
            result.requestId = requestId;
            emit catLoaded(result);
            watcher->deleteLater();
          });

  watcher->setFuture(QtConcurrent::run([this, filePath]() {
    return toLegacyCatalogResult(loadCat(filePath));
  }));

  return requestId;
}

quint64 SpectralFileService::loadLinAsync(const QString &filePath) {
  const quint64 requestId = nextRequestId();

  auto *watcher = new QFutureWatcher<LinResult>(this);
  connect(watcher, &QFutureWatcher<LinResult>::finished, this,
          [this, watcher, requestId]() {
            LinResult result = watcher->result();
            result.requestId = requestId;
            emit linLoaded(result);
            watcher->deleteLater();
          });

  watcher->setFuture(QtConcurrent::run([this, filePath]() {
    return toLegacyLinResult(loadLin(filePath));
  }));

  return requestId;
}

quint64 SpectralFileService::nextRequestId() {
  static std::atomic<quint64> nextId{1};
  return nextId.fetch_add(1, std::memory_order_relaxed);
}
