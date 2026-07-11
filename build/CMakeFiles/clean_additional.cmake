# Additional clean files
cmake_minimum_required(VERSION 3.16)

if("${CONFIG}" STREQUAL "" OR "${CONFIG}" STREQUAL "RelWithDebInfo")
  file(REMOVE_RECURSE
  "src/CMakeFiles/punchidockintegration_autogen.dir/AutogenUsed.txt"
  "src/CMakeFiles/punchidockintegration_autogen.dir/ParseCache.txt"
  "src/CMakeFiles/punchidockintegrationplugin_autogen.dir/AutogenUsed.txt"
  "src/CMakeFiles/punchidockintegrationplugin_autogen.dir/ParseCache.txt"
  "src/punchidockintegration_autogen"
  "src/punchidockintegrationplugin_autogen"
  )
endif()
