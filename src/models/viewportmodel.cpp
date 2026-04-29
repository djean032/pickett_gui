#include "viewportmodel.h"
#include "models/catalogdata.h"
#include "parsers/cat_parser.h"
#include <algorithm>
#include <cmath>
#include <qcontainerfwd.h>

ViewportModel::ViewportModel(QObject *parent) : QObject(parent) {}

void ViewportModel::setDataBounds(double xMin, double xMax) {
  if (!m_hasData) {
    m_dataXMin = xMin;
    m_dataXMax = xMax;
    m_hasData = true;
    updateFromBounds();
    emit hasDataChanged();
  } else {
    m_dataXMin = std::min(m_dataXMin, xMin);
    m_dataXMax = std::max(m_dataXMax, xMax);
    clampView();
    clampSpectrumCursor();
    clampCatalogCursor();
    emit viewChanged();
    emit cursorChanged();
  }
}

void ViewportModel::clearDataBounds() {
  m_hasData = false;
  emit hasDataChanged();
}

void ViewportModel::updateFromBounds() {
  m_viewXMin = m_dataXMin;
  m_viewXMax = m_dataXMax;
  const double center = (m_dataXMin + m_dataXMax) * 0.5;
  m_spectrumCursorX = center;
  m_catalogCursorX = center;
  emit viewChanged();
  emit cursorChanged();
}

void ViewportModel::resetView() {
  if (!m_hasData)
    return;
  m_viewXMin = m_dataXMin;
  m_viewXMax = m_dataXMax;
  const double center = (m_dataXMin + m_dataXMax) * 0.5;
  m_spectrumCursorX = center;
  m_catalogCursorX = center;
  emit viewChanged();
  emit cursorChanged();
}

void ViewportModel::clampView() {
  if (!m_hasData)
    return;

  const double minRange = 1e-12;
  if (m_viewXMax - m_viewXMin < minRange) {
    double center = (m_viewXMin + m_viewXMax) * 0.5;
    m_viewXMin = center - minRange * 0.5;
    m_viewXMax = center + minRange * 0.5;
  }

  double xRange = m_viewXMax - m_viewXMin;
  double dxRange = m_dataXMax - m_dataXMin;
  if (xRange > dxRange) {
    m_viewXMin = m_dataXMin;
    m_viewXMax = m_dataXMax;
  } else {
    if (m_viewXMin < m_dataXMin) {
      m_viewXMin = m_dataXMin;
      m_viewXMax = m_dataXMin + xRange;
    }
    if (m_viewXMax > m_dataXMax) {
      m_viewXMax = m_dataXMax;
      m_viewXMin = m_dataXMax - xRange;
    }
  }
}

void ViewportModel::clampSpectrumCursor() {
  if (m_spectrumCursorX < m_viewXMin)
    m_spectrumCursorX = m_viewXMin;
  if (m_spectrumCursorX > m_viewXMax)
    m_spectrumCursorX = m_viewXMax;
}

void ViewportModel::clampCatalogCursor() {
  if (m_catalogCursorX < m_viewXMin)
    m_catalogCursorX = m_viewXMin;
  if (m_catalogCursorX > m_viewXMax)
    m_catalogCursorX = m_viewXMax;
}

void ViewportModel::panX(double delta) {
  if (!m_hasData)
    return;
  double shift = delta * (m_viewXMax - m_viewXMin);
  m_viewXMin += shift;
  m_viewXMax += shift;
  clampView();
  emit viewChanged();
}

void ViewportModel::zoomX(double factor) {
  if (!m_hasData || factor <= 0.0)
    return;
  double halfRange = (m_viewXMax - m_viewXMin) / (2.0 * factor);
  m_viewXMin = m_catalogCursorX - halfRange;
  m_viewXMax = m_catalogCursorX + halfRange;
  clampView();
  emit viewChanged();
}

void ViewportModel::moveSpectrumCursor(int pixelDelta, double plotWidth) {
  if (!m_hasData || plotWidth <= 0)
    return;

  const double xRange = m_viewXMax - m_viewXMin;
  const double pixelSize = xRange / plotWidth;
  m_spectrumCursorX += pixelDelta * pixelSize;

  clampSpectrumCursor();

  emit cursorChanged();
}

void ViewportModel::moveCatalogCursor(int pixelDelta, double plotWidth) {
  if (!m_hasData || plotWidth <= 0)
    return;

  double xRange = m_viewXMax - m_viewXMin;
  double pixelSize = xRange / plotWidth;
  m_catalogCursorX += pixelDelta * pixelSize;
  if (m_snapToCatalog && m_catalogData && m_catalogData->hasData() &&
      pixelDelta != 0) {
    const auto &records = m_catalogData->records();
    if (pixelDelta > 0) {
      auto it = std::lower_bound(
          records.begin(), records.end(), m_catalogCursorX,
          [](const pickett::CatRecord &r, double val) { return r.freq < val; });
      if (it != records.end()) {
        double pixelDist = (it->freq - m_catalogCursorX) / pixelSize;
        if (pixelDist >= 0 && pixelDist <= m_snapPixelDistance) {
          m_catalogCursorX = it->freq;
        }
      }
    } else {
      auto it = std::upper_bound(
          records.begin(), records.end(), m_catalogCursorX,
          [](double val, const pickett::CatRecord &r) { return val < r.freq; });
      if (it != records.begin()) {
        it = std::prev(it);
        double pixelDist = (m_catalogCursorX - it->freq) / pixelSize;
        if (pixelDist >= 0 && pixelDist <= m_snapPixelDistance) {
          m_catalogCursorX = it->freq;
        }
      }
    }
  }

  bool panned = false;
  double panAmount = xRange;

  if (m_catalogCursorX < m_viewXMin) {
    m_viewXMin -= panAmount;
    m_viewXMax -= panAmount;
    clampView();
    m_catalogCursorX = m_viewXMax;
    panned = true;
  } else if (m_catalogCursorX > m_viewXMax) {
    m_viewXMin += panAmount;
    m_viewXMax += panAmount;
    clampView();
    m_catalogCursorX = m_viewXMin;
    panned = true;
  } else {
    clampCatalogCursor();
  }

  // Catalog cursor is the anchor cursor: moving it also moves spectrum cursor.
  m_spectrumCursorX = m_catalogCursorX;

  emit cursorChanged();
  if (panned)
    emit viewChanged();
}

static double niceNumber(double range) {
  double exponent = floor(log10(range));
  double fraction = range / pow(10.0, exponent);
  double niceFraction;
  if (fraction < 1.5)
    niceFraction = 1.0;
  else if (fraction < 3.0)
    niceFraction = 2.0;
  else if (fraction < 7.0)
    niceFraction = 5.0;
  else
    niceFraction = 10.0;
  return niceFraction * pow(10.0, exponent);
}

static double computeTickStep(double range) {
  double step = niceNumber(range / 4.0);
  if (step <= 0.0)
    return step;
  for (int attempt = 0; attempt < 4; ++attempt) {
    int count = 0;
    double start = ceil(0.0 / step) * step;
    double end = range;
    for (double v = start; v <= end + step * 0.5; v += step)
      ++count;
    if (count >= 4)
      break;
    step *= 0.5;
  }
  return step;
}

QVariantList ViewportModel::xTickPositions() const {
  QVariantList ticks;
  if (!m_hasData || m_viewXMax <= m_viewXMin)
    return ticks;

  double step = computeTickStep(m_viewXMax - m_viewXMin);
  if (step <= 0.0)
    return ticks;

  double start = ceil(m_viewXMin / step) * step;
  for (double v = start; v <= m_viewXMax + step * 0.5; v += step)
    ticks.append(v);
  return ticks;
}

QVariantList ViewportModel::xMinorPositions() const {
  QVariantList ticks;
  if (!m_hasData || m_viewXMax <= m_viewXMin)
    return ticks;

  double majorStep = computeTickStep(m_viewXMax - m_viewXMin);
  if (majorStep <= 0.0)
    return ticks;

  double minorStep = majorStep / 10.0;
  double start = ceil(m_viewXMin / minorStep) * minorStep;
  for (double v = start; v <= m_viewXMax + minorStep * 0.5; v += minorStep)
    ticks.append(v);
  return ticks;
}

void ViewportModel::setCatalogData(CatalogData *data) {
  if (m_catalogData != data) {
    m_catalogData = data;
    m_lastPixel = -1;
    m_pixelLineIndices.clear();
    m_currentPixelLineIndex = 0;
  }
  emit catalogDataChanged();
}

void ViewportModel::setSnapToCatalog(bool value) {
  if (m_snapToCatalog != value) {
    m_snapToCatalog = value;
  }
  emit snapSettingsChanged();
}

void ViewportModel::setSnapPixelDistance(double value) {
  if (m_snapPixelDistance != value) {
    m_snapPixelDistance = value;
  }
  emit snapSettingsChanged();
}
QVariantMap ViewportModel::lineAtPixel(double pixel, double plotWidth) {
  QVariantMap info;
  if (!m_catalogData || !m_catalogData->hasData() || !m_hasData ||
      plotWidth <= 0) {
    return info;
  }

  const auto &records = m_catalogData->records();
  if (records.empty()) {
    return info;
  }

  if (std::abs(m_lastPixel - pixel) > 0.5) {
    m_lastPixel = pixel;

    double xRange = m_viewXMax - m_viewXMin;
    double pixelFreq = xRange / plotWidth;
  double cursorFreq = m_catalogCursorX;
    double startFreq = cursorFreq - pixelFreq * 0.5;
    double endFreq = cursorFreq + pixelFreq * 0.5;

    // Lines in this pixel.
    auto it_start = std::lower_bound(
        records.begin(), records.end(), startFreq,
        [](const pickett::CatRecord &r, double val) { return r.freq < val; });
    auto it_end = std::upper_bound(
        records.begin(), records.end(), endFreq,
        [](double val, const pickett::CatRecord &r) { return val < r.freq; });

    m_pixelLineIndices.clear();

    // Fill vector
    for (auto it = it_start; it != it_end; ++it) {
      int idx = static_cast<int>(std::distance(records.begin(), it));
      m_pixelLineIndices.push_back(idx);
    }

    m_currentPixelLineIndex = 0;
  }

  if (m_pixelLineIndices.empty()) {
    return info;
  }

  int idx = m_pixelLineIndices[m_currentPixelLineIndex];
  const auto &rec = records[idx];

  info["found"] = true;
  info["freq"] = rec.freq;
  info["lgint"] = rec.lgint;
  info["elo"] = rec.elo;
  info["lineIndex"] = m_currentPixelLineIndex;
  info["totalLines"] = static_cast<int>(m_pixelLineIndices.size());

    QVariantList upperQN, lowerQN, upperLabels, lowerLabels;
    int totalQN = 12; //spcat defined
    int nqn = rec.qnfmt % 10;  // Quantum numbers per state
    if (nqn <= 0) nqn = 3;  // Default fallback

    for (int i = 0; i < nqn; ++i) {
        upperQN.append(rec.qn[i]);
    }
    for (int i = totalQN / 2; i < totalQN / 2 + nqn; ++i) {
        lowerQN.append(rec.qn[i]);
    }

    // Get labels for this QNFMT, only take first 'nqn' per state
    auto labels = pickett::CatParser::get_qn_labels(rec.qnfmt);
    for (int i = 0; i < nqn && i < labels.size(); ++i) {
        upperLabels.append(QString::fromStdString(labels[i] + "'"));
    }
    // For lower state, reuse the same labels with "''" suffix
    for (int i = 0; i < nqn && i < labels.size(); ++i) {
        lowerLabels.append(QString::fromStdString(labels[i] + "''"));
    }

  info["upperQN"] = upperQN;
  info["lowerQN"] = lowerQN;
  info["upperLabels"] = upperLabels;
  info["lowerLabels"] = lowerLabels;

  return info;
};

void ViewportModel::cycleLineDown() {
  if (m_pixelLineIndices.size() <= 1) {
    return;
  }

  m_currentPixelLineIndex--;
  if (m_currentPixelLineIndex < 0) {
    m_currentPixelLineIndex = m_pixelLineIndices.size() - 1;
  }
  emit cursorChanged();
}

void ViewportModel::cycleLineUp() {
  if (m_pixelLineIndices.size() <= 1) {
    return;
  }

  m_currentPixelLineIndex++;
  if (m_currentPixelLineIndex >= m_pixelLineIndices.size()) {
    m_currentPixelLineIndex = 0;
  }
  emit cursorChanged();
}
