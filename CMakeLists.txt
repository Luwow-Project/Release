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

# Luau
set(LUAU_ROOT ${CMAKE_SOURCE_DIR}/extern/luau)

# Core engine + executables
set(CORE_ROOT ${CMAKE_SOURCE_DIR}/extern/core)
set(COMPILE_ROOT ${CORE_ROOT}/src/Compile)
set(ENGINE_ROOT ${CORE_ROOT}/src/Engine)
set(RUN_SCRIPT_ROOT ${CORE_ROOT}/src/RunScript)
set(RUN_PACKAGE_ROOT ${CORE_ROOT}/src/RunPackage)

# Libraries
set(LIBRARY_ROOT ${CMAKE_SOURCE_DIR}/libraries)
set(GUI_ROOT ${LIBRARY_ROOT}/gui)

# Luau build
option(LUAU_BUILD_CLI "Build CLI" OFF)
option(LUAU_BUILD_TESTS "Build tests" OFF)
add_subdirectory(${LUAU_ROOT})

# Core components
add_subdirectory(${ENGINE_ROOT})
add_subdirectory(${RUN_SCRIPT_ROOT})
add_subdirectory(${COMPILE_ROOT})
add_subdirectory(${RUN_PACKAGE_ROOT})

if(WIN32 OR APPLE)
    add_subdirectory(${GUI_ROOT}/src/Gui)
    add_subdirectory(${GUI_ROOT}/src/GuiTest)
endif()

# TODO: Remote debugger
# set(CPP_DAP_ROOT ${CMAKE_SOURCE_DIR}/extern/cppdap)
# add_subdirectory(${CPP_DAP_ROOT})
# add_subdirectory(${CMAKE_SOURCE_DIR}/extern/luau-debugger/debugger)
# add_subdirectory(${CMAKE_SOURCE_DIR}/extern/remotedebugger/src/LRemoteDebug)
