#ifndef SPECTRUMPLOTWIDGET_H
#define SPECTRUMPLOTWIDGET_H

#include <QGraphicsView>
#include <QGraphicsScene>
#include <QGraphicsPathItem>
#include <vector>

class SpectrumPlotWidget : public QGraphicsView {
  Q_OBJECT
public:
  explicit SpectrumPlotWidget(QWidget *parent = nullptr);
  void setSpectrum(const std::vector<double> &freqs,
                   const std::vector<double> &intensities);
protected:
  void resizeEvent(QResizeEvent *event) override;

private:
  // Data
  std::vector<double> m_freqs;
  std::vector<double> m_intens;
  double m_y_min, m_y_max;  // Fixed Y range

  // View state
  double m_view_left, m_view_right;  // Visible frequency range
  int m_cursor_idx = 0;

  QGraphicsScene *scene;
  QGraphicsPathItem *plotItem;

  std::vector<double> xData, yData;

  // Margins
  int marginLeft = 50;
  int marginBottom = 40;
  int marginTop = 40;
  int marginRight = 20;

  QRectF plotRect;

  // Methods
  double mapX(double xVal) const;
  double mapY(double yVal) const;
  void updatePlot();
  void drawAxes();
  void clampView();
  void updateCursorDisplay();
};

#endif // SPECTRUMPLOTWIDGET_H
