cmake_minimum_required(VERSION 3.16)
project(usbkvm-windows LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT WIN32)
    message(FATAL_ERROR
        "Configure with the MinGW toolchain file:\n"
        "  cmake -S Windows -B build-win "
        "-DCMAKE_TOOLCHAIN_FILE=cmake/mingw-w64.cmake")
endif()

# Static CRT so the exe runs without a redistributable. This must be set before
# the core subdirectory is added: setting it per-target leaves the static library
# on the default DLL runtime and the link fails with LNK2038.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../core ${CMAKE_CURRENT_BINARY_DIR}/core)

add_executable(USBKVM WIN32
    src/main.cpp
    res/app.rc
)

target_link_libraries(USBKVM PRIVATE usbkvm)

# Shell_NotifyIcon lives in shell32; the HID/SetupAPI libraries come in through
# the core target.
target_link_libraries(USBKVM PRIVATE shell32 user32 advapi32)

if(MINGW)
    target_compile_options(USBKVM PRIVATE -Wall -Wextra -municode)
    # -municode selects the wWinMain entry point; without it the MinGW startup
    # code looks for an ANSI WinMain and the link fails.
    # Static-link the runtime so the exe needs no MinGW DLLs alongside it.
    target_link_options(USBKVM PRIVATE
        -municode -static -static-libgcc -static-libstdc++ -mwindows)
elseif(MSVC)
    target_compile_options(USBKVM PRIVATE /W4)
endif()

install(TARGETS USBKVM RUNTIME DESTINATION .)
