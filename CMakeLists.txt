cmake_minimum_required(VERSION 3.13)
cmake_policy(SET CMP0060 NEW)
project(compas_lcmtypes VERSION 0.3.0)

# Option to build the C library and generate C types (default: ON)
option(LCMTYPES_BUILD_C "Build and install the C library and generate C types" ON)

set(POD_NAME ${PROJECT_NAME})

find_package(lcm REQUIRED)
include(${LCM_USE_FILE})

find_package(Python3 COMPONENTS Interpreter)
if(Python3_FOUND)
  set(PYTHONINTERP_FOUND ${Python3_FOUND})
  set(Python_EXECUTABLE ${Python3_EXECUTABLE})
  set(python_args PYTHON_SOURCES python_install_sources)
endif()

find_package(Java)
if(JAVA_FOUND)
  include(UseJava)
  set(java_args JAVA_SOURCES java_sources)
endif()

# Locate .lcm files
file(GLOB __lcmtypes "${PROJECT_SOURCE_DIR}/*.lcm")

# Conditionally generate types based on the LCMTYPES_BUILD_C option.
# When the C library is to be built, generate both C and C++ types.
# Otherwise, do not generate the C types.
if(LCMTYPES_BUILD_C)
  lcm_wrap_types(
    C_EXPORT ${PROJECT_NAME}
    C_SOURCES c_sources
    C_HEADERS c_install_headers
    CPP_HEADERS cpp_install_headers
    CPP11
    ${python_args}
    ${java_args}
    ${__lcmtypes}
  )
else()
  lcm_wrap_types(
    CPP_HEADERS cpp_install_headers
    CPP11
    ${python_args}
    ${java_args}
    ${__lcmtypes}
  )
endif()

# ========
# Build
# ========

# Conditionally build the C library if LCMTYPES_BUILD_C is ON
if(LCMTYPES_BUILD_C)
  include(GenerateExportHeader)
  lcm_add_library(${PROJECT_NAME} C STATIC ${c_sources} ${c_headers})
  generate_export_header(${PROJECT_NAME})
  target_include_directories(${PROJECT_NAME} INTERFACE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>)
endif()

# Always build the C++ interface (header-only) library
lcm_add_library(${PROJECT_NAME}-cpp CPP ${cpp_headers})
# Dummy target to ensure generating the C++ headers
add_custom_target(force-cpp-lcmtypes ALL DEPENDS ${PROJECT_NAME}-cpp)
target_include_directories(${PROJECT_NAME}-cpp INTERFACE
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>)

# Java
if(JAVA_FOUND)
  add_jar(${PROJECT_NAME}-jar
    OUTPUT_NAME ${PROJECT_NAME}
    INCLUDE_JARS lcm-java
    SOURCES ${java_sources}
  )
endif()

# ========
# Install
# ========

# Conditionally install the C export header and C installation headers
if(LCMTYPES_BUILD_C)
  lcm_install_headers(DESTINATION include
    ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_export.h
    ${c_install_headers}
    ${cpp_install_headers}
  )
else()
  # If the C library isn't built, install only the C++ headers
  lcm_install_headers(DESTINATION include
    ${cpp_install_headers}
  )
endif()

# Export only the targets that were built
set(targets ${PROJECT_NAME}-cpp)
if(LCMTYPES_BUILD_C)
  list(APPEND targets ${PROJECT_NAME})
endif()
pods_export_targets("${targets}")

if(Python3_FOUND)
  set(PY_VERSION_SHORT "${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR}")
  execute_process(
    COMMAND "${Python3_EXECUTABLE}" -c "if True:
      import sysconfig as sc
      import os
      print(os.path.join(sc.get_path('stdlib', vars={'installed_base': '${CMAKE_INSTALL_PREFIX}', 'py_version_short': '${PY_VERSION_SHORT}'}), 'site-packages'))"
    OUTPUT_VARIABLE PY_WS_SITE_PACKAGES
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  set(PY_PACKAGE_PATH "${PY_WS_SITE_PACKAGES}/${PROJECT_NAME}")
  pods_generate_python_dist_info(${PY_WS_SITE_PACKAGES} ${PROJECT_NAME} ${PROJECT_VERSION})

  lcm_install_python(
    DESTINATION ${PY_PACKAGE_PATH}
    ${python_install_sources}
  )

  install(
    CODE
      "execute_process(COMMAND ${CMAKE_COMMAND} -E touch ${PY_PACKAGE_PATH}/__init__.py)"
  )

  install(CODE "message(STATUS \"compas_lcmtypes python package added to ${PY_WS_SITE_PACKAGES}\nRemember to add this directory to PYTHONPATH (source workspace setup script)\")")
endif()

if(JAVA_FOUND)
  install_jar(${PROJECT_NAME}-jar share/java)
endif()
