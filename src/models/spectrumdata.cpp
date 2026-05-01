#include "spectrumdata.h"

#include "errors/service_failure.h"
#include "simd_stats.h"

#include <algorithm>
#include <chrono>
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
toFailure(const SpectralFileService::SpectrumNativeResult &result) {
  ServiceFailure failure;
  failure.errors = result.errors;
  failure.domain = ParserDomain::Spe;
  failure.sourcePath = result.sourcePath;
  return failure;
}

} // namespace

SpectrumData::SpectrumData(QObject *parent) : QObject(parent) {}

void SpectrumData::loadFile(const QString &filePath) {
  if (!m_fileService) {
    setErrorMessage("File service is not configured");
    return;
  }

  m_pendingFileName = filePath;
  clearError();
  clearWarning();
  setLoading(true);
  m_pendingRequestId = m_fileService->loadSpeNativeAsync(filePath);
}

SpectralFileService *SpectrumData::fileService() const { return m_fileService; }
bool SpectrumData::isLoading() const { return m_isLoading; }
bool SpectrumData::hasError() const { return m_hasError; }
QString SpectrumData::errorMessage() const { return m_errorMessage; }
bool SpectrumData::hasWarning() const { return m_hasWarning; }
QString SpectrumData::warningMessage() const { return m_warningMessage; }

void SpectrumData::setFileService(SpectralFileService *service) {
  if (m_fileService == service) {
    return;
  }

  if (m_fileService) {
    disconnect(m_fileService, &SpectralFileService::speNativeLoaded, this,
               &SpectrumData::onSpeLoaded);
  }

  m_fileService = service;

  if (m_fileService) {
    connect(m_fileService, &SpectralFileService::speNativeLoaded, this,
            &SpectrumData::onSpeLoaded);
  }

  emit fileServiceChanged();
}

void SpectrumData::onSpeLoaded(
    const SpectralFileService::SpectrumNativeResult &result) {
  ScopedTimingProbe timing("SpectrumData::onSpeLoaded");

  if (result.requestId != m_pendingRequestId) {
    return;
  }

  setLoading(false);

  if (result.intensities.empty()) {
    clearWarning();
    const ServiceFailure failure = toFailure(result);
    if (hasFatalError(failure) || result.errors.isEmpty()) {
      const QString fatalMessage = firstFatalMessage(failure);
      setErrorMessage(!fatalMessage.isEmpty()
                          ? fatalMessage
                          : firstErrorMessage(result.errors,
                                              "Failed to load spectrum file"));
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

  std::vector<double> freqs;
  std::vector<double> intensities;
  freqs.reserve(result.intensities.size());
  intensities.reserve(result.intensities.size());

  for (size_t i = 0; i < result.intensities.size(); ++i) {
    freqs.push_back(result.fStartMHz +
                    static_cast<double>(i) * result.fIncrMHz);
    intensities.push_back(static_cast<double>(result.intensities[i]));
  }

  decimate(freqs, intensities);

  if (m_xData.empty() || m_yData.empty()) {
    return;
  }

  m_xMin = *std::min_element(m_xData.begin(), m_xData.end());
  m_xMax = *std::max_element(m_xData.begin(), m_xData.end());
  const auto yMinMax = simdstats::findMinMax(m_yData.data(), m_yData.size());
  m_yMin = yMinMax.min;
  m_yMax = yMinMax.max;

  m_fileName = m_pendingFileName;
  emit dataChanged();
  emit fileNameChanged();
}

void SpectrumData::clearData() {
  m_xData.clear();
  m_yData.clear();
  m_xMin = 0.0;
  m_xMax = 0.0;
  m_yMin = 0.0;
  m_yMax = 0.0;
  m_fileName.clear();
  clearError();
  clearWarning();
  emit dataChanged();
  emit fileNameChanged();
}

bool SpectrumData::hasData() const { return !m_xData.empty(); }

void SpectrumData::setLoading(bool loading) {
  if (m_isLoading == loading) {
    return;
  }
  m_isLoading = loading;
  emit loadingChanged();
}

void SpectrumData::clearError() {
  if (!m_hasError && m_errorMessage.isEmpty()) {
    return;
  }
  m_hasError = false;
  m_errorMessage.clear();
  emit errorChanged();
}

void SpectrumData::setErrorMessage(const QString &message) {
  const bool hasErrorNow = !message.isEmpty();
  if (m_hasError == hasErrorNow && m_errorMessage == message) {
    return;
  }
  m_hasError = hasErrorNow;
  m_errorMessage = message;
  emit errorChanged();
}

void SpectrumData::clearWarning() {
  if (!m_hasWarning && m_warningMessage.isEmpty()) {
    return;
  }
  m_hasWarning = false;
  m_warningMessage.clear();
  emit warningChanged();
}

void SpectrumData::setWarningMessage(const QString &message) {
  const bool hasWarningNow = !message.isEmpty();
  if (m_hasWarning == hasWarningNow && m_warningMessage == message) {
    return;
  }
  m_hasWarning = hasWarningNow;
  m_warningMessage = message;
  emit warningChanged();
}

void SpectrumData::decimate(const std::vector<double> &freqs,
                            const std::vector<double> &intensities) {
  const size_t target_buckets = 100000;

  if (freqs.size() > target_buckets * 2) {
    size_t bucket_size = freqs.size() / target_buckets;
    if (bucket_size < 2)
      bucket_size = 2;

    m_xData.clear();
    m_yData.clear();
    m_xData.reserve(target_buckets * 2);
    m_yData.reserve(target_buckets * 2);

    for (size_t i = 0; i < freqs.size(); i += bucket_size) {
      size_t end = std::min(i + bucket_size, freqs.size());

      const auto bucketMinMax =
          simdstats::findMinMaxIndex(intensities.data() + i, end - i);
      const size_t min_idx = i + bucketMinMax.minIndex;
      const size_t max_idx = i + bucketMinMax.maxIndex;

      if (min_idx < max_idx) {
        m_xData.push_back(freqs[min_idx]);
        m_yData.push_back(intensities[min_idx]);
        m_xData.push_back(freqs[max_idx]);
        m_yData.push_back(intensities[max_idx]);
      } else if (max_idx < min_idx) {
        m_xData.push_back(freqs[max_idx]);
        m_yData.push_back(intensities[max_idx]);
        m_xData.push_back(freqs[min_idx]);
        m_yData.push_back(intensities[min_idx]);
      } else {
        m_xData.push_back(freqs[min_idx]);
        m_yData.push_back(intensities[min_idx]);
      }
    }
  } else {
    m_xData = freqs;
    m_yData = intensities;
  }
}

const std::vector<double> &SpectrumData::xData() const { return m_xData; }
const std::vector<double> &SpectrumData::yData() const { return m_yData; }
double SpectrumData::xMin() const { return m_xMin; }
double SpectrumData::xMax() const { return m_xMax; }
double SpectrumData::yMin() const { return m_yMin; }
double SpectrumData::yMax() const { return m_yMax; }
QString SpectrumData::fileName() const { return m_fileName; }
