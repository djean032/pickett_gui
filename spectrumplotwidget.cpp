#include "spectrumplotwidget.h"

SpectrumPlotWidget::SpectrumPlotWidget(QWidget *parent)
      : QGraphicsView(parent)
      , m_y_min(0.0)
      , m_y_max(0.0)
      , m_view_left(0.0)                // Viewport defaults
      , m_view_right(1.0)
      , m_cursor_idx(0)
      , m_dragging(false)
{
  setViewportUpdateMode(QGraphicsView::FullViewportUpdate);
  setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
  setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOff);

  setBackgroundBrush(QBrush(Qt::black));

  setOptimizationFlags(QGraphicsView::DontSavePainterState);
  setCacheMode(QGraphicsView::CacheNone);

}
