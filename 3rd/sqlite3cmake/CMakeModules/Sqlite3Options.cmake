# ################################################################
# ZSTD Build Options Configuration
# ################################################################

# RTREE support configuration
option(SQLITE_ENABLE_ZLIB "Enable Zlib support" ON)


option(SQLITE_BUILD_STATIC "BUILD STATIC LIBRARIES" ON) 
option(SQLITE_BUILD_TOOLS "Build command-line tools" ON) 
 
# SQLITE_MUTEX support configuration
set(SQLITE_MUTEX "unix" CACHE STRING "Build sqlite3 with MUTEX support (unix, win or no)")
set_property(CACHE SQLITE_MUTEX PROPERTY STRINGS "unix" "win" "no")

if(${SQLITE_MUTEX} STREQUAL "unix")
   add_definitions(-DSQLITE_OS_UNIX=1) 
   add_definitions(-DSQLITE_MUTEX_PTHREADS)
elseif( ${SQLITE_MUTEX} STREQUAL "win" )
 
   add_definitions(-DSQLITE_OS_WIN=1) 
   add_definitions(-DSQLITE_MUTEX_W32) 
else()
   message(FATAL_ERROR "....error: SQLITE_MUTEX value is error!")
endif()
 
 
# Android-specific configuration
if(ANDROID) 
    # Handle old Android API levels
    if((NOT ANDROID_PLATFORM_LEVEL) OR (ANDROID_PLATFORM_LEVEL VERSION_LESS 24))
        message(STATUS "Configuring for old Android API - disabling fseeko/ftello")
        add_compile_definitions(LIBC_NO_FSEEKO)
    endif()
else()
    message(STATUS "NOT 4 ANDROID")
endif()

 
  
# Set global definitions
add_definitions(-DXXH_NAMESPACE=SQLITE3_)
