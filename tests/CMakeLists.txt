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
target_link_libraries(dockthemerepository_test PRIVATE Qt6::Core Qt6::Gui Qt6::Qml)

add_test(NAME dockthemerepository_test COMMAND dockthemerepository_test)

add_executable(pipewirebackend_probe EXCLUDE_FROM_ALL
    pipewirebackend_probe.cpp
    ${CMAKE_SOURCE_DIR}/src/pipewireaudiobackend.cpp
    ${CMAKE_SOURCE_DIR}/src/spectrumanalyzer.cpp
)

target_include_directories(pipewirebackend_probe PRIVATE ${CMAKE_SOURCE_DIR}/src)
target_link_libraries(pipewirebackend_probe PRIVATE PkgConfig::PipeWire)
