# ################################################################
# Sqlite3 Package Configuration
# ################################################################

include(CMakePackageConfigHelpers)

# Generate version file
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/sqlite3ConfigVersion.cmake"
    VERSION ${zstd_VERSION}
    COMPATIBILITY SameMajorVersion
)

# Export targets for build directory
export(EXPORT sqliteExports
    FILE "${CMAKE_CURRENT_BINARY_DIR}/sqlite3Targets.cmake"
    NAMESPACE SQLite::
)

# Configure package for installation
set(ConfigPackageLocation ${CMAKE_INSTALL_LIBDIR}/cmake/sqlite3)

# Install exported targets
install(EXPORT sqliteExports
    FILE sqlite3Targets.cmake
    NAMESPACE SQLite::
    DESTINATION ${ConfigPackageLocation}
)

# Configure and install package config file
configure_package_config_file(
    sqlite3Config.cmake.in
    "${CMAKE_CURRENT_BINARY_DIR}/sqlite3Config.cmake"
    INSTALL_DESTINATION ${ConfigPackageLocation}
)

# Install config files
install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/sqlite3Config.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/sqlite3ConfigVersion.cmake"
    DESTINATION ${ConfigPackageLocation}
)
