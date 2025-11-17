    如何用asan调试ndk so
在将 osgearth移植到 android上时，so中出现了crash。为了调试方便，给so加了asan配置。
工作环境： 主机操作系统ubuntu 24.04 ，android studio 版本2025.1.4,cmake version 3.31.8。
注意：不用 HWAsan的原因是，osgearth 的众多第三方依赖库中，有些第三方依赖库的源码编译系统不支持HWAsan。

# 1. 如何给 给ndk so加了asan配置
参照 https://developer.android.google.cn/ndk/guides/asan?hl=cs给 ndk so加了asan配置。

## 1.1 在模块的 build.gradle 中：
```
android {
    defaultConfig {
        externalNativeBuild {
            cmake {
                // Can also use system or none as ANDROID_STL.
                arguments "-DANDROID_ARM_MODE=arm", "-DANDROID_STL=c++_shared"
            }
        }
    }
}
```
在应用的 build.gradle 文件中将 useLegacyPackaging 设置为 true。 
示例见 “ https://github.com/python2019-08/osgearth0x/blob/main/platform/AndroiOearth01/app/build.gradle.kts ”

## 1.2 添加asan编译链接选项
在jni工程或第三方库工程的 根CMakeLists.txt 中 添加asan编译链接选项
```cmake
add_compile_options( -fsanitize=address -g -O0 -fno-omit-frame-pointer )
add_link_options( -fsanitize=address -g "LINKER:-export-dynamic" "LINKER:-z,defs")  
```
### 1.2.1 使用 ASan 时，所有依赖库都需要使用相同的 ASan 选项编译
 在android ndk 开发调试ndk so liba.so时， 依赖链是 "liba.so -> libb.a -> libc.a" ， 则**所有的依赖库（liba.so 、libb.a、libc.a）都需要使用相同的 ASan 选项编译** 以下是详细规则：

**核心原则：一致性编译** 
**要求：** 所有三个库都必须使用 `-fsanitize=address` 编译。
 
**技术原理**
### **为什么需要一致性？**
(1) 内存布局统一 : ASan 会修改内存分配和布局，混合编译会导致内存访问错误。
(2) 符号解析一致: ASan 替换了标准的内存函数（如 `malloc`、`free`），所有库必须使用相同的替换版本。
(3) 运行时兼容性: 部分库使用 ASan 而其他库不使用，会导致运行时崩溃或检测失效。

### 1.2.2 实操：osgearth 的jni so 及第三方库的asan编译
jni so的 CMakeLists.txt的示例 见
    https://github.com/python2019-08/osgearth0x/blob/main/platform/AndroiOearth01/app/src/main/jni/CMakeLists.txt

为了不修改 第三方库源码的CMakeLists.txt，采用 CMAKE_C_FLAGS、CMAKE_CXX_FLAGS来配置
```sh
 CMAKE_C_FLAGS="-fsanitize=address   -g -O0 -fno-omit-frame-pointer" 
 CMAKE_CXX_FLAGS="-fsanitize=address  -g -O0 -fno-omit-frame-pointer" 
 # CMAKE_SHARED_LINKER_FLAGS="-fsanitize=address -Wl,--export-dynamic -Wl,-z,defs"  

 # zlib的cmake配置命令
 cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib} --debug-find \
            "${cmakeCommonParams[@]}"  -DANDROID_ABI="${ABI}" \
 -DCMAKE_C_FLAGS="${CMAKE_C_FLAGS} -DZLIB_DEBUG=1" \
            -DCMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS} -DZLIB_DEBUG=1" \
 -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_zlib} \
            -DCMAKE_EXPORT_PACKAGE_REGISTRY=ON \
 -DZLIB_BUILD_SHARED=OFF \
            -DZLIB_BUILD_STATIC=ON    
```    

有些第三方库是用configure配置编译的，如openssl
```sh
 CMAKE_C_FLAGS="-fsanitize=address   -g -O0 -fno-omit-frame-pointer" 

 # 在编译时标记符号为 "hidden"（仅限动态链接）
 CFLAGS="-fPIC -fvisibility=hidden ${CMAKE_C_FLAGS}" \
    ${SrcDIR_lib}/Configure ${target_ARCH} -d \
 -D__ANDROID_API__=${ABI_LEVEL} \
                --prefix=${INSTALL_PREFIX_openssl} \
 --openssldir=${INSTALL_PREFIX_openssl}/ssl \
                no-shared  no-zlib no-module  no-dso 
```
 第三方库的配置示例 见 
   https://github.com/python2019-08/osgearth0x/blob/main/mk4android.sh


## 1.3 将 ASan 运行时库添加到应用模块的 jniLibs 中。
   如把 libclang_rt.asan-aarch64-android.so 添加到  app/src/main/jniLibs/arm64-v8a/libclang_rt.asan-aarch64-android.so

## 1.4 将 wrap.sh 添加到 src/main/resources/lib目录中的每个目录 。
将包含以下内容的 wrap.sh 文件添加到 src/main/resources/lib 目录中的每个目录。
```sh
#!/system/bin/sh
HERE="$(cd "$(dirname "$0")" && pwd)"
export ASAN_OPTIONS=log_to_syslog=false,allow_user_segv_handler=1
#export ASAN_OPTIONS="log_path=/data/local/tmp/asan.log:help=1:verbosity=2:detect_leaks=1"

# 设置库搜索路径，包含应用的原生库目录
export LD_LIBRARY_PATH="$HERE:$LD_LIBRARY_PATH"

# 加载 ASan 运行时库
ASAN_LIB=$(ls $HERE/libclang_rt.asan-*-android.so)
echo "ASan wrap.sh: Loading libraries ASAN_LIB=${ASAN_LIB}...HERE=${HERE}" 

if [ -f "$HERE/libc++_shared.so" ]; then
 export LD_PRELOAD="$ASAN_LIB $HERE/libc++_shared.so"
else
 export LD_PRELOAD="$ASAN_LIB"
fi

# 添加调试信息（可选）
echo "ASan wrap.sh: Loading libraries from $HERE" > /data/local/tmp/asan_debug.log

exec "$@"
```
## 1.5 目录结构
假设您项目的应用模块的名称为 app，最终的目录结构应包含以下内容：
```txt
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
```


# 2. 编译 

用“ https://github.com/python2019-08/osgearth0x/blob/main/mk4android.sh ”编译第三方库的静态库。
用android studio 编译 jni so 和android apk。

# 3.用手机测试

## 3.1 asan探测到野指针时的log
app 崩溃时，logcat中有 
```txt
2025-11-12 18:04:26.025 12977-12977 wrap.sh                 logwrapper                           I  SUMMARY: AddressSanitizer: heap-use-after-free (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x65b4460) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83) 
2025-11-12 18:04:26.054 12977-12977 chatty                  logwrapper                           I  uid=10440(com.oearth.androioearth01) /system/bin/logwrapper identical 15 lines
2025-11-12 18:04:26.128 12977-12977 chatty                  logwrapper                           I  uid=10440(com.oearth.androioearth01) /system/bin/logwrapper identical 14 lines
2025-11-12 18:04:26.136 13284-13284 DEBUG                   pid-13284                            A  pid: 12978, tid: 12978, name: .androioearth01  >>> com.oearth.androioearth01 <<<
2025-11-12 18:04:26.137 13284-13284 DEBUG                   pid-13284                            A  Abort message: '=================================================================
  ==12978==ERROR: AddressSanitizer: heap-use-after-free on address 0x0055c8c4a218 at pc 0x0070f5047464 bp 0x007fc4a8f330 sp 0x007fc4a8f328
  READ of size 4 at 0x0055c8c4a218 thread T0 (.androioearth01)
      #0 0x70f5047460  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x65b4460) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #1 0x70f50461fc  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x65b31fc) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #2 0x70f5041218  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x65ae218) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #3 0x70f500e134  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x657b134) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #4 0x70f500e08c  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x657b08c) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #5 0x70f3f86620  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x54f3620) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #6 0x70f48f4ad8  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x5e61ad8) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #7 0x70f2c2f088  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x419c088) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #8 0x70f500e054  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x657b054) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #9 0x70f2cafb24  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x421cb24) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #10 0x70f458be0c  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x5af8e0c) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #11 0x70f2c2f088  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x419c088) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #12 0x70f500e054  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x657b054) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #13 0x70f2cafb24  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x421cb24) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #14 0x70f458bd50  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x5af8d50) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #15 0x70f2c2f088  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x419c088) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #16 0x70f500e054  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x657b054) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #17 0x70f2cafb24  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x421cb24) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #18 0x70f458bd50  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x5af8d50) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #19 0x70f2c2f088  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x419c088) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #20 0x70f500e054  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x657b054) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #21 0x70f2cafb24  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x421cb24) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #22 0x70f48f4ad8  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x5e61ad8) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #23 0x70f2c2f088  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x419c088) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #24 0x70f500e054  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x657b054) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #25 0x70f2cafb24  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x421cb24) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #26 0x70f48f4ad8  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x5e61ad8) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #27 0x70f3eb79c8  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x54249c8) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #28 0x70f4423604  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x5990604) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #29 0x70f2c2f088  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x419c088) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #30 0x70f500e054  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x657b054) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #31 0x70f49b1e40  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x5f1ee40) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #32 0x70f4428aa8  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x5995aa8) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #33 0x70f2d9bee0  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x4308ee0) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #34 0x70f2d8ad88  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x42f7d88) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #35 0x70f2db54bc  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x43224bc) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #36 0x70f2c09b78  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x4176b78) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #37 0x70f2c0ea00  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x417ba00) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
 
  0x0055c8c4a218 is located 24 bytes inside of 23040-byte region [0x0055c8c4a200,0x0055c8c4fc00)
  freed by thread T21 (GLThread 17) here:
      #0 0x71f173aba4  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libclang_rt.asan-aarch64-android.so+0xf2ba4) (BuildId: d2089f24857cf6bfee934a5c1e8395bab0e414b6)
      #1 0x70f2bc7b88  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x4134b88) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #2 0x70f2bc7b38  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x4134b38) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #3 0x70f2bc7adc  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x4134adc) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #4 0x70f4944f08  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x5eb1f08) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #5 0x70f4944988  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x5eb1988) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #6 0x70f49454b8  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x5eb24b8) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #7 0x70f494521c  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x5eb221c) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #8 0x70f493f148  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x5eac148) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #9 0x70f493f19c  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x5eac19c) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #10 0x70f4a43550  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x5fb0550) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #11 0x70f4a43970  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x5fb0970) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #12 0x70f48242f0  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x5d912f0) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #13 0x70f4824edc  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x5d91edc) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #14 0x70f4574a2c  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x5ae1a2c) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #15 0x70f4574a54  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x5ae1a54) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #16 0x70f4a43550  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x5fb0550) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #17 0x70f4a43970  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x5fb0970) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #18 0x70f2d28a2c  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x4295a2c) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #19 0x70f310717c  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x467417c) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #20 0x70f3107140  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x4674140) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #21 0x70f31070c0  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x46740c0) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #22 0x70f3106e6c  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x4673e6c) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #23 0x70f3106d18  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x4673d18) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #24 0x70f30f3138  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x4660138) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #25 0x70f48f478c  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x5e6178c) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #26 0x70f4bda6c8  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x61476c8) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #27 0x70f499e114  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x5f0b114) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #28 0x70f4516748  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x5a83748) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
      #29 0x70f4516770  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x5a83770) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83)
 
    ............ 

      SUMMARY: AddressSanitizer: heap-use-after-free (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libandroioearth01.so+0x65b4460) (BuildId: 0d3646fa0f54a8224ed6da161684668a7a27bc83) 
      Shadow bytes around the buggy address:
        0x0055c8c49f80: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
        0x0055c8c4a000: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
        0x0055c8c4a080: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
        0x0055c8c4a100: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
        0x0055c8c4a180: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
      =>0x0055c8c4a200: fd fd fd[fd]fd fd fd fd fd fd fd fd fd fd fd fd
        0x0055c8c4a280: fd fd fd fd fd fd fd fd fd fd fd fd fd fd fd fd
        0x0055c8c4a300: fd fd fd fd fd fd fd fd fd fd fd fd fd fd fd fd
        0x0055c8c4a380: fd fd fd fd fd fd fd fd fd fd fd fd fd fd fd fd
        0x0055c8c4a400: fd fd fd fd fd fd fd fd fd fd fd fd fd fd fd fd
        0x0055c8c4a480: fd fd fd fd fd fd fd fd fd fd fd fd fd fd fd fd
      Shadow byte legend (one shadow byte represents 8 application bytes):
        Addressable:           00
        Partially addressable: 01 02 03 04 05 06 07 
        Heap left redzone:       fa
        Freed heap region:       fd
        Stack left redzone:      f1
        Stack mid redzone:       f2
        Stack right redzone:     f3
        Stack after return:      f5
        Stack use after scope:   f8
        Global redzone:          f9
        Global init order:       f6
        Poisoned by user:        f7
        Container overflow:      fc
        Array cookie:            ac
        Intra object redzone:    bb
        ASan internal:           fe
        Left alloca redzone:     ca
        Right alloca redzone:    cb
      '
2025-11-12 18:04:26.138 13284-13284 DEBUG                   pid-13284                            A        #01 pc 000000000006c5b4  /data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libclang_rt.asan-aarch64-android.so (BuildId: d2089f24857cf6bfee934a5c1e8395bab0e414b6)
```
把log 存到文件  0ndk_asan_log.txt
## 3.2 提取 调用堆栈
用脚本
https://github.com/python2019-08/osgearth0x/blob/main/scripts/ndk_asan_addrs/addr_from_ndk_asan_log.py
从0ndk_asan_log.txt中提取调用堆栈 ,存到1asan_addrs.txt中

```
2025-11-12 18:04:26.137 13284-13284 DEBUG                   pid-13284                            A  Abort message: '=================================================================
      ==12978==ERROR: AddressSanitizer: heap-use-after-free on address 0x0055c8c4a218 at pc 0x0070f5047464 bp 0x007fc4a8f330 sp 0x007fc4a8f328
      READ of size 4 at 0x0055c8c4a218 thread T0 (.androioearth01)
===============================================
"0x65b4460"
"0x65b31fc"
"0x65ae218"
"0x657b134"
"0x657b08c"
"0x54f3620"
"0x5e61ad8"
"0x419c088"
"0x657b054"
"0x421cb24"
"0x5af8e0c"
"0x419c088"
"0x657b054"
"0x421cb24"
"0x5af8d50"
"0x419c088"
"0x657b054"
"0x421cb24"
"0x5af8d50"
"0x419c088"
"0x657b054"
"0x421cb24"
"0x5e61ad8"
"0x419c088"
"0x657b054"
"0x421cb24"
"0x5e61ad8"
"0x54249c8"
"0x5990604"
"0x419c088"
"0x657b054"
"0x5f1ee40"
"0x5995aa8"
"0x4308ee0"
"0x42f7d88"
"0x43224bc"
"0x4176b78"
"0x417ba00"
 
0x0055c8c4a218 is located 24 bytes inside of 23040-byte region [0x0055c8c4a200,0x0055c8c4fc00)
  freed by thread T21 (GLThread 17) here:
===============================================
#0 0x71f173aba4  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libclang_rt.asan-aarch64-android.so+0xf2ba4) (BuildId: d2089f24857cf6bfee934a5c1e8395bab0e414b6)
"0x4134b88"
"0x4134b38"
"0x4134adc"
"0x5eb1f08"
"0x5eb1988"
"0x5eb24b8"
"0x5eb221c"
"0x5eac148"
"0x5eac19c"
"0x5fb0550"
"0x5fb0970"
"0x5d912f0"
"0x5d91edc"
"0x5ae1a2c"
"0x5ae1a54"
"0x5fb0550"
"0x5fb0970"
"0x4295a2c"
"0x467417c"
"0x4674140"
"0x46740c0"
"0x4673e6c"
"0x4673d18"
"0x4660138"
"0x5e6178c"
"0x61476c8"
"0x5f0b114"
"0x5a83748"
"0x5a83770"
```

## 3.3 用addr2line 解析调用堆栈
 
  用基于"${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-addr2line"的脚本 https://github.com/python2019-08/osgearth0x/blob/main/scripts/ndk_asan_addrs/addr2line_parse_crash.sh 解析调用堆栈

  得到：
  ```txt
=== AddressSanitizer 调用栈解析 ===
库文件: /home/abner/abner2/zdev/nv/osgearth0x/platform/AndroiOearth01//app/build/intermediates/cxx/Debug/446nj3h3/obj/libandroioearth01.so
====================================
2025-11-12 18:04:26.136 13284-13284 DEBUG     pid-13284   A  pid: 12978, tid: 12978, name: .androioearth01  >>> com.oearth.androioearth01 <<<
2025-11-12 18:04:26.137 13284-13284 DEBUG     pid-13284   A  Abort message: '=================================================================
    ==12978==ERROR: AddressSanitizer: heap-use-after-free on address 0x0055c8c4a218 at pc 0x0070f5047464 bp 0x007fc4a8f330 sp 0x007fc4a8f328
    READ of size 4 at 0x0055c8c4a218 thread T0 (.androioearth01)

地址: 0x65b4460
void osg::KdTree::intersect<osg::TemplatePrimitiveFunctor<LineSegmentIntersectorUtils::IntersectFunctor<osg::Vec3d, double>>>(osg::TemplatePrimitiveFunctor<LineSegmentIntersectorUtils::IntersectFunctor<osg::Vec3d, double>>&, osg::KdTree::KdNode const&) const at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/KdTree:152

地址: 0x65b31fc
osgUtil::LineSegmentIntersector::intersect(osgUtil::IntersectionVisitor&, osg::Drawable*, osg::Vec3d const&, osg::Vec3d const&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgUtil/LineSegmentIntersector.cpp:598

地址: 0x65ae218
osgUtil::LineSegmentIntersector::intersect(osgUtil::IntersectionVisitor&, osg::Drawable*) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgUtil/LineSegmentIntersector.cpp:562

地址: 0x657b134
osgUtil::IntersectionVisitor::intersect(osg::Drawable*) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osgUtil/IntersectionVisitor:386

地址: 0x657b08c
osgUtil::IntersectionVisitor::apply(osg::Drawable&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgUtil/IntersectionVisitor.cpp:226

地址: 0x54f3620
osg::Drawable::accept(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/Drawable:97

地址: 0x5e61ad8
osg::Group::traverse(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Group.cpp:63

地址: 0x419c088
osg::NodeVisitor::traverse(osg::Node&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/NodeVisitor:277

地址: 0x657b054
osgUtil::IntersectionVisitor::apply(osg::Group&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgUtil/IntersectionVisitor.cpp:219

地址: 0x421cb24
osg::Group::accept(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/Group:38

地址: 0x5af8e0c
osgEarth::REX::TileNode::traverse(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/TileNode.cpp:572

地址: 0x419c088
osg::NodeVisitor::traverse(osg::Node&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/NodeVisitor:277

地址: 0x657b054
osgUtil::IntersectionVisitor::apply(osg::Group&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgUtil/IntersectionVisitor.cpp:219

地址: 0x421cb24
osg::Group::accept(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/Group:38

地址: 0x5af8d50
osgEarth::REX::TileNode::traverse(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/TileNode.cpp:565

地址: 0x419c088
osg::NodeVisitor::traverse(osg::Node&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/NodeVisitor:277

地址: 0x657b054
osgUtil::IntersectionVisitor::apply(osg::Group&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgUtil/IntersectionVisitor.cpp:219

地址: 0x421cb24
osg::Group::accept(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/Group:38

地址: 0x5af8d50
osgEarth::REX::TileNode::traverse(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/TileNode.cpp:565

地址: 0x419c088
osg::NodeVisitor::traverse(osg::Node&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/NodeVisitor:277

地址: 0x657b054
osgUtil::IntersectionVisitor::apply(osg::Group&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgUtil/IntersectionVisitor.cpp:219

地址: 0x421cb24
osg::Group::accept(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/Group:38

地址: 0x5e61ad8
osg::Group::traverse(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Group.cpp:63

地址: 0x419c088
osg::NodeVisitor::traverse(osg::Node&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/NodeVisitor:277

地址: 0x657b054
osgUtil::IntersectionVisitor::apply(osg::Group&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgUtil/IntersectionVisitor.cpp:219

地址: 0x421cb24
osg::Group::accept(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/Group:38

地址: 0x5e61ad8
osg::Group::traverse(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Group.cpp:63

地址: 0x54249c8
osgEarth::TerrainEngineNode::traverse(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/TerrainEngineNode.cpp:325

地址: 0x5990604
osgEarth::REX::RexTerrainEngineNode::traverse(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/RexTerrainEngineNode.cpp:1011

地址: 0x419c088
osg::NodeVisitor::traverse(osg::Node&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/NodeVisitor:277

地址: 0x657b054
osgUtil::IntersectionVisitor::apply(osg::Group&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgUtil/IntersectionVisitor.cpp:219

地址: 0x5f1ee40
osg::NodeVisitor::apply(osg::CoordinateSystemNode&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/NodeVisitor.cpp:122

地址: 0x5995aa8
osgEarth::REX::RexTerrainEngineNode::accept(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/RexTerrainEngineNode:37

地址: 0x4308ee0
osgEarth::Util::EarthManipulator::intersectLookVector(osg::Vec3d&, osg::Vec3d&, osg::Vec3d&) const at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/EarthManipulator.cpp:1405

地址: 0x42f7d88
osgEarth::Util::EarthManipulator::recalculateCenterFromLookVector() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/EarthManipulator.cpp:2465

地址: 0x43224bc
osgEarth::Util::EarthManipulator::zoom(double, double, osg::View*) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/EarthManipulator.cpp:2752

地址: 0x4176b78
OsgMainApp::touchZoomEvent(double) at /mnt/disk2/abner/zdev/nv/osgearth0x/platform/AndroiOearth01/app/src/main/jni/OsgMainApp.cpp:68

地址: 0x417ba00
Java_com_oearth_androioearth01_osgNativeLib_touchZoomEvent at /mnt/disk2/abner/zdev/nv/osgearth0x/platform/AndroiOearth01/app/src/main/jni/osgNativeLib.cpp:82

===================================================================================
  0x0055c8c4a218 is located 24 bytes inside of 23040-byte region [0x0055c8c4a200,0x0055c8c4fc00)
  freed by thread T21 (GLThread 17) here:


地址: 0x4134b88
void std::__ndk1::__libcpp_operator_delete[abi:ne180000]<void*>(void*) at /home/abner/Android/Sdk/ndk/27.0.12077973/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/new:280

地址: 0x4134b38
void std::__ndk1::__do_deallocate_handle_size[abi:ne180000]<>(void*, unsigned long) at /home/abner/Android/Sdk/ndk/27.0.12077973/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/new:302

地址: 0x4134adc
std::__ndk1::__libcpp_deallocate[abi:ne180000](void*, unsigned long, unsigned long) at /home/abner/Android/Sdk/ndk/27.0.12077973/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/new:317

地址: 0x5eb1f08
std::__ndk1::allocator<osg::KdTree::KdNode>::deallocate[abi:ne180000](osg::KdTree::KdNode*, unsigned long) at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/__memory/allocator.h:131

地址: 0x5eb1988
std::__ndk1::allocator_traits<std::__ndk1::allocator<osg::KdTree::KdNode>>::deallocate[abi:ne180000](std::__ndk1::allocator<osg::KdTree::KdNode>&, osg::KdTree::KdNode*, unsigned long) at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/__memory/allocator_traits.h:289

地址: 0x5eb24b8
std::__ndk1::vector<osg::KdTree::KdNode, std::__ndk1::allocator<osg::KdTree::KdNode>>::__destroy_vector::operator()[abi:ne180000]() at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/vector:492

地址: 0x5eb221c
std::__ndk1::vector<osg::KdTree::KdNode, std::__ndk1::allocator<osg::KdTree::KdNode>>::~vector[abi:ne180000]() at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/vector:501

地址: 0x5eac148
osg::KdTree::~KdTree() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/KdTree:26

地址: 0x5eac19c
osg::KdTree::~KdTree() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/KdTree:26

地址: 0x5fb0550
osg::Referenced::signalObserversAndDelete(bool, bool) const at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Referenced.cpp:292

地址: 0x5fb0970
osg::Referenced::unref() const at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Referenced.cpp:348

地址: 0x5d912f0
osg::ref_ptr<osg::Shape>::~ref_ptr() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/ref_ptr:61

地址: 0x5d91edc
osg::Drawable::~Drawable() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Drawable.cpp:281

地址: 0x5ae1a2c
osgEarth::REX::TileDrawable::~TileDrawable() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/TileDrawable.cpp:75

地址: 0x5ae1a54
osgEarth::REX::TileDrawable::~TileDrawable() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/TileDrawable.cpp:73

地址: 0x5fb0550
osg::Referenced::signalObserversAndDelete(bool, bool) const at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Referenced.cpp:292

地址: 0x5fb0970
osg::Referenced::unref() const at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Referenced.cpp:348

地址: 0x4295a2c
osg::ref_ptr<osg::Node>::~ref_ptr() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/ref_ptr:61

地址: 0x467417c
std::__ndk1::allocator<osg::ref_ptr<osg::Node>>::destroy[abi:ne180000](osg::ref_ptr<osg::Node>*) at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/__memory/allocator.h:168

地址: 0x4674140
void std::__ndk1::allocator_traits<std::__ndk1::allocator<osg::ref_ptr<osg::Node>>>::destroy[abi:ne180000]<osg::ref_ptr<osg::Node>, void>(std::__ndk1::allocator<osg::ref_ptr<osg::Node>>&, osg::ref_ptr<osg::Node>*) at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/__memory/allocator_traits.h:311

地址: 0x46740c0
std::__ndk1::vector<osg::ref_ptr<osg::Node>, std::__ndk1::allocator<osg::ref_ptr<osg::Node>>>::__base_destruct_at_end[abi:ne180000](osg::ref_ptr<osg::Node>*) at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/vector:926

地址: 0x4673e6c
std::__ndk1::vector<osg::ref_ptr<osg::Node>, std::__ndk1::allocator<osg::ref_ptr<osg::Node>>>::__clear[abi:ne180000]() at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/vector:920

地址: 0x4673d18
std::__ndk1::vector<osg::ref_ptr<osg::Node>, std::__ndk1::allocator<osg::ref_ptr<osg::Node>>>::__destroy_vector::operator()[abi:ne180000]() at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/vector:490

地址: 0x4660138
std::__ndk1::vector<osg::ref_ptr<osg::Node>, std::__ndk1::allocator<osg::ref_ptr<osg::Node>>>::~vector[abi:ne180000]() at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/vector:501

地址: 0x5e6178c
osg::Group::~Group() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Group.cpp:54

地址: 0x61476c8
osg::Transform::~Transform() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Transform.cpp:143

地址: 0x5f0b114
osg::MatrixTransform::~MatrixTransform() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/MatrixTransform.cpp:41

地址: 0x5a83748
osgEarth::REX::SurfaceNode::~SurfaceNode() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/SurfaceNode:27

地址: 0x5a83770
osgEarth::REX::SurfaceNode::~SurfaceNode() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/SurfaceNode:27
  ```

# 4. ndk 程序加了ASan之后如何去掉asan ？
 
下面的是 腾讯元宝的答案，测试ok。

要去掉 ASan（Address Sanitizer），您需要按照以下步骤操作：

## 4.1 修改 CMake 配置

在 `CMakeLists.txt` 中移除 ASan 相关的编译和链接选项：

```cmake
# 移除这行（或注释掉）
# target_compile_options(${TARGET} PUBLIC -fsanitize=address -fno-omit-frame-pointer)

# 移除这行（或注释掉）
# set_target_properties(${TARGET} PROPERTIES LINK_FLAGS -fsanitize=address)
```

或者直接删除这两部分代码。

## 4.2 修改 build.gradle

在 `app/build.gradle` 中，移除或修改 ASan 相关的配置：

```gradle
android {
    defaultConfig {
        externalNativeBuild {
            cmake {
                // 可以保留其他参数，但确保没有 ASan 相关参数
                arguments "-DANDROID_ARM_MODE=arm", "-DANDROID_STL=c++_shared"
                // 移除任何与 sanitizer 相关的参数
            }
        }
    }
}
```

## 4.3. 清理项目

执行清理操作：
```bash
./gradlew clean
```

或者在 Android Studio 中：
- Build → Clean Project
- File → Invalidate Caches / Restart

## 4.4. 移除 ASan 运行时库

删除 `src/main/jniLibs` 目录下的所有 ASan 库文件：
- `libclang_rt.asan-aarch64-android.so`
- `libclang_rt.asan-arm-android.so`
- `libclang_rt.asan-i686-android.so`
- `libclang_rt.asan-x86_64-android.so`

## 4.5. 移除或禁用 wrap.sh

有两种选择：

**选项一：删除 wrap.sh 文件**
```bash
rm -rf app/src/main/resources/lib
```

**选项二：重命名 wrap.sh 文件（便于以后重新启用）**
```bash
mv app/src/main/resources/lib/arm64-v8a/wrap.sh app/src/main/resources/lib/arm64-v8a/wrap.sh.bak
# 对其他架构重复此操作
```

## 4.6. 重新构建

重新构建项目：
```bash
./gradlew assembleDebug
```

## 4.7验证 ASan 已禁用

检查 APK 内容确认 ASan 库已移除：
```bash
# 查看 APK 中的原生库
unzip -l app/build/outputs/apk/debug/app-debug.apk | grep libclang_rt
```

如果没有输出，说明 ASan 已成功移除。

## 4.8注意事项

1. **性能恢复**：移除 ASan 后，应用性能会恢复正常，内存占用会显著降低
2. **调试信息**：如果需要保留调试信息但不要 ASan，可以保留 `-fno-omit-frame-pointer`
3. **后续调试**：如果需要重新启用 ASan，只需反向操作上述步骤即可

完成以上步骤后，您的应用将不再使用 Address Sanitizer，回归正常的构建和运行模式。  
===================================================================
