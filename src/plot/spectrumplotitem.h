#ifndef SPECTRUMPLOTITEM_H
#define SPECTRUMPLOTITEM_H

#include <QQuickItem>
#include <vector>

class SpectrumData;

class SpectrumPlotItem : public QQuickItem {
    Q_OBJECT
    Q_PROPERTY(SpectrumData *data READ data WRITE setData NOTIFY dataChanged)

public:
    explicit SpectrumPlotItem(QQuickItem *parent = nullptr);

    SpectrumData *data() const;
    void setData(SpectrumData *data);

signals:
    void dataChanged();

protected:
    QSGNode *updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *data) override;

private:
    SpectrumData *m_data = nullptr;
    bool m_dataDirty = true;

    void onDataChanged();
};

#endif // SPECTRUMPLOTITEM_H
