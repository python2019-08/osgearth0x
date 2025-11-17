# 1. automake

使用 `configure` 脚本的编译体系是 **Autotools**（也称为 GNU Build System）。

## Autotools 编译体系

### 核心组件
| 工具 | 作用 |
|------|------|
| **autoconf** | 生成 `configure` 脚本 |
| **automake** | 生成 `Makefile.in` 模板 |
| **libtool** | 管理库的编译和链接 |
| **make** | 执行实际的编译过程 |

### 典型工作流程
```bash
# 1. 生成 configure 脚本（开发者操作）
autoreconf -iv

# 2. 用户配置（交叉编译关键步骤）
./configure --host=aarch64-linux-android \
            --prefix=/install/path \
            CC=aarch64-linux-android-clang \
            CXX=aarch64-linux-android-clang++

# 3. 编译
make -j8

# 4. 安装
make install
```

## 与 CMake 的关键区别

| 特性 | Autotools (configure) | CMake |
|------|----------------------|-------|
| **配置文件** | `configure.ac`, `Makefile.am` | `CMakeLists.txt` |
| **生成文件** | `configure` 脚本 | `CMakeCache.txt`, 构建文件 |
| **跨平台** | 主要 Unix/Linux | 全平台（Windows/macOS/Linux） |
| **交叉编译** | 手动设置工具链 | 工具链文件 |
| **依赖检测** | 运行时检测 | 配置时检测 |

## Android 交叉编译示例

### Autotools 方式：
```bash
export ANDROID_NDK=/path/to/ndk
export TOOLCHAIN=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64

./configure \
    --host=aarch64-linux-android \
    --prefix=$PWD/install \
    CC=$TOOLCHAIN/bin/aarch64-linux-android28-clang \
    CXX=$TOOLCHAIN/bin/aarch64-linux-android28-clang++ \
    AR=$TOOLCHAIN/bin/aarch64-linux-android-ar \
    STRIP=$TOOLCHAIN/bin/aarch64-linux-android-strip \
    RANLIB=$TOOLCHAIN/bin/aarch64-linux-android-ranlib \
    CFLAGS="-fPIC -DANDROID" \
    CXXFLAGS="-fPIC -DANDROID"
```

### 对应 CMake 方式：
```cmake
# android-toolchain.cmake
set(CMAKE_SYSTEM_NAME Android)
set(CMAKE_SYSTEM_VERSION 28)
set(CMAKE_ANDROID_ARCH_ABI arm64-v8a)
set(CMAKE_ANDROID_NDK /path/to/ndk)
```

## Autotools 的优势和劣势

### 优势：
- ✅ **成熟稳定**：几十年历史，广泛测试
- ✅ **自动检测**：自动检测系统特性和依赖
- ✅ **灵活性**：高度可定制的配置选项

### 劣势：
- ❌ **学习曲线**：需要理解 m4 宏和 shell 脚本
- ❌ **Windows 支持差**：主要针对 Unix-like 系统
- ❌ **交叉编译复杂**：需要手动设置所有工具链变量

## 在 vcpkg 中的处理

vcpkg 对 Autotools 项目有内置支持：

### vcpkg_configure_make()
```cmake
# 在 portfile.cmake 中
vcpkg_configure_make(
    SOURCE_PATH "${SOURCE_PATH}"
    AUTOCONFIG
    OPTIONS
        --disable-dependency-tracking
        --disable-silent-rules
    OPTIONS_RELEASE
        --enable-optimizations
    OPTIONS_DEBUG
        --enable-debug
)
```

### 常见问题处理
```cmake
# 1. 设置交叉编译变量
vcpkg_configure_make(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        --host=${HOST_TRIPLET}
        CC=${CMAKE_C_COMPILER}
        CXX=${CMAKE_CXX_COMPILER}
)

# 2. 禁用不需要的功能
vcpkg_configure_make(
    OPTIONS
        --disable-nls
        --disable-docs
        --without-python
)

# 3. 添加编译标志
vcpkg_configure_make(
    OPTIONS
        CFLAGS="-fPIC -O2"
        CXXFLAGS="-fPIC -O2"
)
```

## 识别 Autotools 项目

查看项目根目录是否有：
```bash
ls -la
# 关键文件：
# configure.ac    # Autoconf 输入文件
# Makefile.am     # Automake 输入文件  
# configure       # 生成的配置脚本
# Makefile.in     # 生成的 Makefile 模板
```

## 总结

**Autotools (configure)** 是：
- 基于 shell 脚本的编译系统
- 通过 `./configure && make && make install` 工作
- 在开源项目中非常常见
- 交叉编译需要手动设置工具链变量
- vcpkg 通过 `vcpkg_configure_make()` 封装支持

虽然现代项目越来越多地使用 CMake，但许多经典库（如 zlib、libpng、curl 等）仍然使用 Autotools。