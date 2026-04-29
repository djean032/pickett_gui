#include <catch2/catch_test_macros.hpp>
#include <catch2/matchers/catch_matchers_floating_point.hpp>

#include "models/viewportmodel.h"

using Catch::Matchers::WithinAbs;

TEST_CASE("ViewportModel cursor movement rules", "[viewport]") {
  ViewportModel viewport;
  viewport.setDataBounds(100.0, 200.0);
  viewport.setSnapToCatalog(false);

  const double plotWidth = 1000.0;

  SECTION("Spectrum cursor movement does not affect catalog cursor") {
    CHECK_THAT(viewport.spectrumCursorX(), WithinAbs(150.0, 1e-12));
    CHECK_THAT(viewport.catalogCursorX(), WithinAbs(150.0, 1e-12));

    viewport.moveSpectrumCursor(10, plotWidth);

    CHECK_THAT(viewport.spectrumCursorX(), WithinAbs(151.0, 1e-12));
    CHECK_THAT(viewport.catalogCursorX(), WithinAbs(150.0, 1e-12));
  }

  SECTION("Catalog cursor movement also moves spectrum cursor") {
    CHECK_THAT(viewport.spectrumCursorX(), WithinAbs(150.0, 1e-12));
    CHECK_THAT(viewport.catalogCursorX(), WithinAbs(150.0, 1e-12));

    viewport.moveCatalogCursor(-20, plotWidth);

    CHECK_THAT(viewport.catalogCursorX(), WithinAbs(148.0, 1e-12));
    CHECK_THAT(viewport.spectrumCursorX(), WithinAbs(148.0, 1e-12));
  }
}

TEST_CASE("ViewportModel resetView recenters both cursors", "[viewport]") {
  ViewportModel viewport;
  viewport.setDataBounds(10.0, 110.0);
  viewport.setSnapToCatalog(false);

  const double plotWidth = 1000.0;

  viewport.moveSpectrumCursor(100, plotWidth);
  viewport.moveCatalogCursor(-50, plotWidth);

  CHECK_THAT(viewport.spectrumCursorX(), WithinAbs(55.0, 1e-12));
  CHECK_THAT(viewport.catalogCursorX(), WithinAbs(55.0, 1e-12));

  viewport.resetView();

  CHECK_THAT(viewport.spectrumCursorX(), WithinAbs(60.0, 1e-12));
  CHECK_THAT(viewport.catalogCursorX(), WithinAbs(60.0, 1e-12));
}

TEST_CASE("ViewportModel pans at edges with cursor coupling rules", "[viewport]") {
  ViewportModel viewport;
  viewport.setDataBounds(0.0, 100.0);
  viewport.setSnapToCatalog(false);

  const double plotWidth = 1000.0;

  SECTION("Spectrum cursor crossing right edge clamps without panning") {
    // Start from center for both cursors.
    CHECK_THAT(viewport.spectrumCursorX(), WithinAbs(50.0, 1e-12));
    CHECK_THAT(viewport.catalogCursorX(), WithinAbs(50.0, 1e-12));

    // Move spectrum cursor far enough to cross right edge.
    viewport.moveSpectrumCursor(600, plotWidth);

    // View should remain unchanged.
    CHECK_THAT(viewport.viewXMin(), WithinAbs(0.0, 1e-12));
    CHECK_THAT(viewport.viewXMax(), WithinAbs(100.0, 1e-12));

    // Spectrum cursor clamps to right edge.
    CHECK_THAT(viewport.spectrumCursorX(), WithinAbs(100.0, 1e-12));

    // Catalog cursor remains unchanged.
    CHECK_THAT(viewport.catalogCursorX(), WithinAbs(50.0, 1e-12));
  }

  SECTION("Catalog cursor crossing left edge pans and carries spectrum") {
    CHECK_THAT(viewport.spectrumCursorX(), WithinAbs(50.0, 1e-12));
    CHECK_THAT(viewport.catalogCursorX(), WithinAbs(50.0, 1e-12));

    viewport.moveCatalogCursor(-600, plotWidth);

    CHECK_THAT(viewport.viewXMin(), WithinAbs(0.0, 1e-12));
    CHECK_THAT(viewport.viewXMax(), WithinAbs(100.0, 1e-12));
    CHECK_THAT(viewport.catalogCursorX(), WithinAbs(100.0, 1e-12));
    CHECK_THAT(viewport.spectrumCursorX(), WithinAbs(100.0, 1e-12));
  }
}
