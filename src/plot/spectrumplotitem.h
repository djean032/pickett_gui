#ifndef SPECTRUMPLOTITEM_H
#define SPECTRUMPLOTITEM_H

#include <QQuickItem>
#include <vector>

class SpectrumData;

class SpectrumPlotItem : public QQuickItem {
    Q_OBJECT
    Q_PROPERTY(SpectrumData *data READ data WRITE setData NOTIFY dataChanged)
    Q_PROPERTY(double viewXMin READ viewXMin WRITE setViewXMin NOTIFY viewChanged)
    Q_PROPERTY(double viewXMax READ viewXMax WRITE setViewXMax NOTIFY viewChanged)
    Q_PROPERTY(double viewYMin READ viewYMin WRITE setViewYMin NOTIFY viewChanged)
    Q_PROPERTY(double viewYMax READ viewYMax WRITE setViewYMax NOTIFY viewChanged)
    Q_PROPERTY(double cursorX READ cursorX WRITE setCursorX NOTIFY cursorChanged)
    Q_PROPERTY(bool hasData READ hasData NOTIFY dataChanged)
    Q_PROPERTY(QVariantList xTickPositions READ xTickPositions NOTIFY viewChanged)
    Q_PROPERTY(QVariantList xMinorPositions READ xMinorPositions NOTIFY viewChanged)

public:
    explicit SpectrumPlotItem(QQuickItem *parent = nullptr);

    SpectrumData *data() const;
    void setData(SpectrumData *data);

    double viewXMin() const;
    void setViewXMin(double value);
    double viewXMax() const;
    void setViewXMax(double value);
    double viewYMin() const;
    void setViewYMin(double value);
    double viewYMax() const;
    void setViewYMax(double value);

    double cursorX() const;
    void setCursorX(double value);

    Q_INVOKABLE void resetView();
    Q_INVOKABLE void panX(double delta);
    Q_INVOKABLE void panY(double delta);
    Q_INVOKABLE void zoomX(double factor);
    Q_INVOKABLE void zoomY(double factor);
    Q_INVOKABLE void moveCursor(int pixelDelta);

    bool hasData() const;

    QVariantList xTickPositions() const;
    QVariantList xMinorPositions() const;

signals:
    void dataChanged();
    void viewChanged();
    void cursorChanged();

protected:
    QSGNode *updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *data) override;

private:
    SpectrumData *m_data = nullptr;
    bool m_dataDirty = true;

    double m_viewXMin = 0.0;
    double m_viewXMax = 0.0;
    double m_viewYMin = 0.0;
    double m_viewYMax = 0.0;
    double m_cursorX = 0.0;

    void onDataChanged();
    void syncViewToData();
    void clampView();
    void clampCursor();
};

#endif // SPECTRUMPLOTITEM_H