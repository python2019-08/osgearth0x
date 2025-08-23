#!/bin/bash

OSG3RD_ROOT=/mnt/disk2/abner/zdev/nv/osg3rd/
OSG3RD_srcDir=${OSG3RD_ROOT}/3rd
OSG3RD_buildDir=${OSG3RD_ROOT}/build_by_sh 
# rm -fr ./build_by_sh 
# rm -fr  ${OSG3RD_buildDir}


OSG3RD_buildDir_ubuntu=${OSG3RD_buildDir}/ubuntu
OSG3RD_INSTALL_PREFIX_ubuntu=${OSG3RD_buildDir_ubuntu}/install/3rd

OSG3RD_buildDir_android=${OSG3RD_buildDir}/android
OSG3RD_INSTALL_PREFIX_android=${OSG3RD_buildDir_android}/install
# 定义需要编译的 Android ABI 列表
ABIS=("arm64-v8a" "armeabi-v7a" "x86" "x86_64")
ANDROID_NDK=/home/abner/Android/Sdk/ndk/27.1.12297006


mkdir -p ${OSG3RD_INSTALL_PREFIX_ubuntu}
mkdir -p ${OSG3RD_INSTALL_PREFIX_android}


# -------------------------------------------------
# zlib
# -------------------------------------------------
isFinished_build_zlib=true 
if [ "${isFinished_build_zlib}" != "true" ]; then 
    echo "========== building zlib 4 ubuntu========== " &&  sleep 5

    # 手动执行配置命令验证
    BuildDIR_lib=${OSG3RD_buildDir_ubuntu}/3rd/zlib/build 
    rm -fr ${BuildDIR_lib}
    mkdir -p ${BuildDIR_lib}
    

    #################################################################### 
    # CMAKE_BUILD_TYPE=Debug
    # CMAKE_C_COMPILER=/usr/bin/clang  # /usr/bin/gcc
    # CMAKE_CXX_COMPILER=/usr/bin/clang++  # /usr/bin/g++    
    # # remark: 当前的 CMakeLists.txt中 未通过 target_compile_definitions 显式指定 ZLIB_DEBUG 宏。
    # cmake -S ${OSG3RD_srcDir}/zlib -B ${BuildDIR_lib} \
    #         -DCMAKE_INSTALL_PREFIX=${OSG3RD_INSTALL_PREFIX_ubuntu}  \
    #         -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}   \
    #         -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}    \
    #         -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} \
    #         -DBUILD_SHARED_LIBS=ON     \
    #         -DZLIB_BUILD_SHARED=ON \
    #         -DZLIB_BUILD_STATIC=ON  \
    #         -DCMAKE_EXE_LINKER_FLAGS="-static" 
    #
    # cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc)
    #
    # cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}
    ####################################################################
 
    cd ${BuildDIR_lib}
    #  --enable-debug  会自动添加 -DZLIB_DEBUG 宏）
    CFLAGS="-fPIC" \
    ${OSG3RD_srcDir}/zlib/configure \
                --prefix=${OSG3RD_INSTALL_PREFIX_ubuntu} \
                --enable-debug  --static

    make  -j$(nproc)  
    make install
    echo "========== finished building zlib 4 ubuntu ========== " &&  sleep 3
fi


# -------------------------------------------------
# zstd
# -------------------------------------------------
isFinished_build_zstd=true
if [ "${isFinished_build_zstd}" != "true" ]; then 
    echo "========== building zstd 4 ubuntu========== " &&  sleep 5

    BuildDIR_lib=${OSG3RD_buildDir_ubuntu}/3rd/zstd/build
    rm -rf   ${BuildDIR_lib}
    mkdir -p ${BuildDIR_lib}    

    cmake -S${OSG3RD_srcDir}/zstd/build/cmake -B ${BuildDIR_lib} \
            -DCMAKE_INSTALL_PREFIX=${OSG3RD_INSTALL_PREFIX_ubuntu}  \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_C_FLAGS="-fPIC" \
            -DCMAKE_CXX_FLAGS="-fPIC" 

    cmake --build ${BuildDIR_lib} -j$(nproc)

    cmake --build ${BuildDIR_lib} --target install    

    echo "========== finished building zstd 4 ubuntu ========== " &&  sleep 3
fi    
 
 
# -------------------------------------------------
# openssl
# -------------------------------------------------
isFinished_build_openssl=true
if [ "${isFinished_build_openssl}" != "true" ]; then 
    echo "========== Building openssl 4 ubuntu ========== " &&  sleep 5

    # 手动执行配置命令验证
    BuildDIR_openssl=${OSG3RD_buildDir_ubuntu}/3rd/openssl/build
    rm -rf   ${BuildDIR_openssl}
    mkdir -p ${BuildDIR_openssl}

    cd ${BuildDIR_openssl}

    CFLAGS="-fPIC" \
    ${OSG3RD_srcDir}/openssl/Configure linux-x86_64 \
                --prefix=${OSG3RD_INSTALL_PREFIX_ubuntu} \
                --openssldir=${OSG3RD_INSTALL_PREFIX_ubuntu}/ssl \
                no-shared \
                no-zlib \
                no-module  no-dso

    make build_sw -j$(nproc)  

    make install_sw  
    echo "========== finished building openssl 4 ubuntu ========== " &&  sleep 3
    # libssl.a是静态库​​，通常依赖 libcrypto.a提供底层加密函数（如 SHA256_Init、EVP_CIPHER_CTX_new）。
fi


# -------------------------------------------------
# icu
# -------------------------------------------------
# icu的可选功能依赖 ：
# 数据压缩解压库：
#   zlib：若需要 ICU 的压缩数据支持（如压缩的 Unicode 字符数据库），需链接 zlib。
#   libbz2（可选）：支持 bzip2 格式的数据解压。
#   liblzma（可选）：支持 LZMA 格式的数据解压。
# 加密库：
#   libcrypto（OpenSSL 组件，可选）：用于 ICU 的加密相关功能（如校验数据完整性）。
# 其他：
#   iconv（可选）：部分平台可能需要 iconv 库用于字符编码转换，但 ICU 通常自带编码转换逻辑，可独立于 iconv。
isFinished_build_icu=true
if [ "${isFinished_build_icu}" != "true" ] ; then 
    echo "========== building icu 4 ubuntu==========do nothing " &&  sleep 3

    # # 手动执行配置命令验证
    # BuildDIR_lib=${OSG3RD_buildDir_ubuntu}/3rd/icu/build
    # rm -rf   ${BuildDIR_lib}
    # mkdir -p ${BuildDIR_lib}

    # SrcDIR_lib=${OSG3RD_srcDir}/icu/icu4c/source/
    # cd ${SrcDIR_lib}
    # chmod +x runConfigureICU configure install-sh  # 确保脚本可执行


    # cd ${BuildDIR_lib}

    # CFLAGS="-fPIC" \
    # ${OSG3RD_srcDir}/icu/icu4c/source/configure   \
    #     --prefix=${OSG3RD_INSTALL_PREFIX_ubuntu} \
    #     --enable-static=yes \
    #     --enable-shared=no \
    #     --disable-samples \
    #     --disable-tests 
    #     # --disable-tests       # 禁用测试，加快编译
    # make -j$(nproc)  # 多线程编译
    # make install     # 安装到指定的 --prefix 目录

    echo "========== finished building icu 4 ubuntu ========== " &&  sleep 1
fi 

# -------------------------------------------------
# libidn2
# -------------------------------------------------
# isFinished_build_libidn2=false
# if [ "${isFinished_build_libidn2}" != "true" ] ; then 
#     echo "============= Building libidn2 =============" &&  sleep 5
# 
# 
#     BuildDIR_lib=${OSG3RD_buildDir_ubuntu}/3rd/libidn2/build
#     rm -rf   ${BuildDIR_lib}
#     mkdir -p ${BuildDIR_lib}
# 
# 
#     # 生成配置脚本（必须在源码目录运行）
#     if [ ! -d "${OSG3RD_srcDir}/libidn2" ]; then
#         echo "Folder ${OSG3RD_srcDir}/libidn2 NOT exist!"
#         exit 1001
#     fi    
#     cd ${OSG3RD_srcDir}/libidn2  && ./bootstrap
#     if [ "$?" != "0" ]; then
#         echo "libidn2/bootstrap failed. exit!!" &&  exit 1002
#     fi
# 
#     # 在构建目录中运行configure
#     cd ${BuildDIR_lib}
#  
#     CFLAGS="-fPIC" \
#     ${OSG3RD_srcDir}/libidn2/configure \
#                 --prefix=${OSG3RD_INSTALL_PREFIX_ubuntu} \
#                 --disable-shared \
#                 --enable-static  
#     # 
#     make   -j$(nproc)  
#     make install       
# 
#     echo "============= Finished Building libidn2 =============" &&  sleep 5
# fi
# 
# -------------------------------------------------
# libpsl
# -------------------------------------------------
isFinished_build_libpsl=true
if [ "${isFinished_build_libpsl}" != "true" ] ; then 
    echo "======== Building libpsl =========" &&  sleep 5


    BuildDIR_libpsl=${OSG3RD_buildDir_ubuntu}/3rd/libpsl/build
    rm -rf   ${BuildDIR_libpsl}
    mkdir -p ${BuildDIR_libpsl}


    # 生成配置脚本（必须在源码目录运行）
    if [ ! -d "${OSG3RD_srcDir}/libpsl" ]; then
        echo "Folder ${OSG3RD_srcDir}/libpsl NOT exist!"
        exit 1001
    fi    
    cd ${OSG3RD_srcDir}/libpsl  && ./autogen.sh

    # 在构建目录中运行configure
    cd ${BuildDIR_libpsl} 

    # CPPFLAGS="-I${OSG3RD_INSTALL_PREFIX_ubuntu}/include/icu" \
    # LDFLAGS="-L${OSG3RD_INSTALL_PREFIX_ubuntu}/lib" \

    CFLAGS="-fPIC" \
    ${OSG3RD_srcDir}/libpsl/configure \
                --prefix=${OSG3RD_INSTALL_PREFIX_ubuntu} \
                --disable-shared \
                --enable-static  \
                --disable-runtime --enable-builtin
                # --without-libidn2 --without-libicu --without-libidn 
    # 
    make   -j$(nproc)  
    make install       
    echo "========== Finished Building libpsl =========" &&  sleep 5
fi



# -------------------------------------------------
# curl
# -------------------------------------------------
isFinished_build_curl=true
# ----build lib for ubuntu
if [ "${isFinished_build_curl}" != "true" ] ; then 
    echo "======== Building curl =========" &&  sleep 3
    BuildDIR_lib=${OSG3RD_buildDir_ubuntu}/3rd/curl/build
    rm -fr ${BuildDIR_lib}
    mkdir -p ${BuildDIR_lib}

    CMAKE_BUILD_TYPE=Debug
    CMAKE_C_COMPILER=/usr/bin/clang  # /usr/bin/gcc
    CMAKE_CXX_COMPILER=/usr/bin/clang++  # /usr/bin/g++

    cmake -S ${OSG3RD_srcDir}/curl -B ${BuildDIR_lib} \
            -DCMAKE_INSTALL_PREFIX=${OSG3RD_INSTALL_PREFIX_ubuntu}  \
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}   \
            -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}    \
            -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_C_FLAGS="-fPIC" \
            -DCMAKE_CXX_FLAGS="-fPIC" \
            -DBUILD_SHARED_LIBS=OFF     \
            -DOPENSSL_ROOT_DIR=${OSG3RD_INSTALL_PREFIX_ubuntu}   \
            -DOPENSSL_USE_STATIC_LIBS=ON                          \
            -DOPENSSL_INCLUDE_DIR=${OSG3RD_INSTALL_PREFIX_ubuntu}/include  \
            -DOPENSSL_LIBRARIES=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib64       \
            -DOPENSSL_SSL_LIBRARY=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib64/libssl.a \
            -DPENSSL_CRYPTO_LIBRARY=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib64/libcrypto.a \
            -DLIBPSL_INCLUDE_DIR=${OSG3RD_INSTALL_PREFIX_ubuntu}/include   \
            -DLIBPSL_LIBRARY=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib/libpsl.a   \
            -DCURL_DISABLE_LDAP=ON     \
            -DCURL_DISABLE_FTP=ON       \
            -DCURL_DISABLE_ZLIB=ON       \
            -DCURL_DISABLE_TELNET=ON      \
            -DCURL_DISABLE_DICT=ON       \
            -DCURL_DISABLE_FILE=ON      \
            -DCURL_DISABLE_TFTP=ON      \
            -DENABLE_ARES=OFF  \
            -DBUILD_DOCS=OFF \
            -DCMAKE_INSTALL_DOCDIR=OFF \
            -DCURL_USE_PKGCONFIG=OFF \
            -DUSE_LIBIDN2=OFF \
            -DZLIB_ROOT=${OSG3RD_INSTALL_PREFIX_ubuntu} \
            -DZLIB_USE_STATIC_LIBS=ON \
            -DZLIB_INCLUDE_DIR=${OSG3RD_INSTALL_PREFIX_ubuntu}/include \
            -DZLIB_LIBRARY=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib/libz.a  \
            -DZSTD_ROOT=${OSG3RD_INSTALL_PREFIX_ubuntu} \
            -DZSTD_LIBRARY=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib/libzstd.a 
            # -DICU_INCLUDE_DIR=${OSG3RD_INSTALL_PREFIX_ubuntu}/include \
            # -DICU_LIBRARY_DIR=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib \
            # -DCMAKE_EXE_LINKER_FLAGS="-licuuc -licudata -licuio"  # 链接ICU相关静态库

            # -DUSE_NGHTTP2=ON 
            # -DCURL_ZLIB=OFF  
            # -DUSE_LIBIDN2=ON 
            # -DENABLE_IPV6=OFF

    cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc)

    cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}
    echo "========== Finished Building curl =========" &&  sleep 2
fi


# # -------------------------------------------------
# # jpeg-9f 
# # remark: libjpeg-turbo是 标准版libjpeg的超集，所以这里不再特地编译标准libjpeg（jpeg-9f）
# #
# # libjpeg-turbo 的位深度支持​​ ：默认仅支持 8-bit​​（即使开启 WITH_JPEG7=ON）。
# # ​​12-bit JPEG 支持需要原版 jpeg-9f​，并通过 --enable-12bit编译选项启用。
# # -------------------------------------------------
# isFinished_buildJpeg9f=true
#
# # ----build jpeg-9f for ubuntu
# if [ "${isFinished_buildJpeg9f}" != "true" ] ; then 
#     echo "========== Building jpeg-9f 4 ubuntu=========="  &&  sleep 5
#
#
#     BuildDIR_Jpeg9f=${OSG3RD_buildDir_ubuntu}/3rd/jpeg-9f/build
#     rm -rf   ${BuildDIR_Jpeg9f}
#     mkdir -p ${BuildDIR_Jpeg9f}
#
#     jpeg9f_installDir=${OSG3RD_INSTALL_PREFIX_ubuntu}/jpeg-9f
#     rm -rf   ${jpeg9f_installDir}
#     mkdir -p ${jpeg9f_installDir}
#
#     # 在构建目录中运行configure
#     cd ${BuildDIR_Jpeg9f} 
#
#     CFLAGS="-fPIC" \ 
#     ${OSG3RD_srcDir}/jpeg-9f/configure --prefix=${jpeg9f_installDir}\
#              --host=arm-linux --enable-shared --enable-static
#
#     # 
#     make   -j$(nproc)  
#
#     make install  
#     echo "========== Finished Building jpeg-9f 4 ubuntu=========="   
# fi
#
 

# -------------------------------------------------
# libjpeg-turbo
# -------------------------------------------------
isFinished_build_libjpegTurbo=true

# ----build libjpeg-turbo for ubuntu
if [ "${isFinished_build_libjpegTurbo}" != "true" ]  ; then 
    if true; then 
        echo "========== Building libjpeg-turbo 4 Ubuntu==========" && sleep 3
    fi

    BuildDIR_libjpeg=${OSG3RD_buildDir_ubuntu}/3rd/libjpeg-turbo/build
    rm -fr ${BuildDIR_libjpeg}
    mkdir -p ${BuildDIR_libjpeg}    

    cmake -S${OSG3RD_srcDir}/libjpeg-turbo -B ${BuildDIR_libjpeg} \
            -DCMAKE_INSTALL_PREFIX=${OSG3RD_INSTALL_PREFIX_ubuntu}  \
            -DCMAKE_BUILD_TYPE=Debug \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_C_FLAGS="-fPIC" \
            -DCMAKE_CXX_FLAGS="-fPIC" \
            -DWITH_JPEG8=ON      \
            -DENABLE_SHARED=OFF  \
            -DWITH_SIMD=ON       # 启用 SIMD 优化（需安装 NASM）

    cmake --build ${BuildDIR_libjpeg} -j$(nproc)

    cmake --build ${BuildDIR_libjpeg} --target install

    echo "========== Finished building libjpeg-turbo  4 Ubuntu==========" && sleep 5
fi
 

# -------------------------------------------------
# libpng
# -------------------------------------------------
isFinished_build_libpng=true

# ----build libpng for ubuntu
if [ "${isFinished_build_libpng}" != "true" ] ; then 
    echo "========== Building libpng 4 Ubuntu==========" && sleep 5
    BuildDIR_lib=${OSG3RD_buildDir_ubuntu}/3rd/libpng/build
    rm -fr ${BuildDIR_lib}
    mkdir -p ${BuildDIR_lib}       

    cmake -S${OSG3RD_srcDir}/libpng -B ${BuildDIR_lib} \
            -DCMAKE_INSTALL_PREFIX=${OSG3RD_INSTALL_PREFIX_ubuntu} \
            -DCMAKE_BUILD_TYPE=Debug \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_C_FLAGS="-fPIC" \
            -DCMAKE_CXX_FLAGS="-fPIC" \
            -DZLIB_LIBRARY=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib/libz.a \
            -DZLIB_INCLUDE_DIR=${OSG3RD_INSTALL_PREFIX_ubuntu}/include \
            -DPNG_SHARED=ON \
            -DPNG_STATIC=ON           

    cmake --build ${BuildDIR_lib} -j$(nproc)

    cmake --build ${BuildDIR_lib} --target install
    echo "========== Finished Building libpng for Ubuntu ==========" && sleep 5    
fi    


# -------------------------------------------------
# xz : xz generates liblzma.a which is needed by libtiff
# -------------------------------------------------

isFinished_build_xz=true

# ----build xz for ubuntu
if [ "${isFinished_build_xz}" != "true" ]  ; then 
    echo "========== Building xz 4 Ubuntu==========" && sleep 5
    BuildDIR_lib=${OSG3RD_buildDir_ubuntu}/3rd/xz/build
    rm -fr ${BuildDIR_lib}
    mkdir -p ${BuildDIR_lib}           

    cmake -S${OSG3RD_srcDir}/xz -B ${BuildDIR_lib} \
            -DCMAKE_BUILD_TYPE=Debug \
            -DCMAKE_INSTALL_PREFIX=${OSG3RD_INSTALL_PREFIX_ubuntu} \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_C_FLAGS="-fPIC" \
            -DCMAKE_CXX_FLAGS="-fPIC"             

    cmake --build ${BuildDIR_lib} -j$(nproc)

    cmake --build ${BuildDIR_lib} --target install
    echo "========== Finished Building xz for Ubuntu ==========" && sleep 2    
fi    


# -------------------------------------------------
# libtiff
# -------------------------------------------------
# 编译libtiff输出：
# -- Found ZLIB: /usr/lib/x86_64-linux-gnu/libz.so (found version "1.3")  
# -- Found JPEG: /usr/lib/x86_64-linux-gnu/libjpeg.so (found version "80") 
# -- Looking for jbg_newlen
# -- Looking for jbg_newlen - found
# -- Looking for lzma_auto_decoder in /usr/lib/x86_64-linux-gnu/liblzma.so
# -- Looking for lzma_auto_decoder in /usr/lib/x86_64-linux-gnu/liblzma.so - found
# -- Looking for lzma_easy_encoder in /usr/lib/x86_64-linux-gnu/liblzma.so
# -- Looking for lzma_easy_encoder in /usr/lib/x86_64-linux-gnu/liblzma.so - found
# -- Looking for lzma_lzma_preset in /usr/lib/x86_64-linux-gnu/liblzma.so
# -- Looking for lzma_lzma_preset in /usr/lib/x86_64-linux-gnu/liblzma.so - found
# -- Found LibLZMA: /usr/lib/x86_64-linux-gnu/liblzma.so (found version "5.4.5") 
# -- The CXX compiler identification is GNU 13.3.0
# 
# liblzma.so:  LZMA 的压缩率通常高于传统的 ZIP（Deflate）或 JPEG 压缩，适合需要高压缩比的场景（如存档、卫星图像）。

isFinished_build_libtiff=true

# ----build libtiff for ubuntu
if [ "${isFinished_build_libtiff}" != "true" ] ; then 
    echo "========== Building libtiff 4 Ubuntu==========" && sleep 5
    BuildDIR_lib=${OSG3RD_buildDir_ubuntu}/3rd/libtiff/build
    rm -fr ${BuildDIR_lib}
    mkdir -p ${BuildDIR_lib}           

    cmake -S${OSG3RD_srcDir}/libtiff -B ${BuildDIR_lib} \
            -DCMAKE_BUILD_TYPE=Debug \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_C_FLAGS="-fPIC" \
            -DCMAKE_CXX_FLAGS="-fPIC" \
            -DCMAKE_INSTALL_PREFIX=${OSG3RD_INSTALL_PREFIX_ubuntu}  \
            -DZLIB_LIBRARY=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib/libz.a \
            -DZLIB_INCLUDE_DIR=${OSG3RD_INSTALL_PREFIX_ubuntu}/include \
            -DJPEG_LIBRARY=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib/libjpeg.a \
            -DJPEG_INCLUDE_DIR=${OSG3RD_INSTALL_PREFIX_ubuntu}/include \
            -DLIBLZMA_LIBRARY=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib/liblzma.a \
            -DLIBLZMA_INCLUDE_DIR=${OSG3RD_INSTALL_PREFIX_ubuntu}/include \
            -DBUILD_SHARED_LIBS=OFF \
            -DCMAKE_EXE_LINKER_FLAGS="-static"  \
            -Djbig=OFF \
            -Dtiff-tools=OFF   

            # -Dtiff-tools=OFF    # 可选：禁用工具构建
            #  -DCMAKE_EXE_LINKER_FLAGS="-static"  # 强制静态链接所有库
    cmake --build ${BuildDIR_lib} -j$(nproc)

    cmake --build ${BuildDIR_lib} --target install
    echo "========== Finished Building libtiff for Ubuntu ==========" && sleep 3    
fi    


# -------------------------------------------------
# freetype
# -------------------------------------------------
# 编译输出中的freetype相关依赖项目：
# -- Found PkgConfig: /usr/bin/pkg-config (found version "1.8.1") 
# -- Looking for dlopen - found
# -- Enabled dynamic loading of HarfBuzz library at runtime.
# -- Found ZLIB: /usr/lib/x86_64-linux-gnu/libz.so (found version "1.3")  
# -- Found PNG: /usr/lib/x86_64-linux-gnu/libpng.so (found version "1.6.43") 
# -- Could NOT find BZip2 (missing: BZIP2_LIBRARIES BZIP2_INCLUDE_DIR) 
# -- Checking for module 'bzip2'
# --   Package 'bzip2', required by 'virtual:world', not found
# -- Could NOT find BrotliDec (missing: BROTLIDEC_INCLUDE_DIRS BROTLIDEC_LIBRARIES) 
# 
# 从CMake 输出日志来看，FreeType 的构建过程中发现了部分依赖库缺失（`BZip2` 和 `BrotliDec`），但其他关键库（如 `ZLIB` 和 `PNG`）已成功检测到。 
# | 依赖库       | 状态                  | 影响                                                                 |
# |--------------|-----------------------|----------------------------------------------------------------------|
# | **BZip2**    | `Could NOT find`      | FreeType 将无法处理 `.bz2` 压缩的字体文件（如 `.ttf.bz2`）。          |
# | **BrotliDec**| `Could NOT find`      | 无法解析 Brotli 压缩的字体（如 `.ttf.br`），但此类文件较少见。         |
# | **ZLIB**     | 已找到（`libz.so`）    | 支持 `.ttf.gz` 和常规压缩。                                           |
# | **PNG**      | 已找到（`libpng.so`）  | 支持位图字体（如 `.png` 格式的彩色字体）。                            |

isFinished_build_freetype=true

# ----build freetype for ubuntu
if [ "${isFinished_build_freetype}" != "true" ] ; then 
    echo "========== Building freetype 4 Ubuntu==========" && sleep 5
    BuildDIR_lib=${OSG3RD_buildDir_ubuntu}/3rd/freetype/build
    rm -fr ${BuildDIR_lib}
    mkdir -p ${BuildDIR_lib}        

    cmake -S${OSG3RD_srcDir}/freetype -B ${BuildDIR_lib} \
            -DCMAKE_BUILD_TYPE=Debug \
            -DCMAKE_INSTALL_PREFIX=${OSG3RD_INSTALL_PREFIX_ubuntu} \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_C_FLAGS="-fPIC" \
            -DCMAKE_CXX_FLAGS="-fPIC" \
            -DFT_DISABLE_BZIP2=ON \
            -DFT_DISABLE_BROTLI=ON \
            -DZLIB_LIBRARY=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib/libz.a  \
            -DZLIB_INCLUDE_DIR=${OSG3RD_INSTALL_PREFIX_ubuntu}/include \
            -DPNG_LIBRARY=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib/libpng.a \
            -DPNG_PNG_INCLUDE_DIR=${OSG3RD_INSTALL_PREFIX_ubuntu}/include \
            -DFT_REQUIRE_ZLIB=ON \
            -DFT_REQUIRE_PNG=ON  \
            -DCMAKE_EXE_LINKER_FLAGS="-static"

    cmake --build ${BuildDIR_lib} -j$(nproc)

    cmake --build ${BuildDIR_lib} --target install

    echo "========== Finished Building freetype for Ubuntu ==========" && sleep 5    
fi

  
# -------------------------------------------------
# geos
# ------------------------------------------------- 
isFinished_build_geos=true
if [ "${isFinished_build_geos}" != "true" ] ; then 
    echo "========== building geos 4 ubuntu========== " &&  sleep 5

    # 手动执行配置命令验证
    BuildDIR_lib=${OSG3RD_buildDir_ubuntu}/3rd/geos/build 
    rm -fr ${BuildDIR_lib}
    mkdir -p ${BuildDIR_lib}    

    #################################################################### 
    # 在顶层 CMakeLists.txt 中全局启用 PIC: set(CMAKE_POSITION_INDEPENDENT_CODE ON)
    CMAKE_BUILD_TYPE=Debug
    CMAKE_C_COMPILER=/usr/bin/clang  # /usr/bin/gcc
    CMAKE_CXX_COMPILER=/usr/bin/clang++  # /usr/bin/g++     
    cmake -S ${OSG3RD_srcDir}/geos -B ${BuildDIR_lib} \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_C_FLAGS="-fPIC" \
            -DCMAKE_CXX_FLAGS="-fPIC" \
            -DCMAKE_INSTALL_PREFIX=${OSG3RD_INSTALL_PREFIX_ubuntu}  \
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}   \
            -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}    \
            -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} \
            -DBUILD_SHARED_LIBS=OFF     \
            -DCMAKE_EXE_LINKER_FLAGS="-static" 
    # -DZLIB_BUILD_SHARED=ON \
    # -DZLIB_BUILD_STATIC=ON  \    
    cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc)
    
    cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}
    #################################################################### 
    echo "========== finished building geos 4 ubuntu ========== " &&  sleep 3
fi



# -------------------------------------------------
# sqlite
# ------------------------------------------------- 
isFinished_build_sqlite=true
if [ "${isFinished_build_sqlite}" != "true" ] ; then 
    echo "========== building sqlite 4 ubuntu========== " &&  sleep 5

    BuildDIR_lib=${OSG3RD_buildDir_ubuntu}/3rd/sqlite/build
    rm -rf   ${BuildDIR_lib}
    mkdir -p ${BuildDIR_lib}

    ####################################################################
    # 生成配置脚本（必须在源码目录运行）
    if [ ! -d "${OSG3RD_srcDir}/sqlite" ]; then
        echo "Folder ${OSG3RD_srcDir}/sqlite NOT exist!"
        exit 1001
    fi 
    
    # 在构建目录中运行configure
    cd ${BuildDIR_lib} 
    # /usr/bin/musl-gcc
    # CPPFLAGS="-I${OSG3RD_INSTALL_PREFIX_ubuntu}/include/icu" \
    # LDFLAGS="-L${OSG3RD_INSTALL_PREFIX_ubuntu}/lib" \ 
    CC=/usr/bin/gcc \
    ${OSG3RD_srcDir}/sqlite/configure  --prefix=${OSG3RD_INSTALL_PREFIX_ubuntu} \
        --disable-shared   \
        --enable-static    \
        --enable-debug  \
        --host=x86_64-linux-musl \
        CFLAGS="-fPIC -DSQLITE_ENABLE_RTREE=1 -DSQLITE_THREADSAFE=1 -DSQLITE_MUTEX=unix"
    #  CFLAGS="-fPIC -DSQLITE_OMIT_LOAD_EXTENSION=1 -DSQLITE_ENABLE_RTREE=1 -DSQLITE_THREADSAFE=1"  
    make   -j$(nproc)  
    make install       
    #################################################################### 
    echo "========== finished building sqlite 4 ubuntu ========== " &&  sleep 2
fi


# -------------------------------------------------
# proj
# ------------------------------------------------- 
isFinished_build_proj=true
if [ "${isFinished_build_proj}" != "true" ] ; then 
    echo "========== building proj 4 ubuntu========== " &&  sleep 5

    # 手动执行配置命令验证
    BuildDIR_lib=${OSG3RD_buildDir_ubuntu}/3rd/proj/build 
    rm -fr ${BuildDIR_lib}
    mkdir -p ${BuildDIR_lib}    
              
    #################################################################### 
    #  CC=musl-gcc cmake -S ${OSG3RD_srcDir}/proj -B ${BuildDIR_lib}  
    CMAKE_BUILD_TYPE=Debug
    # CMAKE_C_COMPILER=/usr/bin/musl-gcc   # /usr/bin/clang  # /usr/bin/gcc
    # CMAKE_CXX_COMPILER=/usr/bin/musl-gcc # /usr/bin/clang++  # /usr/bin/g++    

    lib_dir=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib
    lib64_dir=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib64
    libjpeg_path=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib/libjpeg.a
    liblzma_path=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib/liblzma.a
    libssl_path=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib64/libssl.a 
    libcrypto_path=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib64/libcrypto.a

    cmake -S ${OSG3RD_srcDir}/proj -B ${BuildDIR_lib} \
            -DCMAKE_FIND_ROOT_PATH=${OSG3RD_INSTALL_PREFIX_ubuntu} \
            -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
            -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
            -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
            -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
            -DCMAKE_INSTALL_PREFIX=${OSG3RD_INSTALL_PREFIX_ubuntu}  \
            -DCMAKE_PREFIX_PATH=${OSG3RD_INSTALL_PREFIX_ubuntu} \
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}   \
            -DBUILD_SHARED_LIBS=OFF     \
            -DBUILD_TESTING=OFF \
            -DBUILD_EXAMPLES=OFF \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_CXX_FLAGS="-fPIC" \
            -DCMAKE_C_FLAGS="-fPIC"  \
            -DENABLE_CURL=ON  \
            -DENABLE_TIFF=OFF  \
            -DSQLite3_DISABLE_DYNAMIC_EXTENSIONS=ON \
            -DCURL_DISABLE_ARES=ON  

            # -DOPENSSL_ROOT_DIR=${OSG3RD_INSTALL_PREFIX_ubuntu} \
            # -DOPENSSL_LIBRARIES="${libssl_path};${libcrypto_path}" \
            # -DCMAKE_SHARED_LINKER_FLAGS="-L${lib_dir} -ltiff -ljpeg -llzma -lz -L${lib64_dir} -lssl -lcrypto" \
            # -DCMAKE_EXE_LINKER_FLAGS="-L${lib_dir} -ltiff -ljpeg -llzma -lz -L${lib64_dir} -lssl -lcrypto" \
            # -DCURL_LIBRARY=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib/libcurl-d.a \
            # -DCURL_INCLUDE_DIR=${OSG3RD_INSTALL_PREFIX_ubuntu}/include \
            # -DSQLite3_LIBRARY=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib/libsqlite3.a \
            # -DSQLite3_INCLUDE_DIR=${OSG3RD_INSTALL_PREFIX_ubuntu}/include \
            # -DTIFF_LIBRARY=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib/libtiff.a \
            # -DTIFF_INCLUDE_DIR=${OSG3RD_INSTALL_PREFIX_ubuntu}/include \
            # -DCURL_ROOT=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib \            
            
            # (1)proj源码中，只有find_package(SQLite3 REQUIRED)  find_package(TIFF REQUIRED)
            # find_package(CURL REQUIRED);
            # 所以当-DENABLE_TIFF=ON(默认) 时为了给各个exe target指定 jpeg 、lzma等非直接依赖库，需要修改
            # tests/ 及 examples/ 和 src/apps/ 下的cmake脚本 中的 target_link_libraries，如            
            # 
            # ```examples/CMakeLists.txt  
            # add_executable(crs_to_geodetic crs_to_geodetic.c)
            # target_link_libraries(crs_to_geodetic PRIVATE ${PROJ_LIBRARIES}
            # ${CMAKE_INSTALL_PREFIX}/lib/libtiff.a  # added-code:libtiff 依赖 libjpeg，所以 libjpeg 要在后面
            # ${CMAKE_INSTALL_PREFIX}/lib/libjpeg.a  # added-code:
            # ${CMAKE_INSTALL_PREFIX}/lib/liblzma.a  # added-code:
            # )
            # ```
            #(2)remark: -DJPEG_FOUND=ON -DLIBLZMA_FOUND=ON -DJPEG_LIBRARY=${libjpegPath} 
            #        -DLIBLZMA_LIBRARY=${liblzmaPath} 不起作用
            #(3)不需要tests 及 examples：  -DBUILD_TESTING=OFF  -DBUILD_EXAMPLES=OFF 



            # -DCMAKE_EXE_LINKER_FLAGS="-static" \
            # -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}    \
            # -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} \
            # -DZLIB_LIBRARY=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib/libz.a  \
            # -DZLIB_INCLUDE_DIR=${OSG3RD_INSTALL_PREFIX_ubuntu}/include \
        

    cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j15 # -j$(nproc)
    
    cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}
    #################################################################### 
    echo "========== finished building proj 4 ubuntu ========== " &&  sleep 2
fi


# -------------------------------------------------
# libexpat
# ------------------------------------------------- 
isFinished_build_libexpat=true
if [ "${isFinished_build_libexpat}" != "true" ] ; then 
    echo "========== building libexpat 4 ubuntu========== " &&  sleep 5

    # 手动执行配置命令验证
    BuildDIR_lib=${OSG3RD_buildDir_ubuntu}/3rd/libexpat/build 
    rm -fr ${BuildDIR_lib}
    mkdir -p ${BuildDIR_lib}    
    ####################################################################
    CMAKE_BUILD_TYPE=Debug  #RelWithDebInfo
    # CMAKE_C_COMPILER=/usr/bin/musl-gcc   # /usr/bin/clang  # /usr/bin/gcc
    # CMAKE_CXX_COMPILER=/usr/bin/musl-gcc # /usr/bin/clang++  # /usr/bin/g++    

    lib_dir=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib 
    
    cmake -S ${OSG3RD_srcDir}/libexpat/expat -B ${BuildDIR_lib} \
            -DCMAKE_FIND_ROOT_PATH=${OSG3RD_INSTALL_PREFIX_ubuntu} \
            -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
            -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
            -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
            -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
            -DCMAKE_INSTALL_PREFIX=${OSG3RD_INSTALL_PREFIX_ubuntu}  \
            -DCMAKE_PREFIX_PATH=${OSG3RD_INSTALL_PREFIX_ubuntu} \
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}   \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_CXX_FLAGS="-fPIC" \
            -DCMAKE_C_FLAGS="-fPIC"   \
            -DBUILD_SHARED_LIBS=OFF   \
            -DEXPAT_BUILD_TESTS=OFF \
            -DEXPAT_BUILD_EXAMPLES=OFF \
            -DEXPAT_BUILD_DOCS=OFF \
            -DCMAKE_EXE_LINKER_FLAGS="-static"

    cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc)
    
    cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}     
    #################################################################### 
    echo "========== finished building libexpat 4 ubuntu ========== " &&  sleep 2
fi    



# -------------------------------------------------
# protobuf  
# -------------------------------------------------
isFinished_build_protobuf=true
if [ "${isFinished_build_protobuf}" != "true" ] ; then 
    echo "========== building protobuf 4 ubuntu========== " &&  sleep 5

    # 手动执行配置命令验证
    BuildDIR_lib=${OSG3RD_buildDir_ubuntu}/3rd/protobuf/build 
    rm -fr ${BuildDIR_lib}
    mkdir -p ${BuildDIR_lib}    
    ####################################################################
    CMAKE_BUILD_TYPE=RelWithDebInfo
    # CMAKE_C_COMPILER=/usr/bin/musl-gcc   # /usr/bin/clang  # /usr/bin/gcc
    # CMAKE_CXX_COMPILER=/usr/bin/musl-gcc # /usr/bin/clang++  # /usr/bin/g++    

    lib_dir=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib  
    
    cmake -S ${OSG3RD_srcDir}/protobuf -B ${BuildDIR_lib} \
            -DCMAKE_FIND_ROOT_PATH=${OSG3RD_INSTALL_PREFIX_ubuntu} \
            -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
            -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
            -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
            -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
            -DCMAKE_INSTALL_PREFIX=${OSG3RD_INSTALL_PREFIX_ubuntu}  \
            -DCMAKE_PREFIX_PATH=${OSG3RD_INSTALL_PREFIX_ubuntu} \
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}   \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_CXX_FLAGS="-fPIC" \
            -DCMAKE_C_FLAGS="-fPIC"   \
            -DBUILD_SHARED_LIBS=OFF   \
            -Dprotobuf_BUILD_TESTS=OFF \
            -Dprotobuf_BUILD_EXAMPLES=OFF \
            -Dprotobuf_BUILD_PROTOC_BINARIES=OFF \
            -Dprotobuf_PROTOC_EXE=/home/abner/programs/protoc-31.1-linux-x86_64/bin/protoc \
            -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
            -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
            -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
            -DZLIB_LIBRARY=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib/libz.a  \
            -DZLIB_INCLUDE_DIR=${OSG3RD_INSTALL_PREFIX_ubuntu}/include           

    cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc)
    
    cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}     
    #################################################################### 
    echo "========== finished building protobuf 4 ubuntu ========== " &&  sleep 2
fi    



# -------------------------------------------------
# gdal , see 3rd/gdal/fuzzers/build.sh
# -------------------------------------------------
isFinished_build_gdal=false
if [ "${isFinished_build_gdal}" != "true" ] ; then 
    echo "========== building gdal 4 ubuntu========== " &&  sleep 5

    # 手动执行配置命令验证
    BuildDIR_lib=${OSG3RD_buildDir_ubuntu}/3rd/gdal/build 
    rm -fr ${BuildDIR_lib}
    mkdir -p ${BuildDIR_lib}    

    ####################################################################
    CMAKE_BUILD_TYPE=Debug  #RelWithDebInfo
    # CMAKE_C_COMPILER=/usr/bin/musl-gcc   # /usr/bin/clang  # /usr/bin/gcc
    # CMAKE_CXX_COMPILER=/usr/bin/musl-gcc # /usr/bin/clang++  # /usr/bin/g++    

    lib_dir=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib
    lib64_dir=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib64 
    _LINKER_FLAGS="-L${lib_dir} -lcurl -ltiff -ljpeg -lsqlite3 -lprotobuf -lpng -llzma -lz -L${lib64_dir} -lssl -lcrypto" \
    # -DCMAKE_STATIC_LINKER_FLAGS=${_LINKER_FLAGS}  -DCMAKE_EXE_LINKER_FLAGS=${_LINKER_FLAGS}  
    cmake -S ${OSG3RD_srcDir}/gdal -B ${BuildDIR_lib} \
            -DCMAKE_FIND_ROOT_PATH=${OSG3RD_INSTALL_PREFIX_ubuntu} \
            -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
            -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
            -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
            -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
            -DCMAKE_INSTALL_PREFIX=${OSG3RD_INSTALL_PREFIX_ubuntu}  \
            -DCMAKE_PREFIX_PATH=${OSG3RD_INSTALL_PREFIX_ubuntu} \
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}   \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_CXX_FLAGS="-fPIC  -DJPEG12_SUPPORTED=0 ${_LINKER_FLAGS}" \
            -DCMAKE_C_FLAGS="-fPIC  -DJPEG12_SUPPORTED=0 ${_LINKER_FLAGS}"   \
            -DBUILD_SHARED_LIBS=OFF   \
            -DBUILD_APPS=OFF \
            -DBUILD_TESTING=OFF \
            -DZLIB_ROOT=${OSG3RD_INSTALL_PREFIX_ubuntu} \
            -DCURL_LIBRARY=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib/libcurl.a \
            -DGEOS_INCLUDE_DIR=${OSG3RD_INSTALL_PREFIX_ubuntu}/include \
            -DGEOS_LIBRARY=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib/libgeos.a \
            -DPROJ_INCLUDE_DIR=${OSG3RD_INSTALL_PREFIX_ubuntu}/include \
            -DPROJ_LIBRARY=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib/libproj.a \
            -DSQLITE3_INCLUDE_DIR=${OSG3RD_INSTALL_PREFIX_ubuntu}/include \
            -DPNG_INCLUDE_DIR=${OSG3RD_INSTALL_PREFIX_ubuntu}/include \
            -DPNG_LIBRARY=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib/libpng.a \
            -DJPEG_INCLUDE_DIR=${OSG3RD_INSTALL_PREFIX_ubuntu}/include \
            -DJPEG_LIBRARY=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib/libjpeg.a \
            -DCURL_INCLUDE_DIR=${OSG3RD_INSTALL_PREFIX_ubuntu}/include \
            -DSQLITE3_LIBRARY=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib/libsqlite3.a \
            -DOPENSSL_DIR=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib64/cmake/OpenSSL/ \
            -DOPENSSL_ROOT_DIR=${OSG3RD_INSTALL_PREFIX_ubuntu} \
            -DOPENSSL_INCLUDE_DIR=${OSG3RD_INSTALL_PREFIX_ubuntu}/include \
            -DOPENSSL_SSL_LIBRARY=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib64/libssl.a \
            -DOPENSSL_CRYPTO_LIBRARY=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib64/libcrypto.a \
            -DPROTOBUF_LIBRARY=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib/libprotobuf.a \
            -DPROTOBUF_INCLUDE_DIR=${OSG3RD_INSTALL_PREFIX_ubuntu}/include  \
            -DZLIB_INCLUDE_DIR=${OSG3RD_INSTALL_PREFIX_ubuntu}/include \
            -DZLIB_LIBRARY=${OSG3RD_INSTALL_PREFIX_ubuntu}/lib/libz.a \
            -DGDAL_USE_OPENSSL=ON \
            -DGDAL_USE_ZLIB=ON \
            -DGDAL_USE_PNG=ON \
            -DGDAL_USE_JPEG=ON \
            -DGDAL_USE_CURL=ON \
            -DGDAL_USE_SQLITE3=ON \
            -DGDAL_USE_GEOS=ON \
            -DGDAL_USE_PROJ=ON \
            -DGDAL_USE_EXTERNAL_LIBS=ON \
            -DGDAL_USE_JSONC_INTERNAL=ON \
            -DOGR_BUILD_OPTIONAL_DRIVERS=ON \
            -DOGR_ENABLE_DRIVER_MVT=ON \
            -DGDAL_USE_PROTOBUF=ON \
            -DGDAL_USE_JPEG_INTERNAL=OFF \
            -DHAVE_JPEGTURBO_DUAL_MODE_8_12=OFF


    cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc)
    
    cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}     
    #################################################################### 
    echo "========== finished building gdal 4 ubuntu ========== " &&  sleep 2
fi    


