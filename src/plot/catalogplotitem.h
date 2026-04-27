#ifndef CATALOGPLOTITEM_H
#define CATALOGPLOTITEM_H

#include <QQuickItem>

class ViewportModel;
class CatalogData;

class CatalogPlotItem : public QQuickItem {
  Q_OBJECT
  Q_PROPERTY(ViewportModel *viewport READ viewport WRITE setViewport NOTIFY
                 viewportChanged)
  Q_PROPERTY(CatalogData *catalogData READ catalogData WRITE setCatalogData
                 NOTIFY catalogDataChanged)
  Q_PROPERTY(bool hasData READ hasData NOTIFY catalogDataChanged)

public:
  explicit CatalogPlotItem(QQuickItem *parent = nullptr);

  ViewportModel *viewport() const;
  void setViewport(ViewportModel *viewport);

  CatalogData *catalogData() const;
  void setCatalogData(CatalogData *data);

  bool hasData() const;

signals:
  void viewportChanged();
  void catalogDataChanged();

protected:
  QSGNode *updatePaintNode(QSGNode *oldNode,
                           UpdatePaintNodeData *data) override;

private slots:
  void onCatalogDataChanged();

private:
  ViewportModel *m_viewport = nullptr;
  CatalogData *m_catalogData = nullptr;
  bool m_dataDirty = true;
};

#endif // CATALOGPLOTITEM_H
