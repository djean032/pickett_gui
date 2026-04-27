#include "spectrumplotitem.h"
#include "../models/spectrumdata.h"
#include "../models/viewportmodel.h"
#include <QSGFlatColorMaterial>
#include <QSGGeometry>
#include <QSGGeometryNode>
#include <algorithm>

// Debug toggle: set false to disable SVIEW-style interpolation
constexpr bool enableSmoothing = true;

SpectrumPlotItem::SpectrumPlotItem(QQuickItem *parent) : QQuickItem(parent) {
  setFlag(ItemHasContents, true);
}

SpectrumData *SpectrumPlotItem::data() const { return m_data; }

bool SpectrumPlotItem::hasData() const {
  return m_data && !m_data->xData().empty();
}

void SpectrumPlotItem::setData(SpectrumData *data) {
  if (m_data == data)
    return;

  if (m_data)
    disconnect(m_data, &SpectrumData::dataChanged, this,
               &SpectrumPlotItem::onDataChanged);

  m_data = data;
  m_dataDirty = true;

  if (m_data) {
    connect(m_data, &SpectrumData::dataChanged, this,
            &SpectrumPlotItem::onDataChanged);
    syncViewToData();
  }

  emit dataChanged();
  update();
}

ViewportModel *SpectrumPlotItem::viewport() const { return m_viewport; }

void SpectrumPlotItem::setViewport(ViewportModel *viewport) {
  if (m_viewport == viewport)
    return;

  if (m_viewport)
    disconnect(m_viewport, &ViewportModel::viewChanged, this,
               &SpectrumPlotItem::update);

  m_viewport = viewport;

  if (m_viewport)
    connect(m_viewport, &ViewportModel::viewChanged, this,
            &SpectrumPlotItem::update);

  emit viewportChanged();
  update();
}

void SpectrumPlotItem::onDataChanged() {
  m_dataDirty = true;
  syncViewToData();
  emit dataChanged();
  update();
}

void SpectrumPlotItem::syncViewToData() {
  if (!m_data)
    return;

  m_viewYMin = m_data->yMin();
  m_viewYMax = m_data->yMax();
  emit viewYChanged();
}

void SpectrumPlotItem::clampYView() {
  const double minRange = 1e-12;
  if (m_viewYMax - m_viewYMin < minRange) {
    double center = (m_viewYMin + m_viewYMax) * 0.5;
    m_viewYMin = center - minRange * 0.5;
    m_viewYMax = center + minRange * 0.5;
  }
}

double SpectrumPlotItem::viewYMin() const { return m_viewYMin; }
void SpectrumPlotItem::setViewYMin(double value) {
  m_viewYMin = value;
  emit viewYChanged();
  update();
}
double SpectrumPlotItem::viewYMax() const { return m_viewYMax; }
void SpectrumPlotItem::setViewYMax(double value) {
  m_viewYMax = value;
  emit viewYChanged();
  update();
}

void SpectrumPlotItem::panY(double delta) {
  if (!m_data)
    return;
  double shift = delta * (m_viewYMax - m_viewYMin);
  m_viewYMin += shift;
  m_viewYMax += shift;
  clampYView();
  emit viewYChanged();
  update();
}

void SpectrumPlotItem::zoomY(double factor) {
  if (!m_data || factor <= 0.0)
    return;
  double center = (m_viewYMin + m_viewYMax) * 0.5;
  double halfRange = (m_viewYMax - m_viewYMin) / (2.0 * factor);
  m_viewYMin = center - halfRange;
  m_viewYMax = center + halfRange;
  clampYView();
  emit viewYChanged();
  update();
}

// SVIEW-style quadratic Lagrange interpolation by successive doubling
static std::vector<double> sviewInterpolate(const std::vector<double> &input,
                                            size_t threshold) {
  std::vector<double> work = input;

  while (work.size() < threshold && work.size() >= 2) {
    size_t n = work.size();
    std::vector<double> interp(2 * n - 1);

    for (size_t j = 0; j < n - 1; ++j) {
      interp[2 * j] = work[j];

      double mid;
      if (j + 2 < n) {
        // Forward-looking quadratic Lagrange
        mid = 0.375 * work[j] + 0.75 * work[j + 1] - 0.125 * work[j + 2];
      } else if (j >= 1) {
        // Backward-looking quadratic Lagrange
        mid = -0.125 * work[j - 1] + 0.75 * work[j] + 0.375 * work[j + 1];
      } else {
        // Fallback to linear for n == 2
        mid = 0.5 * work[j] + 0.5 * work[j + 1];
      }
      interp[2 * j + 1] = mid;
    }

    interp[2 * (n - 1)] = work[n - 1];
    work = std::move(interp);
  }

  return work;
}

QSGNode *SpectrumPlotItem::updatePaintNode(QSGNode *oldNode,
                                           UpdatePaintNodeData *) {
  if (!m_data || m_data->xData().empty() || !m_viewport) {
    if (oldNode) {
      delete oldNode;
    }
    return nullptr;
  }

  double xMin = m_viewport->viewXMin();
  double xMax = m_viewport->viewXMax();
  const auto &xData = m_data->xData();
  const auto &yData = m_data->yData();

  auto it_left = std::lower_bound(xData.begin(), xData.end(), xMin);
  auto it_right = std::upper_bound(xData.begin(), xData.end(), xMax);

  if (it_left != xData.begin())
    --it_left;
  if (it_right != xData.end())
    ++it_right;

  size_t i0 = static_cast<size_t>(std::distance(xData.begin(), it_left));
  size_t i1 = static_cast<size_t>(std::distance(xData.begin(), it_right));

  if (i0 >= i1 || i0 >= xData.size()) {
    if (oldNode) {
      delete oldNode;
    }
    return nullptr;
  }
  if (i1 > xData.size())
    i1 = xData.size();

  size_t count = i1 - i0;

  double xRange = xMax - xMin;
  double yMin = m_viewYMin;
  double yMax = m_viewYMax;
  double yRange = yMax - yMin;

  if (xRange <= 0 || yRange <= 0) {
    if (oldNode) {
      delete oldNode;
    }
    return nullptr;
  }

  std::vector<double> yRender;
  std::vector<double> xRender;

  // Safe vertex limit for QSG (16-bit indices cap at 65535; stay well under)
  const size_t MAX_VERTICES = 50000;

  if constexpr (enableSmoothing) {
    std::vector<double> yVisible;
    yVisible.reserve(count);
    for (size_t i = i0; i < i1; ++i)
      yVisible.push_back(yData[i]);

    if (count < MAX_VERTICES && count >= 2) {
      yRender = sviewInterpolate(yVisible, MAX_VERTICES);
      size_t nplot = yRender.size();
      xRender.resize(nplot);
      double fincr = (xMax - xMin) / (nplot - 1);
      for (size_t n = 0; n < nplot; ++n)
        xRender[n] = xMin + n * fincr;
    } else {
      yRender = std::move(yVisible);
      xRender.reserve(count);
      for (size_t i = i0; i < i1; ++i)
        xRender.push_back(xData[i]);
    }
  } else {
    yRender.reserve(count);
    xRender.reserve(count);
    for (size_t i = i0; i < i1; ++i) {
      yRender.push_back(yData[i]);
      xRender.push_back(xData[i]);
    }
  }

  // Stride if still over the safe limit
  if (xRender.size() > MAX_VERTICES) {
    size_t stride = (xRender.size() + MAX_VERTICES - 1) / MAX_VERTICES;
    std::vector<double> xStrided;
    std::vector<double> yStrided;
    xStrided.reserve(MAX_VERTICES);
    yStrided.reserve(MAX_VERTICES);
    for (size_t i = 0; i < xRender.size(); i += stride) {
      xStrided.push_back(xRender[i]);
      yStrided.push_back(yRender[i]);
    }
    xRender = std::move(xStrided);
    yRender = std::move(yStrided);
  }

  size_t vertexCount = xRender.size();

  QSGGeometryNode *node = static_cast<QSGGeometryNode *>(oldNode);
  if (!node) {
    node = new QSGGeometryNode();

    QSGFlatColorMaterial *material = new QSGFlatColorMaterial();
    material->setColor(QColor("white"));
    node->setMaterial(material);
    node->setFlag(QSGNode::OwnsMaterial);
  }

  QSGGeometry *geometry = new QSGGeometry(
      QSGGeometry::defaultAttributes_Point2D(), static_cast<int>(vertexCount));
  geometry->setDrawingMode(QSGGeometry::DrawLineStrip);
  geometry->setLineWidth(2);

  QSGGeometry::Point2D *vertices = geometry->vertexDataAsPoint2D();

  for (size_t i = 0; i < vertexCount; ++i) {
    double x = (xRender[i] - xMin) / xRange * width();
    double y = height() - ((yRender[i] - yMin) / yRange * height());
    vertices[i].set(static_cast<float>(x), static_cast<float>(y));
  }

  node->setGeometry(geometry);
  node->setFlag(QSGNode::OwnsGeometry);
  node->markDirty(QSGNode::DirtyGeometry);

  m_dataDirty = false;

  return node;
}
