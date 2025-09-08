# ################################################################
# SQLITE Version Configuration
# ################################################################

# Setup CMake policy version
set(SQLITE_MAX_VALIDATED_CMAKE_MAJOR_VERSION "3")
set(SQLITE_MAX_VALIDATED_CMAKE_MINOR_VERSION "13")

# Determine appropriate policy version
if("${SQLITE_MAX_VALIDATED_CMAKE_MAJOR_VERSION}" EQUAL "${CMAKE_MAJOR_VERSION}" AND
   "${SQLITE_MAX_VALIDATED_CMAKE_MINOR_VERSION}" GREATER "${CMAKE_MINOR_VERSION}")
    set(SQLITE_CMAKE_POLICY_VERSION "${CMAKE_VERSION}")
else()
    set(SQLITE_CMAKE_POLICY_VERSION 
      "${SQLITE_MAX_VALIDATED_CMAKE_MAJOR_VERSION}.${SQLITE_MAX_VALIDATED_CMAKE_MINOR_VERSION}.0")
endif()

cmake_policy(VERSION ${SQLITE_CMAKE_POLICY_VERSION})

# Parse version from header file
include(GetSqlite3LibraryVersion)
GetSqlite3LibraryVersion(${SQLITE_SOURCE_DIR}/VERSION sqlite3_VERSION_MAJOR 
                      sqlite3_VERSION_MINOR 
                      sqlite3_VERSION_PATCH
                      )

# Set version variables
set(SQLITE_SHORT_VERSION "${sqlite3_VERSION_MAJOR}.${sqlite3_VERSION_MINOR}")
set(SQLITE_FULL_VERSION "${sqlite3_VERSION_MAJOR}.${sqlite3_VERSION_MINOR}.${sqlite3_VERSION_PATCH}")

# Project metadata
set(sqlite_HOMEPAGE_URL "https://github.com/sqlite/sqlite.git")
set(sqlite_DESCRIPTION "sqlite3 is embedded database engine!")

message(STATUS "SQLITE VERSION: ${sqlite3_VERSION_MAJOR}.${sqlite3_VERSION_MINOR}.${sqlite3_VERSION_PATCH}")
