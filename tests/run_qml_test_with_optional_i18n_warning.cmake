# SPDX-License-Identifier: GPL-2.0-or-later

if(NOT DEFINED TEST_RUNNER OR NOT DEFINED TEST_INPUT)
    message(FATAL_ERROR "TEST_RUNNER and TEST_INPUT are required")
endif()

execute_process(
    COMMAND "${TEST_RUNNER}" -input "${TEST_INPUT}"
    TIMEOUT 30
    RESULT_VARIABLE test_result
    OUTPUT_VARIABLE test_stdout
    ERROR_VARIABLE test_stderr
)

set(test_output "${test_stdout}${test_stderr}")
string(REGEX REPLACE
    "[^\n]*0 instead of 1 arguments to message \"%1 rows\" supplied before conversion[^\n]*\n?"
    ""
    filtered_output
    "${test_output}"
)
message("${filtered_output}")

if(NOT test_result EQUAL 0)
    message(FATAL_ERROR "QML test exited with status ${test_result}")
endif()

if(filtered_output MATCHES "QWARN[ ]*:|TypeError:|ReferenceError:")
    message(FATAL_ERROR "QML test emitted an unexpected runtime diagnostic")
endif()
