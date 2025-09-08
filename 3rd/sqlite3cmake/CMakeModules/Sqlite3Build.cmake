# ################################################################
# Sqlite3 Build Targets Configuration
# ################################################################

# Always build the library first (this defines SQLITE_BUILD_STATIC/SHARED options)
add_subdirectory(src)
 
# Clean-all target for thorough cleanup
add_custom_target(clean-all
    COMMAND ${CMAKE_BUILD_TOOL} clean
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_BINARY_DIR}/
    COMMENT "Performing complete clean including build directory"
)
