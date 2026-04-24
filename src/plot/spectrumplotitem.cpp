#include "spectrumplotitem.h"
#include "../models/spectrumdata.h"
#include <QSGGeometryNode>
#include <QSGFlatColorMaterial>
#include <QSGGeometry>
#include <algorithm>

// Debug toggle: set false to disable SVIEW-style interpolation
constexpr bool enableSmoothing = true;

SpectrumPlotItem::SpectrumPlotItem(QQuickItem *parent)
    : QQuickItem(parent)
{
    setFlag(ItemHasContents, true);
}

SpectrumData *SpectrumPlotItem::data() const
{
    return m_data;
}

bool SpectrumPlotItem::hasData() const
{
    return m_data && !m_data->xData().empty();
}

void SpectrumPlotItem::setData(SpectrumData *data)
{
    if (m_data == data)
        return;

    if (m_data)
        disconnect(m_data, &SpectrumData::dataChanged, this, &SpectrumPlotItem::onDataChanged);

    m_data = data;
    m_dataDirty = true;

    if (m_data) {
        connect(m_data, &SpectrumData::dataChanged, this, &SpectrumPlotItem::onDataChanged);
        syncViewToData();
        m_cursorX = (m_viewXMin + m_viewXMax) * 0.5;
        emit cursorChanged();
    }

    emit dataChanged();
    update();
}

void SpectrumPlotItem::onDataChanged()
{
    m_dataDirty = true;
    syncViewToData();
    m_cursorX = (m_viewXMin + m_viewXMax) * 0.5;
    emit cursorChanged();
    emit dataChanged();
    update();
}

double SpectrumPlotItem::viewXMin() const { return m_viewXMin; }
void SpectrumPlotItem::setViewXMin(double value) { m_viewXMin = value; emit viewChanged(); update(); }
double SpectrumPlotItem::viewXMax() const { return m_viewXMax; }
void SpectrumPlotItem::setViewXMax(double value) { m_viewXMax = value; emit viewChanged(); update(); }
double SpectrumPlotItem::viewYMin() const { return m_viewYMin; }
void SpectrumPlotItem::setViewYMin(double value) { m_viewYMin = value; emit viewChanged(); update(); }
double SpectrumPlotItem::viewYMax() const { return m_viewYMax; }
void SpectrumPlotItem::setViewYMax(double value) { m_viewYMax = value; emit viewChanged(); update(); }

double SpectrumPlotItem::cursorX() const { return m_cursorX; }
void SpectrumPlotItem::setCursorX(double value)
{
    m_cursorX = value;
    emit cursorChanged();
    update();
}

void SpectrumPlotItem::syncViewToData()
{
    if (!m_data)
        return;
    m_viewXMin = m_data->xMin();
    m_viewXMax = m_data->xMax();
    m_viewYMin = m_data->yMin();
    m_viewYMax = m_data->yMax();
    emit viewChanged();
}

void SpectrumPlotItem::resetView()
{
    syncViewToData();
    m_cursorX = (m_viewXMin + m_viewXMax) * 0.5;
    emit cursorChanged();
    update();
}

void SpectrumPlotItem::clampView()
{
    if (!m_data)
        return;

    double dxMin = m_data->xMin();
    double dxMax = m_data->xMax();

    const double minRange = 1e-12;

    // Enforce minimum range
    if (m_viewXMax - m_viewXMin < minRange) {
        double center = (m_viewXMin + m_viewXMax) * 0.5;
        m_viewXMin = center - minRange * 0.5;
        m_viewXMax = center + minRange * 0.5;
    }
    if (m_viewYMax - m_viewYMin < minRange) {
        double center = (m_viewYMin + m_viewYMax) * 0.5;
        m_viewYMin = center - minRange * 0.5;
        m_viewYMax = center + minRange * 0.5;
    }

    // Clamp x-axis to data bounds (can't pan/zoom beyond frequency range)
    double xRange = m_viewXMax - m_viewXMin;
    double dxRange = dxMax - dxMin;
    if (xRange > dxRange) {
        m_viewXMin = dxMin;
        m_viewXMax = dxMax;
    } else {
        if (m_viewXMin < dxMin) {
            m_viewXMin = dxMin;
            m_viewXMax = dxMin + xRange;
        }
        if (m_viewXMax > dxMax) {
            m_viewXMax = dxMax;
            m_viewXMin = dxMax - xRange;
        }
    }

    // Y-axis is free — no data-bounds clamping
}

void SpectrumPlotItem::clampCursor()
{
    if (m_cursorX < m_viewXMin) m_cursorX = m_viewXMin;
    if (m_cursorX > m_viewXMax) m_cursorX = m_viewXMax;
}

void SpectrumPlotItem::panX(double delta)
{
    if (!m_data)
        return;
    double shift = delta * (m_viewXMax - m_viewXMin);
    m_viewXMin += shift;
    m_viewXMax += shift;
    clampView();
    emit viewChanged();
    update();
}

void SpectrumPlotItem::panY(double delta)
{
    if (!m_data)
        return;
    double shift = delta * (m_viewYMax - m_viewYMin);
    m_viewYMin += shift;
    m_viewYMax += shift;
    clampView();
    emit viewChanged();
    update();
}

void SpectrumPlotItem::zoomX(double factor)
{
    if (!m_data || factor <= 0.0)
        return;
    double center = m_cursorX;
    double halfRange = (m_viewXMax - m_viewXMin) / (2.0 * factor);
    m_viewXMin = center - halfRange;
    m_viewXMax = center + halfRange;
    clampView();
    emit viewChanged();
    update();
}

void SpectrumPlotItem::zoomY(double factor)
{
    if (!m_data || factor <= 0.0)
        return;
    double center = (m_viewYMin + m_viewYMax) * 0.5;
    double halfRange = (m_viewYMax - m_viewYMin) / (2.0 * factor);
    m_viewYMin = center - halfRange;
    m_viewYMax = center + halfRange;
    clampView();
    emit viewChanged();
    update();
}

void SpectrumPlotItem::moveCursor(int pixelDelta)
{
    if (!m_data || width() <= 0)
        return;

    double xRange = m_viewXMax - m_viewXMin;
    double pixelSize = xRange / width();
    m_cursorX += pixelDelta * pixelSize;

    bool panned = false;
    double panAmount = xRange; // full screen width

    if (m_cursorX < m_viewXMin) {
        // Hit left edge - pan left by full screen width, cursor to right edge
        m_viewXMin -= panAmount;
        m_viewXMax -= panAmount;
        clampView();
        m_cursorX = m_viewXMax;
        panned = true;
    } else if (m_cursorX > m_viewXMax) {
        // Hit right edge - pan right by full screen width, cursor to left edge
        m_viewXMin += panAmount;
        m_viewXMax += panAmount;
        clampView();
        m_cursorX = m_viewXMin;
        panned = true;
    } else {
        clampCursor();
    }

    emit cursorChanged();
    if (panned) emit viewChanged();
    update();
}

static double niceNumber(double range)
{
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

static double computeTickStep(double range)
{
    double step = niceNumber(range / 4.0);
    if (step <= 0.0)
        return step;

    for (int attempt = 0; attempt < 4; ++attempt) {
        int count = 0;
        double start = ceil(0.0 / step) * step; // viewport is arbitrary, just count
        double end = range;
        for (double v = start; v <= end + step * 0.5; v += step)
            ++count;
        if (count >= 4)
            break;
        step *= 0.5;
    }
    return step;
}

QVariantList SpectrumPlotItem::xTickPositions() const
{
    QVariantList ticks;
    if (!m_data || m_viewXMax <= m_viewXMin)
        return ticks;

    double step = computeTickStep(m_viewXMax - m_viewXMin);
    if (step <= 0.0)
        return ticks;

    double start = ceil(m_viewXMin / step) * step;
    for (double v = start; v <= m_viewXMax + step * 0.5; v += step)
        ticks.append(v);

    return ticks;
}

QVariantList SpectrumPlotItem::xMinorPositions() const
{
    QVariantList ticks;
    if (!m_data || m_viewXMax <= m_viewXMin)
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

// SVIEW-style quadratic Lagrange interpolation by successive doubling
static std::vector<double> sviewInterpolate(const std::vector<double> &input,
                                            size_t threshold)
{
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
                                            UpdatePaintNodeData *)
{
    if (!m_data || m_data->xData().empty()) {
        if (oldNode) {
            delete oldNode;
        }
        return nullptr;
    }

    double xMin = m_viewXMin;
    double xMax = m_viewXMax;
    const auto &xData = m_data->xData();
    const auto &yData = m_data->yData();

    auto it_left = std::lower_bound(xData.begin(), xData.end(), xMin);
    auto it_right = std::upper_bound(xData.begin(), xData.end(), xMax);

    if (it_left != xData.begin()) --it_left;
    if (it_right != xData.end()) ++it_right;

    size_t i0 = static_cast<size_t>(std::distance(xData.begin(), it_left));
    size_t i1 = static_cast<size_t>(std::distance(xData.begin(), it_right));

    if (i0 >= i1 || i0 >= xData.size()) {
        if (oldNode) {
            delete oldNode;
        }
        return nullptr;
    }
    if (i1 > xData.size()) i1 = xData.size();

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

    if constexpr (enableSmoothing) {
        std::vector<double> yVisible;
        yVisible.reserve(count);
        for (size_t i = i0; i < i1; ++i)
            yVisible.push_back(yData[i]);

        const size_t threshold = 100000;
        if (count < threshold && count >= 2) {
            yRender = sviewInterpolate(yVisible, threshold);
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
        QSGGeometry::defaultAttributes_Point2D(),
        static_cast<int>(vertexCount));
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
