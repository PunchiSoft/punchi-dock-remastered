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
    NAME window_thumbnail_contract_test
    COMMAND ${PYTHON3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/window_thumbnail_contract_test.py
)

add_test(
    NAME popup_menu_surface_contract_test
    COMMAND ${PYTHON3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/popup_menu_surface_contract_test.py
)

add_test(
    NAME kubuntu_version_detection_test
    COMMAND ${PYTHON3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/kubuntu_version_detection_test.py
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

add_executable(pipewirebackend_probe EXCLUDE_FROM_ALL
    pipewirebackend_probe.cpp
    ${CMAKE_SOURCE_DIR}/src/pipewireaudiobackend.cpp
    ${CMAKE_SOURCE_DIR}/src/spectrumanalyzer.cpp
)

target_include_directories(pipewirebackend_probe PRIVATE ${CMAKE_SOURCE_DIR}/src)
target_link_libraries(pipewirebackend_probe PRIVATE PkgConfig::PipeWire)

add_executable(systemdiscovery_test
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

if(TARGET Qt6::qmltestrunner)
    set(POPUP_COORDINATOR_QML_TEST_RUNNER $<TARGET_FILE:Qt6::qmltestrunner>)
else()
    find_program(POPUP_COORDINATOR_QML_TEST_RUNNER
        NAMES qmltestrunner qmltestrunner6 qmltestrunner-qt6
        REQUIRED
    )
endif()

add_test(
    NAME popup_coordinator_state_test
    COMMAND ${POPUP_COORDINATOR_QML_TEST_RUNNER}
        -input ${CMAKE_CURRENT_SOURCE_DIR}/popup_coordinator_state_test.qml
)
set_tests_properties(popup_coordinator_state_test PROPERTIES
    ENVIRONMENT "QT_QPA_PLATFORM=offscreen"
)

add_test(
    NAME task_popup_surface_test
    COMMAND ${POPUP_COORDINATOR_QML_TEST_RUNNER}
        -input ${CMAKE_CURRENT_SOURCE_DIR}/task_popup_surface_test.qml
)
set_tests_properties(task_popup_surface_test PROPERTIES
    ENVIRONMENT "QT_QPA_PLATFORM=offscreen"
)
