#ifndef SPECTRUMDATA_H
#define SPECTRUMDATA_H

#include <QObject>
#include <vector>

class SpectrumData : public QObject {
  Q_OBJECT
  Q_PROPERTY(double xMin READ xMin NOTIFY dataChanged)
  Q_PROPERTY(double xMax READ xMax NOTIFY dataChanged)
  Q_PROPERTY(double yMin READ yMin NOTIFY dataChanged)
  Q_PROPERTY(double yMax READ yMax NOTIFY dataChanged)
  Q_PROPERTY(QString fileName READ fileName NOTIFY fileNameChanged)
  Q_PROPERTY(bool hasData READ hasData NOTIFY dataChanged)

public:
  explicit SpectrumData(QObject *parent = nullptr);

  Q_INVOKABLE void loadFile(const QString &filePath);
  Q_INVOKABLE void clearData();

  const std::vector<double> &xData() const;
  const std::vector<double> &yData() const;
  double xMin() const;
  double xMax() const;
  double yMin() const;
  double yMax() const;
  QString fileName() const;
  bool hasData() const;

signals:
  void dataChanged();
  void fileNameChanged();

private:
  std::vector<double> m_xData;
  std::vector<double> m_yData;
  double m_xMin = 0.0;
  double m_xMax = 0.0;
  double m_yMin = 0.0;
  double m_yMax = 0.0;
  QString m_fileName;

  void decimate(const std::vector<double> &freqs,
                const std::vector<double> &intensities);
};

#endif // SPECTRUMDATA_H
