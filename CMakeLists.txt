cmake_minimum_required(VERSION 3.13)
cmake_policy(SET CMP0060 NEW)
project(compas_lcmtypes VERSION 0.1)

set(POD_NAME ${PROJECT_NAME})

if(NOT DEFINED NO_COLCON)
  message(STATUS "Colcon detected")
  find_package(ament_cmake REQUIRED)
  find_package(compas_cmake REQUIRED)
endif()

find_package(lcm REQUIRED)
include(${LCM_USE_FILE})

option(LCMTYPES_USE_PYTHON "Build python compas lcmtypes" ON)
option(LCMTYPES_USE_JAVA "Build java compas lcmtypes" ON)

if(LCMTYPES_USE_PYTHON)
  find_package(Python3 COMPONENTS Interpreter)
  if(Python3_FOUND)
    set(PYTHONINTERP_FOUND ${Python3_FOUND})
    set(Python_EXECUTABLE ${Python3_EXECUTABLE})
    set(python_args PYTHON_SOURCES python_install_sources)
  endif()
endif()

if(LCMTYPES_USE_JAVA)
  find_package(Java)
  if(JAVA_FOUND)
    include(UseJava)
    set(java_args JAVA_SOURCES java_sources)
  endif()
endif()

# cmake integration of `lcm-gen`
file(GLOB __lcmtypes "${PROJECT_SOURCE_DIR}/*.lcm")
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

# ========
# Build
# ========

# C library
include(GenerateExportHeader)
lcm_add_library(${PROJECT_NAME} C STATIC ${c_sources} ${c_headers})
generate_export_header(${PROJECT_NAME})
target_include_directories(${PROJECT_NAME} INTERFACE
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>)

# C++ interface (header-only) library
lcm_add_library(${PROJECT_NAME}-cpp CPP ${cpp_headers})
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

lcm_install_headers(DESTINATION include
  ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_export.h
  ${c_install_headers}
  ${cpp_install_headers}
)
set(all_targets ${PROJECT_NAME} ${PROJECT_NAME}-cpp)

if(NOT DEFINED NO_COLCON)
  install(TARGETS ${all_targets}
    EXPORT export_${PROJECT_NAME}
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION lib
    INCLUDES DESTINATION include
  )
  ament_export_targets(export_${PROJECT_NAME})
  ament_export_dependencies(compas_cmake)
else()
  pods_export_targets("${all_targets}")
endif()


if(DEFINED NO_COLCON)
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
endif()

if(JAVA_FOUND)
  install_jar(${PROJECT_NAME}-jar share/java)
endif()

if(NOT DEFINED NO_COLCON)
  ament_package()
endif()
