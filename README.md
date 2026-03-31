# Releases build repository for Luwow-Project

This repository builds all the major components of Luwow Project

## Requirements

- C++17 compatible compiler
- CMake 3.16 or later
- Luau source code (see setup instructions below)

### Supported Platforms

- Windows (Microsoft Visual Studio Code + Visual C++ compiler)
- Windows (Microsoft Visual Studio Code + MinGW C++ compiler)
- MacOS (Microsoft Visual Studio Code + XCode compiler)
- Future OS plans include iPad, Linux, and Android

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/Luwow-Project/Release Luwow --recurse-submodules
cd Luwow
```

If you forget the --recurse-submodules flag, you can follow up with:
```bash
git submodule update --init --recursive
```

### 2. Configure and Build the Project

Choices of config / build type are:
Debug, Release, RelWithDebugInfo, MinSizeRel

Windows:
```bash
cmake . -B build
cmake --build build --config Release
```

If using MinGW:
```bash
cmake . -G "MinGW Makefiles"
cmake --build . --config Release
```

MacOS:
```bash
cmake -S . -B build -D CMAKE_BUILD_TYPE=Release
cmake --build build
```

Your output binaries are located in the build/bin/Release folder on Windows or build/bin folder on Mac.

## Usage

### runscript - Script compiler / runner and remotedebug - compiler / runner / remote debug host

Execute script from the command line:

```bash
./runscript script.luau
./runscriptwithgui script.luau
./remotedebug 59000 script.luau
```

### compile - Script compiler

Compiles one or more scripts into bytecode and places them in a package in the order
listed. The first script in the package is then executed by the package runner. The
remainder are expected to be supporting scripts using require.

```bash
./compile script.luau test.pkg
```

### runpackage - Script Package Executor

Execute Luau scripts from the command line:

```bash
./lrun test.pkg
```
