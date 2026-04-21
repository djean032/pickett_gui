#include "spectrumplotwidget.h"
#include <QPainter>
#include <QGraphicsTextItem>
#include <algorithm>

SpectrumPlotWidget::SpectrumPlotWidget(QWidget *parent)
      : QGraphicsView(parent)
      , scene(new QGraphicsScene(this))
      , plotItem(nullptr)
      , m_y_min(0.0)
      , m_y_max(0.0)
      , m_view_left(0.0)                // Viewport defaults
      , m_view_right(1.0)
      , m_cursor_idx(0)
{
  setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
  setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
  setScene(scene);
//  scene->setBackgroundBrush(QBrush(Qt::black));
  setRenderHint(QPainter::Antialiasing);
}

void SpectrumPlotWidget::setSpectrum(const std::vector<double>& freqs,
                                     const std::vector<double>& intensities)
{
  xData = freqs;
  yData = intensities;

  if (freqs.empty() || intensities.empty() || freqs.size() != intensities.size())
    return;

  m_y_min = *std::min_element(intensities.begin(), intensities.end());
  m_y_max = *std::max_element(intensities.begin(), intensities.end());
  m_view_left = *std::min_element(freqs.begin(), freqs.end());
  m_view_right = *std::max_element(freqs.begin(), freqs.end());

  updatePlot();
}

void SpectrumPlotWidget::resizeEvent(QResizeEvent *event)
{
  QGraphicsView::resizeEvent(event);

  scene->setSceneRect(rect());

  plotRect = QRectF(
      marginLeft,
      marginTop,
      width() - marginLeft - marginRight,
      height() - marginTop - marginBottom
      );

  updatePlot();
}

double SpectrumPlotWidget::mapX(double xVal) const
{
  return plotRect.left() + (xVal - m_view_left) / (m_view_right - m_view_left) * plotRect.width();
}

double SpectrumPlotWidget::mapY(double yVal) const
{
  return plotRect.bottom() - (yVal - m_y_min) / (m_y_max - m_y_min) * plotRect.height();
}

void SpectrumPlotWidget::drawAxes()
{
  scene->addLine(QLineF(plotRect.bottomLeft(), plotRect.bottomRight()));
  scene->addLine(QLineF(plotRect.bottomLeft(), plotRect.topLeft()));
}

void SpectrumPlotWidget::updatePlot()
{
  scene->clear();

  if (xData.empty()) return;

  drawAxes();

  QPainterPath path;
  path.moveTo(mapX(xData[0]), mapY(yData[0]));

  for (size_t i = 1; i < xData.size(); i++)
  {
    path.lineTo(mapX(xData[i]), mapY(yData[i]));
  }

  plotItem = scene->addPath(path, QPen(Qt::blue, 2));
}
