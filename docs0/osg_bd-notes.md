# 0. osg3.4.1 osgearth2.8 Android安卓移植(预)

lawest 于 2018-06-12 16:24:21 发布 
原文链接：https://blog.csdn.net/lawest/article/details/80666958

本文介绍了如何在Android平台上使用Android Studio和CMake编译OSG核心模块及其依赖库，包括JPEG、PNG、FreeType和TIFF等。文章还详细记录了针对Android平台进行必要的代码调整，以解决动态库加载和字体文件查找等问题。  


编译工具Android Studio ，使用cmake编译so动态库

osg核心模块， jpeg , png , freetype ，tiff 等第三方库和部分插件编译已完成，

之前遇到很多坑都没记录，现记录一下，如有时间将之前的补上：

## osg编译：
编译前将include下面osg下面的GL头文件更改如下如没有自己新建一个： 
```cpp
/* -*-c++-*- OpenSceneGraph - Copyright (C) 1998-2009 Robert Osfield
 *
 * This library is open source and may be redistributed and/or modified under
 * the terms of the OpenSceneGraph Public License (OSGPL) version 0.0 or
 * (at your option) any later version.  The full license is in LICENSE file
 * included with this distribution, and on the openscenegraph.org website.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * OpenSceneGraph Public License for more details.
*/
 
#ifndef OSG_OPENGL
#define OSG_OPENGL 1
 
#include <osg/Config>
#include <osg/Export>
#include <osg/Types>
 
//#define OSG_GL1_AVAILABLE
//#define OSG_GL2_AVAILABLE
/* #undef OSG_GL3_AVAILABLE */
/* #undef OSG_GLES1_AVAILABLE */
/* #undef OSG_GLES2_AVAILABLE */
/* #undef OSG_GLES3_AVAILABLE */
/* #undef OSG_GL_LIBRARY_STATIC */
#define OSG_GLES2_AVAILABLE
//#define OSG_GL_LIBRARY_STATIC
//#define OSG_GL_DISPLAYLISTS_AVAILABLE
//#define OSG_GL_MATRICES_AVAILABLE
//#define OSG_GL_VERTEX_FUNCS_AVAILABLE
//#define OSG_GL_VERTEX_ARRAY_FUNCS_AVAILABLE
//#define OSG_GL_FIXED_FUNCTION_AVAILABLE
/* #undef GL_HEADER_HAS_GLINT64 */
/* #undef GL_HEADER_HAS_GLUINT64 */
 
#define OSG_GL1_FEATURES 0
#define OSG_GL2_FEATURES 0
#define OSG_GL3_FEATURES 0
#define OSG_GLES1_FEATURES 0
#define OSG_GLES2_FEATURES 1
#define OSG_GLES3_FEATURES 0
 
 
#ifndef WIN32
 
    // Required for compatibility with glext.h sytle function definitions of
    // OpenGL extensions, such as in src/osg/Point.cpp.
    #ifndef APIENTRY
        #define APIENTRY
    #endif
 
#else // WIN32
 
    #if defined(__CYGWIN__) || defined(__MINGW32__)
 
        #ifndef APIENTRY
                #define GLUT_APIENTRY_DEFINED
                #define APIENTRY __stdcall
        #endif
            // XXX This is from Win32's <windef.h>
        #ifndef CALLBACK
            #define CALLBACK __stdcall
        #endif
 
    #else // ! __CYGWIN__
 
        // Under Windows avoid including <windows.h>
        // to avoid name space pollution, but Win32's <GL/gl.h>
        // needs APIENTRY and WINGDIAPI defined properly.
        // XXX This is from Win32's <windef.h>
        #ifndef APIENTRY
            #define GLUT_APIENTRY_DEFINED
            #if (_MSC_VER >= 800) || defined(_STDCALL_SUPPORTED)
                #define WINAPI __stdcall
                #define APIENTRY WINAPI
            #else
                #define APIENTRY
            #endif
        #endif
 
            // XXX This is from Win32's <windef.h>
        #ifndef CALLBACK
            #if (_MSC_VER >= 800) || defined(_STDCALL_SUPPORTED)
                #define CALLBACK __stdcall
            #else
                #define CALLBACK
            #endif
        #endif
 
    #endif // __CYGWIN__
 
    // XXX This is from Win32's <wingdi.h> and <winnt.h>
    #ifndef WINGDIAPI
        #define GLUT_WINGDIAPI_DEFINED
        #define DECLSPEC_IMPORT __declspec(dllimport)
        #define WINGDIAPI DECLSPEC_IMPORT
    #endif
 
    // XXX This is from Win32's <ctype.h>
    #if !defined(_WCHAR_T_DEFINED) && !(defined(__GNUC__)&&(__GNUC__ > 2))
        typedef unsigned short wchar_t;
        #define _WCHAR_T_DEFINED
    #endif
 
#endif // WIN32
 
#if defined(OSG_GL3_AVAILABLE)
    #define GL3_PROTOTYPES 1
    #define GL_GLEXT_PROTOTYPES 1
#endif
 
 
#include <GLES2/gl2.h>
 
 
 
#ifndef GL_APIENTRY
    #define GL_APIENTRY APIENTRY
#endif // GL_APIENTRY
 
 
#ifndef GL_HEADER_HAS_GLINT64
    typedef int64_t GLint64;
#endif
 
#ifndef GL_HEADER_HAS_GLUINT64
    typedef uint64_t GLuint64;
#endif
 
#ifdef OSG_GL_MATRICES_AVAILABLE
 
    inline void glLoadMatrix(const float* mat) { glLoadMatrixf(static_cast<const GLfloat*>(mat)); }
    inline void glMultMatrix(const float* mat) { glMultMatrixf(static_cast<const GLfloat*>(mat)); }
 
    #ifdef OSG_GLES1_AVAILABLE
        inline void glLoadMatrix(const double* mat)
        {
            GLfloat flt_mat[16];
            for(unsigned int i=0;i<16;++i) flt_mat[i] = mat[i];
            glLoadMatrixf(flt_mat);
        }
 
        inline void glMultMatrix(const double* mat)
        {
            GLfloat flt_mat[16];
            for(unsigned int i=0;i<16;++i) flt_mat[i] = mat[i];
            glMultMatrixf(flt_mat);
        }
 
    #else
        inline void glLoadMatrix(const double* mat) { glLoadMatrixd(static_cast<const GLdouble*>(mat)); }
        inline void glMultMatrix(const double* mat) { glMultMatrixd(static_cast<const GLdouble*>(mat)); }
    #endif
#endif
 
// add defines for OpenGL targets that don't define them, just to ease compatibility across targets
#ifndef GL_DOUBLE
    #define GL_DOUBLE 0x140A
    typedef double GLdouble;
#endif
 
#ifndef GL_INT
    #define GL_INT 0x1404
#endif
 
#ifndef GL_UNSIGNED_INT
    #define GL_UNSIGNED_INT 0x1405
#endif
 
#ifndef GL_NONE
    // OpenGL ES1 doesn't provide GL_NONE
    #define GL_NONE 0x0
#endif
 
#if defined(OSG_GLES1_AVAILABLE) || defined(OSG_GLES2_AVAILABLE)
    //GLES defines (OES)
    #define GL_RGB8_OES                                             0x8051
    #define GL_RGBA8_OES                                            0x8058
#endif
 
#if defined(OSG_GLES1_AVAILABLE) || defined(OSG_GLES2_AVAILABLE) || defined(OSG_GL3_AVAILABLE)
    #define GL_POLYGON                         0x0009
    #define GL_QUADS                           0x0007
    #define GL_QUAD_STRIP                      0x0008
#endif
 
#if defined(OSG_GL3_AVAILABLE)
    #define GL_LUMINANCE                      0x1909
    #define GL_LUMINANCE_ALPHA                0x190A
#endif
 
 
#endif
```

osg核心模块编译完成后有几处需要修改：

1.osg在加载动态库插件是是没有写Android对应分支的

    将osgDB下的Registry.cpp  createLibraryNameForExtension函数和createLibraryNameForNodeKit函数修改如下：
```cpp
std::string Registry::createLibraryNameForNodeKit(const std::string& name)
{
#if defined(__CYGWIN__)
    return "cyg"+name+OSG_LIBRARY_POSTFIX_WITH_QUOTES+".dll";
#elif defined(__MINGW32__)
    return "lib"+name+OSG_LIBRARY_POSTFIX_WITH_QUOTES+".dll";
#elif defined(WIN32)
    return name+OSG_LIBRARY_POSTFIX_WITH_QUOTES+".dll";
#elif macintosh
    return name+OSG_LIBRARY_POSTFIX_WITH_QUOTES;
#elif defined(__ANDROID_NDK__)
    return "lib"+name+OSG_LIBRARY_POSTFIX_WITH_QUOTES+".so";
#else
    return "lib"+name+OSG_LIBRARY_POSTFIX_WITH_QUOTES + ADDQUOTES(OSG_PLUGIN_EXTENSION);
#endif
}
```

```cpp
std::string Registry::createLibraryNameForExtension(const std::string& ext)
{
    std::string lowercase_ext;
    for(std::string::const_iterator sitr=ext.begin();
        sitr!=ext.end();
        ++sitr)
    {
        lowercase_ext.push_back(tolower(*sitr));
    }
 
    ExtensionAliasMap::iterator itr=_extAliasMap.find(lowercase_ext);
    if (itr!=_extAliasMap.end() && ext != itr->second) return createLibraryNameForExtension(itr->second);
 
    std::string prepend = std::string("osgPlugins-")+std::string(osgGetVersion())+std::string("/");
 
#if defined(__CYGWIN__)
    return prepend+"cygwin_"+"osgdb_"+lowercase_ext+OSG_LIBRARY_POSTFIX_WITH_QUOTES+".dll";
#elif defined(__MINGW32__)
    return prepend+"mingw_"+"osgdb_"+lowercase_ext+OSG_LIBRARY_POSTFIX_WITH_QUOTES+".dll";
#elif defined(WIN32)
    return prepend+"osgdb_"+lowercase_ext+OSG_LIBRARY_POSTFIX_WITH_QUOTES+".dll";
#elif macintosh
    return prepend+"osgdb_"+lowercase_ext+OSG_LIBRARY_POSTFIX_WITH_QUOTES;
#elif defined(__ANDROID_NDK__)
    return std::string("lib")+"osgdb_"+lowercase_ext+OSG_LIBRARY_POSTFIX_WITH_QUOTES+".so";
#else
    return prepend+"osgdb_"+lowercase_ext+OSG_LIBRARY_POSTFIX_WITH_QUOTES+ADDQUOTES(OSG_PLUGIN_EXTENSION);
#endif
 
}
```

将osgDB下DynamicLibrary.cpp的getLibraryHandle函数修改如下：
```cpp
DynamicLibrary::HANDLE DynamicLibrary::getLibraryHandle( const std::string& libraryName)
{
    HANDLE handle = NULL;
 
#if defined(WIN32) && !defined(__CYGWIN__)
#ifdef OSG_USE_UTF8_FILENAME
    handle = LoadLibraryW(  convertUTF8toUTF16(libraryName).c_str() );
#else
    handle = LoadLibrary( libraryName.c_str() );
#endif
#elif defined(__APPLE__) && defined(APPLE_PRE_10_3)
    NSObjectFileImage image;
    // NSModule os_handle = NULL;
    if (NSCreateObjectFileImageFromFile(libraryName.c_str(), &image) == NSObjectFileImageSuccess) {
        // os_handle = NSLinkModule(image, libraryName.c_str(), TRUE);
        handle = NSLinkModule(image, libraryName.c_str(), TRUE);
        NSDestroyObjectFileImage(image);
    }
#elif defined(__hpux)
    // BIND_FIRST is necessary for some reason
    handle = shl_load ( libraryName.c_str(), BIND_DEFERRED|BIND_FIRST|BIND_VERBOSE, 0);
    return handle;
#else // other unix
 
    // dlopen will not work with files in the current directory unless
    // they are prefaced with './'  (DB - Nov 5, 2003).
    std::string localLibraryName;
    if( libraryName == osgDB::getSimpleFileName( libraryName ) )
        localLibraryName = "./" + libraryName;
    else
        localLibraryName = libraryName;
 
#ifdef __ANDROID_NDK__
    localLibraryName = libraryName;
#endif
 
    handle = dlopen( localLibraryName.c_str(), RTLD_LAZY | RTLD_GLOBAL);
    if( handle == NULL )
    {
        if (fileExists(localLibraryName))
        {
            OSG_WARN << "Warning: dynamic library '" << libraryName << "' exists, but an error occurred while trying to open it:" << std::endl;
            OSG_WARN << dlerror() << std::endl;
        }
        else
        {
            OSG_INFO << "Warning: dynamic library '" << libraryName << "' does not exist (or isn't readable):" << std::endl;
            OSG_INFO << dlerror() << std::endl;
        }
    }
#endif
    return handle;
}
```

2.由于osg默认加载的字体是arial.ttf,安卓系统没有这个字体，而且就算有这个字体他的拼写方式也不对，现将osgText模块下的Font.cpp的findFontFile函数修改如下:
```cpp
std::string osgText::findFontFile(const std::string& str)
{
    // try looking in OSGFILEPATH etc first for fonts.
    std::string filename = osgDB::findDataFile(str);
    if (!filename.empty()) return filename;
 
    OpenThreads::ScopedLock<OpenThreads::ReentrantMutex> lock(getFontFileMutex());
 
#ifdef __ANDROID_NDK__
    std::string* pStr = const_cast<std::string*>(&str);
    *pStr = "Roboto-Regular.ttf";
#endif
 
    static osgDB::FilePathList s_FontFilePath;
    static bool initialized = false;
    if (!initialized)
    {
        initialized = true;
    #if defined(WIN32)
        osgDB::convertStringPathIntoFilePathList(
            ".;C:/winnt/fonts;C:/windows/fonts",
            s_FontFilePath);
 
        char *ptr;
        if ((ptr = getenv( "windir" )))
        {
            std::string winFontPath = ptr;
            winFontPath += "\\fonts";
            s_FontFilePath.push_back(winFontPath);
        }
    #elif defined(__ANDROID_NDK__)
        std::string strSysFont = "/system/fonts/";
        s_FontFilePath.push_back(strSysFont);
    #elif defined(__APPLE__)
      osgDB::convertStringPathIntoFilePathList(
        ".:/usr/share/fonts/ttf:/usr/share/fonts/ttf/western:/usr/share/fonts/ttf/decoratives:/Library/Fonts:/System/Library/Fonts",
        s_FontFilePath);
    #else
      osgDB::convertStringPathIntoFilePathList(
        ".:/usr/share/fonts/ttf:/usr/share/fonts/ttf/western:/usr/share/fonts/ttf/decoratives",
        s_FontFilePath);
    #endif
    }
 
 
 
    filename = osgDB::findFileInPath(str,s_FontFilePath);
    if (!filename.empty()) return filename;
 
    // Try filename without pathname, if it has a path
    filename = osgDB::getSimpleFileName(str);
    if(filename!=str)
    {
        filename = osgDB::findFileInPath(filename,s_FontFilePath);
        if (!filename.empty()) return filename;
    }
    else
    {
        filename = osgText::findFontFile(std::string("fonts/")+filename);
        if (!filename.empty()) return filename;
    }
 
    // Not found, return empty string
    OSG_INFO<<"Warning: font file \""<<str<<"\" not found."<<std::endl;
    return std::string();
}
```
虽然这样不怎么好但是还是先这样。

编译后测试：

贴张纹理（需要修改自带例子和Shader，有时间回帖上）
 ![osg-andr.png](img_port2android/osg-andr.png)

 牛，纹理没贴上去，可能和数据格式有关后面再 排查：
![cow.png](img_port2android/cow.png)

在Android上操作器有点问题，鼠标灵敏度太大，设置一个因子就好，但是还是有问题，在XZ轴上旋转正常，但是很Y轴很难旋转，后面继续修改操作。

====================================================
# 1.jpeg-libpng-freetype
### 1.jpeg 库的 github地址

jpeg 库（通常指 libjpeg，最经典的 JPEG 图像编解码库）的官方代码仓库托管在 SourceForge，不过在 GitHub 上有其镜像仓库及衍生版本。以下是几个常用的相关 GitHub 地址：

> 1. **libjpeg-turbo（高性能衍生版，最常用）**  
>    这是 libjpeg 的优化版本，提供更快的编解码速度，广泛用于各类项目中。  
>    GitHub 地址：https://github.com/libjpeg-turbo/libjpeg-turbo
> 
> 2. **ijg/libjpeg（官方原版镜像）**  
>    这是 Independent JPEG Group（IJG）维护的官方 libjpeg 镜像，保持与官方源码同步。  
>    地址：http://www.ijg.org/files/jpegsrc.v9f.tar.gz
> 
> 3. **mozjpeg（Mozilla 优化版）**  
>    由 Mozilla 开发的 libjpeg 衍生版，针对 Web 场景优化，生成的 JPEG 文件体积更小。  
>    GitHub 地址：https://github.com/mozilla/mozjpeg

其中，**libjpeg-turbo** 因其高性能和广泛兼容性，是目前最推荐使用的版本。

```sh
# ----my cmd
cmake -S. -Bbuild/jpeg-ubuntu-dbg -DCMAKE_BUILD_TYPE=Debug
cmake --build  build/jpeg-ubuntu-dbg 

cmake --build  build/jpeg-ubuntu-dbg    --target install  -j8
```

===== 
### 2. libpng的github 地址

libpng 是处理 PNG 图像格式的主流库，其官方维护的 GitHub 仓库地址如下：
https://github.com/glennrp/libpng

这是由 libpng 主要维护者 Glenn Randers-Pehrson 管理的官方仓库，包含了最新的源代码、发布版本以及开发文档。该仓库持续更新，用于维护和发展 libpng 库的功能，是获取 libpng 源码的权威来源。

```sh
# 配置CMake  
cmake .. -G "$Generator" -A x64 `
-DCMAKE_BUILD_TYPE=RelWithDebInfo `
-DCMAKE_PREFIX_PATH="$InstallDir" `
-DCMAKE_INSTALL_PREFIX="$InstallDir" `
-DPNG_TESTS=OFF `
-DPNG_STATIC=OFF `

# 构建阶段，指定构建类型
cmake --build . --config RelWithDebInfo

# 安装阶段，指定构建类型和安装目标
cmake --build . --config RelWithDebInfo --target install
```

```sh
# ----my cmd
# 配置CMake
buildDir=build/png-ubuntu-static
cmake -S. -B${buildDir} -DCMAKE_BUILD_TYPE=Debug  

cmake --build  ${buildDir} --config Debug --target install
```
 
### 3.freetype库的github 地址

freetype 库是一个广泛使用的字体渲染引擎，其官方 GitHub 仓库地址如下：
https://github.com/freetype/freetype

这是由 FreeType 项目官方维护的仓库，包含了该库的完整源代码、开发文档以及版本发布信息。FreeType 库支持多种字体格式，如 TrueType、OpenType、Type1 等，被广泛应用于图形界面、排版系统等领域。


#### CMake构建学习笔记7-freetype库的构建
发布于 2024-12-14 09:07:37
Freetype是一个广泛使用的开源字体渲染库，可以加载、渲染和显示各种类型的字体文件。一般的用户来说可能没有直接使用过这个库，都是通过使用依赖于它的依赖库来间接使用它。根据笔者构建的经验，构建这个库需要zlib、libpng这两个库，可以按照本系列博文的相应文章提前构建好。关键的构建指令如下所示：
```sh
# 配置CMake      
cmake .. -G "$Generator" -A x64 `
    -DBUILD_SHARED_LIBS=true `
    -DCMAKE_BUILD_TYPE=RelWithDebInfo `
    -DCMAKE_PREFIX_PATH="$InstallDir" `
    -DCMAKE_INSTALL_PREFIX="$InstallDir"        

# 构建阶段，指定构建类型
cmake --build . --config RelWithDebInfo

# 安装阶段，指定构建类型和安装目标
cmake --build . --config RelWithDebInfo --target install
```

```sh
# ----my cmd
cmake -S. -Bbuild/freetype-ubuntu-dbg -DCMAKE_BUILD_TYPE=Debug
cmake --build  build/freetype-ubuntu-dbg 

cmake --build  build/freetype-ubuntu-dbg    --target install  -j8
```
=====================================
# 2.tiff的github地址

处理 TIFF 图像格式的主流库是 libtiff，其官方维护的 GitHub 仓库地址如下：

<!-- https://github.com/libtiff/libtiff  -->
https://github.com/vadz/libtiff.git
这个仓库由 libtiff 项目团队维护，包含了库的完整源代码、测试用例和文档。libtiff 支持多种 TIFF 格式的读写操作，是图像处理领域处理 TIFF 文件的常用工具库。

```sh
# ----my cmd
cmake -S. -Bbuild01/tiff-ubuntu-dbg -DCMAKE_BUILD_TYPE=Debug
cmake --build  build01/tiff-ubuntu-dbg 

cmake --build  build01/tiff-ubuntu-dbg   --  -j8  install
```

# 6. libjpeg-turbo cannot be integrated using add_subdirectory()

## 问题
```sh
CMake Error at 3rd/libjpeg-turbo/CMakeLists.txt:70 (message):
  The libjpeg-turbo build system cannot be integrated into another build
  system using add_subdirectory().  Use ExternalProject_Add() instead.
```

## 腾讯元宝
这个错误表明 **libjpeg-turbo** 的构建系统设计上不支持通过 `add_subdirectory()` 直接集成到你的 CMake 项目中，必须改用 `ExternalProject_Add()` 或 `FetchContent` 来独立构建它。以下是解决方案：

---

### **原因分析**
libjpeg-turbo 的 `CMakeLists.txt` 明确禁止了 `add_subdirectory()` 的集成方式（https://github.com/libjpeg-turbo/libjpeg-turbo/blob/main/CMakeLists.txt#L70），因为：
1. 它需要独立的构建环境（如 NASM 汇编器）。
2. 它的 CMake 配置可能与其他项目冲突（如变量名污染）。
3. 官方推荐通过系统包或 `ExternalProject` 方式使用。

---

### **解决方案**
#### **方法 1：使用 `ExternalProject_Add()`（推荐）**
在项目的 `CMakeLists.txt` 中添加：
```cmake
include(ExternalProject)

ExternalProject_Add(
    libjpeg-turbo
    GIT_REPOSITORY "https://github.com/libjpeg-turbo/libjpeg-turbo.git"
    GIT_TAG "2.1.5"  # 指定版本
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>  # 指定安装路径
        -DWITH_JPEG8=ON  # 启用JPEG 8兼容性
        -DCMAKE_BUILD_TYPE=Release
    BUILD_ALWAYS OFF
)

# 将 libjpeg-turbo 的头文件和库路径链接到你的项目
target_include_directories(your_target PRIVATE
    ${CMAKE_INSTALL_PREFIX}/include
)
target_link_directories(your_target PRIVATE
    ${CMAKE_INSTALL_PREFIX}/lib
)
target_link_libraries(your_target PRIVATE
    jpeg-static  # 或 jpeg
)
```

#### **方法 2：使用 `FetchContent`（CMake 3.11+）**
```cmake
include(FetchContent)

FetchContent_Declare(
    libjpeg-turbo
    GIT_REPOSITORY "https://github.com/libjpeg-turbo/libjpeg-turbo.git"
    GIT_TAG "2.1.5"
)

# 手动指定构建和安装路径
set(LIBJPEG_TURBO_BUILD_DIR ${CMAKE_BINARY_DIR}/libjpeg-turbo-build)
set(LIBJPEG_TURBO_INSTALL_DIR ${CMAKE_BINARY_DIR}/libjpeg-turbo-install)

# 配置独立构建
FetchContent_GetProperties(libjpeg-turbo)
if(NOT libjpeg-turbo_POPULATED)
    FetchContent_Populate(libjpeg-turbo)
    execute_process(
        COMMAND ${CMAKE_COMMAND} -S ${libjpeg-turbo_SOURCE_DIR} -B ${LIBJPEG_TURBO_BUILD_DIR}
                -DCMAKE_INSTALL_PREFIX=${LIBJPEG_TURBO_INSTALL_DIR}
                -DWITH_JPEG8=ON
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )
    execute_process(
        COMMAND ${CMAKE_COMMAND} --build ${LIBJPEG_TURBO_BUILD_DIR} --target install
    )
endif()

# 链接到你的项目
target_include_directories(your_target PRIVATE
    ${LIBJPEG_TURBO_INSTALL_DIR}/include
)
target_link_libraries(your_target PRIVATE
    ${LIBJPEG_TURBO_INSTALL_DIR}/lib/libjpeg.a
)
```

#### **方法 3：通过系统包管理器安装**
```bash
# Ubuntu/Debian
sudo apt install libjpeg-turbo8-dev

# CentOS/RHEL
sudo yum install libjpeg-turbo-devel
```
然后在 CMake 中直接查找：
```cmake
find_package(JPEG REQUIRED)
target_link_libraries(your_target PRIVATE JPEG::JPEG)
```

---

### **关键注意事项**
1. **静态库 vs 动态库**  
   libjpeg-turbo 默认生成静态库（`libjpeg.a`），如需动态库，添加：
   ```cmake
   -DENABLE_SHARED=ON
   ```

2. **NASM 依赖**  
   如果启用 SIMD 优化（默认开启），需提前安装 NASM：
   ```bash
   sudo apt install nasm
   ```

3. **安装路径冲突**  
   确保 `CMAKE_INSTALL_PREFIX` 不与系统路径冲突，建议用本地路径（如 `${PROJECT_BINARY_DIR}/deps`）。

4. **交叉编译**  
   若需交叉编译，传递 `-DCMAKE_TOOLCHAIN_FILE` 给 `ExternalProject_Add`。

---

### **错误处理**
- **找不到 NASM**：安装 NASM 或禁用 SIMD：
  ```cmake
  -DWITH_SIMD=OFF
  ```
- **权限问题**：确保 `INSTALL_DIR` 可写。
- **版本冲突**：指定明确的 `GIT_TAG` 或下载源码压缩包。

---

### **总结**
| 方法                | 适用场景                          | 优点                     |
|---------------------|----------------------------------|--------------------------|
| `ExternalProject`   | 需控制构建细节（如交叉编译）       | 灵活，隔离性强           |
| `FetchContent`      | CMake 3.11+，希望自动化依赖管理    | 无需预安装，集成简便      |
| 系统包              | 快速集成，不需定制构建            | 最简单，但版本可能较旧   |

推荐优先使用 `ExternalProject_Add()`，尤其对稳定性要求高的项目。

====================================================
# 7. libjpeg-turbo代码已经手动下载到 3rd/libjpeg-turbo/如何设置ExternalProject_Add

如果你的 **libjpeg-turbo** 源码已经手动下载到 `3rd/libjpeg-turbo/`，但仍然希望使用 `ExternalProject_Add()` 进行独立构建（避免 `add_subdirectory()` 的问题），可以按以下方式配置：

---

### **解决方案：使用 `ExternalProject_Add` 构建本地源码**
在项目的 `CMakeLists.txt` 中添加以下内容：

```cmake
include(ExternalProject)

# 设置 libjpeg-turbo 的源码路径（假设放在 3rd/libjpeg-turbo/）
set(LIBJPEG_TURBO_SOURCE_DIR ${CMAKE_SOURCE_DIR}/3rd/libjpeg-turbo)
set(LIBJPEG_TURBO_BUILD_DIR ${CMAKE_BINARY_DIR}/libjpeg-turbo-build)
set(LIBJPEG_TURBO_INSTALL_DIR ${CMAKE_BINARY_DIR}/libjpeg-turbo-install)

# 添加 ExternalProject 构建
ExternalProject_Add(
    libjpeg-turbo
    SOURCE_DIR ${LIBJPEG_TURBO_SOURCE_DIR}  # 指定本地源码路径
    BINARY_DIR ${LIBJPEG_TURBO_BUILD_DIR}    # 构建目录（建议放在 build 目录下）
    INSTALL_DIR ${LIBJPEG_TURBO_INSTALL_DIR} # 安装目录
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${LIBJPEG_TURBO_INSTALL_DIR}  # 必须指定安装路径
        -DWITH_JPEG8=ON      # 启用 JPEG 8 兼容性
        -DENABLE_SHARED=OFF  # 默认构建静态库（如需动态库改为 ON）
        -DWITH_SIMD=ON       # 启用 SIMD 优化（需安装 NASM）
    BUILD_ALWAYS OFF         # 仅在源码变更时重新构建
)

# 将 libjpeg-turbo 的头文件和库路径链接到你的目标
add_library(libjpeg-turbo-imported STATIC IMPORTED)
add_dependencies(libjpeg-turbo-imported libjpeg-turbo)  # 依赖 ExternalProject

# 设置导入库的路径
set_target_properties(libjpeg-turbo-imported PROPERTIES
    IMPORTED_LOCATION ${LIBJPEG_TURBO_INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}jpeg${CMAKE_STATIC_LIBRARY_SUFFIX}
    INTERFACE_INCLUDE_DIRECTORIES ${LIBJPEG_TURBO_INSTALL_DIR}/include
)

# 在你的目标中链接 libjpeg-turbo
target_link_libraries(your_target PRIVATE libjpeg-turbo-imported)
```

---

### **关键说明**
1. **源码路径**  
   - `SOURCE_DIR` 直接指向你本地的 `3rd/libjpeg-turbo/`，避免重复下载。

2. **独立构建**  
   - `BINARY_DIR` 和 `INSTALL_DIR` 设置为 `${CMAKE_BINARY_DIR}` 下的子目录，确保与主项目隔离。

3. **安装路径**  
   - `CMAKE_INSTALL_PREFIX` 必须指定，否则 libjpeg-turbo 不会安装到指定位置。

4. **SIMD 优化**  
   - 如果启用 `-DWITH_SIMD=ON`（默认），需提前安装 NASM：
     ```bash
     sudo apt install nasm  # Ubuntu/Debian
     ```

5. **静态库 vs 动态库**  
   - 默认生成静态库（`libjpeg.a`），如需动态库改为 `-DENABLE_SHARED=ON`。

---

### **常见问题处理**
#### **1. 构建失败：找不到 NASM**
```text
CMake Error: NASM not found
```
- **解决**：安装 NASM 或禁用 SIMD：
  ```cmake
  -DWITH_SIMD=OFF
  ```

#### **2. 链接错误：找不到 `jpeg` 库**
- **检查**：确保 `IMPORTED_LOCATION` 路径正确，例如：
  ```cmake
  message(STATUS "Libjpeg path: ${LIBJPEG_TURBO_INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}jpeg${CMAKE_STATIC_LIBRARY_SUFFIX}")
  ```

#### **3. 如何清理构建缓存？**
- 删除 `libjpeg-turbo-build` 和 `libjpeg-turbo-install` 目录后重新构建。

---

### **替代方案：直接调用 CMake 构建**
如果不想用 `ExternalProject_Add`，可以手动构建：
```bash
cd 3rd/libjpeg-turbo
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=../../install -DWITH_JPEG8=ON ..
make -j8 && make install
```
然后在主项目中引用：
```cmake
target_include_directories(your_target PRIVATE ${CMAKE_SOURCE_DIR}/install/include)
target_link_directories(your_target PRIVATE ${CMAKE_SOURCE_DIR}/install/lib)
target_link_libraries(your_target PRIVATE jpeg)
```

---

### **总结**
| 方法               | 优点                          | 缺点                     |
|--------------------|-------------------------------|--------------------------|
| `ExternalProject`  | 自动化构建，隔离依赖           | 配置稍复杂               |
| 手动构建           | 直接控制，调试方便            | 需手动维护安装路径       |

推荐使用 `ExternalProject_Add`，尤其适合需要跨平台或 CI/CD 集成的项目。

============================================
# 8. libpsl源码已经位于3rd66/libpsl ，如何 3rd66/CMakeLists.txt中写ExternalProject_Add编译libpsl

如果你的 `libpsl` 源码已经位于 `3rd66/libpsl`（而不是从 Git 下载），那么 `ExternalProject_Add` 的写法会更简单，因为你不需要 `GIT_REPOSITORY`，而是直接使用 `SOURCE_DIR` 指定源码路径。  

---

### **方法 1：使用 autotools 构建（推荐）**
```cmake
include(ExternalProject)

ExternalProject_Add(
    libpsl
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/libpsl  # 源码路径
    PREFIX ${CMAKE_BINARY_DIR}/3rd66/libpsl-build  # 构建临时目录
    CONFIGURE_COMMAND <SOURCE_DIR>/autogen.sh && <SOURCE_DIR>/configure --prefix=${CMAKE_INSTALL_PREFIX} --disable-shared --enable-static
    BUILD_COMMAND make
    INSTALL_COMMAND make install
    BUILD_IN_SOURCE 0  # 使用独立构建目录（避免污染源码）
    BUILD_BYPRODUCTS ${CMAKE_INSTALL_PREFIX}/lib/libpsl.a  # 确保 CMake 能检测到生成的库
)
```

#### **关键点**：
1. **`SOURCE_DIR`**：直接指向 `3rd66/libpsl` 源码目录。
2. **`PREFIX`**：构建临时目录（建议放在 `CMAKE_BINARY_DIR` 下）。
3. **`CONFIGURE_COMMAND`**：
   - `<SOURCE_DIR>/autogen.sh` 生成 `configure`（如果从 Git 克隆的源码可能需要）。
   - `<SOURCE_DIR>/configure --prefix=...` 指定安装路径。
   - `--disable-shared --enable-static` 可选，如果你只需要静态库。
4. **`BUILD_IN_SOURCE 0`**：使用独立构建目录（避免污染源码）。
5. **`BUILD_BYPRODUCTS`**：让 CMake 知道生成的库文件路径。

---

### **方法 2：使用 meson 构建**
如果你的系统支持 `meson`，也可以这样写：
```cmake
find_program(MESON meson REQUIRED)
find_program(NINJA ninja REQUIRED)

ExternalProject_Add(
    libpsl
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/libpsl
    PREFIX ${CMAKE_BINARY_DIR}/3rd66/libpsl-build
    CONFIGURE_COMMAND ${MESON} setup <BINARY_DIR> <SOURCE_DIR> --prefix=${CMAKE_INSTALL_PREFIX} --default-library=static
    BUILD_COMMAND ${NINJA} -C <BINARY_DIR>
    INSTALL_COMMAND ${NINJA} -C <BINARY_DIR> install
    BUILD_BYPRODUCTS ${CMAKE_INSTALL_PREFIX}/lib/libpsl.a
)
```

---

### **在 CMake 中使用编译好的 libpsl**
编译完成后，你可以这样链接：
```cmake
# 方式 1：直接引用库文件
find_library(LIBPSL_LIB libpsl HINTS ${CMAKE_INSTALL_PREFIX}/lib)
find_path(LIBPSL_INCLUDE_DIR psl.h HINTS ${CMAKE_INSTALL_PREFIX}/include)

# 方式 2：创建导入目标（推荐）
add_library(libpsl::libpsl STATIC IMPORTED)
set_target_properties(libpsl::libpsl PROPERTIES
    IMPORTED_LOCATION ${LIBPSL_LIB}
    INTERFACE_INCLUDE_DIRECTORIES ${LIBPSL_INCLUDE_DIR}
)

# 在你的目标中使用
target_link_libraries(your_target PRIVATE libpsl::libpsl)
```

---

### **可能遇到的问题 & 解决方案**
1. **`autogen.sh` 报错**：
   - 确保安装了 `autoconf`, `automake`, `libtool`：
     ```sh
     sudo apt-get install autoconf automake libtool
     ```
   - 如果 `autogen.sh` 不存在，可能是源码包已经包含 `configure`，可以跳过：
     ```cmake
     CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=${CMAKE_INSTALL_PREFIX}
     ```

2. **依赖 `libicu` 或 `libidn2`**：
   - 确保系统已安装：
     ```sh
     sudo apt-get install libicu-dev libidn2-dev
     ```

3. **Windows 支持**：
   - 如果要在 Windows 上构建，建议使用 `msvc/README.MSVC.md` 中的方法，或者改用 `vcpkg`。

---

### **完整示例（推荐）**
```cmake
include(ExternalProject)

# 构建 libpsl
ExternalProject_Add(
    libpsl
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/libpsl
    PREFIX ${CMAKE_BINARY_DIR}/3rd66/libpsl-build
    CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=${CMAKE_INSTALL_PREFIX} --disable-shared --enable-static
    BUILD_COMMAND make
    INSTALL_COMMAND make install
    BUILD_BYPRODUCTS ${CMAKE_INSTALL_PREFIX}/lib/libpsl.a
)

# 在你的目标中使用
add_executable(your_target main.c)
target_link_libraries(your_target PRIVATE ${CMAKE_INSTALL_PREFIX}/lib/libpsl.a)
target_include_directories(your_target PRIVATE ${CMAKE_INSTALL_PREFIX}/include)
```

这样，`libpsl` 就会在 CMake 构建时自动编译并安装到 `${CMAKE_INSTALL_PREFIX}`，然后你的项目可以正确链接它。


===============================================
# 9.gdal源码依赖的第3方库

https://github.com/OSGeo/gdal.git
GDAL（Geospatial Data Abstraction Library）在编译时依赖多个第三方库以实现对不同地理数据格式和功能的支持。以下是 **GDAL 核心依赖的第三方库**及其作用，分为 **必需依赖** 和 **可选依赖**：

---

### **1. 必需依赖（编译时必须）**
| **库名**       | **作用**                          | **Ubuntu/Debian 安装命令**              |
|----------------|----------------------------------|---------------------------------------|
| **libgeos**    | 几何运算引擎（空间分析、拓扑操作）     | `sudo apt install libgeos-dev`       |
| **libproj**    | 坐标投影转换（PROJ 库）             | `sudo apt install libproj-dev`       |
| **libsqlite3** | SQLite 数据库驱动（支持 GeoPackage） | `sudo apt install libsqlite3-dev`    |
| **libexpat**   | XML 解析（如 GML、KML 格式）        | `sudo apt install libexpat-dev`      |
| **libcurl**    | 网络数据传输（HTTP/FTP 访问）       | `sudo apt install libcurl4-openssl-dev` |

---

### **2. 可选依赖（按需启用）**
#### **2.1 栅格数据格式支持**
| **库名**            | **支持格式**                  | **安装命令**                          |
|---------------------|-----------------------------|--------------------------------------|
| **libtiff**         | TIFF/GeoTIFF                | `sudo apt install libtiff-dev`       |
| **libpng**          | PNG                         | `sudo apt install libpng-dev`        |
| **libjpeg**         | JPEG                        | `sudo apt install libjpeg-dev`       |
| **libgif**          | GIF                         | `sudo apt install libgif-dev`        |
| **libhdf5**         | HDF5                        | `sudo apt install libhdf5-dev`       |
| **libnetcdf**       | NetCDF                      | `sudo apt install libnetcdf-dev`     |

#### **2.2 矢量数据格式支持**
| **库名**            | **支持格式**                  | **安装命令**                          |
|---------------------|-----------------------------|--------------------------------------|
| **libshp**          | ESRI Shapefile               | `sudo apt install libshp-dev`        |
| **libspatialite**   | Spatialite                  | `sudo apt install libspatialite-dev` |
| **libgdal-grass**   | GRASS GIS 集成               | `sudo apt install gdal-grass`       |

#### **2.3 数据库连接**
| **库名**            | **支持数据库**               | **安装命令**                          |
|---------------------|----------------------------|--------------------------------------|
| **libpq**           | PostgreSQL/PostGIS         | `sudo apt install libpq-dev`         |
| **libmysqlclient**  | MySQL                      | `sudo apt install libmysqlclient-dev`|
| **libodbc**         | ODBC 数据源                | `sudo apt install unixodbc-dev`      |

#### **2.4 其他功能扩展**
| **库名**            | **功能**                     | **安装命令**                          |
|---------------------|----------------------------|--------------------------------------|
| **libxml2**         | XML 解析（GML、KML）        | `sudo apt install libxml2-dev`       |
| **libjson-c**       | JSON 支持（GeoJSON）        | `sudo apt install libjson-c-dev`     |
| **libzstd**         | Zstandard 压缩              | `sudo apt install libzstd-dev`       |
| **libwebp**         | WebP 图像格式               | `sudo apt install libwebp-dev`       |

---

### **3. 编译时启用/禁用依赖**
在配置 GDAL 时，可通过 `cmake` 或 `./configure` 参数控制依赖项：

#### **CMake 示例（推荐）**
```bash
cmake -B build -S . \
  -DGDAL_USE_GEOS=ON \          # 启用 GEOS
  -DGDAL_USE_PROJ=ON \          # 启用 PROJ
  -DGDAL_USE_TIFF=ON \          # 启用 TIFF
  -DGDAL_USE_JSONC=OFF          # 禁用 JSON-C
```

#### **Autotools (./configure) 示例**
```bash
./configure \
  --with-geos \                # 启用 GEOS
  --with-proj \                # 启用 PROJ
  --with-libtiff \             # 启用 TIFF
  --without-json-c             # 禁用 JSON-C
```

---

### **4. 完整依赖安装命令（Ubuntu/Debian）**
一键安装所有常见依赖：
```bash
sudo apt install -y \
  libgeos-dev libproj-dev libsqlite3-dev \
  libtiff-dev libpng-dev libjpeg-dev \
  libcurl4-openssl-dev libxml2-dev \
  libnetcdf-dev libhdf5-dev \
  libpq-dev libmysqlclient-dev \
  libspatialite-dev libjson-c-dev
```

---

### **5. 验证依赖**
编译前检查配置日志：
```bash
cmake -B build -S .
cat build/CMakeCache.txt | grep "GDAL_USE"  # 查看启用的功能
```
或：
```bash
./configure --help | grep "with-"          # 查看支持的选项
```

---

### **6. 常见问题解决**
#### **Q1：找不到 PROJ 库**
- **原因**：PROJ 版本过低（需 ≥ 6.0）。
- **解决**：
  ```bash
  # 卸载旧版，从源码安装 PROJ
  sudo apt remove libproj-dev
  git clone https://github.com/OSGeo/PROJ.git
  cd PROJ && mkdir build && cd build
  cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
  make -j$(nproc) && sudo make install
  ```

#### **Q2：冲突的库路径**
- **现象**：`/usr/lib` 和 `/usr/local/lib` 下有重复库。
- **解决**：指定优先路径：
  ```bash
  export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
  ```

---

### **总结**
- **必需依赖**：GEOS、PROJ、SQLite3、Expat、Curl。
- **按需启用**：根据数据格式需求选择库（如 TIFF、NetCDF、PostgreSQL）。
- **验证工具**：`cmake --graphviz=graph.dot` 生成依赖关系图（需安装 `graphviz`）。

==============================================
# 10.libgeos的源码地址
以下是 **GEOS（Geometry Engine - Open Source）** 的官方源码地址和相关资源：

---

### **1. 官方 GitHub 仓库**
🔗 **https://github.com/libgeos/geos**  
- **主仓库**：包含最新开发代码（支持 C++11/C++14）。  
- **分支说明**：  
  - `main`：主开发分支（可能不稳定）。  
  - `3.12.x`、`3.11.x`：稳定版本分支（推荐生产环境使用）。  

---

### **2. 官方下载地址**
🔗 **https://libgeos.org/**  
- 提供稳定版源码压缩包（如 `geos-3.12.1.tar.gz`）。  
- 历史版本存档：https://download.osgeo.org/geos/。

---

### **3. 克隆源码（最新开发版）**
```bash
git clone https://github.com/libgeos/geos.git
cd geos
git checkout 3.12.1  # 切换到稳定版本
```

---

### **4. 编译安装指南**
#### **基础步骤（CMake）**
```bash
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local \
         -DBUILD_SHARED_LIBS=ON \
         -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
sudo make install
```

#### **关键选项**
| **CMake 选项**               | **作用**                          |
|-----------------------------|----------------------------------|
| `-DBUILD_SHARED_LIBS=ON`    | 生成动态库（默认）                |
| `-DBUILD_TESTING=ON`        | 启用测试套件                     |
| `-DGEOS_ENABLE_TESTS=ON`    | 编译测试程序                     |
| `-DCMAKE_BUILD_TYPE=Debug`  | 调试模式（开发时使用）           |

---

### **5. 依赖项**
- **编译时必需**：  
  - C++14 兼容编译器（GCC ≥ 5、Clang ≥ 3.4）。  
  - CMake ≥ 3.10。  
- **运行时可选**：  
  - **Python**：用于绑定（如 `geos.py`）。  
  - **SWIG**：生成其他语言接口（如 Java、C#）。

---

### **6. 验证安装**
```bash
geos-config --version  # 查看版本
geosop --help         # 命令行工具（需启用工具编译）
```

---

### **7. 文档与社区**
- **API 文档**：https://libgeos.org/documentation/  
- **邮件列表**：mailto:geos-devel@lists.osgeo.org  
- **Slack 频道**：https://osgeo.slack.com/archives/C01PVGDEY4L。

---

### **8. 常见问题**
#### **Q1：找不到 `geos.h` 头文件**
- **原因**：安装路径未加入编译器搜索路径。  
- **解决**：  
  ```bash
  export CPLUS_INCLUDE_PATH=/usr/local/include:$CPLUS_INCLUDE_PATH
  ```

#### **Q2：链接错误 `undefined reference to GEOSxxx`**
- **原因**：未正确链接库。  
- **解决**：  
  ```bash
  g++ your_code.cpp -o output -lgeos_c  # C 接口
  g++ your_code.cpp -o output -lgeos    # C++ 接口
  ```

---

### **总结**
- **生产环境**：建议使用稳定版（如 3.12.x）。  
- **开发调试**：从 GitHub 克隆 `main` 分支。  
- **快速安装**：通过系统包管理器（如 `apt install libgeos-dev`）。

=========================================
# 11.libproj的源码地址
以下是 **PROJ**（地理空间坐标转换库）的官方源码地址和关键资源：

---

### **1. 官方 GitHub 仓库**
🔗 **https://github.com/OSGeo/PROJ**  
- **主仓库**：包含最新开发代码（支持 C++11/C++14）。  
- **分支说明**：  
  - `master`：主开发分支（可能不稳定）。  
  - `9.x`、`8.x`：稳定版本分支（推荐生产环境使用）。  

---

### **2. 官方下载地址**
🔗 **https://proj.org/**  
- 提供稳定版源码压缩包（如 `proj-9.3.1.tar.gz`）。  
- 历史版本存档：https://download.osgeo.org/proj/。

---

### **3. 克隆源码（最新开发版）**
```bash
git clone https://github.com/OSGeo/PROJ.git
cd PROJ
git checkout 9.3.1  # 切换到稳定版本
```

---

### **4. 编译安装指南**
#### **基础步骤（CMake）**
```bash
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local \
         -DBUILD_SHARED_LIBS=ON \
         -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
sudo make install
```

#### **关键选项**
| **CMake 选项**               | **作用**                          |
|-----------------------------|----------------------------------|
| `-DENABLE_CURL=ON`          | 启用网络网格数据下载（需 `libcurl`） |
| `-DENABLE_TIFF=ON`          | 启用 TIFF 网格支持（需 `libtiff`）  |
| `-DBUILD_TESTING=ON`        | 启用测试套件                      |
| `-DCMAKE_BUILD_TYPE=Debug`  | 调试模式（开发时使用）            |

---

### **5. 依赖项**
- **编译时必需**：  
  - C++11 兼容编译器（GCC ≥ 4.8、Clang ≥ 3.5）。  
  - SQLite3 ≥ 3.11（用于数据库支持）。  
- **运行时可选**：  
  - **libtiff**：读取本地网格文件。  
  - **libcurl**：在线获取网格数据。  

---

### **6. 验证安装**
```bash
proj --version            # 查看版本
projinfo EPSG:4326 EPSG:3857  # 测试坐标转换
```

---

### **7. 文档与社区**
- **API 文档**：https://proj.org/documentation/  
- **邮件列表**：mailto:proj@lists.osgeo.org  
- **Slack 频道**：https://osgeo.slack.com/archives/C01PVGDN9CX。

---

### **8. 常见问题**
#### **Q1：找不到 `proj.h` 头文件**
- **原因**：安装路径未加入编译器搜索路径。  
- **解决**：  
  ```bash
  export C_INCLUDE_PATH=/usr/local/include:$C_INCLUDE_PATH
  export CPLUS_INCLUDE_PATH=/usr/local/include:$CPLUS_INCLUDE_PATH
  ```

#### **Q2：运行时缺少 `proj.db`**
- **原因**：数据库文件未正确安装。  
- **解决**：  
  ```bash
  sudo cp /usr/local/share/proj/proj.db /usr/share/proj/
  ```

---

### **总结**
- **生产环境**：建议使用稳定版（如 9.x）。  
- **开发调试**：从 GitHub 克隆 `master` 分支。  
- **快速安装**：通过系统包管理器（如 `apt install libproj-dev`）。

=======================================
# 12.libsqlite3的github地址

以下是 **SQLite**（轻量级嵌入式数据库）的官方源码地址和相关资源：

---

### **1. 官方源码仓库**
🔗 **https://github.com/sqlite/sqlite**  
- **主仓库**：包含完整的 SQLite 源码（C 语言实现）。  
- **分支说明**：  
  - `master`：主开发分支（最新功能，可能不稳定）。  
  - `version-3.xx.x`：稳定版本分支（如 `version-3.41.2`）。  

---

### **2. 官方下载地址**
🔗 **https://www.sqlite.org/download.html**  
- 提供预编译的二进制文件、源码压缩包（如 `sqlite-amalgamation-3420000.zip`）和文档。  
- **合并版本（Amalgamation）**：推荐使用，所有源码合并为单个 `.c` 和 `.h` 文件，便于集成。  

---

### **3. 克隆源码（最新开发版）**
```bash
git clone https://github.com/sqlite/sqlite.git
cd sqlite
git checkout version-3.50.4 # 切换到稳定版本
```

---

### **4. 编译安装指南**
#### **基础步骤（Linux/macOS）**
```bash
# 生成合并版本（可选）
./configure --enable-amalgamation
make sqlite3.c

# 编译命令行工具和库
mkdir -p ./build/install && cd build
../configure --enable-all --enable-debug CFLAGS='-O0 -g' --prefix=./install
make -j$(nproc)
sudo make install
```

#### **关键编译选项**
| **选项**                | **作用**                          |
|-------------------------|----------------------------------|
| `--enable-amalgamation` | 生成合并版本（`sqlite3.c`）       |
| `--enable-debug`        | 启用调试符号                      |
| `--enable-fts5`         | 启用全文搜索扩展（FTS5）          |
| `--enable-json1`        | 启用 JSON 支持                    |

---

### **5. 依赖项**
- **必需**：C 编译器（GCC/Clang）、Make。  
- **可选**：  
  - **Tcl**：用于测试套件（`make test`）。  
  - **Readline**：命令行工具的历史记录支持。  

---

### **6. 验证安装**
```bash
sqlite3 --version  # 查看版本
sqlite3 test.db    # 启动交互式命令行
```

---

### **7. 文档与社区**
- **官方文档**：https://www.sqlite.org/docs.html  
- **邮件列表**：mailto:sqlite-users@mailinglists.sqlite.org  
- **Stack Overflow**：https://stackoverflow.com/questions/tagged/sqlite  

---

### **8. 常见问题**
#### **Q1：如何集成到项目中？**
直接使用合并版本（`sqlite3.c` 和 `sqlite3.h`）：  
```bash
wget https://www.sqlite.org/2023/sqlite-amalgamation-3420000.zip
unzip sqlite-amalgamation-3420000.zip
gcc your_app.c sqlite3.c -lpthread -ldl -o your_app
```

#### **Q2：编译时报错 `missing sqlite3.h`**
- **解决**：指定头文件路径：  
  ```bash
  gcc -I/path/to/sqlite3/include your_code.c -lsqlite3
  ```

---

### **总结**
- **生产环境**：推荐从官网下载合并版本或稳定分支。  
- **开发调试**：从 GitHub 克隆仓库并切换至特定版本。  
- **快速安装**：通过系统包管理器（如 `apt install sqlite3 libsqlite3-dev`）。

===========================================
# 13.libexpat的github地址

以下是 **Expat**（XML 解析库）的官方源码地址和关键资源：

---

### **1. 官方 GitHub 仓库**
🔗 **https://github.com/libexpat/libexpat**  
- **主仓库**：包含完整的 Expat 源码（C 语言实现）。  
- **分支说明**：  
  - `master`：主开发分支（最新功能）。  
  - `R_2.x.x`：稳定版本分支（如 `R_2.5.0`）。  

---

### **2. 官方下载地址**
🔗 **https://libexpat.github.io/**  
- 提供稳定版源码压缩包（如 `expat-2.5.0.tar.gz`）。  
- 历史版本存档：https://github.com/libexpat/libexpat/releases。

---

### **3. 克隆源码（最新开发版）**
```bash
git clone https://github.com/libexpat/libexpat.git
cd libexpat
git checkout R_2.5.0  # 切换到稳定版本
```

---

### **4. 编译安装指南**
#### **基础步骤（CMake）**
```bash
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local \
         -DBUILD_SHARED_LIBS=ON \
         -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
sudo make install
```

#### **关键选项**
| **CMake 选项**               | **作用**                          |
|-----------------------------|----------------------------------|
| `-DBUILD_SHARED_LIBS=ON`    | 生成动态库（默认）                |
| `-DBUILD_DOCS=OFF`          | 禁用文档生成（加速编译）          |
| `-DEXPAT_BUILD_TOOLS=ON`    | 构建命令行工具（如 `xmlwf`）      |

---

### **5. 依赖项**
- **必需**：C 编译器（GCC/Clang）、CMake ≥ 3.5。  
- **可选**：  
  - **Doxygen**：生成 API 文档（需 `-DBUILD_DOCS=ON`）。  

---

### **6. 验证安装**
```bash
xmlwf -v  # 查看版本（需启用工具编译）
```
或通过代码测试：
```c
#include <stdio.h>
#include <expat.h>
int main() {
    printf("Expat version: %d.%d.%d\n", XML_MAJOR_VERSION, XML_MINOR_VERSION, XML_MICRO_VERSION);
    return 0;
}
```
编译并运行：
```bash
gcc test.c -lexpat -o test && ./test
```

---

### **7. 文档与社区**
- **API 文档**：https://libexpat.github.io/doc/  
- **邮件列表**：mailto:expat-discuss@lists.libexpat.org  

---

### **8. 常见问题**
#### **Q1：找不到 `expat.h` 头文件**
- **原因**：安装路径未加入编译器搜索路径。  
- **解决**：  
  ```bash
  export C_INCLUDE_PATH=/usr/local/include:$C_INCLUDE_PATH
  ```

#### **Q2：链接错误 `undefined reference to XML_xxx`**
- **原因**：未正确链接库。  
- **解决**：  
  ```bash
  gcc your_code.c -lexpat -o your_app
  ```

---

### **总结**
- **生产环境**：建议使用稳定版（如 `R_2.5.0`）。  
- **快速安装**：通过系统包管理器（如 `apt install libexpat-dev`）。  
- **集成到项目**：直接使用合并的 `libexpat.a` 或动态库。  

如果需要进一步调试，可通过 `-DCMAKE_BUILD_TYPE=Debug` 启用调试符号。
