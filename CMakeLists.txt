cmake_minimum_required(VERSION 3.16)
project(Luwow VERSION 0.1.0 LANGUAGES CXX)
if(APPLE)
    enable_language(OBJCXX)
endif()

# Set C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Set output directories
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib_archive)

if(WIN32)
    # Define WIN32_LEAN_AND_MEAN to exclude rarely-used APIs.
    add_compile_definitions(
        WIN32_LEAN_AND_MEAN
    )
endif()

# Build options
#   Executables loading library DLLs, and the SDK they're built with:  LUWOW_LIBRARY_MODE=SHARED (the default)
#   Executables with libraries bound in:  LUWOW_LIBRARY_MODE=STATIC LUWOW_LIBRARY_DIRS=<folders adding them>
set(LUWOW_LIBRARY_MODE "SHARED" CACHE STRING "STATIC binds the libraries of LUWOW_LIBRARY_DIRS into the executables, SHARED makes them load DLLs through .config.luau")
set_property(CACHE LUWOW_LIBRARY_MODE PROPERTY STRINGS STATIC SHARED)
set(LUWOW_LIBRARY_DIRS "" CACHE STRING "Folders whose CMakeLists add libraries with luwow_add_library, bound into the executables in a STATIC build")
set(LUWOW_RELEASE_VERSION "dev" CACHE STRING "The release's version, such as v0.2.0, recorded in the SDK")

# Luau
set(LUAU_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/extern/luau)

# Core engine + executables
set(CORE_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/extern/core)
set(COMPILE_ROOT ${CORE_ROOT}/src/Compile)
set(ENGINE_ROOT ${CORE_ROOT}/src/Engine)
set(RUN_SCRIPT_ROOT ${CORE_ROOT}/src/RunScript)
set(RUN_PACKAGE_ROOT ${CORE_ROOT}/src/RunPackage)
set(CORE_CMAKE_ROOT ${CORE_ROOT}/cmake)

include(${CORE_CMAKE_ROOT}/LuwowModules.cmake)

# Luau build
option(LUAU_BUILD_CLI "Build CLI" OFF)
option(LUAU_BUILD_TESTS "Build tests" OFF)
add_subdirectory(${LUAU_ROOT})

luwow_export_luau_api()

# Core engine
add_subdirectory(${ENGINE_ROOT})

# Libraries bound into the executables, registered before the executables are made
foreach(libraryDir IN LISTS LUWOW_LIBRARY_DIRS)
    get_filename_component(libraryName ${libraryDir} NAME)
    add_subdirectory(${libraryDir} ${CMAKE_BINARY_DIR}/libraries/${libraryName})
endforeach()
luwow_generate_static_modules()

# Executables
add_subdirectory(${RUN_SCRIPT_ROOT})
add_subdirectory(${COMPILE_ROOT})
add_subdirectory(${RUN_PACKAGE_ROOT})

install(TARGETS Luwow.RunScript Luwow.Compile Luwow.RunPackage RUNTIME DESTINATION bin COMPONENT executables)

# The SDK library DLLs are built with, from runscript's exports
luwow_install_sdk(Luwow.RunScript)
