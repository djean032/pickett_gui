#include "spectrumdata.h"

#include "errors/service_failure.h"
#include "simd_stats.h"

#include <algorithm>

namespace {

QString firstErrorMessage(const QVector<ParserError> &errors,
                         const QString &fallback) {
  if (errors.isEmpty()) {
    return fallback;
  }
  return errors[0].message;
}

ServiceFailure toFailure(const SpectralFileService::SpectrumResult &result) {
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
  m_pendingRequestId = m_fileService->loadSpeAsync(filePath);
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
    disconnect(m_fileService, &SpectralFileService::speLoaded, this,
               &SpectrumData::onSpeLoaded);
  }

  m_fileService = service;

  if (m_fileService) {
    connect(m_fileService, &SpectralFileService::speLoaded, this,
            &SpectrumData::onSpeLoaded);
  }

  emit fileServiceChanged();
}

void SpectrumData::onSpeLoaded(
    const SpectralFileService::SpectrumResult &result) {
  if (result.requestId != m_pendingRequestId) {
    return;
  }

  setLoading(false);

  if (result.points.isEmpty()) {
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
  freqs.reserve(static_cast<size_t>(result.points.size()));
  intensities.reserve(static_cast<size_t>(result.points.size()));

  for (const auto &point : result.points) {
    freqs.push_back(point.frequencyMHz);
    intensities.push_back(point.intensity);
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
