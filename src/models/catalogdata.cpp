#include "catalogdata.h"
#include <algorithm>
#include <cmath>

CatalogData::CatalogData(QObject *parent) : QObject(parent) {}

void CatalogData::loadFile(const QString &filePath) {
  if (!m_fileService) {
    return;
  }

  m_pendingFileName = filePath;
  m_pendingRequestId = m_fileService->loadCatAsync(filePath);
}

void CatalogData::setFileService(SpectralFileService *service) {
  if (m_fileService == service) {
    return;
  }

  if (m_fileService) {
    disconnect(m_fileService, &SpectralFileService::catLoaded, this,
               &CatalogData::onCatLoaded);
  }

  m_fileService = service;

  if (m_fileService) {
    connect(m_fileService, &SpectralFileService::catLoaded, this,
            &CatalogData::onCatLoaded);
  }

  emit fileServiceChanged();
}

void CatalogData::onCatLoaded(
    const SpectralFileService::CatalogResult &result) {
  if (result.requestId != m_pendingRequestId) {
    return;
  }

  if (!result.success || result.lines.isEmpty()) {
    return;
  }

  m_records.clear();
  m_records.reserve(static_cast<size_t>(result.lines.size()));
  for (const auto &line : result.lines) {
    pickett::CatRecord record;
    record.freq = line.freq;
    record.err = line.err;
    record.lgint = line.lgint;
    record.elo = line.elo;
    record.dr = line.dr;
    record.gup = line.gup;
    record.tag = line.tag;
    record.qnfmt = line.qnfmt;
    for (int i = 0; i < 12; ++i) {
      if (i < line.qn.size()) {
        record.qn[i] = line.qn[i];
      } else {
        record.qn[i] = 0;
      }
    }
    m_records.push_back(record);
  }

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
