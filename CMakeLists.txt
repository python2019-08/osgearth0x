cmake_minimum_required(VERSION 3.20)
 
# Project setup ..........................................................

project(
    OSGEARTH0x
    DESCRIPTION "osgEarth 0x" 
    LANGUAGES CXX C) 

# Require C++14
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Detect out-of-source build. We'll need this for protobuf generated files.
if (NOT "${PROJECT_SOURCE_DIR}" STREQUAL "${PROJECT_BINARY_DIR}")
    message(STATUS "Detected an out-of-source build. Kudos.")    
    set(OSGEARTH_OUT_OF_SOURCE_BUILD TRUE)
else()
    message(FATAL_ERROR "Detected a in-source build.")  
endif()

# We have some custom .cmake scripts not in the official distribution.
# set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH};${PROJECT_SOURCE_DIR}/cmake") 
 
set(CMAKE_INSTALL_PREFIX ${CMAKE_BINARY_DIR}/install)

include(GNUInstallDirs)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/${CMAKE_INSTALL_BINDIR})
   
  
option(USE_CMAKE_TO_BUILD_3RD "Build PROJ library shared." OFF)
if(USE_CMAKE_TO_BUILD_3RD)
    add_subdirectory(3rd) 
endif(USE_CMAKE_TO_BUILD_3RD)

add_subdirectory(src)     

# IDE configuration ......................................................

set_property(GLOBAL PROPERTY USE_FOLDERS ON)
set_property(GLOBAL PROPERTY PREDEFINED_TARGETS_FOLDER "CMake Targets")
 