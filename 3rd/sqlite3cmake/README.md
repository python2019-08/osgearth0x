 sqlite-amalgamation-3500400

# about the cmake script of sqlite3
    refer to "build/cmake/*" of https://github.com/facebook/zstd.git .
<!-- 
3rd/sqlite3cmake/**/CMakeLists.txt,3rd/sqlite3cmake/**/*.cmake  
 -->
## sqlite3的GitHub源码的configure不适合Android
是的，SQLite3 官方 GitHub 源码的 **默认 configure 脚本不适合直接编译 Android 版本**，因为它未针对 Android 的交叉编译环境（如 NDK 工具链）进行适配。


### 核心原因
SQLite3 的默认 `configure` 脚本是为 Linux/macOS/Windows 等桌面/服务器系统设计的，其编译逻辑：
1. 依赖当前系统的编译器（如 `gcc`/`clang`），而非 Android NDK 提供的交叉编译器（如 `arm-linux-androideabi-clang`）。
2. 无法自动识别 Android 的目标架构（arm64-v8a、armeabi-v7a 等）、API 级别和系统库路径。
3. 不会生成符合 Android 动态库（`.so`）或静态库（`.a`）标准的输出文件。


### Android 编译的正确方式
需通过 **Android NDK 交叉编译** 实现，核心是指定 NDK 工具链和编译参数，而非依赖默认 `configure`。常用两种方案：

#### 方案 1：手动编写 NDK 编译脚本（Android.mk + Application.mk）
<!-- 
1. **Android.mk**：指定 SQLite3 源码文件、编译模块类型（静态/动态库）、头文件路径等。
   ```makefile
   LOCAL_PATH := $(call my-dir)
   include $(CLEAR_VARS)
   # 源码文件（需列出 sqlite3.c 等核心文件）
   LOCAL_SRC_FILES := sqlite3.c
   # 模块名（生成的库名：libsqlite3.so）
   LOCAL_MODULE := sqlite3
   # 编译选项（适配 Android）
   LOCAL_CFLAGS := -DSQLITE_ENABLE_FTS5 -Os
   include $(BUILD_SHARED_LIBRARY) # 动态库，静态库用 BUILD_STATIC_LIBRARY
   ```
2. **Application.mk**：指定目标架构、Android API 级别等。
   ```makefile
   APP_ABI := arm64-v8a armeabi-v7a # 目标架构
   APP_PLATFORM := android-24 # 最低支持的 Android 版本
   APP_STL := c++_static # 依赖的 STL 库
   ```
3. 执行 NDK 编译命令：`ndk-build NDK_PROJECT_PATH=. NDK_APPLICATION_MK=./Application.mk`。 
-->


#### 方案 2：使用 CMake（Android Studio 推荐）
通过 `CMakeLists.txt` 配置交叉编译，适配 Android Studio 的构建系统：
```cmake
cmake_minimum_required(VERSION 3.10)
project(sqlite3)
# 源码文件
add_library(sqlite3 SHARED sqlite3.c)
# 编译选项
target_compile_definitions(sqlite3 PRIVATE SQLITE_ENABLE_FTS5)
# 链接 Android 系统库
target_link_libraries(sqlite3 log)
```
在 `build.gradle` 中指定 NDK 版本和目标架构，由 Android Studio 自动调用 NDK 工具链编译。


综上，直接用 SQLite3 官方 `configure` 无法编译 Android 版本，必须通过 NDK 交叉编译，并编写适配的构建脚本（Android.mk 或 CMakeLists.txt）。

## How to build

As cmake doesn't support command like `cmake clean`, it's recommended to perform an "out of source build".
To do this, you can create a new directory and build in it:
```sh
mkdir builddir 
cmake -S. -Bbuilddir
cmake --build builddir -v
```
Then you can clean all cmake caches by simply delete the new directory:
```sh
rm -rf ./builddir
```
 
To show cmake build options, you can:
```sh
cd ./builddir
cmake -LH ..
```

Bool options can be set to `ON/OFF` with `-D[option]=[ON/OFF]`. You can configure cmake options like this:
```sh
cmake -S. -Bbuilddir -DSQLITE_BUILD_TOOLS=ON -DSQLITE_ENABLE_ZLIB=OFF ..
cmake --build builddir 
```
 
<!--  

**Apple Frameworks**
It's generally recommended to have CMake with versions higher than 3.14 for [iOS-derived platforms](https://cmake.org/cmake/help/latest/manual/cmake-toolchains.7.html#id27).
```sh
cmake -S. -B build-cmake -DZSTD_FRAMEWORK=ON -DCMAKE_SYSTEM_NAME=iOS
```
Or you can utilize [iOS-CMake](https://github.com/leetal/ios-cmake) toolchain for CMake versions lower than 3.14
```sh
cmake -B build -G Xcode -DCMAKE_TOOLCHAIN_FILE=<Path To ios.toolchain.cmake> -DPLATFORM=OS64 -DZSTD_FRAMEWORK=ON
``` -->
 
### referring
[Looking for a 'cmake clean' command to clear up CMake output](https://stackoverflow.com/questions/9680420/looking-for-a-cmake-clean-command-to-clear-up-cmake-output)

## CMake Style Recommendations

### Indent all code correctly, i.e. the body of

 * if/else/endif
 * foreach/endforeach
 * while/endwhile
 * macro/endmacro
 * function/endfunction

Use spaces for indenting, 2, 3 or 4 spaces preferably. Use the same amount of
spaces for indenting as is used in the rest of the file. Do not use tabs.

### Upper/lower casing

Most important: use consistent upper- or lowercasing within one file !

In general, the all-lowercase style is preferred.

So, this is recommended:

```
add_executable(foo foo.c)
```

These forms are discouraged

```
ADD_EXECUTABLE(bar bar.c)
Add_Executable(hello hello.c)
aDd_ExEcUtAbLe(blub blub.c)
```

### End commands
To make the code easier to read, use empty commands for endforeach(), endif(),
endfunction(), endmacro() and endwhile(). Also, use empty else() commands.

For example, do this:

```
if(FOOVAR)
   some_command(...)
else()
   another_command(...)
endif()
```

and not this:

```
if(BARVAR)
   some_other_command(...)
endif(BARVAR)
```

### Other resources for best practices

https://cmake.org/cmake/help/latest/manual/cmake-developer.7.html#modules
