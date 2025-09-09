# ################################################################
# Copyright (c) xxx, Inc. and affiliates.
# All rights reserved.
#
# 
# 
#  
# ################################################################

project(libsqlite3 C ASM)

# set(CMAKE_INCLUDE_CURRENT_DIR TRUE)
 
set(sqlite_core_Sources 
    ${SQLITE_SOURCE_DIR}/sqlite3.c
    )
set(sqlite_core_Headers 
    ${SQLITE_SOURCE_DIR}/sqlite3.h
    ${SQLITE_SOURCE_DIR}/sqlite3ext.h
    )

set(sqlite_shell_Sources 
    ${SQLITE_SOURCE_DIR}/shell.c
    )



# add_compile_options(-DZSTD_DISABLE_ASM)

# Define directories containing the library's public headers
set(PUBLIC_INCLUDE_DIRS ${SQLITE_SOURCE_DIR})
 

# Split project to static and shared libraries build
set(library_targets)
 
add_library(SQLite3 STATIC ${sqlite_core_Sources} ${sqlite_core_Headers})
add_library(SQLite::SQLite3 ALIAS SQLite3)
target_include_directories(SQLite3
        INTERFACE $<BUILD_INTERFACE:${PUBLIC_INCLUDE_DIRS}>
        )
list(APPEND library_targets SQLite3)
  
  
# With MSVC static library needs to be renamed to avoid conflict with import library
if (MSVC OR (WIN32 AND CMAKE_CXX_COMPILER_ID STREQUAL "Clang" AND NOT MINGW))
    set(STATIC_LIBRARY_BASE_NAME sqlite3_static)
else ()
    set(STATIC_LIBRARY_BASE_NAME sqlite3)
endif ()
 
set_target_properties( SQLite3
        PROPERTIES  POSITION_INDEPENDENT_CODE On
        OUTPUT_NAME ${STATIC_LIBRARY_BASE_NAME})
 
set(SQLITE_COMMON_DEFINITIONS
    -DSQLITE_ENABLE_RTREE=1
    -DSQLITE_THREADSAFE=1
    -DSQLITE_MUTEX=unix
    -DSQLITE_ENABLE_MATH_FUNCTIONS
    -DSQLITE_ENABLE_MEMSYS5
    -DSQLITE_ENABLE_SELECTTRACE
    -DSQLITE_ENABLE_WHERETRACE
)
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    list(APPEND SQLITE_COMMON_DEFINITIONS
        -DSQLITE_DEBUG
    )
endif()

if (ZLIB_FOUND)
    list(APPEND SQLITE_COMMON_DEFINITIONS
        -DSQLITE_HAVE_ZLIB=1
    )
    include_directories(${ZLIB_INCLUDE_DIRS})
    target_link_libraries(SQLite3 PRIVATE ${ZLIB_LIBRARIES})
else ()
    message(SEND_ERROR "zlib library is missing")
endif ()


target_compile_definitions(SQLite3 
    PRIVATE ${SQLITE_COMMON_DEFINITIONS}
    # 启用日志中提到的扩展功能
    -DSQLITE_ENABLE_FTS3
    -DSQLITE_ENABLE_FTS4
    -DSQLITE_ENABLE_FTS5
    -DSQLITE_ENABLE_GEOPOLY
    -DSQLITE_ENABLE_SESSION
    -DSQLITE_ENABLE_UPDATE_LIMIT
)

target_compile_options(SQLite3
    PRIVATE "-Wno-int-conversion"
    PRIVATE "-Wno-implicit-fallthrough"
    PRIVATE "-Wno-cast-function-type"
    PRIVATE "-fPIC"
    PRIVATE "-Wall"
    PRIVATE "-Wextra"
)

if(CMAKE_SYSTEM_NAME MATCHES "Android")
    target_link_libraries(SQLite3 PRIVATE
    -lm 
    -ldl
    )    
elseif(CMAKE_SYSTEM_NAME MATCHES "Linux")
    target_link_libraries(SQLite3 PRIVATE
        -lm
        -lpthread
        -ldl
    )    
endif()


# target_link_libraries(mbgl-core
#     PUBLIC jni.hpp
#     PUBLIC -llog
#     PUBLIC -landroid
#     PUBLIC -lz
# )

# add_library(libsqlite3 INTERFACE)
# target_link_libraries(libsqlite3 INTERFACE SQLite3)
# list(APPEND library_targets libsqlite3)
 

if(SQLITE_BUILD_TOOLS)
    add_executable(sqlite3_shell ${sqlite_shell_Sources})
    target_link_libraries(sqlite3_shell PRIVATE SQLite3)
    set_target_properties(sqlite3_shell PROPERTIES OUTPUT_NAME sqlite3)

    target_compile_definitions(sqlite3_shell PRIVATE
        ${SQLITE_COMMON_DEFINITIONS}
    )   
    # list(APPEND library_targets sqlite3_shell)

    install(TARGETS sqlite3_shell
        RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
        COMPONENT runtime
    )
endif(SQLITE_BUILD_TOOLS)



# install target
install(FILES ${sqlite_core_Headers} DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")

install(TARGETS ${library_targets}
    EXPORT sqliteExports
    INCLUDES DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
    # BUNDLE DESTINATION "${CMAKE_INSTALL_BINDIR}"
    # FRAMEWORK DESTINATION "${CMAKE_INSTALL_LIBDIR}" COMPONENT runtime OPTIONAL
    PUBLIC_HEADER DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
    )

 