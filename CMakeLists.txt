cmake_minimum_required(VERSION 3.16)

project(pickett_gui VERSION 0.1 LANGUAGES CXX)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Qt6 only - Graphs module
find_package(Qt6 REQUIRED COMPONENTS Widgets Charts)

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

set(PROJECT_SOURCES
        main.cpp
        mainwindow.cpp

        mainwindow.h

)

qt_add_executable(pickett-gui
    MANUAL_FINALIZATION
    ${PROJECT_SOURCES}
    spectrumplotwidget.h spectrumplotwidget.cpp
)

target_link_libraries(pickett-gui PRIVATE
    parsers
    Qt6::Widgets
    Qt6::Charts
)

set_target_properties(pickett-gui PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.picket_gui
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
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
    )
    
    target_link_libraries(test_parsers PRIVATE parsers Catch2::Catch2WithMain)
    target_compile_definitions(test_parsers PRIVATE TEST_DATA_DIR="${CMAKE_SOURCE_DIR}/test_data")
    
    # Automatic test registration with CTest
    include(CTest)
    list(APPEND CMAKE_MODULE_PATH ${Catch2_SOURCE_DIR}/extras)
    include(Catch)
    catch_discover_tests(test_parsers)
endif()
