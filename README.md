# Releases build repository for Luwow-Project

This repository builds all the major components of Luwow Project

## Requirements

* C++ 17 compatible compiler
* CMake 3.16 or later
* Luau source code

-----

## Supported Platforms

* Windows (Microsoft Visual Studio Code + Visual C++ compiler)
* Windows (Microsoft Visual Studio Code + MinGW C++ compiler)
* MacOS (Microsoft Visual Studio Code + XCode compiler)

*(Future OS plans include iPad, Linux, and Android)*

-----

## Setting Up

In a folder, run the commands below in your terminal:

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

Windows:
```bash
cmake . -B build
cmake --build build --config Release
```

If using MinGW on Windows:
```bash
cmake . -B build -G "MinGW Makefiles"
cmake --build build --config Release
```

MacOS:
```bash
cmake -S . -B build -D CMAKE_BUILD_TYPE=Release
cmake --build build
```

If you wish to change the config, config/build types are:
`Debug`, `Release`, `RelWithDebugInfo`, `MinSizeRel`

-----

## Usage

To learn how to use the libraries, you can head over to the [documentation](https://luwow-project.github.io/Documentation/tutorials/setup/#usage).