cmake_minimum_required(VERSION 3.22)

project(punchi-dock-remastered VERSION 0.9.7.50 LANGUAGES CXX)

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

find_package(Qt6 6.6 REQUIRED COMPONENTS Core DBus Gui Qml Quick)
find_package(KF6 6.0 REQUIRED COMPONENTS Config CoreAddons GlobalAccel I18n JobWidgets KIO Service WindowSystem)
find_package(Plasma 6.0 REQUIRED)
find_package(LibKWorkspace REQUIRED)
find_package(PkgConfig REQUIRED)
find_package(Gettext REQUIRED)
pkg_check_modules(PipeWire REQUIRED IMPORTED_TARGET libpipewire-0.3)

set(PUNCHI_PLUGIN_ID "org.kde.plasma.punchi-dock-remastered")
set(
    PUNCHI_PLASMOID_INSTALL_DIR
    "${KDE_INSTALL_DATADIR}/plasma/plasmoids/${PUNCHI_PLUGIN_ID}"
)
option(
    PUNCHI_EMBED_QML_MODULE_IN_KPACKAGE
    "Install the native QML module inside the Plasma KPackage"
    OFF
)

# Install the KPackage through the regular CMake install graph. src/CMakeLists.txt
# selects either the global QML destination or the embedded per-user location,
# so source-tree module stubs are deliberately excluded from this copy.
install(
    FILES metadata.json LICENSE
    DESTINATION "${PUNCHI_PLASMOID_INSTALL_DIR}"
)
install(
    DIRECTORY contents/
    DESTINATION "${PUNCHI_PLASMOID_INSTALL_DIR}/contents"
    PATTERN "ui/org" EXCLUDE
)

set(
    PUNCHI_TRANSLATION_DOMAIN
    "plasma_applet_org.kde.plasma.punchi-dock-remastered"
)
set(PUNCHI_TRANSLATION_OUTPUTS)
foreach(language IN ITEMS de es pt_BR)
    set(
        translation_output
        "${CMAKE_CURRENT_BINARY_DIR}/locale/${language}/LC_MESSAGES/${PUNCHI_TRANSLATION_DOMAIN}.mo"
    )
    add_custom_command(
        OUTPUT "${translation_output}"
        COMMAND ${CMAKE_COMMAND} -E make_directory
            "${CMAKE_CURRENT_BINARY_DIR}/locale/${language}/LC_MESSAGES"
        COMMAND ${GETTEXT_MSGFMT_EXECUTABLE}
            --check
            --check-format
            --output-file=${translation_output}
            "${CMAKE_CURRENT_SOURCE_DIR}/po/${language}.po"
        DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/po/${language}.po"
        COMMENT "Compiling ${language} translation catalog"
        VERBATIM
    )
    list(APPEND PUNCHI_TRANSLATION_OUTPUTS "${translation_output}")
    install(
        FILES "${translation_output}"
        DESTINATION "${KDE_INSTALL_LOCALEDIR}/${language}/LC_MESSAGES"
    )
endforeach()
add_custom_target(punchi_translations ALL DEPENDS ${PUNCHI_TRANSLATION_OUTPUTS})

add_subdirectory(src)

if(BUILD_TESTING)
    add_subdirectory(tests)
endif()
