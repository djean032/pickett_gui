#ifndef SPECTRUMPLOTWIDGET_H
#define SPECTRUMPLOTWIDGET_H

#include <QGraphicsView>

class SpectrumPlotWidget : public QGraphicsView {
  Q_OBJECT
public:
  explicit SpectrumPlotWidget(QWidget *parent = nullptr);
  void setSpectrum(const std::vector<double> &freqs,
                   const std::vector<double> &intensities);
protected:
  void paintEvent(QPaintEvent *event) override;
  void keyPressEvent(QKeyEvent *event) override;
  void wheelEvent(QWheelEvent *event) override;
  void mousePressEvent(QMouseEvent *event) override;
  void mouseMoveEvent(QMouseEvent *event) override;
private:
  // Data
  std::vector<double> m_freqs;
  std::vector<double> m_intens;
  double m_y_min, m_y_max;  // Fixed Y range

  // View state
  double m_view_left, m_view_right;  // Visible frequency range
  int m_cursor_idx = 0;

  // Mouse interaction
  bool m_dragging = false;
  QPoint m_last_mouse_pos;

  // Methods
  void clampView();
  void updateCursorDisplay();
};

#endif // SPECTRUMPLOTWIDGET_H
