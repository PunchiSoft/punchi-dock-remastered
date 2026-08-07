add_library(punchidockintegration)

find_program(PUNCHI_QSB_EXECUTABLE
    NAMES qsb qsb-qt6
    HINTS /usr/lib/qt6/bin /usr/lib64/qt6/bin
)
if(NOT PUNCHI_QSB_EXECUTABLE)
    message(FATAL_ERROR
        "Qt 6 Shader Baker (qsb) is required to build Punchi Dock"
    )
endif()

ecm_add_qml_module(punchidockintegration
    URI org.punchi.dock
    VERSION 1.0
    GENERATE_PLUGIN_SOURCE
    DEPENDENCIES QtCore
)

set_target_properties(punchidockintegration PROPERTIES
    BUILD_WITH_INSTALL_RPATH TRUE
    INSTALL_RPATH "$ORIGIN:$ORIGIN/compat"
)
set_target_properties(punchidockintegrationplugin PROPERTIES
    BUILD_WITH_INSTALL_RPATH TRUE
    INSTALL_RPATH "$ORIGIN:$ORIGIN/compat"
)

target_sources(punchidockintegration PRIVATE
    audiospectrumcontroller.cpp
    audiospectrumcontroller.h
    blurbehindcontroller.cpp
    blurbehindcontroller.h
    commandclassification.cpp
    commandclassification.h
    desktopshortcutwriter.cpp
    desktopshortcutwriter.h
    desktoplauncherresolver.cpp
    desktoplauncherresolver.h
    dockthemerepository.cpp
    dockthemerepository.h
    dockthemevalidator.cpp
    dockthemevalidator.h
    dockitemsjsontransaction.cpp
    dockitemsjsontransaction.h
    dockitemspersistenceadapter.cpp
    dockitemspersistenceadapter.h
    dockruntimeservice.cpp
    dockruntimeservice.h
    dropurlpolicy.cpp
    dropurlpolicy.h
    mediaartworkresolver.cpp
    mediaartworkresolver.h
    mpriscontroller.cpp
    mpriscontroller.h
    mprisplayerselection.cpp
    mprisplayerselection.h
    panellengthmodebridge.cpp
    panellengthmodebridge.h
    pipewireaudiobackend.cpp
    pipewireaudiobackend.h
    punchimenulayoutcontroller.cpp
    punchimenulayoutcontroller.h
    punchimenulayoutdocument.cpp
    punchimenulayoutdocument.h
    punchimenulayoutmodel.cpp
    punchimenulayoutmodel.h
    punchimenushortcutcontroller.cpp
    punchimenushortcutcontroller.h
    sessionactionscontroller.cpp
    sessionactionscontroller.h
    spectrumanalyzer.cpp
    spectrumanalyzer.h
    systemdiscovery.cpp
    systemdiscovery.h
    taskgeometryownershipbridge.cpp
    taskgeometryownershipbridge.h
    themeintegration.cpp
    themeintegration.h
    trashintegration.cpp
    trashintegration.h
)

set(PUNCHI_AVATAR_SHADER_SOURCE
    "${CMAKE_CURRENT_SOURCE_DIR}/shaders/PunchiMenuAvatar.frag"
)
set(PUNCHI_AVATAR_SHADER_BINARY
    "${CMAKE_CURRENT_BINARY_DIR}/PunchiMenuAvatar.frag.qsb"
)
add_custom_command(
    OUTPUT "${PUNCHI_AVATAR_SHADER_BINARY}"
    COMMAND "${PUNCHI_QSB_EXECUTABLE}"
        --qt6
        --qsbversion 65
        -o "${PUNCHI_AVATAR_SHADER_BINARY}"
        "${PUNCHI_AVATAR_SHADER_SOURCE}"
    DEPENDS "${PUNCHI_AVATAR_SHADER_SOURCE}"
    COMMENT "Baking PunchiMenu avatar shader"
    VERBATIM
)
set_source_files_properties("${PUNCHI_AVATAR_SHADER_BINARY}" PROPERTIES
    GENERATED TRUE
    QT_RESOURCE_ALIAS "PunchiMenuAvatar.frag.qsb"
)
qt_add_resources(punchidockintegration "punchimenu_avatar_shader"
    PREFIX "/qt/qml/org/punchi/dock/shaders"
    FILES "${PUNCHI_AVATAR_SHADER_BINARY}"
)

target_link_libraries(punchidockintegration
    PRIVATE
        Qt6::Core
        Qt6::DBus
        Qt6::Gui
        Qt6::Qml
        KF6::ConfigCore
        KF6::ConfigGui
        KF6::CoreAddons
        KF6::GlobalAccel
        KF6::I18n
        KF6::JobWidgets
        KF6::KIOCore
        KF6::KIOGui
        KF6::Service
        KF6::WindowSystem
        PkgConfig::PipeWire
        Plasma::Plasma
        PW::KWorkspace
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
