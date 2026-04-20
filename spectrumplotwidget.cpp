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
  setScene(scene);
  scene->setBackgroundBrush(QBrush(Qt::black));
  setRenderHint(QPainter::Antialiasing);
}
