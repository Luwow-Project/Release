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
#   Executables with bound libraries:  LUWOW_BUILD_EXECUTABLES=ON  LUWOW_BUILD_LIBRARIES=ON   LUWOW_LIBRARY_MODE=STATIC
#   Executables loading DLLs:          LUWOW_BUILD_EXECUTABLES=ON  LUWOW_BUILD_LIBRARIES=OFF  LUWOW_LIBRARY_MODE=SHARED
#   Library DLLs only:                 LUWOW_BUILD_EXECUTABLES=OFF LUWOW_BUILD_LIBRARIES=ON   LUWOW_LIBRARY_MODE=SHARED
option(LUWOW_BUILD_EXECUTABLES "Build runscript and the other Luwow executables" ON)
option(LUWOW_BUILD_LIBRARIES "Build the Luwow libraries" ON)
set(LUWOW_LIBRARY_MODE "SHARED" CACHE STRING "STATIC binds the libraries into runscript, SHARED builds them as DLLs runscript loads through .config.luau")
set_property(CACHE LUWOW_LIBRARY_MODE PROPERTY STRINGS STATIC SHARED)

include(${CMAKE_SOURCE_DIR}/cmake/LuwowModules.cmake)

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
set(TASK_ROOT ${LIBRARY_ROOT}/task)
set(FS_ROOT ${LIBRARY_ROOT}/fs)
set(IO_ROOT ${LIBRARY_ROOT}/io)
set(NET_ROOT ${LIBRARY_ROOT}/net)
set(SIGNAL_ROOT ${LIBRARY_ROOT}/signal)

# Libuv
set(LIBUV_ROOT ${CMAKE_SOURCE_DIR}/extern/libuv)

# Remote debugger
set(CPP_DAP_ROOT ${CMAKE_SOURCE_DIR}/extern/cppdap)
set(LUAU_DEBUGGER_ROOT ${CMAKE_SOURCE_DIR}/extern/luau-debugger)
set(DEBUGGER_ROOT ${CMAKE_SOURCE_DIR}/extern/debug/src)

# Luau build
option(LUAU_BUILD_CLI "Build CLI" OFF)
option(LUAU_BUILD_TESTS "Build tests" OFF)
add_subdirectory(${LUAU_ROOT})

luwow_export_luau_api()

# Core engine
add_subdirectory(${ENGINE_ROOT})

# Libraries
if(LUWOW_BUILD_LIBRARIES)
    if(WIN32 OR APPLE)
        add_subdirectory(${GUI_ROOT}/src)
    endif()

    add_subdirectory(${TASK_ROOT}/src)
    add_subdirectory(${FS_ROOT}/src)
    add_subdirectory(${IO_ROOT}/src)
    add_subdirectory(${SIGNAL_ROOT}/src)
    add_subdirectory(${NET_ROOT}/src)

    # Only the static uv_a is linked, skip building uv.dll
    set(LIBUV_BUILD_SHARED OFF CACHE BOOL "" FORCE)
    add_subdirectory(${LIBUV_ROOT})
endif()

luwow_generate_static_modules()

# Executables
if(LUWOW_BUILD_EXECUTABLES)
    add_subdirectory(${RUN_SCRIPT_ROOT})
    add_subdirectory(${COMPILE_ROOT})
    add_subdirectory(${RUN_PACKAGE_ROOT})

    add_subdirectory(${CPP_DAP_ROOT})
    add_subdirectory(${LUAU_DEBUGGER_ROOT}/debugger)
    add_subdirectory(${DEBUGGER_ROOT})

    # In SHARED mode runscript.lib is the import library third-party module DLLs link against on Windows
    install(TARGETS Luwow.RunScript Luwow.Compile Luwow.RunPackage Luwow.RemoteDebug
        RUNTIME DESTINATION bin COMPONENT executables
        ARCHIVE DESTINATION lib COMPONENT sdk
    )
elseif(LUWOW_LIBRARY_MODE STREQUAL "SHARED")
    # Library DLLs link against the Luau API runscript exports, so it's built but not installed
    add_subdirectory(${RUN_SCRIPT_ROOT} ${CMAKE_BINARY_DIR}/runscript EXCLUDE_FROM_ALL)
endif()
