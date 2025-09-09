#!/bin/bash
# **************************************************************************
# false  ;;;   ./mk4android.sh  >ba.txt 2>&1
isRebuild=true

isFinished_build_zlib=true  #v
# isFinished_build_zstd=true
isFinished_build_openssl=true  # v
# isFinished_build_icu=true  
# isFinished_build_libidn2=true 
# isFinished_build_libpsl=true  
isFinished_build_curl=true   # false v
# isFinished_build_jpeg9f=true  
isFinished_build_libjpegTurbo=true  
isFinished_build_libpng=true 
isFinished_build_xz=true  
isFinished_build_libtiff=true 
isFinished_build_freetype=true  
isFinished_build_geos=true     # false
isFinished_build_sqlite=true  # v
isFinished_build_proj=false 
isFinished_build_libexpat=true  
isFinished_build_absl=true
isFinished_build_protobuf=true
isFinished_build_boost=true
isFinished_build_gdal=true
isFinished_build_osg=true
isFinished_build_zip=true
isFinished_build_osgearth=false
    
# ANDROID_NDK_ROOT ​​:早期 Android 工具链（如 ndk-build）和部分开源项目（如 OpenSSL）习惯使用此变量。
export ANDROID_NDK_ROOT=/home/abner/Android/Sdk/ndk/27.1.12297006    
# ANDROID_NDK_HOME​ ​:后来 Android Studio 和 Gradle 更倾向于使用此变量。    
export ANDROID_NDK_HOME="${ANDROID_NDK_ROOT}"
# CMAKE_SYSROOT=${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/sysroot
# 
export PATH=${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH
export PATH=$PATH:$ANDROID_NDK_HOME

CMAKE_BUILD_TYPE=Debug #RelWithDebInfo
CMAKE_MAKE_PROGRAM=${ANDROID_NDK_HOME}/prebuilt/linux-x86_64/bin/make
# CMAKE_C_COMPILER=/usr/bin/gcc   # /usr/bin/musl-gcc   # /usr/bin/clang  # 
# CMAKE_CXX_COMPILER=/usr/bin/g++ # /usr/bin/musl-gcc # /usr/bin/clang++  #   

# 确保 NDK 路径已设置（需要根据实际环境修改或通过环境变量传入）
if [ -z "${ANDROID_NDK_HOME}" ]; then
    echo "ERROR: ANDROID_NDK_HOME environment variable is not set!"
    exit 1001
fi
# **************************************************************************
Repo_ROOT=/home/abner/abner2/zdev/nv/osgearth0x

# rm -fr ./build_by_sh   
BuildDir_andro=${Repo_ROOT}/build_by_sh/android

INSTALL_PREFIX_andro=${BuildDir_andro}/install
mkdir -p ${INSTALL_PREFIX_andro} 

# 定义需要编译的 Android ABI 列表
ABIS=("arm64-v8a" "armeabi-v7a" "x86" "x86_64")
CMAKE_ANDROID_ARCH_ABI="x86_64" 
 
cmakeCommonParams=(
  "-DCMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}"
  "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
  "-DPKG_CONFIG_EXECUTABLE=/usr/bin/pkg-config"
  "-DCMAKE_FIND_ROOT_PATH=${INSTALL_PREFIX_andro}"
  "-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY"
  "-DCMAKE_FIND_PACKAGE_PREFER_CONFIG=ON"
  "-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY" # BOTH：先查根路径，再查系统路径    
  "-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY" # 头文件仍只查根路径 
  "-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER"
  # 是否访问 /usr/include/、/usr/lib/ 等 系统路径   
  "-DCMAKE_FIND_USE_CMAKE_SYSTEM_PATH=OFF"
  # 是否访问PATH\LD_LIBRARY_PATH等环境变量
  "-DCMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH=OFF" 
  "-DCMAKE_FIND_LIBRARY_SUFFIXES=.a"
  "-DCMAKE_POSITION_INDEPENDENT_CODE=ON" 
  "-DBUILD_SHARED_LIBS=OFF"   
)
 
echo "cmakeCommonParams=${cmakeCommonParams[@]}"
# **************************************************************************
# functions
prepareBuilding()
{
    local aSubSrcDir="$1"
    local aSubBuildDir="$2"
    local aSubInstallDir="$3"
    local aIsRebuild="$4"
    echo "aSubSrcDir= $aSubSrcDir"
    echo "aSubBuildDir=$aSubBuildDir"
    echo "aSubInstallDir=$aSubInstallDir" 
    echo "aIsRebuild=$aIsRebuild" 
    if [ ! -d "${aSubSrcDir}" ]; then
        echo "Folder ${aSubSrcDir}  NOT exist!"
        exit 1001
    fi    
 

    if [ "${aIsRebuild}" = "true" ]; then 
        # echo "${aSubSrcDir} aIsRebuild ==true..1"          
        rm -fr ${aSubBuildDir}
        # 即使此处不创建${aSubBuildDir}，cmake -S -B命令也会创建 
        mkdir -p ${aSubBuildDir}
        
        rm -fr ${aSubInstallDir}
        mkdir -p ${aSubInstallDir}
        # cmake --build 命令会创建 ${aSubInstallDir} 
        echo "${aSubSrcDir} aIsRebuild ==true..2"       
    else
        echo "${aSubSrcDir} aIsRebuild ==false"      
    fi   

    return 0
}
 # **************************************************************************
# **************************************************************************
#  3rd/
# **************************************************************************
SrcDIR_3rd=${Repo_ROOT}/3rd

# -------------------------------------------------
# zlib
# -------------------------------------------------
INSTALL_PREFIX_zlib=${INSTALL_PREFIX_andro}/3rd/zlib

if [ "${isFinished_build_zlib}" != "true" ]; then 
    echo "========== building zlib 4 ubuntu========== " &&  sleep 1
    SrcDIR_lib=${SrcDIR_3rd}/zlib
    BuildDIR_lib=${BuildDir_andro}/3rd/zlib     
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_zlib} ${isRebuild} 
 
    #################################################################### 
    # remark: zlib的 CMakeLists.txt中 未通过 target_compile_definitions 显式指定 ZLIB_DEBUG 宏,
    #    可以用 CMAKE_C_FLAGS="-DZLIB_DEBUG=1" 指定 :
    # 编译时查看详细命令
    # cmake ... -DCMAKE_C_FLAGS="-fPIC -DZLIB_DEBUG=1"
    # make -C ${BuildDIR_lib} VERBOSE=1 
    # 若输出的编译命令中包含 -DZLIB_DEBUG=1，则说明宏已成功定义。
    #----------------------------------------------------  
    cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib} --debug-find  \
        -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
        -DANDROID_ABI="${CMAKE_ANDROID_ARCH_ABI}" \
        -DANDROID_NATIVE_API_LEVEL=24 \
        -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_zlib}  \
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}   \
        -DCMAKE_C_FLAGS="-DZLIB_DEBUG=1"  \
        -DBUILD_SHARED_LIBS=OFF     \
        -DCMAKE_EXPORT_PACKAGE_REGISTRY=ON \
        -DZLIB_BUILD_SHARED=OFF \
        -DZLIB_BUILD_STATIC=ON 

 
        # -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}  
            
             
    cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v 

    cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}
 
    #--## zlib源码编译后产生的ZLIBConfig.cmake 只有 ZLIB::ZLIBSTATIC ;
    #--  要获得导入型目标 ZLIB::ZLIB，需要默认的、来自系统路径的FindZlib.cmake 
    #--
    #----备份 zlib源码编译后产生的ZLIBConfig.cmake
    mv  ${INSTALL_PREFIX_zlib}/lib/cmake/zlib/ZLIBConfig.cmake  ${INSTALL_PREFIX_zlib}/lib/cmake/zlib/ZLIBConfig.cmake-bk
    mv  ${INSTALL_PREFIX_zlib}/lib/cmake/zlib/pkgconfig  ${INSTALL_PREFIX_zlib}/lib/cmake/zlib/pkgconfig-bk
    #---- 把 FindZLIB.cmake 放到 ${INSTALL_PREFIX_zlib}/lib/cmake/
    # mkdir -p ${INSTALL_PREFIX_zlib}/lib/cmake/zlib
    # cp ${Repo_ROOT}/cmake/FindZLIB.cmake  ${INSTALL_PREFIX_zlib}/lib/cmake/zlib

    echo "========== finished building zlib 4 ubuntu ========== " &&  sleep 1
fi 
 


# -------------------------------------------------
# openssl
# -------
# libssl.a是静态库​​，通常依赖 libcrypto.a提供底层加密函数
# （如 SHA256_Init、EVP_CIPHER_CTX_new）。
# -------------------------------------------------
INSTALL_PREFIX_openssl=${INSTALL_PREFIX_andro}/3rd/openssl

if [ "${isFinished_build_openssl}" != "true" ]; then 
    echo "========== Building openssl 4 ubuntu ========== " &&  sleep 3

    SrcDIR_openssl=${SrcDIR_3rd}/openssl
    BuildDIR_openssl=${BuildDir_andro}/3rd/openssl
    prepareBuilding  ${SrcDIR_openssl} ${BuildDIR_openssl} ${INSTALL_PREFIX_openssl} ${isRebuild}

 
    cd ${BuildDIR_openssl}
    # (1) 如需调试支持，改用 enable-asan或 -d​​
    # # 方案1：使用 OpenSSL 的调试模式（生成调试符号）
    #     ./Configure linux-x86_64 -d --prefix=...
    # 
    # # 方案2：启用 AddressSanitizer（调试内存问题）
    #     ./Configure linux-x86_64 enable-asan --prefix=...
    # (2) 如需调试符号，改用 -g：
    #     CFLAGS="-fPIC -g" ./Configure ...
    # (3) 根据设备选择正确的 目标架构
    #   ${SrcDIR_openssl}/Configure android-arm # 32 位 ARM    
    #   ${SrcDIR_openssl}/Configure android-arm64 # 64 位 ARM
    target_ARCH="android-x86_64"

    # 在编译时标记符号为 "hidden"（仅限动态链接）
    CFLAGS="-fPIC -fvisibility=hidden" \
    ${SrcDIR_openssl}/Configure ${target_ARCH} -d \
                -D__ANDROID_API__=24 \
                --prefix=${INSTALL_PREFIX_openssl} \
                --openssldir=${INSTALL_PREFIX_openssl}/ssl  \
                no-shared  no-zlib no-module  no-dso 

      #  (1)-static确保完全静态链接,导致"ld.lld: error: duplicate symbol: time"
      #  即使 -fvisibility=hidden 也无法消除

    make build_sw -j$(nproc)  V=1

    make install_sw  
    echo "========== finished building openssl 4 ubuntu ========== " &&  sleep 2
    
fi 
  

# -------------------------------------------------
# curl
# -------------------------------------------------
INSTALL_PREFIX_curl=${INSTALL_PREFIX_andro}/3rd/curl

if [ "${isFinished_build_curl}" != "true" ] ; then 
    echo "======== Building curl =========" &&  sleep 1 && set -x     

    SrcDIR_lib=${SrcDIR_3rd}/curl
    BuildDIR_lib=${BuildDir_andro}/3rd/curl 
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_curl} ${isRebuild}              
    # ---------------------    
    cmkPrefixPath_Arr=(
        "${INSTALL_PREFIX_zlib}"  
        "${INSTALL_PREFIX_openssl}" 
        )
    # 使用;号连接数组元素.
    cmkPrefixPath=$(IFS=";"; echo "${cmkPrefixPath_Arr[*]}")
    echo "For building curl: cmkPrefixPath=${cmkPrefixPath}" 

    cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib} --debug-find \
        -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
            -DANDROID_ABI=${CMAKE_ANDROID_ARCH_ABI} \
            -DANDROID_NATIVE_API_LEVEL=24 \
            "${cmakeCommonParams[@]}"  \
            -DCMAKE_PREFIX_PATH=${cmkPrefixPath} \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_curl}  \
            -DBUILD_SHARED_LIBS=OFF    \
            -DCURL_DISABLE_LDAP=ON     \
            -DCURL_DISABLE_FTP=ON      \
            -DCURL_DISABLE_TELNET=ON   \
            -DCURL_DISABLE_DICT=ON     \
            -DCURL_DISABLE_FILE=ON     \
            -DCURL_DISABLE_TFTP=ON     \
            -DCURL_BROTLI=OFF  -DCURL_USE_LIBSSH2=OFF \
            -DUSE_LIBIDN2=OFF  -DUSE_NGHTTP2=OFF      \
            -DCURL_ZLIB=ON  -DZLIB_USE_STATIC_LIBS=ON \
            -DCURL_ZSTD=OFF \
            -DBUILD_DOCS=OFF \
            -DCMAKE_INSTALL_DOCDIR=OFF \
            -DCURL_USE_PKGCONFIG=OFF -DCURL_USE_LIBPSL=OFF \
            -DCURL_USE_OPENSSL=ON \
            -DOPENSSL_USE_STATIC_LIBS=ON  \
            -DOPENSSL_ROOT_DIR=${INSTALL_PREFIX_openssl} \
            -DOPENSSL_LIBRARIES=${INSTALL_PREFIX_openssl}/lib \
            -DOPENSSL_INCLUDE_DIR=${INSTALL_PREFIX_openssl}/include  
                         
            # -DCMAKE_MODULE_PATH=${SrcDIR_lib}/cmake  # 优先使用项目内的 FindZLIB.cmake

            #  -DZstd_LIBRARY="${INSTALL_PREFIX_zstd}/lib/libzstd.a" \
            #  -DZLIB_ROOT=${INSTALL_PREFIX_zlib} \
            #  -DOPENSSL_SSL_LIBRARY=${INSTALL_PREFIX_openssl}/lib64/libssl.a \
            #  -DPENSSL_CRYPTO_LIBRARY=${INSTALL_PREFIX_openssl}/lib64/libcrypto.a \
            #  -DLIBPSL_LIBRARY=${INSTALL_PREFIX_psl}/lib/libpsl.a          

            # -DOPENSSL_LIBRARIES="${INSTALL_PREFIX_openssl}/lib/libssl.a; ${INSTALL_PREFIX_openssl}/lib/libcrypto.a" \
    cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v

    cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -v
    echo "========== Finished Building curl =========" &&  set +x
    
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
# if [ "${isFinished_buildJpeg9f}" != "true" ] ; then
#     echo "========== Building jpeg-9f for Android ==========" && sleep 3
#
#
#     # 最低支持的 Android API 级别
#     ANDROID_PLATFORM=21
#
#     # 循环编译每个架构
#     for ABI in "${ABIS[@]}"; do
#         echo "++++++++++++ Building jpeg-9f for ${ABI} ++++++++++++" && sleep 5
#
#         # 设置当前架构的构建目录和安装目录
#         BuildDIR_Jpeg9f=${BuildDir_andro}/3rd/jpeg-9f/build/${ABI}
#         rm -rf ${BuildDIR_Jpeg9f}
#         mkdir -p ${BuildDIR_Jpeg9f}
#
#         jpeg9f_installDir=${INSTALL_PREFIX_3rd}/jpeg-9f/${ABI}
#         rm -rf ${jpeg9f_installDir}
#         mkdir -p ${jpeg9f_installDir}
#
#         # 根据 ABI 选择对应的 NDK 工具链和交叉编译参数
#         case ${ABI} in
#             arm64-v8a)
#                 TARGET_HOST=aarch64-linux-android
#                 ;;
#             armeabi-v7a)
#                 TARGET_HOST=arm-linux-androideabi
#                 ;;
#             x86)
#                 TARGET_HOST=i686-linux-android
#                 ;;
#             x86_64)
#                 TARGET_HOST=x86_64-linux-android
#                 ;;
#             *)
#                 echo "ERROR: Unsupported ABI ${ABI}"
#                 exit 1
#                 ;;
#         esac
#
#         # 设置 NDK 工具链路径（使用 LLVM 工具）
#         TOOLCHAIN=${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64
#         # 使用统一的 LLVM 工具替代传统工具
#         AR=${TOOLCHAIN}/bin/llvm-ar
#         AS=${TOOLCHAIN}/bin/llvm-as
#         CC=${TOOLCHAIN}/bin/${TARGET_HOST}${ANDROID_PLATFORM}-clang
#         CXX=${TOOLCHAIN}/bin/${TARGET_HOST}${ANDROID_PLATFORM}-clang++
#         LD=${TOOLCHAIN}/bin/ld.lld
#         RANLIB=${TOOLCHAIN}/bin/llvm-ranlib
#         STRIP=${TOOLCHAIN}/bin/llvm-strip
#
#         # 进入构建目录并配置
#         cd ${BuildDIR_Jpeg9f}
# 
#         CFLAGS="-fPIC" \
#         ${OSG3RD_srcDir}/jpeg-9f/configure \
#             --prefix=${jpeg9f_installDir} \
#             --host=${TARGET_HOST} \
#             --enable-shared \
#             --enable-static \
#             --disable-doc \
#             CC=${CC} \
#             CXX=${CXX} \
#             AR=${AR} \
#             AS=${AS} \
#             LD=${LD} \
#             RANLIB=${RANLIB} \
#             STRIP=${STRIP}
#
#         # 编译并安装
#         make -j$(nproc)
#         make install
#
#         echo "++++++++++++Finished building jpeg-9f for ${ABI} ++++++++++++"
#     done
#     echo "========== Finished building jpeg-9f for Android ==========" && sleep 5
# fi


# -------------------------------------------------
# libjpeg-turbo
# -------------------------------------------------
isFinished_build_libjpegTurbo=true 

if [ "${isFinished_build_libjpegTurbo}" != "true" ] ; then
    echo "========== Building libjpeg-turbo for Android ==========" && sleep 5
 
    # 循环编译每个架构
    for ABI in "${ABIS[@]}"; do
        echo "++++++++++++ Building libjpeg-turbo for ${ABI} ++++++++++++"
        mkdir -p ${LIB3RD_INSTALL_DIR}/android/$ABI

        BuildDIR_andro=${BuildDir_andro}/3rd/libjpeg-turbo/build/$ABI
        
        cmake  -S${OSG3RD_srcDir}/libjpeg-turbo -B ${BuildDIR_andro} -G"Unix Makefiles" \
            -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
            -DANDROID_PLATFORM=android-21 \
            -DANDROID_ABI=$ABI \
            -DANDROID_STL=c++_shared \
            -DCMAKE_BUILD_TYPE=Debug \
            -DENABLE_SHARED=ON \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_3rd}/$ABI \
            ..
        
        #   make -j$(nproc)
        cmake --build ${BuildDIR_andro} -j$(nproc)

        #   make install
        cmake --build ${BuildDIR_andro} --target install
        echo "++++++++++++Finished building libjpeg-turbo for ${ABI} ++++++++++++"
    done   

    echo "========== Finished Building libjpeg-turbo for Android ==========" && sleep 5    
fi

  
 
# -------------------------------------------------
# sqlite
# ------------------------------------------------- 
INSTALL_PREFIX_sqlite=${INSTALL_PREFIX_andro}/3rd/sqlite

if [ "${isFinished_build_sqlite}" != "true" ] ; then 
    echo "========== building sqlite 4 android========== " &&  sleep 1
    SrcDIR_lib=${SrcDIR_3rd}/sqlite3cmake
    BuildDIR_lib=${BuildDir_andro}/3rd/sqlite
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_sqlite} ${isRebuild}   

    #################################################################### 
    # ---------------------    
    cmkPrefixPath_Arr=(
        "${INSTALL_PREFIX_zlib}"   
        )
    # 使用;号连接数组元素.
    cmkPrefixPath=$(IFS=";"; echo "${cmkPrefixPath_Arr[*]}")
    echo "For building curl: cmkPrefixPath=${cmkPrefixPath}" 

    cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib} --debug-find \
        -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
            -DANDROID_ABI=${CMAKE_ANDROID_ARCH_ABI} \
            -DANDROID_NATIVE_API_LEVEL=24 \
            "${cmakeCommonParams[@]}"  \
            -DCMAKE_PREFIX_PATH=${cmkPrefixPath} \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_sqlite}  
       
 
    cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v

    cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -v
 
    #################################################################### 
    echo "========== finished building sqlite 4 android ========== " &&  sleep 1 
fi

exit 11  
    



# -------------------------------------------------
# gdal 
# -------------------------------------------------
isFinished_build_gdal=false
if [ "${isFinished_build_gdal}" != "true" ] ; then 
    echo "========== building gdal 4 ubuntu========== " &&  sleep 5
 
    echo "========== finished building gdal 4 ubuntu ========== " &&  sleep 2
fi    


exit 11 