cmake_minimum_required(VERSION 3.10)
project(sqlite3 VERSION 3.50.4 LANGUAGES C)

# 基础配置
set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)



# 编译选项（从构建日志提取）
set(SQLITE_COMMON_DEFINITIONS
    -DSQLITE_ENABLE_RTREE=1
    -DSQLITE_THREADSAFE=1
    -DSQLITE_MUTEX=unix
    -DSQLITE_ENABLE_MATH_FUNCTIONS
    -DSQLITE_ENABLE_MEMSYS5
    -DSQLITE_ENABLE_SELECTTRACE
    -DSQLITE_ENABLE_WHERETRACE
    -DSQLITE_HAVE_ZLIB=1
)

# Debug 模式额外选项
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    list(APPEND SQLITE_COMMON_DEFINITIONS
        -DSQLITE_DEBUG
    )
endif()

# 源文件
set(SQLITE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../src")
 
set(SQLITE_SHELL_SOURCES
    ${SQLITE_SOURCE_DIR}/shell.c
    # ${SQLITE_SOURCE_DIR}/sqlite3.h
    # ${SQLITE_SOURCE_DIR}/sqlite3ext.h    
) 

# 构建命令行工具
add_executable(sqlite3_shell ${SQLITE_SHELL_SOURCES})

find_package(SQLite3 REQUIRED)
if(SQLite3_FOUND)
    message(STATUS "sq....SQLite3 library is FOUND")   
    target_link_libraries(sqlite3_shell PRIVATE SQLite::SQLite3)   
else()
    message(SEND_ERROR "sq....SQLite3 library is missing")     
endif(SQLite_FOUND)


# Add gzip support
if (SQLITE3_ZLIB_SUPPORT)
    find_package(ZLIB REQUIRED)

    if (ZLIB_FOUND)
        message(STATUS "sq....ZLIB library is FOUND")
        include_directories(${ZLIB_INCLUDE_DIRS})
        target_link_libraries(sqlite3_shell PRIVATE ${ZLIB_LIBRARIES})
    else ()
        message(SEND_ERROR "ZLIB library is missing")
    endif ()
endif ()

target_include_directories(sqlite3_shell
        INTERFACE $<BUILD_INTERFACE:${SQLITE_SHELL_SOURCES}>
        )
set_target_properties(sqlite3_shell PROPERTIES OUTPUT_NAME sqlite3shell)

target_compile_definitions(sqlite3_shell PRIVATE
    ${SQLITE_COMMON_DEFINITIONS}
)

# 安装配置
install(TARGETS sqlite3_shell  
    RUNTIME DESTINATION bin 
)
 