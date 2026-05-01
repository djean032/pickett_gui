#include "catalogdata.h"

#include "errors/service_failure.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdio>

namespace {

bool timingProbesEnabled() {
  static const bool enabled = qEnvironmentVariableIntValue(
                                  "PICKETT_TIMING_PROBES") > 0;
  return enabled;
}

class ScopedTimingProbe {
public:
  explicit ScopedTimingProbe(QString label)
      : m_label(std::move(label)), m_start(std::chrono::steady_clock::now()) {}

  ~ScopedTimingProbe() {
    if (!timingProbesEnabled()) {
      return;
    }
    const auto end = std::chrono::steady_clock::now();
    const auto elapsedMs =
        std::chrono::duration<double, std::milli>(end - m_start).count();
    std::fprintf(stderr, "[timing] %s ms=%.3f\n", m_label.toUtf8().constData(),
                 elapsedMs);
  }

private:
  QString m_label;
  std::chrono::steady_clock::time_point m_start;
};

QString firstErrorMessage(const QVector<ParserError> &errors,
                          const QString &fallback) {
  if (errors.isEmpty()) {
    return fallback;
  }
  return errors[0].message;
}

ServiceFailure
toFailure(const SpectralFileService::CatalogNativeResult &result) {
  ServiceFailure failure;
  failure.errors = result.errors;
  failure.domain = ParserDomain::Cat;
  failure.sourcePath = result.sourcePath;
  return failure;
}

} // namespace

CatalogData::CatalogData(QObject *parent) : QObject(parent) {}

void CatalogData::loadFile(const QString &filePath) {
  if (!m_fileService) {
    setErrorMessage("File service is not configured");
    return;
  }

  m_pendingFileName = filePath;
  clearError();
  clearWarning();
  setLoading(true);
  m_pendingRequestId = m_fileService->loadCatNativeAsync(filePath);
}

void CatalogData::setFileService(SpectralFileService *service) {
  if (m_fileService == service) {
    return;
  }

  if (m_fileService) {
    disconnect(m_fileService, &SpectralFileService::catNativeLoaded, this,
               &CatalogData::onCatLoaded);
  }

  m_fileService = service;

  if (m_fileService) {
    connect(m_fileService, &SpectralFileService::catNativeLoaded, this,
            &CatalogData::onCatLoaded);
  }

  emit fileServiceChanged();
}

void CatalogData::onCatLoaded(
    const SpectralFileService::CatalogNativeResult &result) {
  ScopedTimingProbe timing("CatalogData::onCatLoaded");

  if (result.requestId != m_pendingRequestId) {
    return;
  }

  setLoading(false);

  if (result.records.empty()) {
    clearWarning();
    const ServiceFailure failure = toFailure(result);
    if (hasFatalError(failure) || result.errors.isEmpty()) {
      const QString fatalMessage = firstFatalMessage(failure);
      setErrorMessage(!fatalMessage.isEmpty()
                          ? fatalMessage
                          : firstErrorMessage(result.errors,
                                              "Failed to load catalog file"));
    } else {
      clearError();
      setWarningMessage(firstWarningMessage(failure));
    }
    return;
  }

  clearError();
  const QString warning = firstWarningMessage(toFailure(result));
  if (!warning.isEmpty()) {
    setWarningMessage(warning);
  } else {
    clearWarning();
  }

  m_records = result.records;

  if (m_records.empty()) {
    return;
  }

  std::sort(m_records.begin(), m_records.end(),
            [](const pickett::CatRecord &a, const pickett::CatRecord &b) {
              return a.freq < b.freq;
            });

  m_xMin = m_records[0].freq;
  m_xMax = m_records[0].freq;
  m_yMax = 0.0;

  for (const auto &rec : m_records) {
    if (rec.freq < m_xMin)
      m_xMin = rec.freq;
    if (rec.freq > m_xMax)
      m_xMax = rec.freq;
    double intensity = std::pow(10.0, rec.lgint);
    if (intensity > m_yMax)
      m_yMax = intensity;
  }

  std::transform(m_records.begin(), m_records.end(), m_records.begin(),
                 [this](pickett::CatRecord &rec) {
                    rec.lgint = std::pow(10, rec.lgint) / m_yMax;
                    return rec;
                  });
  m_yMax = 1.0;

  m_fileName = m_pendingFileName;
  emit dataChanged();
  emit fileNameChanged();
}

void CatalogData::setLoading(bool loading) {
  if (m_isLoading == loading) {
    return;
  }
  m_isLoading = loading;
  emit loadingChanged();
}

void CatalogData::clearError() {
  if (!m_hasError && m_errorMessage.isEmpty()) {
    return;
  }
  m_hasError = false;
  m_errorMessage.clear();
  emit errorChanged();
}

void CatalogData::setErrorMessage(const QString &message) {
  const bool hasErrorNow = !message.isEmpty();
  if (m_hasError == hasErrorNow && m_errorMessage == message) {
    return;
  }
  m_hasError = hasErrorNow;
  m_errorMessage = message;
  emit errorChanged();
}

void CatalogData::clearWarning() {
  if (!m_hasWarning && m_warningMessage.isEmpty()) {
    return;
  }
  m_hasWarning = false;
  m_warningMessage.clear();
  emit warningChanged();
}

void CatalogData::setWarningMessage(const QString &message) {
  const bool hasWarningNow = !message.isEmpty();
  if (m_hasWarning == hasWarningNow && m_warningMessage == message) {
    return;
  }
  m_hasWarning = hasWarningNow;
  m_warningMessage = message;
  emit warningChanged();
}
