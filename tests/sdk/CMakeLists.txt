#   cmake -S tests/sdk -B build-sdk -D LuwowSDK_DIR=<sdk>/cmake
cmake_minimum_required(VERSION 3.16)
project(LuwowSdkTest LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(LuwowSDK REQUIRED CONFIG)
message(STATUS "Luwow SDK ${LUWOW_SDK_VERSION}, module ABI ${LUWOW_SDK_ABI_VERSION}")

luwow_add_library(Luwow.SdkTest
    NAME sdktest
    MODES SERIAL
    SOURCES
        SdkTest.cpp
)
