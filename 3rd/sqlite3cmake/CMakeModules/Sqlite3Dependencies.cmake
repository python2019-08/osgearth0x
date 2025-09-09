# ################################################################
#  Dependencies Configuration
# ################################################################

# # Function to handle HP-UX thread configuration
# function(setup_hpux_threads)
#     find_package(Threads)
#     if(NOT Threads_FOUND)
#         set(CMAKE_USE_PTHREADS_INIT 1 PARENT_SCOPE)
#         set(CMAKE_THREAD_LIBS_INIT -lpthread PARENT_SCOPE)
#         set(CMAKE_HAVE_THREADS_LIBRARY 1 PARENT_SCOPE)
#         set(Threads_FOUND TRUE PARENT_SCOPE)
#     endif()
# endfunction()

# Add gzip support
set(ZLIB_FOUND False)
if (SQLITE_ENABLE_ZLIB)
    find_package(ZLIB REQUIRED)
endif ()

# Configure threading support
if(SQLITE_MULTITHREAD_SUPPORT AND UNIX)
    if(CMAKE_SYSTEM_NAME MATCHES "HP-UX")
        message(FATAL_ERROR "SQLITE3 currently does not support HP-UX")
    else()
        set(THREADS_PREFER_PTHREAD_FLAG ON)
        find_package(Threads REQUIRED)
    endif()
    
    if(CMAKE_USE_PTHREADS_INIT)
        set(THREADS_LIBS "${CMAKE_THREAD_LIBS_INIT}")
    else()
        message(SEND_ERROR "SQLITE3 currently does not support thread libraries other than pthreads")
    endif()
endif()
