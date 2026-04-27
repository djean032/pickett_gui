#include "catalogdata.h"
#include "parsers/cat_parser.h"
#include <QUrl>
#include <algorithm>
#include <cmath>

CatalogData::CatalogData(QObject *parent) : QObject(parent) {}

void CatalogData::loadFile(const QString &filePath) {
  QString localPath = filePath;
  QUrl url(filePath);
  if (url.isLocalFile()) {
    localPath = url.toLocalFile();
  }

  pickett::CatParseResult result =
      pickett::CatParser::parse_file(localPath.toStdString());
  if (!result.success) {
    return;
  }

  m_records = std::move(result.records);
  if (m_records.empty()) {
    return;
  }

  // Sort by frequency so that lower_bound/upper_bound work correctly
  std::sort(m_records.begin(), m_records.end(),
            [](const pickett::CatRecord &a, const pickett::CatRecord &b) {
              return a.freq < b.freq;
            });

  // Compute bounds
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

  m_fileName = filePath;
  emit dataChanged();
  emit fileNameChanged();
}
