#include <catch2/catch_test_macros.hpp>

#include "models/catalogdata.h"
#include "models/spectrumdata.h"
#include "services/spectralfileservice.h"

#include <QCoreApplication>
#include <QElapsedTimer>
#include <QEventLoop>
#include <QMetaObject>
#include <QThread>

namespace {

QCoreApplication &ensureApp() {
  static int argc = 1;
  static char appName[] = "test_parsers";
  static char *argv[] = {appName, nullptr};
  static QCoreApplication app(argc, argv);
  return app;
}

QString testDataPath(const char *fileName) {
  return QString::fromUtf8(TEST_DATA_DIR) + "/" + QString::fromUtf8(fileName);
}

template <typename Predicate>
bool waitForCondition(Predicate predicate, int timeoutMs) {
  ensureApp();

  QElapsedTimer timer;
  timer.start();

  while (!predicate()) {
    QCoreApplication::processEvents(QEventLoop::AllEvents, 10);
    if (timer.elapsed() > timeoutMs) {
      return false;
    }
    QThread::msleep(1);
  }

  return true;
}

} // namespace

TEST_CASE("SpectrumData reports and clears load errors", "[model]") {
  SpectralFileService service;
  SpectrumData spectrum;
  spectrum.setFileService(&service);

  spectrum.loadFile("missing_file.spe");
  REQUIRE(waitForCondition([&]() { return !spectrum.isLoading(); }, 5000));
  CHECK(spectrum.hasError());
  CHECK(!spectrum.errorMessage().isEmpty());
  CHECK(!spectrum.hasWarning());

  spectrum.loadFile(testDataPath("cyanomethylenecyclopropane_235-500GHz_bin.spe"));
  REQUIRE(waitForCondition([&]() { return !spectrum.isLoading(); }, 120000));
  CHECK(spectrum.hasData());
  CHECK(!spectrum.hasError());
  CHECK(spectrum.errorMessage().isEmpty());
}

TEST_CASE("CatalogData reports and clears load errors", "[model]") {
  SpectralFileService service;
  CatalogData catalog;
  catalog.setFileService(&service);

  catalog.loadFile("missing_file.cat");
  REQUIRE(waitForCondition([&]() { return !catalog.isLoading(); }, 5000));
  CHECK(catalog.hasError());
  CHECK(!catalog.errorMessage().isEmpty());
  CHECK(!catalog.hasWarning());

  catalog.loadFile(testDataPath("cyanomethcycloprop.cat"));
  REQUIRE(waitForCondition([&]() { return !catalog.isLoading(); }, 10000));
  CHECK(catalog.hasData());
  CHECK(!catalog.hasError());
  CHECK(catalog.errorMessage().isEmpty());
}

TEST_CASE("Models surface non-fatal parse warnings", "[model]") {
  SECTION("SpectrumData warning state") {
    SpectrumData spectrum;

    SpectralFileService::SpectrumNativeResult result;
    result.requestId = 0;
    result.fStartMHz = 100.0;
    result.fIncrMHz = 0.5;
    result.intensities.push_back(1);

    ParserError warning;
    warning.code = ParserErrorCode::InvalidHeader;
    warning.domain = ParserDomain::Spe;
    warning.message = "Header field appears out of range";
    warning.isFatal = false;
    result.errors.push_back(warning);

    const bool invoked = QMetaObject::invokeMethod(
        &spectrum, "onSpeLoaded", Qt::DirectConnection,
        Q_ARG(SpectralFileService::SpectrumNativeResult, result));
    REQUIRE(invoked);

    CHECK(spectrum.hasWarning());
    CHECK(!spectrum.warningMessage().isEmpty());
    CHECK(!spectrum.hasError());
  }

  SECTION("CatalogData warning state") {
    CatalogData catalog;

    SpectralFileService::CatalogNativeResult result;
    result.requestId = 0;

    pickett::CatRecord line;
    line.freq = 100.0;
    line.err = 0.0;
    line.lgint = -1.0;
    line.elo = 0.0;
    result.records.push_back(line);

    ParserError warning;
    warning.code = ParserErrorCode::InvalidRecord;
    warning.domain = ParserDomain::Cat;
    warning.message = "Skipped malformed catalog line";
    warning.isFatal = false;
    result.errors.push_back(warning);

    const bool invoked = QMetaObject::invokeMethod(
        &catalog, "onCatLoaded", Qt::DirectConnection,
        Q_ARG(SpectralFileService::CatalogNativeResult, result));
    REQUIRE(invoked);

    CHECK(catalog.hasWarning());
    CHECK(!catalog.warningMessage().isEmpty());
    CHECK(!catalog.hasError());
  }
}
