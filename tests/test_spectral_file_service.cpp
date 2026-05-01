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

  SECTION("SPE native success") {
    const auto result = service.loadSpeNative(
        testDataPath("cyanomethylenecyclopropane_235-500GHz_bin.spe"));

    REQUIRE(result.has_value());
    CHECK(!result->intensities.empty());
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

  SECTION("CAT native success") {
    const auto result = service.loadCatNative(testDataPath("cyanomethcycloprop.cat"));

    REQUIRE(result.has_value());
    CHECK(!result->records.empty());
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

  SECTION("SPE native failure") {
    const auto legacy = service.loadSpe("nonexistent_file.spe");
    const auto native = service.loadSpeNative("nonexistent_file.spe");

    CHECK(!native.has_value());
    CHECK(!legacy.has_value());
    REQUIRE(!native.error().errors.isEmpty());
    REQUIRE(!legacy.error().errors.isEmpty());
    CHECK(native.error().errors[0].code == legacy.error().errors[0].code);
    CHECK(native.error().errors[0].domain == legacy.error().errors[0].domain);
    CHECK(native.error().domain == legacy.error().domain);
  }

  SECTION("CAT failure") {
    const auto result = service.loadCat("nonexistent_file.cat");

    CHECK(!result.has_value());
    REQUIRE(!result.error().errors.isEmpty());
    CHECK(result.error().errors[0].code == ParserErrorCode::FileNotFound);
    CHECK(result.error().errors[0].domain == ParserDomain::Common);
    CHECK(result.error().domain == ParserDomain::Common);
  }

  SECTION("CAT native failure") {
    const auto legacy = service.loadCat("nonexistent_file.cat");
    const auto native = service.loadCatNative("nonexistent_file.cat");

    CHECK(!native.has_value());
    CHECK(!legacy.has_value());
    REQUIRE(!native.error().errors.isEmpty());
    REQUIRE(!legacy.error().errors.isEmpty());
    CHECK(native.error().errors[0].code == legacy.error().errors[0].code);
    CHECK(native.error().errors[0].domain == legacy.error().errors[0].domain);
    CHECK(native.error().domain == legacy.error().domain);
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

  SECTION("SPE native invalid format maps to typed domain error") {
    const QString invalidPath = testDataPath("service_invalid_tiny_native.spe");
    {
      std::ofstream out(invalidPath.toStdString(), std::ios::binary);
      out.write("abc", 3);
    }

    const auto legacy = service.loadSpe(invalidPath);
    const auto native = service.loadSpeNative(invalidPath);

    CHECK(!native.has_value());
    CHECK(!legacy.has_value());
    REQUIRE(!native.error().errors.isEmpty());
    REQUIRE(!legacy.error().errors.isEmpty());
    CHECK(native.error().errors[0].code == legacy.error().errors[0].code);
    CHECK(native.error().errors[0].domain == legacy.error().errors[0].domain);
    CHECK(native.error().domain == legacy.error().domain);
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

  SECTION("SPE native success") {
    bool done = false;
    SpectralFileService::SpectrumNativeResult received;
    QObject::connect(&service, &SpectralFileService::speNativeLoaded,
                     [&](const SpectralFileService::SpectrumNativeResult &result) {
                       received = result;
                       done = true;
                     });

    const quint64 requestId = service.loadSpeNativeAsync(
        testDataPath("cyanomethylenecyclopropane_235-500GHz_bin.spe"));

    REQUIRE(waitForCondition([&]() { return done; }, 120000));
    CHECK(received.requestId == requestId);
    CHECK(!received.intensities.empty());
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

  SECTION("CAT native success") {
    bool done = false;
    SpectralFileService::CatalogNativeResult received;
    QObject::connect(&service, &SpectralFileService::catNativeLoaded,
                     [&](const SpectralFileService::CatalogNativeResult &result) {
                       received = result;
                       done = true;
                     });

    const quint64 requestId = service.loadCatNativeAsync(testDataPath("cyanomethcycloprop.cat"));

    REQUIRE(waitForCondition([&]() { return done; }, 10000));
    CHECK(received.requestId == requestId);
    CHECK(!received.records.empty());
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

  SECTION("SPE native failure") {
    bool done = false;
    SpectralFileService::SpectrumNativeResult received;
    QObject::connect(&service, &SpectralFileService::speNativeLoaded,
                     [&](const SpectralFileService::SpectrumNativeResult &result) {
                       received = result;
                       done = true;
                     });

    const quint64 requestId = service.loadSpeNativeAsync("nonexistent_file.spe");

    REQUIRE(waitForCondition([&]() { return done; }, 5000));
    CHECK(received.requestId == requestId);
    CHECK(received.intensities.empty());
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

  SECTION("CAT native failure") {
    bool done = false;
    SpectralFileService::CatalogNativeResult received;
    QObject::connect(&service, &SpectralFileService::catNativeLoaded,
                     [&](const SpectralFileService::CatalogNativeResult &result) {
                       received = result;
                       done = true;
                     });

    const quint64 requestId = service.loadCatNativeAsync("nonexistent_file.cat");

    REQUIRE(waitForCondition([&]() { return done; }, 5000));
    CHECK(received.requestId == requestId);
    CHECK(received.records.empty());
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

  SECTION("SPE native invalid format async maps to typed domain error") {
    const QString invalidPath = testDataPath("service_invalid_tiny_async_native.spe");
    {
      std::ofstream out(invalidPath.toStdString(), std::ios::binary);
      out.write("xyz", 3);
    }

    bool done = false;
    SpectralFileService::SpectrumNativeResult received;
    QObject::connect(&service, &SpectralFileService::speNativeLoaded,
                     [&](const SpectralFileService::SpectrumNativeResult &result) {
                       received = result;
                       done = true;
                     });

    const quint64 requestId = service.loadSpeNativeAsync(invalidPath);

    REQUIRE(waitForCondition([&]() { return done; }, 5000));
    CHECK(received.requestId == requestId);
    CHECK(received.intensities.empty());
    REQUIRE(!received.errors.isEmpty());
    CHECK(received.errors[0].code == ParserErrorCode::InvalidFormat);
    CHECK(received.errors[0].domain == ParserDomain::Spe);
  }
}
