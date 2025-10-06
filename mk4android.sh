#!/bin/bash
# **************************************************************************
# false  ;;;   ./mk4android.sh  >ba.txt 2>&1
startTm=$(date +%Y/%m/%d--%H:%M:%S) 

# 输出脚本名称
echo "mk4ubuntu.sh: param 0=$0"

# 获取脚本的物理绝对路径（解析软链接）
SCRIPT_PHYSICAL_PATH=$(readlink -f "$0")
echo "Physical path: $SCRIPT_PHYSICAL_PATH"

#--额外：获取脚本所在目录的绝对路径
# Repo_ROOT=$(dirname "$SCRIPT_PHYSICAL_PATH") 

#--当/home/abner/abner2 是 实际路径/mnt/disk2/abner/ 的软链接时，Repo_ROOT应该是 软链接目录下的路径，
#--否则，cmake 在使用CMAKE_PREFIX_PATH查找 xxxConfig.cmake 时有歧义、混淆，从而编译失败。
#--所以这里强制指定为：
Repo_ROOT=/mnt/d/gm/zdev/nv/osgearth0x
echo "Repo_ROOT=${Repo_ROOT}"

# 验证路径是否存在
if [ ! -d "$Repo_ROOT" ]; then
    echo "Error: Repo_ROOT does not exist: $Repo_ROOT"
    exit 1
fi
 
echo "============================================================="
isRebuild=true
# ------------
isFinished_build_zlib=false  
# isFinished_build_zstd=true
isFinished_build_openssl=false  
# isFinished_build_icu=true  
# isFinished_build_libidn2=true 
# isFinished_build_libpsl=true  
isFinished_build_curl=false   # false  
# isFinished_build_jpeg9f=true  
isFinished_build_libjpegTurbo=false   
isFinished_build_libpng=false    
# isFinished_build_xz=true  
isFinished_build_libtiff=false  
isFinished_build_freetype=false
isFinished_build_geos=false     # false
isFinished_build_sqlite=false
isFinished_build_proj=false   
# isFinished_build_libexpat=true  
isFinished_build_absl=false
isFinished_build_protobuf=false
isFinished_build_boost=false  
isFinished_build_gdal=false # v
isFinished_build_osg=false
isFinished_build_zip=false
isFinished_build_oearth=false
# ------------    
# ANDROID_NDK_ROOT ​​:早期 Android 工具链（如 ndk-build）和部分开源项目（如 OpenSSL）习惯使用此变量。
export ANDROID_NDK_ROOT=/home/abel/programs/android-ndk-r27d    
# ANDROID_NDK_HOME​ ​:后来 Android Studio 和 Gradle 更倾向于使用此变量。    
export ANDROID_NDK_HOME="${ANDROID_NDK_ROOT}"
# 确保 NDK 路径已设置（需要根据实际环境修改或通过环境变量传入）
if [ -z "${ANDROID_NDK_HOME}" -o ! -d "${ANDROID_NDK_HOME}"  ]; then
    echo "ERROR: ANDROID_NDK_HOME=${ANDROID_NDK_HOME} not exist!"
    exit 1001
fi
# CMAKE_SYSROOT=${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/sysroot
# 
# 设置 NDK 工具链路径（使用 LLVM 工具）
TOOLCHAIN=${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64
if [ ! -d "${TOOLCHAIN}"  ]; then
    echo "ERROR: TOOLCHAIN=${TOOLCHAIN} not exist!"
    exit 1001
fi
# 使用统一的 LLVM 工具替代传统工具
export AR=${TOOLCHAIN}/bin/llvm-ar
export AS=${TOOLCHAIN}/bin/llvm-as
export LD=${TOOLCHAIN}/bin/ld.lld
export RANLIB=${TOOLCHAIN}/bin/llvm-ranlib
export STRIP=${TOOLCHAIN}/bin/llvm-strip
# 
ANDRO_TOOLCHAIN_FILE=${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake
if [ ! -f "${ANDRO_TOOLCHAIN_FILE}"  ]; then
    echo "ERROR: ANDRO_TOOLCHAIN_FILE=${ANDRO_TOOLCHAIN_FILE} not exist!"
    exit 1001
fi

export PATH=${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH
export PATH=$PATH:$ANDROID_NDK_HOME

CMAKE_BUILD_TYPE=Debug #RelWithDebInfo
CMAKE_MAKE_PROGRAM=${ANDROID_NDK_HOME}/prebuilt/linux-x86_64/bin/make
if [ ! -f "${CMAKE_MAKE_PROGRAM}"  ]; then
    echo "ERROR: CMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM} not exist!"
    exit 1001
fi

# CMAKE_C_COMPILER=/usr/bin/gcc   # /usr/bin/musl-gcc   # /usr/bin/clang  # 
# CMAKE_CXX_COMPILER=/usr/bin/g++ # /usr/bin/musl-gcc # /usr/bin/clang++  #   


# **************************************************************************
# rm -fr ./build_by_sh   
BuildDir_andro=${Repo_ROOT}/build_by_sh/android

INSTALL_PREFIX_andro=${BuildDir_andro}/install
mkdir -p ${INSTALL_PREFIX_andro} 

# 定义需要编译的 Android ABI 列表
# ABIS=("arm64-v8a"  "x86_64"   "armeabi-v7a"  "x86" )
# CMAKE_ANDROID_ARCH_ABI="x86_64" 
ABIS=("arm64-v8a")  
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
    # ---- check params
    echo "aSubSrcDir=$aSubSrcDir"
    echo "aSubBuildDir=$aSubBuildDir"
    echo "aSubInstallDir=$aSubInstallDir;;aIsRebuild=$aIsRebuild" 
    if  [ -z "$aSubSrcDir" ] || [ ! -d "${aSubSrcDir}" ]; then
        echo "aSubSrcDir=${aSubSrcDir}  NOT exist!"
        exit 1001
    fi    
 
    if  [ -z "$aSubBuildDir" ]; then
        echo "aSubBuildDir=${aSubBuildDir}  is empty string!"
        exit 1002
    fi   

    if  [ -z "$aSubInstallDir" ]; then
        echo "aSubInstallDir=${aSubInstallDir}  is empty string!"
        exit 1002
    fi     

    # ----  if aIsRebuild is true,del old folders
    if [ "${aIsRebuild}" = "true" ]; then 
        # echo "${aSubSrcDir} aIsRebuild ==true..1"          
        rm -fr ${aSubBuildDir}          
        rm -fr ${aSubInstallDir}
        echo "${aSubSrcDir} aIsRebuild ==true..2"       
    else
        rm -fr ${aSubInstallDir}
        echo "${aSubSrcDir} aIsRebuild ==false"      
    fi   

    # ---- 不管是否 Rebuild，都创建 aSubBuildDir 和 aSubInstallDir，
    #      因为configure 不会创建 aSubBuildDir 
    if [ ! -d "${aSubBuildDir}" ]; then
        mkdir -p ${aSubBuildDir} || { 
            echo "mkdir -p ${aSubBuildDir}失败！"
            exit 1002
        } 
    fi    

     
    if  [ ! -d "${aSubInstallDir}" ]; then
        mkdir -p ${aSubInstallDir} || { 
            echo "mkdir -p ${aSubInstallDir}失败！"
            exit 1002
        } 
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
    
        # (1)remark: ${INSTALL_PREFIX_zlib}/lib/cmake/zlib/ZLIBConfig.cmake只提供了 ZLIB::ZLIBstatic
        #        /usr/share/cmake-3.28/Modules/FindZLIB.cmake 提供了 ZLIB::ZLIB
        #       所以作为workaround，这里使用/usr/share/cmake-3.28/Modules/FindZLIB.cmake        
        #--
        #----备份 zlib源码编译后产生的ZLIBConfig.cmake
        INSTALL_cmakeDir_zlib=${INSTALL_PREFIX_zlib}/lib/cmake/zlib/
        mv  ${INSTALL_cmakeDir_zlib}/ZLIB-static.cmake         ${INSTALL_cmakeDir_zlib}/ZLIB-static_bk.cmake
        mv  ${INSTALL_cmakeDir_zlib}/ZLIBConfig.cmake          ${INSTALL_cmakeDir_zlib}/ZLIBConfig_bk.cmake
        mv  ${INSTALL_cmakeDir_zlib}/ZLIBConfigVersion.cmake   ${INSTALL_cmakeDir_zlib}/ZLIBConfigVersion_bk.cmake
        #---- 把 FindZLIB.cmake 放到 ${INSTALL_PREFIX_zlib}/lib/cmake/
        # mkdir -p ${INSTALL_cmakeDir_zlib}
        # cp ${Repo_ROOT}/cmake/FindZLIB.cmake  ${INSTALL_cmakeDir_zlib}
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
                -DCURL_BROTLI=OFF  -DCURL_USE_LIBSSH2=OFF  \
                -DUSE_LIBIDN2=OFF  -DUSE_NGHTTP2=OFF        \
                -DCURL_ZLIB=ON     -DZLIB_USE_STATIC_LIBS=ON \
                -DCURL_USE_LIBPSL=OFF   -DCURL_ZSTD=OFF \
                -DCURL_USE_OPENSSL=ON  \
                -DBUILD_DOCS=OFF   -DCMAKE_INSTALL_DOCDIR=OFF \
                -DCURL_USE_PKGCONFIG=OFF \
                -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include \
                -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a   \
                -DOPENSSL_USE_STATIC_LIBS=ON                        \
                -DOPENSSL_ROOT_DIR=${INSTALL_PREFIX_openssl}         \
                -DOPENSSL_LIBRARIES=${INSTALL_PREFIX_openssl}/lib     \
                -DOPENSSL_SSL_LIBRARY=${INSTALL_PREFIX_openssl}/lib/libssl.a     \
                -DPENSSL_CRYPTO_LIBRARY=${INSTALL_PREFIX_openssl}/lib/libcrypto.a \
                -DOPENSSL_INCLUDE_DIR=${INSTALL_PREFIX_openssl}/include  


                # -DCMAKE_MODULE_PATH=${SrcDIR_lib}/cmake  # 优先使用项目内的 FindZLIB.cmake
 
                #  -DZLIB_ROOT=${INSTALL_PREFIX_zlib} \
                #  
                #     

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
            -DJPEG_INCLUDE_DIR=${INSTALL_PREFIX_jpegTb}/include \
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
                -DPNG_LIBRARY="${INSTALL_PREFIX_png}/lib/libpng.a"  \
                -DPNG_INCLUDE_DIR="${INSTALL_PREFIX_png}/include"    \
                -DPNG_PNG_INCLUDE_DIR="${INSTALL_PREFIX_png}/include" \
                -DPNG_INCLUDE_DIRS="${INSTALL_PREFIX_png}/include"     \
                -DPNG_LIBRARIES="${INSTALL_PREFIX_png}/lib/libpng.a"    \
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
            -DCMAKE_EXE_LINKER_FLAGS="-static  -fuse-ld=lld" \
            -DCMAKE_SHARED_LINKER_FLAGS="-static  -fuse-ld=lld" \
            -DCMAKE_MODULE_LINKER_FLAGS="-static  -fuse-ld=lld" \
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
    echo "========== building proj 4 Android ========== " &&  sleep 1 # && set -x

    SrcDIR_lib=${SrcDIR_3rd}/proj

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
        echo "For building proj: cmkPrefixPath=${cmkPrefixPath}" 

        # 在 proj/data/generate_proj_db.cmake中, 有execute_process(COMMAND "${EXE_SQLITE3}" "${PROJ_DB}"...)
        # 用 sqlite3 的二进制程序来生成 proj.db。 但是在x86_64的ubuntu系统里， arm64-v8a/bin/sqlite3 和
        #  armeabi-v7a/bin/sqlite3 都无法运行，所以这里特地指定 EXE_SQLITE3 为 x86_64/bin/sqlite3
        EXE_SQLITE3=${INSTALL_PREFIX_3rd}/sqlite/x86_64/bin/sqlite3

        #  CC=musl-gcc cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib}     
        cmake -S ${SrcDIR_lib}  -B ${BuildDIR_lib} --debug-find \
                "${cmakeCommonParams[@]}"   -DANDROID_ABI=${ABI} \
                -DCMAKE_PREFIX_PATH="${cmkPrefixPath}" \
                -DCMAKE_MODULE_PATH="${INSTALL_PREFIX_zlib}/lib/cmake/zlib" \
                -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_proj}  \
                -DBUILD_TESTING=OFF \
                -DBUILD_EXAMPLES=OFF \
                -DENABLE_CURL=ON  \
                -DENABLE_TIFF=OFF  \
                -DCMAKE_HAVE_PTHREAD_H=ON    \
                -DCMAKE_HAVE_LIBC_PTHREAD=ON \
                -DCMAKE_USE_PTHREADS_INIT=ON \
                -DSQLite3_DISABLE_DYNAMIC_EXTENSIONS=ON \
                -DCURL_DISABLE_ARES=ON  \
                -DZLIB_ROOT="${INSTALL_PREFIX_zlib}" \
                -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a  \
                -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include  \
                -DEXE_SQLITE3=${EXE_SQLITE3}  \
                -DSQLite3_LIBRARY=${INSTALL_PREFIX_sqlite}/lib/libsqlite3.a \
                -DSQLite3_INCLUDE_DIR=${INSTALL_PREFIX_sqlite}/include       \
                -DCURL_ROOT=${INSTALL_PREFIX_curl}                   \
                -DCURL_LIBRARY=${INSTALL_PREFIX_curl}/lib/libcurl-d.a \
                -DCURL_INCLUDE_DIR=${INSTALL_PREFIX_curl}/include      \
                -DOPENSSL_DIR=${INSTALL_PREFIX_openssl}/lib/cmake/OpenSSL/ \
                -DOPENSSL_ROOT_DIR=${INSTALL_PREFIX_openssl} \
                -DOPENSSL_INCLUDE_DIR=${INSTALL_PREFIX_openssl}/include \
                -DOPENSSL_SSL_LIBRARY=${INSTALL_PREFIX_openssl}/lib/libssl.a \
                -DOPENSSL_CRYPTO_LIBRARY=${INSTALL_PREFIX_openssl}/lib/libcrypto.a \                              

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
    echo "========== finished building proj 4 Android ========== "  # && set -x
fi

 
# -------------------------------------------------
# abseil-cpp  
# -------------------------------------------------
if [ "${isFinished_build_absl}" != "true" ] ; then 
    echo "========== building abseil-cpp 4 Android ========== " &&  sleep 5

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
    echo "========== finished building abseil-cpp 4 Android ========== " &&  sleep 2
fi     

# -------------------------------------------------
# protobuf  
# -------------------------------------------------
if [ "${isFinished_build_protobuf}" != "true" ] ; then 
    echo "========== building protobuf 4 Android ========== " &&  sleep 5

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
      
    echo "========== finished building protobuf 4 Android ========== " &&  sleep 1
fi    


# -------------------------------------------------
# boost  
# -------------------------------------------------
if [ "${isFinished_build_boost}" != "true" ] ; then 
    echo "========== building boost 4 Android========== " &&  sleep 1 # && set -x


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
    echo "========== Finished Building boost 4 Android========="  # && set +x
fi


# -------------------------------------------------
# gdal , see 3rd/gdal/fuzzers/build.sh
# -------------------------------------------------
if [ "${isFinished_build_gdal}" != "true" ] ; then 
    echo "========== building gdal 4 Android========== " &&  sleep 1 #  && set -x

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
                -DPNG_INCLUDE_DIR=${INSTALL_PREFIX_png}/include      \
                -DPNG_PNG_INCLUDE_DIR="${INSTALL_PREFIX_png}/include" \
                -DPNG_LIBRARY=${INSTALL_PREFIX_png}/lib/libpng.a       \
                -DJPEG_INCLUDE_DIR=${INSTALL_PREFIX_jpegTb}/include \
                -DJPEG_LIBRARY=${INSTALL_PREFIX_jpegTb}/lib/libjpeg.a \
                -DSQLite3_HAS_COLUMN_METADATA=ON \
                -DSQLite3_HAS_MUTEX_ALLOC=ON      \
                -DSQLite3_HAS_RTREE=ON             \
                -DSQLITE3_LIBRARY=${INSTALL_PREFIX_sqlite}/lib/libsqlite3.a \
                -DOPENSSL_DIR=${INSTALL_PREFIX_openssl}/lib/cmake/OpenSSL/ \
                -DOPENSSL_ROOT_DIR=${INSTALL_PREFIX_openssl} \
                -DOPENSSL_INCLUDE_DIR=${INSTALL_PREFIX_openssl}/include \
                -DOPENSSL_SSL_LIBRARY=${INSTALL_PREFIX_openssl}/lib/libssl.a \
                -DOPENSSL_CRYPTO_LIBRARY=${INSTALL_PREFIX_openssl}/lib/libcrypto.a \
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
    echo "========== finished building gdal 4 Android ========== " # && set +x
fi    



# -------------------------------------------------
# osg 
# -------------------------------------------------
if [ "${isFinished_build_osg}" != "true" ] ; then 
    echo "========== building osg 4 Android========== " &&  sleep 1

    SrcDIR_lib=${SrcDIR_3rd}/osg

    for ABI in "${ABIS[@]}"; do
        echo "++++++++++++ Building osg for ${ABI} ++++++++++++"
        
        BuildDIR_lib=${BuildDir_3rd}/osg/$ABI
        INSTALL_PREFIX_osg=${INSTALL_PREFIX_3rd}/osg/$ABI
        prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_osg} ${isRebuild}     
 
        # _LINKER_FLAGS="-L${lib_dir} -lcurl -ltiff -ljpeg -lsqlite3 -lprotobuf -lpng -llzma -lz"
        # _LINKER_FLAGS="${_LINKER_FLAGS} -L${lib64_dir} -lssl -lcrypto" 
        # 
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
        INSTALL_PREFIX_freetype=${INSTALL_PREFIX_3rd}/freetype/$ABI    
        INSTALL_PREFIX_gdal=${INSTALL_PREFIX_3rd}/gdal/$ABI     
        INSTALL_PREFIX_boost=${INSTALL_PREFIX_3rd}/boost/$ABI 

        cmkPrefixPath_Arr=(
            "${INSTALL_PREFIX_zlib}"     "${INSTALL_PREFIX_png}" 
            "${INSTALL_PREFIX_absl}"     "${INSTALL_PREFIX_protobuf}"  
            "${INSTALL_PREFIX_jpegTb}"   "${INSTALL_PREFIX_openssl}" 
            "${INSTALL_PREFIX_tiff}"     "${INSTALL_PREFIX_geos}"   
            "${INSTALL_PREFIX_proj}"     "${INSTALL_PREFIX_curl}"   
            "${INSTALL_PREFIX_sqlite}"   "${INSTALL_PREFIX_freetype}"
            "${INSTALL_PREFIX_gdal}"     "${INSTALL_PREFIX_boost}"
            )
        # 使用;号连接数组元素.
        cmkPrefixPath=$(IFS=";"; echo "${cmkPrefixPath_Arr[*]}")
        echo "......For building osg: cmkPrefixPath=${cmkPrefixPath}"   

        # <<osg的间接依赖库>>
        # 依赖关系：osg -->gdal-->curl-->libpsl， 所以OSG 的 CMake 配置需要确保在
        # target_link_libraries 时包含所有 cURL 所依赖的库(osg的间接依赖库)。
        # 这通常在 CMakeLists.txt中通过 find_package(CURL)返回的导入型目标CURL::libCurl获得或直接在
        # CMake -S -B命令中加 -DCMAKE_EXE_LINKER_FLAGS或CMAKE_SHARED_LINKER_FLAGS来添加缺失的库。​ 
        # 
        echo "gg==========_exeLinkerFlags=${_exeLinkerFlags}" 
        _curlLibs="${INSTALL_PREFIX_curl}/lib/libcurl-d.a;"
        _curlLibs="${_curlLibs} ${INSTALL_PREFIX_openssl}/lib/libssl.a;"
        _curlLibs="${_curlLibs} ${INSTALL_PREFIX_openssl}/lib/libcrypto.a;"
        _curlLibs="${_curlLibs} ${INSTALL_PREFIX_zlib}/lib/libz.a"
        echo "gg==========_curlLibs=${_curlLibs}" 


        osgModulePath_arr=(
            "${INSTALL_PREFIX_zlib}/lib/cmake/zlib"
            "${INSTALL_PREFIX_jpegTb}/lib/cmake/libjpeg-turbo"
            "${INSTALL_PREFIX_openssl}/lib/cmake/OpenSSL"
            "${INSTALL_PREFIX_gdal}/lib/cmake/gdal" 
        )
        # 使用;号连接数组元素.
        # IFS是Shell中的“内部字段分隔符”（Internal Field Separator），默认值包含空格、制表符和换行符
        osg_MODULE_PATH=$(IFS=";"; echo "${osgModulePath_arr[*]}")
        echo "gg==========osg_MODULE_PATH=${osg_MODULE_PATH}" 
    

        echo "=== cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib}  --debug-find ......"
        # -DCMAKE_C_FLAGS="-march=armv7-a -mfpu=neon -DOSG_GLES3_AVAILABLE=1" \
        # -DCMAKE_CXX_FLAGS="-std=c++14 -march=armv7-a -mfpu=neon -DOSG_GLES3_AVAILABLE=1" \
        TARGET_HOST=$(get_targetHost_byABILvl "${ABI}")
        OPENGL_gl_LIBRARY=${CMAKE_SYSROOT}/usr/lib/${TARGET_HOST}/${ABI_LEVEL}/libGLESv3.so
 
        # --debug-find    --debug-output 
        cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib}  --debug-find  \
            "${cmakeCommonParams[@]}"  -DANDROID_ABI=${ABI}       \
            -DCMAKE_FIND_LIBRARY_SUFFIXES=".a"         \
            -DCMAKE_PREFIX_PATH="${cmk_prefixPath}"     \
            -DCMAKE_MODULE_PATH="${osg_MODULE_PATH}"     \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_osg}  \
            -DCMAKE_C_FLAGS="-fPIC"             \
            -DCMAKE_CXX_FLAGS="-fPIC -std=c++14" \
            -DBUILD_SHARED_LIBS=OFF  \
        -DCMAKE_DEBUG_POSTFIX=""   \
        -DDYNAMIC_OPENTHREADS=OFF   \
        -DDYNAMIC_OPENSCENEGRAPH=OFF \
        -DANDROID=ON                \
        -DOSG_GL1_AVAILABLE=OFF \
        -DOSG_GL2_AVAILABLE=OFF \
        -DOSG_GL3_AVAILABLE=OFF \
        -DOSG_GLES1_AVAILABLE=OFF \
        -DOSG_GLES2_AVAILABLE=OFF \
        -DOSG_GLES3_AVAILABLE=ON  \
        -DOSG_GL_LIBRARY_STATIC=OFF \
        -DOSG_GL_DISPLAYLISTS_AVAILABLE=OFF \
        -DOSG_GL_MATRICES_AVAILABLE=OFF \
        -DOSG_GL_VERTEX_FUNCS_AVAILABLE=OFF \
        -DOSG_GL_VERTEX_ARRAY_FUNCS_AVAILABLE=OFF \
        -DOSG_GL_FIXED_FUNCTION_AVAILABLE=OFF \
        -DOPENGL_PROFILE="GLES3" \
        -DOPENGL_gl_LIBRARY=${OPENGL_gl_LIBRARY} \
        -DOSG_FIND_3RD_PARTY_DEPS=OFF  \
        -DZLIB_USE_STATIC_LIBS=ON \
        -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include \
        -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a \
        -DZLIB_LIBRARIES="${INSTALL_PREFIX_zlib}/lib/libz.a" \
        -DJPEG_INCLUDE_DIR=${INSTALL_PREFIX_jpegTb}/include \
        -DJPEG_LIBRARY=${INSTALL_PREFIX_jpegTb}/lib/libjpeg.a \
        -DJPEG_LIBRARIES=${INSTALL_PREFIX_jpegTb}/lib/libjpeg.a \
        -DPNG_INCLUDE_DIR=${INSTALL_PREFIX_png}/include      \
        -DPNG_PNG_INCLUDE_DIR="${INSTALL_PREFIX_png}/include" \
        -DPNG_LIBRARY=${INSTALL_PREFIX_png}/lib/libpng.a       \
        -DPNG_LIBRARIES=${INSTALL_PREFIX_png}/lib/libpng.a      \
        -DOpenSSL_ROOT="${INSTALL_PREFIX_openssl}" \
        -DOpenSSL_USE_STATIC_LIBS=ON                \
        -DTIFF_INCLUDE_DIR=${INSTALL_PREFIX_tiff}/include   \
        -DTIFF_LIBRARY=${INSTALL_PREFIX_tiff}/lib/libtiff.a  \
        -DTIFF_LIBRARIES=${INSTALL_PREFIX_tiff}/lib/libtiff.a \
        -DFREETYPE_DIR=${INSTALL_PREFIX_freetype}/lib/freetype              \
        -DFREETYPE_INCLUDE_DIRS=${INSTALL_PREFIX_freetype}/include/freetype2 \
        -DFREETYPE_LIBRARY=${INSTALL_PREFIX_freetype}/lib/libfreetyped.a      \
        -DFREETYPE_LIBRARIES=${INSTALL_PREFIX_freetype}/lib/libfreetyped.a     \
        -DCURL_DIR="${INSTALL_PREFIX_curl}/lib/cmake/CURL" \
        -DCURL_LIBRARY=CURL::libcurl   \
        -DCURL_LIBRARIES="${_curlLibs}" \
        -DGDAL_DIR=${INSTALL_PREFIX_gdal}                  \
        -DGDAL_INCLUDE_DIR=${INSTALL_PREFIX_gdal}/include   \
        -DGDAL_LIBRARY=${INSTALL_PREFIX_gdal}/lib/libgdal.a  \
        -DNO_DEFAULT_PATH=ON \
        -DCMAKE_EXE_LINKER_FLAGS="-llog -landroid" 

        # -DJPEG_DIR= \
        # -DOpenSSL_DIR="${INSTALL_PREFIX_openssl}/lib/cmake/OpenSSL"  \
        # -DCMAKE_LIBRARY_PATH="/usr/lib/gcc/x86_64-linux-gnu/13" \
        # -DCMAKE_EXE_LINKER_FLAGS=" \
        #     -Wl,--whole-archive \
        #     /usr/lib/gcc/x86_64-linux-gnu/13/libstdc++.a \
        #     -Wl,--no-whole-archive \
        #     -Wl,-Bdynamic -lm -lc -lGL -lGLU -ldl \
        #     -Wl,--no-as-needed -lX11 -lXext"
        
 
        # (1)关于-DCURL_LIBRARY="CURL::libcurl" ：
        #  -DCURL_LIBRARY="${INSTALL_PREFIX_curl}/lib/libcurl-d.a"  ## 根据一般的规则，ok
        #  -DCURL_LIBRARIES="CURL::libcurl" ## 根据一般的规则，ok
        #  -DCURL_LIBRARY="CURL::libcurl" ##  特定于osg项目，是ok的，因为osg/src/osgPlugins/curl/CMakeLists.txt中
        #     ## SET(TARGET_LIBRARIES_VARS   CURL_LIBRARY     ZLIB_LIBRARIES)用的是CURL_LIBRARY而不是CURL_LIBRARIES
        
        # (2)Glibc 的某些函数（如网络相关）在静态链接时需要动态库支持,使用libc.a和libm.a会导致 collect2: error: ld returned 1 exit status
        #     
        # (3) -DZLIB_ROOT=${INSTALL_PREFIX_zlib} \
        # (4) osg/src/osgPlugins/png/CMakeLists.txt中强制 SET(TARGET_LIBRARIES_VARS PNG_LIBRARY ZLIB_LIBRARIES )
        #    而 lib/cmake/PNG/PNGConfig.cmake 中 没提供PNG_LIBRARY
        #    所以 cmake -S -B 必须添加 -DPNG_LIBRARY=${INSTALL_PREFIX_png}/lib/libpng.a
        # (5)针对cmakeCommonParams，特化设置：
        #    -DEGL_LIBRARY=  -DEGL_INCLUDE_DIR=  -DEGL_LIBRARY= 
        #    -DOPENGL_EGL_INCLUDE_DIR=  -DOPENGL_INCLUDE_DIR=  -DOPENGL_gl_LIBRARY=
        #    -DPKG_CONFIG_EXECUTABLE= 
        # 
        # -DEGL_LIBRARY=/usr/lib/x86_64-linux-gnu/libEGL.so \
        # -DEGL_INCLUDE_DIR=/usr/include/EGL                 \
        # -DEGL_LIBRARY=/usr/lib/x86_64-linux-gnu/libEGL.so   \
        # -DOPENGL_EGL_INCLUDE_DIR=/usr/include/EGL            \
        # -DOPENGL_INCLUDE_DIR=/usr/include/GL                  \
        # -DOPENGL_gl_LIBRARY=/usr/lib/x86_64-linux-gnu/libGL.so \
        # -DPKG_CONFIG_EXECUTABLE=/usr/bin/pkg-config             \

        # -DBoost_ROOT=${INSTALL_PREFIX_boost}  \ ## 现代CMake（>=3.12）官方标准
        # -DBOOST_ROOT=${INSTALL_PREFIX_boost}  \ ## 旧版兼容（FindBoost.cmake传统方式）
        
        # -DGDAL_LIBRARIES=${INSTALL_PREFIX_gdal}/lib/libgdal.a  \ 
        # -DCMAKE_STATIC_LINKER_FLAGS=${_LINKER_FLAGS}  


 
        echo "=== cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v"
        cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v
        
        echo "=== cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}"
        cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  
        echo "++++++++++++Finished building osg for ${ABI} ++++++++++++"
    done       
    echo "========== finished building osg 4 Android ========== " &&  sleep 1 

fi    


# -------------------------------------------------
# libzip 
# ------------------------------------------------- 
if [ "${isFinished_build_zip}" != "true" ]; then 
    echo "========== building libzip 4 Android========== " &&  sleep 3
    SrcDIR_lib=${SrcDIR_3rd}/libzip 

    for ABI in "${ABIS[@]}"; do
        echo "++++++++++++ Building libzip for ${ABI} ++++++++++++"
        
        BuildDIR_lib=${BuildDir_3rd}/libzip/$ABI
        INSTALL_PREFIX_zip=${INSTALL_PREFIX_3rd}/libzip/$ABI
        prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_zip} ${isRebuild}     
 
        # ------
        INSTALL_PREFIX_zlib=${INSTALL_PREFIX_3rd}/zlib/$ABI 

        # "${INSTALL_PREFIX_xz}" "${INSTALL_PREFIX_zstd}" "${INSTALL_PREFIX_openssl}" 
        cmk_prefixPath="${INSTALL_PREFIX_zlib}"  
        echo "==========cmk_prefixPath=${cmk_prefixPath}"   

        # ------
        cmake -S ${SrcDIR_lib}  -B ${BuildDIR_lib} --debug-find \
                "${cmakeCommonParams[@]}"  -DANDROID_ABI=${ABI}  \
                -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
                -DCMAKE_PREFIX_PATH="${cmk_prefixPath}" \
                -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_zip}  \
                -DBUILD_SHARED_LIBS=OFF   \
            -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a   \
            -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include \
            -DENABLE_COMMONCRYPTO=OFF \
            -DENABLE_GNUTLS=OFF \
            -DENABLE_MBEDTLS=OFF \
            -DENABLE_OPENSSL=OFF \
            -DENABLE_LZMA=OFF \
            -DENABLE_ZSTD=OFF \
            -DBUILD_TOOLS=OFF \
            -DBUILD_EXAMPLES=OFF

            # (1)libzip cmakelists.txt 存在error:"docs/libzip-cmakelists-err.png",导致lzma没起作用，
            #  所以这里 设置-DENABLE_LZMA=OFF 
            # (2)类似原因，zstd没有提供ZSTD_FOUND,而libzip-config.cmake.in中有 set(ENABLE_ZSTD "@ZSTD_FOUND@")，
            #    所以这里-DENABLE_ZSTD=OFF 
            # 
            # -Dzstd_LIBRARY=${INSTALL_PREFIX_zstd}/lib/libzstd.a   \
            # -Dzstd_INCLUDE_DIR=${INSTALL_PREFIX_zstd}/include \
        cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v 

        cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE} 
        echo "++++++++++++Finished building libzip for ${ABI} ++++++++++++"
    done           
    echo "========== finished building libzip 4 Android ========== " &&  sleep 2
fi
 

# -------------------------------------------------
# osgearth 
# -------------------------------------------------
if [ "${isFinished_build_oearth}" != "true" ] ; then 
    echo "========== building osgearth 4 Android========== " &&  sleep 1 # && set -x

    SrcDIR_lib=${SrcDIR_3rd}/osgearth

    for ABI in "${ABIS[@]}"; do
        echo "++++++++++++ Building osgearth for ${ABI} ++++++++++++"
        
        BuildDIR_lib=${BuildDir_3rd}/osgearth/$ABI
        INSTALL_PREFIX_osgearth=${INSTALL_PREFIX_3rd}/osgearth/$ABI 
        echo "gg====         SrcDIR_lib=${SrcDIR_lib}" 
        echo "gg====       BuildDIR_lib=${BuildDIR_lib}" 
        echo "gg==== INSTALL_PREFIX_osg=${INSTALL_PREFIX_osgearth}" 
        prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_osgearth} ${isRebuild}  
 
        # ------
        INSTALL_PREFIX_zlib=${INSTALL_PREFIX_3rd}/zlib/$ABI 
        INSTALL_PREFIX_zip=${INSTALL_PREFIX_3rd}/libzip/$ABI
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
        INSTALL_PREFIX_freetype=${INSTALL_PREFIX_3rd}/freetype/$ABI    
        INSTALL_PREFIX_gdal=${INSTALL_PREFIX_3rd}/gdal/$ABI     
        INSTALL_PREFIX_boost=${INSTALL_PREFIX_3rd}/boost/$ABI 
        INSTALL_PREFIX_osg=${INSTALL_PREFIX_3rd}/osg/$ABI

        cmkPrefixPath_Arr=( "${INSTALL_PREFIX_zlib}"
                "${INSTALL_PREFIX_zip}"      "${INSTALL_PREFIX_png}"   
                "${INSTALL_PREFIX_absl}"     "${INSTALL_PREFIX_jpegTb}"   
                "${INSTALL_PREFIX_protobuf}" "${INSTALL_PREFIX_openssl}"      
                "${INSTALL_PREFIX_tiff}"     "${INSTALL_PREFIX_geos}"         
                "${INSTALL_PREFIX_proj}"         
                "${INSTALL_PREFIX_freetype}" "${INSTALL_PREFIX_curl}"   
                "${INSTALL_PREFIX_sqlite}"   "${INSTALL_PREFIX_gdal}"   
                "${INSTALL_PREFIX_boost}"    "${INSTALL_PREFIX_osg}" 
                )
        cmkPrefixPath=$(IFS=";"; echo "${cmkPrefixPath_Arr[*]}")
        echo "......For building oearth: cmkPrefixPath=${cmkPrefixPath}"    
        # ------
        export PKG_CONFIG_PATH="${INSTALL_PREFIX_osg}/lib/pkgconfig:$PKG_CONFIG_PATH"
        # ------
        osgearth_MODULE_PATH="${INSTALL_PREFIX_zlib}/lib/cmake/zlib"
        osgearth_MODULE_PATH="${osgearth_MODULE_PATH};${INSTALL_PREFIX_gdal}/lib/cmake/gdal/packages/"

        # ------
        cmakeParams_osgearth=(  
        "-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH" # BOTH：先查根路径，再查系统路径    
        "-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH"  
        # "-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER"
        # 是否访问 /usr/include/、/usr/lib/ 等 系统路径   
        "-DCMAKE_FIND_USE_CMAKE_SYSTEM_PATH=ON"
        # 是否访问PATH\LD_LIBRARY_PATH等环境变量
        "-DCMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH=OFF"  
        )
        # "${cmakeParams_osgearth[@]}"

        # ------
        # 2. 清理环境
        unset LD_LIBRARY_PATH
        unset LIBRARY_PATH
        
 
        TARGET_HOST=$(get_targetHost_byABILvl "${ABI}")
        OPENGL_gl_LIBRARY=${CMAKE_SYSROOT}/usr/lib/${TARGET_HOST}/${ABI_LEVEL}/libGLESv3.so
        OPENGL_opengl_LIBRARY=${OPENGL_gl_LIBRARY} 
        OPENGL_EGL_LIBRARY=${CMAKE_SYSROOT}/usr/lib/${TARGET_HOST}/${ABI_LEVEL}/libEGL.so
        OPENGL_GLES3_INCLUDE_DIR=${CMAKE_SYSROOT}/usr/include/GLES3


        # --debug-find    --debug-output 
        cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib}  --debug-find  \
                "${cmakeCommonParams[@]}" -DANDROID_ABI=${ABI}  \
                -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
                -DCMAKE_PREFIX_PATH="${cmkPrefixPath}"           \
                -DCMAKE_MODULE_PATH=${osgearth_MODULE_PATH}       \
                -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_osgearth}  \
                -DCMAKE_C_FLAGS="-fPIC -DGLES32=1 -DANDROID=1 -DGL_GLEXT_PROTOTYPES=1 -U GDAL_DEBUG -DOSGEARTH_LIBRARY=1"   \
                -DCMAKE_CXX_FLAGS="-fPIC -DGLES32=1 -DANDROID=1 -DGL_GLEXT_PROTOTYPES=1 -U GDAL_DEBUG -DOSGEARTH_LIBRARY=1"  \
                -DBUILD_SHARED_LIBS=OFF   \
            -DNRL_STATIC_LIBRARIES=ON  -DOSGEARTH_BUILD_SHARED_LIBS=OFF \
            -DCMAKE_SKIP_RPATH=ON  \
            -DANDROID=ON            \
            -DDYNAMIC_OPENTHREADS=OFF  -DDYNAMIC_OPENSCENEGRAPH=OFF \
            -DOSGEARTH_ENABLE_FASTDXT=OFF \
            -DOSGEARTH_BUILD_TOOLS=OFF       \
            -DOSGEARTH_BUILD_EXAMPLES=OFF     \
            -DOSGEARTH_BUILD_IMGUI_NODEKIT=OFF \
            -DOSG_GL1_AVAILABLE=OFF \
            -DOSG_GL2_AVAILABLE=OFF  \
            -DOSG_GL3_AVAILABLE=OFF   \
            -DOSG_GLES1_AVAILABLE=OFF  \
            -DOSG_GLES2_AVAILABLE=OFF   \
            -DOSG_GLES3_AVAILABLE=ON     \
            -DOSG_GL_LIBRARY_STATIC=OFF   \
            -DOSG_GL_DISPLAYLISTS_AVAILABLE=OFF    \
            -DOSG_GL_MATRICES_AVAILABLE=OFF         \
            -DOSG_GL_VERTEX_FUNCS_AVAILABLE=OFF      \
            -DOSG_GL_VERTEX_ARRAY_FUNCS_AVAILABLE=OFF \
            -DOSG_GL_FIXED_FUNCTION_AVAILABLE=OFF      \
            -DOPENGL_PROFILE="GLES3"                    \
            -DOPENGL_glx_LIBRARY=NOTFOUND              \
            -DOPENGL_opengl_LIBRARY=${OPENGL_opengl_LIBRARY} \
            -DOPENGL_EGL_LIBRARY=${OPENGL_EGL_LIBRARY} \
            -DOPENGL_gl_LIBRARY=${OPENGL_gl_LIBRARY}    \
            -DOPENGL_gles3_LIBRARY=${OPENGL_gl_LIBRARY}  \
            -DOPENGL_INCLUDE_DIR=${OPENGL_GLES3_INCLUDE_DIR}      \
            -DOPENGL_GLES3_INCLUDE_DIR=${OPENGL_GLES3_INCLUDE_DIR} \
            -DOSG_LIBRARY_STATIC=ON \
            -DPKG_CONFIG_EXECUTABLE=/usr/bin/pkg-config \
            -DOpenSceneGraph_FIND_QUIETLY=OFF  \
            -DOSG_DIR=${INSTALL_PREFIX_osg}     \
            -DOPENSCENEGRAPH_INCLUDE_DIR=${INSTALL_PREFIX_osg}/include \
            -DOPENTHREADS_INCLUDE_DIR=${INSTALL_PREFIX_osg}/include \
            -DZLIB_ROOT_DIR="${INSTALL_PREFIX_zlib}"         \
            -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include \
            -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a   \
            -DPNG_INCLUDE_DIR=${INSTALL_PREFIX_png}/include/     \
            -DPNG_PNG_INCLUDE_DIR="${INSTALL_PREFIX_png}/include" \
            -DPNG_LIBRARY=${INSTALL_PREFIX_png}/lib/libpng.a       \
            -DJPEG_INCLUDE_DIR=${INSTALL_PREFIX_jpegTb}/include  \
            -DJPEG_LIBRARY=${INSTALL_PREFIX_jpegTb}/lib/libjpeg.a \
            -DTIFF_INCLUDE_DIR=${INSTALL_PREFIX_tiff}/include  \
            -DTIFF_LIBRARY=${INSTALL_PREFIX_tiff}/lib/libtiff.a \
            -DFREETYPE_ROOT=${INSTALL_PREFIX_freetype}                    \
            -DFREETYPE_INCLUDE_DIR=${INSTALL_PREFIX_freetype}/include      \
            -DFREETYPE_LIBRARY=${INSTALL_PREFIX_freetype}/lib/libfreetype.a \
            -DCURL_ROOT=${INSTALL_PREFIX_curl}                  \
            -DCURL_INCLUDE_DIR=${INSTALL_PREFIX_curl}/include    \
            -DCURL_LIBRARY=${INSTALL_PREFIX_curl}/lib/libcurl-d.a \
            -DSQLite3_INCLUDE_DIR=${INSTALL_PREFIX_sqlite}/include      \
            -DSQLite3_LIBRARY=${INSTALL_PREFIX_sqlite}/lib/libsqlite3.a  \
            -DSQLite3_LIBRARIES=${INSTALL_PREFIX_sqlite}/lib/libsqlite3.a \
            -DGEOS_DIR=${INSTALL_PREFIX_geos}                   \
            -DGEOS_INCLUDE_DIR=${INSTALL_PREFIX_geos}/include    \
            -DGEOS_LIBRARY=${INSTALL_PREFIX_geos}/lib/libgeos_c.a \
            -DPROJ_INCLUDE_DIR=${INSTALL_PREFIX_proj}/include  \
            -DPROJ_LIBRARY=${INSTALL_PREFIX_proj}/lib/libproj.a \
            -DPROJ4_LIBRARY=${INSTALL_PREFIX_proj}/lib/libproj.a \
            -DGDAL_ROOT=${INSTALL_PREFIX_gdal}                \
            -DGDAL_INCLUDE_DIR=${INSTALL_PREFIX_gdal}/include  \
            -DGDAL_LIBRARY=${INSTALL_PREFIX_gdal}/lib/libgdal.a \
            -DOPENSSL_SSL_LIBRARY=${INSTALL_PREFIX_openssl}/lib/libssl.a     \
            -DSSL_EAY_RELEASE=${INSTALL_PREFIX_openssl}/lib/libssl.a          \
            -DOPENSSL_CRYPTO_LIBRARY=${INSTALL_PREFIX_openssl}/lib/libcrypto.a \
            -DLIB_EAY_RELEASE=""  \
            -DCMAKE_EXE_LINKER_FLAGS="-llog -landroid" 

        # (1)/usr/share/cmake-3.28/Modules/FindGLEW.cmake中需要用 ENV GLEW_ROOT。
        # (2)在 CMake 命令行中临时设置环境变量（一次性生效），格式为 
        #   GLEW_ROOT=/path/to/GLEW cmake ...  ，无需提前 export。如：
        #   GLEW_ROOT="/usr/lib/x86_64-linux-gnu/" cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib}\

            # -DGLEW_USE_STATIC_LIBS=OFF  \
            # -DCMAKE_EXE_LINKER_FLAGS=" \
            # -Wl,--whole-archive  -fvisibility=hidden   -Wl,--no-whole-archive   \
            # -Wl,-Bdynamic -lstdc++  -lGL -lGLU -ldl -lm -lc -lpthread -lrt     \
            # -Wl,--no-as-needed -lX11 -lXext "  
    

            # (0) osgearth 编译时发生 类型转换错误​​（invalid conversion from 'void*' to 'OGRLayerH'）,
            #     用-DCMAKE_C_FLAGS="-U GDAL_DEBUG" 解决

            # (1) osgearth ->GEOS::geos_c ; osgearth -> gdal -> GEOS::GEOS
            #   GEOS 自身的 install/geos/lib/cmake/GEOS/geos-config.cmake 生成 GEOS::geos 目标 ,
            #   GDAL 自带的 install/gdal/lib/cmake/gdal/packages/FindGEOS.cmake 生成 GEOS::GEOS 目标。
            #   osgearth 的cmakelists.txt中需要GEOS::geos_c，osgearth依赖gdal，而gdal需要GEOS::GEOS,因为
            #   gdal/lib/cmake/gdal/GDAL-targets.cmake  有
            # ```
            # set_target_properties(GDAL::GDAL PROPERTIES
            #     INTERFACE_COMPILE_DEFINITIONS "\$<\$<CONFIG:DEBUG>:GDAL_DEBUG>"
            #     INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include"
            #     INTERFACE_LINK_LIBRARIES "\$<LINK_ONLY:ZLIB::ZLIB>;。。。。。。。。。。。\$<LINK_ONLY:GEOS::GEOS>。。。。
            # ```
            # (2)remark: osgearth/src/osgEarth/CMakeLists.txt 
            # ```
            # OPTION(NRL_STATIC_LIBRARIES "Link osgEarth against static GDAL and cURL, including static OpenSSL, Proj4, JPEG, PNG, and TIFF." OFF)
            # if(NOT NRL_STATIC_LIBRARIES)
            # LINK_WITH_VARIABLES(${LIB_NAME} OSG_LIBRARY ... CURL_LIBRARY GDAL_LIBRARY OSGMANIPULATOR_LIBRARY)
            # else(NOT NRL_STATIC_LIBRARIES)
            # LINK_WITH_VARIABLES(${LIB_NAME} OSG_LIBRARY ... CURL_LIBRARY GDAL_LIBRARY OSGMANIPULATOR_LIBRARY 
            #                           SSL_EAY_RELEASE LIB_EAY_RELEASE 
            #                           TIFF_LIBRARY PROJ4_LIBRARY PNG_LIBRARY JPEG_LIBRARY)
            # endif(NOT NRL_STATIC_LIBRARIES)
            # ```
            # (3)
            # OSGDB_LIBRARY  OSGGA_LIBRARY OSGMANIPULATOR_LIBRARY OSGSHADOW_LIBRARY 
            # OSGSIM_LIBRARY OSGTEXT_LIBRARY OSGUTIL_LIBRARY 
            # OSGVIEWER_LIBRARY OSG_LIBRARY
        echo "oe....cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v" 
        cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v
        
        echo "oe....cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}" 
        cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}         
        echo "++++++++++++Finished building osgearth for ${ABI} ++++++++++++"
    done         
    echo "========== finished building osgearth 4 Android ========== "  # && set +x

fi    

 
# **************************************************************************
# **************************************************************************
#  src/
# ************************************************************************** 
SrcDIR_src=${Repo_ROOT}/src
  

# **************************************************************************
endTm=$(date +%Y/%m/%d--%H:%M:%S)
printf "${startTm}----${endTm}\n"    