#ifndef SPECTRUMDATA_H
#define SPECTRUMDATA_H

#include "services/spectralfileservice.h"
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
  Q_PROPERTY(bool isLoading READ isLoading NOTIFY loadingChanged)
  Q_PROPERTY(bool hasError READ hasError NOTIFY errorChanged)
  Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorChanged)
  Q_PROPERTY(bool hasWarning READ hasWarning NOTIFY warningChanged)
  Q_PROPERTY(QString warningMessage READ warningMessage NOTIFY warningChanged)
  Q_PROPERTY(SpectralFileService *fileService READ fileService WRITE
                 setFileService NOTIFY fileServiceChanged)

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
  bool isLoading() const;
  bool hasError() const;
  QString errorMessage() const;
  bool hasWarning() const;
  QString warningMessage() const;
  SpectralFileService *fileService() const;
  void setFileService(SpectralFileService *service);

signals:
  void dataChanged();
  void fileNameChanged();
  void loadingChanged();
  void errorChanged();
  void warningChanged();
  void fileServiceChanged();

private slots:
  void onSpeLoaded(const SpectralFileService::SpectrumNativeResult &result);

private:
  std::vector<double> m_xData;
  std::vector<double> m_yData;
  double m_xMin = 0.0;
  double m_xMax = 0.0;
  double m_yMin = 0.0;
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

  void decimate(const std::vector<double> &freqs,
                const std::vector<double> &intensities);
  void setLoading(bool loading);
  void clearError();
  void setErrorMessage(const QString &message);
  void clearWarning();
  void setWarningMessage(const QString &message);
};

#endif // SPECTRUMDATA_H
