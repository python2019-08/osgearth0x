# 0. Android NDK 开发中使用 ASan 时，所有相互依赖的库都需要使用相同的 ASan 选项编译
问题：在android ndk 开发调试ndk so liba.so时，liba.so依赖于libb.a,libb.a依赖于libc.a.则所有的依赖库（liba.so 、libb.a、libc.a）都要使用Asan选项编译么？


答案: 在 Android NDK 开发中使用 ASan 时，**所有相互依赖的库都需要使用相同的 ASan 选项编译**。以下是详细规则：

## ✅ **核心原则：一致性编译**

### **必须全部使用 ASan 的情况：**
```cmake
# 所有相互依赖的库都必须使用相同的 ASan 标志
target_compile_options(libc PRIVATE -fsanitize=address)
target_compile_options(libb PRIVATE -fsanitize=address)  
target_compile_options(liba PRIVATE -fsanitize=address)

# 链接时也要传递 ASan 标志
set_target_properties(libc PROPERTIES LINK_FLAGS -fsanitize=address)
set_target_properties(libb PROPERTIES LINK_FLAGS -fsanitize=address)
set_target_properties(liba PROPERTIES LINK_FLAGS -fsanitize=address)
```

**依赖链：** `liba.so` → `libb.a` → `libc.a`  
**要求：** 所有三个库都必须使用 `-fsanitize=address` 编译。

---

## 🔍 **技术原理**

### **为什么需要一致性？**
1. **内存布局统一**  
   ASan 会修改内存分配和布局，混合编译会导致内存访问错误。

2. **符号解析一致**  
   ASan 替换了标准的内存函数（如 `malloc`、`free`），所有库必须使用相同的替换版本。

3. **运行时兼容性**  
   部分库使用 ASan 而其他库不使用，会导致运行时崩溃或检测失效。

---

## 🛠️ **具体配置方案**

### **方案一：全局统一配置（推荐）**
在顶层的 `CMakeLists.txt` 中设置全局标志：
```cmake
# 设置全局编译标志
add_compile_options(-fsanitize=address -fno-omit-frame-pointer)

# 设置全局链接标志  
add_link_options(-fsanitize=address)

# 然后正常添加库
add_library(libc STATIC libc_sources.cpp)
add_library(libb STATIC libb_sources.cpp) 
add_library(liba SHARED liba_sources.cpp)

# 链接依赖关系
target_link_libraries(libb PRIVATE libc)
target_link_libraries(liba PRIVATE libb)
```

### **方案二：逐库配置**
如果无法全局设置，确保每个库都单独配置：
```cmake
# libc.a
add_library(libc STATIC libc_sources.cpp)
target_compile_options(libc PRIVATE -fsanitize=address -fno-omit-frame-pointer)
set_target_properties(libc PROPERTIES LINK_FLAGS -fsanitize=address)

# libb.a  
add_library(libb STATIC libb_sources.cpp)
target_compile_options(libb PRIVATE -fsanitize=address -fno-omit-frame-pointer)
set_target_properties(libb PROPERTIES LINK_FLAGS -fsanitize=address)
target_link_libraries(libb PRIVATE libc)

# liba.so
add_library(liba SHARED liba_sources.cpp) 
target_compile_options(liba PRIVATE -fsanitize=address -fno-omit-frame-pointer)
set_target_properties(liba PROPERTIES LINK_FLAGS -fsanitize=address)
target_link_libraries(liba PRIVATE libb)
```

---

## ⚠️ **常见问题与例外情况**

### **1. 第三方预编译库**
如果 `libb.a` 或 `libc.a` 是第三方预编译库：
```cmake
# 情况1：第三方库提供 ASan 版本（推荐）
find_library(LIBB_ASAN libb_asan.a)
target_link_libraries(liba PRIVATE ${LIBB_ASAN})

# 情况2：第三方库无 ASan 版本（可能有问题）
# 需要确保第三方库是"ASan-safe"的（不依赖特定内存布局）
```

### **2. 系统库例外**
系统库（如 `libc++`、`liblog`）通常不需要重新编译，NDK 会提供兼容版本。

---

## 🔧 **验证方法**

### **检查库是否包含 ASan 符号：**
```bash
# 检查静态库是否包含 ASan 相关符号
nm libb.a | grep -i asan
nm libc.a | grep -i asan

# 检查动态库的依赖
readelf -d liba.so | grep NEEDED
```

### **运行时验证：**
```bash
# 运行应用，检查 ASan 是否生效
adb logcat | grep -i asan
```

---

## 📋 **总结表格**

| 库类型 | ASan 要求 | 说明 |
|--------|-----------|------|
| **主库 (liba.so)** | ✅ 必须使用 ASan | 需要检测内存问题 |
| **直接依赖静态库 (libb.a)** | ✅ 必须使用 ASan | 与主库直接交互 |
| **间接依赖静态库 (libc.a)** | ✅ 必须使用 ASan | 通过 libb.a 间接依赖 |
| **系统库** | ❌ 不需要重新编译 | NDK 自动处理兼容性 |
| **第三方预编译库** | ⚠️ 需要 ASan 版本 | 否则可能不兼容 |

## 💡 **最佳实践建议**
1. **统一编译环境**：所有依赖库使用相同的 NDK 版本和编译选项。
2. **优先使用动态链接**：考虑将 `libb.a` 和 `libc.a` 改为动态库，简化 ASan 管理。
3. **分层测试**：先单独测试每个库的 ASan 编译，再整合验证。

**结论：** 在您的依赖链 `liba.so → libb.a → libc.a` 中，**所有三个库都必须使用 ASan 选项编译**，否则会出现运行时错误或 ASan 检测失效。

# 1.Address Sanitizer

https://developer.android.google.cn/ndk/guides/asan?hl=cs
 
**注意**：本文档将介绍如何在 Address Sanitizer 下运行使用 NDK 构建的 Android 应用。如需了解如何对 Android 平台组件使用 Address Sanitizer，请参阅 AOSP 文档。

**已废弃：自 2023 年起，ASan 不再受支持。建议改用 HWASan。HWASan 可在搭载 Android 14（API 级别 34）或更高版本的 ARM64 设备上使用；或通过刷写特殊系统映像在搭载 Android 10（API 级别 29）的 Pixel 设备上使用。ASan 仍然可以使用，但可能存在 bug。**

**重要提示**：Asan 是用于调试和减少内存错误的众多工具之一。如需简要了解所有工具，请参阅[调试和减少内存错误](https://developer.android.google.cn/ndk/guides/memory-debug?hl=cs)。

从 API 级别 27 (Android O MR 1) 开始，Android NDK 可支持 Address Sanitizer（也称为 ASan）。

ASan 是一种基于编译器的快速检测工具，用于检测原生代码中的内存错误。ASan 可以检测以下问题：

堆栈和堆缓冲区上溢/下溢
释放之后的堆使用情况
超出范围的堆栈使用情况
重复释放/错误释放
ASan 的 CPU 开销约为 2 倍，代码大小开销在 50% 到 2 倍之间，并且内存开销很大（具体取决于您的分配模式，但约为 2 倍）。

## 示例应用
[示例应用](https://github.com/android/ndk-samples/tree/main/sanitizers)展示了如何为 asan 配置 build 变体。

## 构建
如需使用 Address Sanitizer 构建应用的原生 (JNI) 代码，请添加以下代码：

注意：在使用 libc++_static 时，ASan 目前不兼容 C++ 异常处理。使用 libc++_shared 或不使用异常处理的应用或者不受影响，或者有相应解决方法。如需了解详情，请参阅问题 988。
## 运行
从 Android O MR1（API 级别 27）开始，应用可以提供可封装或替换应用进程的封装 Shell 脚本。这样一来，可调试的应用就可对其应用启动过程进行自定义，以便在生产设备上使用 ASan。

注意：以下说明将介绍如何在 Android Studio 项目中使用 ASan。对于非 Android Studio 项目，请参阅封装 Shell 脚本文档。
将 android:debuggable 添加到应用清单中。
在应用的 build.gradle 文件中将 useLegacyPackaging 设置为 true。如需了解详情，请参阅封装 Shell 脚本指南。
将 ASan 运行时库添加到应用模块的 jniLibs 中。
将包含以下内容的 wrap.sh 文件添加到 src/main/resources/lib 目录中的每个目录。

#!/system/bin/sh
HERE="$(cd "$(dirname "$0")" && pwd)"
export ASAN_OPTIONS=log_to_syslog=false,allow_user_segv_handler=1
ASAN_LIB=$(ls $HERE/libclang_rt.asan-*-android.so)
if [ -f "$HERE/libc++_shared.so" ]; then
    # Workaround for https://github.com/android-ndk/ndk/issues/988.
    export LD_PRELOAD="$ASAN_LIB $HERE/libc++_shared.so"
else
    export LD_PRELOAD="$ASAN_LIB"
fi
"$@"
注意：NDK 在此处提供了适用于 ASan、推荐使用的 wrap.sh 文件。
假设您项目的应用模块的名称为 app，最终的目录结构应包含以下内容：

<project root>
└── app
    └── src
        └── main
            ├── jniLibs
            │   ├── arm64-v8a
            │   │   └── libclang_rt.asan-aarch64-android.so
            │   ├── armeabi-v7a
            │   │   └── libclang_rt.asan-arm-android.so
            │   ├── x86
            │   │   └── libclang_rt.asan-i686-android.so
            │   └── x86_64
            │       └── libclang_rt.asan-x86_64-android.so
            └── resources
                └── lib
                    ├── arm64-v8a
                    │   └── wrap.sh
                    ├── armeabi-v7a
                    │   └── wrap.sh
                    ├── x86
                    │   └── wrap.sh
                    └── x86_64
                        └── wrap.sh
## 堆栈轨迹
Address Sanitizer 需要在每次调用 malloc/realloc/free 时都展开堆栈。这里介绍两个选项：

基于帧指针的“快速”展开程序。按照构建部分中的说明执行操作时使用的就是此展开程序。

“慢速”CFI 展开程序。在此模式下，ASan 会使用 _Unwind_Backtrace。它只需要使用 -funwind-tables（通常默认处于启用状态）。

注意：“慢速”展开程序速度缓慢（速度差距达 10 倍或更多，具体取决于您调用 malloc/free 的频率）。
快速展开程序是 malloc/realloc/free 的默认选项。慢速展开程序是严重异常所对应堆栈轨迹的默认选项。通过将 fast_unwind_on_malloc=0 添加到 wrap.sh 的 ASAN_OPTIONS 变量中，即可为所有堆栈轨迹启用慢速展开程序。
==============================================================
# 2.HWAddress Sanitizer
https://developer.android.google.cn/ndk/guides/hwasan?hl=nb#ndk-build

注意：本文档将介绍如何在 HWAddress Sanitizer 下运行使用 NDK 构建的 Android 应用。如需了解如何对 Android 平台组件使用 HWAddress Sanitizer，请参阅 AOSP 文档。
从 NDK r21 和 Android 10（API 级别 29）开始，Android NDK 支持 HWAddress Sanitizer（也称为 HWASan）。HWASan 仅适用于 64 位 Arm 设备。

重要提示：HWAsan 是用于调试和减少内存错误的众多工具之一。如需简要了解所有工具，请参阅调试和减少内存错误。

HWASan 是一款类似于 ASan 的内存错误检测工具。与传统的 ASan 相比，HWASan 具有如下特征：
> 类似的 CPU 开销（约为 2 倍）
> 类似的代码大小开销 (40 - 50%)
> 更小的 RAM 开销 (10% - 35%)

HWASan 能检测到 ASan 所能检测到的同一系列错误：
> 堆栈和堆缓冲区上溢或下溢
> 释放之后的堆使用情况
> 超出范围的堆栈使用情况
> 重复释放或错误释放

此外，HWASan 还可以检测：
返回之后的堆栈使用情况

## 1.示例应用
[示例应用](https://github.com/android/ndk-samples/tree/main/sanitizers)展示了如何为 hwasan 配置 [build 变体](https://developer.android.google.cn/studio/build/build-variants?hl=nb)。

## 2.构建
重要提示：请务必使用最新的 NDK 来构建代码。
若要使用 HWAddress Sanitizer 构建应用的原生 (JNI) 代码，请执行以下操作：

### 2.1Application.mk 
在您的 Application.mk 文件中： 
```mk
APP_STL := c++_shared # Or system, or none, but not c++_static.
APP_CFLAGS := -fsanitize=hwaddress -fno-omit-frame-pointer
APP_LDFLAGS := -fsanitize=hwaddress
```
### 2.2CMake (Gradle Groovy)
在模块的 build.gradle 文件中：
```
android {
    defaultConfig {
        externalNativeBuild {
            cmake {
                # Can also use system or none as ANDROID_STL, but not c++_static.
                arguments "-DANDROID_STL=c++_shared"
            }
        }
    }
}
```

对于 CMakeLists.txt 中的每个目标：
```
target_compile_options(${TARGET} PUBLIC -fsanitize=hwaddress -fno-omit-frame-pointer)
target_link_options(${TARGET} PUBLIC -fsanitize=hwaddress)
```

如果使用 NDK 27 或更高版本，您还可以在 build.gradle 中使用以下内容，而无需更改 CMakeLists.txt：
```
android {
    defaultConfig {
        externalNativeBuild {
            cmake {
                arguments "-DANDROID_SANITIZE=hwaddress"
            }
        }
    }
}
```
使用 ANDROID_USE_LEGACY_TOOLCHAIN_FILE=false 时，此方法将不起作用。

### 2.3 CMake (Gradle Kotlin)

在模块的 build.gradle 文件中：
```
android {
    defaultConfig {
        externalNativeBuild {
            cmake {
                # Can also use system or none as ANDROID_STL, but not c++_static.
                arguments += "-DANDROID_STL=c++_shared"
            }
        }
    }
}
```

对于 CMakeLists.txt 中的每个目标：
```
target_compile_options(${TARGET} PUBLIC -fsanitize=hwaddress -fno-omit-frame-pointer)
target_link_options(${TARGET} PUBLIC -fsanitize=hwaddress)
```

如果使用 NDK 27 或更高版本，您还可以在 build.gradle 中使用以下内容，而无需更改 CMakeLists.txt：
```
android {
    defaultConfig {
        externalNativeBuild {
            cmake {
                arguments += "-DANDROID_SANITIZE=hwaddress"
            }
        }
    }
}
```
使用 ANDROID_USE_LEGACY_TOOLCHAIN_FILE=false 时，此方法将不起作用。

**注意：必须提供共享库 STL，因为 STL 中的 new 和 delete 运算符的实现通常是在没有框架指针的情况下构建的。HWASan 可提供自己的实现，但如果 STL 是以静态方式链接到应用，您将无法使用此实现。**

### Android 14 或更高版本：添加 wrap.sh
重要提示： 这与在 AndroidManifest 中使用 android:useAppZygote 不兼容。移除 android:useAppZygote 以便使用 HWASan 进行测试，或者按照设置说明操作（如果您需要保留 android:useAppZygote）。

如果您运行的是 Android 14 或更高版本，则可以使用 wrap.sh 脚本在任何由 Android 提供支持的设备上运行您的可调试应用。如果您选择按照设置说明中的步骤操作，则可以跳过此步骤。

按照说明打包 wrap.sh 脚本，为 arm64-v8a 添加以下 wrap.sh 脚本。
```
#!/system/bin/sh
LD_HWASAN=1 exec "$@"
```
## 3.运行
如果您运行的是低于 14 的 Android 版本，或者未添加 wrap.sh 脚本，请在运行应用之前按照设置说明操作。

照常运行应用。当检测到内存错误时，应用会因 SIGABRT 而崩溃，并向 logcat 输出详细消息。您可以在 /data/tombstones 下的文件中找到该消息的副本，内容如下：
```
ERROR: HWAddressSanitizer: tag-mismatch on address 0x0042a0826510 at pc 0x007b24d90a0c
WRITE of size 1 at 0x0042a0826510 tags: 32/3d (ptr/mem) in thread T0
    #0 0x7b24d90a08  (/data/app/com.example.hellohwasan-eRpO2UhYylZaW0P_E0z7vA==/lib/arm64/libnative-lib.so+0x2a08)
    #1 0x7b8f1e4ccc  (/apex/com.android.art/lib64/libart.so+0x198ccc)
    #2 0x7b8f1db364  (/apex/com.android.art/lib64/libart.so+0x18f364)
    #3 0x7b8f2ad8d4  (/apex/com.android.art/lib64/libart.so+0x2618d4)

0x0042a0826510 is located 0 bytes to the right of 16-byte region [0x0042a0826500,0x0042a0826510)
allocated here:
    #0 0x7b92a322bc  (/apex/com.android.runtime/lib64/bionic/libclang_rt.hwasan-aarch64-android.so+0x212bc)
    #1 0x7b24d909e0  (/data/app/com.example.hellohwasan-eRpO2UhYylZaW0P_E0z7vA==/lib/arm64/libnative-lib.so+0x29e0)
    #2 0x7b8f1e4ccc  (/apex/com.android.art/lib64/libart.so+0x198ccc)
```
消息后面可能还跟着其他调试信息，包括应用中的活动线程列表、临近内存分配的标记和 CPU 寄存器值。

如需详细了解 HWASan 错误消息，请参阅了解 HWASan 报告。
## 4.构建命令行可执行文件
**重要提示： 请务必使用最新的 NDK。对于 r26b 之前的 NDK，此操作会失败。**
您可以在 Android 14 及更高版本上构建和运行通过 HWASan 检测的可执行文件。您可以针对可执行文件使用与 Build 中针对 ndk-build 或 CMake 描述的相同的配置。将可执行文件推送到搭载 Android 14 或更高版本的设备，然后使用 shell 正常运行。

如果您使用的是 libc++，请确保您使用的是共享 STL，并将其推送到设备，然后在运行二进制文件时将 LD_LIBRARY_PATH 设置为包含该共享 STL 的目录。

如果您不使用 Gradle，请参阅 NDK 文档，了解如何使用 CMake 和 ndk-build 从命令行进行构建。

### Android 13 或更低版本：设置
如果您的设备搭载的是 Android 14 或更高版本，您可以跳过此步骤，然后按照构建部分中的使用 wrap.sh 的说明进行操作。您也可以选择按照本部分操作，并跳过有关使用 wrap.sh 的说明。

在 Android 14 之前，HWASan 应用需要 Android 的 HWASan build 才能运行。您可以将预构建的 HWASan 映像刷写到支持的 Pixel 设备上。在 ci.android.com 上可以找到这些 build，您可以在此页面上点击所需的确切 build 的方格来获取 Flash Build 链接。您需要知道您手机的代号。






==============================================================
# 2.callstack 5

```sh
2025-11-08 13:30:31.460  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  ==5692==Shadow memory range interleaves with an existing memory mapping. ASan cannot proceed correctly. ABORTING.
2025-11-08 13:30:31.460  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  ==5692==ASan shadow was supposed to be located in the [0x00007fff7000-0x10007fff7fff] range.
2025-11-08 13:30:31.460  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  ==5692==This might be related to ELF_ET_DYN_BASE change in Linux 4.12.
2025-11-08 13:30:31.460  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  ==5692==See https://github.com/google/sanitizers/issues/856 for possible workarounds.
2025-11-08 13:30:31.467  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  ==5692==Process memory map follows:
2025-11-08 13:30:31.467  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000014000000-0x000020000000	[anon:dalvik-main space]
2025-11-08 13:30:31.467  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000040085000-0x00004008d000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.468  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000040125000-0x000040129000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.468  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x00004020a000-0x000040211000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.468  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x00004023c000-0x00004027d000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.468  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000402a8000-0x0000402b6000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.468  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000404c0000-0x0000404c4000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.468  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x00004058c000-0x000040592000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.468  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000405a4000-0x0000405a8000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.468  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000406d2000-0x0000406ef000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.468  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000407ee000-0x0000407f7000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.468  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000408b6000-0x0000408ba000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.468  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000040a5e000-0x000040a65000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.468  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000040be7000-0x000040beb000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.468  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000040cb5000-0x000040cbb000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.468  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000040d83000-0x000040d87000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.468  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000040e52000-0x000040e56000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.469  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000040e72000-0x000040e76000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.469  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000040f0a000-0x000040f28000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.469  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000040f4a000-0x000040f51000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.469  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x00004121b000-0x00004121d000	
2025-11-08 13:30:31.469  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000412e9000-0x000041363000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.469  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x00004145b000-0x000041464000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.469  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000414e1000-0x0000414e8000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.469  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x00004154d000-0x000041551000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.469  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000418d9000-0x0000418df000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.469  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000041937000-0x000041940000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.469  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000419e9000-0x0000419f1000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.469  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000041a7c000-0x000041a81000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.469  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000041b85000-0x000041b91000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.469  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000041c2e000-0x000043c2e000	/memfd:jit-zygote-cache (deleted)
2025-11-08 13:30:31.469  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000043c2e000-0x000045c2e000	[anon_shmem:dalvik-zygote-jit-code-cache]
2025-11-08 13:30:31.469  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000045c2e000-0x000045c56000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.470  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000045c5b000-0x000045c61000	[anon:dalvik-large object space allocation]
2025-11-08 13:30:31.470  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000045c61000-0x000047c61000	/memfd:jit-cache (deleted)
2025-11-08 13:30:31.470  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000047c61000-0x000049c61000	[anon_shmem:dalvik-jit-code-cache]
2025-11-08 13:30:31.470  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000704d8000-0x0000707ac000	[anon:dalvik-/system/framework/boot.art]
2025-11-08 13:30:31.470  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000707ac000-0x0000707f4000	[anon:dalvik-/system/framework/boot-core-libart.art]
2025-11-08 13:30:31.470  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000707f4000-0x000070820000	[anon:dalvik-/system/framework/boot-okhttp.art]
2025-11-08 13:30:31.470  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000070820000-0x000070854000	[anon:dalvik-/system/framework/boot-bouncycastle.art]
2025-11-08 13:30:31.470  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000070854000-0x000070858000	[anon:dalvik-/system/framework/boot-apache-xml.art]
2025-11-08 13:30:31.470  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000070858000-0x00007159c000	[anon:dalvik-/system/framework/boot-framework.art]
2025-11-08 13:30:31.470  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x00007159c000-0x0000715a0000	[anon:dalvik-/system/framework/boot-framework-graphics.art]
2025-11-08 13:30:31.470  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000715a0000-0x0000715a4000	[anon:dalvik-/system/framework/boot-framework-location.art]
2025-11-08 13:30:31.470  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000715a4000-0x0000715d4000	[anon:dalvik-/system/framework/boot-ext.art]
2025-11-08 13:30:31.470  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000715d4000-0x00007172c000	[anon:dalvik-/system/framework/boot-telephony-common.art]
2025-11-08 13:30:31.470  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x00007172c000-0x0000717d4000	[anon:dalvik-/system/framework/boot-voip-common.art]
2025-11-08 13:30:31.470  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000717d4000-0x000071820000	[anon:dalvik-/system/framework/boot-ims-common.art]
2025-11-08 13:30:31.470  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071820000-0x0000719a8000	[anon:dalvik-/system/framework/boot-core-icu4j.art]
2025-11-08 13:30:31.471  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000719a8000-0x000071a48000	/system/framework/x86_64/boot.oat
2025-11-08 13:30:31.471  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071a48000-0x000071c8e000	/system/framework/x86_64/boot.oat
2025-11-08 13:30:31.471  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071c8e000-0x000071c90000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.471  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071c90000-0x000071c91000	[anon:.bss]
2025-11-08 13:30:31.471  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071c91000-0x000071c94000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.471  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071c94000-0x000071cb0000	/system/framework/boot.vdex
2025-11-08 13:30:31.471  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071cb0000-0x000071cb1000	/system/framework/x86_64/boot.oat
2025-11-08 13:30:31.471  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071cb1000-0x000071cb4000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.471  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071cb4000-0x000071cb5000	/system/framework/x86_64/boot.oat
2025-11-08 13:30:31.471  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071cb5000-0x000071cb8000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.471  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071cb8000-0x000071ccc000	/system/framework/x86_64/boot-core-libart.oat
2025-11-08 13:30:31.471  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071ccc000-0x000071d09000	/system/framework/x86_64/boot-core-libart.oat
2025-11-08 13:30:31.471  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071d09000-0x000071d0c000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.471  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071d0c000-0x000071d0d000	[anon:.bss]
2025-11-08 13:30:31.471  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071d0d000-0x000071d10000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.471  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071d10000-0x000071d13000	/system/framework/boot-core-libart.vdex
2025-11-08 13:30:31.471  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071d13000-0x000071d14000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.472  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071d14000-0x000071d15000	/system/framework/x86_64/boot-core-libart.oat
2025-11-08 13:30:31.472  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071d15000-0x000071d18000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.472  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071d18000-0x000071d19000	/system/framework/x86_64/boot-core-libart.oat
2025-11-08 13:30:31.472  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071d19000-0x000071d1c000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.472  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071d1c000-0x000071d30000	/system/framework/x86_64/boot-okhttp.oat
2025-11-08 13:30:31.472  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071d30000-0x000071d5f000	/system/framework/x86_64/boot-okhttp.oat
2025-11-08 13:30:31.472  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071d5f000-0x000071d60000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.472  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071d60000-0x000071d61000	[anon:.bss]
2025-11-08 13:30:31.472  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071d61000-0x000071d64000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.472  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071d64000-0x000071d66000	/system/framework/boot-okhttp.vdex
2025-11-08 13:30:31.472  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071d66000-0x000071d68000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.472  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071d68000-0x000071d69000	/system/framework/x86_64/boot-okhttp.oat
2025-11-08 13:30:31.472  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071d69000-0x000071d6c000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.472  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071d6c000-0x000071d6d000	/system/framework/x86_64/boot-okhttp.oat
2025-11-08 13:30:31.472  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071d6d000-0x000071d70000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.472  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071d70000-0x000071d7c000	/system/framework/x86_64/boot-bouncycastle.oat
2025-11-08 13:30:31.472  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071d7c000-0x000071d8e000	/system/framework/x86_64/boot-bouncycastle.oat
2025-11-08 13:30:31.473  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071d8e000-0x000071d90000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.473  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071d90000-0x000071d91000	[anon:.bss]
2025-11-08 13:30:31.473  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071d91000-0x000071d94000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.473  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071d94000-0x000071d99000	/system/framework/boot-bouncycastle.vdex
2025-11-08 13:30:31.473  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071d99000-0x000071d9c000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.473  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071d9c000-0x000071d9d000	/system/framework/x86_64/boot-bouncycastle.oat
2025-11-08 13:30:31.473  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071d9d000-0x000071da0000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.473  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071da0000-0x000071da1000	/system/framework/x86_64/boot-bouncycastle.oat
2025-11-08 13:30:31.473  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071da1000-0x000071da4000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.473  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071da4000-0x000071dac000	/system/framework/x86_64/boot-apache-xml.oat
2025-11-08 13:30:31.473  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071dac000-0x000071db1000	/system/framework/boot-apache-xml.vdex
2025-11-08 13:30:31.473  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071db1000-0x000071db4000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.473  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071db4000-0x000071db5000	/system/framework/x86_64/boot-apache-xml.oat
2025-11-08 13:30:31.473  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071db5000-0x000071db8000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.473  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071db8000-0x000071db9000	/system/framework/x86_64/boot-apache-xml.oat
2025-11-08 13:30:31.473  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071db9000-0x000071dbc000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.473  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071dbc000-0x000071fb0000	/system/framework/x86_64/boot-framework.oat
2025-11-08 13:30:31.474  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000071fb0000-0x00007261c000	/system/framework/x86_64/boot-framework.oat
2025-11-08 13:30:31.474  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x00007261c000-0x00007261d000	[anon:.bss]
2025-11-08 13:30:31.474  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x00007261d000-0x000072620000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.474  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072620000-0x0000726c5000	/system/framework/boot-framework.vdex
2025-11-08 13:30:31.474  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000726c5000-0x0000726c8000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.474  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000726c8000-0x0000726c9000	/system/framework/x86_64/boot-framework.oat
2025-11-08 13:30:31.474  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000726c9000-0x0000726cc000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.474  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000726cc000-0x0000726cd000	/system/framework/x86_64/boot-framework.oat
2025-11-08 13:30:31.474  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000726cd000-0x0000726d0000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.474  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000726d0000-0x0000726d8000	/system/framework/x86_64/boot-framework-graphics.oat
2025-11-08 13:30:31.474  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000726d8000-0x0000726d9000	/system/framework/boot-framework-graphics.vdex
2025-11-08 13:30:31.474  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000726d9000-0x0000726dc000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.474  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000726dc000-0x0000726dd000	/system/framework/x86_64/boot-framework-graphics.oat
2025-11-08 13:30:31.474  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000726dd000-0x0000726e0000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.474  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000726e0000-0x0000726e1000	/system/framework/x86_64/boot-framework-graphics.oat
2025-11-08 13:30:31.474  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000726e1000-0x0000726e4000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.474  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000726e4000-0x0000726ec000	/system/framework/x86_64/boot-framework-location.oat
2025-11-08 13:30:31.475  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000726ec000-0x0000726ee000	/system/framework/boot-framework-location.vdex
2025-11-08 13:30:31.475  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000726ee000-0x0000726f0000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.475  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000726f0000-0x0000726f1000	/system/framework/x86_64/boot-framework-location.oat
2025-11-08 13:30:31.475  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000726f1000-0x0000726f4000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.475  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000726f4000-0x0000726f5000	/system/framework/x86_64/boot-framework-location.oat
2025-11-08 13:30:31.475  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000726f5000-0x0000726f8000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.475  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000726f8000-0x000072704000	/system/framework/x86_64/boot-ext.oat
2025-11-08 13:30:31.475  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072704000-0x000072719000	/system/framework/x86_64/boot-ext.oat
2025-11-08 13:30:31.475  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072719000-0x00007271c000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.475  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x00007271c000-0x00007271d000	/system/framework/boot-ext.vdex
2025-11-08 13:30:31.475  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x00007271d000-0x000072720000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.475  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072720000-0x000072721000	/system/framework/x86_64/boot-ext.oat
2025-11-08 13:30:31.475  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072721000-0x000072724000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.475  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072724000-0x000072725000	/system/framework/x86_64/boot-ext.oat
2025-11-08 13:30:31.475  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072725000-0x000072728000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.475  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072728000-0x000072734000	/system/framework/x86_64/boot-telephony-common.oat
2025-11-08 13:30:31.475  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072734000-0x000072743000	/system/framework/boot-telephony-common.vdex
2025-11-08 13:30:31.475  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072743000-0x000072744000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.476  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072744000-0x000072745000	/system/framework/x86_64/boot-telephony-common.oat
2025-11-08 13:30:31.476  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072745000-0x000072748000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.476  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072748000-0x000072749000	/system/framework/x86_64/boot-telephony-common.oat
2025-11-08 13:30:31.476  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072749000-0x00007274c000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.476  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x00007274c000-0x000072754000	/system/framework/x86_64/boot-voip-common.oat
2025-11-08 13:30:31.476  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072754000-0x000072755000	/system/framework/x86_64/boot-voip-common.oat
2025-11-08 13:30:31.476  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072755000-0x000072758000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.476  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072758000-0x00007275d000	/system/framework/boot-voip-common.vdex
2025-11-08 13:30:31.476  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x00007275d000-0x000072760000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.476  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072760000-0x000072761000	/system/framework/x86_64/boot-voip-common.oat
2025-11-08 13:30:31.476  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072761000-0x000072764000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.476  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072764000-0x000072765000	/system/framework/x86_64/boot-voip-common.oat
2025-11-08 13:30:31.476  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072765000-0x000072768000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.476  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072768000-0x000072770000	/system/framework/x86_64/boot-ims-common.oat
2025-11-08 13:30:31.476  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072770000-0x000072772000	/system/framework/boot-ims-common.vdex
2025-11-08 13:30:31.476  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072772000-0x000072774000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.476  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072774000-0x000072775000	/system/framework/x86_64/boot-ims-common.oat
2025-11-08 13:30:31.476  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072775000-0x000072778000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.477  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072778000-0x000072779000	/system/framework/x86_64/boot-ims-common.oat
2025-11-08 13:30:31.477  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072779000-0x00007277c000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.477  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x00007277c000-0x0000727ac000	/system/framework/x86_64/boot-core-icu4j.oat
2025-11-08 13:30:31.477  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000727ac000-0x000072868000	/system/framework/x86_64/boot-core-icu4j.oat
2025-11-08 13:30:31.477  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072868000-0x000072869000	[anon:.bss]
2025-11-08 13:30:31.477  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072869000-0x00007286c000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.477  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x00007286c000-0x000072875000	/system/framework/boot-core-icu4j.vdex
2025-11-08 13:30:31.477  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072875000-0x000072878000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.477  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072878000-0x000072879000	/system/framework/x86_64/boot-core-icu4j.oat
2025-11-08 13:30:31.477  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072879000-0x00007287c000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.477  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x00007287c000-0x00007287d000	/system/framework/x86_64/boot-core-icu4j.oat
2025-11-08 13:30:31.477  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x00007287d000-0x000072880000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.477  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000072880000-0x000073078000	[anon:dalvik-/system/framework/boot-framework-adservices.art]
2025-11-08 13:30:31.477  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000073078000-0x000073090000	/system/framework/x86_64/boot-framework-adservices.oat
2025-11-08 13:30:31.477  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x000073090000-0x0000730be000	/system/framework/boot-framework-adservices.vdex
2025-11-08 13:30:31.477  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000730be000-0x0000730c0000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.478  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000730c0000-0x0000730c1000	/system/framework/x86_64/boot-framework-adservices.oat
2025-11-08 13:30:31.478  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000730c1000-0x0000730c4000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.478  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000730c4000-0x0000730c5000	/system/framework/x86_64/boot-framework-adservices.oat
2025-11-08 13:30:31.478  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000730c5000-0x0000730c8000	[anon:dalvik-Boot image reservation]
2025-11-08 13:30:31.478  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000730c8000-0x0000736d3000	[anon:dalvik-zygote space]
2025-11-08 13:30:31.478  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000736d3000-0x0000736d4000	[anon:dalvik-non moving space]
2025-11-08 13:30:31.478  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000736d4000-0x0000736d5000	[anon:dalvik-non moving space]
2025-11-08 13:30:31.478  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000736d5000-0x0000768c9000	[anon:dalvik-non moving space]
2025-11-08 13:30:31.478  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000768c9000-0x0000770c8000	[anon:dalvik-non moving space]
2025-11-08 13:30:31.478  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x0000ebad6000-0x0000ebad7000	[anon:dalvik-Sentinel fault page]
2025-11-08 13:30:31.478  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x62e0d6514000-0x62e0d6516000	/system/bin/app_process64
2025-11-08 13:30:31.478  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x62e0d6518000-0x62e0d651a000	/system/bin/app_process64
2025-11-08 13:30:31.478  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x62e0d651c000-0x62e0d651d000	/system/bin/app_process64
2025-11-08 13:30:31.478  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x62e0d6520000-0x62e0d6521000	/system/bin/app_process64
2025-11-08 13:30:31.478  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x749f80000000-0x749fc0000000	[anon:dalvik-linear-alloc shadow map]
2025-11-08 13:30:31.479  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x749fc0000000-0x74a000000000	[anon:dalvik-LinearAlloc]
2025-11-08 13:30:31.479  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a00ea59000-0x74a00eaf2000	/data/app/~~EApFJKn0TYks1NB7znMWgA==/com.oearth.androioearth01-kkGgvQ6-x5_Ioed2KatziA==/lib/x86_64/libc++_shared.so
2025-11-08 13:30:31.479  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a00eaf2000-0x74a00eaf5000	
2025-11-08 13:30:31.479  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a00eaf5000-0x74a00eb85000	/data/app/~~EApFJKn0TYks1NB7znMWgA==/com.oearth.androioearth01-kkGgvQ6-x5_Ioed2KatziA==/lib/x86_64/libc++_shared.so
2025-11-08 13:30:31.479  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a00eb85000-0x74a00eb88000	
2025-11-08 13:30:31.479  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a00eb88000-0x74a00eb92000	/data/app/~~EApFJKn0TYks1NB7znMWgA==/com.oearth.androioearth01-kkGgvQ6-x5_Ioed2KatziA==/lib/x86_64/libc++_shared.so
2025-11-08 13:30:31.479  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a00eb92000-0x74a00eb95000	
2025-11-08 13:30:31.479  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a00eb95000-0x74a00eb97000	/data/app/~~EApFJKn0TYks1NB7znMWgA==/com.oearth.androioearth01-kkGgvQ6-x5_Ioed2KatziA==/lib/x86_64/libc++_shared.so
2025-11-08 13:30:31.479  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a00eb97000-0x74a00eb9e000	[anon:.bss]
2025-11-08 13:30:31.479  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a00ec00000-0x74a010000000	
2025-11-08 13:30:31.479  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a01006f000-0x74a0100c5000	/data/app/~~EApFJKn0TYks1NB7znMWgA==/com.oearth.androioearth01-kkGgvQ6-x5_Ioed2KatziA==/lib/x86_64/libclang_rt.asan-x86_64-android.so
2025-11-08 13:30:31.479  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0100c5000-0x74a0100c8000	
2025-11-08 13:30:31.479  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0100c8000-0x74a010163000	/data/app/~~EApFJKn0TYks1NB7znMWgA==/com.oearth.androioearth01-kkGgvQ6-x5_Ioed2KatziA==/lib/x86_64/libclang_rt.asan-x86_64-android.so
2025-11-08 13:30:31.479  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a010163000-0x74a010166000	
2025-11-08 13:30:31.479  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a010166000-0x74a010169000	/data/app/~~EApFJKn0TYks1NB7znMWgA==/com.oearth.androioearth01-kkGgvQ6-x5_Ioed2KatziA==/lib/x86_64/libclang_rt.asan-x86_64-android.so
2025-11-08 13:30:31.479  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a010169000-0x74a01016c000	
2025-11-08 13:30:31.479  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a01016c000-0x74a010170000	/data/app/~~EApFJKn0TYks1NB7znMWgA==/com.oearth.androioearth01-kkGgvQ6-x5_Ioed2KatziA==/lib/x86_64/libclang_rt.asan-x86_64-android.so
2025-11-08 13:30:31.479  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a010170000-0x74a010364000	[anon:.bss]
2025-11-08 13:30:31.479  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a010400000-0x74a012600000	
2025-11-08 13:30:31.480  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0126ad000-0x74a01bcd1000	/data/app/~~EApFJKn0TYks1NB7znMWgA==/com.oearth.androioearth01-kkGgvQ6-x5_Ioed2KatziA==/lib/x86_64/libandroioearth01.so
2025-11-08 13:30:31.480  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a01bcd1000-0x74a01bcd4000	
2025-11-08 13:30:31.480  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a01bcd4000-0x74a01c04a000	/data/app/~~EApFJKn0TYks1NB7znMWgA==/com.oearth.androioearth01-kkGgvQ6-x5_Ioed2KatziA==/lib/x86_64/libandroioearth01.so
2025-11-08 13:30:31.480  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a01c04a000-0x74a01c04d000	
2025-11-08 13:30:31.480  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a01c04d000-0x74a01cc7e000	/data/app/~~EApFJKn0TYks1NB7znMWgA==/com.oearth.androioearth01-kkGgvQ6-x5_Ioed2KatziA==/lib/x86_64/libandroioearth01.so
2025-11-08 13:30:31.480  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a01cc7e000-0x74a01cdbc000	[anon:.bss]
2025-11-08 13:30:31.480  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a01ce00000-0x74a01ee00000	
2025-11-08 13:30:31.480  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a01f42f000-0x74a01f7bd000	[anon:AddrHashMap]
2025-11-08 13:30:31.480  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a01f7bd000-0x74a0202a3000	
2025-11-08 13:30:31.480  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0202a3000-0x74a0202a4000	
2025-11-08 13:30:31.480  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0202a4000-0x74a0203f6000	[anon:scudo:secondary]
2025-11-08 13:30:31.480  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0203f6000-0x74a0203f8000	
2025-11-08 13:30:31.480  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0203f8000-0x74a020548000	[anon:scudo:secondary]
2025-11-08 13:30:31.480  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a020548000-0x74a020549000	
2025-11-08 13:30:31.480  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a02063f000-0x74a020758000	/data/app/~~EApFJKn0TYks1NB7znMWgA==/com.oearth.androioearth01-kkGgvQ6-x5_Ioed2KatziA==/base.apk
2025-11-08 13:30:31.480  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a020758000-0x74a02075c000	
2025-11-08 13:30:31.480  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a02075c000-0x74a02075d000	[anon:stack_and_tls:5708]
2025-11-08 13:30:31.480  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a02075d000-0x74a020858000	[anon:stack_and_tls:5708]
2025-11-08 13:30:31.481  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a020858000-0x74a02085c000	
2025-11-08 13:30:31.481  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a02085c000-0x74a020a11000	/data/data/com.oearth.androioearth01/code_cache/startup_agents/11c0cda9-agent.so
2025-11-08 13:30:31.481  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a020a11000-0x74a020a14000	
2025-11-08 13:30:31.481  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a020a14000-0x74a020a20000	/data/data/com.oearth.androioearth01/code_cache/startup_agents/11c0cda9-agent.so
2025-11-08 13:30:31.481  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a020a20000-0x74a020a23000	
2025-11-08 13:30:31.481  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a020a23000-0x74a020a5d000	/data/data/com.oearth.androioearth01/code_cache/startup_agents/11c0cda9-agent.so
2025-11-08 13:30:31.481  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a020a5d000-0x74a020a61000	[anon:.bss]
2025-11-08 13:30:31.481  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a020af9000-0x74a020b81000	/dev/ashmem/fontMap (deleted)
2025-11-08 13:30:31.481  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a020b81000-0x74a020c00000	
2025-11-08 13:30:31.481  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a020c00000-0x74a023600000	
2025-11-08 13:30:31.481  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a023606000-0x74a023633000	/apex/com.android.art/lib64/libopenjdkjvmti.so
2025-11-08 13:30:31.481  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a023633000-0x74a023636000	[page size compat]
2025-11-08 13:30:31.481  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a023636000-0x74a0236f6000	/apex/com.android.art/lib64/libopenjdkjvmti.so
2025-11-08 13:30:31.481  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0236f6000-0x74a0236f9000	/apex/com.android.art/lib64/libopenjdkjvmti.so
2025-11-08 13:30:31.481  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0236f9000-0x74a0236fa000	
2025-11-08 13:30:31.481  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0236fa000-0x74a0236fb000	/apex/com.android.art/lib64/libopenjdkjvmti.so
2025-11-08 13:30:31.481  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a023734000-0x74a023738000	
2025-11-08 13:30:31.482  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a023738000-0x74a023739000	[anon:stack_and_tls:5704]
2025-11-08 13:30:31.482  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a023739000-0x74a023834000	[anon:stack_and_tls:5704]
2025-11-08 13:30:31.482  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a023834000-0x74a02383c000	
2025-11-08 13:30:31.482  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a02383c000-0x74a02383d000	[anon:stack_and_tls:5703]
2025-11-08 13:30:31.482  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a02383d000-0x74a023938000	[anon:stack_and_tls:5703]
2025-11-08 13:30:31.482  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a023938000-0x74a023940000	
2025-11-08 13:30:31.482  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a023940000-0x74a023941000	[anon:stack_and_tls:5702]
2025-11-08 13:30:31.482  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a023941000-0x74a023a3c000	[anon:stack_and_tls:5702]
2025-11-08 13:30:31.482  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a023a3c000-0x74a023a44000	
2025-11-08 13:30:31.482  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a023a44000-0x74a023a45000	[anon:stack_and_tls:5701]
2025-11-08 13:30:31.482  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a023a45000-0x74a023b40000	[anon:stack_and_tls:5701]
2025-11-08 13:30:31.482  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a023b40000-0x74a023b44000	
2025-11-08 13:30:31.482  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a023b44000-0x74a023c42000	/dev/binderfs/binder
2025-11-08 13:30:31.482  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a023c42000-0x74a023c46000	
2025-11-08 13:30:31.482  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a023c46000-0x74a023c47000	[anon:stack_and_tls:5700]
2025-11-08 13:30:31.482  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a023c47000-0x74a023d4e000	[anon:stack_and_tls:5700]
2025-11-08 13:30:31.482  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a023d4e000-0x74a023d56000	
2025-11-08 13:30:31.483  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a023d56000-0x74a023d57000	[anon:stack_and_tls:5699]
2025-11-08 13:30:31.483  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a023d57000-0x74a023e5e000	[anon:stack_and_tls:5699]
2025-11-08 13:30:31.483  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a023e5e000-0x74a023e66000	
2025-11-08 13:30:31.483  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a023e66000-0x74a023e67000	[anon:stack_and_tls:5698]
2025-11-08 13:30:31.483  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a023e67000-0x74a023f6e000	[anon:stack_and_tls:5698]
2025-11-08 13:30:31.483  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a023f6e000-0x74a023f76000	
2025-11-08 13:30:31.483  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a023f76000-0x74a023f77000	[anon:stack_and_tls:5697]
2025-11-08 13:30:31.483  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a023f77000-0x74a02407e000	[anon:stack_and_tls:5697]
2025-11-08 13:30:31.483  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a02407e000-0x74a024086000	
2025-11-08 13:30:31.483  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a024086000-0x74a024087000	[anon:stack_and_tls:5696]
2025-11-08 13:30:31.483  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a024087000-0x74a02418a000	[anon:stack_and_tls:5696]
2025-11-08 13:30:31.483  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a02418a000-0x74a02418e000	
2025-11-08 13:30:31.483  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a02418e000-0x74a06418e000	[anon:libwebview reservation]
2025-11-08 13:30:31.483  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06418e000-0x74a06418f000	/system/lib64/libwebviewchromium_loader.so
2025-11-08 13:30:31.483  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06418f000-0x74a064192000	[page size compat]
2025-11-08 13:30:31.483  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a064192000-0x74a064193000	/system/lib64/libwebviewchromium_loader.so
2025-11-08 13:30:31.483  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a064193000-0x74a064196000	[page size compat]
2025-11-08 13:30:31.483  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a064196000-0x74a064197000	/system/lib64/libwebviewchromium_loader.so
2025-11-08 13:30:31.484  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a064197000-0x74a06419a000	
2025-11-08 13:30:31.484  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06419a000-0x74a06419b000	[anon:.bss]
2025-11-08 13:30:31.484  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0641d5000-0x74a0641da000	/system/lib64/libcompiler_rt.so
2025-11-08 13:30:31.484  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0641da000-0x74a0641dd000	[page size compat]
2025-11-08 13:30:31.484  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0641dd000-0x74a0641e5000	/system/lib64/libcompiler_rt.so
2025-11-08 13:30:31.484  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0641e5000-0x74a0641e6000	/system/lib64/libcompiler_rt.so
2025-11-08 13:30:31.484  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a064205000-0x74a0642e6000	/vendor/lib64/libOpenglSystemCommon.so
2025-11-08 13:30:31.484  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0642e6000-0x74a0642e9000	[page size compat]
2025-11-08 13:30:31.484  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0642e9000-0x74a0643e9000	/vendor/lib64/libOpenglSystemCommon.so
2025-11-08 13:30:31.484  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0643e9000-0x74a0643ef000	/vendor/lib64/libOpenglSystemCommon.so
2025-11-08 13:30:31.484  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0643ef000-0x74a0643f1000	
2025-11-08 13:30:31.484  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0643f1000-0x74a0643f2000	/vendor/lib64/libOpenglSystemCommon.so
2025-11-08 13:30:31.484  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a064400000-0x74a066800000	
2025-11-08 13:30:31.484  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066856000-0x74a066861000	/vendor/lib64/android.hardware.graphics.mapper@3.0.so
2025-11-08 13:30:31.484  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066861000-0x74a066862000	[page size compat]
2025-11-08 13:30:31.484  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066862000-0x74a06686c000	/vendor/lib64/android.hardware.graphics.mapper@3.0.so
2025-11-08 13:30:31.484  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06686c000-0x74a06686e000	[page size compat]
2025-11-08 13:30:31.484  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06686e000-0x74a066870000	/vendor/lib64/android.hardware.graphics.mapper@3.0.so
2025-11-08 13:30:31.484  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066870000-0x74a066872000	
2025-11-08 13:30:31.484  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066872000-0x74a066873000	/vendor/lib64/android.hardware.graphics.mapper@3.0.so
2025-11-08 13:30:31.485  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066883000-0x74a066899000	/vendor/lib64/libGLESv1_enc.so
2025-11-08 13:30:31.485  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066899000-0x74a06689b000	[page size compat]
2025-11-08 13:30:31.485  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06689b000-0x74a0668bb000	/vendor/lib64/libGLESv1_enc.so
2025-11-08 13:30:31.485  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0668bb000-0x74a0668bc000	/vendor/lib64/libGLESv1_enc.so
2025-11-08 13:30:31.485  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0668bc000-0x74a0668bf000	
2025-11-08 13:30:31.485  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0668bf000-0x74a0668c0000	[anon:.bss]
2025-11-08 13:30:31.485  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0668c7000-0x74a06694a000	/vendor/lib64/libc++.so
2025-11-08 13:30:31.485  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06694a000-0x74a06694d000	
2025-11-08 13:30:31.485  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06694d000-0x74a0669c2000	/vendor/lib64/libc++.so
2025-11-08 13:30:31.485  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0669c2000-0x74a0669c5000	
2025-11-08 13:30:31.485  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0669c5000-0x74a0669cd000	/vendor/lib64/libc++.so
2025-11-08 13:30:31.485  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0669cd000-0x74a0669d0000	
2025-11-08 13:30:31.485  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0669d0000-0x74a0669d1000	/vendor/lib64/libc++.so
2025-11-08 13:30:31.485  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0669d1000-0x74a0669d8000	[anon:.bss]
2025-11-08 13:30:31.485  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066a15000-0x74a066a53000	/vendor/lib64/libhidlbase.so
2025-11-08 13:30:31.485  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066a53000-0x74a066a55000	[page size compat]
2025-11-08 13:30:31.485  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066a55000-0x74a066aa1000	/vendor/lib64/libhidlbase.so
2025-11-08 13:30:31.485  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066aa1000-0x74a066aac000	/vendor/lib64/libhidlbase.so
2025-11-08 13:30:31.485  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066aac000-0x74a066aad000	
2025-11-08 13:30:31.485  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066aad000-0x74a066aae000	/vendor/lib64/libhidlbase.so
2025-11-08 13:30:31.486  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066ae4000-0x74a066ae5000	/vendor/lib64/android.hardware.graphics.common@1.1.so
2025-11-08 13:30:31.486  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066ae5000-0x74a066ae8000	[page size compat]
2025-11-08 13:30:31.486  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066ae8000-0x74a066ae9000	/vendor/lib64/android.hardware.graphics.common@1.1.so
2025-11-08 13:30:31.486  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066ae9000-0x74a066aec000	[page size compat]
2025-11-08 13:30:31.486  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066aec000-0x74a066aed000	/vendor/lib64/android.hardware.graphics.common@1.1.so
2025-11-08 13:30:31.486  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066b03000-0x74a066b12000	/vendor/lib64/libbase.so
2025-11-08 13:30:31.486  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066b12000-0x74a066b13000	[page size compat]
2025-11-08 13:30:31.486  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066b13000-0x74a066b34000	/vendor/lib64/libbase.so
2025-11-08 13:30:31.486  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066b34000-0x74a066b37000	[page size compat]
2025-11-08 13:30:31.486  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066b37000-0x74a066b38000	/vendor/lib64/libbase.so
2025-11-08 13:30:31.486  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066b38000-0x74a066b3b000	
2025-11-08 13:30:31.486  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066b3b000-0x74a066b3c000	/vendor/lib64/libbase.so
2025-11-08 13:30:31.486  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066b47000-0x74a066b56000	/vendor/lib64/libOpenglCodecCommon.so
2025-11-08 13:30:31.486  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066b56000-0x74a066b57000	[page size compat]
2025-11-08 13:30:31.486  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066b57000-0x74a066b73000	/vendor/lib64/libOpenglCodecCommon.so
2025-11-08 13:30:31.486  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066b73000-0x74a066b74000	/vendor/lib64/libOpenglCodecCommon.so
2025-11-08 13:30:31.486  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066b74000-0x74a066b77000	
2025-11-08 13:30:31.486  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066b77000-0x74a066b78000	[anon:.bss]
2025-11-08 13:30:31.486  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066b92000-0x74a066b9a000	/vendor/lib64/libcutils.so
2025-11-08 13:30:31.486  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066b9a000-0x74a066ba4000	/vendor/lib64/libcutils.so
2025-11-08 13:30:31.487  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066ba4000-0x74a066ba6000	[page size compat]
2025-11-08 13:30:31.487  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066ba6000-0x74a066ba8000	/vendor/lib64/libcutils.so
2025-11-08 13:30:31.487  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066ba8000-0x74a066baa000	
2025-11-08 13:30:31.487  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066baa000-0x74a066bab000	/vendor/lib64/libcutils.so
2025-11-08 13:30:31.487  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066bcf000-0x74a066bd0000	/vendor/lib64/android.hardware.graphics.common@1.2.so
2025-11-08 13:30:31.487  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066bd0000-0x74a066bd3000	[page size compat]
2025-11-08 13:30:31.487  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066bd3000-0x74a066bd4000	/vendor/lib64/android.hardware.graphics.common@1.2.so
2025-11-08 13:30:31.487  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066bd4000-0x74a066bd7000	[page size compat]
2025-11-08 13:30:31.487  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066bd7000-0x74a066bd8000	/vendor/lib64/android.hardware.graphics.common@1.2.so
2025-11-08 13:30:31.487  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066c07000-0x74a066c0f000	/vendor/lib64/libdrm.so
2025-11-08 13:30:31.487  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066c0f000-0x74a066c1c000	/vendor/lib64/libdrm.so
2025-11-08 13:30:31.487  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066c1c000-0x74a066c1f000	[page size compat]
2025-11-08 13:30:31.487  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066c1f000-0x74a066c20000	/vendor/lib64/libdrm.so
2025-11-08 13:30:31.487  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066c20000-0x74a066c23000	
2025-11-08 13:30:31.487  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066c23000-0x74a066c24000	[anon:.bss]
2025-11-08 13:30:31.487  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066c40000-0x74a066c48000	/vendor/lib64/libandroidemu.so
2025-11-08 13:30:31.487  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066c48000-0x74a066c54000	/vendor/lib64/libandroidemu.so
2025-11-08 13:30:31.487  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066c54000-0x74a066c55000	/vendor/lib64/libandroidemu.so
2025-11-08 13:30:31.487  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066c55000-0x74a066c58000	
2025-11-08 13:30:31.487  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066c58000-0x74a066c59000	[anon:.bss]
2025-11-08 13:30:31.487  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066c89000-0x74a066cc3000	/vendor/lib64/libGLESv2_enc.so
2025-11-08 13:30:31.488  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066cc3000-0x74a066cc5000	[page size compat]
2025-11-08 13:30:31.488  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066cc5000-0x74a066d16000	/vendor/lib64/libGLESv2_enc.so
2025-11-08 13:30:31.488  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066d16000-0x74a066d19000	[page size compat]
2025-11-08 13:30:31.488  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066d19000-0x74a066d1b000	/vendor/lib64/libGLESv2_enc.so
2025-11-08 13:30:31.488  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066d1b000-0x74a066d1d000	
2025-11-08 13:30:31.488  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066d1d000-0x74a066d1e000	/vendor/lib64/libGLESv2_enc.so
2025-11-08 13:30:31.488  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066d41000-0x74a066d45000	/vendor/lib64/hw/android.hardware.graphics.mapper@3.0-impl-ranchu.so
2025-11-08 13:30:31.488  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066d45000-0x74a066d48000	/vendor/lib64/hw/android.hardware.graphics.mapper@3.0-impl-ranchu.so
2025-11-08 13:30:31.488  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066d48000-0x74a066d49000	[page size compat]
2025-11-08 13:30:31.488  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066d49000-0x74a066d4a000	/vendor/lib64/hw/android.hardware.graphics.mapper@3.0-impl-ranchu.so
2025-11-08 13:30:31.488  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066d4a000-0x74a066d4d000	
2025-11-08 13:30:31.488  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066d4d000-0x74a066d4e000	[anon:.bss]
2025-11-08 13:30:31.488  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066d99000-0x74a066d9f000	/vendor/lib64/lib_renderControl_enc.so
2025-11-08 13:30:31.488  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066d9f000-0x74a066da1000	[page size compat]
2025-11-08 13:30:31.488  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066da1000-0x74a066dab000	/vendor/lib64/lib_renderControl_enc.so
2025-11-08 13:30:31.488  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066dab000-0x74a066dad000	[page size compat]
2025-11-08 13:30:31.488  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066dad000-0x74a066dae000	/vendor/lib64/lib_renderControl_enc.so
2025-11-08 13:30:31.488  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066dae000-0x74a066db1000	
2025-11-08 13:30:31.488  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066db1000-0x74a066db2000	[anon:.bss]
2025-11-08 13:30:31.489  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066dd0000-0x74a066dd1000	/vendor/lib64/android.hardware.graphics.common@1.0.so
2025-11-08 13:30:31.489  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066dd1000-0x74a066dd4000	[page size compat]
2025-11-08 13:30:31.489  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066dd4000-0x74a066dd5000	/vendor/lib64/android.hardware.graphics.common@1.0.so
2025-11-08 13:30:31.489  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066dd5000-0x74a066dd8000	[page size compat]
2025-11-08 13:30:31.489  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066dd8000-0x74a066dd9000	/vendor/lib64/android.hardware.graphics.common@1.0.so
2025-11-08 13:30:31.489  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066e19000-0x74a066e26000	/vendor/lib64/libutils.so
2025-11-08 13:30:31.489  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066e26000-0x74a066e29000	[page size compat]
2025-11-08 13:30:31.489  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066e29000-0x74a066e38000	/vendor/lib64/libutils.so
2025-11-08 13:30:31.489  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066e38000-0x74a066e39000	[page size compat]
2025-11-08 13:30:31.489  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066e39000-0x74a066e3a000	/vendor/lib64/libutils.so
2025-11-08 13:30:31.489  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066e3a000-0x74a066e3d000	
2025-11-08 13:30:31.489  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066e3d000-0x74a066e3e000	/vendor/lib64/libutils.so
2025-11-08 13:30:31.489  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066e46000-0x74a066e4e000	/system_ext/framework/oat/x86_64/androidx.window.sidecar.odex
2025-11-08 13:30:31.489  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066e4e000-0x74a066e4f000	/system_ext/framework/oat/x86_64/androidx.window.sidecar.vdex
2025-11-08 13:30:31.489  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066e4f000-0x74a066e52000	
2025-11-08 13:30:31.489  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066e52000-0x74a066e53000	/system_ext/framework/oat/x86_64/androidx.window.sidecar.odex
2025-11-08 13:30:31.489  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066e53000-0x74a066e56000	
2025-11-08 13:30:31.489  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066e56000-0x74a066e57000	/system_ext/framework/oat/x86_64/androidx.window.sidecar.odex
2025-11-08 13:30:31.489  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066eaa000-0x74a066eb2000	/system_ext/framework/oat/x86_64/androidx.window.extensions.odex
2025-11-08 13:30:31.489  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066eb2000-0x74a066eb3000	/system_ext/framework/oat/x86_64/androidx.window.extensions.vdex
2025-11-08 13:30:31.490  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066eb3000-0x74a066eb6000	
2025-11-08 13:30:31.490  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066eb6000-0x74a066eb7000	/system_ext/framework/oat/x86_64/androidx.window.extensions.odex
2025-11-08 13:30:31.490  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066eb7000-0x74a066eba000	
2025-11-08 13:30:31.490  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066eba000-0x74a066ebb000	/system_ext/framework/oat/x86_64/androidx.window.extensions.odex
2025-11-08 13:30:31.490  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066ec3000-0x74a066ed7000	/system/framework/oat/x86_64/org.apache.http.legacy.odex
2025-11-08 13:30:31.490  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066ed7000-0x74a066f0f000	/system/framework/oat/x86_64/org.apache.http.legacy.odex
2025-11-08 13:30:31.490  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066f0f000-0x74a066f10000	/system/framework/oat/x86_64/org.apache.http.legacy.odex
2025-11-08 13:30:31.490  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066f10000-0x74a066f13000	
2025-11-08 13:30:31.490  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066f13000-0x74a066f15000	[anon:.bss]
2025-11-08 13:30:31.490  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066f15000-0x74a066f17000	
2025-11-08 13:30:31.490  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066f17000-0x74a066f1a000	/system/framework/oat/x86_64/org.apache.http.legacy.vdex
2025-11-08 13:30:31.490  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066f1a000-0x74a066f1b000	
2025-11-08 13:30:31.490  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066f1b000-0x74a066f1c000	/system/framework/oat/x86_64/org.apache.http.legacy.odex
2025-11-08 13:30:31.490  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066f1c000-0x74a066f1f000	
2025-11-08 13:30:31.490  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066f1f000-0x74a066f20000	/system/framework/oat/x86_64/org.apache.http.legacy.odex
2025-11-08 13:30:31.490  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066f60000-0x74a066f68000	/system/framework/oat/x86_64/android.test.base.odex
2025-11-08 13:30:31.490  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066f68000-0x74a066f69000	/system/framework/oat/x86_64/android.test.base.vdex
2025-11-08 13:30:31.490  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066f69000-0x74a066f6c000	
2025-11-08 13:30:31.490  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066f6c000-0x74a066f6d000	/system/framework/oat/x86_64/android.test.base.odex
2025-11-08 13:30:31.491  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066f6d000-0x74a066f70000	
2025-11-08 13:30:31.491  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066f70000-0x74a066f71000	/system/framework/oat/x86_64/android.test.base.odex
2025-11-08 13:30:31.491  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066f8b000-0x74a066f93000	/system/framework/oat/x86_64/android.hidl.manager-V1.0-java.odex
2025-11-08 13:30:31.491  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066f93000-0x74a066f94000	/system/framework/oat/x86_64/android.hidl.manager-V1.0-java.vdex
2025-11-08 13:30:31.491  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066f94000-0x74a066f97000	
2025-11-08 13:30:31.491  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066f97000-0x74a066f98000	/system/framework/oat/x86_64/android.hidl.manager-V1.0-java.odex
2025-11-08 13:30:31.491  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066f98000-0x74a066f9b000	
2025-11-08 13:30:31.491  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066f9b000-0x74a066f9c000	/system/framework/oat/x86_64/android.hidl.manager-V1.0-java.odex
2025-11-08 13:30:31.491  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066fc4000-0x74a066fcc000	/system/framework/oat/x86_64/android.hidl.base-V1.0-java.odex
2025-11-08 13:30:31.491  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066fcc000-0x74a066fcd000	/system/framework/oat/x86_64/android.hidl.base-V1.0-java.vdex
2025-11-08 13:30:31.491  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066fcd000-0x74a066fd0000	
2025-11-08 13:30:31.491  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066fd0000-0x74a066fd1000	/system/framework/oat/x86_64/android.hidl.base-V1.0-java.odex
2025-11-08 13:30:31.491  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066fd1000-0x74a066fd4000	
2025-11-08 13:30:31.491  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a066fd4000-0x74a066fd5000	/system/framework/oat/x86_64/android.hidl.base-V1.0-java.odex
2025-11-08 13:30:31.491  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06702f000-0x74a067031000	/apex/com.android.tethering/lib64/libframework-connectivity-jni.so
2025-11-08 13:30:31.491  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a067031000-0x74a067033000	[page size compat]
2025-11-08 13:30:31.491  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a067033000-0x74a067035000	/apex/com.android.tethering/lib64/libframework-connectivity-jni.so
2025-11-08 13:30:31.491  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a067035000-0x74a067037000	[page size compat]
2025-11-08 13:30:31.491  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a067037000-0x74a067038000	/apex/com.android.tethering/lib64/libframework-connectivity-jni.so
2025-11-08 13:30:31.491  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a067038000-0x74a06703b000	
2025-11-08 13:30:31.492  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06703b000-0x74a06703c000	/apex/com.android.tethering/lib64/libframework-connectivity-jni.so
2025-11-08 13:30:31.492  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a067060000-0x74a0680d1000	/system/framework/framework-res.apk
2025-11-08 13:30:31.492  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0680d1000-0x74a06819b000	/system/framework/framework-res.apk
2025-11-08 13:30:31.492  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06819b000-0x74a0681a2000	/system/lib64/librs_jni.so
2025-11-08 13:30:31.492  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0681a2000-0x74a0681a3000	[page size compat]
2025-11-08 13:30:31.492  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0681a3000-0x74a0681ae000	/system/lib64/librs_jni.so
2025-11-08 13:30:31.492  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0681ae000-0x74a0681af000	[page size compat]
2025-11-08 13:30:31.492  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0681af000-0x74a0681b1000	/system/lib64/librs_jni.so
2025-11-08 13:30:31.492  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0681b1000-0x74a0681b3000	
2025-11-08 13:30:31.492  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0681b3000-0x74a0681b4000	[anon:.bss]
2025-11-08 13:30:31.492  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0681c4000-0x74a0681c8000	/system/lib64/libvintf_jni.so
2025-11-08 13:30:31.492  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0681c8000-0x74a0681cd000	/system/lib64/libvintf_jni.so
2025-11-08 13:30:31.492  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0681cd000-0x74a0681d0000	[page size compat]
2025-11-08 13:30:31.492  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0681d0000-0x74a0681d1000	/system/lib64/libvintf_jni.so
2025-11-08 13:30:31.492  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0681d1000-0x74a0681d4000	
2025-11-08 13:30:31.492  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0681d4000-0x74a0681d5000	[anon:.bss]
2025-11-08 13:30:31.492  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068201000-0x74a068227000	/system/lib64/libvintf.so
2025-11-08 13:30:31.492  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068227000-0x74a068229000	[page size compat]
2025-11-08 13:30:31.492  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068229000-0x74a068295000	/system/lib64/libvintf.so
2025-11-08 13:30:31.492  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068295000-0x74a068298000	/system/lib64/libvintf.so
2025-11-08 13:30:31.493  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068298000-0x74a068299000	
2025-11-08 13:30:31.493  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068299000-0x74a06829a000	[anon:.bss]
2025-11-08 13:30:31.493  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0682e1000-0x74a0682ec000	/system/lib64/libstagefright_amrnb_common.so
2025-11-08 13:30:31.493  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0682ec000-0x74a0682ed000	[page size compat]
2025-11-08 13:30:31.493  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0682ed000-0x74a0682f6000	/system/lib64/libstagefright_amrnb_common.so
2025-11-08 13:30:31.493  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0682f6000-0x74a0682f9000	[page size compat]
2025-11-08 13:30:31.493  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0682f9000-0x74a0682fa000	/system/lib64/libstagefright_amrnb_common.so
2025-11-08 13:30:31.493  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068303000-0x74a068311000	/system/lib64/librtp_jni.so
2025-11-08 13:30:31.493  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068311000-0x74a068313000	[page size compat]
2025-11-08 13:30:31.493  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068313000-0x74a06833d000	/system/lib64/librtp_jni.so
2025-11-08 13:30:31.493  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06833d000-0x74a06833f000	[page size compat]
2025-11-08 13:30:31.493  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06833f000-0x74a068341000	/system/lib64/librtp_jni.so
2025-11-08 13:30:31.493  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068341000-0x74a068343000	
2025-11-08 13:30:31.493  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068343000-0x74a068344000	/system/lib64/librtp_jni.so
2025-11-08 13:30:31.493  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068398000-0x74a06839e000	/system/lib64/libaudioeffect_jni.so
2025-11-08 13:30:31.493  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06839e000-0x74a0683a0000	[page size compat]
2025-11-08 13:30:31.493  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0683a0000-0x74a0683a8000	/system/lib64/libaudioeffect_jni.so
2025-11-08 13:30:31.493  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0683a8000-0x74a0683a9000	/system/lib64/libaudioeffect_jni.so
2025-11-08 13:30:31.493  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0683a9000-0x74a0683ac000	
2025-11-08 13:30:31.493  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0683ac000-0x74a0683ad000	[anon:.bss]
2025-11-08 13:30:31.494  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0683d8000-0x74a0683e1000	/system/lib64/libsoundpool.so
2025-11-08 13:30:31.494  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0683e1000-0x74a0683e4000	[page size compat]
2025-11-08 13:30:31.494  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0683e4000-0x74a0683f0000	/system/lib64/libsoundpool.so
2025-11-08 13:30:31.494  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0683f0000-0x74a0683f1000	/system/lib64/libsoundpool.so
2025-11-08 13:30:31.494  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0683f1000-0x74a0683f4000	
2025-11-08 13:30:31.494  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0683f4000-0x74a0683f5000	/system/lib64/libsoundpool.so
2025-11-08 13:30:31.494  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06842e000-0x74a0684f8000	/system/lib64/libprotobuf-cpp-full.so
2025-11-08 13:30:31.494  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0684f8000-0x74a0684fa000	[page size compat]
2025-11-08 13:30:31.494  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0684fa000-0x74a06864d000	/system/lib64/libprotobuf-cpp-full.so
2025-11-08 13:30:31.494  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06864d000-0x74a06864e000	[page size compat]
2025-11-08 13:30:31.494  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06864e000-0x74a068657000	/system/lib64/libprotobuf-cpp-full.so
2025-11-08 13:30:31.494  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068657000-0x74a06865a000	
2025-11-08 13:30:31.494  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06865a000-0x74a06865c000	/system/lib64/libprotobuf-cpp-full.so
2025-11-08 13:30:31.494  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068661000-0x74a0686d6000	
2025-11-08 13:30:31.494  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0686d6000-0x74a068711000	/system/lib64/libmedia_jni.so
2025-11-08 13:30:31.494  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068711000-0x74a068712000	[page size compat]
2025-11-08 13:30:31.494  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068712000-0x74a068768000	/system/lib64/libmedia_jni.so
2025-11-08 13:30:31.494  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068768000-0x74a06876a000	[page size compat]
2025-11-08 13:30:31.495  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06876a000-0x74a068771000	/system/lib64/libmedia_jni.so
2025-11-08 13:30:31.495  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068771000-0x74a068772000	
2025-11-08 13:30:31.495  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068772000-0x74a068773000	/system/lib64/libmedia_jni.so
2025-11-08 13:30:31.495  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06878c000-0x74a06878d000	/system/lib64/libasyncio.so
2025-11-08 13:30:31.495  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06878d000-0x74a068790000	[page size compat]
2025-11-08 13:30:31.495  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068790000-0x74a068791000	/system/lib64/libasyncio.so
2025-11-08 13:30:31.495  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068791000-0x74a068794000	[page size compat]
2025-11-08 13:30:31.495  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068794000-0x74a068795000	/system/lib64/libasyncio.so
2025-11-08 13:30:31.495  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0687ce000-0x74a0687d9000	/system/lib64/libmediadrmmetrics_full.so
2025-11-08 13:30:31.495  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0687d9000-0x74a0687da000	[page size compat]
2025-11-08 13:30:31.495  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0687da000-0x74a0687e7000	/system/lib64/libmediadrmmetrics_full.so
2025-11-08 13:30:31.495  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0687e7000-0x74a0687ea000	[page size compat]
2025-11-08 13:30:31.495  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0687ea000-0x74a0687ec000	/system/lib64/libmediadrmmetrics_full.so
2025-11-08 13:30:31.495  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0687ec000-0x74a0687ee000	
2025-11-08 13:30:31.495  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0687ee000-0x74a0687ef000	/system/lib64/libmediadrmmetrics_full.so
2025-11-08 13:30:31.495  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068800000-0x74a068a00000	
2025-11-08 13:30:31.495  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068a50000-0x74a068a52000	/system/lib64/libmediadrmmetrics_consumer.so
2025-11-08 13:30:31.495  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068a52000-0x74a068a54000	[page size compat]
2025-11-08 13:30:31.495  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068a54000-0x74a068a57000	/system/lib64/libmediadrmmetrics_consumer.so
2025-11-08 13:30:31.496  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068a57000-0x74a068a58000	[page size compat]
2025-11-08 13:30:31.496  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068a58000-0x74a068a59000	/system/lib64/libmediadrmmetrics_consumer.so
2025-11-08 13:30:31.496  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068aad000-0x74a068ac2000	/system/lib64/libmtp.so
2025-11-08 13:30:31.496  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068ac2000-0x74a068ac5000	[page size compat]
2025-11-08 13:30:31.496  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068ac5000-0x74a068ae9000	/system/lib64/libmtp.so
2025-11-08 13:30:31.496  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068ae9000-0x74a068aec000	/system/lib64/libmtp.so
2025-11-08 13:30:31.496  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068aec000-0x74a068aed000	
2025-11-08 13:30:31.496  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068aed000-0x74a068aee000	[anon:.bss]
2025-11-08 13:30:31.496  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068b08000-0x74a068b7f000	/system/lib64/libsonivox.so
2025-11-08 13:30:31.496  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068b7f000-0x74a068b80000	[page size compat]
2025-11-08 13:30:31.496  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068b80000-0x74a068b97000	/system/lib64/libsonivox.so
2025-11-08 13:30:31.496  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068b97000-0x74a068b98000	[page size compat]
2025-11-08 13:30:31.496  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068b98000-0x74a068b99000	/system/lib64/libsonivox.so
2025-11-08 13:30:31.496  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068b99000-0x74a068b9c000	
2025-11-08 13:30:31.496  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068b9c000-0x74a068b9d000	/system/lib64/libsonivox.so
2025-11-08 13:30:31.496  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068b9d000-0x74a068ba4000	[anon:.bss]
2025-11-08 13:30:31.496  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068bd6000-0x74a068e1a000	/system/fonts/Roboto-Regular.ttf
2025-11-08 13:30:31.496  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068e1a000-0x74a068e86000	/apex/com.android.conscrypt/lib64/libcrypto.so
2025-11-08 13:30:31.496  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068e86000-0x74a068f99000	/apex/com.android.conscrypt/lib64/libcrypto.so
2025-11-08 13:30:31.496  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068f99000-0x74a068f9a000	[page size compat]
2025-11-08 13:30:31.497  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068f9a000-0x74a068fa9000	/apex/com.android.conscrypt/lib64/libcrypto.so
2025-11-08 13:30:31.497  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068fa9000-0x74a068faa000	
2025-11-08 13:30:31.497  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068faa000-0x74a068fab000	/apex/com.android.conscrypt/lib64/libcrypto.so
2025-11-08 13:30:31.497  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a068fab000-0x74a068fb3000	[anon:.bss]
2025-11-08 13:30:31.497  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a069000000-0x74a06c200000	
2025-11-08 13:30:31.497  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06c254000-0x74a06c281000	/system/lib64/android.hardware.tv.tuner-V2-ndk.so
2025-11-08 13:30:31.497  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06c281000-0x74a06c284000	[page size compat]
2025-11-08 13:30:31.497  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06c284000-0x74a06c2b8000	/system/lib64/android.hardware.tv.tuner-V2-ndk.so
2025-11-08 13:30:31.497  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06c2b8000-0x74a06c2bc000	/system/lib64/android.hardware.tv.tuner-V2-ndk.so
2025-11-08 13:30:31.497  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06c2bc000-0x74a06c2bd000	/system/lib64/android.hardware.tv.tuner-V2-ndk.so
2025-11-08 13:30:31.497  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06c2c0000-0x74a06c343000	/apex/com.android.conscrypt/lib64/libc++.so
2025-11-08 13:30:31.497  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06c343000-0x74a06c346000	
2025-11-08 13:30:31.497  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06c346000-0x74a06c3bb000	/apex/com.android.conscrypt/lib64/libc++.so
2025-11-08 13:30:31.497  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06c3bb000-0x74a06c3be000	
2025-11-08 13:30:31.497  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06c3be000-0x74a06c3c6000	/apex/com.android.conscrypt/lib64/libc++.so
2025-11-08 13:30:31.497  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06c3c6000-0x74a06c3c9000	
2025-11-08 13:30:31.497  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06c3c9000-0x74a06c3ca000	/apex/com.android.conscrypt/lib64/libc++.so
2025-11-08 13:30:31.497  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06c3ca000-0x74a06c3d1000	[anon:.bss]
2025-11-08 13:30:31.497  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06c400000-0x74a06deaa000	/apex/com.android.i18n/etc/icu/icudt75l.dat
2025-11-08 13:30:31.497  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06df09000-0x74a06df30000	/apex/com.android.conscrypt/lib64/libssl.so
2025-11-08 13:30:31.498  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06df30000-0x74a06df31000	[page size compat]
2025-11-08 13:30:31.498  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06df31000-0x74a06df78000	/apex/com.android.conscrypt/lib64/libssl.so
2025-11-08 13:30:31.498  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06df78000-0x74a06df79000	[page size compat]
2025-11-08 13:30:31.498  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06df79000-0x74a06df7d000	/apex/com.android.conscrypt/lib64/libssl.so
2025-11-08 13:30:31.498  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06df7d000-0x74a06df7e000	/apex/com.android.conscrypt/lib64/libssl.so
2025-11-08 13:30:31.498  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06df81000-0x74a06df96000	/apex/com.android.conscrypt/lib64/libjavacrypto.so
2025-11-08 13:30:31.498  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06df96000-0x74a06df99000	[page size compat]
2025-11-08 13:30:31.498  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06df99000-0x74a06dfb4000	/apex/com.android.conscrypt/lib64/libjavacrypto.so
2025-11-08 13:30:31.498  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06dfb4000-0x74a06dfb5000	[page size compat]
2025-11-08 13:30:31.498  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06dfb5000-0x74a06dfb7000	/apex/com.android.conscrypt/lib64/libjavacrypto.so
2025-11-08 13:30:31.498  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06dfb7000-0x74a06dfb9000	
2025-11-08 13:30:31.498  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06dfb9000-0x74a06dfbb000	/apex/com.android.conscrypt/lib64/libjavacrypto.so
2025-11-08 13:30:31.498  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06dfeb000-0x74a06dfec000	/apex/com.android.os.statsd/lib64/libstats_jni.so
2025-11-08 13:30:31.498  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06dfec000-0x74a06dfef000	[page size compat]
2025-11-08 13:30:31.498  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06dfef000-0x74a06dff0000	/apex/com.android.os.statsd/lib64/libstats_jni.so
2025-11-08 13:30:31.498  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06dff0000-0x74a06dff3000	[page size compat]
2025-11-08 13:30:31.498  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06dff3000-0x74a06dff4000	/apex/com.android.os.statsd/lib64/libstats_jni.so
2025-11-08 13:30:31.498  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06e05c000-0x74a06e05d000	/apex/com.android.tethering/lib64/libframework-connectivity-tiramisu-jni.so
2025-11-08 13:30:31.498  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06e05d000-0x74a06e060000	[page size compat]
2025-11-08 13:30:31.498  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06e060000-0x74a06e061000	/apex/com.android.tethering/lib64/libframework-connectivity-tiramisu-jni.so
2025-11-08 13:30:31.499  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06e061000-0x74a06e064000	[page size compat]
2025-11-08 13:30:31.499  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06e064000-0x74a06e065000	/apex/com.android.tethering/lib64/libframework-connectivity-tiramisu-jni.so
2025-11-08 13:30:31.499  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06e09b000-0x74a06e09f000	
2025-11-08 13:30:31.499  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06e09f000-0x74a06e0a0000	[anon:stack_and_tls:5695]
2025-11-08 13:30:31.499  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06e0a0000-0x74a06e19b000	[anon:stack_and_tls:5695]
2025-11-08 13:30:31.499  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06e19b000-0x74a06e1a3000	
2025-11-08 13:30:31.499  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06e1a3000-0x74a06e1a4000	[anon:stack_and_tls:5694]
2025-11-08 13:30:31.499  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06e1a4000-0x74a06e29f000	[anon:stack_and_tls:5694]
2025-11-08 13:30:31.499  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06e29f000-0x74a06e2a7000	
2025-11-08 13:30:31.499  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06e2a7000-0x74a06e2a8000	[anon:stack_and_tls:5693]
2025-11-08 13:30:31.499  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06e2a8000-0x74a06e3a3000	[anon:stack_and_tls:5693]
2025-11-08 13:30:31.499  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06e3a3000-0x74a06e3a7000	
2025-11-08 13:30:31.499  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06e3a7000-0x74a06e48f000	[anon:dalvik-allocspace non moving space mark-bitmap 1]
2025-11-08 13:30:31.499  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06e48f000-0x74a06e577000	[anon:dalvik-allocspace non moving space live-bitmap 1]
2025-11-08 13:30:31.499  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a06e577000-0x74a072577000	/memfd:jit-cache (deleted)
2025-11-08 13:30:31.499  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a072577000-0x74a07257b000	/apex/com.android.art/lib64/libopenjdkjvm.so
2025-11-08 13:30:31.499  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07257b000-0x74a07257e000	/apex/com.android.art/lib64/libopenjdkjvm.so
2025-11-08 13:30:31.499  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07257e000-0x74a07257f000	[page size compat]
2025-11-08 13:30:31.499  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07257f000-0x74a072580000	/apex/com.android.art/lib64/libopenjdkjvm.so
2025-11-08 13:30:31.499  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0725ba000-0x74a0725d5000	/apex/com.android.art/lib64/libopenjdk.so
2025-11-08 13:30:31.499  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0725d5000-0x74a0725d6000	[page size compat]
2025-11-08 13:30:31.499  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0725d6000-0x74a0725f3000	/apex/com.android.art/lib64/libopenjdk.so
2025-11-08 13:30:31.500  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0725f3000-0x74a0725f6000	[page size compat]
2025-11-08 13:30:31.500  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0725f6000-0x74a0725f7000	/apex/com.android.art/lib64/libopenjdk.so
2025-11-08 13:30:31.500  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0725f7000-0x74a0725fa000	
2025-11-08 13:30:31.500  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0725fa000-0x74a0725fc000	/apex/com.android.art/lib64/libopenjdk.so
2025-11-08 13:30:31.500  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a072600000-0x74a0740aa000	/apex/com.android.i18n/etc/icu/icudt75l.dat
2025-11-08 13:30:31.500  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0740ae000-0x74a074126000	/system/framework/org.apache.http.legacy.jar
2025-11-08 13:30:31.500  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a074126000-0x74a07413b000	/apex/com.android.art/lib64/libjavacore.so
2025-11-08 13:30:31.500  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07413b000-0x74a07413e000	[page size compat]
2025-11-08 13:30:31.500  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07413e000-0x74a07416c000	/apex/com.android.art/lib64/libjavacore.so
2025-11-08 13:30:31.500  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07416c000-0x74a07416e000	[page size compat]
2025-11-08 13:30:31.500  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07416e000-0x74a07416f000	/apex/com.android.art/lib64/libjavacore.so
2025-11-08 13:30:31.500  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07416f000-0x74a074172000	
2025-11-08 13:30:31.500  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a074172000-0x74a074174000	/apex/com.android.art/lib64/libjavacore.so
2025-11-08 13:30:31.500  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0741ad000-0x74a0741ae000	/apex/com.android.art/lib64/libandroidio.so
2025-11-08 13:30:31.500  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0741ae000-0x74a0741b1000	[page size compat]
2025-11-08 13:30:31.500  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0741b1000-0x74a0741b2000	/apex/com.android.art/lib64/libandroidio.so
2025-11-08 13:30:31.500  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0741b2000-0x74a0741b5000	[page size compat]
2025-11-08 13:30:31.500  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0741b5000-0x74a0741b6000	/apex/com.android.art/lib64/libandroidio.so
2025-11-08 13:30:31.500  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0741b6000-0x74a0741b9000	
2025-11-08 13:30:31.500  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0741b9000-0x74a0741ba000	[anon:.bss]
2025-11-08 13:30:31.500  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0741c5000-0x74a0741d0000	/apex/com.android.art/lib64/libexpat.so
2025-11-08 13:30:31.500  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0741d0000-0x74a0741d1000	[page size compat]
2025-11-08 13:30:31.501  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0741d1000-0x74a0741ef000	/apex/com.android.art/lib64/libexpat.so
2025-11-08 13:30:31.501  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0741ef000-0x74a0741f1000	[page size compat]
2025-11-08 13:30:31.501  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0741f1000-0x74a0741f3000	/apex/com.android.art/lib64/libexpat.so
2025-11-08 13:30:31.501  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a074201000-0x74a074208000	/apex/com.android.i18n/lib64/libicu_jni.so
2025-11-08 13:30:31.501  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a074208000-0x74a074209000	[page size compat]
2025-11-08 13:30:31.501  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a074209000-0x74a074214000	/apex/com.android.i18n/lib64/libicu_jni.so
2025-11-08 13:30:31.501  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a074214000-0x74a074215000	[page size compat]
2025-11-08 13:30:31.501  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a074215000-0x74a074216000	/apex/com.android.i18n/lib64/libicu_jni.so
2025-11-08 13:30:31.501  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a074216000-0x74a074219000	
2025-11-08 13:30:31.501  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a074219000-0x74a07421a000	/apex/com.android.i18n/lib64/libicu_jni.so
2025-11-08 13:30:31.501  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a074254000-0x74a074256000	/system/lib64/libwebviewchromium_plat_support.so
2025-11-08 13:30:31.501  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a074256000-0x74a074258000	[page size compat]
2025-11-08 13:30:31.501  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a074258000-0x74a07425a000	/system/lib64/libwebviewchromium_plat_support.so
2025-11-08 13:30:31.501  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07425a000-0x74a07425c000	[page size compat]
2025-11-08 13:30:31.501  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07425c000-0x74a07425d000	/system/lib64/libwebviewchromium_plat_support.so
2025-11-08 13:30:31.501  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07425d000-0x74a074260000	
2025-11-08 13:30:31.501  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a074260000-0x74a074261000	/system/lib64/libwebviewchromium_plat_support.so
2025-11-08 13:30:31.501  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a074288000-0x74a0742a7000	/system/lib64/android.hardware.renderscript@1.0.so
2025-11-08 13:30:31.501  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0742a7000-0x74a0742a8000	[page size compat]
2025-11-08 13:30:31.501  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0742a8000-0x74a0742d6000	/system/lib64/android.hardware.renderscript@1.0.so
2025-11-08 13:30:31.501  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0742d6000-0x74a0742d8000	[page size compat]
2025-11-08 13:30:31.502  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0742d8000-0x74a0742dc000	/system/lib64/android.hardware.renderscript@1.0.so
2025-11-08 13:30:31.502  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0742dc000-0x74a0742dd000	/system/lib64/android.hardware.renderscript@1.0.so
2025-11-08 13:30:31.502  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07434e000-0x74a074350000	/system/lib64/libstdc++.so
2025-11-08 13:30:31.502  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a074350000-0x74a074352000	[page size compat]
2025-11-08 13:30:31.502  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a074352000-0x74a074354000	/system/lib64/libstdc++.so
2025-11-08 13:30:31.502  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a074354000-0x74a074356000	[page size compat]
2025-11-08 13:30:31.502  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a074356000-0x74a074357000	/system/lib64/libstdc++.so
2025-11-08 13:30:31.502  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0743ae000-0x74a0743b1000	/system/lib64/libutilscallstack.so
2025-11-08 13:30:31.502  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0743b1000-0x74a0743b2000	[page size compat]
2025-11-08 13:30:31.502  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0743b2000-0x74a0743b5000	/system/lib64/libutilscallstack.so
2025-11-08 13:30:31.502  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0743b5000-0x74a0743b6000	[page size compat]
2025-11-08 13:30:31.502  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0743b6000-0x74a0743b7000	/system/lib64/libutilscallstack.so
2025-11-08 13:30:31.502  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0743c8000-0x74a0743cf000	/system/lib64/libRS.so
2025-11-08 13:30:31.502  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0743cf000-0x74a0743d0000	[page size compat]
2025-11-08 13:30:31.502  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0743d0000-0x74a0743d9000	/system/lib64/libRS.so
2025-11-08 13:30:31.502  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0743d9000-0x74a0743dc000	[page size compat]
2025-11-08 13:30:31.502  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0743dc000-0x74a0743dd000	/system/lib64/libRS.so
2025-11-08 13:30:31.502  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0743dd000-0x74a0743e0000	
2025-11-08 13:30:31.502  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0743e0000-0x74a0743e1000	[anon:.bss]
2025-11-08 13:30:31.502  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a074400000-0x74a077600000	
2025-11-08 13:30:31.502  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a077657000-0x74a077659000	/system/lib64/libOpenSLES.so
2025-11-08 13:30:31.503  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a077659000-0x74a07765b000	[page size compat]
2025-11-08 13:30:31.503  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07765b000-0x74a07765c000	/system/lib64/libOpenSLES.so
2025-11-08 13:30:31.503  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07765c000-0x74a07765f000	[page size compat]
2025-11-08 13:30:31.503  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07765f000-0x74a077660000	/system/lib64/libOpenSLES.so
2025-11-08 13:30:31.503  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a077689000-0x74a07768b000	/system/lib64/libOpenMAXAL.so
2025-11-08 13:30:31.503  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07768b000-0x74a07768d000	[page size compat]
2025-11-08 13:30:31.503  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07768d000-0x74a07768e000	/system/lib64/libOpenMAXAL.so
2025-11-08 13:30:31.503  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07768e000-0x74a077691000	[page size compat]
2025-11-08 13:30:31.503  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a077691000-0x74a077692000	/system/lib64/libOpenMAXAL.so
2025-11-08 13:30:31.503  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0776f5000-0x74a0776f8000	/system/lib64/libjnigraphics.so
2025-11-08 13:30:31.503  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0776f8000-0x74a0776f9000	[page size compat]
2025-11-08 13:30:31.503  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0776f9000-0x74a0776fb000	/system/lib64/libjnigraphics.so
2025-11-08 13:30:31.503  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0776fb000-0x74a0776fd000	[page size compat]
2025-11-08 13:30:31.503  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0776fd000-0x74a0776fe000	/system/lib64/libjnigraphics.so
2025-11-08 13:30:31.503  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07772f000-0x74a077740000	/system/lib64/libcamera2ndk.so
2025-11-08 13:30:31.503  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a077740000-0x74a077743000	[page size compat]
2025-11-08 13:30:31.503  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a077743000-0x74a077776000	/system/lib64/libcamera2ndk.so
2025-11-08 13:30:31.503  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a077776000-0x74a077777000	[page size compat]
2025-11-08 13:30:31.503  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a077777000-0x74a07777a000	/system/lib64/libcamera2ndk.so
2025-11-08 13:30:31.503  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07777a000-0x74a07777b000	
2025-11-08 13:30:31.503  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07777b000-0x74a07777c000	/system/lib64/libcamera2ndk.so
2025-11-08 13:30:31.504  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0777a2000-0x74a0777a3000	/system/lib64/android.companion.virtualdevice.flags-aconfig-cc.so
2025-11-08 13:30:31.504  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0777a3000-0x74a0777a6000	[page size compat]
2025-11-08 13:30:31.504  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0777a6000-0x74a0777a7000	/system/lib64/android.companion.virtualdevice.flags-aconfig-cc.so
2025-11-08 13:30:31.504  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0777a7000-0x74a0777aa000	[page size compat]
2025-11-08 13:30:31.504  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0777aa000-0x74a0777ab000	/system/lib64/android.companion.virtualdevice.flags-aconfig-cc.so
2025-11-08 13:30:31.504  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0777ab000-0x74a0777ae000	
2025-11-08 13:30:31.504  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0777ae000-0x74a0777af000	[anon:.bss]
2025-11-08 13:30:31.504  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0777d8000-0x74a0777dc000	/system/lib64/libamidi.so
2025-11-08 13:30:31.504  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0777dc000-0x74a0777e0000	/system/lib64/libamidi.so
2025-11-08 13:30:31.504  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0777e0000-0x74a0777e1000	/system/lib64/libamidi.so
2025-11-08 13:30:31.504  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0777e1000-0x74a0777e4000	
2025-11-08 13:30:31.504  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0777e4000-0x74a0777e5000	/system/lib64/libamidi.so
2025-11-08 13:30:31.504  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a077809000-0x74a07780a000	/system/lib64/com.android.media.aaudio-aconfig-cc.so
2025-11-08 13:30:31.504  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07780a000-0x74a07780d000	[page size compat]
2025-11-08 13:30:31.504  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07780d000-0x74a07780f000	/system/lib64/com.android.media.aaudio-aconfig-cc.so
2025-11-08 13:30:31.504  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07780f000-0x74a077811000	[page size compat]
2025-11-08 13:30:31.504  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a077811000-0x74a077812000	/system/lib64/com.android.media.aaudio-aconfig-cc.so
2025-11-08 13:30:31.504  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a077812000-0x74a077815000	
2025-11-08 13:30:31.505  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a077815000-0x74a077816000	[anon:.bss]
2025-11-08 13:30:31.505  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a077861000-0x74a077865000	/system/lib64/libaaudio.so
2025-11-08 13:30:31.505  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a077865000-0x74a077869000	/system/lib64/libaaudio.so
2025-11-08 13:30:31.505  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a077869000-0x74a07786a000	/system/lib64/libaaudio.so
2025-11-08 13:30:31.505  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a077893000-0x74a0778b7000	/system/lib64/libaaudio_internal.so
2025-11-08 13:30:31.505  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0778b7000-0x74a0778f1000	/system/lib64/libaaudio_internal.so
2025-11-08 13:30:31.505  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0778f1000-0x74a0778f3000	[page size compat]
2025-11-08 13:30:31.505  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0778f3000-0x74a0778fa000	/system/lib64/libaaudio_internal.so
2025-11-08 13:30:31.505  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0778fa000-0x74a0778fb000	
2025-11-08 13:30:31.505  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0778fb000-0x74a0778fc000	/system/lib64/libaaudio_internal.so
2025-11-08 13:30:31.505  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a077915000-0x74a07791c000	/system/lib64/aaudio-aidl-cpp.so
2025-11-08 13:30:31.505  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07791c000-0x74a07791d000	[page size compat]
2025-11-08 13:30:31.505  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07791d000-0x74a077926000	/system/lib64/aaudio-aidl-cpp.so
2025-11-08 13:30:31.505  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a077926000-0x74a077929000	[page size compat]
2025-11-08 13:30:31.505  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a077929000-0x74a07792c000	/system/lib64/aaudio-aidl-cpp.so
2025-11-08 13:30:31.505  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07792c000-0x74a07792d000	
2025-11-08 13:30:31.505  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07792d000-0x74a07792e000	/system/lib64/aaudio-aidl-cpp.so
2025-11-08 13:30:31.505  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07795f000-0x74a07797b000	/apex/com.android.art/lib64/libperfetto_hprof.so
2025-11-08 13:30:31.505  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07797b000-0x74a0779d3000	/apex/com.android.art/lib64/libperfetto_hprof.so
2025-11-08 13:30:31.505  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0779d3000-0x74a0779d7000	/apex/com.android.art/lib64/libperfetto_hprof.so
2025-11-08 13:30:31.506  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0779d7000-0x74a0779d8000	/apex/com.android.art/lib64/libperfetto_hprof.so
2025-11-08 13:30:31.506  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0779d8000-0x74a0779d9000	[anon:.bss]
2025-11-08 13:30:31.506  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a077a00000-0x74a07a400000	
2025-11-08 13:30:31.506  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07a467000-0x74a07a552000	/system/lib64/libndk_translation.so
2025-11-08 13:30:31.506  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07a552000-0x74a07a553000	[page size compat]
2025-11-08 13:30:31.506  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07a553000-0x74a07a756000	/system/lib64/libndk_translation.so
2025-11-08 13:30:31.506  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07a756000-0x74a07a757000	[page size compat]
2025-11-08 13:30:31.506  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07a757000-0x74a07a7c0000	/system/lib64/libndk_translation.so
2025-11-08 13:30:31.506  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07a7c0000-0x74a07a7c3000	
2025-11-08 13:30:31.506  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07a7c3000-0x74a07a7c4000	/system/lib64/libndk_translation.so
2025-11-08 13:30:31.506  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07a7c4000-0x74a07a7cd000	[anon:.bss]
2025-11-08 13:30:31.506  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07a800000-0x74a07ca00000	
2025-11-08 13:30:31.506  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07ca0c000-0x74a07ca60000	/system/lib64/libxml2.so
2025-11-08 13:30:31.506  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07ca60000-0x74a07cb30000	/system/lib64/libxml2.so
2025-11-08 13:30:31.506  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07cb30000-0x74a07cb33000	/system/lib64/libxml2.so
2025-11-08 13:30:31.506  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07cb33000-0x74a07cb34000	
2025-11-08 13:30:31.506  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07cb34000-0x74a07cb35000	/system/lib64/libxml2.so
2025-11-08 13:30:31.506  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07cb35000-0x74a07cb36000	[anon:.bss]
2025-11-08 13:30:31.506  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07cb9a000-0x74a07cbb4000	/system/lib64/libpowermanager.so
2025-11-08 13:30:31.506  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07cbb4000-0x74a07cbb6000	[page size compat]
2025-11-08 13:30:31.506  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07cbb6000-0x74a07cbd7000	/system/lib64/libpowermanager.so
2025-11-08 13:30:31.506  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07cbd7000-0x74a07cbda000	[page size compat]
2025-11-08 13:30:31.506  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07cbda000-0x74a07cbe1000	/system/lib64/libpowermanager.so
2025-11-08 13:30:31.506  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07cbe1000-0x74a07cbe2000	
2025-11-08 13:30:31.506  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07cbe2000-0x74a07cbe3000	/system/lib64/libpowermanager.so
2025-11-08 13:30:31.507  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07cc00000-0x74a07e800000	
2025-11-08 13:30:31.507  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e843000-0x74a07e85c000	/system/lib64/libandroid.so
2025-11-08 13:30:31.507  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e85c000-0x74a07e85f000	[page size compat]
2025-11-08 13:30:31.507  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e85f000-0x74a07e874000	/system/lib64/libandroid.so
2025-11-08 13:30:31.507  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e874000-0x74a07e877000	[page size compat]
2025-11-08 13:30:31.507  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e877000-0x74a07e87a000	/system/lib64/libandroid.so
2025-11-08 13:30:31.507  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e87a000-0x74a07e87b000	
2025-11-08 13:30:31.507  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e87b000-0x74a07e87c000	/system/lib64/libandroid.so
2025-11-08 13:30:31.507  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e883000-0x74a07e88c000	/system/lib64/android.hardware.power-V5-ndk.so
2025-11-08 13:30:31.507  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e88c000-0x74a07e88f000	[page size compat]
2025-11-08 13:30:31.507  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e88f000-0x74a07e898000	/system/lib64/android.hardware.power-V5-ndk.so
2025-11-08 13:30:31.507  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e898000-0x74a07e89b000	[page size compat]
2025-11-08 13:30:31.507  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e89b000-0x74a07e89c000	/system/lib64/android.hardware.power-V5-ndk.so
2025-11-08 13:30:31.507  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e89c000-0x74a07e89f000	
2025-11-08 13:30:31.507  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e89f000-0x74a07e8a0000	/system/lib64/android.hardware.power-V5-ndk.so
2025-11-08 13:30:31.507  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e8db000-0x74a07e8e0000	/system/lib64/libactivitymanager_aidl.so
2025-11-08 13:30:31.507  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e8e0000-0x74a07e8e3000	[page size compat]
2025-11-08 13:30:31.507  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e8e3000-0x74a07e8e7000	/system/lib64/libactivitymanager_aidl.so
2025-11-08 13:30:31.507  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e8e7000-0x74a07e8e9000	/system/lib64/libactivitymanager_aidl.so
2025-11-08 13:30:31.507  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e8e9000-0x74a07e8eb000	
2025-11-08 13:30:31.507  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e8eb000-0x74a07e8ec000	/system/lib64/libactivitymanager_aidl.so
2025-11-08 13:30:31.507  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e904000-0x74a07e90d000	/system/lib64/android.hardware.power@1.0.so
2025-11-08 13:30:31.507  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e90d000-0x74a07e910000	[page size compat]
2025-11-08 13:30:31.508  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e910000-0x74a07e918000	/system/lib64/android.hardware.power@1.0.so
2025-11-08 13:30:31.508  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e918000-0x74a07e91a000	/system/lib64/android.hardware.power@1.0.so
2025-11-08 13:30:31.508  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e91a000-0x74a07e91c000	
2025-11-08 13:30:31.508  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e91c000-0x74a07e91d000	/system/lib64/android.hardware.power@1.0.so
2025-11-08 13:30:31.508  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e953000-0x74a07e955000	/system/lib64/android.os.flags-aconfig-cc.so
2025-11-08 13:30:31.508  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e955000-0x74a07e957000	[page size compat]
2025-11-08 13:30:31.508  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e957000-0x74a07e958000	/system/lib64/android.os.flags-aconfig-cc.so
2025-11-08 13:30:31.508  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e958000-0x74a07e95b000	[page size compat]
2025-11-08 13:30:31.508  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e95b000-0x74a07e95c000	/system/lib64/android.os.flags-aconfig-cc.so
2025-11-08 13:30:31.508  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e95c000-0x74a07e95f000	
2025-11-08 13:30:31.508  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e95f000-0x74a07e960000	[anon:.bss]
2025-11-08 13:30:31.508  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e997000-0x74a07e9a2000	/system/lib64/android.hardware.power@1.3.so
2025-11-08 13:30:31.508  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e9a2000-0x74a07e9a3000	[page size compat]
2025-11-08 13:30:31.508  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e9a3000-0x74a07e9ab000	/system/lib64/android.hardware.power@1.3.so
2025-11-08 13:30:31.508  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e9ab000-0x74a07e9ad000	/system/lib64/android.hardware.power@1.3.so
2025-11-08 13:30:31.508  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e9ad000-0x74a07e9af000	
2025-11-08 13:30:31.508  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e9af000-0x74a07e9b0000	/system/lib64/android.hardware.power@1.3.so
2025-11-08 13:30:31.508  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07e9ff000-0x74a07f200000	[anon:dalvik-Concurrent mark-compact compaction buffers]
2025-11-08 13:30:31.508  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a07f200000-0x74a0a3200000	[anon:dalvik-main space]
2025-11-08 13:30:31.508  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a325b000-0x74a0a3265000	/system/lib64/android.hardware.power@1.2.so
2025-11-08 13:30:31.508  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a3265000-0x74a0a3267000	[page size compat]
2025-11-08 13:30:31.508  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a3267000-0x74a0a326f000	/system/lib64/android.hardware.power@1.2.so
2025-11-08 13:30:31.509  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a326f000-0x74a0a3271000	/system/lib64/android.hardware.power@1.2.so
2025-11-08 13:30:31.509  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a3271000-0x74a0a3273000	
2025-11-08 13:30:31.509  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a3273000-0x74a0a3274000	/system/lib64/android.hardware.power@1.2.so
2025-11-08 13:30:31.509  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a328a000-0x74a0a3294000	/system/lib64/android.hardware.power@1.1.so
2025-11-08 13:30:31.509  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a3294000-0x74a0a3296000	[page size compat]
2025-11-08 13:30:31.509  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a3296000-0x74a0a329e000	/system/lib64/android.hardware.power@1.1.so
2025-11-08 13:30:31.509  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a329e000-0x74a0a32a0000	/system/lib64/android.hardware.power@1.1.so
2025-11-08 13:30:31.509  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a32a0000-0x74a0a32a2000	
2025-11-08 13:30:31.509  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a32a2000-0x74a0a32a3000	/system/lib64/android.hardware.power@1.1.so
2025-11-08 13:30:31.509  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a32cc000-0x74a0a32d4000	/apex/com.android.art/lib64/libadbconnection.so
2025-11-08 13:30:31.509  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a32d4000-0x74a0a32e3000	/apex/com.android.art/lib64/libadbconnection.so
2025-11-08 13:30:31.509  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a32e3000-0x74a0a32e4000	[page size compat]
2025-11-08 13:30:31.509  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a32e4000-0x74a0a32e5000	/apex/com.android.art/lib64/libadbconnection.so
2025-11-08 13:30:31.509  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a32e5000-0x74a0a32e8000	
2025-11-08 13:30:31.509  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a32e8000-0x74a0a32e9000	[anon:.bss]
2025-11-08 13:30:31.509  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a332e000-0x74a0a3340000	/apex/com.android.adbd/lib64/libadbconnection_client.so
2025-11-08 13:30:31.509  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a3340000-0x74a0a3342000	[page size compat]
2025-11-08 13:30:31.509  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a3342000-0x74a0a3373000	/apex/com.android.adbd/lib64/libadbconnection_client.so
2025-11-08 13:30:31.509  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a3373000-0x74a0a3376000	[page size compat]
2025-11-08 13:30:31.509  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a3376000-0x74a0a3379000	/apex/com.android.adbd/lib64/libadbconnection_client.so
2025-11-08 13:30:31.509  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a3379000-0x74a0a337a000	
2025-11-08 13:30:31.509  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a337a000-0x74a0a337b000	/apex/com.android.adbd/lib64/libadbconnection_client.so
2025-11-08 13:30:31.509  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a337b000-0x74a0a337c000	[anon:.bss]
2025-11-08 13:30:31.509  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a33a7000-0x74a0a39e7000	[anon:dalvik-Concurrent mark-compact chunk-info vector]
2025-11-08 13:30:31.510  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a39e7000-0x74a0a42e7000	[anon:dalvik-Concurrent Mark Compact live words bitmap]
2025-11-08 13:30:31.510  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a42e7000-0x74a0a4ae8000	[anon:dalvik-live stack]
2025-11-08 13:30:31.510  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a4ae8000-0x74a0a52e9000	[anon:dalvik-allocation stack]
2025-11-08 13:30:31.510  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a52e9000-0x74a0a56ea000	[anon:dalvik-card table]
2025-11-08 13:30:31.510  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a56ea000-0x74a0a59ea000	[anon:dalvik-bump-pointer space live bitmap]
2025-11-08 13:30:31.510  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a5c18000-0x74a0a5d18000	[anon:ReadFileToBuffer]
2025-11-08 13:30:31.510  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a5d18000-0x74a0a5d28000	/vendor/lib64/egl/libGLESv2_emulation.so
2025-11-08 13:30:31.510  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a5d28000-0x74a0a5d30000	/vendor/lib64/egl/libGLESv2_emulation.so
2025-11-08 13:30:31.510  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a5d30000-0x74a0a5d32000	/vendor/lib64/egl/libGLESv2_emulation.so
2025-11-08 13:30:31.510  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a5d32000-0x74a0a5d34000	
2025-11-08 13:30:31.510  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a5d34000-0x74a0a5d35000	[anon:.bss]
2025-11-08 13:30:31.510  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a5d4d000-0x74a0a5d57000	/vendor/lib64/egl/libGLESv1_CM_emulation.so
2025-11-08 13:30:31.510  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a5d57000-0x74a0a5d59000	[page size compat]
2025-11-08 13:30:31.510  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a5d59000-0x74a0a5d5e000	/vendor/lib64/egl/libGLESv1_CM_emulation.so
2025-11-08 13:30:31.510  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a5d5e000-0x74a0a5d61000	[page size compat]
2025-11-08 13:30:31.510  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a5d61000-0x74a0a5d63000	/vendor/lib64/egl/libGLESv1_CM_emulation.so
2025-11-08 13:30:31.510  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a5d63000-0x74a0a5d65000	
2025-11-08 13:30:31.510  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a5d65000-0x74a0a5d66000	[anon:.bss]
2025-11-08 13:30:31.510  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a5d98000-0x74a0a5da2000	/vendor/lib64/egl/libEGL_emulation.so
2025-11-08 13:30:31.510  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a5da2000-0x74a0a5da4000	[page size compat]
2025-11-08 13:30:31.510  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a5da4000-0x74a0a5db2000	/vendor/lib64/egl/libEGL_emulation.so
2025-11-08 13:30:31.510  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a5db2000-0x74a0a5db4000	[page size compat]
2025-11-08 13:30:31.510  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a5db4000-0x74a0a5db6000	/vendor/lib64/egl/libEGL_emulation.so
2025-11-08 13:30:31.511  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a5db6000-0x74a0a5db8000	
2025-11-08 13:30:31.511  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a5db8000-0x74a0a5db9000	/vendor/lib64/egl/libEGL_emulation.so
2025-11-08 13:30:31.511  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a5de2000-0x74a0a5de6000	
2025-11-08 13:30:31.511  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a5de6000-0x74a0a5ee2000	[anon:stack_and_tls:5711]
2025-11-08 13:30:31.511  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a5ee2000-0x74a0a5eea000	
2025-11-08 13:30:31.511  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a5eea000-0x74a0a5eeb000	[anon:stack_and_tls:5709]
2025-11-08 13:30:31.511  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a5eeb000-0x74a0a5fe6000	[anon:stack_and_tls:5709]
2025-11-08 13:30:31.511  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a5fe6000-0x74a0a5fea000	
2025-11-08 13:30:31.511  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a5fea000-0x74a0a60ea000	[anon:dalvik-allocspace zygote / non moving space mark-bitmap 0]
2025-11-08 13:30:31.511  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a60ea000-0x74a0a61ea000	[anon:dalvik-allocspace zygote / non moving space live-bitmap 0]
2025-11-08 13:30:31.511  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a61ea000-0x74a0a6328000	/apex/com.android.wifi/javalib/framework-wifi.jar
2025-11-08 13:30:31.511  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a6328000-0x74a0a6500000	/apex/com.android.tethering/javalib/framework-connectivity.jar
2025-11-08 13:30:31.511  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a6500000-0x74a0a65be000	/apex/com.android.media/javalib/updatable-media.jar
2025-11-08 13:30:31.511  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a65be000-0x74a0a6676000	/apex/com.android.ipsec/javalib/android.net.ipsec.ike.jar
2025-11-08 13:30:31.511  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a6676000-0x74a0a6718000	/apex/com.android.healthfitness/javalib/framework-healthfitness.jar
2025-11-08 13:30:31.511  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a6718000-0x74a0a6845000	/apex/com.android.btservices/javalib/framework-bluetooth.jar
2025-11-08 13:30:31.511  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a6845000-0x74a0a6b1e000	/apex/com.android.i18n/javalib/core-icu4j.jar
2025-11-08 13:30:31.511  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a6b1e000-0x74a0a6bb3000	/system/framework/ims-common.jar
2025-11-08 13:30:31.511  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a6bb3000-0x74a0a6c7d000	/system/framework/voip-common.jar
2025-11-08 13:30:31.512  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a6c7d000-0x74a0a70c0000	/system/framework/telephony-common.jar
2025-11-08 13:30:31.512  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a70c0000-0x74a0a76e9000	/system/framework/framework.jar
2025-11-08 13:30:31.512  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a76e9000-0x74a0a7ecb000	/system/framework/framework.jar
2025-11-08 13:30:31.512  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a7ecb000-0x74a0a87fe000	/system/framework/framework.jar
2025-11-08 13:30:31.512  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a87fe000-0x74a0a90aa000	/system/framework/framework.jar
2025-11-08 13:30:31.512  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a90aa000-0x74a0a9a00000	/system/framework/framework.jar
2025-11-08 13:30:31.512  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0a9a00000-0x74a0a9f8d000	/apex/com.android.art/javalib/core-oj.jar
2025-11-08 13:30:31.512  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0aa000000-0x74a0aa150000	/apex/com.android.art/lib64/libart.so
2025-11-08 13:30:31.512  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0aa150000-0x74a0aa200000	
2025-11-08 13:30:31.512  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0aa200000-0x74a0aa9b4000	/apex/com.android.art/lib64/libart.so
2025-11-08 13:30:31.512  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0aa9b4000-0x74a0aaa00000	
2025-11-08 13:30:31.512  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0aaa00000-0x74a0aaa22000	/apex/com.android.art/lib64/libart.so
2025-11-08 13:30:31.512  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0aaa22000-0x74a0aac00000	
2025-11-08 13:30:31.512  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0aac00000-0x74a0aac04000	/apex/com.android.art/lib64/libart.so
2025-11-08 13:30:31.512  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0aac04000-0x74a0aac0a000	[anon:.bss]
2025-11-08 13:30:31.512  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0aac26000-0x74a0aad4b000	/apex/com.android.art/javalib/apache-xml.jar
2025-11-08 13:30:31.512  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0aad4b000-0x74a0aae00000	/apex/com.android.art/javalib/bouncycastle.jar
2025-11-08 13:30:31.512  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0aae00000-0x74a0abc00000	
2025-11-08 13:30:31.512  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0abc4c000-0x74a0abc55000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.512  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0abc55000-0x74a0abc95000	[anon:scudo:primary]
2025-11-08 13:30:31.512  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0abc95000-0x74a0bbc51000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.512  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0bbc51000-0x74a0bbc91000	[anon:scudo:primary]
2025-11-08 13:30:31.512  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0bbc91000-0x74a0cbc56000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.513  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0cbc56000-0x74a0cbc96000	[anon:scudo:primary]
2025-11-08 13:30:31.513  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0cbc96000-0x74a0cbcd6000	[anon:scudo:primary]
2025-11-08 13:30:31.513  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0cbcd6000-0x74a0dbc53000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.513  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0dbc53000-0x74a0dbc93000	[anon:scudo:primary]
2025-11-08 13:30:31.513  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0dbc93000-0x74a0ebc52000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.513  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0ebc52000-0x74a0ebc92000	[anon:scudo:primary]
2025-11-08 13:30:31.513  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0ebc92000-0x74a0fbc58000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.513  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0fbc58000-0x74a0fbc98000	[anon:scudo:primary]
2025-11-08 13:30:31.513  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a0fbc98000-0x74a10bc50000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.513  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a10bc50000-0x74a10bc90000	[anon:scudo:primary]
2025-11-08 13:30:31.513  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a10bc90000-0x74a11bc5b000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.513  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a11bc5b000-0x74a11bc9b000	[anon:scudo:primary]
2025-11-08 13:30:31.513  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a11bc9b000-0x74a12bc51000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.513  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a12bc51000-0x74a12bcd1000	[anon:scudo:primary]
2025-11-08 13:30:31.513  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a12bcd1000-0x74a13bc53000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.513  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a13bc53000-0x74a13bc93000	[anon:scudo:primary]
2025-11-08 13:30:31.513  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a13bc93000-0x74a14bc4e000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.513  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a14bc4e000-0x74a14bcce000	[anon:scudo:primary]
2025-11-08 13:30:31.513  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a14bcce000-0x74a15bc53000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.513  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a15bc53000-0x74a15bc93000	[anon:scudo:primary]
2025-11-08 13:30:31.513  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a15bc93000-0x74a16bc56000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.513  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a16bc56000-0x74a16bc96000	[anon:scudo:primary]
2025-11-08 13:30:31.513  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a16bc96000-0x74a17bc52000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.513  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a17bc52000-0x74a17bc92000	[anon:scudo:primary]
2025-11-08 13:30:31.514  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a17bc92000-0x74a18bc55000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.514  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a18bc55000-0x74a18bc95000	[anon:scudo:primary]
2025-11-08 13:30:31.514  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a18bc95000-0x74a19bc51000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.514  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a19bc51000-0x74a19bc91000	[anon:scudo:primary]
2025-11-08 13:30:31.514  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a19bc91000-0x74a19bcd1000	[anon:scudo:primary]
2025-11-08 13:30:31.514  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a19bcd1000-0x74a1abc52000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.514  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a1abc52000-0x74a1abc92000	[anon:scudo:primary]
2025-11-08 13:30:31.514  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a1abc92000-0x74a1bbc57000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.514  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a1bbc57000-0x74a1bbd57000	[anon:scudo:primary]
2025-11-08 13:30:31.514  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a1bbd57000-0x74a1cbc53000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.514  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a1cbc53000-0x74a1cbc93000	[anon:scudo:primary]
2025-11-08 13:30:31.514  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a1cbc93000-0x74a1dbc54000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.514  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a1dbc54000-0x74a1dbd14000	[anon:scudo:primary]
2025-11-08 13:30:31.514  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a1dbd14000-0x74a1ebc51000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.514  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a1ebc51000-0x74a1ebcd1000	[anon:scudo:primary]
2025-11-08 13:30:31.514  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a1ebcd1000-0x74a1fbc4f000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.514  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a1fbc4f000-0x74a1fbc8f000	[anon:scudo:primary]
2025-11-08 13:30:31.514  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a1fbc8f000-0x74a20bc57000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.514  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a20bc57000-0x74a20bc97000	[anon:scudo:primary]
2025-11-08 13:30:31.514  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a20bc97000-0x74a21bc57000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.514  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a21bc57000-0x74a21bcd7000	[anon:scudo:primary]
2025-11-08 13:30:31.514  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a21bcd7000-0x74a22bc5b000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.514  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a22bc5b000-0x74a22bc9b000	[anon:scudo:primary]
2025-11-08 13:30:31.514  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a22bc9b000-0x74a23bc5a000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.515  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a23bc5a000-0x74a23bc9a000	[anon:scudo:primary]
2025-11-08 13:30:31.515  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a23bc9a000-0x74a24bc55000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.515  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a24bc55000-0x74a24bc95000	[anon:scudo:primary]
2025-11-08 13:30:31.515  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a24bc95000-0x74a25bc5b000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.515  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a25bc5b000-0x74a25bc9b000	[anon:scudo:primary]
2025-11-08 13:30:31.515  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a25bc9b000-0x74a25bcdb000	[anon:scudo:primary]
2025-11-08 13:30:31.515  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a25bcdb000-0x74a26bc4f000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.515  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a26bc4f000-0x74a26bc8f000	[anon:scudo:primary]
2025-11-08 13:30:31.515  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a26bc8f000-0x74a27bc57000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.515  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a27bc57000-0x74a27bcd7000	[anon:scudo:primary]
2025-11-08 13:30:31.515  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a27bcd7000-0x74a28bc53000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.515  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a28bc53000-0x74a28bc93000	[anon:scudo:primary]
2025-11-08 13:30:31.515  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a28bc93000-0x74a29bc59000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.515  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a29bc59000-0x74a29bc99000	[anon:scudo:primary]
2025-11-08 13:30:31.515  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a29bc99000-0x74a2abc59000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.515  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a2abc59000-0x74a2abcd9000	[anon:scudo:primary]
2025-11-08 13:30:31.515  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a2abcd9000-0x74a2bbc4c000	[anon:scudo:primary_reserve]
2025-11-08 13:30:31.515  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a2bbc4c000-0x74a2bbc4f000	[anon:cfi shadow]
2025-11-08 13:30:31.515  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a2bbc4f000-0x74a2bbc50000	[anon:cfi shadow]
2025-11-08 13:30:31.515  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a2bbc50000-0x74a2ed352000	[anon:cfi shadow]
2025-11-08 13:30:31.515  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a2ed352000-0x74a2ed353000	[anon:cfi shadow]
2025-11-08 13:30:31.515  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a2ed353000-0x74a2f614c000	[anon:cfi shadow]
2025-11-08 13:30:31.515  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a2f614c000-0x74a2f614d000	[anon:cfi shadow]
2025-11-08 13:30:31.515  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a2f614d000-0x74a2f614e000	[anon:cfi shadow]
2025-11-08 13:30:31.515  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a2f614e000-0x74a2f614f000	[anon:cfi shadow]
2025-11-08 13:30:31.516  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a2f614f000-0x74a2f6150000	[anon:cfi shadow]
2025-11-08 13:30:31.516  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a2f6150000-0x74a2f6151000	[anon:cfi shadow]
2025-11-08 13:30:31.516  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a2f6151000-0x74a2f6152000	[anon:cfi shadow]
2025-11-08 13:30:31.516  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a2f6152000-0x74a2f6165000	[anon:cfi shadow]
2025-11-08 13:30:31.516  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a2f6165000-0x74a2f6166000	[anon:cfi shadow]
2025-11-08 13:30:31.516  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a2f6166000-0x74a2f6167000	[anon:cfi shadow]
2025-11-08 13:30:31.516  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a2f6167000-0x74a2f6168000	[anon:cfi shadow]
2025-11-08 13:30:31.516  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a2f6168000-0x74a2fbc38000	[anon:cfi shadow]
2025-11-08 13:30:31.516  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a2fbc38000-0x74a2fbc39000	[anon:cfi shadow]
2025-11-08 13:30:31.516  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a2fbc39000-0x74a33bc4c000	[anon:cfi shadow]
2025-11-08 13:30:31.516  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33bc4c000-0x74a33bc93000	/system/lib64/libcodec2_vndk.so
2025-11-08 13:30:31.516  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33bc93000-0x74a33bc94000	[page size compat]
2025-11-08 13:30:31.516  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33bc94000-0x74a33bd02000	/system/lib64/libcodec2_vndk.so
2025-11-08 13:30:31.516  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33bd02000-0x74a33bd04000	[page size compat]
2025-11-08 13:30:31.516  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33bd04000-0x74a33bd09000	/system/lib64/libcodec2_vndk.so
2025-11-08 13:30:31.516  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33bd09000-0x74a33bd0c000	
2025-11-08 13:30:31.516  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33bd0c000-0x74a33bd0d000	/system/lib64/libcodec2_vndk.so
2025-11-08 13:30:31.516  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33bd73000-0x74a33be00000	/apex/com.android.art/javalib/core-libart.jar
2025-11-08 13:30:31.516  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33be00000-0x74a33de00000	
2025-11-08 13:30:31.516  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33de5a000-0x74a33de5c000	/system/lib64/libtracing_perfetto.so
2025-11-08 13:30:31.516  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33de5c000-0x74a33de5e000	[page size compat]
2025-11-08 13:30:31.516  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33de5e000-0x74a33de5f000	/system/lib64/libtracing_perfetto.so
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33de5f000-0x74a33de62000	[page size compat]
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33de62000-0x74a33de63000	/system/lib64/libtracing_perfetto.so
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33de63000-0x74a33de66000	
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33de66000-0x74a33de67000	/system/lib64/libtracing_perfetto.so
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33de8a000-0x74a33de8b000	/system/lib64/android.media.audiopolicy-aconfig-cc.so
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33de8b000-0x74a33de8e000	[page size compat]
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33de8e000-0x74a33de90000	/system/lib64/android.media.audiopolicy-aconfig-cc.so
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33de90000-0x74a33de92000	[page size compat]
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33de92000-0x74a33de93000	/system/lib64/android.media.audiopolicy-aconfig-cc.so
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33de93000-0x74a33de96000	
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33de96000-0x74a33de97000	[anon:.bss]
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33ded7000-0x74a33dee3000	/system/lib64/android.hardware.configstore@1.0.so
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33dee3000-0x74a33deef000	/system/lib64/android.hardware.configstore@1.0.so
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33deef000-0x74a33def1000	/system/lib64/android.hardware.configstore@1.0.so
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33def1000-0x74a33def3000	
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33def3000-0x74a33def4000	/system/lib64/android.hardware.configstore@1.0.so
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33df03000-0x74a33df0a000	/system/lib64/libstagefright_xmlparser.so
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33df0a000-0x74a33df0b000	[page size compat]
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33df0b000-0x74a33df1c000	/system/lib64/libstagefright_xmlparser.so
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33df1c000-0x74a33df1f000	[page size compat]
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33df1f000-0x74a33df20000	/system/lib64/libstagefright_xmlparser.so
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33df20000-0x74a33df23000	
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33df23000-0x74a33df24000	[anon:.bss]
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33df5e000-0x74a33e034000	/system/lib64/libandroid_runtime.so
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33e034000-0x74a33e036000	[page size compat]
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33e036000-0x74a33e1ad000	/system/lib64/libandroid_runtime.so
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33e1ad000-0x74a33e1ae000	[page size compat]
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33e1ae000-0x74a33e1cd000	/system/lib64/libandroid_runtime.so
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33e1cd000-0x74a33e1ce000	
2025-11-08 13:30:31.517  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33e1ce000-0x74a33e1cf000	/system/lib64/libandroid_runtime.so
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33e1cf000-0x74a33e1d2000	[anon:.bss]
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a33e200000-0x74a341200000	
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a341232000-0x74a341331000	/apex/com.android.i18n/lib64/libicui18n.so
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a341331000-0x74a341332000	[page size compat]
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a341332000-0x74a3414d1000	/apex/com.android.i18n/lib64/libicui18n.so
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3414d1000-0x74a3414d2000	[page size compat]
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3414d2000-0x74a3414e6000	/apex/com.android.i18n/lib64/libicui18n.so
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3414e6000-0x74a3414e7000	/apex/com.android.i18n/lib64/libicui18n.so
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3414e7000-0x74a3414e8000	[anon:.bss]
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a341541000-0x74a341582000	/system/lib64/libprotobuf-cpp-lite.so
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a341582000-0x74a341585000	[page size compat]
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a341585000-0x74a3415c8000	/system/lib64/libprotobuf-cpp-lite.so
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3415c8000-0x74a3415c9000	[page size compat]
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3415c9000-0x74a3415cb000	/system/lib64/libprotobuf-cpp-lite.so
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3415cb000-0x74a3415cd000	
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3415cd000-0x74a3415ce000	/system/lib64/libprotobuf-cpp-lite.so
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a341600000-0x74a344800000	
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a344842000-0x74a344848000	/system/lib64/libpiex.so
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a344848000-0x74a34484a000	[page size compat]
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34484a000-0x74a34485d000	/system/lib64/libpiex.so
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34485d000-0x74a34485e000	[page size compat]
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34485e000-0x74a34485f000	/system/lib64/libpiex.so
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34485f000-0x74a344862000	
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a344862000-0x74a344863000	[anon:.bss]
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34488b000-0x74a344919000	/system/lib64/libgui.so
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a344919000-0x74a34491b000	[page size compat]
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34491b000-0x74a3449d6000	/system/lib64/libgui.so
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3449d6000-0x74a3449d7000	[page size compat]
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3449d7000-0x74a3449fc000	/system/lib64/libgui.so
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3449fc000-0x74a3449ff000	
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3449ff000-0x74a344a00000	/system/lib64/libgui.so
2025-11-08 13:30:31.518  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a344a00000-0x74a344b90000	/system/lib64/libhwui.so
2025-11-08 13:30:31.519  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a344b90000-0x74a344c00000	
2025-11-08 13:30:31.519  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a344c00000-0x74a34520f000	/system/lib64/libhwui.so
2025-11-08 13:30:31.519  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34520f000-0x74a345400000	
2025-11-08 13:30:31.519  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a345400000-0x74a345429000	/system/lib64/libhwui.so
2025-11-08 13:30:31.519  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a345429000-0x74a345600000	
2025-11-08 13:30:31.519  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a345600000-0x74a345602000	/system/lib64/libhwui.so
2025-11-08 13:30:31.519  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a345602000-0x74a34560b000	[anon:.bss]
2025-11-08 13:30:31.519  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a345644000-0x74a345647000	/system/lib64/libdebuggerd_client.so
2025-11-08 13:30:31.519  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a345647000-0x74a345648000	[page size compat]
2025-11-08 13:30:31.519  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a345648000-0x74a34564c000	/system/lib64/libdebuggerd_client.so
2025-11-08 13:30:31.519  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34564c000-0x74a34564d000	/system/lib64/libdebuggerd_client.so
2025-11-08 13:30:31.519  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34569c000-0x74a3456a1000	/system/lib64/audio-permission-aidl-cpp.so
2025-11-08 13:30:31.519  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3456a1000-0x74a3456a4000	[page size compat]
2025-11-08 13:30:31.519  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3456a4000-0x74a3456a6000	/system/lib64/audio-permission-aidl-cpp.so
2025-11-08 13:30:31.519  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3456a6000-0x74a3456a8000	[page size compat]
2025-11-08 13:30:31.519  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3456a8000-0x74a3456aa000	/system/lib64/audio-permission-aidl-cpp.so
2025-11-08 13:30:31.519  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3456aa000-0x74a3456ac000	
2025-11-08 13:30:31.519  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3456ac000-0x74a3456ad000	/system/lib64/audio-permission-aidl-cpp.so
2025-11-08 13:30:31.519  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3456c7000-0x74a3456d7000	/system/lib64/libstagefright_framecapture_utils.so
2025-11-08 13:30:31.519  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3456d7000-0x74a3456f5000	/system/lib64/libstagefright_framecapture_utils.so
2025-11-08 13:30:31.519  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3456f5000-0x74a3456f7000	[page size compat]
2025-11-08 13:30:31.519  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3456f7000-0x74a3456f9000	/system/lib64/libstagefright_framecapture_utils.so
2025-11-08 13:30:31.519  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3456f9000-0x74a3456fb000	
2025-11-08 13:30:31.519  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3456fb000-0x74a3456fc000	[anon:.bss]
2025-11-08 13:30:31.520  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a345707000-0x74a345708000	/system/lib64/libbattery.so
2025-11-08 13:30:31.520  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a345708000-0x74a34570b000	[page size compat]
2025-11-08 13:30:31.520  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34570b000-0x74a34570c000	/system/lib64/libbattery.so
2025-11-08 13:30:31.520  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34570c000-0x74a34570f000	[page size compat]
2025-11-08 13:30:31.520  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34570f000-0x74a345710000	/system/lib64/libbattery.so
2025-11-08 13:30:31.520  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a345763000-0x74a345768000	/system/lib64/libbinderdebug.so
2025-11-08 13:30:31.520  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a345768000-0x74a34576b000	[page size compat]
2025-11-08 13:30:31.520  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34576b000-0x74a345777000	/system/lib64/libbinderdebug.so
2025-11-08 13:30:31.520  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a345777000-0x74a345778000	/system/lib64/libbinderdebug.so
2025-11-08 13:30:31.520  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a345778000-0x74a34577b000	
2025-11-08 13:30:31.520  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34577b000-0x74a34577c000	[anon:.bss]
2025-11-08 13:30:31.520  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a345793000-0x74a3457a3000	/system/lib64/android.hardware.drm@1.3.so
2025-11-08 13:30:31.520  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3457a3000-0x74a3457b0000	/system/lib64/android.hardware.drm@1.3.so
2025-11-08 13:30:31.520  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3457b0000-0x74a3457b3000	[page size compat]
2025-11-08 13:30:31.520  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3457b3000-0x74a3457b7000	/system/lib64/android.hardware.drm@1.3.so
2025-11-08 13:30:31.520  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3457b7000-0x74a3457b8000	/system/lib64/android.hardware.drm@1.3.so
2025-11-08 13:30:31.520  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3457cb000-0x74a3457de000	/system/lib64/android.hardware.graphics.bufferqueue@2.0.so
2025-11-08 13:30:31.520  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3457de000-0x74a3457df000	[page size compat]
2025-11-08 13:30:31.520  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3457df000-0x74a3457f4000	/system/lib64/android.hardware.graphics.bufferqueue@2.0.so
2025-11-08 13:30:31.520  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3457f4000-0x74a3457f7000	[page size compat]
2025-11-08 13:30:31.520  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3457f7000-0x74a3457fb000	/system/lib64/android.hardware.graphics.bufferqueue@2.0.so
2025-11-08 13:30:31.520  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3457fb000-0x74a3457fc000	/system/lib64/android.hardware.graphics.bufferqueue@2.0.so
2025-11-08 13:30:31.520  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a345800000-0x74a347e00000	
2025-11-08 13:30:31.520  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a347e62000-0x74a348076000	/system/lib64/libpdfium.so
2025-11-08 13:30:31.520  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a348076000-0x74a348313000	/system/lib64/libpdfium.so
2025-11-08 13:30:31.520  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a348313000-0x74a348316000	[page size compat]
2025-11-08 13:30:31.521  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a348316000-0x74a348329000	/system/lib64/libpdfium.so
2025-11-08 13:30:31.521  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a348329000-0x74a34832a000	
2025-11-08 13:30:31.521  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34832a000-0x74a34832d000	/system/lib64/libpdfium.so
2025-11-08 13:30:31.521  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34832d000-0x74a34832f000	[anon:.bss]
2025-11-08 13:30:31.521  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34839b000-0x74a3483b5000	/system/lib64/audioflinger-aidl-cpp.so
2025-11-08 13:30:31.521  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3483b5000-0x74a3483b7000	[page size compat]
2025-11-08 13:30:31.521  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3483b7000-0x74a3483f1000	/system/lib64/audioflinger-aidl-cpp.so
2025-11-08 13:30:31.521  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3483f1000-0x74a3483f3000	[page size compat]
2025-11-08 13:30:31.521  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3483f3000-0x74a3483fb000	/system/lib64/audioflinger-aidl-cpp.so
2025-11-08 13:30:31.521  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3483fb000-0x74a3483fc000	/system/lib64/audioflinger-aidl-cpp.so
2025-11-08 13:30:31.521  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a348400000-0x74a34a200000	
2025-11-08 13:30:31.521  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a246000-0x74a34a24f000	/system/lib64/android.hidl.allocator@1.0.so
2025-11-08 13:30:31.521  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a24f000-0x74a34a252000	[page size compat]
2025-11-08 13:30:31.521  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a252000-0x74a34a259000	/system/lib64/android.hidl.allocator@1.0.so
2025-11-08 13:30:31.521  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a259000-0x74a34a25a000	[page size compat]
2025-11-08 13:30:31.521  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a25a000-0x74a34a25c000	/system/lib64/android.hidl.allocator@1.0.so
2025-11-08 13:30:31.521  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a25c000-0x74a34a25e000	
2025-11-08 13:30:31.521  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a25e000-0x74a34a25f000	/system/lib64/android.hidl.allocator@1.0.so
2025-11-08 13:30:31.521  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a28f000-0x74a34a2a3000	/system/lib64/libaudio_aidl_conversion_common_cpp.so
2025-11-08 13:30:31.521  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a2a3000-0x74a34a2ce000	/system/lib64/libaudio_aidl_conversion_common_cpp.so
2025-11-08 13:30:31.521  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a2ce000-0x74a34a2cf000	[page size compat]
2025-11-08 13:30:31.521  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a2cf000-0x74a34a2d1000	/system/lib64/libaudio_aidl_conversion_common_cpp.so
2025-11-08 13:30:31.521  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a2d1000-0x74a34a2d3000	
2025-11-08 13:30:31.521  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a2d3000-0x74a34a2d4000	[anon:.bss]
2025-11-08 13:30:31.521  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a301000-0x74a34a318000	/system/lib64/android.hardware.cas@1.0.so
2025-11-08 13:30:31.521  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a318000-0x74a34a319000	[page size compat]
2025-11-08 13:30:31.521  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a319000-0x74a34a336000	/system/lib64/android.hardware.cas@1.0.so
2025-11-08 13:30:31.522  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a336000-0x74a34a339000	[page size compat]
2025-11-08 13:30:31.522  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a339000-0x74a34a33e000	/system/lib64/android.hardware.cas@1.0.so
2025-11-08 13:30:31.522  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a33e000-0x74a34a341000	
2025-11-08 13:30:31.522  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a341000-0x74a34a342000	/system/lib64/android.hardware.cas@1.0.so
2025-11-08 13:30:31.522  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a38d000-0x74a34a38f000	/system/lib64/android.os.flags-aconfig-cc-host.so
2025-11-08 13:30:31.522  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a38f000-0x74a34a391000	[page size compat]
2025-11-08 13:30:31.522  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a391000-0x74a34a392000	/system/lib64/android.os.flags-aconfig-cc-host.so
2025-11-08 13:30:31.522  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a392000-0x74a34a395000	[page size compat]
2025-11-08 13:30:31.522  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a395000-0x74a34a396000	/system/lib64/android.os.flags-aconfig-cc-host.so
2025-11-08 13:30:31.522  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a396000-0x74a34a399000	
2025-11-08 13:30:31.522  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a399000-0x74a34a39a000	[anon:.bss]
2025-11-08 13:30:31.522  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a3c9000-0x74a34a3d3000	/system/lib64/libtinyxml2.so
2025-11-08 13:30:31.522  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a3d3000-0x74a34a3d5000	[page size compat]
2025-11-08 13:30:31.522  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a3d5000-0x74a34a3e6000	/system/lib64/libtinyxml2.so
2025-11-08 13:30:31.522  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a3e6000-0x74a34a3e9000	[page size compat]
2025-11-08 13:30:31.522  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a3e9000-0x74a34a3ea000	/system/lib64/libtinyxml2.so
2025-11-08 13:30:31.522  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a3ea000-0x74a34a3ed000	
2025-11-08 13:30:31.522  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a3ed000-0x74a34a3ee000	/system/lib64/libtinyxml2.so
2025-11-08 13:30:31.522  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a406000-0x74a34a439000	/system/lib64/libsqlite.so
2025-11-08 13:30:31.522  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a439000-0x74a34a43a000	[page size compat]
2025-11-08 13:30:31.522  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a43a000-0x74a34a5e6000	/system/lib64/libsqlite.so
2025-11-08 13:30:31.522  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a5e6000-0x74a34a5e9000	/system/lib64/libsqlite.so
2025-11-08 13:30:31.522  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a5e9000-0x74a34a5ea000	
2025-11-08 13:30:31.522  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a5ea000-0x74a34a5ed000	/system/lib64/libsqlite.so
2025-11-08 13:30:31.522  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a5ed000-0x74a34a5ee000	[anon:.bss]
2025-11-08 13:30:31.522  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34a600000-0x74a34d800000	
2025-11-08 13:30:31.522  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34d844000-0x74a34d846000	/system/lib64/libfmq.so
2025-11-08 13:30:31.523  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34d846000-0x74a34d848000	[page size compat]
2025-11-08 13:30:31.523  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34d848000-0x74a34d849000	/system/lib64/libfmq.so
2025-11-08 13:30:31.523  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34d849000-0x74a34d84c000	[page size compat]
2025-11-08 13:30:31.523  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34d84c000-0x74a34d84d000	/system/lib64/libfmq.so
2025-11-08 13:30:31.523  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34d892000-0x74a34d894000	/system/lib64/libcgrouprc.so
2025-11-08 13:30:31.523  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34d894000-0x74a34d896000	[page size compat]
2025-11-08 13:30:31.523  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34d896000-0x74a34d897000	/system/lib64/libcgrouprc.so
2025-11-08 13:30:31.523  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34d897000-0x74a34d89a000	[page size compat]
2025-11-08 13:30:31.523  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34d89a000-0x74a34d89b000	/system/lib64/libcgrouprc.so
2025-11-08 13:30:31.523  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34d89b000-0x74a34d89e000	
2025-11-08 13:30:31.523  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34d89e000-0x74a34d89f000	[anon:.bss]
2025-11-08 13:30:31.523  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34d8c8000-0x74a34d8ca000	/system/lib64/libmemtrack.so
2025-11-08 13:30:31.523  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34d8ca000-0x74a34d8cc000	[page size compat]
2025-11-08 13:30:31.523  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34d8cc000-0x74a34d8cd000	/system/lib64/libmemtrack.so
2025-11-08 13:30:31.523  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34d8cd000-0x74a34d8d0000	[page size compat]
2025-11-08 13:30:31.523  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34d8d0000-0x74a34d8d1000	/system/lib64/libmemtrack.so
2025-11-08 13:30:31.523  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34d8d1000-0x74a34d8d4000	
2025-11-08 13:30:31.523  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34d8d4000-0x74a34d8d5000	[anon:.bss]
2025-11-08 13:30:31.523  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34d933000-0x74a34d94e000	/system/lib64/libprocessgroup.so
2025-11-08 13:30:31.523  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34d94e000-0x74a34d94f000	[page size compat]
2025-11-08 13:30:31.523  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34d94f000-0x74a34d986000	/system/lib64/libprocessgroup.so
2025-11-08 13:30:31.523  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34d986000-0x74a34d987000	[page size compat]
2025-11-08 13:30:31.523  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34d987000-0x74a34d989000	/system/lib64/libprocessgroup.so
2025-11-08 13:30:31.523  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34d989000-0x74a34d98b000	
2025-11-08 13:30:31.523  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34d98b000-0x74a34d98c000	[anon:.bss]
2025-11-08 13:30:31.523  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a34da00000-0x74a351000000	
2025-11-08 13:30:31.523  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35105c000-0x74a351065000	/system/lib64/android.hidl.token@1.0.so
2025-11-08 13:30:31.524  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351065000-0x74a351068000	[page size compat]
2025-11-08 13:30:31.524  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351068000-0x74a351070000	/system/lib64/android.hidl.token@1.0.so
2025-11-08 13:30:31.524  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351070000-0x74a351072000	/system/lib64/android.hidl.token@1.0.so
2025-11-08 13:30:31.524  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351072000-0x74a351074000	
2025-11-08 13:30:31.524  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351074000-0x74a351075000	/system/lib64/android.hidl.token@1.0.so
2025-11-08 13:30:31.524  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3510b3000-0x74a3510b7000	/system/lib64/android.companion.virtual.virtualdevice_aidl-cpp.so
2025-11-08 13:30:31.524  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3510b7000-0x74a3510b9000	/system/lib64/android.companion.virtual.virtualdevice_aidl-cpp.so
2025-11-08 13:30:31.524  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3510b9000-0x74a3510bb000	[page size compat]
2025-11-08 13:30:31.524  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3510bb000-0x74a3510bc000	/system/lib64/android.companion.virtual.virtualdevice_aidl-cpp.so
2025-11-08 13:30:31.524  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3510bc000-0x74a3510bf000	
2025-11-08 13:30:31.524  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3510bf000-0x74a3510c0000	/system/lib64/android.companion.virtual.virtualdevice_aidl-cpp.so
2025-11-08 13:30:31.524  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3510db000-0x74a3510ef000	/system/lib64/audiopolicy-aidl-cpp.so
2025-11-08 13:30:31.524  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3510ef000-0x74a351125000	/system/lib64/audiopolicy-aidl-cpp.so
2025-11-08 13:30:31.524  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351125000-0x74a351127000	[page size compat]
2025-11-08 13:30:31.524  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351127000-0x74a35112b000	/system/lib64/audiopolicy-aidl-cpp.so
2025-11-08 13:30:31.524  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35112b000-0x74a35112c000	/system/lib64/audiopolicy-aidl-cpp.so
2025-11-08 13:30:31.524  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35115b000-0x74a351167000	/system/lib64/android.hardware.configstore@1.1.so
2025-11-08 13:30:31.524  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351167000-0x74a351170000	/system/lib64/android.hardware.configstore@1.1.so
2025-11-08 13:30:31.524  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351170000-0x74a351173000	[page size compat]
2025-11-08 13:30:31.524  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351173000-0x74a351175000	/system/lib64/android.hardware.configstore@1.1.so
2025-11-08 13:30:31.524  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351175000-0x74a351177000	
2025-11-08 13:30:31.524  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351177000-0x74a351178000	/system/lib64/android.hardware.configstore@1.1.so
2025-11-08 13:30:31.524  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35118e000-0x74a35118f000	/system/lib64/libpackagelistparser.so
2025-11-08 13:30:31.524  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35118f000-0x74a351192000	[page size compat]
2025-11-08 13:30:31.524  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351192000-0x74a351193000	/system/lib64/libpackagelistparser.so
2025-11-08 13:30:31.525  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351193000-0x74a351196000	[page size compat]
2025-11-08 13:30:31.525  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351196000-0x74a351197000	/system/lib64/libpackagelistparser.so
2025-11-08 13:30:31.525  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3511cd000-0x74a3511d0000	/system/lib64/libhidlmemory.so
2025-11-08 13:30:31.525  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3511d0000-0x74a3511d1000	[page size compat]
2025-11-08 13:30:31.525  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3511d1000-0x74a3511d3000	/system/lib64/libhidlmemory.so
2025-11-08 13:30:31.525  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3511d3000-0x74a3511d5000	[page size compat]
2025-11-08 13:30:31.525  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3511d5000-0x74a3511d6000	/system/lib64/libhidlmemory.so
2025-11-08 13:30:31.525  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3511d6000-0x74a3511d9000	
2025-11-08 13:30:31.525  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3511d9000-0x74a3511da000	[anon:.bss]
2025-11-08 13:30:31.525  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351203000-0x74a351208000	/system/lib64/android.hardware.graphics.allocator-V2-ndk.so
2025-11-08 13:30:31.525  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351208000-0x74a35120b000	[page size compat]
2025-11-08 13:30:31.525  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35120b000-0x74a35120f000	/system/lib64/android.hardware.graphics.allocator-V2-ndk.so
2025-11-08 13:30:31.525  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35120f000-0x74a351210000	/system/lib64/android.hardware.graphics.allocator-V2-ndk.so
2025-11-08 13:30:31.525  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351210000-0x74a351213000	
2025-11-08 13:30:31.525  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351213000-0x74a351214000	/system/lib64/android.hardware.graphics.allocator-V2-ndk.so
2025-11-08 13:30:31.525  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351260000-0x74a3512e3000	/system/lib64/libc++.so
2025-11-08 13:30:31.525  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3512e3000-0x74a3512e6000	
2025-11-08 13:30:31.525  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3512e6000-0x74a35135b000	/system/lib64/libc++.so
2025-11-08 13:30:31.525  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35135b000-0x74a35135e000	
2025-11-08 13:30:31.525  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35135e000-0x74a351366000	/system/lib64/libc++.so
2025-11-08 13:30:31.525  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351366000-0x74a351369000	
2025-11-08 13:30:31.525  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351369000-0x74a35136a000	/system/lib64/libc++.so
2025-11-08 13:30:31.525  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35136a000-0x74a351371000	[anon:.bss]
2025-11-08 13:30:31.525  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351392000-0x74a35139a000	/system/lib64/libnativedisplay.so
2025-11-08 13:30:31.525  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35139a000-0x74a3513a1000	/system/lib64/libnativedisplay.so
2025-11-08 13:30:31.525  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3513a1000-0x74a3513a2000	[page size compat]
2025-11-08 13:30:31.525  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3513a2000-0x74a3513a3000	/system/lib64/libnativedisplay.so
2025-11-08 13:30:31.526  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3513a3000-0x74a3513a6000	
2025-11-08 13:30:31.526  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3513a6000-0x74a3513a7000	[anon:.bss]
2025-11-08 13:30:31.526  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3513d4000-0x74a3513dd000	/system/lib64/libziparchive.so
2025-11-08 13:30:31.526  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3513dd000-0x74a3513e0000	[page size compat]
2025-11-08 13:30:31.526  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3513e0000-0x74a3513ec000	/system/lib64/libziparchive.so
2025-11-08 13:30:31.526  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3513ec000-0x74a3513ed000	/system/lib64/libziparchive.so
2025-11-08 13:30:31.526  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3513ed000-0x74a3513f0000	
2025-11-08 13:30:31.526  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3513f0000-0x74a3513f1000	[anon:.bss]
2025-11-08 13:30:31.526  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35140c000-0x74a35143b000	/system/lib64/libunwindstack.so
2025-11-08 13:30:31.526  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35143b000-0x74a35143c000	[page size compat]
2025-11-08 13:30:31.526  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35143c000-0x74a3514c2000	/system/lib64/libunwindstack.so
2025-11-08 13:30:31.526  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3514c2000-0x74a3514c4000	[page size compat]
2025-11-08 13:30:31.526  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3514c4000-0x74a3514cc000	/system/lib64/libunwindstack.so
2025-11-08 13:30:31.526  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3514cc000-0x74a3514cd000	/system/lib64/libunwindstack.so
2025-11-08 13:30:31.526  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35152d000-0x74a351531000	/system/lib64/android.hardware.memtrack-V1-ndk.so
2025-11-08 13:30:31.526  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351531000-0x74a351534000	/system/lib64/android.hardware.memtrack-V1-ndk.so
2025-11-08 13:30:31.526  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351534000-0x74a351535000	[page size compat]
2025-11-08 13:30:31.526  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351535000-0x74a351536000	/system/lib64/android.hardware.memtrack-V1-ndk.so
2025-11-08 13:30:31.526  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351536000-0x74a351539000	
2025-11-08 13:30:31.526  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351539000-0x74a35153a000	/system/lib64/android.hardware.memtrack-V1-ndk.so
2025-11-08 13:30:31.526  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35156e000-0x74a351573000	/apex/com.android.i18n/lib64/libandroidicu.so
2025-11-08 13:30:31.526  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351573000-0x74a351576000	[page size compat]
2025-11-08 13:30:31.526  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351576000-0x74a351577000	/apex/com.android.i18n/lib64/libandroidicu.so
2025-11-08 13:30:31.526  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351577000-0x74a35157a000	[page size compat]
2025-11-08 13:30:31.526  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35157a000-0x74a35157b000	/apex/com.android.i18n/lib64/libandroidicu.so
2025-11-08 13:30:31.527  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351587000-0x74a351596000	/system/lib64/libultrahdr.so
2025-11-08 13:30:31.527  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351596000-0x74a351597000	[page size compat]
2025-11-08 13:30:31.527  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351597000-0x74a3515bb000	/system/lib64/libultrahdr.so
2025-11-08 13:30:31.527  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3515bb000-0x74a3515bc000	/system/lib64/libultrahdr.so
2025-11-08 13:30:31.527  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3515bc000-0x74a3515bf000	
2025-11-08 13:30:31.527  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3515bf000-0x74a3515c0000	[anon:.bss]
2025-11-08 13:30:31.527  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3515cd000-0x74a3515d6000	/apex/com.android.art/lib64/libnativeloader.so
2025-11-08 13:30:31.527  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3515d6000-0x74a3515d9000	[page size compat]
2025-11-08 13:30:31.527  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3515d9000-0x74a3515f3000	/apex/com.android.art/lib64/libnativeloader.so
2025-11-08 13:30:31.527  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3515f3000-0x74a3515f5000	[page size compat]
2025-11-08 13:30:31.527  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3515f5000-0x74a3515f6000	/apex/com.android.art/lib64/libnativeloader.so
2025-11-08 13:30:31.527  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3515f6000-0x74a3515f9000	
2025-11-08 13:30:31.527  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3515f9000-0x74a3515fa000	[anon:.bss]
2025-11-08 13:30:31.527  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351610000-0x74a35162f000	/system/lib64/android.hardware.media.c2-V1-ndk.so
2025-11-08 13:30:31.527  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35162f000-0x74a351630000	[page size compat]
2025-11-08 13:30:31.527  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351630000-0x74a351650000	/system/lib64/android.hardware.media.c2-V1-ndk.so
2025-11-08 13:30:31.527  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351650000-0x74a351653000	/system/lib64/android.hardware.media.c2-V1-ndk.so
2025-11-08 13:30:31.527  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351653000-0x74a351654000	
2025-11-08 13:30:31.527  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351654000-0x74a351655000	/system/lib64/android.hardware.media.c2-V1-ndk.so
2025-11-08 13:30:31.527  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351697000-0x74a35169c000	/system/lib64/libnativewindow.so
2025-11-08 13:30:31.527  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35169c000-0x74a35169f000	[page size compat]
2025-11-08 13:30:31.527  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35169f000-0x74a3516a2000	/system/lib64/libnativewindow.so
2025-11-08 13:30:31.527  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3516a2000-0x74a3516a3000	[page size compat]
2025-11-08 13:30:31.527  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3516a3000-0x74a3516a4000	/system/lib64/libnativewindow.so
2025-11-08 13:30:31.527  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3516a4000-0x74a3516a7000	
2025-11-08 13:30:31.528  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3516a7000-0x74a3516a8000	[anon:.bss]
2025-11-08 13:30:31.528  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3516f0000-0x74a3516f2000	/system/lib64/server_configurable_flags.so
2025-11-08 13:30:31.528  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3516f2000-0x74a3516f4000	[page size compat]
2025-11-08 13:30:31.528  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3516f4000-0x74a3516f6000	/system/lib64/server_configurable_flags.so
2025-11-08 13:30:31.528  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3516f6000-0x74a3516f8000	[page size compat]
2025-11-08 13:30:31.528  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3516f8000-0x74a3516f9000	/system/lib64/server_configurable_flags.so
2025-11-08 13:30:31.528  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351711000-0x74a351712000	/system/lib64/libcodec2.so
2025-11-08 13:30:31.528  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351712000-0x74a351715000	[page size compat]
2025-11-08 13:30:31.528  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351715000-0x74a351716000	/system/lib64/libcodec2.so
2025-11-08 13:30:31.528  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351716000-0x74a351719000	[page size compat]
2025-11-08 13:30:31.528  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351719000-0x74a35171a000	/system/lib64/libcodec2.so
2025-11-08 13:30:31.528  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35174f000-0x74a351750000	/system/lib64/libvndksupport.so
2025-11-08 13:30:31.528  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351750000-0x74a351753000	[page size compat]
2025-11-08 13:30:31.528  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351753000-0x74a351754000	/system/lib64/libvndksupport.so
2025-11-08 13:30:31.528  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351754000-0x74a351757000	[page size compat]
2025-11-08 13:30:31.528  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351757000-0x74a351758000	/system/lib64/libvndksupport.so
2025-11-08 13:30:31.528  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351758000-0x74a35175b000	
2025-11-08 13:30:31.528  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35175b000-0x74a35175c000	[anon:.bss]
2025-11-08 13:30:31.528  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351790000-0x74a351791000	/system/lib64/libnativeloader_lazy.so
2025-11-08 13:30:31.528  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351791000-0x74a351794000	[page size compat]
2025-11-08 13:30:31.528  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351794000-0x74a351795000	/system/lib64/libnativeloader_lazy.so
2025-11-08 13:30:31.529  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351795000-0x74a351798000	[page size compat]
2025-11-08 13:30:31.529  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351798000-0x74a351799000	/system/lib64/libnativeloader_lazy.so
2025-11-08 13:30:31.529  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351799000-0x74a35179c000	
2025-11-08 13:30:31.529  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35179c000-0x74a35179d000	[anon:.bss]
2025-11-08 13:30:31.529  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3517c4000-0x74a3517d3000	/system/lib64/libdatasource.so
2025-11-08 13:30:31.529  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3517d3000-0x74a3517d4000	[page size compat]
2025-11-08 13:30:31.529  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3517d4000-0x74a3517e7000	/system/lib64/libdatasource.so
2025-11-08 13:30:31.529  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3517e7000-0x74a3517e8000	[page size compat]
2025-11-08 13:30:31.529  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3517e8000-0x74a3517ea000	/system/lib64/libdatasource.so
2025-11-08 13:30:31.529  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3517ea000-0x74a3517ec000	
2025-11-08 13:30:31.529  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3517ec000-0x74a3517ed000	/system/lib64/libdatasource.so
2025-11-08 13:30:31.529  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35181e000-0x74a351829000	/system/lib64/android.hardware.graphics.mapper@2.1.so
2025-11-08 13:30:31.529  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351829000-0x74a35182a000	[page size compat]
2025-11-08 13:30:31.529  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35182a000-0x74a351833000	/system/lib64/android.hardware.graphics.mapper@2.1.so
2025-11-08 13:30:31.529  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351833000-0x74a351836000	[page size compat]
2025-11-08 13:30:31.529  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351836000-0x74a351838000	/system/lib64/android.hardware.graphics.mapper@2.1.so
2025-11-08 13:30:31.530  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351838000-0x74a35183a000	
2025-11-08 13:30:31.530  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35183a000-0x74a35183b000	/system/lib64/android.hardware.graphics.mapper@2.1.so
2025-11-08 13:30:31.530  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35185c000-0x74a351863000	/system/lib64/libnetdutils.so
2025-11-08 13:30:31.530  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351863000-0x74a351864000	[page size compat]
2025-11-08 13:30:31.530  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351864000-0x74a351872000	/system/lib64/libnetdutils.so
2025-11-08 13:30:31.530  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351872000-0x74a351874000	[page size compat]
2025-11-08 13:30:31.530  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351874000-0x74a351875000	/system/lib64/libnetdutils.so
2025-11-08 13:30:31.530  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351875000-0x74a351878000	
2025-11-08 13:30:31.530  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351878000-0x74a351879000	[anon:.bss]
2025-11-08 13:30:31.530  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35188c000-0x74a3518ac000	/system/lib64/libmediautils.so
2025-11-08 13:30:31.530  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3518ac000-0x74a3518ef000	/system/lib64/libmediautils.so
2025-11-08 13:30:31.530  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3518ef000-0x74a3518f0000	[page size compat]
2025-11-08 13:30:31.530  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3518f0000-0x74a3518f7000	/system/lib64/libmediautils.so
2025-11-08 13:30:31.530  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3518f7000-0x74a3518f8000	
2025-11-08 13:30:31.530  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3518f8000-0x74a3518f9000	/system/lib64/libmediautils.so
2025-11-08 13:30:31.530  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35190d000-0x74a351943000	/system/lib64/libmedia.so
2025-11-08 13:30:31.530  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351943000-0x74a351945000	[page size compat]
2025-11-08 13:30:31.530  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351945000-0x74a35199e000	/system/lib64/libmedia.so
2025-11-08 13:30:31.530  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35199e000-0x74a3519a1000	[page size compat]
2025-11-08 13:30:31.530  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3519a1000-0x74a3519b4000	/system/lib64/libmedia.so
2025-11-08 13:30:31.530  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3519b4000-0x74a3519b5000	
2025-11-08 13:30:31.530  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3519b5000-0x74a3519b6000	/system/lib64/libmedia.so
2025-11-08 13:30:31.530  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3519d4000-0x74a3519e1000	/system/lib64/android.hidl.memory@1.0.so
2025-11-08 13:30:31.530  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3519e1000-0x74a3519e4000	[page size compat]
2025-11-08 13:30:31.530  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3519e4000-0x74a3519f1000	/system/lib64/android.hidl.memory@1.0.so
2025-11-08 13:30:31.531  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3519f1000-0x74a3519f4000	[page size compat]
2025-11-08 13:30:31.531  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3519f4000-0x74a3519f7000	/system/lib64/android.hidl.memory@1.0.so
2025-11-08 13:30:31.531  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3519f7000-0x74a3519f8000	
2025-11-08 13:30:31.531  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3519f8000-0x74a3519f9000	/system/lib64/android.hidl.memory@1.0.so
2025-11-08 13:30:31.531  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351a03000-0x74a351a3a000	/system/lib64/libsfplugin_ccodec.so
2025-11-08 13:30:31.531  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351a3a000-0x74a351a3b000	[page size compat]
2025-11-08 13:30:31.531  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351a3b000-0x74a351ac6000	/system/lib64/libsfplugin_ccodec.so
2025-11-08 13:30:31.531  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351ac6000-0x74a351ac7000	[page size compat]
2025-11-08 13:30:31.531  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351ac7000-0x74a351ace000	/system/lib64/libsfplugin_ccodec.so
2025-11-08 13:30:31.531  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351ace000-0x74a351acf000	
2025-11-08 13:30:31.531  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351acf000-0x74a351ad0000	/system/lib64/libsfplugin_ccodec.so
2025-11-08 13:30:31.531  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351b14000-0x74a351b15000	/system/lib64/libjpegdecoder.so
2025-11-08 13:30:31.531  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351b15000-0x74a351b18000	[page size compat]
2025-11-08 13:30:31.531  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351b18000-0x74a351b1a000	/system/lib64/libjpegdecoder.so
2025-11-08 13:30:31.531  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351b1a000-0x74a351b1c000	[page size compat]
2025-11-08 13:30:31.531  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351b1c000-0x74a351b1d000	/system/lib64/libjpegdecoder.so
2025-11-08 13:30:31.531  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351b60000-0x74a351b91000	/system/lib64/android.hardware.media.c2@1.0.so
2025-11-08 13:30:31.531  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351b91000-0x74a351b94000	[page size compat]
2025-11-08 13:30:31.531  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351b94000-0x74a351bd8000	/system/lib64/android.hardware.media.c2@1.0.so
2025-11-08 13:30:31.531  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351bd8000-0x74a351be2000	/system/lib64/android.hardware.media.c2@1.0.so
2025-11-08 13:30:31.531  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351be2000-0x74a351be4000	
2025-11-08 13:30:31.531  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351be4000-0x74a351be5000	/system/lib64/android.hardware.media.c2@1.0.so
2025-11-08 13:30:31.531  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351c0d000-0x74a351ccd000	/apex/com.android.i18n/lib64/libicuuc.so
2025-11-08 13:30:31.531  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351ccd000-0x74a351ddd000	/apex/com.android.i18n/lib64/libicuuc.so
2025-11-08 13:30:31.531  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351ddd000-0x74a351df2000	/apex/com.android.i18n/lib64/libicuuc.so
2025-11-08 13:30:31.531  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351df2000-0x74a351df5000	
2025-11-08 13:30:31.532  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351df5000-0x74a351df6000	/apex/com.android.i18n/lib64/libicuuc.so
2025-11-08 13:30:31.532  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351df6000-0x74a351df8000	[anon:.bss]
2025-11-08 13:30:31.532  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a351e00000-0x74a352000000	
2025-11-08 13:30:31.532  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a352055000-0x74a3520c1000	/system/lib64/libcrypto.so
2025-11-08 13:30:31.532  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3520c1000-0x74a3521be000	/system/lib64/libcrypto.so
2025-11-08 13:30:31.532  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3521be000-0x74a3521c1000	[page size compat]
2025-11-08 13:30:31.532  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3521c1000-0x74a3521d0000	/system/lib64/libcrypto.so
2025-11-08 13:30:31.532  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3521d0000-0x74a3521d1000	
2025-11-08 13:30:31.532  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3521d1000-0x74a3521d2000	/system/lib64/libcrypto.so
2025-11-08 13:30:31.532  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3521d2000-0x74a3521da000	[anon:.bss]
2025-11-08 13:30:31.532  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a352200000-0x74a355000000	
2025-11-08 13:30:31.532  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a355047000-0x74a355050000	/system/lib64/android.hardware.graphics.allocator@4.0.so
2025-11-08 13:30:31.532  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a355050000-0x74a355053000	[page size compat]
2025-11-08 13:30:31.532  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a355053000-0x74a35505a000	/system/lib64/android.hardware.graphics.allocator@4.0.so
2025-11-08 13:30:31.532  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35505a000-0x74a35505b000	[page size compat]
2025-11-08 13:30:31.532  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35505b000-0x74a35505d000	/system/lib64/android.hardware.graphics.allocator@4.0.so
2025-11-08 13:30:31.532  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35505d000-0x74a35505f000	
2025-11-08 13:30:31.532  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35505f000-0x74a355060000	/system/lib64/android.hardware.graphics.allocator@4.0.so
2025-11-08 13:30:31.532  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a355099000-0x74a35509b000	/system/lib64/libmedia_jni_utils.so
2025-11-08 13:30:31.532  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35509b000-0x74a35509d000	[page size compat]
2025-11-08 13:30:31.532  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35509d000-0x74a35509f000	/system/lib64/libmedia_jni_utils.so
2025-11-08 13:30:31.532  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35509f000-0x74a3550a1000	[page size compat]
2025-11-08 13:30:31.532  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3550a1000-0x74a3550a2000	/system/lib64/libmedia_jni_utils.so
2025-11-08 13:30:31.532  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3550d8000-0x74a3550eb000	/system/lib64/libclang_rt.ubsan_standalone-x86_64-android.so
2025-11-08 13:30:31.532  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3550eb000-0x74a3550ee000	
2025-11-08 13:30:31.532  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3550ee000-0x74a35510b000	/system/lib64/libclang_rt.ubsan_standalone-x86_64-android.so
2025-11-08 13:30:31.532  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35510b000-0x74a35510e000	
2025-11-08 13:30:31.533  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35510e000-0x74a355110000	/system/lib64/libclang_rt.ubsan_standalone-x86_64-android.so
2025-11-08 13:30:31.533  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a355110000-0x74a355113000	
2025-11-08 13:30:31.533  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a355113000-0x74a355116000	/system/lib64/libclang_rt.ubsan_standalone-x86_64-android.so
2025-11-08 13:30:31.533  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a355116000-0x74a3552f8000	[anon:.bss]
2025-11-08 13:30:31.533  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a355348000-0x74a35534a000	/system/lib64/aconfig_text_flags_c_lib.so
2025-11-08 13:30:31.533  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35534a000-0x74a35534c000	[page size compat]
2025-11-08 13:30:31.533  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35534c000-0x74a35534d000	/system/lib64/aconfig_text_flags_c_lib.so
2025-11-08 13:30:31.533  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35534d000-0x74a355350000	[page size compat]
2025-11-08 13:30:31.533  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a355350000-0x74a355351000	/system/lib64/aconfig_text_flags_c_lib.so
2025-11-08 13:30:31.533  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a355351000-0x74a355354000	
2025-11-08 13:30:31.533  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a355354000-0x74a355355000	[anon:.bss]
2025-11-08 13:30:31.533  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35539b000-0x74a3553a4000	/system/lib64/spatializer-aidl-cpp.so
2025-11-08 13:30:31.533  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3553a4000-0x74a3553a7000	[page size compat]
2025-11-08 13:30:31.533  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3553a7000-0x74a3553b4000	/system/lib64/spatializer-aidl-cpp.so
2025-11-08 13:30:31.533  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3553b4000-0x74a3553b7000	[page size compat]
2025-11-08 13:30:31.533  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3553b7000-0x74a3553ba000	/system/lib64/spatializer-aidl-cpp.so
2025-11-08 13:30:31.533  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3553ba000-0x74a3553bb000	
2025-11-08 13:30:31.533  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3553bb000-0x74a3553bc000	/system/lib64/spatializer-aidl-cpp.so
2025-11-08 13:30:31.533  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3553e2000-0x74a3553eb000	/system/lib64/libcutils.so
2025-11-08 13:30:31.533  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3553eb000-0x74a3553ee000	[page size compat]
2025-11-08 13:30:31.533  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3553ee000-0x74a3553f8000	/system/lib64/libcutils.so
2025-11-08 13:30:31.533  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3553f8000-0x74a3553fa000	[page size compat]
2025-11-08 13:30:31.533  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3553fa000-0x74a3553fc000	/system/lib64/libcutils.so
2025-11-08 13:30:31.533  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3553fc000-0x74a3553fe000	
2025-11-08 13:30:31.533  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3553fe000-0x74a3553ff000	/system/lib64/libcutils.so
2025-11-08 13:30:31.533  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a355400000-0x74a356600000	
2025-11-08 13:30:31.533  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356660000-0x74a356661000	/system/lib64/android.database.sqlite-aconfig-cc.so
2025-11-08 13:30:31.533  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356661000-0x74a356664000	[page size compat]
2025-11-08 13:30:31.534  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356664000-0x74a356665000	/system/lib64/android.database.sqlite-aconfig-cc.so
2025-11-08 13:30:31.534  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356665000-0x74a356668000	[page size compat]
2025-11-08 13:30:31.534  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356668000-0x74a356669000	/system/lib64/android.database.sqlite-aconfig-cc.so
2025-11-08 13:30:31.534  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356669000-0x74a35666c000	
2025-11-08 13:30:31.534  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35666c000-0x74a35666d000	[anon:.bss]
2025-11-08 13:30:31.534  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3566ac000-0x74a3566af000	/system/lib64/libhardware_legacy.so
2025-11-08 13:30:31.534  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3566af000-0x74a3566b0000	[page size compat]
2025-11-08 13:30:31.534  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3566b0000-0x74a3566b3000	/system/lib64/libhardware_legacy.so
2025-11-08 13:30:31.534  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3566b3000-0x74a3566b4000	[page size compat]
2025-11-08 13:30:31.534  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3566b4000-0x74a3566b5000	/system/lib64/libhardware_legacy.so
2025-11-08 13:30:31.534  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3566b5000-0x74a3566b8000	
2025-11-08 13:30:31.534  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3566b8000-0x74a3566b9000	/system/lib64/libhardware_legacy.so
2025-11-08 13:30:31.534  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3566c8000-0x74a3566d3000	/system/lib64/android.hardware.media.bufferpool2-V2-ndk.so
2025-11-08 13:30:31.534  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3566d3000-0x74a3566d4000	[page size compat]
2025-11-08 13:30:31.534  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3566d4000-0x74a3566dd000	/system/lib64/android.hardware.media.bufferpool2-V2-ndk.so
2025-11-08 13:30:31.534  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3566dd000-0x74a3566e0000	[page size compat]
2025-11-08 13:30:31.534  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3566e0000-0x74a3566e2000	/system/lib64/android.hardware.media.bufferpool2-V2-ndk.so
2025-11-08 13:30:31.534  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3566e2000-0x74a3566e4000	
2025-11-08 13:30:31.534  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3566e4000-0x74a3566e5000	/system/lib64/android.hardware.media.bufferpool2-V2-ndk.so
2025-11-08 13:30:31.534  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356700000-0x74a356709000	/system/lib64/liblzma.so
2025-11-08 13:30:31.534  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356709000-0x74a35670c000	[page size compat]
2025-11-08 13:30:31.534  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35670c000-0x74a35672e000	/system/lib64/liblzma.so
2025-11-08 13:30:31.534  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35672e000-0x74a356730000	[page size compat]
2025-11-08 13:30:31.534  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356730000-0x74a356731000	/system/lib64/liblzma.so
2025-11-08 13:30:31.534  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356731000-0x74a356734000	
2025-11-08 13:30:31.534  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356734000-0x74a356735000	/system/lib64/liblzma.so
2025-11-08 13:30:31.534  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356735000-0x74a356740000	[anon:.bss]
2025-11-08 13:30:31.534  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356751000-0x74a356765000	/system/lib64/android.hardware.media.c2@1.2.so
2025-11-08 13:30:31.535  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356765000-0x74a356778000	/system/lib64/android.hardware.media.c2@1.2.so
2025-11-08 13:30:31.535  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356778000-0x74a356779000	[page size compat]
2025-11-08 13:30:31.535  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356779000-0x74a35677d000	/system/lib64/android.hardware.media.c2@1.2.so
2025-11-08 13:30:31.535  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35677d000-0x74a35677e000	/system/lib64/android.hardware.media.c2@1.2.so
2025-11-08 13:30:31.535  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35679a000-0x74a3567c5000	/system/lib64/libpcre2.so
2025-11-08 13:30:31.535  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3567c5000-0x74a3567c6000	[page size compat]
2025-11-08 13:30:31.535  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3567c6000-0x74a3567fa000	/system/lib64/libpcre2.so
2025-11-08 13:30:31.535  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3567fa000-0x74a3567fb000	/system/lib64/libpcre2.so
2025-11-08 13:30:31.535  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3567fb000-0x74a3567fe000	
2025-11-08 13:30:31.535  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3567fe000-0x74a3567ff000	/system/lib64/libpcre2.so
2025-11-08 13:30:31.535  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35681a000-0x74a356828000	/system/lib64/libmedia_helper.so
2025-11-08 13:30:31.535  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356828000-0x74a35682a000	[page size compat]
2025-11-08 13:30:31.535  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35682a000-0x74a35683a000	/system/lib64/libmedia_helper.so
2025-11-08 13:30:31.535  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35683a000-0x74a35683b000	/system/lib64/libmedia_helper.so
2025-11-08 13:30:31.535  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356848000-0x74a35684c000	/system/lib64/libbpf_minimal.so
2025-11-08 13:30:31.535  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35684c000-0x74a356854000	/system/lib64/libbpf_minimal.so
2025-11-08 13:30:31.535  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356854000-0x74a356855000	/system/lib64/libbpf_minimal.so
2025-11-08 13:30:31.535  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356855000-0x74a356858000	
2025-11-08 13:30:31.535  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356858000-0x74a356859000	/system/lib64/libbpf_minimal.so
2025-11-08 13:30:31.535  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356896000-0x74a356897000	/system/lib64/libsync.so
2025-11-08 13:30:31.535  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356897000-0x74a35689a000	[page size compat]
2025-11-08 13:30:31.535  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35689a000-0x74a35689b000	/system/lib64/libsync.so
2025-11-08 13:30:31.535  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35689b000-0x74a35689e000	[page size compat]
2025-11-08 13:30:31.535  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35689e000-0x74a35689f000	/system/lib64/libsync.so
2025-11-08 13:30:31.535  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35689f000-0x74a3568a2000	
2025-11-08 13:30:31.535  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3568a2000-0x74a3568a3000	[anon:.bss]
2025-11-08 13:30:31.536  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3568f3000-0x74a3568f7000	/system/lib64/mediametricsservice-aidl-cpp.so
2025-11-08 13:30:31.536  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3568f7000-0x74a3568fa000	/system/lib64/mediametricsservice-aidl-cpp.so
2025-11-08 13:30:31.536  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3568fa000-0x74a3568fb000	[page size compat]
2025-11-08 13:30:31.536  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3568fb000-0x74a3568fd000	/system/lib64/mediametricsservice-aidl-cpp.so
2025-11-08 13:30:31.536  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3568fd000-0x74a3568ff000	
2025-11-08 13:30:31.536  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3568ff000-0x74a356900000	/system/lib64/mediametricsservice-aidl-cpp.so
2025-11-08 13:30:31.536  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356921000-0x74a35692c000	/system/lib64/android.hardware.graphics.mapper@3.0.so
2025-11-08 13:30:31.536  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35692c000-0x74a35692d000	[page size compat]
2025-11-08 13:30:31.536  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35692d000-0x74a356937000	/system/lib64/android.hardware.graphics.mapper@3.0.so
2025-11-08 13:30:31.536  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356937000-0x74a356939000	[page size compat]
2025-11-08 13:30:31.536  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356939000-0x74a35693b000	/system/lib64/android.hardware.graphics.mapper@3.0.so
2025-11-08 13:30:31.536  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35693b000-0x74a35693d000	
2025-11-08 13:30:31.536  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35693d000-0x74a35693e000	/system/lib64/android.hardware.graphics.mapper@3.0.so
2025-11-08 13:30:31.536  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356941000-0x74a356955000	/system/lib64/libnblog.so
2025-11-08 13:30:31.536  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356955000-0x74a356976000	/system/lib64/libnblog.so
2025-11-08 13:30:31.536  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356976000-0x74a356979000	[page size compat]
2025-11-08 13:30:31.536  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356979000-0x74a35697b000	/system/lib64/libnblog.so
2025-11-08 13:30:31.536  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35697b000-0x74a35697d000	
2025-11-08 13:30:31.536  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35697d000-0x74a35697e000	[anon:.bss]
2025-11-08 13:30:31.536  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356984000-0x74a356985000	/system/lib64/libstagefright_http_support.so
2025-11-08 13:30:31.536  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356985000-0x74a356988000	[page size compat]
2025-11-08 13:30:31.536  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356988000-0x74a35698a000	/system/lib64/libstagefright_http_support.so
2025-11-08 13:30:31.536  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35698a000-0x74a35698c000	[page size compat]
2025-11-08 13:30:31.536  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35698c000-0x74a35698d000	/system/lib64/libstagefright_http_support.so
2025-11-08 13:30:31.536  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3569d6000-0x74a3569d8000	/system/lib64/av-types-aidl-cpp.so
2025-11-08 13:30:31.536  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3569d8000-0x74a3569da000	[page size compat]
2025-11-08 13:30:31.536  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3569da000-0x74a3569db000	/system/lib64/av-types-aidl-cpp.so
2025-11-08 13:30:31.537  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3569db000-0x74a3569de000	[page size compat]
2025-11-08 13:30:31.537  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3569de000-0x74a3569df000	/system/lib64/av-types-aidl-cpp.so
2025-11-08 13:30:31.537  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356a0f000-0x74a356a1a000	/system/lib64/libexpat.so
2025-11-08 13:30:31.537  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356a1a000-0x74a356a1b000	[page size compat]
2025-11-08 13:30:31.537  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356a1b000-0x74a356a39000	/system/lib64/libexpat.so
2025-11-08 13:30:31.537  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356a39000-0x74a356a3b000	[page size compat]
2025-11-08 13:30:31.537  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356a3b000-0x74a356a3d000	/system/lib64/libexpat.so
2025-11-08 13:30:31.537  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356a40000-0x74a356a42000	/system/lib64/camera_platform_flags_c_lib.so
2025-11-08 13:30:31.537  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356a42000-0x74a356a44000	[page size compat]
2025-11-08 13:30:31.537  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356a44000-0x74a356a46000	/system/lib64/camera_platform_flags_c_lib.so
2025-11-08 13:30:31.537  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356a46000-0x74a356a48000	[page size compat]
2025-11-08 13:30:31.537  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356a48000-0x74a356a49000	/system/lib64/camera_platform_flags_c_lib.so
2025-11-08 13:30:31.537  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356a49000-0x74a356a4c000	
2025-11-08 13:30:31.537  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356a4c000-0x74a356a4d000	[anon:.bss]
2025-11-08 13:30:31.537  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356a86000-0x74a356a87000	/system/lib64/libandroid_net.so
2025-11-08 13:30:31.537  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356a87000-0x74a356a8a000	[page size compat]
2025-11-08 13:30:31.537  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356a8a000-0x74a356a8b000	/system/lib64/libandroid_net.so
2025-11-08 13:30:31.537  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356a8b000-0x74a356a8e000	[page size compat]
2025-11-08 13:30:31.537  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356a8e000-0x74a356a8f000	/system/lib64/libandroid_net.so
2025-11-08 13:30:31.537  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356ac1000-0x74a356aca000	/system/lib64/libcodec2_hidl_client@1.0.so
2025-11-08 13:30:31.537  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356aca000-0x74a356acd000	[page size compat]
2025-11-08 13:30:31.537  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356acd000-0x74a356adf000	/system/lib64/libcodec2_hidl_client@1.0.so
2025-11-08 13:30:31.537  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356adf000-0x74a356ae1000	[page size compat]
2025-11-08 13:30:31.537  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356ae1000-0x74a356ae2000	/system/lib64/libcodec2_hidl_client@1.0.so
2025-11-08 13:30:31.537  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356b0f000-0x74a356b54000	/system/lib64/libdng_sdk.so
2025-11-08 13:30:31.537  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356b54000-0x74a356b57000	[page size compat]
2025-11-08 13:30:31.537  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356b57000-0x74a356bd7000	/system/lib64/libdng_sdk.so
2025-11-08 13:30:31.538  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356bd7000-0x74a356bdd000	/system/lib64/libdng_sdk.so
2025-11-08 13:30:31.538  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356bdd000-0x74a356bdf000	
2025-11-08 13:30:31.538  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356bdf000-0x74a356be0000	/system/lib64/libdng_sdk.so
2025-11-08 13:30:31.538  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a356c00000-0x74a358200000	
2025-11-08 13:30:31.538  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358254000-0x74a35827a000	/system/lib64/android.hardware.media.omx@1.0.so
2025-11-08 13:30:31.538  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35827a000-0x74a35827c000	[page size compat]
2025-11-08 13:30:31.538  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35827c000-0x74a3582b0000	/system/lib64/android.hardware.media.omx@1.0.so
2025-11-08 13:30:31.538  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3582b0000-0x74a3582b8000	/system/lib64/android.hardware.media.omx@1.0.so
2025-11-08 13:30:31.538  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3582b8000-0x74a3582b9000	/system/lib64/android.hardware.media.omx@1.0.so
2025-11-08 13:30:31.538  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3582d3000-0x74a358301000	/system/lib64/libft2.so
2025-11-08 13:30:31.538  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358301000-0x74a358303000	[page size compat]
2025-11-08 13:30:31.538  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358303000-0x74a358374000	/system/lib64/libft2.so
2025-11-08 13:30:31.538  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358374000-0x74a358377000	[page size compat]
2025-11-08 13:30:31.538  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358377000-0x74a35837c000	/system/lib64/libft2.so
2025-11-08 13:30:31.538  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358388000-0x74a35838a000	/system/lib64/android.hardware.common-V2-ndk.so
2025-11-08 13:30:31.538  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35838a000-0x74a35838c000	[page size compat]
2025-11-08 13:30:31.538  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35838c000-0x74a35838d000	/system/lib64/android.hardware.common-V2-ndk.so
2025-11-08 13:30:31.538  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35838d000-0x74a358390000	[page size compat]
2025-11-08 13:30:31.538  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358390000-0x74a358391000	/system/lib64/android.hardware.common-V2-ndk.so
2025-11-08 13:30:31.538  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358391000-0x74a358394000	
2025-11-08 13:30:31.538  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358394000-0x74a358395000	/system/lib64/android.hardware.common-V2-ndk.so
2025-11-08 13:30:31.538  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3583c4000-0x74a3583d3000	/system/lib64/libbinder_ndk.so
2025-11-08 13:30:31.538  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3583d3000-0x74a3583d4000	[page size compat]
2025-11-08 13:30:31.538  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3583d4000-0x74a3583e2000	/system/lib64/libbinder_ndk.so
2025-11-08 13:30:31.538  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3583e2000-0x74a3583e4000	[page size compat]
2025-11-08 13:30:31.538  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3583e4000-0x74a3583e6000	/system/lib64/libbinder_ndk.so
2025-11-08 13:30:31.538  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3583e6000-0x74a3583e8000	
2025-11-08 13:30:31.539  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3583e8000-0x74a3583e9000	[anon:.bss]
2025-11-08 13:30:31.539  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35840d000-0x74a35840e000	/apex/com.android.runtime/lib64/bionic/libdl_android.so
2025-11-08 13:30:31.539  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35840e000-0x74a358411000	[page size compat]
2025-11-08 13:30:31.539  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358411000-0x74a358412000	/apex/com.android.runtime/lib64/bionic/libdl_android.so
2025-11-08 13:30:31.539  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358412000-0x74a358415000	[page size compat]
2025-11-08 13:30:31.539  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358415000-0x74a358416000	/apex/com.android.runtime/lib64/bionic/libdl_android.so
2025-11-08 13:30:31.539  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358446000-0x74a35845b000	/system/lib64/android.hardware.media.bufferpool@2.0.so
2025-11-08 13:30:31.539  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35845b000-0x74a35845e000	[page size compat]
2025-11-08 13:30:31.539  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35845e000-0x74a358473000	/system/lib64/android.hardware.media.bufferpool@2.0.so
2025-11-08 13:30:31.539  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358473000-0x74a358476000	[page size compat]
2025-11-08 13:30:31.539  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358476000-0x74a35847b000	/system/lib64/android.hardware.media.bufferpool@2.0.so
2025-11-08 13:30:31.539  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35847b000-0x74a35847e000	
2025-11-08 13:30:31.539  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35847e000-0x74a35847f000	/system/lib64/android.hardware.media.bufferpool@2.0.so
2025-11-08 13:30:31.539  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35848f000-0x74a358491000	/system/lib64/libstagefright_omx_utils.so
2025-11-08 13:30:31.539  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358491000-0x74a358493000	[page size compat]
2025-11-08 13:30:31.539  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358493000-0x74a358495000	/system/lib64/libstagefright_omx_utils.so
2025-11-08 13:30:31.539  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358495000-0x74a358497000	[page size compat]
2025-11-08 13:30:31.539  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358497000-0x74a358498000	/system/lib64/libstagefright_omx_utils.so
2025-11-08 13:30:31.539  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358498000-0x74a35849b000	
2025-11-08 13:30:31.539  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35849b000-0x74a35849c000	[anon:.bss]
2025-11-08 13:30:31.539  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3584cb000-0x74a3584de000	/apex/com.android.runtime/lib64/bionic/libm.so
2025-11-08 13:30:31.539  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3584de000-0x74a3584df000	[page size compat]
2025-11-08 13:30:31.539  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3584df000-0x74a35850e000	/apex/com.android.runtime/lib64/bionic/libm.so
2025-11-08 13:30:31.539  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35850e000-0x74a35850f000	[page size compat]
2025-11-08 13:30:31.539  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35850f000-0x74a358510000	/apex/com.android.runtime/lib64/bionic/libm.so
2025-11-08 13:30:31.539  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358510000-0x74a358513000	
2025-11-08 13:30:31.539  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358513000-0x74a358514000	/apex/com.android.runtime/lib64/bionic/libm.so
2025-11-08 13:30:31.539  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35854c000-0x74a35854d000	/system/lib64/com.android.media.audioclient-aconfig-cc.so
2025-11-08 13:30:31.540  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35854d000-0x74a358550000	[page size compat]
2025-11-08 13:30:31.540  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358550000-0x74a358552000	/system/lib64/com.android.media.audioclient-aconfig-cc.so
2025-11-08 13:30:31.540  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358552000-0x74a358554000	[page size compat]
2025-11-08 13:30:31.540  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358554000-0x74a358555000	/system/lib64/com.android.media.audioclient-aconfig-cc.so
2025-11-08 13:30:31.540  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358555000-0x74a358558000	
2025-11-08 13:30:31.540  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358558000-0x74a358559000	[anon:.bss]
2025-11-08 13:30:31.540  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35859d000-0x74a3585af000	/system/lib64/libGLESv3.so
2025-11-08 13:30:31.540  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3585af000-0x74a3585b1000	[page size compat]
2025-11-08 13:30:31.540  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3585b1000-0x74a3585b8000	/system/lib64/libGLESv3.so
2025-11-08 13:30:31.540  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3585b8000-0x74a3585b9000	[page size compat]
2025-11-08 13:30:31.540  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3585b9000-0x74a3585ba000	/system/lib64/libGLESv3.so
2025-11-08 13:30:31.540  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3585cf000-0x74a3585d0000	/system/lib64/libnativebridge_lazy.so
2025-11-08 13:30:31.540  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3585d0000-0x74a3585d3000	[page size compat]
2025-11-08 13:30:31.540  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3585d3000-0x74a3585d4000	/system/lib64/libnativebridge_lazy.so
2025-11-08 13:30:31.540  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3585d4000-0x74a3585d7000	[page size compat]
2025-11-08 13:30:31.540  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3585d7000-0x74a3585d8000	/system/lib64/libnativebridge_lazy.so
2025-11-08 13:30:31.540  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3585d8000-0x74a3585db000	
2025-11-08 13:30:31.540  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3585db000-0x74a3585dc000	[anon:.bss]
2025-11-08 13:30:31.540  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358605000-0x74a358688000	/system/lib64/libc++.so
2025-11-08 13:30:31.540  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358688000-0x74a35868b000	
2025-11-08 13:30:31.540  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35868b000-0x74a358700000	/system/lib64/libc++.so
2025-11-08 13:30:31.540  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358700000-0x74a358703000	
2025-11-08 13:30:31.540  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358703000-0x74a35870b000	/system/lib64/libc++.so
2025-11-08 13:30:31.541  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35870b000-0x74a35870e000	
2025-11-08 13:30:31.541  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35870e000-0x74a35870f000	/system/lib64/libc++.so
2025-11-08 13:30:31.541  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35870f000-0x74a358716000	[anon:.bss]
2025-11-08 13:30:31.541  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358719000-0x74a35878c000	/apex/com.android.tethering/javalib/framework-connectivity-t.jar
2025-11-08 13:30:31.541  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35878c000-0x74a35878f000	/system/lib64/android.hardware.graphics.common-V5-ndk.so
2025-11-08 13:30:31.541  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35878f000-0x74a358790000	[page size compat]
2025-11-08 13:30:31.541  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358790000-0x74a358793000	/system/lib64/android.hardware.graphics.common-V5-ndk.so
2025-11-08 13:30:31.541  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358793000-0x74a358794000	[page size compat]
2025-11-08 13:30:31.541  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358794000-0x74a358795000	/system/lib64/android.hardware.graphics.common-V5-ndk.so
2025-11-08 13:30:31.541  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358795000-0x74a358798000	
2025-11-08 13:30:31.541  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358798000-0x74a358799000	/system/lib64/android.hardware.graphics.common-V5-ndk.so
2025-11-08 13:30:31.541  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3587c8000-0x74a3587cd000	/system/lib64/android.system.suspend-V1-ndk.so
2025-11-08 13:30:31.541  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3587cd000-0x74a3587d0000	[page size compat]
2025-11-08 13:30:31.541  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3587d0000-0x74a3587d4000	/system/lib64/android.system.suspend-V1-ndk.so
2025-11-08 13:30:31.541  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3587d4000-0x74a3587d5000	/system/lib64/android.system.suspend-V1-ndk.so
2025-11-08 13:30:31.541  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3587d5000-0x74a3587d8000	
2025-11-08 13:30:31.541  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3587d8000-0x74a3587d9000	/system/lib64/android.system.suspend-V1-ndk.so
2025-11-08 13:30:31.541  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a358800000-0x74a359600000	
2025-11-08 13:30:31.541  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a359659000-0x74a35967e000	/system/lib64/android.hardware.drm@1.4.so
2025-11-08 13:30:31.541  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35967e000-0x74a359681000	[page size compat]
2025-11-08 13:30:31.541  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a359681000-0x74a3596a1000	/system/lib64/android.hardware.drm@1.4.so
2025-11-08 13:30:31.542  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3596a1000-0x74a3596a9000	/system/lib64/android.hardware.drm@1.4.so
2025-11-08 13:30:31.542  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3596a9000-0x74a3596aa000	/system/lib64/android.hardware.drm@1.4.so
2025-11-08 13:30:31.542  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3596de000-0x74a35970e000	/system/lib64/libmediadrm.so
2025-11-08 13:30:31.542  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35970e000-0x74a359763000	/system/lib64/libmediadrm.so
2025-11-08 13:30:31.542  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a359763000-0x74a359766000	[page size compat]
2025-11-08 13:30:31.542  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a359766000-0x74a35976b000	/system/lib64/libmediadrm.so
2025-11-08 13:30:31.542  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35976b000-0x74a35976e000	
2025-11-08 13:30:31.542  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35976e000-0x74a35976f000	/system/lib64/libmediadrm.so
2025-11-08 13:30:31.542  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a359771000-0x74a3597ea000	/apex/com.android.conscrypt/javalib/conscrypt.jar
2025-11-08 13:30:31.542  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3597ea000-0x74a3597eb000	/system/lib64/aconfig_mediacodec_flags_c_lib.so
2025-11-08 13:30:31.542  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3597eb000-0x74a3597ee000	[page size compat]
2025-11-08 13:30:31.542  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3597ee000-0x74a3597f0000	/system/lib64/aconfig_mediacodec_flags_c_lib.so
2025-11-08 13:30:31.542  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3597f0000-0x74a3597f2000	[page size compat]
2025-11-08 13:30:31.542  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3597f2000-0x74a3597f3000	/system/lib64/aconfig_mediacodec_flags_c_lib.so
2025-11-08 13:30:31.542  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3597f3000-0x74a3597f6000	
2025-11-08 13:30:31.542  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3597f6000-0x74a3597f7000	[anon:.bss]
2025-11-08 13:30:31.542  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a359800000-0x74a35a800000	
2025-11-08 13:30:31.542  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35a847000-0x74a35a876000	/apex/com.android.art/lib64/libunwindstack.so
2025-11-08 13:30:31.542  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35a876000-0x74a35a877000	[page size compat]
2025-11-08 13:30:31.542  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35a877000-0x74a35a8fd000	/apex/com.android.art/lib64/libunwindstack.so
2025-11-08 13:30:31.542  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35a8fd000-0x74a35a8ff000	[page size compat]
2025-11-08 13:30:31.542  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35a8ff000-0x74a35a907000	/apex/com.android.art/lib64/libunwindstack.so
2025-11-08 13:30:31.542  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35a907000-0x74a35a908000	/apex/com.android.art/lib64/libunwindstack.so
2025-11-08 13:30:31.542  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35a909000-0x74a35a984000	/apex/com.android.adservices/javalib/framework-adservices.jar
2025-11-08 13:30:31.542  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35a984000-0x74a35a98b000	/system/lib64/libaconfig_storage_read_api_cc.so
2025-11-08 13:30:31.542  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35a98b000-0x74a35a98c000	[page size compat]
2025-11-08 13:30:31.542  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35a98c000-0x74a35a99a000	/system/lib64/libaconfig_storage_read_api_cc.so
2025-11-08 13:30:31.543  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35a99a000-0x74a35a99c000	[page size compat]
2025-11-08 13:30:31.543  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35a99c000-0x74a35a99e000	/system/lib64/libaconfig_storage_read_api_cc.so
2025-11-08 13:30:31.543  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35a99e000-0x74a35a9a0000	
2025-11-08 13:30:31.543  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35a9a0000-0x74a35a9a1000	/system/lib64/libaconfig_storage_read_api_cc.so
2025-11-08 13:30:31.543  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35a9ea000-0x74a35a9eb000	/system/lib64/libcodec2_hidl_client@1.1.so
2025-11-08 13:30:31.543  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35a9eb000-0x74a35a9ee000	[page size compat]
2025-11-08 13:30:31.543  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35a9ee000-0x74a35a9f0000	/system/lib64/libcodec2_hidl_client@1.1.so
2025-11-08 13:30:31.543  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35a9f0000-0x74a35a9f2000	[page size compat]
2025-11-08 13:30:31.543  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35a9f2000-0x74a35a9f3000	/system/lib64/libcodec2_hidl_client@1.1.so
2025-11-08 13:30:31.543  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35aa00000-0x74a35c600000	
2025-11-08 13:30:31.543  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35c65d000-0x74a35c6ab000	/system/lib64/libbinder.so
2025-11-08 13:30:31.543  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35c6ab000-0x74a35c6ad000	[page size compat]
2025-11-08 13:30:31.543  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35c6ad000-0x74a35c70e000	/system/lib64/libbinder.so
2025-11-08 13:30:31.543  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35c70e000-0x74a35c711000	[page size compat]
2025-11-08 13:30:31.543  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35c711000-0x74a35c71f000	/system/lib64/libbinder.so
2025-11-08 13:30:31.543  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35c71f000-0x74a35c721000	
2025-11-08 13:30:31.543  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35c721000-0x74a35c722000	/system/lib64/libbinder.so
2025-11-08 13:30:31.543  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35c726000-0x74a35c786000	[anon:linker_alloc]
2025-11-08 13:30:31.543  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35c786000-0x74a35c791000	/system/lib64/libcodec2_aidl_client.so
2025-11-08 13:30:31.543  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35c791000-0x74a35c792000	[page size compat]
2025-11-08 13:30:31.543  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35c792000-0x74a35c7a7000	/system/lib64/libcodec2_aidl_client.so
2025-11-08 13:30:31.543  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35c7a7000-0x74a35c7aa000	[page size compat]
2025-11-08 13:30:31.543  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35c7aa000-0x74a35c7ab000	/system/lib64/libcodec2_aidl_client.so
2025-11-08 13:30:31.543  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35c7ab000-0x74a35c7ae000	
2025-11-08 13:30:31.543  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35c7ae000-0x74a35c7af000	[anon:.bss]
2025-11-08 13:30:31.543  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35c7d2000-0x74a35c7da000	/system/lib64/libselinux.so
2025-11-08 13:30:31.543  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35c7da000-0x74a35c7eb000	/system/lib64/libselinux.so
2025-11-08 13:30:31.543  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35c7eb000-0x74a35c7ee000	[page size compat]
2025-11-08 13:30:31.544  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35c7ee000-0x74a35c7ef000	/system/lib64/libselinux.so
2025-11-08 13:30:31.544  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35c7ef000-0x74a35c7f2000	
2025-11-08 13:30:31.544  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35c7f2000-0x74a35c7f3000	/system/lib64/libselinux.so
2025-11-08 13:30:31.544  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35c7f3000-0x74a35c7f4000	[anon:.bss]
2025-11-08 13:30:31.544  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35c800000-0x74a35fc00000	
2025-11-08 13:30:31.544  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35fc06000-0x74a35fc6f000	/apex/com.android.tzdata/etc/tz/versioned/8/tzdata
2025-11-08 13:30:31.544  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35fc6f000-0x74a35fc71000	/system/lib64/android.hidl.token@1.0-utils.so
2025-11-08 13:30:31.544  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35fc71000-0x74a35fc73000	[page size compat]
2025-11-08 13:30:31.544  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35fc73000-0x74a35fc74000	/system/lib64/android.hidl.token@1.0-utils.so
2025-11-08 13:30:31.544  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35fc74000-0x74a35fc77000	[page size compat]
2025-11-08 13:30:31.544  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35fc77000-0x74a35fc78000	/system/lib64/android.hidl.token@1.0-utils.so
2025-11-08 13:30:31.544  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35fc78000-0x74a35fc7b000	
2025-11-08 13:30:31.544  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35fc7b000-0x74a35fc7c000	[anon:.bss]
2025-11-08 13:30:31.544  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35fcb4000-0x74a35fd37000	/apex/com.android.art/lib64/libc++.so
2025-11-08 13:30:31.544  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35fd37000-0x74a35fd3a000	
2025-11-08 13:30:31.544  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35fd3a000-0x74a35fdaf000	/apex/com.android.art/lib64/libc++.so
2025-11-08 13:30:31.544  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35fdaf000-0x74a35fdb2000	
2025-11-08 13:30:31.544  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35fdb2000-0x74a35fdba000	/apex/com.android.art/lib64/libc++.so
2025-11-08 13:30:31.544  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35fdba000-0x74a35fdbd000	
2025-11-08 13:30:31.544  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35fdbd000-0x74a35fdbe000	/apex/com.android.art/lib64/libc++.so
2025-11-08 13:30:31.544  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35fdbe000-0x74a35fdc5000	[anon:.bss]
2025-11-08 13:30:31.544  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a35fe00000-0x74a363c00000	
2025-11-08 13:30:31.544  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a363c5c000-0x74a363c5d000	/system/lib64/android.hardware.camera.common@1.0.so
2025-11-08 13:30:31.544  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a363c5d000-0x74a363c60000	[page size compat]
2025-11-08 13:30:31.545  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a363c60000-0x74a363c61000	/system/lib64/android.hardware.camera.common@1.0.so
2025-11-08 13:30:31.545  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a363c61000-0x74a363c64000	[page size compat]
2025-11-08 13:30:31.545  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a363c64000-0x74a363c65000	/system/lib64/android.hardware.camera.common@1.0.so
2025-11-08 13:30:31.545  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a363c97000-0x74a363cb0000	/system/lib64/libcodec2_client.so
2025-11-08 13:30:31.545  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a363cb0000-0x74a363cb3000	[page size compat]
2025-11-08 13:30:31.545  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a363cb3000-0x74a363cde000	/system/lib64/libcodec2_client.so
2025-11-08 13:30:31.545  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a363cde000-0x74a363cdf000	[page size compat]
2025-11-08 13:30:31.545  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a363cdf000-0x74a363ce2000	/system/lib64/libcodec2_client.so
2025-11-08 13:30:31.545  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a363ce2000-0x74a363ce3000	
2025-11-08 13:30:31.545  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a363ce3000-0x74a363ce4000	[anon:.bss]
2025-11-08 13:30:31.545  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a363d11000-0x74a363d45000	/system/lib64/libcamera_client.so
2025-11-08 13:30:31.545  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a363d45000-0x74a363d98000	/system/lib64/libcamera_client.so
2025-11-08 13:30:31.545  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a363d98000-0x74a363d99000	[page size compat]
2025-11-08 13:30:31.545  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a363d99000-0x74a363da6000	/system/lib64/libcamera_client.so
2025-11-08 13:30:31.545  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a363da6000-0x74a363da9000	
2025-11-08 13:30:31.545  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a363da9000-0x74a363daa000	/system/lib64/libcamera_client.so
2025-11-08 13:30:31.545  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a363e00000-0x74a367000000	
2025-11-08 13:30:31.545  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367042000-0x74a367055000	/system/lib64/libvulkan.so
2025-11-08 13:30:31.545  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367055000-0x74a367056000	[page size compat]
2025-11-08 13:30:31.545  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367056000-0x74a367071000	/system/lib64/libvulkan.so
2025-11-08 13:30:31.545  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367071000-0x74a367072000	[page size compat]
2025-11-08 13:30:31.545  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367072000-0x74a367074000	/system/lib64/libvulkan.so
2025-11-08 13:30:31.545  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367074000-0x74a367076000	
2025-11-08 13:30:31.545  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367076000-0x74a367077000	/system/lib64/libvulkan.so
2025-11-08 13:30:31.545  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367094000-0x74a3670bc000	/system/lib64/android.hardware.drm@1.2.so
2025-11-08 13:30:31.545  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3670bc000-0x74a3670e6000	/system/lib64/android.hardware.drm@1.2.so
2025-11-08 13:30:31.545  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3670e6000-0x74a3670e8000	[page size compat]
2025-11-08 13:30:31.545  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3670e8000-0x74a3670f0000	/system/lib64/android.hardware.drm@1.2.so
2025-11-08 13:30:31.546  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3670f0000-0x74a3670f1000	/system/lib64/android.hardware.drm@1.2.so
2025-11-08 13:30:31.546  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3670fc000-0x74a3670fd000	
2025-11-08 13:30:31.546  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3670fd000-0x74a36715d000	[anon:scudo:secondary]
2025-11-08 13:30:31.546  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36715d000-0x74a36715e000	
2025-11-08 13:30:31.546  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36715e000-0x74a367164000	/system/lib64/libbpf_bcc.so
2025-11-08 13:30:31.546  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367164000-0x74a367166000	[page size compat]
2025-11-08 13:30:31.546  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367166000-0x74a36716b000	/system/lib64/libbpf_bcc.so
2025-11-08 13:30:31.546  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36716b000-0x74a36716e000	[page size compat]
2025-11-08 13:30:31.546  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36716e000-0x74a367170000	/system/lib64/libbpf_bcc.so
2025-11-08 13:30:31.546  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367170000-0x74a367172000	
2025-11-08 13:30:31.546  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367172000-0x74a367173000	/system/lib64/libbpf_bcc.so
2025-11-08 13:30:31.546  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367192000-0x74a36719a000	/system/lib64/libdmabufheap.so
2025-11-08 13:30:31.546  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36719a000-0x74a3671a5000	/system/lib64/libdmabufheap.so
2025-11-08 13:30:31.546  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3671a5000-0x74a3671a6000	[page size compat]
2025-11-08 13:30:31.546  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3671a6000-0x74a3671a7000	/system/lib64/libdmabufheap.so
2025-11-08 13:30:31.546  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3671a7000-0x74a3671aa000	
2025-11-08 13:30:31.546  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3671aa000-0x74a3671ab000	/system/lib64/libdmabufheap.so
2025-11-08 13:30:31.546  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3671da000-0x74a3671db000	/system/lib64/libmediandk_utils.so
2025-11-08 13:30:31.546  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3671db000-0x74a3671de000	[page size compat]
2025-11-08 13:30:31.546  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3671de000-0x74a3671e0000	/system/lib64/libmediandk_utils.so
2025-11-08 13:30:31.546  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3671e0000-0x74a3671e2000	[page size compat]
2025-11-08 13:30:31.546  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3671e2000-0x74a3671e3000	/system/lib64/libmediandk_utils.so
2025-11-08 13:30:31.546  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367200000-0x74a367c00000	
2025-11-08 13:30:31.546  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367c03000-0x74a367c67000	[anon:dalvik-indirect ref table]
2025-11-08 13:30:31.546  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367c67000-0x74a367c8b000	/system/lib64/libstagefright_omx.so
2025-11-08 13:30:31.547  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367c8b000-0x74a367cb2000	/system/lib64/libstagefright_omx.so
2025-11-08 13:30:31.547  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367cb2000-0x74a367cb3000	[page size compat]
2025-11-08 13:30:31.547  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367cb3000-0x74a367cb9000	/system/lib64/libstagefright_omx.so
2025-11-08 13:30:31.547  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367cb9000-0x74a367cbb000	
2025-11-08 13:30:31.547  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367cbb000-0x74a367cbc000	/system/lib64/libstagefright_omx.so
2025-11-08 13:30:31.547  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367d14000-0x74a367d22000	/system/lib64/libPlatformProperties.so
2025-11-08 13:30:31.547  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367d22000-0x74a367d24000	[page size compat]
2025-11-08 13:30:31.547  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367d24000-0x74a367d2f000	/system/lib64/libPlatformProperties.so
2025-11-08 13:30:31.547  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367d2f000-0x74a367d30000	[page size compat]
2025-11-08 13:30:31.547  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367d30000-0x74a367d31000	/system/lib64/libPlatformProperties.so
2025-11-08 13:30:31.547  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367d59000-0x74a367d60000	/system/lib64/libmeminfo.so
2025-11-08 13:30:31.547  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367d60000-0x74a367d61000	[page size compat]
2025-11-08 13:30:31.547  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367d61000-0x74a367d6f000	/system/lib64/libmeminfo.so
2025-11-08 13:30:31.547  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367d6f000-0x74a367d71000	[page size compat]
2025-11-08 13:30:31.547  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367d71000-0x74a367d72000	/system/lib64/libmeminfo.so
2025-11-08 13:30:31.547  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367d72000-0x74a367d75000	
2025-11-08 13:30:31.547  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367d75000-0x74a367d76000	[anon:.bss]
2025-11-08 13:30:31.547  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367d80000-0x74a367d81000	/system/lib64/libETC1.so
2025-11-08 13:30:31.547  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367d81000-0x74a367d84000	[page size compat]
2025-11-08 13:30:31.547  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367d84000-0x74a367d86000	/system/lib64/libETC1.so
2025-11-08 13:30:31.547  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367d86000-0x74a367d88000	[page size compat]
2025-11-08 13:30:31.547  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367d88000-0x74a367d89000	/system/lib64/libETC1.so
2025-11-08 13:30:31.547  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367dce000-0x74a367dcf000	/system/lib64/android.hardware.graphics.common@1.2.so
2025-11-08 13:30:31.547  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367dcf000-0x74a367dd2000	[page size compat]
2025-11-08 13:30:31.548  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367dd2000-0x74a367dd3000	/system/lib64/android.hardware.graphics.common@1.2.so
2025-11-08 13:30:31.548  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367dd3000-0x74a367dd6000	[page size compat]
2025-11-08 13:30:31.548  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367dd6000-0x74a367dd7000	/system/lib64/android.hardware.graphics.common@1.2.so
2025-11-08 13:30:31.548  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a367e00000-0x74a369c00000	
2025-11-08 13:30:31.548  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a369c58000-0x74a369c60000	/system/lib64/libstagefright_bufferqueue_helper.so
2025-11-08 13:30:31.548  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a369c60000-0x74a369c6d000	/system/lib64/libstagefright_bufferqueue_helper.so
2025-11-08 13:30:31.548  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a369c6d000-0x74a369c70000	[page size compat]
2025-11-08 13:30:31.548  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a369c70000-0x74a369c71000	/system/lib64/libstagefright_bufferqueue_helper.so
2025-11-08 13:30:31.548  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a369cad000-0x74a369cd3000	/system/lib64/libperfetto_c.so
2025-11-08 13:30:31.548  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a369cd3000-0x74a369cd5000	[page size compat]
2025-11-08 13:30:31.548  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a369cd5000-0x74a369d6f000	/system/lib64/libperfetto_c.so
2025-11-08 13:30:31.548  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a369d6f000-0x74a369d71000	[page size compat]
2025-11-08 13:30:31.548  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a369d71000-0x74a369d76000	/system/lib64/libperfetto_c.so
2025-11-08 13:30:31.548  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a369d76000-0x74a369d79000	
2025-11-08 13:30:31.548  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a369d79000-0x74a369d7a000	/system/lib64/libperfetto_c.so
2025-11-08 13:30:31.548  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a369d7a000-0x74a369d7b000	[anon:.bss]
2025-11-08 13:30:31.548  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a369dc2000-0x74a369dcc000	/system/lib64/android.hardware.cas.native@1.0.so
2025-11-08 13:30:31.548  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a369dcc000-0x74a369dce000	[page size compat]
2025-11-08 13:30:31.548  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a369dce000-0x74a369dd6000	/system/lib64/android.hardware.cas.native@1.0.so
2025-11-08 13:30:31.548  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a369dd6000-0x74a369dd8000	/system/lib64/android.hardware.cas.native@1.0.so
2025-11-08 13:30:31.548  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a369dd8000-0x74a369dda000	
2025-11-08 13:30:31.548  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a369dda000-0x74a369ddb000	/system/lib64/android.hardware.cas.native@1.0.so
2025-11-08 13:30:31.548  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a369de0000-0x74a369e00000	/dev/__properties__/u:object_r:graphics_config_writable_prop:s0
2025-11-08 13:30:31.548  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a369e00000-0x74a36b600000	
2025-11-08 13:30:31.548  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b602000-0x74a36b603000	
2025-11-08 13:30:31.548  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b603000-0x74a36b65f000	[anon:scudo:secondary]
2025-11-08 13:30:31.548  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b65f000-0x74a36b660000	
2025-11-08 13:30:31.549  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b660000-0x74a36b666000	/system/lib64/effect-aidl-cpp.so
2025-11-08 13:30:31.549  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b666000-0x74a36b668000	[page size compat]
2025-11-08 13:30:31.549  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b668000-0x74a36b66f000	/system/lib64/effect-aidl-cpp.so
2025-11-08 13:30:31.549  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b66f000-0x74a36b670000	[page size compat]
2025-11-08 13:30:31.549  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b670000-0x74a36b672000	/system/lib64/effect-aidl-cpp.so
2025-11-08 13:30:31.549  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b672000-0x74a36b674000	
2025-11-08 13:30:31.549  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b674000-0x74a36b675000	/system/lib64/effect-aidl-cpp.so
2025-11-08 13:30:31.549  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b691000-0x74a36b6b1000	/dev/__properties__/u:object_r:servicemanager_prop:s0
2025-11-08 13:30:31.549  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b6b1000-0x74a36b6b4000	/system/lib64/libnetd_client.so
2025-11-08 13:30:31.549  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b6b4000-0x74a36b6b5000	[page size compat]
2025-11-08 13:30:31.549  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b6b5000-0x74a36b6b9000	/system/lib64/libnetd_client.so
2025-11-08 13:30:31.549  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b6b9000-0x74a36b6ba000	/system/lib64/libnetd_client.so
2025-11-08 13:30:31.549  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b6ba000-0x74a36b6bd000	
2025-11-08 13:30:31.549  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b6bd000-0x74a36b6be000	/system/lib64/libnetd_client.so
2025-11-08 13:30:31.549  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b6c6000-0x74a36b6d5000	/system/lib64/libbase.so
2025-11-08 13:30:31.549  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b6d5000-0x74a36b6d6000	[page size compat]
2025-11-08 13:30:31.549  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b6d6000-0x74a36b6f7000	/system/lib64/libbase.so
2025-11-08 13:30:31.549  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b6f7000-0x74a36b6fa000	[page size compat]
2025-11-08 13:30:31.549  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b6fa000-0x74a36b6fb000	/system/lib64/libbase.so
2025-11-08 13:30:31.549  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b6fb000-0x74a36b6fe000	
2025-11-08 13:30:31.549  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b6fe000-0x74a36b6ff000	/system/lib64/libbase.so
2025-11-08 13:30:31.549  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b70b000-0x74a36b74d000	/system/lib64/libandroidfw.so
2025-11-08 13:30:31.549  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b74d000-0x74a36b74f000	[page size compat]
2025-11-08 13:30:31.549  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b74f000-0x74a36b7ea000	/system/lib64/libandroidfw.so
2025-11-08 13:30:31.549  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b7ea000-0x74a36b7eb000	[page size compat]
2025-11-08 13:30:31.549  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b7eb000-0x74a36b7ee000	/system/lib64/libandroidfw.so
2025-11-08 13:30:31.549  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b7ee000-0x74a36b7ef000	
2025-11-08 13:30:31.550  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b7ef000-0x74a36b7f0000	/system/lib64/libandroidfw.so
2025-11-08 13:30:31.550  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b7f2000-0x74a36b812000	[anon:dalvik-LinearAlloc]
2025-11-08 13:30:31.550  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b812000-0x74a36b814000	/system/lib64/libshmemcompat.so
2025-11-08 13:30:31.550  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b814000-0x74a36b816000	[page size compat]
2025-11-08 13:30:31.550  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b816000-0x74a36b818000	/system/lib64/libshmemcompat.so
2025-11-08 13:30:31.550  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b818000-0x74a36b81a000	[page size compat]
2025-11-08 13:30:31.550  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b81a000-0x74a36b81b000	/system/lib64/libshmemcompat.so
2025-11-08 13:30:31.550  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b821000-0x74a36b841000	/dev/__properties__/u:object_r:graphics_config_prop:s0
2025-11-08 13:30:31.550  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b841000-0x74a36b853000	/system/lib64/libstagefright_bufferpool@2.0.1.so
2025-11-08 13:30:31.550  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b853000-0x74a36b855000	[page size compat]
2025-11-08 13:30:31.550  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b855000-0x74a36b86e000	/system/lib64/libstagefright_bufferpool@2.0.1.so
2025-11-08 13:30:31.550  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b86e000-0x74a36b871000	[page size compat]
2025-11-08 13:30:31.550  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b871000-0x74a36b873000	/system/lib64/libstagefright_bufferpool@2.0.1.so
2025-11-08 13:30:31.550  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b873000-0x74a36b875000	
2025-11-08 13:30:31.550  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b875000-0x74a36b876000	[anon:.bss]
2025-11-08 13:30:31.550  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b880000-0x74a36b881000	
2025-11-08 13:30:31.550  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b881000-0x74a36b8ac000	[anon:scudo:secondary]
2025-11-08 13:30:31.550  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b8ac000-0x74a36b8ad000	
2025-11-08 13:30:31.550  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b8ad000-0x74a36b8ae000	/system/lib64/android.hardware.graphics.common@1.0.so
2025-11-08 13:30:31.550  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b8ae000-0x74a36b8b1000	[page size compat]
2025-11-08 13:30:31.550  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b8b1000-0x74a36b8b2000	/system/lib64/android.hardware.graphics.common@1.0.so
2025-11-08 13:30:31.550  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b8b2000-0x74a36b8b5000	[page size compat]
2025-11-08 13:30:31.550  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b8b5000-0x74a36b8b6000	/system/lib64/android.hardware.graphics.common@1.0.so
2025-11-08 13:30:31.550  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b8ce000-0x74a36b8d4000	/system/lib64/audioclient-types-aidl-cpp.so
2025-11-08 13:30:31.550  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b8d4000-0x74a36b8d6000	[page size compat]
2025-11-08 13:30:31.550  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b8d6000-0x74a36b8e0000	/system/lib64/audioclient-types-aidl-cpp.so
2025-11-08 13:30:31.550  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b8e0000-0x74a36b8e2000	[page size compat]
2025-11-08 13:30:31.551  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b8e2000-0x74a36b8e3000	/system/lib64/audioclient-types-aidl-cpp.so
2025-11-08 13:30:31.551  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b901000-0x74a36b913000	/system/lib64/libharfbuzz_subset.so
2025-11-08 13:30:31.551  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b913000-0x74a36b915000	[page size compat]
2025-11-08 13:30:31.551  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b915000-0x74a36b9f8000	/system/lib64/libharfbuzz_subset.so
2025-11-08 13:30:31.551  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b9f8000-0x74a36b9f9000	[page size compat]
2025-11-08 13:30:31.551  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b9f9000-0x74a36b9fa000	/system/lib64/libharfbuzz_subset.so
2025-11-08 13:30:31.551  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b9fa000-0x74a36b9fd000	
2025-11-08 13:30:31.551  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36b9fd000-0x74a36b9fe000	/system/lib64/libharfbuzz_subset.so
2025-11-08 13:30:31.551  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ba09000-0x74a36ba29000	/dev/__properties__/u:object_r:binder_cache_system_server_prop:s0
2025-11-08 13:30:31.551  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ba29000-0x74a36ba5f000	/system/lib64/libjpeg.so
2025-11-08 13:30:31.551  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ba5f000-0x74a36ba61000	[page size compat]
2025-11-08 13:30:31.551  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ba61000-0x74a36bac0000	/system/lib64/libjpeg.so
2025-11-08 13:30:31.551  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bac0000-0x74a36bac1000	[page size compat]
2025-11-08 13:30:31.551  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bac1000-0x74a36bac2000	/system/lib64/libjpeg.so
2025-11-08 13:30:31.551  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bad3000-0x74a36bb13000	[anon:dalvik-CompilerMetadata]
2025-11-08 13:30:31.551  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bb13000-0x74a36bb15000	/system/lib64/com.android.media.audio-aconfig-cc.so
2025-11-08 13:30:31.551  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bb15000-0x74a36bb17000	[page size compat]
2025-11-08 13:30:31.551  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bb17000-0x74a36bb19000	/system/lib64/com.android.media.audio-aconfig-cc.so
2025-11-08 13:30:31.551  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bb19000-0x74a36bb1b000	[page size compat]
2025-11-08 13:30:31.551  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bb1b000-0x74a36bb1c000	/system/lib64/com.android.media.audio-aconfig-cc.so
2025-11-08 13:30:31.551  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bb1c000-0x74a36bb1f000	
2025-11-08 13:30:31.551  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bb1f000-0x74a36bb20000	[anon:.bss]
2025-11-08 13:30:31.551  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bb2a000-0x74a36bb6a000	[anon:dalvik-CompilerMetadata]
2025-11-08 13:30:31.551  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bb6a000-0x74a36bb72000	/system/lib64/android.hidl.memory.token@1.0.so
2025-11-08 13:30:31.551  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bb72000-0x74a36bb78000	/system/lib64/android.hidl.memory.token@1.0.so
2025-11-08 13:30:31.551  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bb78000-0x74a36bb7a000	[page size compat]
2025-11-08 13:30:31.551  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bb7a000-0x74a36bb7c000	/system/lib64/android.hidl.memory.token@1.0.so
2025-11-08 13:30:31.552  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bb7c000-0x74a36bb7e000	
2025-11-08 13:30:31.552  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bb7e000-0x74a36bb7f000	/system/lib64/android.hidl.memory.token@1.0.so
2025-11-08 13:30:31.552  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bb80000-0x74a36bb89000	/apex/com.android.art/lib64/liblzma.so
2025-11-08 13:30:31.552  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bb89000-0x74a36bb8c000	[page size compat]
2025-11-08 13:30:31.552  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bb8c000-0x74a36bbae000	/apex/com.android.art/lib64/liblzma.so
2025-11-08 13:30:31.552  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bbae000-0x74a36bbb0000	[page size compat]
2025-11-08 13:30:31.552  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bbb0000-0x74a36bbb1000	/apex/com.android.art/lib64/liblzma.so
2025-11-08 13:30:31.552  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bbb1000-0x74a36bbb4000	
2025-11-08 13:30:31.552  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bbb4000-0x74a36bbb5000	/apex/com.android.art/lib64/liblzma.so
2025-11-08 13:30:31.552  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bbb5000-0x74a36bbc0000	[anon:.bss]
2025-11-08 13:30:31.552  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bbc5000-0x74a36bbce000	/system/lib64/libmediadrmmetrics_lite.so
2025-11-08 13:30:31.552  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bbce000-0x74a36bbd1000	[page size compat]
2025-11-08 13:30:31.552  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bbd1000-0x74a36bbdd000	/system/lib64/libmediadrmmetrics_lite.so
2025-11-08 13:30:31.552  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bbdd000-0x74a36bbde000	/system/lib64/libmediadrmmetrics_lite.so
2025-11-08 13:30:31.552  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bbde000-0x74a36bbe1000	
2025-11-08 13:30:31.552  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bbe1000-0x74a36bbe2000	/system/lib64/libmediadrmmetrics_lite.so
2025-11-08 13:30:31.552  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36bc00000-0x74a36cc00000	
2025-11-08 13:30:31.552  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36cc12000-0x74a36cc52000	[anon:dalvik-CompilerMetadata]
2025-11-08 13:30:31.552  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36cc52000-0x74a36cc58000	/system/lib64/libmedia_codeclist.so
2025-11-08 13:30:31.552  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36cc58000-0x74a36cc5a000	[page size compat]
2025-11-08 13:30:31.552  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36cc5a000-0x74a36cc61000	/system/lib64/libmedia_codeclist.so
2025-11-08 13:30:31.552  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36cc61000-0x74a36cc62000	[page size compat]
2025-11-08 13:30:31.552  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36cc62000-0x74a36cc64000	/system/lib64/libmedia_codeclist.so
2025-11-08 13:30:31.552  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36cc64000-0x74a36cc66000	
2025-11-08 13:30:31.552  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36cc66000-0x74a36cc67000	/system/lib64/libmedia_codeclist.so
2025-11-08 13:30:31.552  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36cc67000-0x74a36cca7000	[anon:dalvik-CompilerMetadata]
2025-11-08 13:30:31.553  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36cca7000-0x74a36ccec000	/apex/com.android.runtime/lib64/bionic/libc.so
2025-11-08 13:30:31.553  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ccec000-0x74a36ccef000	[page size compat]
2025-11-08 13:30:31.553  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ccef000-0x74a36cd85000	/apex/com.android.runtime/lib64/bionic/libc.so
2025-11-08 13:30:31.553  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36cd85000-0x74a36cd87000	[page size compat]
2025-11-08 13:30:31.553  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36cd87000-0x74a36cd8b000	/apex/com.android.runtime/lib64/bionic/libc.so
2025-11-08 13:30:31.553  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36cd8b000-0x74a36cd8c000	/apex/com.android.runtime/lib64/bionic/libc.so
2025-11-08 13:30:31.553  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36cd8c000-0x74a36cda3000	[anon:.bss]
2025-11-08 13:30:31.553  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36cda3000-0x74a36cda7000	[anon:.bss]
2025-11-08 13:30:31.553  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36cda7000-0x74a36cdaf000	[anon:.bss]
2025-11-08 13:30:31.553  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36cdc0000-0x74a36ce00000	[anon:dalvik-CompilerMetadata]
2025-11-08 13:30:31.553  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ce00000-0x74a36e000000	
2025-11-08 13:30:31.553  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e001000-0x74a36e041000	[anon:dalvik-CompilerMetadata]
2025-11-08 13:30:31.553  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e041000-0x74a36e046000	/system/lib64/libappfuse.so
2025-11-08 13:30:31.553  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e046000-0x74a36e049000	[page size compat]
2025-11-08 13:30:31.553  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e049000-0x74a36e050000	/system/lib64/libappfuse.so
2025-11-08 13:30:31.553  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e050000-0x74a36e051000	[page size compat]
2025-11-08 13:30:31.553  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e051000-0x74a36e052000	/system/lib64/libappfuse.so
2025-11-08 13:30:31.553  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e052000-0x74a36e055000	
2025-11-08 13:30:31.553  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e055000-0x74a36e056000	[anon:.bss]
2025-11-08 13:30:31.553  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e061000-0x74a36e081000	[anon:dalvik-CompilerMetadata]
2025-11-08 13:30:31.553  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e081000-0x74a36e089000	/system/lib64/libz.so
2025-11-08 13:30:31.553  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e089000-0x74a36e09a000	/system/lib64/libz.so
2025-11-08 13:30:31.553  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e09a000-0x74a36e09d000	[page size compat]
2025-11-08 13:30:31.553  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e09d000-0x74a36e09e000	/system/lib64/libz.so
2025-11-08 13:30:31.553  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e09e000-0x74a36e0a1000	
2025-11-08 13:30:31.553  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e0a1000-0x74a36e0a2000	[anon:.bss]
2025-11-08 13:30:31.553  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e0bb000-0x74a36e0db000	[anon:dalvik-CompilerMetadata]
2025-11-08 13:30:31.554  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e0db000-0x74a36e0e4000	/system/lib64/libSurfaceFlingerProp.so
2025-11-08 13:30:31.554  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e0e4000-0x74a36e0e7000	[page size compat]
2025-11-08 13:30:31.554  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e0e7000-0x74a36e0f1000	/system/lib64/libSurfaceFlingerProp.so
2025-11-08 13:30:31.554  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e0f1000-0x74a36e0f3000	[page size compat]
2025-11-08 13:30:31.554  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e0f3000-0x74a36e0f4000	/system/lib64/libSurfaceFlingerProp.so
2025-11-08 13:30:31.554  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e0f4000-0x74a36e0f7000	
2025-11-08 13:30:31.554  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e0f7000-0x74a36e0f8000	[anon:.bss]
2025-11-08 13:30:31.554  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e108000-0x74a36e114000	/apex/com.android.i18n/lib64/libicu.so
2025-11-08 13:30:31.554  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e114000-0x74a36e117000	/apex/com.android.i18n/lib64/libicu.so
2025-11-08 13:30:31.554  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e117000-0x74a36e118000	[page size compat]
2025-11-08 13:30:31.554  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e118000-0x74a36e119000	/apex/com.android.i18n/lib64/libicu.so
2025-11-08 13:30:31.554  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e120000-0x74a36e140000	[anon:dalvik-CompilerMetadata]
2025-11-08 13:30:31.554  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e140000-0x74a36e156000	/system/lib64/libmedia_omx.so
2025-11-08 13:30:31.554  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e156000-0x74a36e158000	[page size compat]
2025-11-08 13:30:31.554  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e158000-0x74a36e16e000	/system/lib64/libmedia_omx.so
2025-11-08 13:30:31.554  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e16e000-0x74a36e170000	[page size compat]
2025-11-08 13:30:31.554  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e170000-0x74a36e177000	/system/lib64/libmedia_omx.so
2025-11-08 13:30:31.554  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e177000-0x74a36e178000	
2025-11-08 13:30:31.554  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e178000-0x74a36e179000	/system/lib64/libmedia_omx.so
2025-11-08 13:30:31.554  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e186000-0x74a36e195000	/system/lib64/libstagefright_aidl_bufferpool2.so
2025-11-08 13:30:31.554  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e195000-0x74a36e196000	[page size compat]
2025-11-08 13:30:31.554  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e196000-0x74a36e1ac000	/system/lib64/libstagefright_aidl_bufferpool2.so
2025-11-08 13:30:31.554  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e1ac000-0x74a36e1ae000	[page size compat]
2025-11-08 13:30:31.554  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e1ae000-0x74a36e1af000	/system/lib64/libstagefright_aidl_bufferpool2.so
2025-11-08 13:30:31.554  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e1af000-0x74a36e1b2000	
2025-11-08 13:30:31.554  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e1b2000-0x74a36e1b3000	[anon:.bss]
2025-11-08 13:30:31.555  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e1c2000-0x74a36e1c5000	/system/lib64/libaudiomanager.so
2025-11-08 13:30:31.555  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e1c5000-0x74a36e1c6000	[page size compat]
2025-11-08 13:30:31.555  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e1c6000-0x74a36e1c8000	/system/lib64/libaudiomanager.so
2025-11-08 13:30:31.555  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e1c8000-0x74a36e1ca000	[page size compat]
2025-11-08 13:30:31.555  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e1ca000-0x74a36e1cb000	/system/lib64/libaudiomanager.so
2025-11-08 13:30:31.555  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e1cb000-0x74a36e1ce000	
2025-11-08 13:30:31.555  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e1ce000-0x74a36e1cf000	/system/lib64/libaudiomanager.so
2025-11-08 13:30:31.555  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e1d0000-0x74a36e1d1000	
2025-11-08 13:30:31.555  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e1d1000-0x74a36e207000	[anon:scudo:secondary]
2025-11-08 13:30:31.555  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e207000-0x74a36e208000	
2025-11-08 13:30:31.555  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e208000-0x74a36e228000	[anon:dalvik-CompilerMetadata]
2025-11-08 13:30:31.555  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e228000-0x74a36e22a000	/system/lib64/libmedia_omx_client.so
2025-11-08 13:30:31.555  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e22a000-0x74a36e22c000	[page size compat]
2025-11-08 13:30:31.555  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e22c000-0x74a36e22f000	/system/lib64/libmedia_omx_client.so
2025-11-08 13:30:31.555  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e22f000-0x74a36e230000	[page size compat]
2025-11-08 13:30:31.555  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e230000-0x74a36e231000	/system/lib64/libmedia_omx_client.so
2025-11-08 13:30:31.555  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e242000-0x74a36e262000	/dev/__properties__/u:object_r:gwp_asan_prop:s0
2025-11-08 13:30:31.555  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e262000-0x74a36e268000	/system/lib64/libmediametrics.so
2025-11-08 13:30:31.555  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e268000-0x74a36e26a000	[page size compat]
2025-11-08 13:30:31.555  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e26a000-0x74a36e275000	/system/lib64/libmediametrics.so
2025-11-08 13:30:31.555  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e275000-0x74a36e276000	[page size compat]
2025-11-08 13:30:31.555  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e276000-0x74a36e277000	/system/lib64/libmediametrics.so
2025-11-08 13:30:31.555  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e277000-0x74a36e27a000	
2025-11-08 13:30:31.555  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e27a000-0x74a36e27b000	/system/lib64/libmediametrics.so
2025-11-08 13:30:31.555  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e282000-0x74a36e283000	/system/lib64/libshmemutil.so
2025-11-08 13:30:31.555  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e283000-0x74a36e286000	[page size compat]
2025-11-08 13:30:31.555  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e286000-0x74a36e288000	/system/lib64/libshmemutil.so
2025-11-08 13:30:31.556  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e288000-0x74a36e28a000	[page size compat]
2025-11-08 13:30:31.556  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e28a000-0x74a36e28b000	/system/lib64/libshmemutil.so
2025-11-08 13:30:31.556  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e2a5000-0x74a36e2e5000	[anon:dalvik-linear-alloc page-status map]
2025-11-08 13:30:31.556  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e2e5000-0x74a36e2e9000	/system/lib64/capture_state_listener-aidl-cpp.so
2025-11-08 13:30:31.556  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e2e9000-0x74a36e2ec000	/system/lib64/capture_state_listener-aidl-cpp.so
2025-11-08 13:30:31.556  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e2ec000-0x74a36e2ed000	[page size compat]
2025-11-08 13:30:31.556  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e2ed000-0x74a36e2ef000	/system/lib64/capture_state_listener-aidl-cpp.so
2025-11-08 13:30:31.556  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e2ef000-0x74a36e2f1000	
2025-11-08 13:30:31.556  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e2f1000-0x74a36e2f2000	/system/lib64/capture_state_listener-aidl-cpp.so
2025-11-08 13:30:31.556  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e304000-0x74a36e305000	/system/lib64/libhidlallocatorutils.so
2025-11-08 13:30:31.556  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e305000-0x74a36e308000	[page size compat]
2025-11-08 13:30:31.556  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e308000-0x74a36e309000	/system/lib64/libhidlallocatorutils.so
2025-11-08 13:30:31.556  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e309000-0x74a36e30c000	[page size compat]
2025-11-08 13:30:31.556  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e30c000-0x74a36e30d000	/system/lib64/libhidlallocatorutils.so
2025-11-08 13:30:31.556  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e31a000-0x74a36e33a000	/dev/__properties__/u:object_r:device_config_memory_safety_native_prop:s0
2025-11-08 13:30:31.556  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e33a000-0x74a36e35a000	/dev/__properties__/u:object_r:lmkd_config_prop:s0
2025-11-08 13:30:31.556  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e35a000-0x74a36e362000	/system/lib64/graphicbuffersource-aidl-ndk.so
2025-11-08 13:30:31.556  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e362000-0x74a36e36e000	/system/lib64/graphicbuffersource-aidl-ndk.so
2025-11-08 13:30:31.556  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e36e000-0x74a36e36f000	/system/lib64/graphicbuffersource-aidl-ndk.so
2025-11-08 13:30:31.556  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e36f000-0x74a36e372000	
2025-11-08 13:30:31.556  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e372000-0x74a36e373000	/system/lib64/graphicbuffersource-aidl-ndk.so
2025-11-08 13:30:31.556  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e377000-0x74a36e397000	/dev/__properties__/u:object_r:zygote_wrap_prop:s0
2025-11-08 13:30:31.557  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e397000-0x74a36e398000	/system/lib64/libandroid_runtime_lazy.so
2025-11-08 13:30:31.557  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e398000-0x74a36e39b000	[page size compat]
2025-11-08 13:30:31.557  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e39b000-0x74a36e39c000	/system/lib64/libandroid_runtime_lazy.so
2025-11-08 13:30:31.557  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e39c000-0x74a36e39f000	[page size compat]
2025-11-08 13:30:31.557  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e39f000-0x74a36e3a0000	/system/lib64/libandroid_runtime_lazy.so
2025-11-08 13:30:31.557  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e3a0000-0x74a36e3a3000	
2025-11-08 13:30:31.557  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e3a3000-0x74a36e3a4000	[anon:.bss]
2025-11-08 13:30:31.557  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e3ba000-0x74a36e3df000	/apex/com.android.tzdata/etc/tz/versioned/8/icu/zoneinfo64.res
2025-11-08 13:30:31.557  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e3df000-0x74a36e3e8000	/system/lib64/android.hardware.graphics.allocator@2.0.so
2025-11-08 13:30:31.557  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e3e8000-0x74a36e3eb000	[page size compat]
2025-11-08 13:30:31.557  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e3eb000-0x74a36e3f2000	/system/lib64/android.hardware.graphics.allocator@2.0.so
2025-11-08 13:30:31.557  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e3f2000-0x74a36e3f3000	[page size compat]
2025-11-08 13:30:31.557  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e3f3000-0x74a36e3f5000	/system/lib64/android.hardware.graphics.allocator@2.0.so
2025-11-08 13:30:31.557  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e3f5000-0x74a36e3f7000	
2025-11-08 13:30:31.557  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e3f7000-0x74a36e3f8000	/system/lib64/android.hardware.graphics.allocator@2.0.so
2025-11-08 13:30:31.557  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e400000-0x74a36e46a000	/system/lib64/libinput.so
2025-11-08 13:30:31.557  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e46a000-0x74a36e46c000	[page size compat]
2025-11-08 13:30:31.557  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e46c000-0x74a36e56b000	/system/lib64/libinput.so
2025-11-08 13:30:31.557  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e56b000-0x74a36e56c000	[page size compat]
2025-11-08 13:30:31.557  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e56c000-0x74a36e57a000	/system/lib64/libinput.so
2025-11-08 13:30:31.558  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e57a000-0x74a36e57c000	
2025-11-08 13:30:31.558  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e57c000-0x74a36e580000	/system/lib64/libinput.so
2025-11-08 13:30:31.558  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e59a000-0x74a36e5ab000	/system/lib64/libpng.so
2025-11-08 13:30:31.558  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e5ab000-0x74a36e5ae000	[page size compat]
2025-11-08 13:30:31.558  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e5ae000-0x74a36e5d7000	/system/lib64/libpng.so
2025-11-08 13:30:31.558  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e5d7000-0x74a36e5da000	[page size compat]
2025-11-08 13:30:31.558  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e5da000-0x74a36e5db000	/system/lib64/libpng.so
2025-11-08 13:30:31.558  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e5e3000-0x74a36e631000	/system/usr/hyphen-data/hyph-hu.hyb
2025-11-08 13:30:31.558  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e631000-0x74a36e632000	/system/lib64/libhardware.so
2025-11-08 13:30:31.558  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e632000-0x74a36e635000	[page size compat]
2025-11-08 13:30:31.558  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e635000-0x74a36e636000	/system/lib64/libhardware.so
2025-11-08 13:30:31.558  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e636000-0x74a36e639000	[page size compat]
2025-11-08 13:30:31.558  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e639000-0x74a36e63a000	/system/lib64/libhardware.so
2025-11-08 13:30:31.558  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e64a000-0x74a36e657000	/system/lib64/libmemunreachable.so
2025-11-08 13:30:31.558  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e657000-0x74a36e65a000	[page size compat]
2025-11-08 13:30:31.558  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e65a000-0x74a36e683000	/system/lib64/libmemunreachable.so
2025-11-08 13:30:31.558  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e683000-0x74a36e686000	[page size compat]
2025-11-08 13:30:31.558  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e686000-0x74a36e68a000	/system/lib64/libmemunreachable.so
2025-11-08 13:30:31.558  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e68a000-0x74a36e68b000	/system/lib64/libmemunreachable.so
2025-11-08 13:30:31.558  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e68b000-0x74a36e6af000	/system/usr/hyphen-data/hyph-nn.hyb
2025-11-08 13:30:31.558  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e6af000-0x74a36e6d3000	/system/usr/hyphen-data/hyph-nb.hyb
2025-11-08 13:30:31.558  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e6d3000-0x74a36e70d000	/system/lib64/libharfbuzz_ng.so
2025-11-08 13:30:31.558  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e70d000-0x74a36e70f000	[page size compat]
2025-11-08 13:30:31.558  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e70f000-0x74a36e7cf000	/system/lib64/libharfbuzz_ng.so
2025-11-08 13:30:31.558  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e7cf000-0x74a36e7d0000	/system/lib64/libharfbuzz_ng.so
2025-11-08 13:30:31.558  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e7d0000-0x74a36e7d3000	
2025-11-08 13:30:31.558  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e7d3000-0x74a36e7d4000	/system/lib64/libharfbuzz_ng.so
2025-11-08 13:30:31.558  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e7f0000-0x74a36e80e000	/system/usr/hyphen-data/hyph-de-ch-1901.hyb
2025-11-08 13:30:31.559  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e80e000-0x74a36e82c000	/system/usr/hyphen-data/hyph-de-1996.hyb
2025-11-08 13:30:31.559  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e82c000-0x74a36e82d000	/system/lib64/libcodec2_hidl_client@1.2.so
2025-11-08 13:30:31.559  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e82d000-0x74a36e830000	[page size compat]
2025-11-08 13:30:31.559  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e830000-0x74a36e832000	/system/lib64/libcodec2_hidl_client@1.2.so
2025-11-08 13:30:31.559  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e832000-0x74a36e834000	[page size compat]
2025-11-08 13:30:31.559  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e834000-0x74a36e835000	/system/lib64/libcodec2_hidl_client@1.2.so
2025-11-08 13:30:31.559  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e846000-0x74a36e848000	/system/lib64/libprocinfo.so
2025-11-08 13:30:31.559  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e848000-0x74a36e84a000	[page size compat]
2025-11-08 13:30:31.559  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e84a000-0x74a36e84b000	/system/lib64/libprocinfo.so
2025-11-08 13:30:31.559  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e84b000-0x74a36e84e000	[page size compat]
2025-11-08 13:30:31.559  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e84e000-0x74a36e84f000	/system/lib64/libprocinfo.so
2025-11-08 13:30:31.559  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e865000-0x74a36e883000	/system/usr/hyphen-data/hyph-de-1901.hyb
2025-11-08 13:30:31.559  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e883000-0x74a36e8d2000	/system/lib64/libaudioclient.so
2025-11-08 13:30:31.559  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e8d2000-0x74a36e8d3000	[page size compat]
2025-11-08 13:30:31.559  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e8d3000-0x74a36e96f000	/system/lib64/libaudioclient.so
2025-11-08 13:30:31.559  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e96f000-0x74a36e97b000	/system/lib64/libaudioclient.so
2025-11-08 13:30:31.559  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e97b000-0x74a36e97c000	/system/lib64/libaudioclient.so
2025-11-08 13:30:31.559  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e987000-0x74a36e996000	/apex/com.android.art/lib64/libbase.so
2025-11-08 13:30:31.559  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e996000-0x74a36e997000	[page size compat]
2025-11-08 13:30:31.559  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e997000-0x74a36e9b8000	/apex/com.android.art/lib64/libbase.so
2025-11-08 13:30:31.559  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e9b8000-0x74a36e9bb000	[page size compat]
2025-11-08 13:30:31.559  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e9bb000-0x74a36e9bc000	/apex/com.android.art/lib64/libbase.so
2025-11-08 13:30:31.559  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e9bc000-0x74a36e9bf000	
2025-11-08 13:30:31.559  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e9bf000-0x74a36e9c0000	/apex/com.android.art/lib64/libbase.so
2025-11-08 13:30:31.559  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e9d3000-0x74a36e9d8000	/system/lib64/libdataloader.so
2025-11-08 13:30:31.559  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e9d8000-0x74a36e9db000	[page size compat]
2025-11-08 13:30:31.559  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e9db000-0x74a36e9e7000	/system/lib64/libdataloader.so
2025-11-08 13:30:31.559  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e9e7000-0x74a36e9e8000	/system/lib64/libdataloader.so
2025-11-08 13:30:31.560  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e9e8000-0x74a36e9eb000	
2025-11-08 13:30:31.560  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e9eb000-0x74a36e9ec000	[anon:.bss]
2025-11-08 13:30:31.560  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36e9fb000-0x74a36ea1b000	/dev/__properties__/u:object_r:zygote_config_prop:s0
2025-11-08 13:30:31.560  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ea1b000-0x74a36ea3b000	/dev/__properties__/u:object_r:vndk_prop:s0
2025-11-08 13:30:31.560  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ea3b000-0x74a36ea6a000	/system/lib64/libsfplugin_ccodec_utils.so
2025-11-08 13:30:31.560  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ea6a000-0x74a36ea6b000	[page size compat]
2025-11-08 13:30:31.560  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ea6b000-0x74a36eaf4000	/system/lib64/libsfplugin_ccodec_utils.so
2025-11-08 13:30:31.560  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eaf4000-0x74a36eaf7000	[page size compat]
2025-11-08 13:30:31.560  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eaf7000-0x74a36eafa000	/system/lib64/libsfplugin_ccodec_utils.so
2025-11-08 13:30:31.560  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eafa000-0x74a36eafb000	
2025-11-08 13:30:31.560  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eafb000-0x74a36eafc000	[anon:.bss]
2025-11-08 13:30:31.560  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eb10000-0x74a36eb13000	/system/lib64/libstagefright_graphicbuffersource_aidl.so
2025-11-08 13:30:31.560  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eb13000-0x74a36eb14000	[page size compat]
2025-11-08 13:30:31.560  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eb14000-0x74a36eb17000	/system/lib64/libstagefright_graphicbuffersource_aidl.so
2025-11-08 13:30:31.560  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eb17000-0x74a36eb18000	[page size compat]
2025-11-08 13:30:31.560  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eb18000-0x74a36eb19000	/system/lib64/libstagefright_graphicbuffersource_aidl.so
2025-11-08 13:30:31.560  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eb26000-0x74a36eb62000	/system_ext/framework/androidx.window.extensions.jar
2025-11-08 13:30:31.560  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eb62000-0x74a36eb69000	/system/lib64/packagemanager_aidl-cpp.so
2025-11-08 13:30:31.560  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eb69000-0x74a36eb6a000	[page size compat]
2025-11-08 13:30:31.560  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eb6a000-0x74a36eb70000	/system/lib64/packagemanager_aidl-cpp.so
2025-11-08 13:30:31.560  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eb70000-0x74a36eb72000	[page size compat]
2025-11-08 13:30:31.560  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eb72000-0x74a36eb75000	/system/lib64/packagemanager_aidl-cpp.so
2025-11-08 13:30:31.560  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eb75000-0x74a36eb76000	
2025-11-08 13:30:31.560  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eb76000-0x74a36eb77000	/system/lib64/packagemanager_aidl-cpp.so
2025-11-08 13:30:31.560  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eb83000-0x74a36eb90000	/system/lib64/libutils.so
2025-11-08 13:30:31.560  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eb90000-0x74a36eb93000	[page size compat]
2025-11-08 13:30:31.560  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eb93000-0x74a36eba2000	/system/lib64/libutils.so
2025-11-08 13:30:31.561  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eba2000-0x74a36eba3000	[page size compat]
2025-11-08 13:30:31.561  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eba3000-0x74a36eba4000	/system/lib64/libutils.so
2025-11-08 13:30:31.561  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eba4000-0x74a36eba7000	
2025-11-08 13:30:31.561  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eba7000-0x74a36eba8000	/system/lib64/libutils.so
2025-11-08 13:30:31.561  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ebb6000-0x74a36ebb7000	
2025-11-08 13:30:31.561  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ebb7000-0x74a36ebee000	[anon:scudo:secondary]
2025-11-08 13:30:31.561  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ebee000-0x74a36ebef000	
2025-11-08 13:30:31.561  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ebef000-0x74a36ebf1000	/system/lib64/libstagefright_surface_utils.so
2025-11-08 13:30:31.561  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ebf1000-0x74a36ebf3000	[page size compat]
2025-11-08 13:30:31.561  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ebf3000-0x74a36ebf6000	/system/lib64/libstagefright_surface_utils.so
2025-11-08 13:30:31.561  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ebf6000-0x74a36ebf7000	[page size compat]
2025-11-08 13:30:31.561  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ebf7000-0x74a36ebf8000	/system/lib64/libstagefright_surface_utils.so
2025-11-08 13:30:31.561  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ec04000-0x74a36ec05000	/system/lib64/android.hidl.safe_union@1.0.so
2025-11-08 13:30:31.561  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ec05000-0x74a36ec08000	[page size compat]
2025-11-08 13:30:31.561  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ec08000-0x74a36ec09000	/system/lib64/android.hidl.safe_union@1.0.so
2025-11-08 13:30:31.561  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ec09000-0x74a36ec0c000	[page size compat]
2025-11-08 13:30:31.561  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ec0c000-0x74a36ec0d000	/system/lib64/android.hidl.safe_union@1.0.so
2025-11-08 13:30:31.561  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ec1c000-0x74a36ec44000	/product/overlay/GoogleConfigOverlay.apk
2025-11-08 13:30:31.561  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ec44000-0x74a36ec52000	/system/lib64/libincfs.so
2025-11-08 13:30:31.561  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ec52000-0x74a36ec54000	[page size compat]
2025-11-08 13:30:31.561  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ec54000-0x74a36ec71000	/system/lib64/libincfs.so
2025-11-08 13:30:31.561  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ec71000-0x74a36ec74000	[page size compat]
2025-11-08 13:30:31.561  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ec74000-0x74a36ec75000	/system/lib64/libincfs.so
2025-11-08 13:30:31.561  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ec75000-0x74a36ec78000	
2025-11-08 13:30:31.562  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ec78000-0x74a36ec79000	/system/lib64/libincfs.so
2025-11-08 13:30:31.562  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ec7c000-0x74a36ec9c000	/dev/__properties__/u:object_r:vold_status_prop:s0
2025-11-08 13:30:31.562  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ec9c000-0x74a36eca2000	/system/lib64/libcodec2_hal_common.so
2025-11-08 13:30:31.562  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eca2000-0x74a36eca4000	[page size compat]
2025-11-08 13:30:31.562  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eca4000-0x74a36ecb2000	/system/lib64/libcodec2_hal_common.so
2025-11-08 13:30:31.562  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ecb2000-0x74a36ecb4000	[page size compat]
2025-11-08 13:30:31.562  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ecb4000-0x74a36ecb5000	/system/lib64/libcodec2_hal_common.so
2025-11-08 13:30:31.562  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ecb5000-0x74a36ecb8000	
2025-11-08 13:30:31.562  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ecb8000-0x74a36ecb9000	[anon:.bss]
2025-11-08 13:30:31.562  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ecc7000-0x74a36ecf9000	/system/lib64/libminikin.so
2025-11-08 13:30:31.562  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ecf9000-0x74a36ecfb000	[page size compat]
2025-11-08 13:30:31.562  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ecfb000-0x74a36ed56000	/system/lib64/libminikin.so
2025-11-08 13:30:31.562  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ed56000-0x74a36ed57000	[page size compat]
2025-11-08 13:30:31.562  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ed57000-0x74a36ed5c000	/system/lib64/libminikin.so
2025-11-08 13:30:31.562  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ed5c000-0x74a36ed5f000	
2025-11-08 13:30:31.562  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ed5f000-0x74a36ed60000	/system/lib64/libminikin.so
2025-11-08 13:30:31.562  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ed6c000-0x74a36ed8c000	/dev/__properties__/u:object_r:hdmi_config_prop:s0
2025-11-08 13:30:31.562  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ed8c000-0x74a36ed9f000	/system/lib64/libaudioutils.so
2025-11-08 13:30:31.562  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ed9f000-0x74a36eda0000	[page size compat]
2025-11-08 13:30:31.562  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eda0000-0x74a36edf8000	/system/lib64/libaudioutils.so
2025-11-08 13:30:31.562  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36edf8000-0x74a36edfa000	/system/lib64/libaudioutils.so
2025-11-08 13:30:31.562  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36edfa000-0x74a36edfc000	
2025-11-08 13:30:31.562  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36edfc000-0x74a36edfd000	[anon:.bss]
2025-11-08 13:30:31.562  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ee0b000-0x74a36ee1b000	/system/lib64/libapexsupport.so
2025-11-08 13:30:31.562  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ee1b000-0x74a36ee3a000	/system/lib64/libapexsupport.so
2025-11-08 13:30:31.563  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ee3a000-0x74a36ee3b000	[page size compat]
2025-11-08 13:30:31.563  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ee3b000-0x74a36ee3e000	/system/lib64/libapexsupport.so
2025-11-08 13:30:31.563  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ee3e000-0x74a36ee3f000	
2025-11-08 13:30:31.563  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ee3f000-0x74a36ee40000	/system/lib64/libapexsupport.so
2025-11-08 13:30:31.563  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ee40000-0x74a36ee60000	/dev/__properties__/u:object_r:packagemanager_config_prop:s0
2025-11-08 13:30:31.563  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ee60000-0x74a36ee66000	/system/lib64/libGLESv1_CM.so
2025-11-08 13:30:31.563  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ee66000-0x74a36ee68000	[page size compat]
2025-11-08 13:30:31.563  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ee68000-0x74a36ee6b000	/system/lib64/libGLESv1_CM.so
2025-11-08 13:30:31.563  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ee6b000-0x74a36ee6c000	[page size compat]
2025-11-08 13:30:31.563  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ee6c000-0x74a36ee6d000	/system/lib64/libGLESv1_CM.so
2025-11-08 13:30:31.563  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ee7d000-0x74a36ee9d000	[anon:dalvik-Pre-zygote-LinearAlloc]
2025-11-08 13:30:31.563  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ee9d000-0x74a36ee9f000	/system/lib64/libusbhost.so
2025-11-08 13:30:31.563  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ee9f000-0x74a36eea1000	[page size compat]
2025-11-08 13:30:31.563  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eea1000-0x74a36eea4000	/system/lib64/libusbhost.so
2025-11-08 13:30:31.563  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eea4000-0x74a36eea5000	[page size compat]
2025-11-08 13:30:31.563  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eea5000-0x74a36eea6000	/system/lib64/libusbhost.so
2025-11-08 13:30:31.563  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eea6000-0x74a36eec6000	/dev/__properties__/u:object_r:log_prop:s0
2025-11-08 13:30:31.563  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eec6000-0x74a36eee6000	/dev/__properties__/u:object_r:persist_wm_debug_prop:s0
2025-11-08 13:30:31.563  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eee6000-0x74a36eee7000	/system/lib64/android.hardware.common.fmq-V1-ndk.so
2025-11-08 13:30:31.563  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eee7000-0x74a36eeea000	[page size compat]
2025-11-08 13:30:31.563  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eeea000-0x74a36eeeb000	/system/lib64/android.hardware.common.fmq-V1-ndk.so
2025-11-08 13:30:31.563  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eeeb000-0x74a36eeee000	[page size compat]
2025-11-08 13:30:31.563  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eeee000-0x74a36eeef000	/system/lib64/android.hardware.common.fmq-V1-ndk.so
2025-11-08 13:30:31.563  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eeef000-0x74a36eef2000	
2025-11-08 13:30:31.563  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36eef2000-0x74a36eef3000	/system/lib64/android.hardware.common.fmq-V1-ndk.so
2025-11-08 13:30:31.563  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ef03000-0x74a36ef18000	/system/lib64/libEGL.so
2025-11-08 13:30:31.564  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ef18000-0x74a36ef1b000	[page size compat]
2025-11-08 13:30:31.564  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ef1b000-0x74a36ef3c000	/system/lib64/libEGL.so
2025-11-08 13:30:31.564  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ef3c000-0x74a36ef3f000	[page size compat]
2025-11-08 13:30:31.564  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ef3f000-0x74a36ef44000	/system/lib64/libEGL.so
2025-11-08 13:30:31.564  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ef44000-0x74a36ef47000	
2025-11-08 13:30:31.564  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ef47000-0x74a36ef48000	/system/lib64/libEGL.so
2025-11-08 13:30:31.564  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ef48000-0x74a36ef50000	[anon:.bss]
2025-11-08 13:30:31.564  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36ef51000-0x74a36efb5000	[anon:dalvik-indirect ref table]
2025-11-08 13:30:31.564  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36efb5000-0x74a36efb8000	/system/lib64/audiopolicy-types-aidl-cpp.so
2025-11-08 13:30:31.564  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36efb8000-0x74a36efb9000	[page size compat]
2025-11-08 13:30:31.564  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36efb9000-0x74a36efbd000	/system/lib64/audiopolicy-types-aidl-cpp.so
2025-11-08 13:30:31.564  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36efbd000-0x74a36efbe000	/system/lib64/audiopolicy-types-aidl-cpp.so
2025-11-08 13:30:31.564  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36efc2000-0x74a36efc3000	/system/lib64/android.hardware.media@1.0.so
2025-11-08 13:30:31.564  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36efc3000-0x74a36efc6000	[page size compat]
2025-11-08 13:30:31.564  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36efc6000-0x74a36efc7000	/system/lib64/android.hardware.media@1.0.so
2025-11-08 13:30:31.564  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36efc7000-0x74a36efca000	[page size compat]
2025-11-08 13:30:31.564  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36efca000-0x74a36efcb000	/system/lib64/android.hardware.media@1.0.so
2025-11-08 13:30:31.564  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36efcc000-0x74a36f017000	/system/fonts/RobotoStatic-Regular.ttf
2025-11-08 13:30:31.564  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f017000-0x74a36f03b000	/system/lib64/libui.so
2025-11-08 13:30:31.564  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f03b000-0x74a36f068000	/system/lib64/libui.so
2025-11-08 13:30:31.564  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f068000-0x74a36f06b000	[page size compat]
2025-11-08 13:30:31.564  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f06b000-0x74a36f06e000	/system/lib64/libui.so
2025-11-08 13:30:31.564  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f06e000-0x74a36f06f000	
2025-11-08 13:30:31.564  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f06f000-0x74a36f071000	[anon:.bss]
2025-11-08 13:30:31.564  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f072000-0x74a36f089000	/data/app/~~EApFJKn0TYks1NB7znMWgA==/com.oearth.androioearth01-kkGgvQ6-x5_Ioed2KatziA==/base.apk
2025-11-08 13:30:31.564  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f089000-0x74a36f09b000	/system/lib64/android.hardware.media.c2@1.1.so
2025-11-08 13:30:31.564  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f09b000-0x74a36f09d000	[page size compat]
2025-11-08 13:30:31.565  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f09d000-0x74a36f0af000	/system/lib64/android.hardware.media.c2@1.1.so
2025-11-08 13:30:31.565  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f0af000-0x74a36f0b1000	[page size compat]
2025-11-08 13:30:31.565  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f0b1000-0x74a36f0b5000	/system/lib64/android.hardware.media.c2@1.1.so
2025-11-08 13:30:31.565  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f0b5000-0x74a36f0b6000	/system/lib64/android.hardware.media.c2@1.1.so
2025-11-08 13:30:31.565  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f0ba000-0x74a36f0bb000	
2025-11-08 13:30:31.565  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f0bb000-0x74a36f0ec000	[anon:scudo:secondary]
2025-11-08 13:30:31.565  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f0ec000-0x74a36f0ed000	
2025-11-08 13:30:31.565  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f0ed000-0x74a36f0ee000	/system/lib64/shared-file-region-aidl-cpp.so
2025-11-08 13:30:31.565  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f0ee000-0x74a36f0f1000	[page size compat]
2025-11-08 13:30:31.565  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f0f1000-0x74a36f0f3000	/system/lib64/shared-file-region-aidl-cpp.so
2025-11-08 13:30:31.565  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f0f3000-0x74a36f0f5000	[page size compat]
2025-11-08 13:30:31.565  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f0f5000-0x74a36f0f6000	/system/lib64/shared-file-region-aidl-cpp.so
2025-11-08 13:30:31.565  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f101000-0x74a36f121000	/dev/__properties__/u:object_r:config_prop:s0
2025-11-08 13:30:31.565  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f121000-0x74a36f15f000	/system/lib64/libhidlbase.so
2025-11-08 13:30:31.565  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f15f000-0x74a36f161000	[page size compat]
2025-11-08 13:30:31.565  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f161000-0x74a36f1ad000	/system/lib64/libhidlbase.so
2025-11-08 13:30:31.565  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f1ad000-0x74a36f1b8000	/system/lib64/libhidlbase.so
2025-11-08 13:30:31.565  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f1b8000-0x74a36f1b9000	
2025-11-08 13:30:31.565  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f1b9000-0x74a36f1ba000	/system/lib64/libhidlbase.so
2025-11-08 13:30:31.565  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f1ca000-0x74a36f1ea000	[anon:dalvik-Pre-zygote-LinearAlloc]
2025-11-08 13:30:31.565  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f1ea000-0x74a36f1ef000	/system/lib64/libstagefright_codecbase.so
2025-11-08 13:30:31.565  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f1ef000-0x74a36f1f2000	[page size compat]
2025-11-08 13:30:31.565  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f1f2000-0x74a36f1f6000	/system/lib64/libstagefright_codecbase.so
2025-11-08 13:30:31.565  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f1f6000-0x74a36f1f7000	/system/lib64/libstagefright_codecbase.so
2025-11-08 13:30:31.565  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f1fb000-0x74a36f21b000	/dev/__properties__/u:object_r:telephony_config_prop:s0
2025-11-08 13:30:31.566  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f21b000-0x74a36f228000	/system/lib64/android.hardware.graphics.mapper@4.0.so
2025-11-08 13:30:31.566  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f228000-0x74a36f22b000	[page size compat]
2025-11-08 13:30:31.566  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f22b000-0x74a36f239000	/system/lib64/android.hardware.graphics.mapper@4.0.so
2025-11-08 13:30:31.566  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f239000-0x74a36f23b000	[page size compat]
2025-11-08 13:30:31.566  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f23b000-0x74a36f23d000	/system/lib64/android.hardware.graphics.mapper@4.0.so
2025-11-08 13:30:31.566  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f23d000-0x74a36f23f000	
2025-11-08 13:30:31.566  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f23f000-0x74a36f240000	/system/lib64/android.hardware.graphics.mapper@4.0.so
2025-11-08 13:30:31.566  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f240000-0x74a36f255000	/system/lib64/android.hardware.camera.device@3.2.so
2025-11-08 13:30:31.566  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f255000-0x74a36f258000	[page size compat]
2025-11-08 13:30:31.566  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f258000-0x74a36f26f000	/system/lib64/android.hardware.camera.device@3.2.so
2025-11-08 13:30:31.566  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f26f000-0x74a36f270000	[page size compat]
2025-11-08 13:30:31.566  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f270000-0x74a36f274000	/system/lib64/android.hardware.camera.device@3.2.so
2025-11-08 13:30:31.566  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f274000-0x74a36f275000	/system/lib64/android.hardware.camera.device@3.2.so
2025-11-08 13:30:31.566  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f283000-0x74a36f299000	/system/lib64/libmediandk.so
2025-11-08 13:30:31.566  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f299000-0x74a36f29b000	[page size compat]
2025-11-08 13:30:31.566  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f29b000-0x74a36f2b9000	/system/lib64/libmediandk.so
2025-11-08 13:30:31.566  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f2b9000-0x74a36f2bb000	[page size compat]
2025-11-08 13:30:31.566  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f2bb000-0x74a36f2bd000	/system/lib64/libmediandk.so
2025-11-08 13:30:31.566  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f2bd000-0x74a36f2bf000	
2025-11-08 13:30:31.566  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f2bf000-0x74a36f2c0000	/system/lib64/libmediandk.so
2025-11-08 13:30:31.566  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f2d6000-0x74a36f2df000	/system/lib64/libpermission.so
2025-11-08 13:30:31.566  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f2df000-0x74a36f2e2000	[page size compat]
2025-11-08 13:30:31.566  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f2e2000-0x74a36f2e8000	/system/lib64/libpermission.so
2025-11-08 13:30:31.566  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f2e8000-0x74a36f2ea000	[page size compat]
2025-11-08 13:30:31.566  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f2ea000-0x74a36f2ed000	/system/lib64/libpermission.so
2025-11-08 13:30:31.566  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f2ed000-0x74a36f2ee000	
2025-11-08 13:30:31.566  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f2ee000-0x74a36f2ef000	/system/lib64/libpermission.so
2025-11-08 13:30:31.567  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f2f4000-0x74a36f304000	[anon:AppendToErrorMessageBuffer]
2025-11-08 13:30:31.567  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f304000-0x74a36f30c000	/system/lib64/libaudiopolicy.so
2025-11-08 13:30:31.567  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f30c000-0x74a36f31b000	/system/lib64/libaudiopolicy.so
2025-11-08 13:30:31.567  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f31b000-0x74a36f31c000	[page size compat]
2025-11-08 13:30:31.567  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f31c000-0x74a36f31d000	/system/lib64/libaudiopolicy.so
2025-11-08 13:30:31.567  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f32c000-0x74a36f34c000	[anon:dalvik-Pre-zygote-LinearAlloc]
2025-11-08 13:30:31.567  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f34c000-0x74a36f351000	/system/lib64/framework-permission-aidl-cpp.so
2025-11-08 13:30:31.567  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f351000-0x74a36f354000	[page size compat]
2025-11-08 13:30:31.567  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f354000-0x74a36f357000	/system/lib64/framework-permission-aidl-cpp.so
2025-11-08 13:30:31.567  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f357000-0x74a36f358000	[page size compat]
2025-11-08 13:30:31.567  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f358000-0x74a36f35a000	/system/lib64/framework-permission-aidl-cpp.so
2025-11-08 13:30:31.567  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f35a000-0x74a36f35c000	
2025-11-08 13:30:31.567  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f35c000-0x74a36f35d000	/system/lib64/framework-permission-aidl-cpp.so
2025-11-08 13:30:31.567  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f36b000-0x74a36f38b000	/dev/__properties__/u:object_r:media_variant_prop:s0
2025-11-08 13:30:31.567  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f38b000-0x74a36f3a4000	/system/lib64/libwilhelm.so
2025-11-08 13:30:31.567  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f3a4000-0x74a36f3a7000	[page size compat]
2025-11-08 13:30:31.567  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f3a7000-0x74a36f3c7000	/system/lib64/libwilhelm.so
2025-11-08 13:30:31.567  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f3c7000-0x74a36f3cc000	/system/lib64/libwilhelm.so
2025-11-08 13:30:31.567  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f3cc000-0x74a36f3cf000	
2025-11-08 13:30:31.567  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f3cf000-0x74a36f3d0000	[anon:.bss]
2025-11-08 13:30:31.567  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f3d0000-0x74a36f3e0000	[anon:Allocate]
2025-11-08 13:30:31.567  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f3e0000-0x74a36f400000	/dev/__properties__/u:object_r:camera_config_prop:s0
2025-11-08 13:30:31.567  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a36f400000-0x74a370600000	
2025-11-08 13:30:31.567  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37060c000-0x74a37062c000	/dev/__properties__/u:object_r:use_memfd_prop:s0
2025-11-08 13:30:31.567  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37062c000-0x74a37064c000	/dev/__properties__/u:object_r:surfaceflinger_prop:s0
2025-11-08 13:30:31.567  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37064c000-0x74a370655000	/system/lib64/libimg_utils.so
2025-11-08 13:30:31.567  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a370655000-0x74a370658000	[page size compat]
2025-11-08 13:30:31.568  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a370658000-0x74a370668000	/system/lib64/libimg_utils.so
2025-11-08 13:30:31.568  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a370668000-0x74a37066a000	/system/lib64/libimg_utils.so
2025-11-08 13:30:31.568  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37066a000-0x74a37066c000	
2025-11-08 13:30:31.568  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37066c000-0x74a37066d000	[anon:.bss]
2025-11-08 13:30:31.568  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a370679000-0x74a370699000	[anon:dalvik-Pre-zygote-LinearAlloc]
2025-11-08 13:30:31.568  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a370699000-0x74a370738000	/system/lib64/libstagefright.so
2025-11-08 13:30:31.568  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a370738000-0x74a370739000	[page size compat]
2025-11-08 13:30:31.568  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a370739000-0x74a3708a9000	/system/lib64/libstagefright.so
2025-11-08 13:30:31.568  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3708a9000-0x74a3708ba000	/system/lib64/libstagefright.so
2025-11-08 13:30:31.568  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3708ba000-0x74a3708bd000	
2025-11-08 13:30:31.568  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3708bd000-0x74a3708be000	/system/lib64/libstagefright.so
2025-11-08 13:30:31.568  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3708c8000-0x74a3708cc000	
2025-11-08 13:30:31.568  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3708cc000-0x74a3708d4000	[anon:thread signal stack]
2025-11-08 13:30:31.568  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3708d4000-0x74a370914000	[anon:dalvik-Pre-zygote-LinearAlloc]
2025-11-08 13:30:31.568  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a370914000-0x74a37091a000	/system/lib64/libcamera_metadata.so
2025-11-08 13:30:31.568  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37091a000-0x74a37091c000	[page size compat]
2025-11-08 13:30:31.568  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37091c000-0x74a370922000	/system/lib64/libcamera_metadata.so
2025-11-08 13:30:31.568  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a370922000-0x74a370924000	[page size compat]
2025-11-08 13:30:31.568  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a370924000-0x74a370925000	/system/lib64/libcamera_metadata.so
2025-11-08 13:30:31.568  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a370925000-0x74a370928000	
2025-11-08 13:30:31.568  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a370928000-0x74a37092a000	/system/lib64/libcamera_metadata.so
2025-11-08 13:30:31.568  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a370934000-0x74a370938000	
2025-11-08 13:30:31.568  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a370938000-0x74a370940000	[anon:thread signal stack]
2025-11-08 13:30:31.568  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a370940000-0x74a370953000	/system/lib64/android.hardware.drm-V1-ndk.so
2025-11-08 13:30:31.569  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a370953000-0x74a370954000	[page size compat]
2025-11-08 13:30:31.569  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a370954000-0x74a37096c000	/system/lib64/android.hardware.drm-V1-ndk.so
2025-11-08 13:30:31.569  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37096c000-0x74a37096e000	/system/lib64/android.hardware.drm-V1-ndk.so
2025-11-08 13:30:31.569  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37096e000-0x74a370970000	
2025-11-08 13:30:31.569  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a370970000-0x74a370971000	/system/lib64/android.hardware.drm-V1-ndk.so
2025-11-08 13:30:31.569  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a370976000-0x74a37097a000	
2025-11-08 13:30:31.569  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37097a000-0x74a370982000	[anon:thread signal stack]
2025-11-08 13:30:31.569  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a370982000-0x74a370984000	/system/lib64/libspeexresampler.so
2025-11-08 13:30:31.569  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a370984000-0x74a370986000	[page size compat]
2025-11-08 13:30:31.569  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a370986000-0x74a370988000	/system/lib64/libspeexresampler.so
2025-11-08 13:30:31.569  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a370988000-0x74a37098a000	[page size compat]
2025-11-08 13:30:31.569  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37098a000-0x74a37098b000	/system/lib64/libspeexresampler.so
2025-11-08 13:30:31.569  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a370995000-0x74a3709b5000	/dev/__properties__/u:object_r:build_odm_prop:s0
2025-11-08 13:30:31.569  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3709b5000-0x74a3709d5000	[anon:dalvik-Pre-zygote-LinearAlloc]
2025-11-08 13:30:31.569  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3709d5000-0x74a3709e7000	/system/lib64/libGLESv2.so
2025-11-08 13:30:31.569  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3709e7000-0x74a3709e9000	[page size compat]
2025-11-08 13:30:31.569  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3709e9000-0x74a3709f0000	/system/lib64/libGLESv2.so
2025-11-08 13:30:31.569  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3709f0000-0x74a3709f1000	[page size compat]
2025-11-08 13:30:31.569  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3709f1000-0x74a3709f2000	/system/lib64/libGLESv2.so
2025-11-08 13:30:31.569  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3709f4000-0x74a3709f8000	
2025-11-08 13:30:31.570  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3709f8000-0x74a370a00000	[anon:thread signal stack]
2025-11-08 13:30:31.570  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a370a00000-0x74a371e00000	
2025-11-08 13:30:31.570  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371e01000-0x74a371e61000	[anon:linker_alloc]
2025-11-08 13:30:31.570  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371e61000-0x74a371e62000	/system/lib64/android.hardware.configstore-utils.so
2025-11-08 13:30:31.570  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371e62000-0x74a371e65000	[page size compat]
2025-11-08 13:30:31.570  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371e65000-0x74a371e66000	/system/lib64/android.hardware.configstore-utils.so
2025-11-08 13:30:31.570  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371e66000-0x74a371e69000	[page size compat]
2025-11-08 13:30:31.570  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371e69000-0x74a371e6a000	/system/lib64/android.hardware.configstore-utils.so
2025-11-08 13:30:31.570  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371e6d000-0x74a371e71000	
2025-11-08 13:30:31.570  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371e71000-0x74a371e79000	[anon:thread signal stack]
2025-11-08 13:30:31.570  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371e79000-0x74a371e7d000	
2025-11-08 13:30:31.570  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371e7d000-0x74a371e85000	[anon:thread signal stack]
2025-11-08 13:30:31.570  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371e85000-0x74a371e8a000	/system/lib64/liblog.so
2025-11-08 13:30:31.570  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371e8a000-0x74a371e8d000	[page size compat]
2025-11-08 13:30:31.570  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371e8d000-0x74a371e96000	/system/lib64/liblog.so
2025-11-08 13:30:31.570  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371e96000-0x74a371e99000	[page size compat]
2025-11-08 13:30:31.570  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371e99000-0x74a371e9a000	/system/lib64/liblog.so
2025-11-08 13:30:31.570  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371e9a000-0x74a371e9d000	
2025-11-08 13:30:31.570  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371e9d000-0x74a371e9e000	/system/lib64/liblog.so
2025-11-08 13:30:31.570  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371ea1000-0x74a371ec1000	[anon:dalvik-Pre-zygote-LinearAlloc]
2025-11-08 13:30:31.570  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371ec1000-0x74a371ee1000	/dev/__properties__/u:object_r:framework_status_prop:s0
2025-11-08 13:30:31.570  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371ee1000-0x74a371ee4000	/system/lib64/libtimeinstate.so
2025-11-08 13:30:31.570  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371ee4000-0x74a371ee5000	[page size compat]
2025-11-08 13:30:31.570  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371ee5000-0x74a371eef000	/system/lib64/libtimeinstate.so
2025-11-08 13:30:31.570  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371eef000-0x74a371ef1000	[page size compat]
2025-11-08 13:30:31.570  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371ef1000-0x74a371ef2000	/system/lib64/libtimeinstate.so
2025-11-08 13:30:31.570  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371ef2000-0x74a371ef5000	
2025-11-08 13:30:31.571  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371ef5000-0x74a371ef6000	[anon:.bss]
2025-11-08 13:30:31.571  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371f00000-0x74a371f04000	
2025-11-08 13:30:31.571  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371f04000-0x74a371f0c000	[anon:thread signal stack]
2025-11-08 13:30:31.571  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371f0c000-0x74a371f2c000	[anon:dalvik-CompilerMetadata]
2025-11-08 13:30:31.571  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371f2c000-0x74a371f30000	/system/lib64/lib-platform-compat-native-api.so
2025-11-08 13:30:31.571  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371f30000-0x74a371f32000	/system/lib64/lib-platform-compat-native-api.so
2025-11-08 13:30:31.571  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371f32000-0x74a371f34000	[page size compat]
2025-11-08 13:30:31.571  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371f34000-0x74a371f36000	/system/lib64/lib-platform-compat-native-api.so
2025-11-08 13:30:31.571  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371f36000-0x74a371f38000	
2025-11-08 13:30:31.571  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371f38000-0x74a371f39000	/system/lib64/lib-platform-compat-native-api.so
2025-11-08 13:30:31.571  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371f3e000-0x74a371f49000	/apex/com.android.tzdata/etc/tz/versioned/8/icu/metaZones.res
2025-11-08 13:30:31.571  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371f49000-0x74a371f69000	[anon:dalvik-CompilerMetadata]
2025-11-08 13:30:31.571  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371f69000-0x74a371f7b000	/system/lib64/libaudiofoundation.so
2025-11-08 13:30:31.571  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371f7b000-0x74a371f7d000	[page size compat]
2025-11-08 13:30:31.571  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371f7d000-0x74a371fad000	/system/lib64/libaudiofoundation.so
2025-11-08 13:30:31.571  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371fad000-0x74a371faf000	/system/lib64/libaudiofoundation.so
2025-11-08 13:30:31.571  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371faf000-0x74a371fb1000	
2025-11-08 13:30:31.571  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371fb1000-0x74a371fb2000	[anon:.bss]
2025-11-08 13:30:31.571  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371fb5000-0x74a371fc7000	/system/usr/hyphen-data/hyph-sv.hyb
2025-11-08 13:30:31.571  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371fc7000-0x74a371fcc000	/system/lib64/libheif.so
2025-11-08 13:30:31.571  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371fcc000-0x74a371fcf000	[page size compat]
2025-11-08 13:30:31.571  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371fcf000-0x74a371fd4000	/system/lib64/libheif.so
2025-11-08 13:30:31.571  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371fd4000-0x74a371fd7000	[page size compat]
2025-11-08 13:30:31.571  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371fd7000-0x74a371fd8000	/system/lib64/libheif.so
2025-11-08 13:30:31.571  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a371fe0000-0x74a372005000	/apex/com.android.tzdata/etc/tz/versioned/8/icu/zoneinfo64.res
2025-11-08 13:30:31.571  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372005000-0x74a37200e000	/system/lib64/android.media.audio.common.types-V3-cpp.so
2025-11-08 13:30:31.572  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37200e000-0x74a372011000	[page size compat]
2025-11-08 13:30:31.572  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372011000-0x74a37201d000	/system/lib64/android.media.audio.common.types-V3-cpp.so
2025-11-08 13:30:31.572  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37201d000-0x74a37201e000	/system/lib64/android.media.audio.common.types-V3-cpp.so
2025-11-08 13:30:31.572  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37201e000-0x74a37201f000	
2025-11-08 13:30:31.572  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37201f000-0x74a37203b000	[anon:scudo:secondary]
2025-11-08 13:30:31.572  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37203b000-0x74a37203c000	
2025-11-08 13:30:31.572  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37203c000-0x74a37205c000	/dev/__properties__/u:object_r:exported_default_prop:s0
2025-11-08 13:30:31.572  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37205c000-0x74a372076000	/system/lib64/libaudioclient_aidl_conversion.so
2025-11-08 13:30:31.572  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372076000-0x74a372078000	[page size compat]
2025-11-08 13:30:31.572  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372078000-0x74a3720b3000	/system/lib64/libaudioclient_aidl_conversion.so
2025-11-08 13:30:31.572  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3720b3000-0x74a3720b4000	[page size compat]
2025-11-08 13:30:31.572  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3720b4000-0x74a3720b6000	/system/lib64/libaudioclient_aidl_conversion.so
2025-11-08 13:30:31.572  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3720b6000-0x74a3720b8000	
2025-11-08 13:30:31.572  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3720b8000-0x74a3720b9000	[anon:.bss]
2025-11-08 13:30:31.572  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3720bc000-0x74a3720c2000	/apex/com.android.tzdata/etc/tz/versioned/8/icu/windowsZones.res
2025-11-08 13:30:31.572  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3720c2000-0x74a3720e2000	[anon:dalvik-LinearAlloc]
2025-11-08 13:30:31.572  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3720e2000-0x74a3720e3000	/system/lib64/libion.so
2025-11-08 13:30:31.572  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3720e3000-0x74a3720e6000	[page size compat]
2025-11-08 13:30:31.572  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3720e6000-0x74a3720e7000	/system/lib64/libion.so
2025-11-08 13:30:31.572  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3720e7000-0x74a3720ea000	[page size compat]
2025-11-08 13:30:31.572  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3720ea000-0x74a3720eb000	/system/lib64/libion.so
2025-11-08 13:30:31.572  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3720eb000-0x74a3720ee000	
2025-11-08 13:30:31.572  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3720ee000-0x74a3720ef000	[anon:.bss]
2025-11-08 13:30:31.572  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3720f3000-0x74a372106000	/system/usr/hyphen-data/hyph-nl.hyb
2025-11-08 13:30:31.572  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372106000-0x74a372115000	/system/lib64/libbase.so
2025-11-08 13:30:31.572  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372115000-0x74a372116000	[page size compat]
2025-11-08 13:30:31.572  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372116000-0x74a372137000	/system/lib64/libbase.so
2025-11-08 13:30:31.573  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372137000-0x74a37213a000	[page size compat]
2025-11-08 13:30:31.573  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37213a000-0x74a37213b000	/system/lib64/libbase.so
2025-11-08 13:30:31.573  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37213b000-0x74a37213e000	
2025-11-08 13:30:31.573  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37213e000-0x74a37213f000	/system/lib64/libbase.so
2025-11-08 13:30:31.573  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372142000-0x74a372164000	/system/lib64/android.hardware.drm@1.0.so
2025-11-08 13:30:31.573  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372164000-0x74a372166000	[page size compat]
2025-11-08 13:30:31.573  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372166000-0x74a372197000	/system/lib64/android.hardware.drm@1.0.so
2025-11-08 13:30:31.573  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372197000-0x74a37219a000	[page size compat]
2025-11-08 13:30:31.573  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37219a000-0x74a3721a1000	/system/lib64/android.hardware.drm@1.0.so
2025-11-08 13:30:31.573  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3721a1000-0x74a3721a2000	
2025-11-08 13:30:31.573  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3721a2000-0x74a3721a3000	/system/lib64/android.hardware.drm@1.0.so
2025-11-08 13:30:31.573  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3721a3000-0x74a3721a9000	/apex/com.android.tzdata/etc/tz/versioned/8/icu/timezoneTypes.res
2025-11-08 13:30:31.573  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3721a9000-0x74a3721c9000	/dev/__properties__/u:object_r:radio_prop:s0
2025-11-08 13:30:31.573  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3721c9000-0x74a3721d0000	/system/lib64/libgraphicsenv.so
2025-11-08 13:30:31.573  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3721d0000-0x74a3721d1000	[page size compat]
2025-11-08 13:30:31.573  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3721d1000-0x74a3721d7000	/system/lib64/libgraphicsenv.so
2025-11-08 13:30:31.573  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3721d7000-0x74a3721d9000	[page size compat]
2025-11-08 13:30:31.573  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3721d9000-0x74a3721db000	/system/lib64/libgraphicsenv.so
2025-11-08 13:30:31.573  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3721db000-0x74a3721dd000	
2025-11-08 13:30:31.573  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3721dd000-0x74a3721de000	/system/lib64/libgraphicsenv.so
2025-11-08 13:30:31.573  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3721df000-0x74a3721ff000	/dev/__properties__/u:object_r:bootloader_prop:s0
2025-11-08 13:30:31.573  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3721ff000-0x74a37221f000	/dev/__properties__/u:object_r:soc_prop:s0
2025-11-08 13:30:31.573  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37221f000-0x74a372221000	/apex/com.android.art/lib64/libnativebridge.so
2025-11-08 13:30:31.573  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372221000-0x74a372223000	[page size compat]
2025-11-08 13:30:31.573  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372223000-0x74a372225000	/apex/com.android.art/lib64/libnativebridge.so
2025-11-08 13:30:31.573  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372225000-0x74a372227000	[page size compat]
2025-11-08 13:30:31.573  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372227000-0x74a372228000	/apex/com.android.art/lib64/libnativebridge.so
2025-11-08 13:30:31.574  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372228000-0x74a37222b000	
2025-11-08 13:30:31.574  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37222b000-0x74a37222c000	[anon:.bss]
2025-11-08 13:30:31.574  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37222c000-0x74a37223c000	/system/usr/hyphen-data/hyph-sk.hyb
2025-11-08 13:30:31.574  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37223c000-0x74a372246000	/system/usr/hyphen-data/hyph-lv.hyb
2025-11-08 13:30:31.574  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372246000-0x74a37224e000	/system/lib64/android.hardware.memtrack@1.0.so
2025-11-08 13:30:31.574  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37224e000-0x74a372255000	/system/lib64/android.hardware.memtrack@1.0.so
2025-11-08 13:30:31.574  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372255000-0x74a372256000	[page size compat]
2025-11-08 13:30:31.574  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372256000-0x74a372258000	/system/lib64/android.hardware.memtrack@1.0.so
2025-11-08 13:30:31.574  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372258000-0x74a37225a000	
2025-11-08 13:30:31.574  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37225a000-0x74a37225b000	/system/lib64/android.hardware.memtrack@1.0.so
2025-11-08 13:30:31.574  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372260000-0x74a372280000	/dev/__properties__/u:object_r:build_vendor_prop:s0
2025-11-08 13:30:31.574  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372280000-0x74a372297000	/system/lib64/libstagefright_foundation.so
2025-11-08 13:30:31.574  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372297000-0x74a372298000	[page size compat]
2025-11-08 13:30:31.574  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372298000-0x74a3722b7000	/system/lib64/libstagefright_foundation.so
2025-11-08 13:30:31.574  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3722b7000-0x74a3722b8000	[page size compat]
2025-11-08 13:30:31.574  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3722b8000-0x74a3722ba000	/system/lib64/libstagefright_foundation.so
2025-11-08 13:30:31.574  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3722ba000-0x74a3722bc000	
2025-11-08 13:30:31.574  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3722bc000-0x74a3722bd000	/system/lib64/libstagefright_foundation.so
2025-11-08 13:30:31.574  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3722bf000-0x74a3722ce000	/system/usr/hyphen-data/hyph-en-us.hyb
2025-11-08 13:30:31.574  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3722ce000-0x74a3722da000	/system/usr/hyphen-data/hyph-en-gb.hyb
2025-11-08 13:30:31.574  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3722da000-0x74a3722fa000	/dev/__properties__/u:object_r:init_service_status_prop:s0
2025-11-08 13:30:31.574  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3722fa000-0x74a372314000	/system/lib64/android.hardware.drm@1.1.so
2025-11-08 13:30:31.574  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372314000-0x74a372316000	[page size compat]
2025-11-08 13:30:31.574  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372316000-0x74a372331000	/system/lib64/android.hardware.drm@1.1.so
2025-11-08 13:30:31.574  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372331000-0x74a372332000	[page size compat]
2025-11-08 13:30:31.574  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372332000-0x74a372337000	/system/lib64/android.hardware.drm@1.1.so
2025-11-08 13:30:31.575  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372337000-0x74a37233a000	
2025-11-08 13:30:31.575  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37233a000-0x74a37233b000	/system/lib64/android.hardware.drm@1.1.so
2025-11-08 13:30:31.575  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37233d000-0x74a372342000	/system/usr/hyphen-data/hyph-uk.hyb
2025-11-08 13:30:31.575  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372342000-0x74a372362000	/dev/__properties__/u:object_r:boot_status_prop:s0
2025-11-08 13:30:31.575  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372362000-0x74a372363000	/apex/com.android.runtime/lib64/bionic/libdl.so
2025-11-08 13:30:31.575  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372363000-0x74a372366000	[page size compat]
2025-11-08 13:30:31.575  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372366000-0x74a372367000	/apex/com.android.runtime/lib64/bionic/libdl.so
2025-11-08 13:30:31.575  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372367000-0x74a37236a000	[page size compat]
2025-11-08 13:30:31.575  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37236a000-0x74a37236b000	/apex/com.android.runtime/lib64/bionic/libdl.so
2025-11-08 13:30:31.575  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37236b000-0x74a37236e000	
2025-11-08 13:30:31.575  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37236e000-0x74a37236f000	[anon:.bss]
2025-11-08 13:30:31.575  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37236f000-0x74a372372000	[anon:.bss]
2025-11-08 13:30:31.575  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372372000-0x74a372377000	/system/usr/hyphen-data/hyph-ru.hyb
2025-11-08 13:30:31.575  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372377000-0x74a372378000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.575  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372378000-0x74a372381000	/system/usr/hyphen-data/hyph-ga.hyb
2025-11-08 13:30:31.575  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372381000-0x74a372396000	/system/lib64/android.hardware.graphics.bufferqueue@1.0.so
2025-11-08 13:30:31.575  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372396000-0x74a372399000	[page size compat]
2025-11-08 13:30:31.575  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372399000-0x74a3723b2000	/system/lib64/android.hardware.graphics.bufferqueue@1.0.so
2025-11-08 13:30:31.575  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3723b2000-0x74a3723b5000	[page size compat]
2025-11-08 13:30:31.575  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3723b5000-0x74a3723b9000	/system/lib64/android.hardware.graphics.bufferqueue@1.0.so
2025-11-08 13:30:31.575  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3723b9000-0x74a3723ba000	/system/lib64/android.hardware.graphics.bufferqueue@1.0.so
2025-11-08 13:30:31.575  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3723bd000-0x74a3723c2000	/system/usr/hyphen-data/hyph-pl.hyb
2025-11-08 13:30:31.575  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3723c2000-0x74a3723cb000	/system/usr/hyphen-data/hyph-cy.hyb
2025-11-08 13:30:31.575  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3723cb000-0x74a3723d4000	/system/lib64/android.hardware.graphics.allocator@3.0.so
2025-11-08 13:30:31.575  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3723d4000-0x74a3723d7000	[page size compat]
2025-11-08 13:30:31.576  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3723d7000-0x74a3723de000	/system/lib64/android.hardware.graphics.allocator@3.0.so
2025-11-08 13:30:31.576  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3723de000-0x74a3723df000	[page size compat]
2025-11-08 13:30:31.576  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3723df000-0x74a3723e1000	/system/lib64/android.hardware.graphics.allocator@3.0.so
2025-11-08 13:30:31.576  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3723e1000-0x74a3723e3000	
2025-11-08 13:30:31.576  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3723e3000-0x74a3723e4000	/system/lib64/android.hardware.graphics.allocator@3.0.so
2025-11-08 13:30:31.576  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3723e7000-0x74a372407000	[anon:dalvik-Pre-zygote-LinearAlloc]
2025-11-08 13:30:31.576  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372407000-0x74a37241f000	/system/lib64/android.hardware.graphics.composer3-V3-ndk.so
2025-11-08 13:30:31.576  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37241f000-0x74a37243b000	/system/lib64/android.hardware.graphics.composer3-V3-ndk.so
2025-11-08 13:30:31.576  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37243b000-0x74a37243d000	/system/lib64/android.hardware.graphics.composer3-V3-ndk.so
2025-11-08 13:30:31.576  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37243d000-0x74a37243f000	
2025-11-08 13:30:31.576  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37243f000-0x74a372440000	/system/lib64/android.hardware.graphics.composer3-V3-ndk.so
2025-11-08 13:30:31.576  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372443000-0x74a372463000	[anon:dalvik-Pre-zygote-LinearAlloc]
2025-11-08 13:30:31.576  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372463000-0x74a37246a000	/system/lib64/libgralloctypes.so
2025-11-08 13:30:31.576  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37246a000-0x74a37246b000	[page size compat]
2025-11-08 13:30:31.576  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37246b000-0x74a372475000	/system/lib64/libgralloctypes.so
2025-11-08 13:30:31.576  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372475000-0x74a372477000	[page size compat]
2025-11-08 13:30:31.576  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372477000-0x74a372478000	/system/lib64/libgralloctypes.so
2025-11-08 13:30:31.576  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372478000-0x74a37247b000	
2025-11-08 13:30:31.576  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37247b000-0x74a37247c000	[anon:.bss]
2025-11-08 13:30:31.576  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37247d000-0x74a37247f000	[anon:ReadFileToBuffer]
2025-11-08 13:30:31.576  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37247f000-0x74a372480000	/dev/ashmem/561638ee-e25a-4e30-9354-dd3e72da0663 (deleted)
2025-11-08 13:30:31.576  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372480000-0x74a37248a000	/system/lib64/android.hardware.graphics.mapper@2.0.so
2025-11-08 13:30:31.576  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37248a000-0x74a37248c000	[page size compat]
2025-11-08 13:30:31.576  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37248c000-0x74a372495000	/system/lib64/android.hardware.graphics.mapper@2.0.so
2025-11-08 13:30:31.576  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372495000-0x74a372498000	[page size compat]
2025-11-08 13:30:31.576  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372498000-0x74a37249a000	/system/lib64/android.hardware.graphics.mapper@2.0.so
2025-11-08 13:30:31.576  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37249a000-0x74a37249c000	
2025-11-08 13:30:31.576  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37249c000-0x74a37249d000	/system/lib64/android.hardware.graphics.mapper@2.0.so
2025-11-08 13:30:31.577  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37249d000-0x74a37249e000	/dev/ashmem/561638ee-e25a-4e30-9354-dd3e72da0663 (deleted)
2025-11-08 13:30:31.577  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37249e000-0x74a37249f000	/product/overlay/NavigationBarModeGestural/NavigationBarModeGesturalOverlay.apk
2025-11-08 13:30:31.577  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37249f000-0x74a3724af000	/system/usr/hyphen-data/hyph-cs.hyb
2025-11-08 13:30:31.577  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3724af000-0x74a3724ef000	[anon:dalvik-mark stack]
2025-11-08 13:30:31.577  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3724ef000-0x74a3724f0000	/system/lib64/libjpegencoder.so
2025-11-08 13:30:31.577  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3724f0000-0x74a3724f3000	[page size compat]
2025-11-08 13:30:31.577  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3724f3000-0x74a3724f5000	/system/lib64/libjpegencoder.so
2025-11-08 13:30:31.577  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3724f5000-0x74a3724f7000	[page size compat]
2025-11-08 13:30:31.577  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3724f7000-0x74a3724f8000	/system/lib64/libjpegencoder.so
2025-11-08 13:30:31.577  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3724f8000-0x74a3724fb000	
2025-11-08 13:30:31.577  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3724fb000-0x74a3724fc000	[anon:.bss]
2025-11-08 13:30:31.577  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3724fc000-0x74a3724fd000	/product/overlay/NavigationBarModeGestural/NavigationBarModeGesturalOverlay.apk
2025-11-08 13:30:31.577  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3724fd000-0x74a372503000	/system/usr/hyphen-data/hyph-et.hyb
2025-11-08 13:30:31.577  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372503000-0x74a372515000	/system/usr/hyphen-data/hyph-af.hyb
2025-11-08 13:30:31.577  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372515000-0x74a372520000	/system/lib64/libsensor.so
2025-11-08 13:30:31.577  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372520000-0x74a372521000	[page size compat]
2025-11-08 13:30:31.577  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372521000-0x74a37252a000	/system/lib64/libsensor.so
2025-11-08 13:30:31.577  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37252a000-0x74a37252d000	[page size compat]
2025-11-08 13:30:31.577  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37252d000-0x74a372530000	/system/lib64/libsensor.so
2025-11-08 13:30:31.577  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372530000-0x74a372531000	
2025-11-08 13:30:31.577  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372531000-0x74a372532000	/system/lib64/libsensor.so
2025-11-08 13:30:31.577  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372532000-0x74a372533000	/data/resource-cache/product@overlay@NavigationBarModeGestural@NavigationBarModeGesturalOverlay.apk@idmap
2025-11-08 13:30:31.577  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372533000-0x74a372534000	/product/overlay/EmulationPixelFold/EmulationPixelFoldOverlay.apk
2025-11-08 13:30:31.577  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372534000-0x74a372541000	/system/usr/hyphen-data/hyph-cu.hyb
2025-11-08 13:30:31.577  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372541000-0x74a372561000	[anon:dalvik-Pre-zygote-LinearAlloc]
2025-11-08 13:30:31.577  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372561000-0x74a372564000	/apex/com.android.art/lib64/libsigchain.so
2025-11-08 13:30:31.578  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372564000-0x74a372565000	[page size compat]
2025-11-08 13:30:31.578  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372565000-0x74a37256a000	/apex/com.android.art/lib64/libsigchain.so
2025-11-08 13:30:31.578  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37256a000-0x74a37256d000	[page size compat]
2025-11-08 13:30:31.578  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37256d000-0x74a37256e000	/apex/com.android.art/lib64/libsigchain.so
2025-11-08 13:30:31.578  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37256e000-0x74a372571000	
2025-11-08 13:30:31.578  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372571000-0x74a372573000	[anon:.bss]
2025-11-08 13:30:31.578  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372573000-0x74a372574000	/product/overlay/EmulationPixelFold/EmulationPixelFoldOverlay.apk
2025-11-08 13:30:31.578  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372574000-0x74a372575000	/data/resource-cache/product@overlay@EmulationPixelFold@EmulationPixelFoldOverlay.apk@idmap
2025-11-08 13:30:31.578  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372575000-0x74a372576000	/dev/cgroup_info/cgroup.rc
2025-11-08 13:30:31.578  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372576000-0x74a372577000	/system/usr/hyphen-data/hyph-und-ethi.hyb
2025-11-08 13:30:31.578  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372577000-0x74a372578000	
2025-11-08 13:30:31.578  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372578000-0x74a372590000	[anon:scudo:secondary]
2025-11-08 13:30:31.578  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372590000-0x74a372591000	
2025-11-08 13:30:31.578  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372591000-0x74a372592000	/system/lib64/android.hardware.graphics.common@1.1.so
2025-11-08 13:30:31.578  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372592000-0x74a372595000	[page size compat]
2025-11-08 13:30:31.578  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372595000-0x74a372596000	/system/lib64/android.hardware.graphics.common@1.1.so
2025-11-08 13:30:31.578  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372596000-0x74a372599000	[page size compat]
2025-11-08 13:30:31.578  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372599000-0x74a37259a000	/system/lib64/android.hardware.graphics.common@1.1.so
2025-11-08 13:30:31.578  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37259a000-0x74a37259b000	/system/usr/hyphen-data/hyph-tk.hyb
2025-11-08 13:30:31.578  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37259b000-0x74a37259c000	/system/usr/hyphen-data/hyph-te.hyb
2025-11-08 13:30:31.578  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37259c000-0x74a3725a4000	/system_ext/framework/androidx.window.sidecar.jar
2025-11-08 13:30:31.578  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3725a4000-0x74a3725c4000	[anon:dalvik-Pre-zygote-LinearAlloc]
2025-11-08 13:30:31.578  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3725c4000-0x74a3725db000	/system/lib64/libimage_io.so
2025-11-08 13:30:31.578  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3725db000-0x74a3725dc000	[page size compat]
2025-11-08 13:30:31.578  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3725dc000-0x74a3725f9000	/system/lib64/libimage_io.so
2025-11-08 13:30:31.579  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3725f9000-0x74a3725fc000	[page size compat]
2025-11-08 13:30:31.579  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3725fc000-0x74a3725fe000	/system/lib64/libimage_io.so
2025-11-08 13:30:31.579  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3725fe000-0x74a3725ff000	/system/usr/hyphen-data/hyph-ta.hyb
2025-11-08 13:30:31.579  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3725ff000-0x74a372600000	/system/usr/hyphen-data/hyph-sq.hyb
2025-11-08 13:30:31.579  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372600000-0x74a372602000	/system/usr/hyphen-data/hyph-sl.hyb
2025-11-08 13:30:31.579  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372602000-0x74a372612000	[anon:atexit handlers]
2025-11-08 13:30:31.579  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372612000-0x74a372613000	[anon:bionic_alloc_lob]
2025-11-08 13:30:31.579  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372613000-0x74a372614000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.579  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372614000-0x74a372654000	
2025-11-08 13:30:31.579  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372654000-0x74a372655000	/system/usr/hyphen-data/hyph-pt.hyb
2025-11-08 13:30:31.579  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372655000-0x74a372656000	/system/usr/hyphen-data/hyph-pa.hyb
2025-11-08 13:30:31.579  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372656000-0x74a372661000	/apex/com.android.tzdata/etc/tz/versioned/8/icu/metaZones.res
2025-11-08 13:30:31.579  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372661000-0x74a372662000	
2025-11-08 13:30:31.579  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372662000-0x74a37267f000	[anon:scudo:secondary]
2025-11-08 13:30:31.579  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37267f000-0x74a372680000	
2025-11-08 13:30:31.579  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372680000-0x74a3726c6000	/apex/com.android.ondevicepersonalization/javalib/framework-ondevicepersonalization.jar
2025-11-08 13:30:31.579  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3726c6000-0x74a3726c9000	/system/lib64/libtombstoned_client.so
2025-11-08 13:30:31.579  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3726c9000-0x74a3726ca000	[page size compat]
2025-11-08 13:30:31.579  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3726ca000-0x74a3726ce000	/system/lib64/libtombstoned_client.so
2025-11-08 13:30:31.579  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3726ce000-0x74a3726cf000	/system/lib64/libtombstoned_client.so
2025-11-08 13:30:31.579  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3726cf000-0x74a3726d0000	
2025-11-08 13:30:31.579  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3726d0000-0x74a3726e9000	[anon:scudo:secondary]
2025-11-08 13:30:31.579  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3726e9000-0x74a3726ea000	
2025-11-08 13:30:31.579  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3726ea000-0x74a37270a000	[anon:dalvik-large marked objects]
2025-11-08 13:30:31.579  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37270a000-0x74a37270b000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.579  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37270b000-0x74a37270c000	/system/usr/hyphen-data/hyph-or.hyb
2025-11-08 13:30:31.579  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37270c000-0x74a37275d000	/apex/com.android.appsearch/javalib/framework-appsearch.jar
2025-11-08 13:30:31.579  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37275d000-0x74a37277a000	/system/lib64/libdebugstore_cxx.so
2025-11-08 13:30:31.580  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37277a000-0x74a37277d000	[page size compat]
2025-11-08 13:30:31.580  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37277d000-0x74a37279a000	/system/lib64/libdebugstore_cxx.so
2025-11-08 13:30:31.580  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37279a000-0x74a37279d000	[page size compat]
2025-11-08 13:30:31.580  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37279d000-0x74a3727a0000	/system/lib64/libdebugstore_cxx.so
2025-11-08 13:30:31.580  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3727a0000-0x74a3727a1000	
2025-11-08 13:30:31.580  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3727a1000-0x74a3727a2000	/system/lib64/libdebugstore_cxx.so
2025-11-08 13:30:31.580  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3727a2000-0x74a3727a3000	/system/usr/hyphen-data/hyph-mr.hyb
2025-11-08 13:30:31.580  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3727a3000-0x74a3727a5000	/system/usr/hyphen-data/hyph-mn-cyrl.hyb
2025-11-08 13:30:31.580  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3727a5000-0x74a3727a7000	/system/usr/hyphen-data/hyph-lt.hyb
2025-11-08 13:30:31.580  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3727a7000-0x74a3727e4000	/apex/com.android.permission/javalib/framework-permission-s.jar
2025-11-08 13:30:31.580  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3727e4000-0x74a3727e5000	[anon:bionic_alloc_lob]
2025-11-08 13:30:31.580  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3727e5000-0x74a3727ee000	/system/framework/android.test.base.jar
2025-11-08 13:30:31.580  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3727ee000-0x74a372828000	/apex/com.android.nfcservices/javalib/framework-nfc.jar
2025-11-08 13:30:31.580  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372828000-0x74a372829000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.580  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372829000-0x74a37282a000	/system/usr/hyphen-data/hyph-ml.hyb
2025-11-08 13:30:31.580  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37282a000-0x74a37282b000	/system/usr/hyphen-data/hyph-la.hyb
2025-11-08 13:30:31.580  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37282b000-0x74a37282e000	/system/usr/hyphen-data/hyph-ka.hyb
2025-11-08 13:30:31.580  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37282e000-0x74a372892000	/apex/com.android.art/javalib/okhttp.jar
2025-11-08 13:30:31.580  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372892000-0x74a372895000	/system/lib64/libartpalette-system.so
2025-11-08 13:30:31.580  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372895000-0x74a372896000	[page size compat]
2025-11-08 13:30:31.580  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372896000-0x74a372898000	/system/lib64/libartpalette-system.so
2025-11-08 13:30:31.580  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372898000-0x74a37289a000	[page size compat]
2025-11-08 13:30:31.580  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37289a000-0x74a37289b000	/system/lib64/libartpalette-system.so
2025-11-08 13:30:31.580  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37289b000-0x74a37289e000	
2025-11-08 13:30:31.580  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37289e000-0x74a37289f000	[anon:.bss]
2025-11-08 13:30:31.580  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37289f000-0x74a3728a7000	/system/framework/android.hidl.manager-V1.0-java.jar
2025-11-08 13:30:31.580  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3728a7000-0x74a3728ab000	
2025-11-08 13:30:31.581  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3728ab000-0x74a3728b3000	[anon:thread signal stack]
2025-11-08 13:30:31.581  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3728b3000-0x74a3728d3000	[anon:dalvik-large live objects]
2025-11-08 13:30:31.581  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3728d3000-0x74a3728d7000	/system/lib64/heapprofd_client_api.so
2025-11-08 13:30:31.581  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3728d7000-0x74a3728e0000	/system/lib64/heapprofd_client_api.so
2025-11-08 13:30:31.581  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3728e0000-0x74a3728e3000	[page size compat]
2025-11-08 13:30:31.581  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3728e3000-0x74a3728e4000	/system/lib64/heapprofd_client_api.so
2025-11-08 13:30:31.581  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3728e4000-0x74a3728e7000	
2025-11-08 13:30:31.581  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3728e7000-0x74a3728e8000	/system/lib64/heapprofd_client_api.so
2025-11-08 13:30:31.581  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3728e8000-0x74a3728f1000	[anon:.bss]
2025-11-08 13:30:31.581  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3728f1000-0x74a372913000	/apex/com.android.virt/javalib/framework-virtualization.jar
2025-11-08 13:30:31.581  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372913000-0x74a372914000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.581  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372914000-0x74a372915000	/system/usr/hyphen-data/hyph-kn.hyb
2025-11-08 13:30:31.581  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372915000-0x74a372916000	/system/usr/hyphen-data/hyph-it.hyb
2025-11-08 13:30:31.581  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372916000-0x74a37291a000	
2025-11-08 13:30:31.581  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37291a000-0x74a372922000	[anon:thread signal stack]
2025-11-08 13:30:31.581  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372922000-0x74a372948000	/apex/com.android.uwb/javalib/framework-uwb.jar
2025-11-08 13:30:31.581  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372948000-0x74a37295b000	/apex/com.android.art/lib64/libdexfile.so
2025-11-08 13:30:31.581  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37295b000-0x74a37295c000	[page size compat]
2025-11-08 13:30:31.581  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37295c000-0x74a372986000	/apex/com.android.art/lib64/libdexfile.so
2025-11-08 13:30:31.581  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372986000-0x74a372988000	[page size compat]
2025-11-08 13:30:31.581  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372988000-0x74a37298a000	/apex/com.android.art/lib64/libdexfile.so
2025-11-08 13:30:31.581  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37298a000-0x74a37298c000	
2025-11-08 13:30:31.581  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37298c000-0x74a37298d000	/apex/com.android.art/lib64/libdexfile.so
2025-11-08 13:30:31.581  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37298d000-0x74a37298e000	/system/usr/hyphen-data/hyph-hy.hyb
2025-11-08 13:30:31.581  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37298e000-0x74a37298f000	/system/usr/hyphen-data/hyph-hr.hyb
2025-11-08 13:30:31.581  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37298f000-0x74a372992000	/system/usr/hyphen-data/hyph-gl.hyb
2025-11-08 13:30:31.581  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372992000-0x74a3729db000	/system/framework/ext.jar
2025-11-08 13:30:31.581  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3729db000-0x74a3729dd000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.582  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3729dd000-0x74a3729de000	/system/usr/hyphen-data/hyph-hi.hyb
2025-11-08 13:30:31.582  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3729de000-0x74a3729e0000	/system/usr/hyphen-data/hyph-fr.hyb
2025-11-08 13:30:31.582  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3729e0000-0x74a3729e4000	/system/usr/hyphen-data/hyph-es.hyb
2025-11-08 13:30:31.582  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3729e4000-0x74a3729e8000	
2025-11-08 13:30:31.582  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3729e8000-0x74a3729f0000	[anon:thread signal stack]
2025-11-08 13:30:31.582  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3729f0000-0x74a372a0a000	/apex/com.android.os.statsd/javalib/framework-statsd.jar
2025-11-08 13:30:31.582  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372a0a000-0x74a372a0f000	/apex/com.android.art/lib64/liblz4.so
2025-11-08 13:30:31.582  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372a0f000-0x74a372a12000	[page size compat]
2025-11-08 13:30:31.582  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372a12000-0x74a372a36000	/apex/com.android.art/lib64/liblz4.so
2025-11-08 13:30:31.582  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372a36000-0x74a372a37000	/apex/com.android.art/lib64/liblz4.so
2025-11-08 13:30:31.582  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372a37000-0x74a372a3b000	
2025-11-08 13:30:31.582  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372a3b000-0x74a372a43000	[anon:thread signal stack]
2025-11-08 13:30:31.582  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372a43000-0x74a372a6a000	/apex/com.android.configinfrastructure/javalib/framework-configinfrastructure.jar
2025-11-08 13:30:31.582  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372a6a000-0x74a372a6b000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.582  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372a6b000-0x74a372a6c000	/system/usr/hyphen-data/hyph-gu.hyb
2025-11-08 13:30:31.582  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372a6c000-0x74a372a6e000	/system/usr/hyphen-data/hyph-el.hyb
2025-11-08 13:30:31.582  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372a6e000-0x74a372a70000	/system/usr/hyphen-data/hyph-da.hyb
2025-11-08 13:30:31.582  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372a70000-0x74a372acb000	/system/framework/framework-location.jar
2025-11-08 13:30:31.582  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372acb000-0x74a372ad4000	/apex/com.android.art/lib64/libprofile.so
2025-11-08 13:30:31.582  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372ad4000-0x74a372ad7000	[page size compat]
2025-11-08 13:30:31.582  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372ad7000-0x74a372af4000	/apex/com.android.art/lib64/libprofile.so
2025-11-08 13:30:31.582  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372af4000-0x74a372af7000	[page size compat]
2025-11-08 13:30:31.582  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372af7000-0x74a372af8000	/apex/com.android.art/lib64/libprofile.so
2025-11-08 13:30:31.582  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372af8000-0x74a372afb000	
2025-11-08 13:30:31.582  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372afb000-0x74a372afc000	[anon:.bss]
2025-11-08 13:30:31.582  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372afc000-0x74a372afd000	/system/usr/hyphen-data/hyph-eu.hyb
2025-11-08 13:30:31.582  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372afd000-0x74a372afe000	/system/usr/hyphen-data/hyph-bn.hyb
2025-11-08 13:30:31.583  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372afe000-0x74a372aff000	/system/usr/hyphen-data/hyph-bg.hyb
2025-11-08 13:30:31.583  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372aff000-0x74a372b01000	/system/usr/hyphen-data/hyph-be.hyb
2025-11-08 13:30:31.583  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372b01000-0x74a372b02000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.583  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372b02000-0x74a372b1a000	/apex/com.android.os.statsd/lib64/libstatssocket.so
2025-11-08 13:30:31.583  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372b1a000-0x74a372b2f000	/apex/com.android.os.statsd/lib64/libstatssocket.so
2025-11-08 13:30:31.583  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372b2f000-0x74a372b32000	[page size compat]
2025-11-08 13:30:31.583  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372b32000-0x74a372b34000	/apex/com.android.os.statsd/lib64/libstatssocket.so
2025-11-08 13:30:31.583  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372b34000-0x74a372b36000	
2025-11-08 13:30:31.583  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372b36000-0x74a372b37000	/apex/com.android.os.statsd/lib64/libstatssocket.so
2025-11-08 13:30:31.583  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372b37000-0x74a372b38000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.583  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372b38000-0x74a372b3c000	/system/framework/android.hidl.base-V1.0-java.jar
2025-11-08 13:30:31.583  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372b3c000-0x74a372b41000	/product/overlay/PixelConfigOverlayCommon.apk
2025-11-08 13:30:31.583  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372b41000-0x74a372b43000	/apex/com.android.art/lib64/libartpalette.so
2025-11-08 13:30:31.583  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372b43000-0x74a372b45000	[page size compat]
2025-11-08 13:30:31.583  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372b45000-0x74a372b46000	/apex/com.android.art/lib64/libartpalette.so
2025-11-08 13:30:31.583  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372b46000-0x74a372b49000	[page size compat]
2025-11-08 13:30:31.583  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372b49000-0x74a372b4a000	/apex/com.android.art/lib64/libartpalette.so
2025-11-08 13:30:31.583  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372b4a000-0x74a372b4d000	
2025-11-08 13:30:31.583  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372b4d000-0x74a372b4e000	[anon:.bss]
2025-11-08 13:30:31.583  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372b4e000-0x74a372b50000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.583  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372b50000-0x74a372b6d000	/apex/com.android.mediaprovider/javalib/framework-mediaprovider.jar
2025-11-08 13:30:31.583  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372b6d000-0x74a372b87000	/apex/com.android.adservices/javalib/framework-sdksandbox.jar
2025-11-08 13:30:31.583  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372b87000-0x74a372b89000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.583  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372b89000-0x74a372b8b000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.583  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372b8b000-0x74a372b91000	/apex/com.android.tzdata/etc/tz/versioned/8/icu/timezoneTypes.res
2025-11-08 13:30:31.584  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372b91000-0x74a372b93000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.584  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372b93000-0x74a372b9c000	[anon:dalvik-/system/framework/framework.jar-transformed]
2025-11-08 13:30:31.584  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372b9c000-0x74a372b9d000	[anon:dalvik-mod union bitmap]
2025-11-08 13:30:31.584  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372b9d000-0x74a372bbd000	/dev/__properties__/u:object_r:hw_timeout_multiplier_prop:s0
2025-11-08 13:30:31.584  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372bbd000-0x74a372bbe000	/system/usr/hyphen-data/hyph-as.hyb
2025-11-08 13:30:31.584  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372bbe000-0x74a372bbf000	/product/overlay/RanchuCommonOverlay.apk
2025-11-08 13:30:31.584  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372bbf000-0x74a372bd5000	/apex/com.android.mediaprovider/javalib/framework-pdf.jar
2025-11-08 13:30:31.584  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372bd5000-0x74a372bf5000	/dev/__properties__/u:object_r:device_config_runtime_native_prop:s0
2025-11-08 13:30:31.584  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372bf5000-0x74a372c15000	/dev/__properties__/u:object_r:fingerprint_prop:s0
2025-11-08 13:30:31.584  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372c15000-0x74a372c37000	/apex/com.android.art/lib64/libartbase.so
2025-11-08 13:30:31.584  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372c37000-0x74a372c39000	[page size compat]
2025-11-08 13:30:31.584  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372c39000-0x74a372c6a000	/apex/com.android.art/lib64/libartbase.so
2025-11-08 13:30:31.584  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372c6a000-0x74a372c6d000	[page size compat]
2025-11-08 13:30:31.584  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372c6d000-0x74a372c70000	/apex/com.android.art/lib64/libartbase.so
2025-11-08 13:30:31.584  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372c70000-0x74a372c71000	
2025-11-08 13:30:31.584  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372c71000-0x74a372c72000	/apex/com.android.art/lib64/libartbase.so
2025-11-08 13:30:31.584  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372c72000-0x74a372c73000	/product/overlay/RanchuCommonOverlay.apk
2025-11-08 13:30:31.584  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372c73000-0x74a372c74000	/data/resource-cache/product@overlay@RanchuCommonOverlay.apk@idmap
2025-11-08 13:30:31.584  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372c74000-0x74a372c75000	/product/overlay/framework-res__sdk_gphone64_x86_64__auto_generated_rro_product.apk
2025-11-08 13:30:31.584  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372c75000-0x74a372c87000	/apex/com.android.tethering/javalib/framework-tethering.jar
2025-11-08 13:30:31.584  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372c87000-0x74a372c88000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.584  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372c88000-0x74a372c89000	/product/overlay/framework-res__sdk_gphone64_x86_64__auto_generated_rro_product.apk
2025-11-08 13:30:31.584  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372c89000-0x74a372c8a000	/data/resource-cache/product@overlay@framework-res__sdk_gphone64_x86_64__auto_generated_rro_product.apk@idmap
2025-11-08 13:30:31.584  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372c8a000-0x74a372c8b000	/product/overlay/PixelConfigOverlayCommon.apk
2025-11-08 13:30:31.584  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372c8b000-0x74a372c91000	/apex/com.android.tzdata/etc/tz/versioned/8/icu/windowsZones.res
2025-11-08 13:30:31.584  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372c91000-0x74a372cb1000	/dev/__properties__/u:object_r:persist_debug_prop:s0
2025-11-08 13:30:31.584  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372cb1000-0x74a372cd1000	/dev/__properties__/u:object_r:default_prop:s0
2025-11-08 13:30:31.584  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372cd1000-0x74a372cf1000	/dev/__properties__/u:object_r:system_prop:s0
2025-11-08 13:30:31.585  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372cf1000-0x74a372d15000	/apex/com.android.os.statsd/lib64/libstatspull.so
2025-11-08 13:30:31.585  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372d15000-0x74a372d38000	/apex/com.android.os.statsd/lib64/libstatspull.so
2025-11-08 13:30:31.585  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372d38000-0x74a372d39000	[page size compat]
2025-11-08 13:30:31.585  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372d39000-0x74a372d3d000	/apex/com.android.os.statsd/lib64/libstatspull.so
2025-11-08 13:30:31.585  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372d3d000-0x74a372d3e000	/apex/com.android.os.statsd/lib64/libstatspull.so
2025-11-08 13:30:31.585  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372d3e000-0x74a372d3f000	/data/resource-cache/product@overlay@PixelConfigOverlayCommon.apk@idmap
2025-11-08 13:30:31.585  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372d3f000-0x74a372d40000	/product/overlay/LargeScreenConfigOverlay.apk
2025-11-08 13:30:31.585  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372d40000-0x74a372d48000	/apex/com.android.profiling/javalib/framework-profiling.jar
2025-11-08 13:30:31.585  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372d48000-0x74a372d57000	/system/framework/x86_64/boot-framework-adservices.art
2025-11-08 13:30:31.585  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372d57000-0x74a372d5a000	/apex/com.android.art/lib64/libnativehelper.so
2025-11-08 13:30:31.585  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372d5a000-0x74a372d5b000	[page size compat]
2025-11-08 13:30:31.585  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372d5b000-0x74a372d5e000	/apex/com.android.art/lib64/libnativehelper.so
2025-11-08 13:30:31.585  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372d5e000-0x74a372d5f000	[page size compat]
2025-11-08 13:30:31.585  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372d5f000-0x74a372d60000	/apex/com.android.art/lib64/libnativehelper.so
2025-11-08 13:30:31.585  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372d60000-0x74a372d63000	
2025-11-08 13:30:31.585  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372d63000-0x74a372d64000	[anon:.bss]
2025-11-08 13:30:31.585  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372d64000-0x74a372d65000	/product/overlay/LargeScreenConfigOverlay.apk
2025-11-08 13:30:31.585  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372d65000-0x74a372d69000	/apex/com.android.scheduling/javalib/framework-scheduling.jar
2025-11-08 13:30:31.585  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372d69000-0x74a372d81000	/system/framework/x86_64/boot-framework.art
2025-11-08 13:30:31.585  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372d81000-0x74a372da1000	/dev/__properties__/u:object_r:locale_prop:s0
2025-11-08 13:30:31.585  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372da1000-0x74a372da2000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.585  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372da2000-0x74a372daa000	/apex/com.android.devicelock/javalib/framework-devicelock.jar
2025-11-08 13:30:31.585  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372daa000-0x74a372dab000	
2025-11-08 13:30:31.585  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372dab000-0x74a372dbc000	[anon:scudo:secondary]
2025-11-08 13:30:31.585  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372dbc000-0x74a372dbd000	
2025-11-08 13:30:31.585  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372dbd000-0x74a372ddd000	/dev/__properties__/u:object_r:dalvik_dynamic_config_prop:s0
2025-11-08 13:30:31.585  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372ddd000-0x74a372dfd000	/dev/__properties__/u:object_r:exported_config_prop:s0
2025-11-08 13:30:31.586  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372dfd000-0x74a372e01000	
2025-11-08 13:30:31.586  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372e01000-0x74a372e05000	[anon:dalvik-/apex/com.android.art/javalib/core-libart.jar-transformed]
2025-11-08 13:30:31.586  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372e05000-0x74a372e09000	
2025-11-08 13:30:31.586  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372e09000-0x74a372e11000	[anon:thread signal stack]
2025-11-08 13:30:31.586  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372e11000-0x74a372e15000	
2025-11-08 13:30:31.586  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372e15000-0x74a372e1d000	[anon:thread signal stack]
2025-11-08 13:30:31.586  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372e1d000-0x74a372e3d000	/dev/__properties__/u:object_r:device_config_runtime_native_boot_prop:s0
2025-11-08 13:30:31.586  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372e3d000-0x74a372e5d000	/dev/__properties__/u:object_r:dalvik_config_prop:s0
2025-11-08 13:30:31.586  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372e5d000-0x74a372e7d000	/dev/__properties__/u:object_r:dalvik_runtime_prop:s0
2025-11-08 13:30:31.586  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372e7d000-0x74a372e9d000	/dev/__properties__/u:object_r:log_file_logger_prop:s0
2025-11-08 13:30:31.586  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372e9d000-0x74a372e9e000	
2025-11-08 13:30:31.586  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372e9e000-0x74a372edf000	[anon:scudo:secondary]
2025-11-08 13:30:31.586  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372edf000-0x74a372ee1000	
2025-11-08 13:30:31.586  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372ee1000-0x74a372f22000	[anon:scudo:secondary]
2025-11-08 13:30:31.586  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f22000-0x74a372f23000	
2025-11-08 13:30:31.586  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f23000-0x74a372f24000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.586  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f24000-0x74a372f25000	
2025-11-08 13:30:31.586  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f25000-0x74a372f29000	[anon:dalvik-/apex/com.android.art/javalib/core-oj.jar-transformed]
2025-11-08 13:30:31.586  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f29000-0x74a372f2b000	[anon:dalvik-/system/framework/framework.jar-transformed]
2025-11-08 13:30:31.586  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f2b000-0x74a372f2c000	[anon:dalvik-local ref table]
2025-11-08 13:30:31.586  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f2c000-0x74a372f30000	
2025-11-08 13:30:31.586  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f30000-0x74a372f38000	[anon:thread signal stack]
2025-11-08 13:30:31.586  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f38000-0x74a372f3c000	
2025-11-08 13:30:31.586  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f3c000-0x74a372f44000	[anon:thread signal stack]
2025-11-08 13:30:31.586  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f44000-0x74a372f45000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.586  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f45000-0x74a372f46000	/data/resource-cache/product@overlay@LargeScreenConfigOverlay.apk@idmap
2025-11-08 13:30:31.586  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f46000-0x74a372f47000	/product/overlay/GoogleWebViewOverlay.apk
2025-11-08 13:30:31.586  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f47000-0x74a372f48000	
2025-11-08 13:30:31.587  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f48000-0x74a372f68000	/dev/__properties__/u:object_r:log_tag_prop:s0
2025-11-08 13:30:31.587  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f68000-0x74a372f78000	[anon:Allocate]
2025-11-08 13:30:31.587  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f78000-0x74a372f79000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.587  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f79000-0x74a372f7a000	[anon:dalvik-local ref table]
2025-11-08 13:30:31.587  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f7a000-0x74a372f7c000	/apex/com.android.sdkext/javalib/framework-sdkextensions.jar
2025-11-08 13:30:31.587  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f7c000-0x74a372f7d000	/apex/com.android.permission/javalib/framework-permission.jar
2025-11-08 13:30:31.587  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f7d000-0x74a372f80000	/apex/com.android.mediaprovider/javalib/framework-pdf-v.jar
2025-11-08 13:30:31.587  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f80000-0x74a372f81000	/system/framework/framework-graphics.jar
2025-11-08 13:30:31.587  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f81000-0x74a372f85000	/system/framework/x86_64/boot-core-icu4j.art
2025-11-08 13:30:31.587  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f85000-0x74a372f95000	[anon:Allocate]
2025-11-08 13:30:31.587  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f95000-0x74a372f96000	/product/overlay/GoogleWebViewOverlay.apk
2025-11-08 13:30:31.587  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f96000-0x74a372f97000	/data/resource-cache/product@overlay@GoogleWebViewOverlay.apk@idmap
2025-11-08 13:30:31.587  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f97000-0x74a372f98000	/product/overlay/GoogleConfigOverlay.apk
2025-11-08 13:30:31.587  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f98000-0x74a372f99000	/data/resource-cache/product@overlay@GoogleConfigOverlay.apk@idmap
2025-11-08 13:30:31.587  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f99000-0x74a372f9a000	/vendor/overlay/framework-res__sdk_gphone64_x86_64__auto_generated_rro_vendor.apk
2025-11-08 13:30:31.587  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f9a000-0x74a372f9b000	/vendor/overlay/framework-res__sdk_gphone64_x86_64__auto_generated_rro_vendor.apk
2025-11-08 13:30:31.587  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f9b000-0x74a372f9c000	/data/resource-cache/vendor@overlay@framework-res__sdk_gphone64_x86_64__auto_generated_rro_vendor.apk@idmap
2025-11-08 13:30:31.587  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f9c000-0x74a372f9d000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.587  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f9d000-0x74a372f9e000	
2025-11-08 13:30:31.587  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372f9e000-0x74a372fbf000	[anon:scudo:secondary]
2025-11-08 13:30:31.587  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372fbf000-0x74a372fc0000	
2025-11-08 13:30:31.587  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372fc0000-0x74a372fe0000	/dev/__properties__/u:object_r:bq_config_prop:s0
2025-11-08 13:30:31.587  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a372fe0000-0x74a373000000	/dev/__properties__/u:object_r:build_prop:s0
2025-11-08 13:30:31.587  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373000000-0x74a373020000	/dev/__properties__/u:object_r:debug_prop:s0
2025-11-08 13:30:31.587  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373020000-0x74a373040000	/dev/__properties__/properties_serial
2025-11-08 13:30:31.587  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373040000-0x74a373057000	/dev/__properties__/property_info
2025-11-08 13:30:31.587  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373057000-0x74a37305b000	
2025-11-08 13:30:31.588  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37305b000-0x74a37305f000	[anon:stack_and_tls:main]
2025-11-08 13:30:31.588  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37305f000-0x74a373063000	
2025-11-08 13:30:31.588  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373063000-0x74a373083000	/dev/__properties__/u:object_r:vendor_socket_hook_prop:s0
2025-11-08 13:30:31.588  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373083000-0x74a3730a3000	/dev/__properties__/u:object_r:heapprofd_prop:s0
2025-11-08 13:30:31.588  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3730a3000-0x74a3730c3000	/dev/__properties__/u:object_r:libc_debug_prop:s0
2025-11-08 13:30:31.588  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3730c3000-0x74a373183000	[anon:linker_alloc]
2025-11-08 13:30:31.588  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373183000-0x74a373185000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.588  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373185000-0x74a373186000	[anon:dalvik-local ref table]
2025-11-08 13:30:31.588  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373186000-0x74a373187000	/system/framework/x86_64/boot-ims-common.art
2025-11-08 13:30:31.588  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373187000-0x74a373189000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.588  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373189000-0x74a37318b000	/system/framework/x86_64/boot-voip-common.art
2025-11-08 13:30:31.588  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37318b000-0x74a37318c000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.588  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37318c000-0x74a37318f000	/system/framework/x86_64/boot-telephony-common.art
2025-11-08 13:30:31.588  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37318f000-0x74a373190000	/system/framework/x86_64/boot-ext.art
2025-11-08 13:30:31.588  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373190000-0x74a373192000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.588  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373192000-0x74a373193000	/system/framework/x86_64/boot-framework-location.art
2025-11-08 13:30:31.588  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373193000-0x74a373194000	/system/framework/x86_64/boot-framework-graphics.art
2025-11-08 13:30:31.588  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373194000-0x74a373195000	/system/framework/x86_64/boot-apache-xml.art
2025-11-08 13:30:31.588  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373195000-0x74a373196000	/system/framework/x86_64/boot-bouncycastle.art
2025-11-08 13:30:31.588  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373196000-0x74a373197000	/system/framework/x86_64/boot-okhttp.art
2025-11-08 13:30:31.588  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373197000-0x74a373198000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.588  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373198000-0x74a373199000	/system/framework/x86_64/boot-core-libart.art
2025-11-08 13:30:31.588  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373199000-0x74a37319a000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.589  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37319a000-0x74a37319f000	/system/framework/x86_64/boot.art
2025-11-08 13:30:31.589  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37319f000-0x74a3731a1000	[anon:InternalMmapVector]
2025-11-08 13:30:31.589  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3731a1000-0x74a3731a5000	[anon:System property context nodes]
2025-11-08 13:30:31.589  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3731a5000-0x74a3731ad000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.589  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3731ad000-0x74a3731cd000	/dev/__properties__/u:object_r:vndk_prop:s0
2025-11-08 13:30:31.589  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3731cd000-0x74a3731cf000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.589  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3731cf000-0x74a37322f000	[anon:linker_alloc]
2025-11-08 13:30:31.589  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37322f000-0x74a37324f000	/dev/__properties__/u:object_r:debug_prop:s0
2025-11-08 13:30:31.589  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37324f000-0x74a373250000	
2025-11-08 13:30:31.589  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373250000-0x74a373258000	
2025-11-08 13:30:31.589  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373258000-0x74a373259000	
2025-11-08 13:30:31.589  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373259000-0x74a373279000	/dev/__properties__/properties_serial
2025-11-08 13:30:31.589  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373279000-0x74a37327d000	[anon:System property context nodes]
2025-11-08 13:30:31.589  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37327d000-0x74a373294000	/dev/__properties__/property_info
2025-11-08 13:30:31.589  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373294000-0x74a3732f4000	[anon:linker_alloc]
2025-11-08 13:30:31.590  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3732f4000-0x74a3732f8000	
2025-11-08 13:30:31.590  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a3732f8000-0x74a373300000	[anon:thread signal stack]
2025-11-08 13:30:31.590  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373300000-0x74a373302000	[anon:ReadFileToBuffer]
2025-11-08 13:30:31.590  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373302000-0x74a373303000	[anon:arc4random data]
2025-11-08 13:30:31.590  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373303000-0x74a37334d000	/apex/com.android.runtime/bin/linker64
2025-11-08 13:30:31.590  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37334d000-0x74a37334f000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.590  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37334f000-0x74a373479000	/apex/com.android.runtime/bin/linker64
2025-11-08 13:30:31.590  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373479000-0x74a37347a000	[anon:atexit handlers]
2025-11-08 13:30:31.590  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37347a000-0x74a37347b000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.590  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a37347b000-0x74a373485000	/apex/com.android.runtime/bin/linker64
2025-11-08 13:30:31.590  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373485000-0x74a373486000	[anon:bionic_alloc_small_objects]
2025-11-08 13:30:31.590  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373486000-0x74a373487000	[anon:arc4random data]
2025-11-08 13:30:31.590  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373487000-0x74a373488000	/apex/com.android.runtime/bin/linker64
2025-11-08 13:30:31.590  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373488000-0x74a373493000	[anon:.bss]
2025-11-08 13:30:31.590  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373493000-0x74a373497000	[anon:.bss]
2025-11-08 13:30:31.590  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x74a373497000-0x74a3734a3000	[anon:.bss]
2025-11-08 13:30:31.590  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x7ffd80d1f000-0x7ffd80d20000	
2025-11-08 13:30:31.590  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x7ffd80d20000-0x7ffd8151f000	[stack]
2025-11-08 13:30:31.590  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x7ffd8153c000-0x7ffd81540000	[vvar]
2025-11-08 13:30:31.590  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0x7ffd81540000-0x7ffd81541000	[vdso]
2025-11-08 13:30:31.590  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  	0xffffffffff600000-0xffffffffff601000	[vsyscall]
2025-11-08 13:30:31.590  5692-5692  com.oearth...oioearth01 com.oearth.androioearth01            I  ==5692==End of process memory map.
2025-11-08 13:30:31.590  5692-5692  libc                    com.oearth.androioearth01            A  Fatal signal 6 (SIGABRT), code -1 (SI_QUEUE) in tid 5692 (.androioearth01), pid 5692 (.androioearth01)
---------------------------- PROCESS STARTED (5716) for package com.oearth.androioearth01 ----------------------------
2025-11-08 13:30:31.777  5714-5714  DEBUG                   crash_dump64                         A  Cmdline: com.oearth.androioearth01
2025-11-08 13:30:31.777  5714-5714  DEBUG                   crash_dump64                         A  pid: 5692, tid: 5692, name: .androioearth01  >>> com.oearth.androioearth01 <<<
2025-11-08 13:30:31.777  5714-5714  DEBUG                   crash_dump64                         A        #01 pc 00000000000681d1  /data/app/~~EApFJKn0TYks1NB7znMWgA==/com.oearth.androioearth01-kkGgvQ6-x5_Ioed2KatziA==/lib/x86_64/libclang_rt.asan-x86_64-android.so (BuildId: f84ac7f72cacc1abcf16cfc927bedd3be194254c)
2025-11-08 13:30:31.777  5714-5714  DEBUG                   crash_dump64                         A        #02 pc 0000000000067000  /data/app/~~EApFJKn0TYks1NB7znMWgA==/com.oearth.androioearth01-kkGgvQ6-x5_Ioed2KatziA==/lib/x86_64/libclang_rt.asan-x86_64-android.so (BuildId: f84ac7f72cacc1abcf16cfc927bedd3be194254c)
2025-11-08 13:30:31.777  5714-5714  DEBUG                   crash_dump64                         A        #03 pc 00000000000e7288  /data/app/~~EApFJKn0TYks1NB7znMWgA==/com.oearth.androioearth01-kkGgvQ6-x5_Ioed2KatziA==/lib/x86_64/libclang_rt.asan-x86_64-android.so (BuildId: f84ac7f72cacc1abcf16cfc927bedd3be194254c)
2025-11-08 13:30:31.777  5714-5714  DEBUG                   crash_dump64                         A        #04 pc 00000000000e6593  /data/app/~~EApFJKn0TYks1NB7znMWgA==/com.oearth.androioearth01-kkGgvQ6-x5_Ioed2KatziA==/lib/x86_64/libclang_rt.asan-x86_64-android.so (BuildId: f84ac7f72cacc1abcf16cfc927bedd3be194254c)
2025-11-08 13:30:31.777  5714-5714  DEBUG                   crash_dump64                         A        #05 pc 00000000000e6d3d  /data/app/~~EApFJKn0TYks1NB7znMWgA==/com.oearth.androioearth01-kkGgvQ6-x5_Ioed2KatziA==/lib/x86_64/libclang_rt.asan-x86_64-android.so (BuildId: f84ac7f72cacc1abcf16cfc927bedd3be194254c)
2025-11-08 13:30:31.777  5714-5714  DEBUG                   crash_dump64                         A        #23 pc 00000000000018f0  <anonymous:74a372dfd000> (com.oearth.androioearth01.osgEarthViewer.onCreate+0)
2025-11-08 13:30:31.790   618-5717  ActivityTaskManager     system_server                        W    Force finishing activity com.oearth.androioearth01/.osgEarthViewer
2025-11-08 13:30:31.792   618-638   ActivityManager         system_server                        I  Showing crash dialog for package com.oearth.androioearth01 u0
---------------------------- PROCESS ENDED (5692) for package com.oearth.androioearth01 ----------------------------
```

这是一个经典的 **ASan 内存映射冲突问题**。错误信息明确指出：

```
Shadow memory range interleaves with an existing memory mapping. ASan cannot proceed correctly. ABORTING.
ASan shadow was supposed to be located in the [0x00007fff7000-0x10007fff7fff] range.
```

## 🔍 问题分析

**根本原因**：ASan 需要一块特定的内存区域（shadow memory）来跟踪内存使用情况，但这个区域已经被 Android 系统的其他组件占用了。

从内存映射可以看到，`0x749f80000000-0x749fc0000000` 区域被标记为 `[anon:dalvik-linear-alloc shadow map]`，这与 ASan 需要的 shadow memory 区域冲突。

## 🛠️ 解决方案

### 方案1：使用 ASan 的替代 shadow memory 位置

**修改 wrap.sh**：
```bash
#!/system/bin/sh
HERE="$(cd "$(dirname "$0")" && pwd)"

# 关键配置：指定不同的 shadow memory 位置
export ASAN_OPTIONS="
    log_to_syslog=false,
    allow_user_segv_handler=1,
    abort_on_error=1,
    symbolize=1,
    debug=1,
    verbosity=1,
    # 指定不同的 shadow memory 基地址
    ASAN_SHADOW_OFFSET=0x7FFF8000
"

# 或者尝试其他偏移量
# export ASAN_OPTIONS="$ASAN_OPTIONS,ASAN_SHADOW_OFFSET=0x10000000"

ASAN_LIB=$(ls $HERE/libclang_rt.asan-*-android.so 2>/dev/null)

if [ -f "$ASAN_LIB" ]; then
    if [ -f "$HERE/libc++_shared.so" ]; then
        export LD_PRELOAD="$ASAN_LIB $HERE/libc++_shared.so"
    else
        export LD_PRELOAD="$ASAN_LIB"
    fi
fi

exec "$@"
```

### 方案2：使用 Android 特定的 ASan 配置

**创建专门的 asan.options 文件**：
```bash
# 在设备上创建
adb shell "echo 'verbosity=1
debug=1
abort_on_error=1
symbolize=1
allow_user_segv_handler=1
# Android 特定的 shadow memory 配置
use_shadow=1
ASAN_SHADOW_SCALE=3
ASAN_SHADOW_OFFSET=0x7FFF8000
# 或者尝试禁用某些功能
protect_shadow_gap=0
malloc_context_size=10' > /data/local/tmp/asan.options"

adb shell chmod 644 /data/local/tmp/asan.options
```

### 方案3：使用 HWAddressSanitizer（如果 NDK 支持）

如果您的 NDK 版本较新，可以尝试 HWASan：

**修改 CMakeLists.txt**：
```cmake
if(ANDROID AND CMAKE_BUILD_TYPE STREQUAL "Debug")
    # 尝试使用 HWASan 替代 ASan
    add_compile_options(-fsanitize=hwaddress -fno-omit-frame-pointer)
    add_link_options(-fsanitize=hwaddress)
endif()
```

### 方案4：降级到更简单的内存检测

**使用 LeakSanitizer 或其他工具**：
```cmake
if(ANDROID AND CMAKE_BUILD_TYPE STREQUAL "Debug")
    # 只检测内存泄漏，不检测越界访问
    add_compile_options(-fsanitize=leak -fno-omit-frame-pointer)
    add_link_options(-fsanitize=leak)
endif()
```

### 方案5：临时禁用 ASan 进行开发

**完全禁用 ASan**：
```cmake
# 注释掉 ASan 配置
# if(ANDROID AND CMAKE_BUILD_TYPE STREQUAL "Debug")
#     add_compile_options(-fsanitize=address -fno-omit-frame-pointer)
#     add_link_options(-fsanitize=address)
# endif()

# 改为普通调试配置
if(ANDROID AND CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_compile_options(-g -O0 -DDEBUG)
endif()
```

**修改 wrap.sh 为不加载 ASan**：
```bash
#!/system/bin/sh
# 临时禁用 ASan
# export LD_PRELOAD=""
exec "$@"
```

## 🔧 诊断和测试步骤

### 1. 测试不同的 shadow memory 偏移量

创建测试脚本：
```bash
#!/system/bin/sh
HERE="$(cd "$(dirname "$0")" && pwd)"

# 测试不同的偏移量
for OFFSET in 0x7FFF8000 0x10000000 0x20000000 0x40000000; do
    echo "Testing ASAN_SHADOW_OFFSET=$OFFSET"
    export ASAN_OPTIONS="ASAN_SHADOW_OFFSET=$OFFSET,verbosity=1,abort_on_error=1"
    
    ASAN_LIB=$(ls $HERE/libclang_rt.asan-*-android.so)
    export LD_PRELOAD="$ASAN_LIB"
    
    # 运行简单测试
    $HERE/libandroioearth01.so --test 2>&1 | grep -i "shadow\|asan" && break
done

exec "$@"
```

### 2. 检查 Android 版本和内存布局

```bash
# 检查 Android 版本
adb shell getprop ro.build.version.sdk

# 检查内存布局
adb shell cat /proc/self/maps | head -20
```

## 📋 针对不同 Android 版本的解决方案

### Android 10+（API 29+）
问题更常见，需要特殊配置：
```bash
# 对于 Android 10+
export ASAN_OPTIONS="
    ASAN_SHADOW_OFFSET=0x10000000
    protect_shadow_gap=0
    allow_user_segv_handler=1
"
```

### Android 9 及以下
通常问题较少：
```bash
# 对于 Android 9-
export ASAN_OPTIONS="
    ASAN_SHADOW_OFFSET=0x7FFF8000
    check_initialization_order=1
"
```

## 🎯 推荐解决步骤

1. **首先尝试方案1**：修改 `ASAN_SHADOW_OFFSET`
2. **如果失败，尝试方案5**：临时禁用 ASan 继续开发
3. **长期解决方案**：考虑使用其他内存检测工具或等待 Android 版本更新

这个问题的根本原因是 Android 系统的内存布局与 ASan 的预期冲突，在 Android 10+ 的版本中尤其常见。如果您的应用必须使用 ASan，可能需要针对特定的 Android 版本进行调优。

====================================================================
# 3. callstack 6

```sh
2025-11-08 17:48:04.375   618-2605  ActivityManager         system_server                        I  Force stopping com.oearth.androioearth01 appid=10212 user=0: from pid 13182
2025-11-08 17:48:04.380   618-2605  AppsFilter              system_server                        I  interaction: PackageSetting{a2c7e60 com.android.microdroid.empty_payload/10199} -> PackageSetting{c131511 com.oearth.androioearth01/10212} BLOCKED
2025-11-08 17:48:04.380   618-2605  AppsFilter              system_server                        I  interaction: PackageSetting{ce1abde com.example.androioearthdemo/10211} -> PackageSetting{c131511 com.oearth.androioearth01/10212} BLOCKED
2025-11-08 17:48:04.380   618-2605  AppsFilter              system_server                        I  interaction: PackageSetting{a2801bf com.example.mynavdrawer/10209} -> PackageSetting{c131511 com.oearth.androioearth01/10212} BLOCKED
2025-11-08 17:48:04.380   618-2605  AppsFilter              system_server                        I  interaction: PackageSetting{c4b208c app.organicmaps.debug/10210} -> PackageSetting{c131511 com.oearth.androioearth01/10212} BLOCKED
2025-11-08 17:48:04.386  1025-1025  CarrierSvcBindHelper    com.android.phone                    D  onHandleForceStop: [com.oearth.androioearth01]
2025-11-08 17:48:05.544   618-685   NativeLibraryHelper     system_server                        D  Punching extracted elf file libandroioearth01.so on fs:61267
2025-11-08 17:48:05.544   618-685   FileSystemUtils         system_server                        D  Punching holes in file: /data/app/vmdl1240991519.tmp/lib/x86_64/libandroioearth01.so programHeaderOffset: 64 programHeaderNum: 9
2025-11-08 17:48:05.612   618-649   ActivityManager         system_server                        I  Force stopping com.oearth.androioearth01 appid=10212 user=-1: installPackageLI
2025-11-08 17:48:05.612   618-677   PackageManager          system_server                        I  Update package com.oearth.androioearth01 code path from /data/app/~~EApFJKn0TYks1NB7znMWgA==/com.oearth.androioearth01-kkGgvQ6-x5_Ioed2KatziA== to /data/app/~~rbcPWBYsEg6E5mfqaQEjhw==/com.oearth.androioearth01-uTGgp89vXvEJUneZSzlXLw==; Retain data and using new
2025-11-08 17:48:05.613   618-677   AppsFilter              system_server                        I  interaction: PackageSetting{5154951 com.android.microdroid.empty_payload/10199} -> PackageSetting{bbd75de com.oearth.androioearth01/10212} BLOCKED
2025-11-08 17:48:05.613   618-677   AppsFilter              system_server                        I  interaction: PackageSetting{3076b63 com.example.androioearthdemo/10211} -> PackageSetting{bbd75de com.oearth.androioearth01/10212} BLOCKED
2025-11-08 17:48:05.613   618-677   AppsFilter              system_server                        I  interaction: PackageSetting{ed0accc com.example.mynavdrawer/10209} -> PackageSetting{bbd75de com.oearth.androioearth01/10212} BLOCKED
2025-11-08 17:48:05.613   618-677   AppsFilter              system_server                        I  interaction: PackageSetting{82264f8 app.organicmaps.debug/10210} -> PackageSetting{bbd75de com.oearth.androioearth01/10212} BLOCKED
2025-11-08 17:48:05.613   618-677   AppsFilter              system_server                        I  interaction: PackageSetting{5154951 com.android.microdroid.empty_payload/10199} -> PackageSetting{9e45866 com.oearth.androioearth01/10212} BLOCKED
2025-11-08 17:48:05.613   618-677   AppsFilter              system_server                        I  interaction: PackageSetting{3076b63 com.example.androioearthdemo/10211} -> PackageSetting{9e45866 com.oearth.androioearth01/10212} BLOCKED
2025-11-08 17:48:05.613   618-677   AppsFilter              system_server                        I  interaction: PackageSetting{ed0accc com.example.mynavdrawer/10209} -> PackageSetting{9e45866 com.oearth.androioearth01/10212} BLOCKED
2025-11-08 17:48:05.613   618-677   AppsFilter              system_server                        I  interaction: PackageSetting{82264f8 app.organicmaps.debug/10210} -> PackageSetting{9e45866 com.oearth.androioearth01/10212} BLOCKED
2025-11-08 17:48:05.638   618-677   AppsFilter              system_server                        I  interaction: PackageSetting{a2c7e60 com.android.microdroid.empty_payload/10199} -> PackageSetting{c3cc9c1 com.oearth.androioearth01/10212} BLOCKED
2025-11-08 17:48:05.638   618-677   AppsFilter              system_server                        I  interaction: PackageSetting{ce1abde com.example.androioearthdemo/10211} -> PackageSetting{c3cc9c1 com.oearth.androioearth01/10212} BLOCKED
2025-11-08 17:48:05.638   618-677   AppsFilter              system_server                        I  interaction: PackageSetting{a2801bf com.example.mynavdrawer/10209} -> PackageSetting{c3cc9c1 com.oearth.androioearth01/10212} BLOCKED
2025-11-08 17:48:05.638   618-677   AppsFilter              system_server                        I  interaction: PackageSetting{c4b208c app.organicmaps.debug/10210} -> PackageSetting{c3cc9c1 com.oearth.androioearth01/10212} BLOCKED
2025-11-08 17:48:05.664   618-677   ActivityManager         system_server                        I  Force stopping com.oearth.androioearth01 appid=10212 user=0: pkg removed
2025-11-08 17:48:05.671  1117-1117  ActivityThread          com.google.android.gms.persistent    D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.671  1150-1150  ActivityThread          com...le.android.apps.nexuslauncher  D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.672  1461-1461  ActivityThread          com...gle.android.inputmethod.latin  D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.672  4688-4688  ActivityThread          com.google.android.configupdater     D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.672  1622-1622  ActivityThread          com.android.emulator.multidisplay    D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.673  1509-1509  ActivityThread          com...ndroid.providers.media.module  D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.673   993-993   ActivityThread          com.android.se                       D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.673  1571-1571  ActivityThread          com....android.googlequicksearchbox  D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.674   952-952   ActivityThread          com.android.networkstack.process     D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.674  1051-1051  ActivityThread          com.google.android.ext.services      D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.674   855-855   ActivityThread          com.android.systemui                 D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.675   618-737   PackageConfigPersister  system_server                        W  App-specific configuration not found for packageName: com.oearth.androioearth01 and userId: 0
2025-11-08 17:48:05.676  1609-1609  ActivityThread          com.google.android.apps.messaging    D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.676  1549-1549  ActivityThread          com.google.android.as                D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.680   618-826   SdkSandboxManager       system_server                        I  No SDKs used. Skipping SDK data reconcilation for CallingInfo{mUid=10212, mPackageName='com.oearth.androioearth01, mAppProcessToken='null'}
2025-11-08 17:48:05.680 10647-10647 ActivityThread          com.android.settings                 D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.685   618-826   SdkSandboxManager       system_server                        I  No SDKs used. Skipping SDK data reconcilation for CallingInfo{mUid=10212, mPackageName='com.oearth.androioearth01, mAppProcessToken='null'}
2025-11-08 17:48:05.685  1549-1549  AiAiEcho                com.google.android.as                I  AppFetcherImpl onPackageChanged com.oearth.androioearth01.
2025-11-08 17:48:05.685   618-819   ShortcutService         system_server                        D  replacing package: com.oearth.androioearth01 userId0
2025-11-08 17:48:05.686   618-819   ShortcutService         system_server                        D  handlePackageUpdateFinished: com.oearth.androioearth01 user=0
2025-11-08 17:48:05.686  1150-1203  PackageUpdatedTask      com...le.android.apps.nexuslauncher  D  Package updated: mOp=UPDATE packages=[com.oearth.androioearth01]
2025-11-08 17:48:05.689   618-819   ShortcutService         system_server                        D  rescanPackageIfNeeded 0@com.oearth.androioearth01, forceRescan=true , isNewApp=true
2025-11-08 17:48:05.689  1549-13208 AiAiEcho                com.google.android.as                I  AppIndexer Package:[com.oearth.androioearth01] UserProfile:[0] Enabled:[true].
2025-11-08 17:48:05.689  1549-13208 AiAiEcho                com.google.android.as                I  AppFetcherImplV2 updateApps package:[com.oearth.androioearth01], userId:[0], reason:[package is updated.].
2025-11-08 17:48:05.689   618-819   ShortcutService         system_server                        D  Package com.oearth.androioearth01 has 0 manifest shortcut(s), and 0 share target(s)
2025-11-08 17:48:05.694  1025-1025  ActivityThread          com.android.phone                    D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.695  1025-1025  CarrierSvcBindHelper    com.android.phone                    D  onPackageUpdateFinished: com.oearth.androioearth01
2025-11-08 17:48:05.695  1025-1025  CarrierSvcBindHelper    com.android.phone                    D  onPackageModified: com.oearth.androioearth01
2025-11-08 17:48:05.697 11494-11494 ActivityThread          com....android.permissioncontroller  D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.700  1117-1117  ActivityThread          com.google.android.gms.persistent    D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.700  1150-1150  ActivityThread          com...le.android.apps.nexuslauncher  D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.701 10647-10647 ActivityThread          com.android.settings                 D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.702  1549-1549  ActivityThread          com.google.android.as                D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.704  1509-1509  ActivityThread          com...ndroid.providers.media.module  D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.704  1609-1609  ActivityThread          com.google.android.apps.messaging    D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.704  4688-4688  ActivityThread          com.google.android.configupdater     D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.705  1571-1571  ActivityThread          com....android.googlequicksearchbox  D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.705  1461-1461  ActivityThread          com...gle.android.inputmethod.latin  D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.705  1622-1622  ActivityThread          com.android.emulator.multidisplay    D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.705   993-993   ActivityThread          com.android.se                       D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.705  1051-1051  ActivityThread          com.google.android.ext.services      D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.705   952-952   ActivityThread          com.android.networkstack.process     D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.706   855-855   ActivityThread          com.android.systemui                 D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.710   618-618   Telecom                 system_server                        I  CarModeTracker: Package com.oearth.androioearth01 is not tracked.: SSH.oR@AHI
2025-11-08 17:48:05.714   618-618   ActivityThread          system_server                        D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.721  1025-1210  ImsResolver             com.android.phone                    D  maybeAddedImsService, packageName: com.oearth.androioearth01
2025-11-08 17:48:05.727 11494-11494 SafetyLabe...stReceiver com....android.permissioncontroller  I  received broadcast packageName: com.oearth.androioearth01, current user: UserHandle{0}, packageChangeEvent: UPDATE, intent user: UserHandle{0}
2025-11-08 17:48:05.728  1025-1025  ActivityThread          com.android.phone                    D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.757  1150-1162  s.nexuslauncher         com...le.android.apps.nexuslauncher  W  ApkAssets: Deleting an ApkAssets object '<empty> and /data/app/~~EApFJKn0TYks1NB7znMWgA==/com.oearth.androioearth01-kkGgvQ6-x5_Ioed2KatziA==/base.apk' with 1 weak references
2025-11-08 17:48:05.759  1150-1162  s.nexuslauncher         com...le.android.apps.nexuslauncher  W  ApkAssets: Deleting an ApkAssets object '<empty> and /data/app/~~rbcPWBYsEg6E5mfqaQEjhw==/com.oearth.androioearth01-uTGgp89vXvEJUneZSzlXLw==/base.apk' with 1 weak references
2025-11-08 17:48:05.766   618-634   ActivityManager         system_server                        I  Force stopping com.oearth.androioearth01 appid=10212 user=0: from pid 13233
2025-11-08 17:48:05.767   618-634   AppsFilter              system_server                        I  interaction: PackageSetting{a2c7e60 com.android.microdroid.empty_payload/10199} -> PackageSetting{c3cc9c1 com.oearth.androioearth01/10212} BLOCKED
2025-11-08 17:48:05.767   618-634   AppsFilter              system_server                        I  interaction: PackageSetting{ce1abde com.example.androioearthdemo/10211} -> PackageSetting{c3cc9c1 com.oearth.androioearth01/10212} BLOCKED
2025-11-08 17:48:05.767   618-634   AppsFilter              system_server                        I  interaction: PackageSetting{a2801bf com.example.mynavdrawer/10209} -> PackageSetting{c3cc9c1 com.oearth.androioearth01/10212} BLOCKED
2025-11-08 17:48:05.767   618-634   AppsFilter              system_server                        I  interaction: PackageSetting{c4b208c app.organicmaps.debug/10210} -> PackageSetting{c3cc9c1 com.oearth.androioearth01/10212} BLOCKED
2025-11-08 17:48:05.772  1025-1025  CarrierSvcBindHelper    com.android.phone                    D  onHandleForceStop: [com.oearth.androioearth01]
2025-11-08 17:48:05.778   618-618   ActivityThread          system_server                        D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.781   618-618   AlarmManager            system_server                        W  Package com.oearth.androioearth01, uid 10212 lost permission to set exact alarms!
2025-11-08 17:48:05.801  1549-1557  ogle.android.as         com.google.android.as                W  ApkAssets: Deleting an ApkAssets object '<empty> and /data/app/~~rbcPWBYsEg6E5mfqaQEjhw==/com.oearth.androioearth01-uTGgp89vXvEJUneZSzlXLw==/base.apk' with 1 weak references
2025-11-08 17:48:05.805 11494-11494 ActivityThread          com....android.permissioncontroller  D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.889   618-1016  ActivityTaskManager     system_server                        I  START u0 {act=android.intent.action.MAIN cat=[android.intent.category.LAUNCHER] flg=0x10000000 cmp=com.oearth.androioearth01/.osgEarthViewer} with LAUNCH_MULTIPLE from uid 2000 (BAL_ALLOW_PERMISSION) result code=0
2025-11-08 17:48:05.889   855-898   WindowManagerShell      com.android.systemui                 V  Transition requested (#20): android.os.BinderProxy@dc8a194 TransitionRequestInfo { type = OPEN, triggerTask = TaskInfo{userId=0 taskId=203 displayId=0 isRunning=true baseIntent=Intent { act=android.intent.action.MAIN cat=[android.intent.category.LAUNCHER] flg=0x10000000 cmp=com.oearth.androioearth01/.osgEarthViewer } baseActivity=ComponentInfo{com.oearth.androioearth01/com.oearth.androioearth01.osgEarthViewer} topActivity=ComponentInfo{com.oearth.androioearth01/com.oearth.androioearth01.osgEarthViewer} origActivity=null realActivity=ComponentInfo{com.oearth.androioearth01/com.oearth.androioearth01.osgEarthViewer} numActivities=1 lastActiveTime=18146339 supportsMultiWindow=true resizeMode=1 isResizeable=true minWidth=-1 minHeight=-1 defaultMinSize=220 token=WCT{android.window.IWindowContainerToken$Stub$Proxy@c20143d} topActivityType=1 pictureInPictureParams=null shouldDockBigOverlays=false launchIntoPipHostTaskId=-1 lastParentTaskIdBeforePip=-1 displayCutoutSafeInsets=null topActivityInfo=ActivityInfo{4016432 com.oearth.androioearth01.osgEarthViewer} launchCookies=[] positionInParent=Point(0, 0) parentTaskId=-1 isFocused=false isVisible=false isVisibleRequested=false isSleeping=false locusId=null displayAreaFeatureId=1 isTopActivityTransparent=false appCompatTaskInfo=AppCompatTaskInfo { topActivityInSizeCompat=false topActivityEligibleForLetterboxEducation= falseisLetterboxEducationEnabled= true isLetterboxDoubleTapEnabled= false topActivityEligibleForUserAspectRatioButton= true topActivityBoundsLetterboxed= false isFromLetterboxDoubleTap= false topActivityLetterboxVerticalPosition= -1 topActivityLetterboxHorizontalPosition= -1 topActivityLetterboxWidth=2208 topActivityLetterboxHeight=1840 isUserFullscreenOverrideEnabled=false isSystemFullscreenOverrideEnabled=false cameraCompatTaskInfo=CameraCompatTaskInfo { cameraCompatControlState=hidden freeformCameraCompatMode=inactive}}}, pipTask = null, remoteTransition = null, displayChange = null, flags = 0, debugId = 20 }
2025-11-08 17:48:05.893   618-1016  AppsFilter              system_server                        I  interaction: PackageSetting{a2c7e60 com.android.microdroid.empty_payload/10199} -> PackageSetting{a247d92 com.oearth.androioearth01/10212} BLOCKED
2025-11-08 17:48:05.893   618-1016  AppsFilter              system_server                        I  interaction: PackageSetting{ce1abde com.example.androioearthdemo/10211} -> PackageSetting{a247d92 com.oearth.androioearth01/10212} BLOCKED
2025-11-08 17:48:05.893   618-1016  AppsFilter              system_server                        I  interaction: PackageSetting{a2801bf com.example.mynavdrawer/10209} -> PackageSetting{a247d92 com.oearth.androioearth01/10212} BLOCKED
2025-11-08 17:48:05.893   618-1016  AppsFilter              system_server                        I  interaction: PackageSetting{c4b208c app.organicmaps.debug/10210} -> PackageSetting{a247d92 com.oearth.androioearth01/10212} BLOCKED
2025-11-08 17:48:05.896  1150-1150  TopTaskTracker          com...le.android.apps.nexuslauncher  I  onTaskMovedToFront: (moved taskInfo to front) taskId=203, baseIntent=Intent { act=android.intent.action.MAIN cat=[android.intent.category.LAUNCHER] flg=0x10000000 cmp=com.oearth.androioearth01/.osgEarthViewer }
2025-11-08 17:48:05.899   398-398   Zygote                  pid-398                              D  mbuffer starts with 21, nice name is com.oearth.androioearth01, mEnd = 1431, mNext = 333, mLinesLeft = 9, mFd = 5
2025-11-08 17:48:05.900  1460-1460  ActivityThread          com.google.android.gms               D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.900  1460-1460  ActivityThread          com.google.android.gms               D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:05.915 13313-13313 .androioearth01         pid-13313                            I  Late-enabling -Xcheck:jni
2025-11-08 17:48:05.918   618-2605  CoreBackPreview         system_server                        D  Window{5c1dd8c u0 Splash Screen com.oearth.androioearth01}: Setting back callback OnBackInvokedCallbackInfo{mCallback=android.window.IOnBackInvokedCallback$Stub$Proxy@76f87fd, mPriority=0, mIsAnimationCallback=false}
2025-11-08 17:48:05.938 13313-13313 .androioearth01         pid-13313                            I  Using CollectorTypeCMC GC.
2025-11-08 17:48:05.939 13313-13313 .androioearth01         pid-13313                            W  Unexpected CPU variant for x86: x86_64.
                                                                                                    Known variants: atom, sandybridge, silvermont, goldmont, goldmont-plus, goldmont-without-sha-xsaves, tremont, kabylake, default
2025-11-08 17:48:05.993   618-637   WindowManager           system_server                        V  Sent Transition (#20) createdAt=11-08 17:48:05.885 via request=TransitionRequestInfo { type = OPEN, triggerTask = TaskInfo{userId=0 taskId=203 displayId=0 isRunning=true baseIntent=Intent { act=android.intent.action.MAIN cat=[android.intent.category.LAUNCHER] flg=0x10000000 cmp=com.oearth.androioearth01/.osgEarthViewer } baseActivity=ComponentInfo{com.oearth.androioearth01/com.oearth.androioearth01.osgEarthViewer} topActivity=ComponentInfo{com.oearth.androioearth01/com.oearth.androioearth01.osgEarthViewer} origActivity=null realActivity=ComponentInfo{com.oearth.androioearth01/com.oearth.androioearth01.osgEarthViewer} numActivities=1 lastActiveTime=18146339 supportsMultiWindow=true resizeMode=1 isResizeable=true minWidth=-1 minHeight=-1 defaultMinSize=220 token=WCT{RemoteToken{81ca568 Task{db431c7 #203 type=standard A=10212:com.oearth.androioearth01}}} topActivityType=1 pictureInPictureParams=null shouldDockBigOverlays=false launchIntoPipHostTaskId=-1 lastParentTaskIdBeforePip=-1 displayCutoutSafeInsets=null topActivityInfo=ActivityInfo{5084d81 com.oearth.androioearth01.osgEarthViewer} launchCookies=[] positionInParent=Point(0, 0) parentTaskId=-1 isFocused=false isVisible=false isVisibleRequested=false isSleeping=false locusId=null displayAreaFeatureId=1 isTopActivityTransparent=false appCompatTaskInfo=AppCompatTaskInfo { topActivityInSizeCompat=false topActivityEligibleForLetterboxEducation= falseisLetterboxEducationEnabled= true isLetterboxDoubleTapEnabled= false topActivityEligibleForUserAspectRatioButton= true topActivityBoundsLetterboxed= false isFromLetterboxDoubleTap= false topActivityLetterboxVerticalPosition= -1 topActivityLetterboxHorizontalPosition= -1 topActivityLetterboxWidth=2208 topActivityLetterboxHeight=1840 isUserFullscreenOverrideEnabled=false isSystemFullscreenOverrideEnabled=false cameraCompatTaskInfo=CameraCompatTaskInfo { cameraCompatControlState=hidden freeformCameraCompatMode=inactive}}}, pipTask = null, remoteTransition = null, displayChange = null, flags = 0, debugId = 20 }
2025-11-08 17:48:05.994   618-637   WindowManager           system_server                        V      info={id=20 t=OPEN f=0x0 trk=0 r=[0@Point(0, 0)] c=[
                                                                                                            {WCT{RemoteToken{81ca568 Task{db431c7 #203 type=standard A=10212:com.oearth.androioearth01}}} m=OPEN f=NONE leash=Surface(name=Task=203)/@0x959a902 sb=Rect(0, 0 - 2208, 1840) eb=Rect(0, 0 - 2208, 1840) d=0 taskParent=-1},
                                                                                                            {WCT{RemoteToken{e8a4f9d Task{101709c #1 type=home}}} m=TO_BACK f=SHOW_WALLPAPER leash=Surface(name=Task=1)/@0x32bcddb sb=Rect(0, 0 - 2208, 1840) eb=Rect(0, 0 - 2208, 1840) d=0 taskParent=-1}
                                                                                                        ]}
2025-11-08 17:48:06.037  2475-2475  ActivityThread          com.android.vending                  D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:06.037  2475-2475  ActivityThread          com.android.vending                  D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:06.211 13363-13363 DEBUG                   pid-13363                            A  Cmdline: /system/bin/app_process64 -Xcompiler-option --generate-mini-debug-info /system/bin --application --nice-name=com.oearth.androioearth01 com.android.internal.os.WrapperInit 70 36 android.app.ActivityThread seq=90
2025-11-08 17:48:06.211 13363-13363 DEBUG                   pid-13363                            A        #01 pc 00000000000681d1  /data/app/~~rbcPWBYsEg6E5mfqaQEjhw==/com.oearth.androioearth01-uTGgp89vXvEJUneZSzlXLw==/lib/x86_64/libclang_rt.asan-x86_64-android.so (BuildId: f84ac7f72cacc1abcf16cfc927bedd3be194254c)
2025-11-08 17:48:06.211 13363-13363 DEBUG                   pid-13363                            A        #02 pc 0000000000067000  /data/app/~~rbcPWBYsEg6E5mfqaQEjhw==/com.oearth.androioearth01-uTGgp89vXvEJUneZSzlXLw==/lib/x86_64/libclang_rt.asan-x86_64-android.so (BuildId: f84ac7f72cacc1abcf16cfc927bedd3be194254c)
2025-11-08 17:48:06.211 13363-13363 DEBUG                   pid-13363                            A        #03 pc 000000000005edb4  /data/app/~~rbcPWBYsEg6E5mfqaQEjhw==/com.oearth.androioearth01-uTGgp89vXvEJUneZSzlXLw==/lib/x86_64/libclang_rt.asan-x86_64-android.so (BuildId: f84ac7f72cacc1abcf16cfc927bedd3be194254c)
2025-11-08 17:48:06.211 13363-13363 DEBUG                   pid-13363                            A        #04 pc 000000000005eeb8  /data/app/~~rbcPWBYsEg6E5mfqaQEjhw==/com.oearth.androioearth01-uTGgp89vXvEJUneZSzlXLw==/lib/x86_64/libclang_rt.asan-x86_64-android.so (BuildId: f84ac7f72cacc1abcf16cfc927bedd3be194254c)
2025-11-08 17:48:06.211 13363-13363 DEBUG                   pid-13363                            A        #05 pc 0000000000088623  /data/app/~~rbcPWBYsEg6E5mfqaQEjhw==/com.oearth.androioearth01-uTGgp89vXvEJUneZSzlXLw==/lib/x86_64/libclang_rt.asan-x86_64-android.so (BuildId: f84ac7f72cacc1abcf16cfc927bedd3be194254c)
2025-11-08 17:48:06.211 13363-13363 DEBUG                   pid-13363                            A        #06 pc 00000000000e64d8  /data/app/~~rbcPWBYsEg6E5mfqaQEjhw==/com.oearth.androioearth01-uTGgp89vXvEJUneZSzlXLw==/lib/x86_64/libclang_rt.asan-x86_64-android.so (BuildId: f84ac7f72cacc1abcf16cfc927bedd3be194254c)
2025-11-08 17:48:06.211 13363-13363 DEBUG                   pid-13363                            A        #07 pc 00000000000e66ba  /data/app/~~rbcPWBYsEg6E5mfqaQEjhw==/com.oearth.androioearth01-uTGgp89vXvEJUneZSzlXLw==/lib/x86_64/libclang_rt.asan-x86_64-android.so (BuildId: f84ac7f72cacc1abcf16cfc927bedd3be194254c)
2025-11-08 17:48:06.211 13363-13363 DEBUG                   pid-13363                            A        #08 pc 000000000008ba9e  /data/app/~~rbcPWBYsEg6E5mfqaQEjhw==/com.oearth.androioearth01-uTGgp89vXvEJUneZSzlXLw==/lib/x86_64/libclang_rt.asan-x86_64-android.so (__interceptor_strcmp+30) (BuildId: f84ac7f72cacc1abcf16cfc927bedd3be194254c)
2025-11-08 17:48:06.217  1762-1762  ActivityThread          com....android.googlequicksearchbox  D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:06.219  1762-1762  ActivityThread          com....android.googlequicksearchbox  D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:06.220  2739-2739  ActivityThread          com.google.android.webview           D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:06.220  2739-2739  ActivityThread          com.google.android.webview           D  Package [com.oearth.androioearth01] reported as REPLACED, but missing application info. Assuming REMOVED.
2025-11-08 17:48:06.234   618-650   ActivityManager         system_server                        I  Start proc 13313:com.oearth.androioearth01/u0a212 for next-top-activity {com.oearth.androioearth01/com.oearth.androioearth01.osgEarthViewer}
2025-11-08 17:48:06.254  1460-13376 SQLiteLog               com.google.android.gms               W  (28) double-quoted string literal: "com.oearth.androioearth01"
2025-11-08 17:48:06.260  1117-13368 ProximityAuth           com.google.android.gms.persistent    I  [RecentAppsMediator] Package added: (user=UserHandle{0}) com.oearth.androioearth01
2025-11-08 17:48:16.234   618-649   ActivityManager         system_server                        W  Process ProcessRecord{f522819 13313:com.oearth.androioearth01/u0a212} failed to attach
2025-11-08 17:48:16.234   618-649   ActivityTaskManager     system_server                        W  ProcessRecord{f522819 13313:com.oearth.androioearth01/u0a212} is removed with pending start ActivityRecord{90ff706 u0 com.oearth.androioearth01/.osgEarthViewer t203}
2025-11-08 17:48:16.235   855-898   WindowManagerShell      com.android.systemui                 V  Transition requested (#21): android.os.BinderProxy@b29e0bf TransitionRequestInfo { type = CLOSE, triggerTask = TaskInfo{userId=0 taskId=203 displayId=0 isRunning=false baseIntent=Intent { act=android.intent.action.MAIN cat=[android.intent.category.LAUNCHER] flg=0x10000000 cmp=com.oearth.androioearth01/.osgEarthViewer } baseActivity=null topActivity=null origActivity=null realActivity=ComponentInfo{com.oearth.androioearth01/com.oearth.androioearth01.osgEarthViewer} numActivities=0 lastActiveTime=18146339 supportsMultiWindow=true resizeMode=1 isResizeable=true minWidth=-1 minHeight=-1 defaultMinSize=220 token=WCT{android.window.IWindowContainerToken$Stub$Proxy@609138c} topActivityType=1 pictureInPictureParams=null shouldDockBigOverlays=false launchIntoPipHostTaskId=-1 lastParentTaskIdBeforePip=-1 displayCutoutSafeInsets=null topActivityInfo=null launchCookies=[] positionInParent=Point(0, 0) parentTaskId=-1 isFocused=false isVisible=true isVisibleRequested=true isSleeping=false locusId=null displayAreaFeatureId=1 isTopActivityTransparent=false appCompatTaskInfo=AppCompatTaskInfo { topActivityInSizeCompat=false topActivityEligibleForLetterboxEducation= falseisLetterboxEducationEnabled= false isLetterboxDoubleTapEnabled= false topActivityEligibleForUserAspectRatioButton= false topActivityBoundsLetterboxed= false isFromLetterboxDoubleTap= false topActivityLetterboxVerticalPosition= -1 topActivityLetterboxHorizontalPosition= -1 topActivityLetterboxWidth=-1 topActivityLetterboxHeight=-1 isUserFullscreenOverrideEnabled=false isSystemFullscreenOverrideEnabled=false cameraCompatTaskInfo=CameraCompatTaskInfo { cameraCompatControlState=hidden freeformCameraCompatMode=inactive}}}, pipTask = null, remoteTransition = null, displayChange = null, flags = 0, debugId = 21 }
2025-11-08 17:48:16.238   618-649   ActivityManager         system_server                        I  Killing 13313:com.oearth.androioearth01/u0a212 (adj -10000): start timeout
2025-11-08 17:48:16.239   618-701   UsageStatsService       system_server                        W  Unexpected activity event reported! (com.oearth.androioearth01/com.oearth.androioearth01.osgEarthViewer event : 23 instanceId : 63833076)
2025-11-08 17:48:16.490   618-637   WindowManager           system_server                        V  Sent Transition (#21) createdAt=11-08 17:48:16.235 via request=TransitionRequestInfo { type = CLOSE, triggerTask = TaskInfo{userId=0 taskId=203 displayId=0 isRunning=false baseIntent=Intent { act=android.intent.action.MAIN cat=[android.intent.category.LAUNCHER] flg=0x10000000 cmp=com.oearth.androioearth01/.osgEarthViewer } baseActivity=null topActivity=null origActivity=null realActivity=ComponentInfo{com.oearth.androioearth01/com.oearth.androioearth01.osgEarthViewer} numActivities=0 lastActiveTime=18146339 supportsMultiWindow=true resizeMode=1 isResizeable=true minWidth=-1 minHeight=-1 defaultMinSize=220 token=WCT{RemoteToken{81ca568 Task{db431c7 #203 type=standard A=10212:com.oearth.androioearth01}}} topActivityType=1 pictureInPictureParams=null shouldDockBigOverlays=false launchIntoPipHostTaskId=-1 lastParentTaskIdBeforePip=-1 displayCutoutSafeInsets=null topActivityInfo=null launchCookies=[] positionInParent=Point(0, 0) parentTaskId=-1 isFocused=false isVisible=true isVisibleRequested=true isSleeping=false locusId=null displayAreaFeatureId=1 isTopActivityTransparent=false appCompatTaskInfo=AppCompatTaskInfo { topActivityInSizeCompat=false topActivityEligibleForLetterboxEducation= falseisLetterboxEducationEnabled= false isLetterboxDoubleTapEnabled= false topActivityEligibleForUserAspectRatioButton= false topActivityBoundsLetterboxed= false isFromLetterboxDoubleTap= false topActivityLetterboxVerticalPosition= -1 topActivityLetterboxHorizontalPosition= -1 topActivityLetterboxWidth=-1 topActivityLetterboxHeight=-1 isUserFullscreenOverrideEnabled=false isSystemFullscreenOverrideEnabled=false cameraCompatTaskInfo=CameraCompatTaskInfo { cameraCompatControlState=hidden freeformCameraCompatMode=inactive}}}, pipTask = null, remoteTransition = null, displayChange = null, flags = 0, debugId = 21 }
2025-11-08 17:48:16.490   618-637   WindowManager           system_server                        V      info={id=21 t=CLOSE f=0x0 trk=0 r=[0@Point(0, 0)] c=[
                                                                                                            {WCT{RemoteToken{e8a4f9d Task{101709c #1 type=home}}} m=TO_FRONT f=SHOW_WALLPAPER leash=Surface(name=Task=1)/@0x32bcddb sb=Rect(0, 0 - 2208, 1840) eb=Rect(0, 0 - 2208, 1840) d=0 taskParent=-1},
                                                                                                            {WCT{RemoteToken{81ca568 Task{db431c7 #203 type=standard A=10212:com.oearth.androioearth01}}} m=CLOSE f=NONE leash=Surface(name=Task=203)/@0x959a902 sb=Rect(0, 0 - 2208, 1840) eb=Rect(0, 0 - 2208, 1840) d=0 taskParent=-1},
                                                                                                            {null m=TO_FRONT f=IS_WALLPAPER leash=Surface(name=WallpaperWindowToken{5598b64 token=android.os.Binder@f0470f7})/@0xc9f6199 sb=Rect(0, 0 - 2208, 1840) eb=Rect(0, 0 - 2208, 1840) d=0}
                                                                                                        ]}
2025-11-08 17:48:16.498   618-686   CoreBackPreview         system_server                        D  Window{5c1dd8c u0 Splash Screen com.oearth.androioearth01 EXITING}: Setting back callback null
2025-11-08 17:48:16.498   618-2609  InputManager-JNI        system_server                        W  Input channel object '5c1dd8c Splash Screen com.oearth.androioearth01 (client)' was disposed without first being removed with the input manager!
2025-11-08 17:48:21.376  1460-1467  gle.android.gms         com.google.android.gms               W  ApkAssets: Deleting an ApkAssets object '<empty> and /data/app/~~rbcPWBYsEg6E5mfqaQEjhw==/com.oearth.androioearth01-uTGgp89vXvEJUneZSzlXLw==/base.apk' with 1 weak references
2025-11-08 17:48:25.995 13377-13390 .apps.wellbeing         com.google.android.apps.wellbeing    W  ApkAssets: Deleting an ApkAssets object '<empty> and /data/app/~~rbcPWBYsEg6E5mfqaQEjhw==/com.oearth.androioearth01-uTGgp89vXvEJUneZSzlXLw==/base.apk' with 1 weak references
2025-11-08 17:48:29.591   618-631   system_server           system_server                        W  ApkAssets: Deleting an ApkAssets object '<empty> and /data/app/~~EApFJKn0TYks1NB7znMWgA==/com.oearth.androioearth01-kkGgvQ6-x5_Ioed2KatziA==/base.apk' with 1 weak references
```

看到日志，您的应用在启动过程中遇到了 **ASan 初始化失败** 的问题。从日志可以看到：

1. **应用正常安装和启动**
2. **ASan 库已正确加载** (`libclang_rt.asan-x86_64-android.so`)
3. **但在 ASan 初始化阶段崩溃**（调用栈显示在 ASan 库内部）

## 🔍 问题分析

关键错误信息：
```
#08 pc 000000000008ba9e  /data/app/.../libclang_rt.asan-x86_64-android.so (__interceptor_strcmp+30)
```

这表明 ASan 在拦截 `strcmp` 函数时发生了崩溃，这是典型的 **ASan 内存映射冲突** 问题。

## 🛠️ 立即解决方案

### 方案1：完全禁用 ASan（推荐用于继续开发）

**修改 CMakeLists.txt**：
```cmake
# 注释掉 ASan 配置
# if(ANDROID AND CMAKE_BUILD_TYPE STREQUAL "Debug")
#     add_compile_options(-fsanitize=address -fno-omit-frame-pointer)
#     add_link_options(-fsanitize=address)
# endif()

# 改为普通调试配置
if(ANDROID AND CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_compile_options(-g -O0 -DDEBUG)
endif()
```

**删除或禁用 wrap.sh**：
```bash
# 重命名 wrap.sh 文件，使其不生效
mv app/src/main/jniLibs/x86_64/wrap.sh app/src/main/jniLibs/x86_64/wrap.sh.disabled
mv app/src/main/jniLibs/arm64-v8a/wrap.sh app/src/main/jniLibs/arm64-v8a/wrap.sh.disabled
```

### 方案2：使用更稳定的内存检测工具

**改用 LeakSanitizer**：
```cmake
if(ANDROID AND CMAKE_BUILD_TYPE STREQUAL "Debug")
    # 只检测内存泄漏，不检测越界访问
    add_compile_options(-fsanitize=leak -fno-omit-frame-pointer)
    add_link_options(-fsanitize=leak)
endif()
```

### 方案3：尝试不同的 ASan 配置

**修改 wrap.sh**：
```bash
#!/system/bin/sh
HERE="$(cd "$(dirname "$0")" && pwd)"

# 尝试不同的配置
export ASAN_OPTIONS="
    verbosity=1
    debug=1
    abort_on_error=0  # 不立即终止，尝试继续运行
    allow_user_segv_handler=1
    handle_segv=0
    handle_sigbus=0
    handle_abort=0
    handle_sigfpe=0
    handle_sigill=0
"

ASAN_LIB=$(ls $HERE/libclang_rt.asan-*-android.so 2>/dev/null)

if [ -f "$ASAN_LIB" ]; then
    echo "尝试加载 ASan 库: $ASAN_LIB"
    export LD_PRELOAD="$ASAN_LIB"
fi

exec "$@"
```

## 🔧 清理和重建步骤

### 1. 清理项目
```bash
./gradlew clean
rm -rf app/build
rm -rf .cxx
```

### 2. 移除 ASan 相关配置
**检查 app/build.gradle**：
```gradle
android {
    buildTypes {
        debug {
            packagingOptions {
                // 移除 ASan 相关配置
                // pickFirst '**/libclang_rt.asan-*.so'
                // jniLibs { useLegacyPackaging true }
            }
        }
    }
}
```

### 3. 重新构建
```bash
./gradlew assembleDebug
```

## 📋 验证修复

### 检查 APK 内容
```bash
# 确认 ASan 库不再被强制打包
unzip -l app-debug.apk | grep libclang_rt.asan
```

### 测试启动
```bash
# 卸载旧版本
adb uninstall com.oearth.androioearth01

# 安装新版本
adb install app-debug.apk

# 启动应用
adb shell am start -n com.oearth.androioearth01/.osgEarthViewer
```

## 🎯 长期解决方案建议

### 1. 使用其他调试工具
- **Valgrind**（在开发阶段使用）
- **Android Studio 的内存分析器**
- **简单的日志和断言**

### 2. 分阶段启用内存检测
```cmake
# 第一阶段：基础调试
option(ENABLE_BASIC_DEBUG "Enable basic debug options" ON)
if(ENABLE_BASIC_DEBUG)
    add_compile_options(-g -O0 -DDEBUG)
endif()

# 第二阶段：内存检测（谨慎启用）
option(ENABLE_MEMORY_CHECK "Enable memory checking tools" OFF)
if(ENABLE_MEMORY_CHECK)
    # 使用更轻量的工具
    add_compile_options(-fsanitize=leak)
    add_link_options(-fsanitize=leak)
endif()
```

### 3. 平台特定的内存检测
```cmake
# 根据平台选择不同的调试策略
if(ANDROID)
    # Android 平台使用系统工具
    add_compile_options(-g -DANDROID_DEBUG)
elseif(UNIX)
    # Linux 平台可以使用更完整的 ASan
    add_compile_options(-fsanitize=address)
    add_link_options(-fsanitize=address)
endif()
```

## 📝 总结

**推荐立即执行方案1**（完全禁用 ASan），因为：

1. **ASan 在 Android 上存在兼容性问题**
2. **影响开发效率**
3. **有其他替代的调试工具**

等您的应用核心功能稳定后，再考虑使用更适合 Android 平台的内存检测工具。

================================================================
# 4.使用 Address Sanitizer 调试内存损坏问题

https://developer.android.google.cn/games/agde/address-sanitizer?hl=zh-cn

## 前提条件
注意： 请使用 HWASan，而不是 ASan，因为 HWASan 的速度更快且内存开销更低。不过，HWASan 有一些额外的要求。
### HWASan 要求

如需使用 HWASan，请执行以下操作：
> 1. 您必须使用 AGDE 24.1.99 或更高版本。
> 2. 应用必须使用 NDK 26 或更高版本构建。
> 3. 应用必须使用目标 SDK 34 或更高版本构建。
> 4. 目标设备必须是搭载 Android 14（API 级别 34）或更高版本的 arm64-v8a 设备。

### 在项目中使用共享 C++ 标准库
受已知问题影响，使用 libc++_static 时 ASan 与 C++ 异常处理机制不兼容。使用 libc++_shared 时则不会发生这个问题。

HWASan 有自己的运算符 new 和 delete 实现，如果标准库是以静态方式关联到项目的，则您无法使用此实现。

**注意：使用这些功能时，您必须在项目中使用标准库的共享版本。**
如需更改此设置，请参阅本文档的关联 C++ 标准库部分。

**注意：如果您已启用 ASan 但未启用 C++ 共享库，将会遇到构建错误。**

### 启用帧指针生成功能
HWASan 和 ASan 使用基于帧指针的快速展开程序 (unwinder)，根据内存分配和取消分配事件来生成堆栈轨迹信息。也就是说，您必须在 C++ 编译器设置中启用帧指针生成功能，才能使用这些功能。具体来说，您需要停用帧指针省略优化功能。

如需更改此设置，请参阅本文档的启用帧指针生成功能部分。

===========================================================

# 5.ndk程序 配置asan后 INSTALL_FAILED_INVALID_APK

为什么android ndk程序 配置asan后，安装时出错 ：The application could not be installed: INSTALL_FAILED_INVALID_APK The APKs are invalid.
remark-abner：chmod +x app/src/main/resources/lib/*/wrap.sh

这个错误通常是因为 ASan (Address Sanitizer) 配置不正确导致的 APK 结构或依赖问题。以下是主要的原因和解决方案：

## 🔍 主要问题原因

### 1. **缺少 ASan 运行时库**
这是最常见的原因。ASan 需要特定的运行时库，但这些库没有正确打包到 APK 中。

### 2. **wrap.sh 脚本配置错误**
ASan 需要 wrap.sh 脚本在应用启动时预加载 ASan 运行时库。

### 3. **ABI 不匹配**
ASan 库的架构与目标设备架构不匹配。

### 4. **清单配置问题**
debuggable 或其他清单配置不正确。

## 🛠️ 解决方案

### 方案一：检查并修复 ASan 库配置

#### 1. **确保 ASan 库正确打包**
在 `app/build.gradle` 中添加：

```gradle
android {
    buildTypes {
        debug {
            packagingOptions {
                jniLibs {
                    useLegacyPackaging = true
                }
            }
        }
    }
    
    sourceSets {
        main {
            jniLibs.srcDirs = ['src/main/jniLibs']
        }
    }
}
```

#### 2. **创建正确的目录结构**
确保项目有以下结构：
```
app/src/main/
├── jniLibs/
│   ├── arm64-v8a/
│   │   └── libclang_rt.asan-aarch64-android.so
│   ├── armeabi-v7a/
│   │   └── libclang_rt.asan-arm-android.so
│   ├── x86/
│   │   └── libclang_rt.asan-i686-android.so
│   └── x86_64/
│       └── libclang_rt.asan-x86_64-android.so
└── resources/lib/
    ├── arm64-v8a/
    │   └── wrap.sh
    ├── armeabi-v7a/
    │   └── wrap.sh
    ├── x86/
    │   └── wrap.sh
    └── x86_64/
        └── wrap.sh
```

### 方案二：修复 wrap.sh 脚本

#### 1. **创建正确的 wrap.sh**
每个 ABI 目录下的 `wrap.sh` 内容：

```bash
#!/system/bin/sh
HERE="$(cd "$(dirname "$0")" && pwd)"
export ASAN_OPTIONS=log_to_syslog=false,allow_user_segv_handler=1
ASAN_LIB=$(ls $HERE/libclang_rt.asan-*-android.so)
if [ -f "$HERE/libc++_shared.so" ]; then
    export LD_PRELOAD="$ASAN_LIB $HERE/libc++_shared.so"
else
    export LD_PRELOAD="$ASAN_LIB"
fi
exec "$@"
```

#### 2. **设置 wrap.sh 权限**
```bash
chmod +x app/src/main/resources/lib/*/wrap.sh
```

### 方案三：获取 ASan 运行时库

#### 从 NDK 复制 ASan 库：
```bash
# 查找 ASan 库路径
find $ANDROID_NDK_HOME -name "libclang_rt.asan-*-android.so"

# 通常路径示例
NDK_ASAN_PATH="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/lib64/clang/*/lib/linux/"
```

#### 复制命令示例：
```bash
# 创建目录
mkdir -p app/src/main/jniLibs/arm64-v8a
mkdir -p app/src/main/jniLibs/x86_64

# 复制 ASan 库
cp $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/lib64/clang/*/lib/linux/aarch64/libclang_rt.asan-aarch64-android.so app/src/main/jniLibs/arm64-v8a/
cp $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/lib64/clang/*/lib/linux/x86_64/libclang_rt.asan-x86_64-android.so app/src/main/jniLibs/x86_64/
```

### 方案四：完整的 CMake 和 Gradle 配置

#### 1. **CMakeLists.txt 配置**
```cmake
target_compile_options(${TARGET} PRIVATE
    -fsanitize=address
    -fno-omit-frame-pointer
)

set_target_properties(${TARGET} PROPERTIES
    LINK_FLAGS -fsanitize=address
)
```

#### 2. **app/build.gradle 完整配置**
```gradle
android {
    defaultConfig {
        externalNativeBuild {
            cmake {
                arguments "-DANDROID_ARM_MODE=arm",
                          "-DANDROID_STL=c++_shared"
                cFlags "-fsanitize=address -fno-omit-frame-pointer"
                cppFlags "-fsanitize=address -fno-omit-frame-pointer"
            }
        }
        ndk {
            abiFilters 'arm64-v8a', 'x86_64' // 根据目标设备选择
        }
    }
    
    buildTypes {
        debug {
            debuggable true
            jniDebuggable true
            packagingOptions {
                jniLibs {
                    useLegacyPackaging true
                }
            }
        }
    }
    
    externalNativeBuild {
        cmake {
            path "src/main/cpp/CMakeLists.txt"
        }
    }
}
```

### 方案五：检查设备兼容性

#### 1. **验证设备架构**
```bash
adb shell getprop ro.product.cpu.abi
```

#### 2. **确保 ABI 匹配**
如果设备是 `arm64-v8a`，APK 必须包含对应的 ASan 库。

### 方案六：清理和重建

#### 1. **彻底清理项目**
```bash
./gradlew clean
rm -rf app/build
rm -rf .cxx
```

#### 2. **重新构建**
```bash
./gradlew assembleDebug
```

## 🔧 调试步骤

如果问题仍然存在，按以下步骤调试：

1. **检查 APK 内容**：
   ```bash
   unzip -l app-debug.apk | grep -E "(asan|wrap)"
   ```

2. **验证安装**：
   ```bash
   adb install -r -g app-debug.apk
   ```

3. **查看详细错误**：
   ```bash
   adb logcat | grep -i "packageinstaller\|installd"
   ```

## 💡 替代方案：考虑使用 HWASan

如果继续遇到问题，可以考虑使用 HWASan（特别是对于 Android 11+ 设备）：
- 更好的性能
- 更低的内存开销
- 更简单的配置

**最重要的检查点**：
1. ✅ 确保 `useLegacyPackaging = true`
2. ✅ 确保 ASan 库在正确的 jniLibs 目录
3. ✅ 确保 wrap.sh 脚本存在且权限正确
4. ✅ 确保设备架构与 APK 中的 ABI 匹配

按照以上步骤逐一检查，应该能解决 INSTALL_FAILED_INVALID_APK 错误。

==============================================================
# 6.chmod +x  wrap.sh命令执行后，INSTALL_FAILED_INVALID_APK错误不出现了；但是 dlopen failed: library "libandroioearth01.so" not found

chmod +x app/src/main/resources/lib/*/wrap.sh命令执行后，INSTALL_FAILED_INVALID_APK错误不出现了；但是

```
2025-11-10 12:27:59.198 20442-20442 libEGL                  com.oearth.androioearth01            D  loaded /vendor/lib64/egl/libEGL_adreno.so
2025-11-10 12:27:59.202 20442-20442 libEGL                  com.oearth.androioearth01            D  loaded /vendor/lib64/egl/libGLESv1_CM_adreno.so
2025-11-10 12:27:59.206 20442-20442 libEGL                  com.oearth.androioearth01            D  loaded /vendor/lib64/egl/libGLESv2_adreno.so
2025-11-10 12:27:59.236 20442-20442 Zygote                  com.oearth.androioearth01            I  Preloading shared libraries...
2025-11-10 12:27:59.241 20442-20442 Zygote                  com.oearth.androioearth01            I  Called ZygoteHooks.endPreload()
2025-11-10 12:27:59.241 20442-20442 Zygote                  com.oearth.androioearth01            I  Installed AndroidKeyStoreProvider in 0ms.
2025-11-10 12:27:59.244 20442-20442 Zygote                  com.oearth.androioearth01            I  Warmed up JCA providers in 3ms.
2025-11-10 12:27:59.244 20442-20442 Zygote                  com.oearth.androioearth01            D  end preload
2025-11-10 12:27:59.038 20442-20442 VgcUtil                 com.oearth.androioearth01            E  getFile name :theme_dir_pathnot exit in vgc_path_config.xml
2025-11-10 12:27:59.520 20442-20442 NetworkSecurityConfig   com.oearth.androioearth01            D  No Network Security Config specified, using platform default
2025-11-10 12:27:59.520 20442-20442 NetworkSecurityConfig   com.oearth.androioearth01            D  No Network Security Config specified, using platform default
2025-11-10 12:27:59.560 20442-20442 OSG Activity            com.oearth.androioearth01            D  ^-^::::::osgEarthViewer::onCreate(Bundle icicle)..........
2025-11-10 12:27:59.562 20442-20442 AndroidRuntime          com.oearth.androioearth01            D  Shutting down VM
2025-11-10 12:27:59.563 20442-20442 AndroidRuntime          com.oearth.androioearth01            E  FATAL EXCEPTION: main
                    Process: com.oearth.androioearth01, PID: 20442
                    java.lang.UnsatisfiedLinkError: dlopen failed: library "libandroioearth01.so" not found
                        at java.lang.Runtime.loadLibrary0(Runtime.java:1087)
                        at java.lang.Runtime.loadLibrary0(Runtime.java:1008)
                        at java.lang.System.loadLibrary(System.java:1664)
                        at com.oearth.androioearth01.osgEarthViewer.onCreate(osgEarthViewer.java:39)
                        at android.app.Activity.performCreate(Activity.java:8129)
                        at android.app.Activity.performCreate(Activity.java:8113)
                        at android.app.Instrumentation.callActivityOnCreate(Instrumentation.java:1359)
                        at android.app.ActivityThread.performLaunchActivity(ActivityThread.java:3753)
                        at android.app.ActivityThread.handleLaunchActivity(ActivityThread.java:3938)
                        at android.app.servertransaction.LaunchActivityItem.execute(LaunchActivityItem.java:85)
                        at android.app.servertransaction.TransactionExecutor.executeCallbacks(TransactionExecutor.java:135)
                        at android.app.servertransaction.TransactionExecutor.execute(TransactionExecutor.java:95)
                        at android.app.ActivityThread$H.handleMessage(ActivityThread.java:2345)
                        at android.os.Handler.dispatchMessage(Handler.java:106)
                        at android.os.Looper.loop(Looper.java:257)
```
但是app/build/outputs/apk/debug/app-debug.apk 里是存在 相关so的。如何解决这个问题？

这个问题是因为 ASan 的 `wrap.sh` 脚本改变了库文件的加载路径，导致系统找不到你的原生库 `libandroioearth01.so`。下面是详细的解决方案：

## 🔍 问题分析

当使用 ASan 时，`wrap.sh` 脚本会设置 `LD_PRELOAD` 环境变量，这改变了动态库的加载行为。你的原生库虽然存在于 APK 中，但系统在加载时无法正确找到它。

## 🛠️ 解决方案

### 方案一：修改 wrap.sh 脚本（推荐）

修改 `app/src/main/resources/lib/[abi]/wrap.sh` 文件：

```bash
#!/system/bin/sh
HERE="$(cd "$(dirname "$0")" && pwd)"
export ASAN_OPTIONS=log_to_syslog=false,allow_user_segv_handler=1

# 设置库搜索路径，包含应用的原生库目录
export LD_LIBRARY_PATH="$HERE:$LD_LIBRARY_PATH"

# 加载 ASan 运行时库
ASAN_LIB=$(ls $HERE/libclang_rt.asan-*-android.so)

if [ -f "$HERE/libc++_shared.so" ]; then
    export LD_PRELOAD="$ASAN_LIB $HERE/libc++_shared.so"
else
    export LD_PRELOAD="$ASAN_LIB"
fi

# 添加调试信息（可选）
echo "ASan wrap.sh: Loading libraries from $HERE" > /data/local/tmp/asan_debug.log

exec "$@"
```

### 方案二：检查并修复原生库打包

#### 1. **验证 APK 中的库文件**
```bash
# 检查 APK 中是否包含你的原生库
unzip -l app/build/outputs/apk/debug/app-debug.apk | grep libandroioearth01.so

# 检查库文件在 APK 中的路径
unzip -l app-debug.apk | grep -E "lib/.*\.so"
```

#### 2. **确保正确的 Gradle 配置**
在 `app/build.gradle` 中添加：

```gradle
android {
    buildTypes {
        debug {
            packagingOptions {
                jniLibs {
                    useLegacyPackaging = true
                }
                // 确保不排除任何库文件
                pickFirst 'lib/**/libandroioearth01.so'
                pickFirst 'lib/**/libc++_shared.so'
            }
        }
    }
    
    sourceSets {
        main {
            jniLibs.srcDirs = ['src/main/jniLibs', 'path/to/your/built/libs']
        }
    }
}
```

### 方案三：修改 CMake 配置

确保你的 CMake 配置正确生成和安装库文件：

```cmake
# 在 CMakeLists.txt 中确保正确安装库文件
add_library(androioearth01 SHARED your_source_files.cpp)

# 设置输出属性
set_target_properties(androioearth01 PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/libs/${ANDROID_ABI}
    OUTPUT_NAME "androioearth01"
)

# 安装规则
install(TARGETS androioearth01
    LIBRARY DESTINATION lib/${ANDROID_ABI}
)
```

### 方案四：修改 Java 层库加载代码

在 `osgEarthViewer.java` 中尝试不同的加载方式：

```java
public class osgEarthViewer extends Activity {
    static {
        try {
            // 先尝试加载依赖库（如果有）
            // System.loadLibrary("c++_shared");
            
            // 然后加载主库
            System.loadLibrary("androioearth01");
        } catch (UnsatisfiedLinkError e) {
            Log.e("OSG", "Failed to load native library: " + e.getMessage());
            
            // 尝试从绝对路径加载（调试用）
            try {
                String libPath = getApplicationInfo().nativeLibraryDir + "/libandroioearth01.so";
                System.load(libPath);
                Log.d("OSG", "Loaded library from: " + libPath);
            } catch (UnsatisfiedLinkError e2) {
                Log.e("OSG", "Also failed to load from absolute path: " + e2.getMessage());
            }
        }
    }
    
    @Override
    protected void onCreate(Bundle icicle) {
        super.onCreate(icicle);
        Log.d("OSG Activity", "^-^::::::osgEarthViewer::onCreate(Bundle icicle)..........");
        // 你的其他代码
    }
}
```

### 方案五：调试步骤

#### 1. **检查运行时库路径**
修改 `wrap.sh` 添加调试信息：

```bash
#!/system/bin/sh
HERE="$(cd "$(dirname "$0")" && pwd)"

# 记录调试信息
echo "=== ASan Debug Info ===" > /data/local/tmp/asan_debug.txt
echo "HERE: $HERE" >> /data/local/tmp/asan_debug.txt
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH" >> /data/local/tmp/asan_debug.txt
ls -la $HERE >> /data/local/tmp/asan_debug.txt

export ASAN_OPTIONS=log_to_syslog=false,allow_user_segv_handler=1
export LD_LIBRARY_PATH="$HERE:$LD_LIBRARY_PATH"

ASAN_LIB=$(ls $HERE/libclang_rt.asan-*-android.so)
export LD_PRELOAD="$ASAN_LIB"

exec "$@"
```

#### 2. **检查日志**
```bash
adb shell cat /data/local/tmp/asan_debug.txt
```

### 方案六：验证库文件完整性

#### 1. **检查库文件架构**
```bash
# 检查库文件的架构信息
file app/build/intermediates/merged_native_libs/debug/out/lib/arm64-v8a/libandroioearth01.so

# 或者从 APK 中提取检查
unzip -p app-debug.apk lib/arm64-v8a/libandroioearth01.so > temp.so
file temp.so
```

#### 2. **验证依赖关系**
```bash
# 检查库文件的依赖
aarch64-linux-android-readelf -d libandroioearth01.so
```

## 🔧 快速测试方案

先尝试最简单的解决方案：

1. **修改 wrap.sh** - 添加 `export LD_LIBRARY_PATH="$HERE:$LD_LIBRARY_PATH"`
2. **清理并重建**：
   ```bash
   ./gradlew clean
   ./gradlew assembleDebug
   ```
3. **重新安装**：
   ```bash
   adb uninstall com.oearth.androioearth01
   adb install app-debug.apk
   ```

## 💡 根本原因

问题的根本原因是：ASan 的 `wrap.sh` 改变了动态库加载环境，但没有正确设置库搜索路径来包含你的应用原生库目录。添加 `LD_LIBRARY_PATH` 环境变量可以解决这个问题。

**推荐按顺序尝试**：
1. 方案一（修改 wrap.sh）
2. 方案四（修改 Java 加载代码）
3. 方案二（检查 Gradle 配置）

通常方案一就能解决问题。如果还有问题，请提供修改后的具体错误信息。
=============================================================
# 7. 如何做才可以让asan直接输出带函数名和行号的callstack

要让 ASan 直接输出带函数名和行号的调用栈，你需要确保以下几点：

## 🔧 **启用符号化 (Symbolization)**

### **1. 确保编译时包含调试信息**
在编译时添加 `-g` 标志：

```cmake
# CMakeLists.txt
target_compile_options(your_target PRIVATE
    -fsanitize=address
    -fno-omit-frame-pointer
    -g  # 添加调试信息
)

set_target_properties(your_target PROPERTIES
    LINK_FLAGS "-fsanitize=address"
)
```

或者在 `build.gradle` 中：
```gradle
android {
    defaultConfig {
        externalNativeBuild {
            cmake {
                cFlags "-fsanitize=address -fno-omit-frame-pointer -g"
                cppFlags "-fsanitize=address -fno-omit-frame-pointer -g"
            }
        }
    }
}
```

### **2. 修改 ASAN_OPTIONS 配置**
在 `wrap.sh` 中设置正确的 ASan 选项：

```bash
#!/system/bin/sh
HERE="$(cd "$(dirname "$0")" && pwd)"

# 启用符号化
export ASAN_OPTIONS="\
log_to_syslog=false,\
allow_user_segv_handler=1,\
abort_on_error=1,\
symbolize=1,\
symbolize_inline_frames=1,\
print_symbolize_stack_trace=1,\
fast_unwind_on_malloc=0"  # 使用慢速但更准确的展开

export LD_LIBRARY_PATH="$HERE:$LD_LIBRARY_PATH"

ASAN_LIB="$HERE/libclang_rt.asan-aarch64-android.so"
if [ -f "$ASAN_LIB" ]; then
    export LD_PRELOAD="$ASAN_LIB"
fi

exec "$@"
```

### **3. 确保 llvm-symbolizer 可用**
ASan 需要 `llvm-symbolizer` 来解析符号：

#### **方法一：将 llvm-symbolizer 打包到 APK 中**
```bash
# 从 NDK 复制 llvm-symbolizer
cp $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-symbolizer \
   app/src/main/jniLibs/arm64-v8a/

# 在 wrap.sh 中设置路径
export ASAN_SYMBOLIZER_PATH="$HERE/llvm-symbolizer"
```

#### **方法二：使用主机上的符号化（推荐）**
让 ASan 输出原始地址，然后在主机上符号化：

```bash
# 在 wrap.sh 中
export ASAN_OPTIONS="\
log_to_syslog=false,\
allow_user_segv_handler=1,\
abort_on_error=1,\
symbolize=0"  # 禁用设备端符号化

# 保存原始日志到文件
export ASAN_OPTIONS="$ASAN_OPTIONS,log_path=/data/local/tmp/asan.log"
```

然后在主机上使用 `ndk-stack` 或 `addr2line` 符号化：

### **4. 使用 ndk-stack 符号化**
```bash
# 从设备获取日志
adb logcat -d > logcat.txt

# 使用 ndk-stack 符号化
$ANDROID_NDK_HOME/ndk-stack -sym app/build/intermediates/merged_native_libs/debug/out/lib/arm64-v8a/ -i logcat.txt
```

### **5. 使用 addr2line 手动符号化**
```bash
# 提取地址并符号化
echo "0x724b3397a0" | $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android-addr2line -e app/build/intermediates/merged_native_libs/debug/out/lib/arm64-v8a/libandroioearth01.so -f -C -p

# 批量处理所有地址
grep -oE "0x[0-9a-f]+" logcat.txt | sort -u | while read addr; do
    echo "Address: $addr"
    $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android-addr2line -e app/build/intermediates/merged_native_libs/debug/out/lib/arm64-v8a/libandroioearth01.so -f -C -p $addr
    echo "---"
done
```

### **6. 完整的符号化脚本**
创建一个符号化脚本 `symbolize.sh`：

```bash
#!/bin/bash
LOG_FILE=$1
SO_FILE=$2

if [ -z "$LOG_FILE" ] || [ -z "$SO_FILE" ]; then
    echo "Usage: ./symbolize.sh <log_file> <so_file>"
    exit 1
fi

# 提取所有唯一的地址
grep -oE "0x[0-9a-f]+" "$LOG_FILE" | sort -u | while read addr; do
    # 使用 addr2line 符号化
    result=$(aarch64-linux-android-addr2line -e "$SO_FILE" -f -C -p $addr 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "Address: $addr"
        echo "Symbol: $result"
        echo "---"
    fi
done
```

使用方式：
```bash
adb logcat -d > crash.log
./symbolize.sh crash.log app/build/intermediates/merged_native_libs/debug/out/lib/arm64-v8a/libandroioearth01.so
```

### **7. 优化编译配置**
确保发布版本也包含调试信息：

```gradle
android {
    buildTypes {
        debug {
            debuggable true
            jniDebuggable true
            externalNativeBuild {
                cmake {
                    arguments "-DCMAKE_BUILD_TYPE=RelWithDebInfo"  # 发布版本带调试信息
                }
            }
        }
        release {
            debuggable true  # 即使发布版本也允许调试
            jniDebuggable true
            externalNativeBuild {
                cmake {
                    arguments "-DCMAKE_BUILD_TYPE=RelWithDebInfo"
                }
            }
        }
    }
}
```

## ✅ **验证配置**

### **检查调试信息**
```bash
# 检查 so 文件是否包含调试信息
file app/build/intermediates/merged_native_libs/debug/out/lib/arm64-v8a/libandroioearth01.so

# 检查符号表
aarch64-linux-android-readelf -s libandroioearth01.so | head -20
```

### **测试符号化**
```bash
# 测试单个地址符号化
echo "0x724b3397a0" | aarch64-linux-android-addr2line -e libandroioearth01.so -f -C -p
```

## 📋 **总结**

要实现 ASan 直接输出带函数名的调用栈，你需要：

1. **编译时添加 `-g` 标志**包含调试信息
2. **设置 `ASAN_OPTIONS`** 启用符号化
3. **确保 `llvm-symbolizer` 可用**（设备端或主机端）
4. **使用正确的构建类型**（如 `RelWithDebInfo`）

如果设备端符号化困难，**推荐使用主机端符号化**：让 ASan 输出原始地址，然后在开发机上使用 `ndk-stack` 或 `addr2line` 进行符号化。

=================================================================
# 8.ndk so编译时，如何确保栈回溯能识别函数名
## Qndk so编译，可以用下面的配置吗
```sh
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g -O0") # 调试信息 + 无优化
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -rdynamic") # 导出符号，确保栈回溯能识别函数名
```
## A-Yuanbao
**不完全适用，需要针对 Android NDK 进行调整。** 你的配置主要是为桌面 Linux 设计的，在 Android 上需要修改。

## 问题分析

### 1. **-g -O0 标志**
```cmake
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g -O0")  # 基本可用，但有更好选择
```
- ✅ 在 Android 上基本可用
- ⚠️ 但应该使用 NDK 推荐的调试配置

### 2. **-rdynamic 标志**
```cmake
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -rdynamic")  # ❌ 不适用于 Android
```
- ❌ `-rdynamic` 是 GCC 的 ELF 特定选项
- ❌ Android 使用不同的链接器和二进制格式
- ❌ 对 so 库无效（只对可执行文件有效）

## Android NDK 推荐的配置

### 完整的 CMakeLists.txt 示例

```cmake
cmake_minimum_required(VERSION 3.18.1)
project(mynative)

# 设置编译标准
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Android 特定的编译标志
if(ANDROID)
    # 调试信息配置（比 -g 更精确）
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        # 调试版本配置
        set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -g -O0 -fno-omit-frame-pointer -fno-optimize-sibling-calls")
        set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -g -O0 -fno-omit-frame-pointer -fno-optimize-sibling-calls")
    else()
        # 发布版本配置（保持可调试性）
        set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -g1 -O2 -fomit-frame-pointer")
        set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -g1 -O2 -fomit-frame-pointer")
    endif()

    # Android 栈回溯和符号导出配置
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--export-dynamic")
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-z,defs")  # 检查未定义符号
    
    # 确保所有符号都保留在符号表中
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--whole-archive")
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--no-whole-archive")
endif()

# 添加 NDK 日志库
find_library(log-lib log)

# 创建原生库
add_library(
    mynative
    SHARED
    native-lib.cpp
    # 其他源文件...
)

# 链接库
target_link_libraries(
    mynative
    android
    ${log-lib}
    
    # 添加 unwind 库以支持更好的栈回溯
    unwind
)
```

## 专门的栈回溯配置

### 方案1：使用 Android 的 unwind 库
```cmake
# 在 CMakeLists.txt 中添加
target_link_libraries(your_library unwind)

# 在代码中使用
#include <unwind.h>
#include <dlfcn.h>
#include <cxxabi.h>

struct BacktraceState {
    void** current;
    void** end;
};

static _Unwind_Reason_Code unwindCallback(struct _Unwind_Context* context, void* arg) {
    BacktraceState* state = static_cast<BacktraceState*>(arg);
    uintptr_t pc = _Unwind_GetIP(context);
    if (pc) {
        if (state->current == state->end) {
            return _URC_END_OF_STACK;
        } else {
            *state->current++ = reinterpret_cast<void*>(pc);
        }
    }
    return _URC_NO_REASON;
}

size_t captureBacktrace(void** buffer, size max) {
    BacktraceState state = {buffer, buffer + max};
    _Unwind_Backtrace(unwindCallback, &state);
    return state.current - buffer;
}
```

### 方案2：配置 so 库的符号可见性
```cmake
# 确保所有符号都导出到动态符号表
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--export-dynamic")
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-E")  # 导出所有符号

# 或者针对特定符号
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-exported_symbols_list,exported_symbols.txt")

# exported_symbols.txt 内容：
# Java_*
# JNI_OnLoad
# JNI_OnUnload
# 其他需要导出的符号...
```

## 针对不同构建类型的配置

### 调试版本配置
```cmake
# 在 app/build.gradle 中配置
android {
    buildTypes {
        debug {
            externalNativeBuild {
                cmake {
                    arguments "-DCMAKE_BUILD_TYPE=Debug"
                    cFlags "-g -O0 -DDEBUG -fno-omit-frame-pointer"
                    cppFlags "-g -O0 -DDEBUG -fno-omit-frame-pointer -frtti -fexceptions"
                }
            }
            
            // 确保调试符号包含在 so 中
            packagingOptions {
                doNotStrip "**/*.so"
            }
        }
        
        release {
            externalNativeBuild {
                cmake {
                    arguments "-DCMAKE_BUILD_TYPE=Release"
                    cFlags "-O2 -DNDEBUG"
                    cppFlags "-O2 -DNDEBUG -frtti -fexceptions"
                }
            }
            
            // 发布版本可以移除调试符号以减小体积
            packagingOptions {
                doNotStrip "**/*.so"  # 或者选择性保留
            }
        }
    }
}
```

## 完整的 Android 栈回溯解决方案

### CMakeLists.txt
```cmake
cmake_minimum_required(VERSION 3.18.1)
project(mynative)

# 基础配置
set(CMAKE_CXX_STANDARD 11)

# 调试配置
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g -O0 -fno-omit-frame-pointer")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g -O0 -fno-omit-frame-pointer")
    
    # 栈保护
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fstack-protector-all")
endif()

# Android 特定的符号导出
if(ANDROID)
    # 确保 JNI 函数可被动态查找
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--export-dynamic")
    
    # 保留所有符号用于调试
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--strip-debug")  # 发布时移除
endif()

add_library(mynative SHARED native-lib.cpp)

# 链接栈回溯相关库
target_link_libraries(mynative 
    android
    log
    unwind
    dl  # 动态链接库支持
)
```

### 对应的 C++ 代码
```cpp
#include <unwind.h>
#include <dlfcn.h>
#include <android/log.h>

#define LOG_TAG "NativeDebug"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

// 栈回溯实现
struct BacktraceState {
    void** current;
    void** end;
};

static _Unwind_Reason_Code unwindCallback(struct _Unwind_Context* context, void* arg) {
    BacktraceState* state = static_cast<BacktraceState*>(arg);
    uintptr_t pc = _Unwind_GetIP(context);
    
    if (pc && state->current != state->end) {
        *state->current++ = reinterpret_cast<void*>(pc);
    }
    return state->current == state->end ? _URC_END_OF_STACK : _URC_NO_REASON;
}

extern "C" size_t captureBacktrace(void** buffer, size_t max) {
    BacktraceState state = {buffer, buffer + max};
    _Unwind_Backtrace(unwindCallback, &state);
    return state.current - buffer;
}

extern "C" void printBacktrace() {
    const size_t max = 30;
    void* buffer[max];
    
    size_t count = captureBacktrace(buffer, max);
    for (size_t i = 0; i < count; ++i) {
        Dl_info info;
        if (dladdr(buffer[i], &info)) {
            LOGI("#%zd: %p %s", i, buffer[i], info.dli_sname ? info.dli_sname : "?");
        }
    }
}
```

## 总结

**你的原始配置需要修改为**：

```cmake
# 替换这个：
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -rdynamic")

# 改为 Android 适用的：
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--export-dynamic")
target_link_libraries(your_library unwind dl)
```

**关键点**：
1. 使用 `-Wl,--export-dynamic` 替代 `-rdynamic`
2. 链接 `unwind` 和 `dl` 库以获得更好的栈回溯
3. 在调试版本中使用 `-fno-omit-frame-pointer`
4. 通过 `packagingOptions` 控制符号剥离

这样配置后，你就能在 Android NDK 编译中获得良好的调试体验和栈回溯能力。