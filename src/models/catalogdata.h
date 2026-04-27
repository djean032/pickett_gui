#ifndef CATALOGDATA_H
#define CATALOGDATA_H

#include "parsers/cat_parser.h"
#include <QObject>
#include <vector>

class CatalogData : public QObject {
  Q_OBJECT
  Q_PROPERTY(double xMin READ xMin NOTIFY dataChanged)
  Q_PROPERTY(double xMax READ xMax NOTIFY dataChanged)
  Q_PROPERTY(double yMax READ yMax NOTIFY dataChanged)
  Q_PROPERTY(QString fileName READ fileName NOTIFY fileNameChanged)
  Q_PROPERTY(bool hasData READ hasData NOTIFY dataChanged)

public:
  explicit CatalogData(QObject *parent = nullptr);

  Q_INVOKABLE void loadFile(const QString &filePath);

  double xMin() const { return m_xMin; }
  double xMax() const { return m_xMax; }
  double yMax() const { return m_yMax; }
  QString fileName() const { return m_fileName; }
  bool hasData() const { return !m_records.empty(); }

  const std::vector<pickett::CatRecord> &records() const { return m_records; }

signals:
  void dataChanged();
  void fileNameChanged();

private:
  std::vector<pickett::CatRecord> m_records;
  double m_xMin = 0.0;
  double m_xMax = 0.0;
  double m_yMax = 0.0;
  QString m_fileName;
};

#endif // CATALOGDATA_H
