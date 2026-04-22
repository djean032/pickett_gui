#include "spectrumplotitem.h"
#include "../models/spectrumdata.h"
#include <QSGGeometryNode>
#include <QSGFlatColorMaterial>
#include <QSGGeometry>
#include <algorithm>

SpectrumPlotItem::SpectrumPlotItem(QQuickItem *parent)
    : QQuickItem(parent)
{
    setFlag(ItemHasContents, true);
}

SpectrumData *SpectrumPlotItem::data() const
{
    return m_data;
}

void SpectrumPlotItem::setData(SpectrumData *data)
{
    if (m_data == data)
        return;

    if (m_data)
        disconnect(m_data, &SpectrumData::dataChanged, this, &SpectrumPlotItem::onDataChanged);

    m_data = data;
    m_dataDirty = true;

    if (m_data)
        connect(m_data, &SpectrumData::dataChanged, this, &SpectrumPlotItem::onDataChanged);

    emit dataChanged();
    update();
}

void SpectrumPlotItem::onDataChanged()
{
    m_dataDirty = true;
    update();
}

QSGNode *SpectrumPlotItem::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *)
{
    QSGGeometryNode *node = static_cast<QSGGeometryNode *>(oldNode);

    if (!m_data || m_data->xData().empty()) {
        if (node) {
            delete node;
        }
        return nullptr;
    }

    if (!node) {
        node = new QSGGeometryNode();

        QSGFlatColorMaterial *material = new QSGFlatColorMaterial();
        material->setColor(QColor("blue"));
        node->setMaterial(material);
        node->setFlag(QSGNode::OwnsMaterial);
    }

    // Find visible range
    double xMin = m_data->xMin();
    double xMax = m_data->xMax();
    const auto &xData = m_data->xData();
    const auto &yData = m_data->yData();

    auto it_left = std::lower_bound(xData.begin(), xData.end(), xMin);
    auto it_right = std::upper_bound(xData.begin(), xData.end(), xMax);

    if (it_left != xData.begin()) --it_left;
    if (it_right != xData.end()) ++it_right;

    size_t i0 = static_cast<size_t>(std::distance(xData.begin(), it_left));
    size_t i1 = static_cast<size_t>(std::distance(xData.begin(), it_right));

    if (i0 >= i1 || i0 >= xData.size()) {
        return node;
    }
    if (i1 > xData.size()) i1 = xData.size();

    size_t count = i1 - i0;

    // Map data coordinates to item coordinates
    double xRange = xMax - xMin;
    double yMin = m_data->yMin();
    double yMax = m_data->yMax();
    double yRange = yMax - yMin;

    if (xRange <= 0 || yRange <= 0) {
        return node;
    }

    QSGGeometry *geometry = new QSGGeometry(QSGGeometry::defaultAttributes_Point2D(), static_cast<int>(count));
    geometry->setDrawingMode(QSGGeometry::DrawLineStrip);
    geometry->setLineWidth(2);

    QSGGeometry::Point2D *vertices = geometry->vertexDataAsPoint2D();

    for (size_t i = 0; i < count; ++i) {
        size_t idx = i0 + i;
        double x = (xData[idx] - xMin) / xRange * width();
        double y = height() - ((yData[idx] - yMin) / yRange * height());
        vertices[i].set(static_cast<float>(x), static_cast<float>(y));
    }

    node->setGeometry(geometry);
    node->setFlag(QSGNode::OwnsGeometry);
    node->markDirty(QSGNode::DirtyGeometry);

    m_dataDirty = false;

    return node;
}
