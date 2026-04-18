cmake_minimum_required(VERSION 3.16)
project(pickett_parsers VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Library with all parsers
add_library(parsers
    src/parsers/lin_parser.cpp
)

target_include_directories(parsers PUBLIC src)

# Fetch Catch2 for testing
Include(FetchContent)
FetchContent_Declare(
    Catch2
    GIT_REPOSITORY https://github.com/catchorg/Catch2.git
    GIT_TAG v3.8.1
)
FetchContent_MakeAvailable(Catch2)

# Test executable
add_executable(test_parsers
    tests/test_lin_parser.cpp
)

target_link_libraries(test_parsers PRIVATE parsers Catch2::Catch2WithMain)
target_compile_definitions(test_parsers PRIVATE TEST_DATA_DIR="${CMAKE_SOURCE_DIR}/test_data")

# Automatic test registration with CTest
include(CTest)
list(APPEND CMAKE_MODULE_PATH ${Catch2_SOURCE_DIR}/extras)
include(Catch)
catch_discover_tests(test_parsers)
