#ifndef VIEWPORTMODEL_H
#define VIEWPORTMODEL_H

#include "models/catalogdata.h"
#include <QObject>
#include <QVariantList>

class CatalogData;

class ViewportModel : public QObject {
  Q_OBJECT
  Q_PROPERTY(double viewXMin READ viewXMin NOTIFY viewChanged)
  Q_PROPERTY(double viewXMax READ viewXMax NOTIFY viewChanged)
  Q_PROPERTY(double spectrumCursorX READ spectrumCursorX NOTIFY cursorChanged)
  Q_PROPERTY(double catalogCursorX READ catalogCursorX NOTIFY cursorChanged)
  Q_PROPERTY(bool hasData READ hasData NOTIFY hasDataChanged)
  Q_PROPERTY(QVariantList xTickPositions READ xTickPositions NOTIFY viewChanged)
  Q_PROPERTY(
      QVariantList xMinorPositions READ xMinorPositions NOTIFY viewChanged)
  Q_PROPERTY(bool snapToCatalog READ snapToCatalog WRITE setSnapToCatalog NOTIFY
                 snapSettingsChanged)
  Q_PROPERTY(double snapPixelDistance READ snapPixelDistance WRITE
                 setSnapPixelDistance NOTIFY snapSettingsChanged)
  Q_PROPERTY(CatalogData *catalogData READ catalogData WRITE setCatalogData
                 NOTIFY catalogDataChanged)

public:
  explicit ViewportModel(QObject *parent = nullptr);

  double viewXMin() const { return m_viewXMin; }
  double viewXMax() const { return m_viewXMax; }
  double spectrumCursorX() const { return m_spectrumCursorX; }
  double catalogCursorX() const { return m_catalogCursorX; }
  bool hasData() const { return m_hasData; }
  CatalogData *catalogData() const { return m_catalogData; }
  void setCatalogData(CatalogData *data);
  bool snapToCatalog() const { return m_snapToCatalog; }
  void setSnapToCatalog(bool value);
  double snapPixelDistance() { return m_snapPixelDistance; }
  void setSnapPixelDistance(double value);

  Q_INVOKABLE void setDataBounds(double xMin, double xMax);
  Q_INVOKABLE void clearDataBounds();
  Q_INVOKABLE void resetView();
  Q_INVOKABLE void panX(double delta);
  Q_INVOKABLE void zoomX(double factor);
  Q_INVOKABLE void moveSpectrumCursor(int pixelDelta, double plotWidth);
  Q_INVOKABLE void moveCatalogCursor(int pixelDelta, double plotWidth);
  Q_INVOKABLE QVariantMap lineAtPixel(double pixel, double plotWidth);
  Q_INVOKABLE void cycleLineUp();
  Q_INVOKABLE void cycleLineDown();

  QVariantList xTickPositions() const;
  QVariantList xMinorPositions() const;

signals:
  void viewChanged();
  void cursorChanged();
  void hasDataChanged();
  void snapSettingsChanged();
  void catalogDataChanged();

private:
  double m_viewXMin = 0.0;
  double m_viewXMax = 0.0;
  double m_spectrumCursorX = 0.0;
  double m_catalogCursorX = 0.0;
  double m_dataXMin = 0.0;
  double m_dataXMax = 0.0;
  bool m_hasData = false;
  bool m_snapToCatalog = true;       // enabled by default
  double m_snapPixelDistance = 10.0; // 10px threshold
  CatalogData *m_catalogData = nullptr;
  double m_lastPixel = -1;
  std::vector<int> m_pixelLineIndices;
  int m_currentPixelLineIndex = 0;

  void clampView();
  void clampSpectrumCursor();
  void clampCatalogCursor();
  void updateFromBounds();
};

#endif // VIEWPORTMODEL_H
