#ifndef SPECTRUMPLOTITEM_H
#define SPECTRUMPLOTITEM_H

#include <QQuickItem>
#include <vector>

class SpectrumData;
class ViewportModel;

class SpectrumPlotItem : public QQuickItem {
  Q_OBJECT
  Q_PROPERTY(SpectrumData *data READ data WRITE setData NOTIFY dataChanged)
  Q_PROPERTY(ViewportModel *viewport READ viewport WRITE setViewport NOTIFY
                 viewportChanged)
  Q_PROPERTY(
      double viewYMin READ viewYMin WRITE setViewYMin NOTIFY viewYChanged)
  Q_PROPERTY(
      double viewYMax READ viewYMax WRITE setViewYMax NOTIFY viewYChanged)
  Q_PROPERTY(bool hasData READ hasData NOTIFY dataChanged)

public:
  explicit SpectrumPlotItem(QQuickItem *parent = nullptr);

  SpectrumData *data() const;
  void setData(SpectrumData *data);

  ViewportModel *viewport() const;
  void setViewport(ViewportModel *viewport);

  double viewYMin() const;
  void setViewYMin(double value);
  double viewYMax() const;
  void setViewYMax(double value);

  bool hasData() const;

  Q_INVOKABLE void panY(double delta);
  Q_INVOKABLE void zoomY(double factor);

signals:
  void dataChanged();
  void viewportChanged();
  void viewYChanged();

protected:
  QSGNode *updatePaintNode(QSGNode *oldNode,
                           UpdatePaintNodeData *data) override;

private:
  SpectrumData *m_data = nullptr;
  ViewportModel *m_viewport = nullptr;
  bool m_dataDirty = true;

  double m_viewYMin = 0.0;
  double m_viewYMax = 0.0;

  void onDataChanged();
  void syncViewToData();
  void clampYView();
};

#endif // SPECTRUMPLOTITEM_H
