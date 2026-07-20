add_library(punchidockintegration)

ecm_add_qml_module(punchidockintegration
    URI org.punchi.dock
    VERSION 1.0
    GENERATE_PLUGIN_SOURCE
    DEPENDENCIES QtCore
)

set_target_properties(punchidockintegration PROPERTIES
    BUILD_WITH_INSTALL_RPATH TRUE
    INSTALL_RPATH "$ORIGIN"
)
set_target_properties(punchidockintegrationplugin PROPERTIES
    BUILD_WITH_INSTALL_RPATH TRUE
    INSTALL_RPATH "$ORIGIN"
)

target_sources(punchidockintegration PRIVATE
    audiospectrumcontroller.cpp
    audiospectrumcontroller.h
    commandclassification.cpp
    commandclassification.h
    dockthemerepository.cpp
    dockthemerepository.h
    dockthemevalidator.cpp
    dockthemevalidator.h
    dockruntimeservice.cpp
    dockruntimeservice.h
    mediaartworkresolver.cpp
    mediaartworkresolver.h
    mpriscontroller.cpp
    mpriscontroller.h
    pipewireaudiobackend.cpp
    pipewireaudiobackend.h
    spectrumanalyzer.cpp
    spectrumanalyzer.h
    systemdiscovery.cpp
    systemdiscovery.h
    themeintegration.cpp
    themeintegration.h
    trashintegration.cpp
    trashintegration.h
)

target_link_libraries(punchidockintegration
    PRIVATE
        Qt6::Core
        Qt6::DBus
        Qt6::Gui
        Qt6::Qml
        KF6::CoreAddons
        KF6::I18n
        KF6::JobWidgets
        KF6::KIOCore
        KF6::KIOGui
        KF6::Service
        PkgConfig::PipeWire
        Plasma::Plasma
)

install(TARGETS punchidockintegration ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})

ecm_finalize_qml_module(punchidockintegration
    DESTINATION ${KDE_INSTALL_QMLDIR}
)

set(
    PUNCHI_PACKAGE_QML_MODULE_DIR
    "${CMAKE_BINARY_DIR}/package-root/contents/ui/org/punchi/dock"
    CACHE PATH
    "Destination used to stage the native QML module for plasmoid packaging"
)
add_custom_target(stage_plasmoid_module
    COMMAND ${CMAKE_COMMAND} -E make_directory "${PUNCHI_PACKAGE_QML_MODULE_DIR}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "$<TARGET_FILE:punchidockintegration>"
        "${PUNCHI_PACKAGE_QML_MODULE_DIR}/libpunchidockintegration.so"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "$<TARGET_FILE:punchidockintegrationplugin>"
        "${PUNCHI_PACKAGE_QML_MODULE_DIR}/libpunchidockintegrationplugin.so"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_BINARY_DIR}/bin/org/punchi/dock/qmldir"
        "${PUNCHI_PACKAGE_QML_MODULE_DIR}/qmldir"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_BINARY_DIR}/bin/org/punchi/dock/punchidockintegration.qmltypes"
        "${PUNCHI_PACKAGE_QML_MODULE_DIR}/punchidockintegration.qmltypes"
    DEPENDS punchidockintegration punchidockintegrationplugin
    COMMENT "Staging org.punchi.dock inside the plasmoid package"
)
