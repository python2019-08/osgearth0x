#!/bin/bash
# **************************************************************************
# false  ;;;   ./mk4android.sh  >ba.txt 2>&1
isRebuild=true

isFinished_build_zlib=true  
# isFinished_build_zstd=true
isFinished_build_openssl=true  
# isFinished_build_icu=true  
# isFinished_build_libidn2=true 
# isFinished_build_libpsl=true  
isFinished_build_curl=true   # false  
# isFinished_build_jpeg9f=true  
isFinished_build_libjpegTurbo=true   
isFinished_build_libpng=true    
# isFinished_build_xz=true  
isFinished_build_libtiff=true  
isFinished_build_freetype=true
isFinished_build_geos=true     # false
isFinished_build_sqlite=true
isFinished_build_proj=true   
# isFinished_build_libexpat=true  
isFinished_build_absl=true
isFinished_build_protobuf=true
isFinished_build_boost=false  
isFinished_build_gdal=false # v
isFinished_build_osg=true
isFinished_build_zip=true
isFinished_build_osgearth=false
    
# ANDROID_NDK_ROOT ​​:早期 Android 工具链（如 ndk-build）和部分开源项目（如 OpenSSL）习惯使用此变量。
export ANDROID_NDK_ROOT=/home/abner/Android/Sdk/ndk/27.1.12297006    
# ANDROID_NDK_HOME​ ​:后来 Android Studio 和 Gradle 更倾向于使用此变量。    
export ANDROID_NDK_HOME="${ANDROID_NDK_ROOT}"
# CMAKE_SYSROOT=${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/sysroot
# 
# 设置 NDK 工具链路径（使用 LLVM 工具）
TOOLCHAIN=${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64
# 使用统一的 LLVM 工具替代传统工具
export AR=${TOOLCHAIN}/bin/llvm-ar
export AS=${TOOLCHAIN}/bin/llvm-as
export LD=${TOOLCHAIN}/bin/ld.lld
export RANLIB=${TOOLCHAIN}/bin/llvm-ranlib
export STRIP=${TOOLCHAIN}/bin/llvm-strip
# 
ANDRO_TOOLCHAIN_FILE=${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake


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
# ABIS=("arm64-v8a"  "armeabi-v7a"  "x86_64"  "x86" )
# CMAKE_ANDROID_ARCH_ABI="x86_64" 
ABIS=("armeabi-v7a" )  
ABI_LEVEL=24
 
cmakeCommonParams=(
    "-DCMAKE_TOOLCHAIN_FILE=${ANDRO_TOOLCHAIN_FILE} "
    "-DANDROID_PLATFORM=android-${ABI_LEVEL}"  
    "-DANDROID_NATIVE_API_LEVEL=${ABI_LEVEL}  "
    "-DANDROID_STL=c++_static"  
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

get_targetHost_byABILvl()
{
    local ABILevel=$1

    # 根据 ABI 选择对应的 NDK 工具链和交叉编译参数
    case ${ABILevel} in
        arm64-v8a)
            TARGET_HOST=aarch64-linux-android
            ;;
        armeabi-v7a)
            TARGET_HOST=arm-linux-androideabi
            ;;
        x86)
            TARGET_HOST=i686-linux-android
            ;;
        x86_64)
            TARGET_HOST=x86_64-linux-android
            ;;
        *)
            echo "ERROR: Unsupported ABI ${ABI}"
            exit 1
            ;;
    esac

    echo "${TARGET_HOST}"
}

g_TARGET_HOST="aarch64-linux-android"
g_TARGET_ARCH="android-x86_64"

get_targetArch_byABILvl()
{
    local ABILevel=$1
 
    local targetArch="android-x86_64"
    
    # 根据 ABI 选择对应的 NDK 工具链和交叉编译参数
    case ${ABILevel} in
        arm64-v8a) 
            targetArch="android-arm64"
            ;;
        armeabi-v7a) 
            targetArch="android-arm"
            ;;
        x86) 
            targetArch="android-x86"
            ;;
        x86_64)
            targetArch="android-x86_64"
            ;;
        *)
            echo "ERROR: Unsupported ABI ${ABI}"
            exit 1
            ;;
    esac
         
    g_TARGET_ARCH=${targetArch}

    echo "${targetArch}"
}

for ABI in "${ABIS[@]}"; do
    ret_targetHost=$(get_targetHost_byABILvl "${ABI}")
    echo "....ret_targetHost=${ret_targetHost}"  
done
 
# **************************************************************************
# **************************************************************************
#  3rd/
# **************************************************************************
SrcDIR_3rd=${Repo_ROOT}/3rd
BuildDir_3rd=${BuildDir_andro}/3rd
INSTALL_PREFIX_3rd=${INSTALL_PREFIX_andro}/3rd
# -------------------------------------------------
# zlib
# -------------------------------------------------
if [ "${isFinished_build_zlib}" != "true" ]; then 
    echo "========== building zlib 4 Android========== " &&  sleep 1
    SrcDIR_lib=${SrcDIR_3rd}/zlib

    for ABI in "${ABIS[@]}"; do
        echo "++++++++++++++++++++++++++++++++++++++++++++++++++"
        echo "++++++++++++ Building zlib for ${ABI} ++++++++++++"
        
        BuildDIR_lib=${BuildDir_3rd}/zlib/$ABI
        INSTALL_PREFIX_zlib=${INSTALL_PREFIX_3rd}/zlib/$ABI  
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
            -DCMAKE_TOOLCHAIN_FILE=${ANDRO_TOOLCHAIN_FILE} \
            -DANDROID_ABI="${ABI}" \
            -DANDROID_NATIVE_API_LEVEL=${ABI_LEVEL} \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_zlib}  \
            -DCMAKE_C_FLAGS="-DZLIB_DEBUG=1"  \
            -DCMAKE_EXPORT_PACKAGE_REGISTRY=ON \
            -DZLIB_BUILD_SHARED=OFF \
            -DZLIB_BUILD_STATIC=ON 
  
                
        cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v 

        cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}
    
        #--## zlib源码编译后产生的ZLIBConfig.cmake 只有 ZLIB::ZLIBSTATIC ;
        #--  要获得导入型目标 ZLIB::ZLIB，需要默认的、来自系统路径的FindZlib.cmake 
        #--
        #----备份 zlib源码编译后产生的ZLIBConfig.cmake
        INSTALL_zlib_cmakeDir=${INSTALL_PREFIX_zlib}/lib/cmake/zlib
        mv  ${INSTALL_zlib_cmakeDir}/ZLIBConfig.cmake  ${INSTALL_zlib_cmakeDir}/ZLIBConfig.cmake-bk
        mv  ${INSTALL_zlib_cmakeDir}/pkgconfig         ${INSTALL_zlib_cmakeDir}/pkgconfig-bk
        #---- 把 FindZLIB.cmake 放到 ${INSTALL_PREFIX_zlib}/lib/cmake/
        # mkdir -p ${INSTALL_zlib_cmakeDir}
        # cp ${Repo_ROOT}/cmake/FindZLIB.cmake  ${INSTALL_zlib_cmakeDir}
        echo "++++++++++++Finished building zlib for ${ABI} ++++++++++++"
        echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    done   
    echo "========== finished building zlib 4 Android ========== " &&  sleep 1
fi 
 

# -------------------------------------------------
# openssl
# -------
# libssl.a是静态库​​，通常依赖 libcrypto.a提供底层加密函数
# （如 SHA256_Init、EVP_CIPHER_CTX_new）。
# -------------------------------------------------
if [ "${isFinished_build_openssl}" != "true" ]; then 
    echo "========== Building openssl 4 Android ========== " &&  sleep 1

    SrcDIR_lib=${SrcDIR_3rd}/openssl

    for ABI in "${ABIS[@]}"; do
        echo "++++++++++++++++++++++++++++++++++++++++++++++++++"
        echo "++++++++++++ Building openssl for ${ABI} ++++++++++++"
        
        BuildDIR_lib=${BuildDir_3rd}/openssl/$ABI
        INSTALL_PREFIX_openssl=${INSTALL_PREFIX_3rd}/openssl/$ABI  
        prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_openssl} ${isRebuild}     
 
    
        cd ${BuildDIR_lib}
        # (1) 如需调试支持，改用 enable-asan或 -d​​
        # # 方案1：使用 OpenSSL 的调试模式（生成调试符号）
        #     ./Configure linux-x86_64 -d --prefix=...
        # 
        # # 方案2：启用 AddressSanitizer（调试内存问题）
        #     ./Configure linux-x86_64 enable-asan --prefix=...
        # (2) 如需调试符号，改用 -g：
        #     CFLAGS="-fPIC -g" ./Configure ...
        # (3) 根据设备选择正确的 目标架构
        #   ${SrcDIR_lib}/Configure android-arm # 32 位 ARM    
        #   ${SrcDIR_lib}/Configure android-arm64 # 64 位 ARM
        target_ARCH=$(get_targetArch_byABILvl  ${ABI})
        echo "ssl....target_ARCH=${target_ARCH}"

        # 在编译时标记符号为 "hidden"（仅限动态链接）
        CFLAGS="-fPIC -fvisibility=hidden" \
        ${SrcDIR_lib}/Configure ${target_ARCH} -d \
                    -D__ANDROID_API__=${ABI_LEVEL} \
                    --prefix=${INSTALL_PREFIX_openssl} \
                    --openssldir=${INSTALL_PREFIX_openssl}/ssl  \
                    no-shared  no-zlib no-module  no-dso 

            #  (1)-static确保完全静态链接,导致"ld.lld: error: duplicate symbol: time"
            #  即使 -fvisibility=hidden 也无法消除

        make build_sw -j$(nproc)  V=1

        make install_sw  

        echo "++++++++++++Finished building openssl for ${ABI} ++++++++++++"
        echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    done   
    echo "========== finished building openssl 4 Android ========== "
    
fi 
  

# -------------------------------------------------
# curl
#    remark: /usr/share/cmake-3.28/Modules/FindCURL.cmake
# -------------------------------------------------
if [ "${isFinished_build_curl}" != "true" ] ; then 
    echo "======== Building curl =========" &&  sleep 1 && set -x     
    SrcDIR_lib=${SrcDIR_3rd}/curl

    # 循环编译每个架构
    for ABI in "${ABIS[@]}"; do
        echo "++++++++++++ Building curl for ${ABI} ++++++++++++"
        
        BuildDIR_lib=${BuildDir_3rd}/curl/$ABI
        INSTALL_PREFIX_curl=${INSTALL_PREFIX_3rd}/curl/$ABI  
        prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_curl} ${isRebuild}     
        
        # -------- 
        INSTALL_PREFIX_zlib=${INSTALL_PREFIX_3rd}/zlib/$ABI
        INSTALL_PREFIX_openssl=${INSTALL_PREFIX_3rd}/openssl/$ABI

        cmkPrefixPath_Arr=(
            "${INSTALL_PREFIX_zlib}"  
            "${INSTALL_PREFIX_openssl}" 
            )
        # 使用;号连接数组元素.
        cmkPrefixPath=$(IFS=";"; echo "${cmkPrefixPath_Arr[*]}")
        echo "For building curl: cmkPrefixPath=${cmkPrefixPath}" 
        # --------
        cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib} --debug-find \
              "${cmakeCommonParams[@]}"   -DANDROID_ABI=${ABI}  \
                -DCMAKE_PREFIX_PATH=${cmkPrefixPath} \
                -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_curl}  \
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
        echo "++++++++++++Finished building curl for ${ABI} ++++++++++++"
    done       
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
#     SrcDIR_lib=${SrcDIR_3rd}/jpeg-9f
#
# 
#
#     # 循环编译每个架构
#     for ABI in "${ABIS[@]}"; do
#         echo "++++++++++++ Building jpeg-9f for ${ABI} ++++++++++++" && sleep 5
#         TARGET_HOST=$(get_targetHost_byABILvl "${ABI}")
#   
#         # 设置当前架构的构建目录和安装目录
#         BuildDIR_lib=${BuildDir_andro}/3rd/jpeg-9f/${ABI}
#         INSTALL_PREFIX_jpeg9f=${INSTALL_PREFIX_3rd}/jpeg-9f/${ABI}
#         prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_jpeg9f} ${isRebuild}    
#
#         # 设置 NDK 工具链路径（使用 LLVM 工具）
#         CC=${TOOLCHAIN}/bin/${TARGET_HOST}${ABI_LEVEL}-clang
#         CXX=${TOOLCHAIN}/bin/${TARGET_HOST}${ABI_LEVEL}-clang++
#
#         # 进入构建目录并配置
#         cd ${BuildDIR_lib}
# 
#         CFLAGS="-fPIC" \
#         ${SrcDIR_lib}/configure  --prefix=${INSTALL_PREFIX_jpeg9f} \
#             --host=${TARGET_HOST} \
#             --enable-shared  --enable-static  --disable-doc \
#             CC=${CC}  CXX=${CXX}  AR=${AR}  AS=${AS}  LD=${LD} \
#             RANLIB=${RANLIB}    STRIP=${STRIP}
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
if [ "${isFinished_build_libjpegTurbo}" != "true" ] ; then
    echo "========== Building libjpeg-turbo for Android ==========" && sleep 1
    SrcDIR_lib=${SrcDIR_3rd}/libjpeg-turbo

    # 循环编译每个架构
    for ABI in "${ABIS[@]}"; do
        echo "++++++++++++ Building libjpeg-turbo for ${ABI} ++++++++++++"
        
        BuildDIR_lib=${BuildDir_3rd}/libjpeg-turbo/$ABI
        INSTALL_PREFIX_jpegTb=${INSTALL_PREFIX_3rd}/libjpeg-turbo/$ABI  
        prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_jpegTb} ${isRebuild}     
        
        cmake  -S${SrcDIR_lib} -B ${BuildDIR_lib} -G"Unix Makefiles" \
            "${cmakeCommonParams[@]}"   -DANDROID_ABI=${ABI}  \
            -DCMAKE_FIND_LIBRARY_SUFFIXES=".a"  \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_jpegTb}  \
            -DWITH_JPEG8=ON      \
            -DENABLE_SHARED=OFF  \
            -DWITH_SIMD=ON       # 启用 SIMD 优化（需安装 NASM）

      
        echo "make -j$(nproc)..........................."
        cmake --build ${BuildDIR_lib} -j$(nproc) -v

        echo "make install.............................."
        # cmake --build ${BuildDIR_lib} --target install  -v
        cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -v
        echo "++++++++++++Finished building libjpeg-turbo for ${ABI} ++++++++++++"
    done   

    echo "========== Finished Building libjpeg-turbo for Android =========="   
fi


# -------------------------------------------------
# libpng
# -------------------------------------------------
 
if [ "${isFinished_build_libpng}" != "true" ] ; then 
    echo "========== Building libpng 4 Android==========" && sleep 1 && set -x

    SrcDIR_lib=${SrcDIR_3rd}/libpng

    # 循环编译每个架构
    for ABI in "${ABIS[@]}"; do
        echo "++++++++++++ Building libpng for ${ABI} ++++++++++++"
        
        BuildDIR_lib=${BuildDir_3rd}/libpng/$ABI
        INSTALL_PREFIX_png=${INSTALL_PREFIX_3rd}/libpng/$ABI  
        prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_png} ${isRebuild}     
 
        # ----
        INSTALL_PREFIX_zlib=${INSTALL_PREFIX_3rd}/zlib/$ABI 
        cmk_prefixPath="${INSTALL_PREFIX_zlib}"
        
        # ----        
        cmake -S${SrcDIR_lib} -B ${BuildDIR_lib} --debug-find \
            "${cmakeCommonParams[@]}"   -DANDROID_ABI=${ABI}  \
            -DCMAKE_MODULE_PATH="${INSTALL_PREFIX_zlib}/lib/cmake/zlib" \
            -DCMAKE_PREFIX_PATH="${cmk_prefixPath}" \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_png} \
            -DZLIB_ROOT="${INSTALL_PREFIX_zlib}" \
            -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a \
            -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include \
            -DPNG_SHARED=OFF \
            -DPNG_STATIC=ON   
                

        cmake --build ${BuildDIR_lib} -j$(nproc)

        cmake --build ${BuildDIR_lib} --target install

        echo "++++++++++++Finished building libpng for ${ABI} ++++++++++++"
    done   

    echo "========== Finished Building libpng for Android ==========" && sleep 1 && set +x   
fi    

 

# -------------------------------------------------
# libtiff
# -------------------------------------------------
if [ "${isFinished_build_libtiff}" != "true" ] ; then 
    echo "========== Building libtiff 4 Android==========" && sleep 1 && set -x

    SrcDIR_lib=${SrcDIR_3rd}/libtiff

    # 循环编译每个架构
    for ABI in "${ABIS[@]}"; do
        echo "++++++++++++ Building libtiff for ${ABI} ++++++++++++"
        
        BuildDIR_lib=${BuildDir_3rd}/libtiff/$ABI
        INSTALL_PREFIX_tiff=${INSTALL_PREFIX_3rd}/libtiff/$ABI    
        prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_tiff} ${isRebuild}     
        # 
        INSTALL_PREFIX_zlib=${INSTALL_PREFIX_3rd}/zlib/$ABI
        INSTALL_PREFIX_jpegTb=${INSTALL_PREFIX_3rd}/libjpeg-turbo/$ABI

        cmk_prefixPath="${INSTALL_PREFIX_zlib}"
        cmk_prefixPath="${cmk_prefixPath};${INSTALL_PREFIX_jpegTb}"

        # 
        cmake -S${SrcDIR_lib} -B ${BuildDIR_lib} --debug-find \
            "${cmakeCommonParams[@]}"   -DANDROID_ABI=${ABI}  \
            -DCMAKE_PREFIX_PATH="${cmk_prefixPath}" \
            -DCMAKE_MODULE_PATH="${INSTALL_PREFIX_zlib}/lib/cmake/zlib" \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_tiff}  \
            -DZLIB_ROOT=${INSTALL_PREFIX_zlib}  \
            -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a \
            -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include \
            -DJPEG_LIBRARY=${INSTALL_PREFIX_jpegTb}/lib/libjpeg.a \
            -DJPEG_INCLUDE_DIR=${INSTALL_PREFIX_jpegTb}/include/libjpeg \
            -DCMAKE_EXE_LINKER_FLAGS="-static" \
            -Djbig=OFF \
            -Dlzma=OFF \
            -Dwebp=OFF \
            -Dzstd=OFF \
            -Dtiff-tools=OFF   
 
           
        cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v

        cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -v
        echo "++++++++++++Finished building libtiff for ${ABI} ++++++++++++"
    done       
    echo "========== Finished Building libtiff for Android ==========" && sleep 1 && set +x

fi 


# -------------------------------------------------
# freetype
# -------------------------------------------------
# 编译输出中的freetype相关依赖项目：
# 
# | 依赖库       | 状态                  | 影响                                                    |
# |--------------|-----------------------|-------------------------------------------------------|
# | **BZip2**    | `Could NOT find`      | FreeType 将无法处理 `.bz2` 压缩的字体文件（如 `.ttf.bz2`）。|
# | **BrotliDec**| `Could NOT find`      | 无法解析 Brotli 压缩的字体（如 `.ttf.br`），但此类文件较少见。|
# | **ZLIB**     | 已找到（`libz.so`）    | 支持 `.ttf.gz` 和常规压缩。                              |
# | **PNG**      | 已找到（`libpng.so`）  | 支持位图字体（如 `.png` 格式的彩色字体）。                   |
# -------------------------------------------------
if [ "${isFinished_build_freetype}" != "true" ] ; then 
    echo "========== Building freetype 4 Android ==========" && sleep 1 # && set -x


    SrcDIR_lib=${SrcDIR_3rd}/freetype
    # 循环编译每个架构
    for ABI in "${ABIS[@]}"; do
        echo "++++++++++++ Building freetype for ${ABI} ++++++++++++"
        
        BuildDIR_lib=${BuildDir_3rd}/freetype/$ABI
        INSTALL_PREFIX_freetype=${INSTALL_PREFIX_3rd}/freetype/$ABI    
        prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_freetype} ${isRebuild}     

        # ----
        INSTALL_PREFIX_zlib=${INSTALL_PREFIX_3rd}/zlib/$ABI
        INSTALL_PREFIX_png=${INSTALL_PREFIX_3rd}/libpng/$ABI
         
        cmk_prefixPath="${INSTALL_PREFIX_zlib};${INSTALL_PREFIX_png}"
        echo "ha...cmk_prefixPath=${cmk_prefixPath}"
        # ----
        TARGET_HOST=$(get_targetHost_byABILvl "${ABI}")
        NdkCC=${TOOLCHAIN}/bin/${TARGET_HOST}${ABI_LEVEL}-clang
        NdkCXX=${TOOLCHAIN}/bin/${TARGET_HOST}${ABI_LEVEL}-clang++         
        echo "ha...CC=${NdkCC}  CXX=${NdkCXX} "
        
        # ----
        cmake -S${SrcDIR_lib} -B ${BuildDIR_lib} --debug-find \
            "${cmakeCommonParams[@]}"   -DANDROID_ABI=${ABI}  \
            -DCMAKE_C_COMPILER="${NdkCC}" \
            -DCMAKE_CXX_COMPILER="${NdkCXX}" \
                -DCMAKE_PREFIX_PATH="${cmk_prefixPath}" \
                -DCMAKE_MODULE_PATH="${INSTALL_PREFIX_zlib}/lib/cmake/zlib" \
                -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_freetype} \
                -DFT_DISABLE_BZIP2=ON \
                -DFT_DISABLE_BROTLI=ON \
                -DZLIB_ROOT=${INSTALL_PREFIX_zlib}  \
                -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include \
                -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a \
                -DPNG_LIBRARY="${INSTALL_PREFIX_png}/lib/libpng.a" \
                -DPNG_INCLUDE_DIR="${INSTALL_PREFIX_png}/include" \
                -DPNG_INCLUDE_DIRS="${INSTALL_PREFIX_png}/include" \
                -DPNG_LIBRARIES="${INSTALL_PREFIX_png}/lib/libpng.a" \
                -DFT_REQUIRE_ZLIB=ON \
                -DFT_REQUIRE_PNG=ON  \
                -DCMAKE_EXE_LINKER_FLAGS="-static"  
                # CC=${CC}  CXX=${CXX} 

        # cmake --build ${BuildDIR_lib} -j$(nproc)  -v  
        # 
        # 编译输出：toolchains/llvm/prebuilt/linux-x86_64/bin/clang --target=x86_64-none-linux-android24 --sysroot=
        # clang --target=x86_64-none-linux-android24和 x86_64-linux-android24-clang​​完全等效​​。
        # 
        cmake --build ${BuildDIR_lib} -j$(nproc) -- VERBOSE=1  

        cmake --build ${BuildDIR_lib} --target install -v  
        echo "++++++++++++Finished building freetype for ${ABI} ++++++++++++"
    done       
    echo "========== Finished Building freetype for Android ==========" && sleep 1  #  && set +x
fi
 

 
# -------------------------------------------------
# geos
# ------------------------------------------------- 
if [ "${isFinished_build_geos}" != "true" ] ; then 
    echo "========== building geos 4 Android ========== " &&  sleep 1

    SrcDIR_lib=${SrcDIR_3rd}/geos

    # 循环编译每个架构
    for ABI in "${ABIS[@]}"; do
        echo "++++++++++++ Building geos for ${ABI} ++++++++++++"
        
        BuildDIR_lib=${BuildDir_3rd}/geos/$ABI
        INSTALL_PREFIX_geos=${INSTALL_PREFIX_3rd}/geos/$ABI    
        prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_geos} ${isRebuild}     

        # ----NdkCC
        TARGET_HOST=$(get_targetHost_byABILvl "${ABI}")
        NdkCC=${TOOLCHAIN}/bin/${TARGET_HOST}${ABI_LEVEL}-clang     
        echo "ha...CC=${NdkCC}" 
        
        #################################################################### 
        # 在顶层 CMakeLists.txt 中全局启用 PIC: set(CMAKE_POSITION_INDEPENDENT_CODE ON)  
        cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib} --debug-find   \
                "${cmakeCommonParams[@]}"   -DANDROID_ABI=${ABI}  \
                -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_geos}  \
                -DCMAKE_EXE_LINKER_FLAGS="-static" 
 

                # -DCMAKE_C_COMPILER="${NdkCC}" \
                # -DCMAKE_CXX_COMPILER="${NdkCXX}" \
                # -DCMAKE_C_FLAGS="-fPIC" \
                # -DCMAKE_CXX_FLAGS="-fPIC" \  
        cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v
        
        cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -v

        echo "++++++++++++Finished building geos for ${ABI} ++++++++++++"
    done           
    #################################################################### 
    echo "========== finished building geos 4 Android ========== " 
fi

 
 
# -------------------------------------------------
# sqlite
# ------------------------------------------------- 
if [ "${isFinished_build_sqlite}" != "true" ] ; then 
    echo "========== building sqlite 4 Android========== " &&  sleep 1
    
    SrcDIR_lib=${SrcDIR_3rd}/sqlite3cmake

    # 循环编译每个架构
    for ABI in "${ABIS[@]}"; do
        echo "++++++++++++ Building sqlite for ${ABI} ++++++++++++"
        
        BuildDIR_lib=${BuildDir_3rd}/sqlite/$ABI
        INSTALL_PREFIX_sqlite=${INSTALL_PREFIX_3rd}/sqlite/$ABI
        prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_sqlite} ${isRebuild}     
         
        # ----
        INSTALL_PREFIX_zlib=${INSTALL_PREFIX_3rd}/zlib/$ABI

        cmkPrefixPath_Arr=(
            "${INSTALL_PREFIX_zlib}"   
            )
        # 使用;号连接数组元素.
        cmkPrefixPath=$(IFS=";"; echo "${cmkPrefixPath_Arr[*]}")
        echo "For building curl: cmkPrefixPath=${cmkPrefixPath}" 

        # ----
        cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib} --debug-find \
            "${cmakeCommonParams[@]}"   -DANDROID_ABI=${ABI}    \
            -DCMAKE_PREFIX_PATH=${cmkPrefixPath} \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_sqlite}  \
            -DZLIB_ROOT=${INSTALL_PREFIX_zlib}  \
            -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include \
            -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a   \
            -DCMAKE_EXE_LINKER_FLAGS="-fuse-ld=lld" \
            -DCMAKE_SHARED_LINKER_FLAGS="-fuse-ld=lld" \
            -DCMAKE_MODULE_LINKER_FLAGS="-fuse-ld=lld" \
            -DSQLITE_ENABLE_COLUMN_METADATA=ON \
            -DSQLITE_OMIT_DEPRECATED=ON \
            -DSQLITE_SECURE_DELETE=ON       

            # -DCMAKE_ANDROID_ARCH_ABI=${ABI}     
        cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v

        cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -v
        echo "++++++++++++Finished building sqlite for ${ABI} ++++++++++++"
    done         
    echo "========== finished building sqlite 4 Android ========== " 
fi

 

# -------------------------------------------------
# proj
# ------------------------------------------------- 
if [ "${isFinished_build_proj}" != "true" ] ; then 
    echo "========== building proj 4 ubuntu========== " &&  sleep 1 # && set -x

    # 循环编译每个架构
    for ABI in "${ABIS[@]}"; do
        echo "++++++++++++ Building proj for ${ABI} ++++++++++++"
        
        BuildDIR_lib=${BuildDir_3rd}/proj/$ABI
        INSTALL_PREFIX_proj=${INSTALL_PREFIX_3rd}/proj/$ABI
        prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_proj} ${isRebuild}     
 
        #------
        # INSTALL_PREFIX_xz=...
        INSTALL_PREFIX_zlib=${INSTALL_PREFIX_3rd}/zlib/$ABI        
        INSTALL_PREFIX_openssl=${INSTALL_PREFIX_3rd}/openssl/$ABI
        INSTALL_PREFIX_curl=${INSTALL_PREFIX_3rd}/curl/$ABI  
        INSTALL_PREFIX_sqlite=${INSTALL_PREFIX_3rd}/sqlite/$ABI
 
        cmkPrefixPath_Arr=(
            "${INSTALL_PREFIX_zlib}"  
            "${INSTALL_PREFIX_openssl}" 
            "${INSTALL_PREFIX_curl}" 
            "${INSTALL_PREFIX_sqlite}" 
            )
        # 使用;号连接数组元素.
        cmkPrefixPath=$(IFS=";"; echo "${cmkPrefixPath_Arr[*]}")
        echo "For building curl: cmkPrefixPath=${cmkPrefixPath}" 

        #  CC=musl-gcc cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib}     
        cmake -S ${SrcDIR_lib}  -B ${BuildDIR_lib} --debug-find \
                "${cmakeCommonParams[@]}"   -DANDROID_ABI=${ABI} \
                -DCMAKE_PREFIX_PATH="${cmkPrefixPath}" \
                -DCMAKE_MODULE_PATH="${INSTALL_PREFIX_zlib}/lib/cmake/zlib" \
                -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_proj}  \
                -DBUILD_TESTING=OFF \
                -DBUILD_EXAMPLES=ON \
                -DENABLE_CURL=ON  \
                -DENABLE_TIFF=OFF  \
                -DSQLite3_DISABLE_DYNAMIC_EXTENSIONS=ON \
                -DCURL_DISABLE_ARES=ON  \
                -DZLIB_ROOT="${INSTALL_PREFIX_zlib}" \
                -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a  \
                -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include  \
                -DSQLite3_LIBRARY=${INSTALL_PREFIX_sqlite}/lib/libsqlite3.a \
                -DSQLite3_INCLUDE_DIR=${INSTALL_PREFIX_sqlite}/include       \
                -DCURL_ROOT=${INSTALL_PREFIX_curl}                   \
                -DCURL_LIBRARY=${INSTALL_PREFIX_curl}/lib/libcurl-d.a \
                -DCURL_INCLUDE_DIR=${INSTALL_PREFIX_curl}/include      \                

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
    

                # -DCMAKE_CXX_FLAGS="-fPIC" \
                # -DCMAKE_C_FLAGS="-fPIC"  \
                # -DOPENSSL_ROOT_DIR=${INSTALL_PREFIX_openssl} \
                # -DOPENSSL_LIBRARIES="${libssl_path};${libcrypto_path}" \
                # -DTIFF_LIBRARY=${INSTALL_PREFIX_tiff}/lib/libtiff.a \
                # -DTIFF_INCLUDE_DIR=${INSTALL_PREFIX_tiff}/include \

                # -DCMAKE_SHARED_LINKER_FLAGS="-L${lib_dir} -ltiff -ljpeg -llzma -lz -L${lib64_dir} -lssl -lcrypto -lz" \
                # -DCMAKE_EXE_LINKER_FLAGS="-L${lib_dir} -ltiff -ljpeg -llzma -lz -L${lib64_dir} -lssl -lcrypto -lz" \
                # -DCMAKE_EXE_LINKER_FLAGS="-static" \ 
 
        cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}   -j$(nproc) -v
        
        cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -v
        echo "++++++++++++Finished building proj for ${ABI} ++++++++++++"
    done         
    echo "========== finished building proj 4 ubuntu ========== "  # && set -x
fi


# -------------------------------------------------
# abseil-cpp  
# -------------------------------------------------
if [ "${isFinished_build_absl}" != "true" ] ; then 
    echo "========== building abseil-cpp 4 ubuntu========== " &&  sleep 5

    SrcDIR_lib=${SrcDIR_3rd}/abseil-cpp

    # 循环编译每个架构
    for ABI in "${ABIS[@]}"; do
        echo "++++++++++++ Building abseil-cpp for ${ABI} ++++++++++++"
        
        BuildDIR_lib=${BuildDir_3rd}/abseil-cpp/$ABI
        INSTALL_PREFIX_absl=${INSTALL_PREFIX_3rd}/abseil-cpp/$ABI 
        prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_absl} ${isRebuild}      

        # ------
        cmk_prefixPath=“” 
        
        # ------
        cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib}  --debug-find  \
                "${cmakeCommonParams[@]}"   -DANDROID_ABI=${ABI}  \
                -DCMAKE_PREFIX_PATH="${cmk_prefixPath}"       \
                -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_absl}  \
                -DBUILD_SHARED_LIBS=OFF    
   

        cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v
        
        cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  
        echo "++++++++++++Finished building abseil-cpp for ${ABI} ++++++++++++"
    done  
    echo "========== finished building abseil-cpp 4 ubuntu ========== " &&  sleep 2
fi     

# -------------------------------------------------
# protobuf  
# -------------------------------------------------
if [ "${isFinished_build_protobuf}" != "true" ] ; then 
    echo "========== building protobuf 4 ubuntu========== " &&  sleep 5

    SrcDIR_lib=${SrcDIR_3rd}/protobuf

    # 循环编译每个架构
    for ABI in "${ABIS[@]}"; do
        echo "++++++++++++ Building protobuf for ${ABI} ++++++++++++"
        
        BuildDIR_lib=${BuildDir_3rd}/protobuf/$ABI
        INSTALL_PREFIX_protobuf=${INSTALL_PREFIX_3rd}/protobuf/$ABI
        prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_protobuf} ${isRebuild}     

    
        # ------
        # ;${INSTALL_PREFIX_absl}
        INSTALL_PREFIX_zlib=${INSTALL_PREFIX_3rd}/zlib/$ABI 
        INSTALL_PREFIX_absl=${INSTALL_PREFIX_3rd}/abseil-cpp/$ABI 
        cmk_prefixPath="${INSTALL_PREFIX_zlib};${INSTALL_PREFIX_absl}"

        # ------
        protoc_path=/home/abner/programs/protoc-31.1-linux-x86_64/bin/protoc

        # ------
        cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib}  --debug-find  \
                "${cmakeCommonParams[@]}"   -DANDROID_ABI=${ABI}  \
                -DCMAKE_PREFIX_PATH="${cmk_prefixPath}" \
                -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_protobuf}  \
                -Dprotobuf_BUILD_TESTS=OFF \
                -Dprotobuf_BUILD_EXAMPLES=OFF \
                -Dprotobuf_BUILD_PROTOC_BINARIES=OFF \
                -Dprotobuf_PROTOC_EXE=${protoc_path} \
                -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a  \
                -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include           

        cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc)  -v
        
        cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -v    
        echo "++++++++++++Finished building protobuf for ${ABI} ++++++++++++"
    done            
      
    echo "========== finished building protobuf 4 ubuntu ========== " &&  sleep 1
fi    


# -------------------------------------------------
# boost  
# -------------------------------------------------
if [ "${isFinished_build_boost}" != "true" ] ; then 
    echo "========== building boost 4 ubuntu========== " &&  sleep 1 # && set -x


    SrcDIR_lib=${SrcDIR_3rd}/boost

    # 循环编译每个架构
    for ABI in "${ABIS[@]}"; do
        echo "++++++++++++ Building protobuf for ${ABI} ++++++++++++"
        
        BuildDIR_lib=${BuildDir_3rd}/boost/$ABI
        INSTALL_PREFIX_boost=${INSTALL_PREFIX_3rd}/boost/$ABI
        prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_boost} ${isRebuild}     


        #  进入 Boost 源码目录 
        cd ${SrcDIR_lib}  
        # 清理旧配置
        rm -rf bin.v2/   project-config.jam  b2  bjam
        
        # 重新生成干净的 b2（此时无 MPI 相关配置）
        ./bootstrap.sh --with-toolset=clang
    
        # 静态编译 Boost
        TARGET_HOST=$(get_targetHost_byABILvl "${ABI}")

        ./b2 install  --prefix="${INSTALL_PREFIX_boost}" \
            toolset=clang    target-os=android   \
            cxxflags="--target=${TARGET_HOST}${API_LEVEL} \
                    --sysroot=${TOOLCHAIN}/sysroot \
                    -I${TOOLCHAIN}/include/c++/v1" \
            linkflags="--target=${TARGET_HOST}${API_LEVEL} \
                    --sysroot=${TOOLCHAIN}/sysroot" \
            link=static        \
            runtime-link=static \
            threading=multi      \
            --layout=versioned    \
            --with-system  --with-thread  \
            --with-atomic  --with-regex   \
            -j$(nproc)

  
        #  --without-mpi ### 最推荐的方案，因 osgearth 通常不需 Boost.MPI 组件，排除后可避免 MPI 相关的配置问题
        # (1) 仅编译特定库​​:    ./b2 install --with-thread --with-system --with-filesystem
        # ​​(2) 仅生成静态库​​:    ./b2 link=static
        # ​​(3) 仅生成动态库​​:    ./b2 link=shared
        # ​​(4) 指定 C++ 标准​​:  ./b2 cxxflags="-std=c++17" 
        echo "++++++++++++Finished building protobuf for ${ABI} ++++++++++++"
    done            
    echo "========== Finished Building boost ========="  # && set +x
fi

 
# -------------------------------------------------
# gdal , see 3rd/gdal/fuzzers/build.sh
# -------------------------------------------------


if [ "${isFinished_build_gdal}" != "true" ] ; then 
    echo "========== building gdal 4 Android========== " &&  sleep 1 && set -x

    SrcDIR_lib=${SrcDIR_3rd}/gdal

    for ABI in "${ABIS[@]}"; do
        echo "++++++++++++ Building gdal for ${ABI} ++++++++++++"
        
        BuildDIR_lib=${BuildDir_3rd}/gdal/$ABI
        INSTALL_PREFIX_gdal=${INSTALL_PREFIX_3rd}/gdal/$ABI
        prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_gdal} ${isRebuild}     


        # ------  
        INSTALL_PREFIX_zlib=${INSTALL_PREFIX_3rd}/zlib/$ABI 
        INSTALL_PREFIX_png=${INSTALL_PREFIX_3rd}/libpng/$ABI
        INSTALL_PREFIX_absl=${INSTALL_PREFIX_3rd}/abseil-cpp/$ABI 
        INSTALL_PREFIX_protobuf=${INSTALL_PREFIX_3rd}/protobuf/$ABI
        INSTALL_PREFIX_jpegTb=${INSTALL_PREFIX_3rd}/libjpeg-turbo/$ABI
        INSTALL_PREFIX_openssl=${INSTALL_PREFIX_3rd}/openssl/$ABI
        INSTALL_PREFIX_tiff=${INSTALL_PREFIX_3rd}/libtiff/$ABI   
        INSTALL_PREFIX_geos=${INSTALL_PREFIX_3rd}/geos/$ABI 
        INSTALL_PREFIX_proj=${INSTALL_PREFIX_3rd}/proj/$ABI
        INSTALL_PREFIX_curl=${INSTALL_PREFIX_3rd}/curl/$ABI  
        INSTALL_PREFIX_sqlite=${INSTALL_PREFIX_3rd}/sqlite/$ABI        

        cmkPrefixPath_Arr=(
            "${INSTALL_PREFIX_zlib}" 
            "${INSTALL_PREFIX_png}" 
            "${INSTALL_PREFIX_absl}"   
            "${INSTALL_PREFIX_protobuf}"  
            "${INSTALL_PREFIX_jpegTb}"  
            "${INSTALL_PREFIX_openssl}" 
            "${INSTALL_PREFIX_tiff}"    
            "${INSTALL_PREFIX_geos}"   
            "${INSTALL_PREFIX_proj}"   
            "${INSTALL_PREFIX_curl}"   
            "${INSTALL_PREFIX_sqlite}"
            )
        # 使用;号连接数组元素.
        cmkPrefixPath=$(IFS=";"; echo "${cmkPrefixPath_Arr[*]}")
        echo "For building gdal: cmkPrefixPath=${cmkPrefixPath}"   
        # 选择Release，否则 osgearth 编译时发生 类型转换错误​​（invalid conversion from 'void*' to 'OGRLayerH'）
        
        # ------
        gdal_MODULE_PATH="${INSTALL_PREFIX_zlib}/lib/cmake/zlib"
        gdal_MODULE_PATH="${gdal_MODULE_PATH};${INSTALL_PREFIX_openssl}/lib/cmake/OpenSSL/"

        cmake -S ${SrcDIR_lib}  -B ${BuildDIR_lib}  --debug-find \
                "${cmakeCommonParams[@]}"   -DANDROID_ABI=${ABI}  \
                -DCMAKE_PREFIX_PATH=${cmkPrefixPath} \
                -DCMAKE_MODULE_PATH="${gdal_MODULE_PATH}" \
                -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_gdal}  \
                -DCMAKE_C_FLAGS="-fPIC  -DJPEG12_SUPPORTED=0"   \
                -DCMAKE_CXX_FLAGS="-fPIC  -DJPEG12_SUPPORTED=0" \
                -DBUILD_SHARED_LIBS=OFF   \
                -DBUILD_APPS=OFF \
                -DBUILD_TESTING=OFF \
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
                -DHAVE_JPEGTURBO_DUAL_MODE_8_12=OFF \
                -DHAVE_KEA=OFF \
                -DCURL_LIBRARY=${INSTALL_PREFIX_curl}/lib/libcurl-d.a \
                -DCURL_INCLUDE_DIR=${INSTALL_PREFIX_curl}/include \
                -DGEOS_INCLUDE_DIR=${INSTALL_PREFIX_geos}/include \
                -DGEOS_LIBRARY=${INSTALL_PREFIX_geos}/lib/libgeos.a \
                -DPROJ_INCLUDE_DIR=${INSTALL_PREFIX_proj}/include \
                -DPROJ_LIBRARY=${INSTALL_PREFIX_proj}/lib/libproj.a \
                -DSQLITE3_INCLUDE_DIR=${INSTALL_PREFIX_sqlite}/include \
                -DPNG_INCLUDE_DIR=${INSTALL_PREFIX_png}/include \
                -DPNG_LIBRARY=${INSTALL_PREFIX_png}/lib/libpng.a \
                -DJPEG_INCLUDE_DIR=${INSTALL_PREFIX_jpegTb}/include \
                -DJPEG_LIBRARY=${INSTALL_PREFIX_jpegTb}/lib/libjpeg.a \
                -DSQLITE3_LIBRARY=${INSTALL_PREFIX_sqlite}/lib/libsqlite3.a \
                -DOPENSSL_DIR=${INSTALL_PREFIX_openssl}/lib64/cmake/OpenSSL/ \
                -DOPENSSL_ROOT_DIR=${INSTALL_PREFIX_openssl} \
                -DOPENSSL_INCLUDE_DIR=${INSTALL_PREFIX_openssl}/include \
                -DOPENSSL_SSL_LIBRARY=${INSTALL_PREFIX_openssl}/lib64/libssl.a \
                -DOPENSSL_CRYPTO_LIBRARY=${INSTALL_PREFIX_openssl}/lib64/libcrypto.a \
                -DPROTOBUF_LIBRARY=${INSTALL_PREFIX_protobuf}/lib/libprotobuf.a \
                -DPROTOBUF_INCLUDE_DIR=${INSTALL_PREFIX_protobuf}/include  \
                -DZLIB_ROOT=${INSTALL_PREFIX_zlib} \
                -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include \
                -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a \

            # -DHAVE_KEA ## hdf5 support 

        cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v
        
        cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}     
        echo "++++++++++++Finished building gdal for ${ABI} ++++++++++++"
    done               
    echo "========== finished building gdal 4 Android ========== " &&  sleep 1 && set +x
fi    

 