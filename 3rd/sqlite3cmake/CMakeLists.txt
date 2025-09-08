# ################################################################
# Copyright (c) xxxx, Inc. and affiliates.
# All rights reserved.
#
#  
#  remark: curl/CMakeLists.txt 中处理了android版本，可参考。
#  
# ################################################################

cmake_minimum_required(VERSION 3.10 FATAL_ERROR)

#-----------------------------------------------------------------------------
# Setup CMake environment
#-----------------------------------------------------------------------------
set(CMAKE_BUILD_WITH_INSTALL_RPATH ON)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/CMakeModules")

# Define project paths
set(SQLITE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src")
 


#-----------------------------------------------------------------------------
# Configure CMake policies and version
#-----------------------------------------------------------------------------
include(Sqlite3Version)

#-----------------------------------------------------------------------------
# Project declaration
#-----------------------------------------------------------------------------
project(sqlite3
    VERSION "${SQLITE_FULL_VERSION}"
    LANGUAGES C  
    HOMEPAGE_URL "${sqlite_HOMEPAGE_URL}"
    DESCRIPTION "${sqlite_DESCRIPTION}"
)

# 配置编译选项
set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

if(CMAKE_CROSSCOMPILING)
  message(STATUS "Cross-compiling: "
    "${CMAKE_HOST_SYSTEM_NAME}/${CMAKE_HOST_SYSTEM_PROCESSOR} -> "
    "${CMAKE_SYSTEM_NAME}/${CMAKE_SYSTEM_PROCESSOR}")
else()
  message(STATUS "**NOT** Cross-compiling: "
    "${CMAKE_HOST_SYSTEM_NAME}/${CMAKE_HOST_SYSTEM_PROCESSOR} -> "
    "${CMAKE_SYSTEM_NAME}/${CMAKE_SYSTEM_PROCESSOR}")    
endif()

#-----------------------------------------------------------------------------
# Build type configuration
#-----------------------------------------------------------------------------
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    message(STATUS "Setting build type to 'Release' as none was specified.")
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build." FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

#-----------------------------------------------------------------------------
# Include standard modules
#-----------------------------------------------------------------------------
include(GNUInstallDirs)

#-----------------------------------------------------------------------------
# Display installation information
#-----------------------------------------------------------------------------
message(STATUS "CMAKE_INSTALL_PREFIX: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "CMAKE_INSTALL_LIBDIR: ${CMAKE_INSTALL_LIBDIR}")

#-----------------------------------------------------------------------------
# Configure build options
#-----------------------------------------------------------------------------
include(Sqlite3Options)

#-----------------------------------------------------------------------------
# Configure compilation flags
#-----------------------------------------------------------------------------
include(AddSqliteCompilationFlags)
ADD_SQLITE_COMPILATION_FLAGS(ON SQLITE3_ENABLE_CXX ON)

CONFIG_ANDROID_COMPILATION_FLAGS()

#-----------------------------------------------------------------------------
# Configure dependencies
#-----------------------------------------------------------------------------
include(Sqlite3Dependencies)

#-----------------------------------------------------------------------------
# Configure build targets
#-----------------------------------------------------------------------------
include(Sqlite3Build)

#-----------------------------------------------------------------------------
# Configure package generation
#-----------------------------------------------------------------------------
include(Sqlite3Package)
