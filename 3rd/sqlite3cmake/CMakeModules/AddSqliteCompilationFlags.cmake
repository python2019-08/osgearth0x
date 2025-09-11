include(CheckCCompilerFlag)
if(CMAKE_CXX_COMPILER)
    include(CheckCXXCompilerFlag)
endif()

if (CMAKE_VERSION VERSION_GREATER_EQUAL 3.18)
    set(SQLITE_HAVE_CHECK_LINKER_FLAG true)
else ()
    set(SQLITE_HAVE_CHECK_LINKER_FLAG false)
endif ()
if (SQLITE_HAVE_CHECK_LINKER_FLAG)
    include(CheckLinkerFlag)
endif()

function(EnableCompilerFlag _flag _C _CXX _LD)
    string(REGEX REPLACE "\\+" "PLUS" varname "${_flag}")
    string(REGEX REPLACE "[^A-Za-z0-9]+" "_" varname "${varname}")
    string(REGEX REPLACE "^_+" "" varname "${varname}")
    string(TOUPPER "${varname}" varname)
    if (_C)
        CHECK_C_COMPILER_FLAG(${_flag} C_FLAG_${varname})
        if (C_FLAG_${varname})
            set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${_flag}" PARENT_SCOPE)
        endif ()
    endif ()
    if (_CXX AND CMAKE_CXX_COMPILER)
        CHECK_CXX_COMPILER_FLAG(${_flag} CXX_FLAG_${varname})
        if (CXX_FLAG_${varname})
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${_flag}" PARENT_SCOPE)
        endif ()
    endif ()
    if (_LD)
        # We never add a linker flag with CMake < 3.18. We will
        # implement CHECK_LINKER_FLAG() like feature for CMake < 3.18
        # or require CMake >= 3.18 when we need to add a required
        # linker flag in future.
        #
        # We also skip linker flags check for MSVC compilers (which includes
        # clang-cl) since currently check_linker_flag() doesn't give correct
        # results for this configuration,
        # see: https://gitlab.kitware.com/cmake/cmake/-/issues/22023
        if (SQLITE_HAVE_CHECK_LINKER_FLAG AND NOT MSVC)
            CHECK_LINKER_FLAG(C ${_flag} LD_FLAG_${varname})
        else ()
            set(LD_FLAG_${varname} false)
        endif ()
        if (LD_FLAG_${varname})
            set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${_flag}" PARENT_SCOPE)
            set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${_flag}" PARENT_SCOPE)
        endif ()
    endif ()
endfunction()

macro(ADD_SQLITE_COMPILATION_FLAGS _C _CXX _LD)
    # We set SQLITE_HAS_NOEXECSTACK if we are certain we've set all the required
    # compiler flags to mark the stack as non-executable.
    set(SQLITE_HAS_NOEXECSTACK false)

    if (CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang" OR MINGW) #Not only UNIX but also WIN32 for MinGW
        # It's possible to select the exact standard used for compilation.
        # It's not necessary, but can be employed for specific purposes.
        # Note that SQLITE source code is compatible with both C++98 and above
        # and C-gnu90 (c90 + long long + variadic macros ) and above
        # EnableCompilerFlag("-std=c++11" false true) # Set C++ compilation to c++11 standard
        # EnableCompilerFlag("-std=c99" true false)   # Set C compilation to c99 standard
        if (CMAKE_CXX_COMPILER_ID MATCHES "Clang" AND MSVC)
            # clang-cl normally maps -Wall to -Weverything.
            EnableCompilerFlag("/clang:-Wall" _C _CXX false)
        else ()
            EnableCompilerFlag("-Wall" _C _CXX false)
        endif ()
        EnableCompilerFlag("-Wextra" _C _CXX false)
        EnableCompilerFlag("-Wundef" _C _CXX false)
        EnableCompilerFlag("-Wshadow" _C _CXX false)
        EnableCompilerFlag("-Wcast-align" _C _CXX false)
        EnableCompilerFlag("-Wcast-qual" _C _CXX false)
        EnableCompilerFlag("-Wstrict-prototypes" _C false false)
        # Enable asserts in Debug mode
        if (CMAKE_BUILD_TYPE MATCHES "Debug")
            EnableCompilerFlag("-DDEBUGLEVEL=1" _C _CXX false)
        endif ()
        # Add noexecstack flags
        # LDFLAGS
        EnableCompilerFlag("-Wl,-z,noexecstack" false false _LD)
        # CFLAGS & CXXFLAGS
        EnableCompilerFlag("-Qunused-arguments" _C _CXX false)
        EnableCompilerFlag("-Wa,--noexecstack" _C _CXX false)
        # NOTE: Using 3 nested ifs because the variables are sometimes
        # empty if the condition is false, and sometimes equal to false.
        # This implicitly converts them to truthy values. There may be
        # a better way to do this, but this reliably works.
        if (${LD_FLAG_WL_Z_NOEXECSTACK})
            if (${C_FLAG_WA_NOEXECSTACK})
                if (${CXX_FLAG_WA_NOEXECSTACK})
                    # We've succeeded in marking the stack as non-executable
                    set(SQLITE_HAS_NOEXECSTACK true)
                endif()
            endif()
        endif()
    elseif (MSVC) # Add specific compilation flags for Windows Visual

        set(ACTIVATE_MULTITHREADED_COMPILATION "ON" CACHE BOOL "activate multi-threaded compilation (/MP flag)")
        if (CMAKE_GENERATOR MATCHES "Visual Studio" AND ACTIVATE_MULTITHREADED_COMPILATION)
            EnableCompilerFlag("/MP" _C _CXX false)
        endif ()

        # UNICODE SUPPORT
        EnableCompilerFlag("/D_UNICODE" _C _CXX false)
        EnableCompilerFlag("/DUNICODE" _C _CXX false)
        # Enable asserts in Debug mode
        if (CMAKE_BUILD_TYPE MATCHES "Debug")
            EnableCompilerFlag("/DDEBUGLEVEL=1" _C _CXX false)
        endif ()
    endif ()

    # Remove duplicates compilation flags
    foreach (flag_var CMAKE_C_FLAGS CMAKE_C_FLAGS_DEBUG CMAKE_C_FLAGS_RELEASE
             CMAKE_C_FLAGS_MINSIZEREL CMAKE_C_FLAGS_RELWITHDEBINFO
             CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_DEBUG CMAKE_CXX_FLAGS_RELEASE
             CMAKE_CXX_FLAGS_MINSIZEREL CMAKE_CXX_FLAGS_RELWITHDEBINFO)
        if( ${flag_var} )
            separate_arguments(${flag_var})
            string(REPLACE ";" " " ${flag_var} "${${flag_var}}")
        endif()
    endforeach ()
 

endmacro()






macro(CONFIG_ANDROID_COMPILATION_FLAGS)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ffunction-sections -fdata-sections")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -ffunction-sections -fdata-sections")


    # `-fuse-ld` 是 GCC/Clang 编译器的一个选项，用于指定链接器（linker）的类型。
    # ### **作用**
    # `-fuse-ld` 允许你选择不同的链接器，例如：
    # - `-fuse-ld=gold` → 使用 **GNU gold** 链接器
    # - `-fuse-ld=bfd` → 使用 **GNU binutils** 的传统 `ld.bfd` 链接器
    # - `-fuse-ld=lld` → 使用 **LLVM lld** 链接器（LLVM 项目的高性能链接器）
    # - `-fuse-ld=mold` → 使用 **mold**（现代高性能链接器）
    # ----------- 
    # if ((ANDROID_ABI STREQUAL "armeabi-v7a") OR (ANDROID_ABI STREQUAL "arm64-v8a") OR
    #     (ANDROID_ABI STREQUAL "x86") OR (ANDROID_ABI STREQUAL "x86_64"))
    #     # Use Identical Code Folding on platforms that support the gold linker.
    #     # -fuse-ld=gold 改为 -fuse-ld=lld ; NDK 默认使用 lld, gold对 Android AArch64 支持不完善
    #     # 移除 "-Wl,--icf=safe", lld的 ICF 行为与 gold不同，无需手动指定
    #     set(CMAKE_EXE_LINKER_FLAGS "-fuse-ld=gold -Wl,--icf=safe ${CMAKE_EXE_LINKER_FLAGS}")
    #     set(CMAKE_SHARED_LINKER_FLAGS "-fuse-ld=gold -Wl,--icf=safe ${CMAKE_SHARED_LINKER_FLAGS}")
    # endif()

    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--gc-sections ")
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--gc-sections ")

    # `-flto` 是 GCC 和 Clang 编译器的一个优化选项，全称是 **Link Time Optimization（链接时优化）**。
    # 它的作用是在编译和链接阶段进行全局优化，以提高程序的运行性能或减少代码体积。
    # 
    # Use LTO in Release builds. Due to a toolchain issue, -O2 is also required for the link step
    #  (https://github.com/android-ndk/ndk/issues/721)
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -flto")
    set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -flto")
    set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO} -flto")
    set(CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELWITHDEBINFO} -flto")
    set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} -flto -O2")
    set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} -flto -O2")
    set(CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO "${CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO} -flto -O2")
    set(CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO "${CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO} -flto -O2")
endmacro()