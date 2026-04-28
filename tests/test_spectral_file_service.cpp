#include <catch2/catch_test_macros.hpp>

#include "services/spectralfileservice.h"

#include <QCoreApplication>
#include <QElapsedTimer>
#include <QEventLoop>
#include <QThread>

#include <fstream>

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

TEST_CASE("SpectralFileService synchronous loading", "[service]") {
  SpectralFileService service;

  SECTION("SPE success") {
    const auto result = service.loadSpe(
        testDataPath("cyanomethylenecyclopropane_235-500GHz_bin.spe"));

    REQUIRE(result.has_value());
    CHECK(!result->points.isEmpty());
    CHECK(result->errors.isEmpty());
    CHECK(result->requestId == 0);
  }

  SECTION("CAT success") {
    const auto result = service.loadCat(testDataPath("cyanomethcycloprop.cat"));

    REQUIRE(result.has_value());
    CHECK(!result->lines.isEmpty());
    CHECK(result->errors.isEmpty());
    CHECK(result->requestId == 0);
  }

  SECTION("LIN success") {
    const auto result = service.loadLin(testDataPath("cyanomethcycloprop.lin"));

    REQUIRE(result.has_value());
    CHECK(!result->lines.isEmpty());
    CHECK(result->errors.isEmpty());
    CHECK(result->requestId == 0);
  }

  SECTION("SPE failure") {
    const auto result = service.loadSpe("nonexistent_file.spe");

    CHECK(!result.has_value());
    REQUIRE(!result.error().errors.isEmpty());
    CHECK(result.error().errors[0].code == ParserErrorCode::FileNotFound);
    CHECK(result.error().errors[0].domain == ParserDomain::Common);
    CHECK(result.error().domain == ParserDomain::Common);
  }

  SECTION("CAT failure") {
    const auto result = service.loadCat("nonexistent_file.cat");

    CHECK(!result.has_value());
    REQUIRE(!result.error().errors.isEmpty());
    CHECK(result.error().errors[0].code == ParserErrorCode::FileNotFound);
    CHECK(result.error().errors[0].domain == ParserDomain::Common);
    CHECK(result.error().domain == ParserDomain::Common);
  }

  SECTION("LIN failure") {
    const auto result = service.loadLin("nonexistent_file.lin");

    CHECK(!result.has_value());
    REQUIRE(!result.error().errors.isEmpty());
    CHECK(result.error().errors[0].code == ParserErrorCode::FileNotFound);
    CHECK(result.error().errors[0].domain == ParserDomain::Common);
    CHECK(result.error().domain == ParserDomain::Common);
  }

  SECTION("SPE invalid format maps to typed domain error") {
    const QString invalidPath = testDataPath("service_invalid_tiny.spe");
    {
      std::ofstream out(invalidPath.toStdString(), std::ios::binary);
      out.write("abc", 3);
    }

    const auto result = service.loadSpe(invalidPath);

    CHECK(!result.has_value());
    REQUIRE(!result.error().errors.isEmpty());
    CHECK(result.error().errors[0].code == ParserErrorCode::InvalidFormat);
    CHECK(result.error().errors[0].domain == ParserDomain::Spe);
    CHECK(result.error().domain == ParserDomain::Spe);
  }
}

TEST_CASE("SpectralFileService asynchronous loading", "[service]") {
  ensureApp();
  SpectralFileService service;

  SECTION("SPE success") {
    bool done = false;
    SpectralFileService::SpectrumResult received;
    QObject::connect(&service, &SpectralFileService::speLoaded,
                     [&](const SpectralFileService::SpectrumResult &result) {
                       received = result;
                       done = true;
                     });

    const quint64 requestId = service.loadSpeAsync(
        testDataPath("cyanomethylenecyclopropane_235-500GHz_bin.spe"));

    REQUIRE(waitForCondition([&]() { return done; }, 120000));
    CHECK(received.requestId == requestId);
    CHECK(!received.points.isEmpty());
    CHECK(received.errors.isEmpty());
  }

  SECTION("CAT success") {
    bool done = false;
    SpectralFileService::CatalogResult received;
    QObject::connect(&service, &SpectralFileService::catLoaded,
                     [&](const SpectralFileService::CatalogResult &result) {
                       received = result;
                       done = true;
                     });

    const quint64 requestId = service.loadCatAsync(testDataPath("cyanomethcycloprop.cat"));

    REQUIRE(waitForCondition([&]() { return done; }, 10000));
    CHECK(received.requestId == requestId);
    CHECK(!received.lines.isEmpty());
    CHECK(received.errors.isEmpty());
  }

  SECTION("LIN success") {
    bool done = false;
    SpectralFileService::LinResult received;
    QObject::connect(&service, &SpectralFileService::linLoaded,
                     [&](const SpectralFileService::LinResult &result) {
                       received = result;
                       done = true;
                     });

    const quint64 requestId = service.loadLinAsync(testDataPath("cyanomethcycloprop.lin"));

    REQUIRE(waitForCondition([&]() { return done; }, 10000));
    CHECK(received.requestId == requestId);
    CHECK(!received.lines.isEmpty());
    CHECK(received.errors.isEmpty());
  }

  SECTION("SPE failure") {
    bool done = false;
    SpectralFileService::SpectrumResult received;
    QObject::connect(&service, &SpectralFileService::speLoaded,
                     [&](const SpectralFileService::SpectrumResult &result) {
                       received = result;
                       done = true;
                     });

    const quint64 requestId = service.loadSpeAsync("nonexistent_file.spe");

    REQUIRE(waitForCondition([&]() { return done; }, 5000));
    CHECK(received.requestId == requestId);
    CHECK(received.points.isEmpty());
    REQUIRE(!received.errors.isEmpty());
    CHECK(received.errors[0].code == ParserErrorCode::FileNotFound);
    CHECK(received.errors[0].domain == ParserDomain::Common);
    CHECK(received.sourcePath == QStringLiteral("nonexistent_file.spe"));
  }

  SECTION("CAT failure") {
    bool done = false;
    SpectralFileService::CatalogResult received;
    QObject::connect(&service, &SpectralFileService::catLoaded,
                     [&](const SpectralFileService::CatalogResult &result) {
                       received = result;
                       done = true;
                     });

    const quint64 requestId = service.loadCatAsync("nonexistent_file.cat");

    REQUIRE(waitForCondition([&]() { return done; }, 5000));
    CHECK(received.requestId == requestId);
    CHECK(received.lines.isEmpty());
    REQUIRE(!received.errors.isEmpty());
    CHECK(received.errors[0].code == ParserErrorCode::FileNotFound);
    CHECK(received.errors[0].domain == ParserDomain::Common);
    CHECK(received.sourcePath == QStringLiteral("nonexistent_file.cat"));
  }

  SECTION("LIN failure") {
    bool done = false;
    SpectralFileService::LinResult received;
    QObject::connect(&service, &SpectralFileService::linLoaded,
                     [&](const SpectralFileService::LinResult &result) {
                       received = result;
                       done = true;
                     });

    const quint64 requestId = service.loadLinAsync("nonexistent_file.lin");

    REQUIRE(waitForCondition([&]() { return done; }, 5000));
    CHECK(received.requestId == requestId);
    CHECK(received.lines.isEmpty());
    REQUIRE(!received.errors.isEmpty());
    CHECK(received.errors[0].code == ParserErrorCode::FileNotFound);
    CHECK(received.errors[0].domain == ParserDomain::Common);
    CHECK(received.sourcePath == QStringLiteral("nonexistent_file.lin"));
  }

  SECTION("SPE invalid format async maps to typed domain error") {
    const QString invalidPath = testDataPath("service_invalid_tiny_async.spe");
    {
      std::ofstream out(invalidPath.toStdString(), std::ios::binary);
      out.write("xyz", 3);
    }

    bool done = false;
    SpectralFileService::SpectrumResult received;
    QObject::connect(&service, &SpectralFileService::speLoaded,
                     [&](const SpectralFileService::SpectrumResult &result) {
                       received = result;
                       done = true;
                     });

    const quint64 requestId = service.loadSpeAsync(invalidPath);

    REQUIRE(waitForCondition([&]() { return done; }, 5000));
    CHECK(received.requestId == requestId);
    CHECK(received.points.isEmpty());
    REQUIRE(!received.errors.isEmpty());
    CHECK(received.errors[0].code == ParserErrorCode::InvalidFormat);
    CHECK(received.errors[0].domain == ParserDomain::Spe);
  }
}
