cmake_minimum_required(VERSION 3.22)

project(punchi-dock-remastered VERSION 0.9.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(ECM 6.0 REQUIRED NO_MODULE)
list(APPEND CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs6)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(ECMQmlModule)
include(CTest)

find_package(Qt6 6.6 REQUIRED COMPONENTS Core DBus Gui Qml)
find_package(KF6 6.0 REQUIRED COMPONENTS CoreAddons I18n JobWidgets KIO Service)
find_package(Plasma 6.0 REQUIRED)
find_package(PkgConfig REQUIRED)
pkg_check_modules(PipeWire REQUIRED IMPORTED_TARGET libpipewire-0.3)

add_subdirectory(src)

if(BUILD_TESTING)
    add_subdirectory(tests)
endif()
