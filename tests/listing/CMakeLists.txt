cmake_minimum_required(VERSION 3.18)
project(extension_listing_tests LANGUAGES C CXX)
include(CTest)
include(FetchContent)
FetchContent_Declare(zip_source
    GIT_REPOSITORY https://github.com/kuba--/zip.git
    GIT_TAG ffd2d395f843c81dc82648c56e3889d539fc3f71
    SOURCE_SUBDIR no-cmake-project)
FetchContent_MakeAvailable(zip_source)
add_library(listing_zip STATIC ${zip_source_SOURCE_DIR}/src/zip.c)
target_include_directories(listing_zip PUBLIC ${zip_source_SOURCE_DIR}/src)
add_executable(extension_listing_tests listing.cpp)
target_compile_features(extension_listing_tests PRIVATE cxx_std_17)
target_include_directories(extension_listing_tests PRIVATE ../../dll)
target_link_libraries(extension_listing_tests PRIVATE listing_zip)
add_test(NAME extension_listing COMMAND extension_listing_tests)
