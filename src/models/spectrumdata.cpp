#include "spectrumdata.h"
#include <algorithm>

SpectrumData::SpectrumData(QObject *parent) : QObject(parent) {}

void SpectrumData::loadFile(const QString &filePath) {
  if (!m_fileService) {
    return;
  }

  m_pendingFileName = filePath;
  m_pendingRequestId = m_fileService->loadSpeAsync(filePath);
}

SpectralFileService *SpectrumData::fileService() const { return m_fileService; }

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

  if (!result.success || result.points.isEmpty()) {
    return;
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
  m_yMin = *std::min_element(m_yData.begin(), m_yData.end());
  m_yMax = *std::max_element(m_yData.begin(), m_yData.end());

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
  emit dataChanged();
  emit fileNameChanged();
}

bool SpectrumData::hasData() const { return !m_xData.empty(); }

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

      auto min_it =
          std::min_element(intensities.begin() + i, intensities.begin() + end);
      auto max_it =
          std::max_element(intensities.begin() + i, intensities.begin() + end);

      size_t min_idx =
          static_cast<size_t>(std::distance(intensities.begin(), min_it));
      size_t max_idx =
          static_cast<size_t>(std::distance(intensities.begin(), max_it));

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
