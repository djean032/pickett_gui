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

void appendParserErrors(const std::vector<std::pair<int, std::string>> &source,
                        QVector<ServiceError> &target,
                        Domain domain, const QString &sourcePath) {
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
        makeError(code, message, domain, field, sourcePath, entry.first, true));
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

SpectralFileService::SpectrumResult
SpectralFileService::loadSpe(const QString &filePath) const {
  SpectrumResult result;
  result.sourcePath = normalizePath(filePath);

  if (!validateReadablePath(result.sourcePath, result.errors)) {
    return result;
  }

  const auto parsed =
      pickett::SpeParser::parse_file(result.sourcePath.toStdString());
  appendParserErrors(parsed.errors, result.errors, Domain::Spe,
                     result.sourcePath);

  if (!parsed.success || parsed.npts <= 0 || parsed.intensities.empty()) {
    if (result.errors.isEmpty()) {
      result.errors.push_back(
          makeError(ErrorCode::EmptyData, "No spectral data points found",
                    Domain::Spe, "spe", result.sourcePath, 0, true));
    }
    return result;
  }

  result.points.reserve(parsed.npts);
  for (int i = 0; i < parsed.npts; ++i) {
    SpectrumPoint point;
    point.frequencyMHz = parsed.footer.fstart + i * parsed.footer.fincr;
    point.intensity = static_cast<double>(parsed.intensities[i]);
    result.points.push_back(point);
  }

  result.fStartMHz = parsed.footer.fstart;
  result.fEndMHz = parsed.footer.fend;
  result.fIncrMHz = parsed.footer.fincr;
  result.success = true;
  return result;
}

SpectralFileService::CatalogResult
SpectralFileService::loadCat(const QString &filePath) const {
  CatalogResult result;
  result.sourcePath = normalizePath(filePath);

  if (!validateReadablePath(result.sourcePath, result.errors)) {
    return result;
  }

  const auto parsed =
      pickett::CatParser::parse_file(result.sourcePath.toStdString());
  appendParserErrors(parsed.errors, result.errors, Domain::Cat,
                     result.sourcePath);

  if (!parsed.success || parsed.records.empty()) {
    if (result.errors.isEmpty()) {
      result.errors.push_back(
          makeError(ErrorCode::EmptyData, "No catalog lines found", Domain::Cat,
                    "cat", result.sourcePath, 0, true));
    }
    return result;
  }

  result.lines.reserve(static_cast<int>(parsed.records.size()));
  for (const auto &record : parsed.records) {
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

  result.success = true;
  return result;
}

SpectralFileService::LinResult
SpectralFileService::loadLin(const QString &filePath) const {
  LinResult result;
  result.sourcePath = normalizePath(filePath);

  if (!validateReadablePath(result.sourcePath, result.errors)) {
    return result;
  }

  const auto parsed =
      pickett::LinParser::parse_file(result.sourcePath.toStdString());
  appendParserErrors(parsed.errors, result.errors, Domain::Lin,
                     result.sourcePath);

  if (!parsed.success || parsed.records.empty()) {
    if (result.errors.isEmpty()) {
      result.errors.push_back(
          makeError(ErrorCode::EmptyData, "No LIN entries found", Domain::Lin,
                    "lin", result.sourcePath, 0, true));
    }
    return result;
  }

  result.lines.reserve(static_cast<int>(parsed.records.size()));
  for (const auto &record : parsed.records) {
    LinLine line;
    line.qn = toQnVector(record.qn);
    line.freq = record.freq;
    line.err = record.err;
    line.wt = record.wt;
    result.lines.push_back(line);
  }

  result.success = true;
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
    return loadSpe(filePath);
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
    return loadCat(filePath);
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
    return loadLin(filePath);
  }));

  return requestId;
}

quint64 SpectralFileService::nextRequestId() {
  static std::atomic<quint64> nextId{1};
  return nextId.fetch_add(1, std::memory_order_relaxed);
}
