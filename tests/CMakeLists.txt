find_package(Qt6 6.6 REQUIRED COMPONENTS QuickTest Test)
find_package(PlasmaQuick 6.0 REQUIRED)

add_executable(spectrumanalyzer_test
    spectrumanalyzer_test.cpp
    ${CMAKE_SOURCE_DIR}/src/spectrumanalyzer.cpp
)

target_include_directories(spectrumanalyzer_test PRIVATE ${CMAKE_SOURCE_DIR}/src)

add_test(NAME spectrumanalyzer_test COMMAND spectrumanalyzer_test)

add_executable(commandclassification_test
    commandclassification_test.cpp
    ${CMAKE_SOURCE_DIR}/src/commandclassification.cpp
)

target_include_directories(commandclassification_test PRIVATE ${CMAKE_SOURCE_DIR}/src)
target_link_libraries(commandclassification_test PRIVATE Qt6::Core KF6::CoreAddons)

add_test(NAME commandclassification_test COMMAND commandclassification_test)

add_executable(applicationcategoryclassifier_test
    applicationcategoryclassifier_test.cpp
    ${CMAKE_SOURCE_DIR}/src/applicationcategoryclassifier.cpp
)

target_include_directories(applicationcategoryclassifier_test PRIVATE ${CMAKE_SOURCE_DIR}/src)
target_link_libraries(applicationcategoryclassifier_test PRIVATE Qt6::Core)

add_test(NAME applicationcategoryclassifier_test COMMAND applicationcategoryclassifier_test)

add_executable(dropurlpolicy_test
    dropurlpolicy_test.cpp
    ${CMAKE_SOURCE_DIR}/src/dropurlpolicy.cpp
)

target_include_directories(dropurlpolicy_test PRIVATE ${CMAKE_SOURCE_DIR}/src)
target_link_libraries(dropurlpolicy_test PRIVATE Qt6::Core)

add_test(NAME dropurlpolicy_test COMMAND dropurlpolicy_test)

add_executable(dockitemsjsontransaction_test
    dockitemsjsontransaction_test.cpp
    ${CMAKE_SOURCE_DIR}/src/dockitemsjsontransaction.cpp
    ${CMAKE_SOURCE_DIR}/src/punchimenulayoutdocument.cpp
)

target_include_directories(dockitemsjsontransaction_test PRIVATE ${CMAKE_SOURCE_DIR}/src)
target_link_libraries(dockitemsjsontransaction_test PRIVATE Qt6::Core KF6::ConfigCore)

add_test(NAME dockitemsjsontransaction_test COMMAND dockitemsjsontransaction_test)

add_executable(desktopshortcutwriter_test
    desktopshortcutwriter_test.cpp
    ${CMAKE_SOURCE_DIR}/src/desktopshortcutwriter.cpp
)

target_include_directories(desktopshortcutwriter_test PRIVATE ${CMAKE_SOURCE_DIR}/src)
target_link_libraries(desktopshortcutwriter_test PRIVATE Qt6::Core)

add_test(NAME desktopshortcutwriter_test COMMAND desktopshortcutwriter_test)

add_executable(taskgeometryownershipbridge_test
    taskgeometryownershipbridge_test.cpp
    ${CMAKE_SOURCE_DIR}/src/taskgeometryownershipbridge.cpp
)

target_include_directories(taskgeometryownershipbridge_test PRIVATE ${CMAKE_SOURCE_DIR}/src)
target_link_libraries(taskgeometryownershipbridge_test PRIVATE Qt6::Core Qt6::Qml)

add_test(NAME taskgeometryownershipbridge_test COMMAND taskgeometryownershipbridge_test)

add_executable(punchimenulayoutmodel_test
    punchimenulayoutmodel_test.cpp
    ${CMAKE_SOURCE_DIR}/src/applicationcategoryclassifier.cpp
    ${CMAKE_SOURCE_DIR}/src/punchimenulayoutdocument.cpp
    ${CMAKE_SOURCE_DIR}/src/punchimenulayoutmodel.cpp
)

target_include_directories(punchimenulayoutmodel_test PRIVATE ${CMAKE_SOURCE_DIR}/src)
target_link_libraries(punchimenulayoutmodel_test PRIVATE Qt6::Core Qt6::Qml)

add_test(NAME punchimenulayoutmodel_test COMMAND punchimenulayoutmodel_test)

add_executable(punchimenulayoutcontroller_test
    punchimenulayoutcontroller_test.cpp
    ${CMAKE_SOURCE_DIR}/src/punchimenulayoutcontroller.cpp
    ${CMAKE_SOURCE_DIR}/src/punchimenulayoutdocument.cpp
)

target_include_directories(punchimenulayoutcontroller_test PRIVATE ${CMAKE_SOURCE_DIR}/src)
target_link_libraries(punchimenulayoutcontroller_test PRIVATE Qt6::Core Qt6::Qml)

add_test(NAME punchimenulayoutcontroller_test COMMAND punchimenulayoutcontroller_test)

add_executable(blurbehindcontroller_test
    blurbehindcontroller_test.cpp
    ${CMAKE_SOURCE_DIR}/src/blurbehindcontroller.cpp
)

target_include_directories(blurbehindcontroller_test PRIVATE ${CMAKE_SOURCE_DIR}/src)
target_link_libraries(blurbehindcontroller_test PRIVATE Qt6::Core Qt6::Gui Qt6::Qml KF6::WindowSystem)

add_test(NAME blurbehindcontroller_test COMMAND blurbehindcontroller_test)

add_executable(mediaartworkresolver_test
    mediaartworkresolver_test.cpp
    ${CMAKE_SOURCE_DIR}/src/mediaartworkresolver.cpp
)

target_include_directories(mediaartworkresolver_test PRIVATE ${CMAKE_SOURCE_DIR}/src)
target_link_libraries(mediaartworkresolver_test PRIVATE Qt6::Core)

add_test(NAME mediaartworkresolver_test COMMAND mediaartworkresolver_test)

add_executable(mprisplayerselection_test
    mprisplayerselection_test.cpp
    ${CMAKE_SOURCE_DIR}/src/mprisplayerselection.cpp
)

target_include_directories(mprisplayerselection_test PRIVATE ${CMAKE_SOURCE_DIR}/src)
target_link_libraries(mprisplayerselection_test PRIVATE Qt6::Core)

add_test(NAME mprisplayerselection_test COMMAND mprisplayerselection_test)

add_executable(dockthemevalidator_test
    dockthemevalidator_test.cpp
    ${CMAKE_SOURCE_DIR}/src/dockthemevalidator.cpp
)

target_include_directories(dockthemevalidator_test PRIVATE ${CMAKE_SOURCE_DIR}/src)
target_link_libraries(dockthemevalidator_test PRIVATE Qt6::Core Qt6::Gui)

add_test(NAME dockthemevalidator_test COMMAND dockthemevalidator_test)

add_executable(dockthemerepository_test
    dockthemerepository_test.cpp
    ${CMAKE_SOURCE_DIR}/src/dockthemerepository.cpp
    ${CMAKE_SOURCE_DIR}/src/dockthemevalidator.cpp
)

target_include_directories(dockthemerepository_test PRIVATE ${CMAKE_SOURCE_DIR}/src)
target_link_libraries(dockthemerepository_test PRIVATE Qt6::Core Qt6::Gui Qt6::Qml KF6::I18n)

add_test(NAME dockthemerepository_test COMMAND dockthemerepository_test)

add_test(
    NAME translation_catalog_test
    COMMAND bash ${CMAKE_CURRENT_SOURCE_DIR}/translation_catalog_test.sh
)

find_program(PYTHON3_EXECUTABLE python3 REQUIRED)
add_test(
    NAME punchimenu_context_contract_test
    COMMAND ${PYTHON3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/punchimenu_context_contract_test.py
)

add_test(
    NAME punchimenu_application_state_contract_test
    COMMAND ${PYTHON3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/punchimenu_application_state_contract_test.py
)

add_test(
    NAME separator_editor_contract_test
    COMMAND ${PYTHON3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/separator_editor_contract_test.py
)

add_test(
    NAME punchimenu_layout_persistence_contract_test
    COMMAND ${PYTHON3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/punchimenu_layout_persistence_contract_test.py
)

add_test(
    NAME punchimenu_folder_ui_contract_test
    COMMAND ${PYTHON3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/punchimenu_folder_ui_contract_test.py
)

add_test(
    NAME punchimenu_external_drag_contract_test
    COMMAND ${PYTHON3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/punchimenu_external_drag_contract_test.py
)

add_test(
    NAME dock_container_launcher_drop_contract_test
    COMMAND ${PYTHON3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/dock_container_launcher_drop_contract_test.py
)

add_test(
    NAME container_editor_launcher_drop_contract_test
    COMMAND ${PYTHON3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/container_editor_launcher_drop_contract_test.py
)

add_test(
    NAME dock_wave_panel_geometry_contract_test
    COMMAND ${PYTHON3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/dock_wave_panel_geometry_contract_test.py
)

add_test(
    NAME dock_overflow_geometry_contract_test
    COMMAND ${PYTHON3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/dock_overflow_geometry_contract_test.py
)

add_test(
    NAME dock_dynamic_applications_reorder_contract_test
    COMMAND ${PYTHON3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/dock_dynamic_applications_reorder_contract_test.py
)

add_test(
    NAME window_thumbnail_contract_test
    COMMAND ${PYTHON3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/window_thumbnail_contract_test.py
)

add_test(
    NAME popup_menu_surface_contract_test
    COMMAND ${PYTHON3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/popup_menu_surface_contract_test.py
)

add_test(
    NAME rounded_image_shader_contract_test
    COMMAND ${PYTHON3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/rounded_image_shader_contract_test.py
)

add_test(
    NAME kubuntu_version_detection_test
    COMMAND ${PYTHON3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/kubuntu_version_detection_test.py
)

add_test(
    NAME qmllint_debt_inventory_test
    COMMAND ${PYTHON3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/qmllint_debt_inventory_test.py
)

add_test(
    NAME qmllint_i18n_candidates_test
    COMMAND ${PYTHON3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/qmllint_i18n_candidates_test.py
)

add_test(
    NAME qmllint_debt_cycle_test
    COMMAND ${PYTHON3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/qmllint_debt_cycle_test.py
)

add_test(
    NAME debian_dependency_detection_test
    COMMAND bash ${CMAKE_CURRENT_SOURCE_DIR}/debian_dependency_detection_test.sh
)

add_test(
    NAME qmllint_baseline_path_test
    COMMAND bash ${CMAKE_CURRENT_SOURCE_DIR}/qmllint_baseline_path_test.sh
)

add_test(
    NAME setup_logging_test
    COMMAND bash ${CMAKE_CURRENT_SOURCE_DIR}/setup_logging_test.sh
)

add_test(
    NAME local_package_install_test
    COMMAND bash ${CMAKE_CURRENT_SOURCE_DIR}/local_package_install_test.sh
)

add_test(
    NAME plasma_runtime_diagnostics_test
    COMMAND bash ${CMAKE_CURRENT_SOURCE_DIR}/plasma_runtime_diagnostics_test.sh
)

add_executable(pipewirebackend_probe EXCLUDE_FROM_ALL
    pipewirebackend_probe.cpp
    ${CMAKE_SOURCE_DIR}/src/pipewireaudiobackend.cpp
    ${CMAKE_SOURCE_DIR}/src/spectrumanalyzer.cpp
)

target_include_directories(pipewirebackend_probe PRIVATE ${CMAKE_SOURCE_DIR}/src)
target_link_libraries(pipewirebackend_probe PRIVATE PkgConfig::PipeWire)

add_executable(systemdiscovery_test
    ${CMAKE_SOURCE_DIR}/src/applicationcategoryclassifier.cpp
    ${CMAKE_SOURCE_DIR}/src/systemdiscovery.cpp
    ${CMAKE_SOURCE_DIR}/src/commandclassification.cpp
    ${CMAKE_SOURCE_DIR}/src/desktoplauncherresolver.cpp
    ${CMAKE_SOURCE_DIR}/src/desktopshortcutwriter.cpp
    ${CMAKE_SOURCE_DIR}/src/dropurlpolicy.cpp
    systemdiscovery_test.cpp
)
target_include_directories(systemdiscovery_test PRIVATE ${CMAKE_SOURCE_DIR}/src)
target_link_libraries(systemdiscovery_test PRIVATE Qt6::Core Qt6::Qml KF6::ConfigCore KF6::Service KF6::KIOCore KF6::KIOGui KF6::JobWidgets KF6::I18n)
add_test(NAME systemdiscovery_test COMMAND systemdiscovery_test)

add_executable(trashintegration_test
    ${CMAKE_SOURCE_DIR}/src/trashintegration.cpp
    ${CMAKE_SOURCE_DIR}/src/dropurlpolicy.cpp
    trashintegration_test.cpp
)
target_include_directories(trashintegration_test PRIVATE ${CMAKE_SOURCE_DIR}/src)
target_link_libraries(trashintegration_test PRIVATE
    Qt6::Core
    Qt6::Qml
    KF6::JobWidgets
    KF6::KIOCore
    KF6::KIOGui
)
add_test(NAME trashintegration_test COMMAND trashintegration_test)
set_tests_properties(trashintegration_test PROPERTIES SKIP_RETURN_CODE 77)

find_program(PUNCHI_DBUS_RUN_SESSION NAMES dbus-run-session REQUIRED)

add_executable(plasmoid_full_load_test plasmoid_full_load_test.cpp)
add_dependencies(plasmoid_full_load_test
    punchidockintegration
    punchidockintegrationplugin
)
target_compile_definitions(plasmoid_full_load_test PRIVATE
    PUNCHI_PROJECT_SOURCE_DIR="${CMAKE_SOURCE_DIR}"
    PUNCHI_INTEGRATION_LIBRARY="$<TARGET_FILE:punchidockintegration>"
    PUNCHI_INTEGRATION_PLUGIN="$<TARGET_FILE:punchidockintegrationplugin>"
    PUNCHI_INTEGRATION_QMLDIR="${CMAKE_BINARY_DIR}/bin/org/punchi/dock/qmldir"
    PUNCHI_INTEGRATION_QMLTYPES="${CMAKE_BINARY_DIR}/bin/org/punchi/dock/punchidockintegration.qmltypes"
)
target_link_libraries(plasmoid_full_load_test PRIVATE
    Qt6::Gui
    Qt6::Quick
    Qt6::Test
    KF6::ConfigQml
    KF6::CoreAddons
    KF6::Package
    Plasma::Plasma
    Plasma::PlasmaQuick
)
add_test(
    NAME plasmoid_full_load_test
    COMMAND ${PUNCHI_DBUS_RUN_SESSION}
        --config-file=${CMAKE_CURRENT_SOURCE_DIR}/dbus-session-isolated.conf
        --
        $<TARGET_FILE:plasmoid_full_load_test>
)
set_tests_properties(plasmoid_full_load_test PROPERTIES
    ENVIRONMENT "QT_QPA_PLATFORM=offscreen;QT_QUICK_BACKEND=software"
    TIMEOUT 60
)

add_executable(punchi_qmltestrunner punchi_qmltestrunner.cpp)
target_link_libraries(punchi_qmltestrunner PRIVATE
    Qt6::Qml
    Qt6::QuickTest
    KF6::I18n
)
if(TARGET KF6::I18nQml)
    target_link_libraries(punchi_qmltestrunner PRIVATE KF6::I18nQml)
    target_compile_definitions(punchi_qmltestrunner PRIVATE
        PUNCHI_HAS_KLOCALIZED_QML_CONTEXT
    )
endif()

function(punchi_add_qml_test test_name qml_file)
    add_test(
        NAME ${test_name}
        COMMAND $<TARGET_FILE:punchi_qmltestrunner>
            -input ${CMAKE_CURRENT_SOURCE_DIR}/${qml_file}
    )
    set_tests_properties(${test_name} PROPERTIES
        ENVIRONMENT "QT_QPA_PLATFORM=offscreen"
        FAIL_REGULAR_EXPRESSION "QWARN[ ]*:|TypeError:|ReferenceError:"
    )
endfunction()

punchi_add_qml_test(
    popup_coordinator_state_test
    popup_coordinator_state_test.qml
)
punchi_add_qml_test(
    popup_visible_gap_placement_test
    popup_visible_gap_placement_test.qml
)
punchi_add_qml_test(
    punchimenu_mapped_surface_geometry_test
    punchimenu_mapped_surface_geometry_test.qml
)
punchi_add_qml_test(task_popup_surface_test task_popup_surface_test.qml)
punchi_add_qml_test(
    app_actions_popup_runtime_test
    app_actions_popup_runtime_test.qml
)
punchi_add_qml_test(
    punchimenu_application_state_test
    punchimenu_application_state_test.qml
)
punchi_add_qml_test(
    dynamic_applications_marker_logic_test
    dynamic_applications_marker_logic_test.qml
)
punchi_add_qml_test(
    dynamic_applications_options_test
    dynamic_applications_options_test.qml
)
punchi_add_qml_test(
    dock_reorder_drag_layer_test
    dock_reorder_drag_layer_test.qml
)
punchi_add_qml_test(
    container_launcher_drop_logic_test
    container_launcher_drop_logic_test.qml
)
punchi_add_qml_test(
    dock_folder_view_context_test
    dock_folder_view_context_test.qml
)
punchi_add_qml_test(
    popup_spacing_metrics_test
    popup_spacing_metrics_test.qml
)
punchi_add_qml_test(
    dock_item_launcher_drop_state_test
    dock_item_launcher_drop_state_test.qml
)
punchi_add_qml_test(
    item_action_editor_drop_test
    item_action_editor_drop_test.qml
)
punchi_add_qml_test(
    themed_separator_lifecycle_test
    themed_separator_lifecycle_test.qml
)
