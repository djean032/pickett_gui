cmake_minimum_required(VERSION 3.16)

project(pickett_gui VERSION 0.1 LANGUAGES CXX)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Qt6 - Quick module for QML UI
find_package(Qt6 REQUIRED COMPONENTS Quick Concurrent)

# Set Qt policies for consistent QML module behavior across Qt versions
qt_policy(SET QTP0001 NEW)
qt_policy(SET QTP0004 NEW)

# Library with all parsers
add_library(parsers
    src/parsers/utils.cpp
    src/parsers/lin_parser.cpp
    src/parsers/cat_parser.cpp
    src/parsers/par_parser.cpp
    src/parsers/int_parser.cpp
    src/parsers/fit_parser.cpp
    src/parsers/spe_parser.cpp
)

target_include_directories(parsers PUBLIC src)

qt_add_executable(pickett-gui
    MANUAL_FINALIZATION
    main.cpp
)

# Add QML module for our C++ types
qt_add_qml_module(pickett-gui
    URI Pickett
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/WelcomePage.qml
        qml/ViewerPage.qml
        qml/SpectrumPlot.qml
    SOURCES
        src/models/spectrumdata.cpp
        src/models/spectrumdata.h
        src/models/viewportmodel.cpp
        src/models/viewportmodel.h
        src/models/catalogdata.cpp
        src/models/catalogdata.h
        src/services/spectralfileservice.cpp
        src/services/spectralfileservice.h
        src/plot/spectrumplotitem.cpp
        src/plot/spectrumplotitem.h
        src/plot/catalogplotitem.cpp
        src/plot/catalogplotitem.h
)

target_link_libraries(pickett-gui PRIVATE
    parsers
    Qt6::Quick
    Qt6::Concurrent
)

set_target_properties(pickett-gui PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.picket_gui
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
)

include(GNUInstallDirs)
install(TARGETS pickett-gui
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

qt_finalize_executable(pickett-gui)

# Tests are optional (off by default)
option(PICKETT_BUILD_TESTS "Build tests" OFF)

if(PICKETT_BUILD_TESTS)
    # Fetch Catch2 for testing
    include(FetchContent)
    FetchContent_Declare(
        Catch2
        GIT_REPOSITORY https://github.com/catchorg/Catch2.git
        GIT_TAG v3.8.1
    )
    FetchContent_MakeAvailable(Catch2)
    
    # Test executable
    add_executable(test_parsers
        tests/test_lin_parser.cpp
        tests/test_cat_parser.cpp
        tests/test_par_parser.cpp
        tests/test_int_parser.cpp
        tests/test_fit_parser.cpp
        tests/test_spe_parser.cpp
        tests/test_spectral_file_service.cpp
        src/services/spectralfileservice.cpp
        src/services/spectralfileservice.h
    )
    
    target_link_libraries(test_parsers PRIVATE
        parsers
        Catch2::Catch2WithMain
        Qt6::Core
        Qt6::Concurrent
    )
    target_compile_definitions(test_parsers PRIVATE TEST_DATA_DIR="${CMAKE_SOURCE_DIR}/test_data")
    
    # Automatic test registration with CTest
    include(CTest)
    list(APPEND CMAKE_MODULE_PATH ${Catch2_SOURCE_DIR}/extras)
    include(Catch)
    catch_discover_tests(test_parsers)
endif()
