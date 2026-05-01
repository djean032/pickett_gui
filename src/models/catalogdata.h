#ifndef CATALOGDATA_H
#define CATALOGDATA_H

#include "parsers/cat_parser.h"
#include "services/spectralfileservice.h"
#include <QObject>
#include <vector>

class CatalogData : public QObject {
  Q_OBJECT
  Q_PROPERTY(double xMin READ xMin NOTIFY dataChanged)
  Q_PROPERTY(double xMax READ xMax NOTIFY dataChanged)
  Q_PROPERTY(double yMax READ yMax NOTIFY dataChanged)
  Q_PROPERTY(QString fileName READ fileName NOTIFY fileNameChanged)
  Q_PROPERTY(bool hasData READ hasData NOTIFY dataChanged)
  Q_PROPERTY(bool isLoading READ isLoading NOTIFY loadingChanged)
  Q_PROPERTY(bool hasError READ hasError NOTIFY errorChanged)
  Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorChanged)
  Q_PROPERTY(bool hasWarning READ hasWarning NOTIFY warningChanged)
  Q_PROPERTY(QString warningMessage READ warningMessage NOTIFY warningChanged)
  Q_PROPERTY(SpectralFileService *fileService READ fileService WRITE
                 setFileService NOTIFY fileServiceChanged)

public:
  explicit CatalogData(QObject *parent = nullptr);

  Q_INVOKABLE void loadFile(const QString &filePath);

  double xMin() const { return m_xMin; }
  double xMax() const { return m_xMax; }
  double yMax() const { return m_yMax; }
  QString fileName() const { return m_fileName; }
  bool hasData() const { return !m_records.empty(); }
  bool isLoading() const { return m_isLoading; }
  bool hasError() const { return m_hasError; }
  QString errorMessage() const { return m_errorMessage; }
  bool hasWarning() const { return m_hasWarning; }
  QString warningMessage() const { return m_warningMessage; }
  SpectralFileService *fileService() const { return m_fileService; }
  void setFileService(SpectralFileService *service);

  const std::vector<pickett::CatRecord> &records() const { return m_records; }

signals:
  void dataChanged();
  void fileNameChanged();
  void loadingChanged();
  void errorChanged();
  void warningChanged();
  void fileServiceChanged();

private slots:
  void onCatLoaded(const SpectralFileService::CatalogNativeResult &result);

private:
  std::vector<pickett::CatRecord> m_records;
  double m_xMin = 0.0;
  double m_xMax = 0.0;
  double m_yMax = 0.0;
  QString m_fileName;
  QString m_pendingFileName;
  SpectralFileService *m_fileService = nullptr;
  quint64 m_pendingRequestId = 0;
  bool m_isLoading = false;
  bool m_hasError = false;
  QString m_errorMessage;
  bool m_hasWarning = false;
  QString m_warningMessage;

  void setLoading(bool loading);
  void clearError();
  void setErrorMessage(const QString &message);
  void clearWarning();
  void setWarningMessage(const QString &message);
};

#endif // CATALOGDATA_H
