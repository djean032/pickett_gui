#include "catalogplotitem.h"
#include "../models/catalogdata.h"
#include "../models/viewportmodel.h"
#include "parsers/cat_parser.h"
#include <QSGFlatColorMaterial>
#include <QSGGeometry>
#include <QSGGeometryNode>
#include <algorithm>
#include <qcolor.h>
#include <qsgflatcolormaterial.h>
#include <qsggeometry.h>
#include <qsgnode.h>

CatalogPlotItem::CatalogPlotItem(QQuickItem *parent) : QQuickItem(parent) {
  setFlag(ItemHasContents, true);
}

ViewportModel *CatalogPlotItem::viewport() const { return m_viewport; }

void CatalogPlotItem::setViewport(ViewportModel *viewport) {
  if (m_viewport == viewport)
    return;

  if (m_viewport)
    disconnect(m_viewport, &ViewportModel::viewChanged, this,
               &CatalogPlotItem::update);

  m_viewport = viewport;

  if (m_viewport)
    connect(m_viewport, &ViewportModel::viewChanged, this,
            &CatalogPlotItem::update);

  emit viewportChanged();
  update();
}

CatalogData *CatalogPlotItem::catalogData() const { return m_catalogData; }

void CatalogPlotItem::setCatalogData(CatalogData *data) {
  if (m_catalogData == data)
    return;

  if (m_catalogData)
    disconnect(m_catalogData, &CatalogData::dataChanged, this,
               &CatalogPlotItem::onCatalogDataChanged);

  m_catalogData = data;
  m_dataDirty = true;

  if (m_catalogData)
    connect(m_catalogData, &CatalogData::dataChanged, this,
            &CatalogPlotItem::onCatalogDataChanged);

  emit catalogDataChanged();
  update();
}

void CatalogPlotItem::onCatalogDataChanged() {
  m_dataDirty = true;
  emit catalogDataChanged();
  update();
}

bool CatalogPlotItem::hasData() const {
  return m_catalogData && m_catalogData->hasData();
}

QSGNode *CatalogPlotItem::updatePaintNode(QSGNode *oldNode,
                                          UpdatePaintNodeData *) {
  if (!m_catalogData || !m_catalogData->hasData() || !m_viewport) {
    if (oldNode) {
      delete oldNode;
    }
    return nullptr;
  }

  double xMin = m_viewport->viewXMin();
  double xMax = m_viewport->viewXMax();
  double xRange = xMax - xMin;

  if (xRange <= 0) {
    if (oldNode) {
      delete oldNode;
    }
    return nullptr;
  }

  const auto &records = m_catalogData->records();
  if (records.empty()) {
    if (oldNode) {
      delete oldNode;
    }
    return nullptr;
  }

  // Find visible range using lower_bound/upper_bound on frequencies
  // We need a temp vector of just frequencies, or we can do a custom comparator
  // Since records is sorted by freq, we can use a custom comparator on the
  // vector
  auto it_left = std::lower_bound(
      records.begin(), records.end(), xMin,
      [](const pickett::CatRecord &rec, double val) { return rec.freq < val; });
  auto it_right = std::upper_bound(
      records.begin(), records.end(), xMax,
      [](double val, const pickett::CatRecord &rec) { return val < rec.freq; });

  if (it_left != records.begin())
    --it_left;
  if (it_right != records.end())
    ++it_right;

  size_t rawCount = static_cast<size_t>(std::distance(it_left, it_right));
  if (rawCount == 0) {
    if (oldNode) {
      delete oldNode;
    }
    return nullptr;
  }

  // Cap visible records to avoid GPU geometry buffer truncation.
  // The QSG renderer may use 16-bit indices internally, so we must keep
  // the total vertex count under 65535. Each stick is 2 vertices, so we
  // cap at 30000 lines (60000 vertices) — well within the safe limit.
  // To avoid x-gaps, we stride across frequency and pick the strongest
  // line from each bin, giving uniform coverage across the full range.
  const size_t MAX_VISIBLE = 30000;
  std::vector<const pickett::CatRecord *> selected;
  selected.reserve(std::min(rawCount, MAX_VISIBLE));

  if (rawCount <= MAX_VISIBLE) {
    for (auto it = it_left; it != it_right; ++it)
      selected.push_back(&(*it));
  } else {
    size_t stride = (rawCount + MAX_VISIBLE - 1) / MAX_VISIBLE; // ceiling
    for (size_t i = 0; i < rawCount; i += stride) {
      size_t end = std::min(i + stride, rawCount);
      auto strongest = std::max_element(
          it_left + i, it_left + end,
          [](const pickett::CatRecord &a, const pickett::CatRecord &b) {
            return a.lgint < b.lgint;
          });
      selected.push_back(&(*strongest));
    }
  }

  std::map<int, std::vector<const pickett::CatRecord *>> groups;
  for (const auto *rec : selected) {
    groups[rec->qn[3]].push_back(rec);
  }

  auto colorForV = [](int v) -> QColor {
    switch (v) {
    case 0:
      return QColor("#E6194B"); // Red
    case 1:
      return QColor("#3CB44B"); // Green
    case 2:
      return QColor("#4363D8"); // Blue
    case 3:
      return QColor("#FFE119"); // Yellow
    case 4:
      return QColor("#911EB4"); // Purple
    case 5:
      return QColor("#42D4F4"); // Cyan
    case 6:
      return QColor("#F032E6"); // Magenta
    case 7:
      return QColor("#FF4500"); // OrangeRed
    default:
      return QColor("white");
    }
  };

  double yMax = m_catalogData->yMax();
  if (yMax <= 0) {
    if (oldNode) {
      delete oldNode;
    }
    return nullptr;
  }

  if (oldNode) {
    delete oldNode;
  }
  QSGNode *parentNode = new QSGNode();

  double h = height();
  bool singleColor = (groups.size() <= 1);

  for (const auto &[v, recs] : groups) {
    size_t count = recs.size();
    QSGGeometry *geometry = new QSGGeometry(
        QSGGeometry::defaultAttributes_Point2D(), static_cast<int>(count * 2));
    geometry->setDrawingMode(QSGGeometry::DrawLines);
    geometry->setLineWidth(2);

    QSGGeometry::Point2D *vertices = geometry->vertexDataAsPoint2D();

    for (auto i = 0; i < count; ++i) {
      const auto &rec = *recs[i];
      double x = (rec.freq - xMin) / xRange * width();
      double intensity = rec.lgint;
      double yTop = h - (intensity / yMax * h);

      vertices[2 * i].set(static_cast<float>(x), static_cast<float>(h));
      vertices[2 * i + 1].set(static_cast<float>(x), static_cast<float>(yTop));
    }

    QSGGeometryNode *child = new QSGGeometryNode();
    child->setGeometry(geometry);
    child->setFlag(QSGNode::OwnsGeometry);

    QSGFlatColorMaterial *material = new QSGFlatColorMaterial();
    material->setColor(singleColor ? QColor("white") : colorForV(v));
    child->setMaterial(material);
    child->setFlag(QSGNode::OwnsMaterial);
    parentNode->appendChildNode(child);
  }

  m_dataDirty = false;
  return parentNode;
}
