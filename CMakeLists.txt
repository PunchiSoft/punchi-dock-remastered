cmake_minimum_required(VERSION 3.22)

project(punchi-dock-remastered VERSION 0.8.2 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(ECM 6.0 REQUIRED NO_MODULE)
list(APPEND CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs6)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(ECMQmlModule)

find_package(Qt6 6.6 REQUIRED COMPONENTS Core Qml)
find_package(KF6 6.0 REQUIRED COMPONENTS CoreAddons KIO Service)
find_package(Plasma 6.0 REQUIRED)

add_subdirectory(src)
