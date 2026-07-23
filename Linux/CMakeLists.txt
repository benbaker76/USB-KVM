cmake_minimum_required(VERSION 3.16)
project(usbkvm-linux LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../core ${CMAKE_CURRENT_BINARY_DIR}/core)

add_executable(kvmctl cli/kvmctl.cpp)
target_link_libraries(kvmctl PRIVATE usbkvm)

if(NOT MSVC)
    target_compile_options(kvmctl PRIVATE -Wall -Wextra)
endif()

include(GNUInstallDirs)
install(TARGETS kvmctl RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES udev/70-usbkvm.rules DESTINATION ${CMAKE_INSTALL_SYSCONFDIR}/udev/rules.d)
