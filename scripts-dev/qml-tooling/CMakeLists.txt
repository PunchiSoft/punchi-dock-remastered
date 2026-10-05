cmake_minimum_required(VERSION 3.22)
project(PunchiDebianQmlTooling LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
find_package(Qt6 6.6 REQUIRED COMPONENTS Quick Widgets)
find_package(KF6Config REQUIRED)
find_package(PlasmaQuick 6.0 REQUIRED)
find_package(KF6CoreAddons REQUIRED)
find_package(KF6Package REQUIRED)
add_executable(export-plasmoid-types export-plasmoid-types.cpp)
target_link_libraries(export-plasmoid-types PRIVATE
    Qt6::Quick Qt6::Widgets Qt6::QmlPrivate Plasma::PlasmaQuick
    Plasma::Plasma KF6::CoreAddons KF6::Package)

# Optional diagnostic runners. No existing test target or registration changes.
if(PUNCHI_TEST_SOURCE_ROOT AND PUNCHI_TEST_BUILD_ROOT)
    find_package(Qt6 6.8 REQUIRED COMPONENTS QuickTest)
    find_package(KF6I18n REQUIRED)
    foreach(kind IN ITEMS punchi config_items)
        if(kind STREQUAL "punchi")
            set(original punchi_qmltestrunner)
            set(setup PunchiQmlTestSetup)
            set(test_name punchi_qmltests)
        else()
            set(original config_items_qml_test_runner)
            set(setup ConfigItemsTestSetup)
            set(test_name punchi_config_tests)
        endif()
        add_executable(legacy_${original} legacy-test-runner.cpp)
        set_target_properties(legacy_${original} PROPERTIES AUTOMOC ON)
        target_compile_definitions(legacy_${original} PRIVATE
            PUNCHI_ORIGINAL_RUNNER="${PUNCHI_TEST_SOURCE_ROOT}/tests/${original}.cpp"
            PUNCHI_SETUP_CLASS=${setup} PUNCHI_TEST_NAME="${test_name}")
        target_include_directories(legacy_${original} PRIVATE
            "${PUNCHI_TEST_BUILD_ROOT}/tests/${original}_autogen/include")
        target_link_libraries(legacy_${original} PRIVATE Qt6::QuickTest Qt6::Widgets
            KF6::I18n Plasma::PlasmaQuick Plasma::Plasma)
        if(TARGET KF6::I18nQml)
            target_link_libraries(legacy_${original} PRIVATE KF6::I18nQml)
            target_compile_definitions(legacy_${original} PRIVATE PUNCHI_HAS_KLOCALIZED_QML_CONTEXT)
        endif()
    endforeach()
    # Drain the old Kirigami twin-form callback while both forms still exist.
    # Keep the original fixture ownership, setup and every QML assertion.
    file(READ "${PUNCHI_TEST_SOURCE_ROOT}/tests/recent_general_qml_test_runner.cpp" recent_runner)
    set(recent_destroy "    Q_INVOKABLE void destroyPage(QQuickItem *page)\n    {")
    string(FIND "${recent_runner}" "${recent_destroy}" recent_destroy_position)
    if(recent_destroy_position EQUAL -1)
        message(FATAL_ERROR "Review the changed recent fixture before adapting its teardown")
    endif()
    string(REPLACE "${recent_destroy}" "${recent_destroy}\n        QCoreApplication::processEvents(QEventLoop::AllEvents);"
        recent_runner "${recent_runner}")
    file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/recent-general-adapted.cpp" "${recent_runner}")
    add_executable(legacy_recent_general_qml_test_runner legacy-recent-general-runner.cpp)
    target_compile_definitions(legacy_recent_general_qml_test_runner PRIVATE
        PUNCHI_ORIGINAL_RECENT_RUNNER="${CMAKE_CURRENT_BINARY_DIR}/recent-general-adapted.cpp"
        PUNCHI_PROJECT_SOURCE_DIR="${PUNCHI_TEST_SOURCE_ROOT}")
    target_include_directories(legacy_recent_general_qml_test_runner PRIVATE
        "${PUNCHI_TEST_BUILD_ROOT}/tests/recent_general_qml_test_runner_autogen/include")
    target_link_libraries(legacy_recent_general_qml_test_runner PRIVATE
        Qt6::QuickTest KF6::I18n KF6::Package Plasma::PlasmaQuick Plasma::Plasma)
    if(TARGET KF6::I18nQml)
        target_link_libraries(legacy_recent_general_qml_test_runner PRIVATE KF6::I18nQml)
        target_compile_definitions(legacy_recent_general_qml_test_runner PRIVATE
            PUNCHI_HAS_KLOCALIZED_QML_CONTEXT)
    endif()
endif()
