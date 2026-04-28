#ifndef SPECTRALFILESERVICE_H
#define SPECTRALFILESERVICE_H

#include "errors/parser_error.h"

#include <QObject>
#include <QString>
#include <QVector>
#include <QtGlobal>

class SpectralFileService : public QObject {
  Q_OBJECT

public:
  struct SpectrumPoint {
    double frequencyMHz = 0.0;
    double intensity = 0.0;
  };

  struct SpectrumResult {
    bool success = false;
    quint64 requestId = 0;
    QString sourcePath;
    QVector<SpectrumPoint> points;
    double fStartMHz = 0.0;
    double fEndMHz = 0.0;
    double fIncrMHz = 0.0;
    QVector<ParserError> errors;
  };

  struct CatalogLine {
    double freq = 0.0;
    double err = 0.0;
    double lgint = 0.0;
    double elo = 0.0;
    int dr = 0;
    int gup = 0;
    int tag = 0;
    int qnfmt = 0;
    QVector<int> qn;
  };

  struct CatalogResult {
    bool success = false;
    quint64 requestId = 0;
    QString sourcePath;
    QVector<CatalogLine> lines;
    QVector<ParserError> errors;
  };

  struct LinLine {
    QVector<int> qn;
    double freq = 0.0;
    double err = 0.0;
    double wt = 0.0;
  };

  struct LinResult {
    bool success = false;
    quint64 requestId = 0;
    QString sourcePath;
    QVector<LinLine> lines;
    QVector<ParserError> errors;
  };

  explicit SpectralFileService(QObject *parent = nullptr);

  SpectrumResult loadSpe(const QString &filePath) const;
  CatalogResult loadCat(const QString &filePath) const;
  LinResult loadLin(const QString &filePath) const;

  quint64 loadSpeAsync(const QString &filePath);
  quint64 loadCatAsync(const QString &filePath);
  quint64 loadLinAsync(const QString &filePath);

signals:
  void speLoaded(const SpectralFileService::SpectrumResult &result);
  void catLoaded(const SpectralFileService::CatalogResult &result);
  void linLoaded(const SpectralFileService::LinResult &result);

private:
  quint64 nextRequestId();
};

Q_DECLARE_METATYPE(SpectralFileService::SpectrumPoint)
Q_DECLARE_METATYPE(SpectralFileService::SpectrumResult)
Q_DECLARE_METATYPE(SpectralFileService::CatalogLine)
Q_DECLARE_METATYPE(SpectralFileService::CatalogResult)
Q_DECLARE_METATYPE(SpectralFileService::LinLine)
Q_DECLARE_METATYPE(SpectralFileService::LinResult)

#endif // SPECTRALFILESERVICE_H
