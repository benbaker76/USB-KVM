cmake_minimum_required(VERSION 3.16)
project(usbkvm-core LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(usbkvm STATIC
    src/devices.cpp
)

if(WIN32)
    target_sources(usbkvm PRIVATE src/device_windows.cpp)
    # SetupDi* lives in setupapi; HidD_*/HidP_* in hid.
    target_link_libraries(usbkvm PUBLIC setupapi hid)
else()
    target_sources(usbkvm PRIVATE src/device_linux.cpp)
endif()

target_include_directories(usbkvm
    PUBLIC  ${CMAKE_CURRENT_SOURCE_DIR}/include
    PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src
)

if(MSVC)
    target_compile_options(usbkvm PRIVATE /W4)
else()
    target_compile_options(usbkvm PRIVATE -Wall -Wextra)
endif()
