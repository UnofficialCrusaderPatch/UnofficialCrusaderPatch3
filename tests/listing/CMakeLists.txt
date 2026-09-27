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

# Compile the production listing function bodies with real Lua and controlled
# Core/mount services. The complete game backend still needs its separate build.
FetchContent_Declare(lua_source
    GIT_REPOSITORY https://github.com/lua/lua.git
    GIT_TAG 6443185167c77adcc8552a3fee7edab7895db1a9
    SOURCE_SUBDIR no-cmake-project)
FetchContent_MakeAvailable(lua_source)
file(GLOB lua_files "${lua_source_SOURCE_DIR}/*.c")
list(FILTER lua_files EXCLUDE REGEX "/(lua|luac|onelua|ltests)\\.c$")
add_library(listing_lua STATIC ${lua_files})
target_include_directories(listing_lua PUBLIC ${lua_source_SOURCE_DIR})
if(UNIX)
    target_link_libraries(listing_lua PUBLIC m)
endif()
set(bridge_source "#include \"bridge.hpp\"\n")
foreach(source LuaFilesList.cpp LuaDirectoriesList.cpp deprecated/LuaListFiles.cpp deprecated/LuaListDirectories.cpp)
    file(READ "${CMAKE_CURRENT_SOURCE_DIR}/../../dll/lua/${source}" function_source)
    string(REGEX REPLACE "#include[^\n]*\n" "" function_source "${function_source}")
    string(APPEND bridge_source "${function_source}\n")
endforeach()
file(READ "${CMAKE_CURRENT_SOURCE_DIR}/../../dll/core/Core-path.cpp" path_source)
string(FIND "${path_source}" "bool Core::pathIsInPluginDirectory" first)
string(FIND "${path_source}" "bool Core::pathIsInInternalCodeDirectory" last)
math(EXPR length "${last} - ${first}")
string(SUBSTRING "${path_source}" ${first} ${length} routing_source)
string(APPEND bridge_source "${routing_source}\n")
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/bridge-functions.cpp" "${bridge_source}")
add_executable(listing_bridge_tests bridge.cpp "${CMAKE_CURRENT_BINARY_DIR}/bridge-functions.cpp")
target_compile_features(listing_bridge_tests PRIVATE cxx_std_17)
target_include_directories(listing_bridge_tests PRIVATE . ../../dll)
target_link_libraries(listing_bridge_tests PRIVATE listing_zip listing_lua)
add_test(NAME listing_lua_bridge COMMAND listing_bridge_tests)
