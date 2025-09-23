#!/bin/bash
# **************************************************************************
# false  ;;;   ./mk4ubuntu.sh  >bu.txt 2>&1
echo "mk4ubuntu.sh: param 0=$0"

# 获取脚本的绝对路径（处理符号链接）
SCRIPT_PATH=$(readlink -f "$0")
echo "sh-path: $SCRIPT_PATH"

# 额外：获取脚本所在目录的绝对路径
# Repo_ROOT=$(dirname "$SCRIPT_PATH")
Repo_ROOT=/home/abner/abner2/zdev/nv/osgearth0x
echo "Repo_ROOT=${Repo_ROOT}"

 
echo "============================================================="
# **************************************************************************
isRebuild=true

# ------
isFinished_build_zlib=true
isFinished_build_zstd=true
isFinished_build_openssl=true  
# isFinished_build_icu=true  
# isFinished_build_libidn2=true 
isFinished_build_libpsl=true  
isFinished_build_curl=true   # false #big code
# isFinished_build_jpeg9f=true  
isFinished_build_libjpegTurbo=true  
isFinished_build_libpng=true 
isFinished_build_xz=true  
isFinished_build_libtiff=true 
isFinished_build_freetype=true  
isFinished_build_geos=true     
isFinished_build_sqlite=true  
isFinished_build_proj=true     #-- false #big code
isFinished_build_libexpat=true  
isFinished_build_absl=true
isFinished_build_protobuf=true
isFinished_build_boost=true
isFinished_build_gdal=true   #-- false #big code
isFinished_build_osg=true    # osg-a ..false  
isFinished_build_osgdll=true # osg-dll..false
isFinished_build_zip=true
isFinished_build_osgearth=false  # osgearth-a
isFinished_build_oearthdll=true  # osgearth-dll
# ------
CMAKE_BUILD_TYPE=Debug #RelWithDebInfo
CMAKE_MAKE_PROGRAM=/usr/bin/make
CMAKE_C_COMPILER=/usr/bin/gcc   # /usr/bin/musl-gcc   # /usr/bin/clang  # 
CMAKE_CXX_COMPILER=/usr/bin/g++ # /usr/bin/musl-gcc # /usr/bin/clang++  #   

# **************************************************************************
# rm -fr ./build_by_sh   
BuildDir_ubuntu=${Repo_ROOT}/build_by_sh/ubuntu

# INSTALL_PREFIX_root
INSTALL_PREFIX_ubt=${BuildDir_ubuntu}/install
mkdir -p ${INSTALL_PREFIX_ubt} 


cmakeCommonParams=(
  "-DCMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}"
  "-DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}"
  "-DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}"
  "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
  "-DPKG_CONFIG_EXECUTABLE=/usr/bin/pkg-config"
  "-DCMAKE_FIND_ROOT_PATH=${INSTALL_PREFIX_ubt}"
  "-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY"
  "-DCMAKE_FIND_PACKAGE_PREFER_CONFIG=ON"
  "-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY" # BOTH：先查根路径，再查系统路径    
  "-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY" # 头文件仍只查根路径 
  "-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER"
  # 是否访问 /usr/include/、/usr/lib/ 等 系统路径；；与 PREFIX_PATH 配合 
  "-DCMAKE_FIND_USE_CMAKE_SYSTEM_PATH=OFF"
  # 是否访问PATH\LD_LIBRARY_PATH等环境变量
  "-DCMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH=OFF" 
  "-DCMAKE_FIND_LIBRARY_SUFFIXES=.a"
  "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
  "-DBUILD_SHARED_LIBS=OFF"    
)
  #  -DCMAKE_C_FLAGS= "-fPIC"     
  #  -DCMAKE_CXX_FLAGS="-fPIC" 
echo "cmakeCommonParams=${cmakeCommonParams[@]}"
# **************************************************************************
# functions
prepareBuilding()
{
    local aSubSrcDir="$1"
    local aSubBuildDir="$2"
    local aSubInstallDir="$3"
    local aIsRebuild="$4"
    # echo "aSubSrcDir= $aSubSrcDir"
    # echo "aSubBuildDir=$aSubBuildDir"
    # echo "aSubInstallDir=$aSubInstallDir" 
    # echo "aIsRebuild=$aIsRebuild" 
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

# 检查并拼接路径
check_concat_paths()
{
    # echo "gg.....check_concat_paths():all params=$@"
    local finalPaths=""
    for path in "$@"; do
        if [ -n "${path}" ] && [ -d "${path}" ]; then
            finalPaths="${finalPaths};${path}"
        else 
            echo "Folder ${path}  NOT exist!"
            exit 1002
        fi     
    done
    finalPaths="${finalPaths#;}"  # 移除开头的分号
    # echo "gg......check_concat_paths(): finalPaths=${finalPaths}"


    # 验证路径非空
    if [ -z "${finalPaths}" ]; then
        echo "check_concat_paths(): fatal-error: concated finalPaths is empty "
        exit 1
    fi  

    echo "${finalPaths}"
}


check_concat_paths_1()
{
  # echo "gg.....check_concat_paths_1():all params=$@"
  local finalPaths=""
  for path in "$@"; do
      if [ -n "${path}" ] && [ -d "${path}" ]; then
        # ${cmk_prefixPath:+;} 表示：若 cmk_prefixPath 非空，则添加 ;，避免开头或结尾出现多余分号。
        finalPaths="${finalPaths}${finalPaths:+;}${path}"
      else
        cho "Folder ${path}  NOT exist!"
        exit 1002
      fi     
  done  

  # 验证路径非空
  if [ -z "${finalPaths}" ]; then
      echo "check_concat_paths_1(): fatal-error:concated finalPaths is empty"
      exit 1
  fi  
  echo "${finalPaths}"
}
# **************************************************************************
# **************************************************************************
#  3rd/
# **************************************************************************
SrcDIR_3rd=${Repo_ROOT}/3rd

# -------------------------------------------------
# zlib
# -------------------------------------------------
INSTALL_PREFIX_zlib=${INSTALL_PREFIX_ubt}/zlib

if [ "${isFinished_build_zlib}" != "true" ]; then 
    echo "========== building zlib 4 ubuntu========== " &&  sleep 1
    SrcDIR_lib=${SrcDIR_3rd}/zlib
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/zlib     
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_zlib} ${isRebuild} 
 
    #################################################################### 
    # remark: zlib的 CMakeLists.txt中 未通过 target_compile_definitions 显式指定 ZLIB_DEBUG 宏,
    #    可以用 CMAKE_C_FLAGS="-DZLIB_DEBUG=1" 指定 :
    # 编译时查看详细命令
    # cmake ... -DCMAKE_C_FLAGS="-fPIC -DZLIB_DEBUG=1"
    # make -C ${BuildDIR_lib} VERBOSE=1 
    # 若输出的编译命令中包含 -DZLIB_DEBUG=1，则说明宏已成功定义。
    #----------------------------------------------------        
    cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib} \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_zlib}  \
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}   \
            -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}    \
            -DCMAKE_C_FLAGS="-fPIC -DZLIB_DEBUG=1"  \
            -DCMAKE_EXE_LINKER_FLAGS="-static"   \
            -DBUILD_SHARED_LIBS=OFF     \
            -DCMAKE_EXPORT_PACKAGE_REGISTRY=ON \
            -DZLIB_BUILD_SHARED=OFF \
            -DZLIB_BUILD_STATIC=ON 
             
    cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v 

    cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}
 
    # (1)remark: ${INSTALL_PREFIX_zlib}/lib/cmake/zlib/ZLIBConfig.cmake只提供了 ZLIB::ZLIBstatic
    #        /usr/share/cmake-3.28/Modules/FindZLIB.cmake 提供了 ZLIB::ZLIB
    #       所以作为workaround，这里使用/usr/share/cmake-3.28/Modules/FindZLIB.cmake
    # 
    # --备份 zlib源码编译后产生的ZLIBConfig.cmake
    mv    ${INSTALL_PREFIX_zlib}/lib/cmake  ${INSTALL_PREFIX_zlib}/lib/cmake-bk
    mv    ${INSTALL_PREFIX_zlib}/lib/pkgconfig  ${INSTALL_PREFIX_zlib}/lib/pkgconfig-bk
    # -- 把 FindZLIB.cmake 放到 ${INSTALL_PREFIX_zlib}/lib/cmake/
    mkdir -p ${INSTALL_PREFIX_zlib}/lib/cmake/zlib
    cp ${Repo_ROOT}/cmake/FindZLIB.cmake  ${INSTALL_PREFIX_zlib}/lib/cmake/zlib
    #################################################################### 
    # cd ${BuildDIR_lib}
    # ####  --enable-debug  会自动添加 -DZLIB_DEBUG 宏）
    # CFLAGS="-fPIC" \
    # ${SrcDIR_3rd}/zlib/configure \
    #             --prefix=${INSTALL_PREFIX_zlib} \
    #             --enable-debug  --static
    # 
    # make  -j$(nproc)  
    # make install
    echo "========== finished building zlib 4 ubuntu ========== " &&  sleep 1
fi
 
 
# -------------------------------------------------
# zstd
# -------------------------------------------------
INSTALL_PREFIX_zstd=${INSTALL_PREFIX_ubt}/zstd

if [ "${isFinished_build_zstd}" != "true" ]; then 
    echo "========== building zstd 4 ubuntu========== " &&  sleep 1
    SrcDIR_zstd=${SrcDIR_3rd}/zstd
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/zstd
    prepareBuilding  ${SrcDIR_zstd} ${BuildDIR_lib} ${INSTALL_PREFIX_zstd} ${isRebuild} 
  
    # remark:zstd的根CMakeLists.txt在 "${SrcDIR_zstd}/build/cmake"目录下，比较特别^-^
    cmake -S${SrcDIR_zstd}/build/cmake -B ${BuildDIR_lib} \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_zstd}  \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}   \
            -DBUILD_SHARED_LIBS=OFF     \
            -DCMAKE_C_FLAGS="-fPIC" \
            -DCMAKE_CXX_FLAGS="-fPIC" 

    cmake --build ${BuildDIR_lib} -j$(nproc) -v

    cmake --build ${BuildDIR_lib} --target install    

    echo "========== finished building zstd 4 ubuntu ========== " 
fi    
 

# -------------------------------------------------
# openssl
# -------
# libssl.a是静态库​​，通常依赖 libcrypto.a提供底层加密函数
# （如 SHA256_Init、EVP_CIPHER_CTX_new）。
# -------------------------------------------------
INSTALL_PREFIX_openssl=${INSTALL_PREFIX_ubt}/openssl

if [ "${isFinished_build_openssl}" != "true" ]; then 
    echo "========== Building openssl 4 ubuntu ========== " &&  sleep 3

    SrcDIR_openssl=${SrcDIR_3rd}/openssl
    BuildDIR_openssl=${BuildDir_ubuntu}/3rd/openssl
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
    CFLAGS="-fPIC" \
    ${SrcDIR_openssl}/Configure linux-x86_64 -d \
                --prefix=${INSTALL_PREFIX_openssl} \
                --openssldir=${INSTALL_PREFIX_openssl}/ssl  \
                no-shared \
                no-zlib \
                no-module  no-dso 

    make build_sw -j$(nproc)  V=1

    make install_sw  
    echo "========== finished building openssl 4 ubuntu ========== " &&  sleep 2
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
# -------------------------------------------------
# INSTALL_PREFIX_icu=${INSTALL_PREFIX_ubt}/icu
# 
# if [ "${isFinished_build_icu}" != "true" ] ; then 
#     echo "========== building icu 4 ubuntu==========do nothing " &&  sleep 3
# 
#     SrcDIR_lib=${SrcDIR_3rd}/icu/icu4c/source/
#     BuildDIR_lib=${BuildDir_ubuntu}/3rd/icu
#     prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_icu} ${isRebuild}  
# 
#     
#     cd ${SrcDIR_lib}
#     chmod +x runConfigureICU configure install-sh  # 确保脚本可执行
# 
# 
#     cd ${BuildDIR_lib}
# 
#     CFLAGS="-fPIC" \
#     ${SrcDIR_lib}/configure   \
#         --prefix=${INSTALL_PREFIX_icu} \
#         --enable-static=yes --enable-debug \
#         --enable-shared=no \
#         --disable-samples \
#         --disable-tests 
#         # --disable-tests       # 禁用测试，加快编译
#     make -j$(nproc)  # 多线程编译
#     make install     # 安装到指定的 --prefix 目录
# 
#     echo "========== finished building icu 4 ubuntu ========== " &&  sleep 1
# fi 

# -------------------------------------------------
# libidn2
# -------------------------------------------------
# INSTALL_PREFIX_idn2=${INSTALL_PREFIX_ubt}/libidn2
# 
# if [ "${isFinished_build_libidn2}" != "true" ] ; then 
#     echo "============= Building libidn2 =============" &&  sleep 3
# 
#     SrcDIR_lib=${SrcDIR_3rd}/libidn2
#     BuildDIR_lib=${BuildDir_ubuntu}/3rd/libidn2
#     prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_idn2} ${isRebuild}    
#  
#     cd ${SrcDIR_lib}  && ./bootstrap
#     if [ "$?" != "0" ]; then
#         echo "libidn2/bootstrap failed. exit!!" &&  exit 1002
#     fi
# 
#     # 在构建目录中运行configure
#     cd ${BuildDIR_lib}
#  
#     CFLAGS="-fPIC" \
#     ${SrcDIR_lib}/configure \
#                 --prefix=${INSTALL_PREFIX_idn2} --enable-debug \
#                 --disable-shared \
#                 --enable-static  
#     # 
#     make   -j$(nproc)  
#     make install       
# 
#     echo "============= Finished Building libidn2 =============" &&  sleep 2
# fi


# -------------------------------------------------
# libpsl : is depended on by curl.
# -------------------------------------------------
INSTALL_PREFIX_psl=${INSTALL_PREFIX_ubt}/libpsl

if [ "${isFinished_build_libpsl}" != "true" ] ; then 
    echo "======== Building libpsl =========" &&  sleep 3 

    SrcDIR_lib=${SrcDIR_3rd}/libpsl
    BuildDIR_libpsl=${BuildDir_ubuntu}/3rd/libpsl 
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_libpsl} ${INSTALL_PREFIX_psl} ${isRebuild}

    cd ${SrcDIR_lib}  && ./autogen.sh

    # 在构建目录中运行configure
    cd ${BuildDIR_libpsl} 

    # CFLAGS="-I${INSTALL_PREFIX_icu}/include/icu" \
    # LDFLAGS="-L${INSTALL_PREFIX_icu}/lib" \

    CFLAGS="-fPIC" \
    ${SrcDIR_lib}/configure \
                --prefix=${INSTALL_PREFIX_psl} --enable-debug \
                --disable-shared  --enable-static  \
                --disable-runtime --enable-builtin  -disable-gtk-doc
                # --without-libidn2 --without-libicu --without-libidn 
    # 
    make   -j$(nproc)  -v
    make install       
    echo "========== Finished Building libpsl =========" &&  sleep 2
fi

   

# -------------------------------------------------
# curl
# -------------------------------------------------
INSTALL_PREFIX_curl=${INSTALL_PREFIX_ubt}/curl

if [ "${isFinished_build_curl}" != "true" ] ; then 
    echo "======== Building curl =========" &&  sleep 3 # && set -x     

    SrcDIR_lib=${SrcDIR_3rd}/curl
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/curl 
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_curl} ${isRebuild}              
    # ---------------------    
    cmk_prefixPath=$(check_concat_paths  "${INSTALL_PREFIX_openssl}" \
                "${INSTALL_PREFIX_psl}" \
                "${INSTALL_PREFIX_zlib}"  "${INSTALL_PREFIX_zstd}" )
    echo "ubt....for curl: cmk_prefixPath=${cmk_prefixPath}" 

    # CMAKE_PREFIX_PATH是 find_package 用于搜索 XxxConfig.cmake，
    # CMAKE_MODULE_PATH是 find_package 用于搜索 FindXxx.cmake 
    curl_MODULE_PATH="${INSTALL_PREFIX_zlib}/lib/cmake/zlib" 
    echo "ubt....for curl: curl_MODULE_PATH=${curl_MODULE_PATH}" 
    
    cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib} --debug-find \
            "${cmakeCommonParams[@]}"   \
            -DCMAKE_MODULE_PATH="${curl_MODULE_PATH}" \
            -DCMAKE_PREFIX_PATH="${cmk_prefixPath}"  \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_curl}  \
            -DCMAKE_C_FLAGS="-fPIC"               \
            -DCMAKE_CXX_FLAGS="-fPIC"              \
            -DCURL_DISABLE_LDAP=ON     \
            -DCURL_DISABLE_FTP=ON      \
            -DCURL_DISABLE_TELNET=ON   \
            -DCURL_DISABLE_DICT=ON     \
            -DCURL_DISABLE_FILE=ON     \
            -DCURL_DISABLE_TFTP=ON     \
            -DCURL_BROTLI=OFF  -DCURL_USE_LIBSSH2=OFF \
            -DUSE_LIBIDN2=OFF  -DUSE_NGHTTP2=OFF       \
            -DCURL_USE_LIBPSL=OFF       -DCURL_ZSTD=OFF      \
            -DCURL_ZLIB=ON    -DZLIB_USE_STATIC_LIBS=ON \
            -DBUILD_DOCS=OFF  -DCMAKE_INSTALL_DOCDIR=OFF \
            -DCURL_USE_PKGCONFIG=OFF    \
            -DOPENSSL_USE_STATIC_LIBS=ON  \
            -DZSTD_INCLUDE_DIR="${INSTALL_PREFIX_zstd}/include"  \
            -DZSTD_LIBRARY="${INSTALL_PREFIX_zstd}/lib/libzstd.a" \
            -DZLIB_ROOT=${INSTALL_PREFIX_zlib}               \
            -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include \
            -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a   \
            -DOpenSSL_DIR="${INSTALL_PREFIX_openssl}/lib64/cmake/OpenSSL" \
            -DOPENSSL_INCLUDE_DIR=${INSTALL_PREFIX_openssl}/include        \
            -DOPENSSL_SSL_LIBRARY=${INSTALL_PREFIX_openssl}/lib64/libssl.a  \
            -DOPENSSL_CRYPTO_LIBRARY=${INSTALL_PREFIX_openssl}/lib64/libcrypto.a \
            -DLIBPSL_INCLUDE_DIR=${INSTALL_PREFIX_psl}/include   \
            -DLIBPSL_LIBRARY=${INSTALL_PREFIX_psl}/lib/libpsl.a  

 
            # (1) -DZLIB_DIR="${INSTALL_PREFIX_zlib}/lib/cmake/zlib"
            # (2) find_package(Zstd) 用的是 3rd/curl/CMake/FindZstd.cmake,
            #    因为 -DZstd_DIR="${INSTALL_PREFIX_zstd}/lib/cmake/zstd" 下只有zstdConfig.cmake(开头字母小写，不是Zstd)。
            # (3)-DCURL_ZSTD=OFF ： 禁用 zstd
            #  
            # -DOPENSSL_ROOT_DIR=${INSTALL_PREFIX_openssl}   \
            # -DOPENSSL_LIBRARIES="${INSTALL_PREFIX_openssl}/lib64/libssl.a; ${INSTALL_PREFIX_openssl}/lib64/libcrypto.a" \
            # -DZSTD_ROOT=${INSTALL_PREFIX_zstd} \ 

        # -- hi..OPENSSL_LIBRARIES=/home/osg0/install/openssl/lib64/libssl.a;/home/osg0/install/openssl/lib64/libcrypto.a;dl
        # -- hi..OpenSSL::SSL library path: /home/osg0/install/openssl/lib64/libssl.a
        # -- hi..OpenSSL::Crypto library path: /home/osg0/install/openssl/lib64/libcrypto.a
 
            # -DCMAKE_EXE_LINKER_FLAGS="-licuuc -licudata -licuio"  # 链接ICU相关静态库
            # -DENABLE_IPV6=OFF

    cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc)

    cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}
    echo "========== Finished Building curl =========" # &&  set +x
    
fi

 
# -------------------------------------------------
# jpeg-9f 
# remark: libjpeg-turbo是 标准版libjpeg的超集，所以这里不再特地编译标准libjpeg（jpeg-9f）
#
# libjpeg-turbo 的位深度支持​​ ：默认仅支持 8-bit​​（即使开启 WITH_JPEG7=ON）。
# ​​12-bit JPEG 支持需要原版 jpeg-9f​，并通过 --enable-12bit编译选项启用。
# -------------------------------------------------
# INSTALL_PREFIX_jpeg9f=${INSTALL_PREFIX_ubt}/jpeg9f
# 
# if [ "${isFinished_build_jpeg9f}" != "true" ] ; then 
#     echo "========== Building jpeg-9f 4 ubuntu=========="  &&  sleep 5
# 
#     SrcDIR_lib=${SrcDIR_3rd}/jpeg-9f
#     BuildDIR_Jpeg9f=${BuildDir_ubuntu}/3rd/jpeg9f
#     prepareBuilding  ${SrcDIR_lib} ${BuildDIR_Jpeg9f} ${INSTALL_PREFIX_jpeg9f} ${isRebuild}              
# 
#     # 在构建目录中运行configure
#     cd ${BuildDIR_Jpeg9f} 
#       
#     CFLAGS="-fPIC" \ 
#     ${SrcDIR_lib}/configure --prefix=${INSTALL_PREFIX_jpeg9f}\
#              --host=arm-linux --enable-debug \
#              --enable-shared --enable-static
# 
#     # 
#     make   -j$(nproc)  
# 
#     make install  
#     echo "========== Finished Building jpeg-9f 4 ubuntu=========="   
# fi
 

# -------------------------------------------------
# libjpeg-turbo
# -------------------------------------------------
INSTALL_PREFIX_jpegTurbo=${INSTALL_PREFIX_ubt}/libjpeg-turbo

if [ "${isFinished_build_libjpegTurbo}" != "true" ]  ; then 
    if true; then 
        echo "========== Building libjpeg-turbo 4 Ubuntu==========" && sleep 3
    fi

    SrcDIR_lib=${SrcDIR_3rd}/libjpeg-turbo
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/libjpeg-turbo
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_jpegTurbo} ${isRebuild}  

    cmake -S${SrcDIR_lib}  -B ${BuildDIR_lib} --debug-find \
            "${cmakeCommonParams[@]}"   \
            -DCMAKE_FIND_LIBRARY_SUFFIXES=".a"  \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_jpegTurbo}  \
            -DWITH_JPEG8=ON      \
            -DENABLE_SHARED=OFF  \
            -DWITH_SIMD=ON       # 启用 SIMD 优化（需安装 NASM）
    echo "make-----------------------------------------"
    cmake --build ${BuildDIR_lib} -j$(nproc) -v

    echo "make install-----------------------------------------"
    cmake --build ${BuildDIR_lib} --target install -v

    echo "========== Finished building libjpeg-turbo  4 Ubuntu==========" && sleep 5
fi


# -------------------------------------------------
# libpng
# -------------------------------------------------

INSTALL_PREFIX_png=${INSTALL_PREFIX_ubt}/libpng
 
if [ "${isFinished_build_libpng}" != "true" ] ; then 
    echo "========== Building libpng 4 Ubuntu==========" && sleep 1 && set -x

    SrcDIR_lib=${SrcDIR_3rd}/libpng
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/libpng
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_png} ${isRebuild}  
         
    cmk_prefixPath="${INSTALL_PREFIX_zlib}"

    cmake -S${SrcDIR_lib} -B ${BuildDIR_lib} --debug-find \
            "${cmakeCommonParams[@]}"  \
            -DCMAKE_MODULE_PATH="${INSTALL_PREFIX_zlib}/lib/cmake/zlib" \
            -DCMAKE_PREFIX_PATH="${cmk_prefixPath}" \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_png} \
            -DZLIB_ROOT="${INSTALL_PREFIX_zlib}" \
            -DPNG_SHARED=OFF  -DPNG_STATIC=ON   
            
            # -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a \
            # -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include \
    cmake --build ${BuildDIR_lib} -j$(nproc)

    cmake --build ${BuildDIR_lib} --target install
    echo "========== Finished Building libpng for Ubuntu ==========" && sleep 1 && set +x   
fi    

 
# -------------------------------------------------
# xz : xz generates liblzma.a which is needed by libtiff
# -------------------------------------------------
INSTALL_PREFIX_xz=${INSTALL_PREFIX_ubt}/xz
 
if [ "${isFinished_build_xz}" != "true" ]  ; then 
    echo "========== Building xz 4 Ubuntu==========" && sleep 5
    SrcDIR_lib=${SrcDIR_3rd}/xz
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/xz
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_xz} ${isRebuild}     

    cmake -S${SrcDIR_lib}  -B ${BuildDIR_lib}  --debug-find \
            "${cmakeCommonParams[@]}"    \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_xz}  

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
# -- ......
# -- Found LibLZMA: /usr/lib/x86_64-linux-gnu/liblzma.so (found version "5.4.5") 
# -- The CXX compiler identification is GNU 13.3.0
# 
# liblzma.so:  LZMA 的压缩率通常高于传统的 ZIP（Deflate）或 JPEG 压缩，适合需要高压缩比的场景（如存档、卫星图像）。
# -------------------------------------------------
INSTALL_PREFIX_tiff=${INSTALL_PREFIX_ubt}/libtiff
 
if [ "${isFinished_build_libtiff}" != "true" ] ; then 
    echo "========== Building libtiff 4 Ubuntu==========" && sleep 1 # && set -x
    SrcDIR_lib=${SrcDIR_3rd}/libtiff
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/libtiff
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_tiff} ${isRebuild}     

    cmk_prefixPath="${INSTALL_PREFIX_zlib};${INSTALL_PREFIX_xz}"
    cmk_prefixPath="${cmk_prefixPath};${INSTALL_PREFIX_jpegTurbo}"
    echo "ubt....for libtiff: cmk_prefixPath=${cmk_prefixPath}" 

    cmake -S${SrcDIR_lib} -B ${BuildDIR_lib} --debug-find \
            "${cmakeCommonParams[@]}"   \
            -DCMAKE_PREFIX_PATH="${cmk_prefixPath}" \
            -DCMAKE_MODULE_PATH="${INSTALL_PREFIX_zlib}/lib/cmake/zlib" \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_tiff}  \
            -DM_LIBRARY="/usr/lib/x86_64-linux-gnu/libm.so" \
            -DZLIB_ROOT=${INSTALL_PREFIX_zlib}  \
            -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a \
            -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include \
            -DJPEG_LIBRARY=${INSTALL_PREFIX_jpegTurbo}/lib/libjpeg.a \
            -DJPEG_INCLUDE_DIR=${INSTALL_PREFIX_jpegTurbo}/include/libjpeg \
            -DLIBLZMA_LIBRARY=${INSTALL_PREFIX_xz}/lib/liblzma.a \
            -DLIBLZMA_INCLUDE_DIR=${INSTALL_PREFIX_xz}/include \
            -DCMAKE_C_FLAGS="-fPIC" \
            -DCMAKE_CXX_FLAGS="-fPIC" \
            -DCMAKE_EXE_LINKER_FLAGS="-static" \
            -Djbig=OFF \
            -Dtiff-tools=OFF   

            # -DCMAKE_FIND_USE_SYSTEM_LIBS=ON \          
            # -DLINK_LIBRARIES="/usr/lib/x86_64-linux-gnu/libm.so"  ## not ok
            # -Dtiff-tools=OFF    # 可选：禁用工具构建
            #  -DCMAKE_EXE_LINKER_FLAGS="-static"  # 强制静态链接所有库

            # (1) 因为libtiff/CMakeLists.txt中 find_library(M_LIBRARY m)，需要 
            #    -DM_LIBRARY="/usr/lib/x86_64-linux-gnu/libm.so" 针对cmakeCommonParams做特化
            
    cmake --build ${BuildDIR_lib} -j$(nproc) -v

    cmake --build ${BuildDIR_lib} --target install  -v
    echo "========== Finished Building libtiff for Ubuntu ==========" # && sleep 1 && set +x 
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
# | 依赖库       | 状态                  | 影响                                                    |
# |--------------|-----------------------|-------------------------------------------------------|
# | **BZip2**    | `Could NOT find`      | FreeType 将无法处理 `.bz2` 压缩的字体文件（如 `.ttf.bz2`）。|
# | **BrotliDec**| `Could NOT find`      | 无法解析 Brotli 压缩的字体（如 `.ttf.br`），但此类文件较少见。|
# | **ZLIB**     | 已找到（`libz.so`）    | 支持 `.ttf.gz` 和常规压缩。                              |
# | **PNG**      | 已找到（`libpng.so`）  | 支持位图字体（如 `.png` 格式的彩色字体）。                   |
# -------------------------------------------------
INSTALL_PREFIX_freetype=${INSTALL_PREFIX_ubt}/freetype
 
if [ "${isFinished_build_freetype}" != "true" ] ; then 
    echo "========== Building freetype 4 Ubuntu==========" && sleep 1 # && set -x
    SrcDIR_lib=${SrcDIR_3rd}/freetype
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/freetype
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_freetype} ${isRebuild}       
 

    cmk_prefixPath="${INSTALL_PREFIX_zlib};${INSTALL_PREFIX_png}"
    echo "ubt....for libtiff: cmk_prefixPath=${cmk_prefixPath}" 

    cmake -S${SrcDIR_lib} -B ${BuildDIR_lib} --debug-find \
            "${cmakeCommonParams[@]}"  \
            -DCMAKE_PREFIX_PATH="${cmk_prefixPath}" \
            -DCMAKE_MODULE_PATH="${INSTALL_PREFIX_zlib}/lib/cmake/zlib" \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_freetype} \
            -DCMAKE_C_FLAGS="-fPIC" \
            -DCMAKE_CXX_FLAGS="-fPIC" \
            -DFT_DISABLE_BZIP2=ON \
            -DFT_DISABLE_BROTLI=ON \
            -DZLIB_ROOT=${INSTALL_PREFIX_zlib}              \
            -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a \
            -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include \
            -DPNG_LIBRARIES=${INSTALL_PREFIX_png}/lib/libpng.a  \
            -DPNG_INCLUDE_DIRS="${INSTALL_PREFIX_png}/include"    \
            -DFT_REQUIRE_ZLIB=ON \
            -DFT_REQUIRE_PNG=ON  \
            -DCMAKE_EXE_LINKER_FLAGS="-static"

    cmake --build ${BuildDIR_lib} -j$(nproc) -v

    cmake --build ${BuildDIR_lib} --target install

    echo "========== Finished Building freetype for Ubuntu ==========" # && sleep 1  && set -x
fi

 
# -------------------------------------------------
# geos
# ------------------------------------------------- 

INSTALL_PREFIX_geos=${INSTALL_PREFIX_ubt}/geos

if [ "${isFinished_build_geos}" != "true" ] ; then 
    echo "========== building geos 4 ubuntu========== " &&  sleep 3

    SrcDIR_lib=${SrcDIR_3rd}/geos
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/geos 
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_geos} ${isRebuild} 
     
    #################################################################### 
    # 在顶层 CMakeLists.txt 中全局启用 PIC: set(CMAKE_POSITION_INDEPENDENT_CODE ON)  
    cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib} \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_C_FLAGS="-fPIC" \
            -DCMAKE_CXX_FLAGS="-fPIC" \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_geos}  \
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}   \
            -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}    \
            -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} \
            -DBUILD_SHARED_LIBS=OFF     \
            -DCMAKE_EXE_LINKER_FLAGS="-static" 
 
    cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc)
    
    cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}
    #################################################################### 
    echo "========== finished building geos 4 ubuntu ========== " &&  sleep 2
fi


# -------------------------------------------------
# sqlite
# ------------------------------------------------- 
INSTALL_PREFIX_sqlite=${INSTALL_PREFIX_ubt}/sqlite

if [ "${isFinished_build_sqlite}" != "true" ] ; then 
    echo "========== building sqlite 4 ubuntu========== " &&  sleep 1
    SrcDIR_lib=${SrcDIR_3rd}/sqlite3cmake
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/sqlite
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_sqlite} ${isRebuild}   

    #################################################################### 
    # ${SrcDIR_3rd}/sqlite 代码来自于github 而不是官网
    # ------ 
    # SrcDIR_lib=${SrcDIR_3rd}/sqlite
    # cd ${BuildDIR_lib}  # 在构建目录中运行configure
    # 
    # # CFLAGS="-I${INSTALL_PREFIX_icu}/include/icu" \
    # # LDFLAGS="-L${INSTALL_PREFIX_icu}/lib" \ 
    # cFlags="-fPIC -O0 -g -DSQLITE_ENABLE_RTREE=1 "
    # cFlags="${cFlags} -DSQLITE_THREADSAFE=1"
    # cFlags+=" -DSQLITE_MUTEX=unix" 
    #  
    # ldFlags="-Wl,-rpath=${INSTALL_PREFIX_sqlite}/lib -lz -lm"
    # 
    # 
    # echo "sqlite...SrcDIR=${SrcDIR_lib};BuildDIR=${BuildDir_ubuntu}/3rd/sqlite"
    # CC=${CMAKE_C_COMPILER} \
    # ${SrcDIR_lib}/configure  --prefix=${INSTALL_PREFIX_sqlite} \
	# 	--host=x86_64-linux-musl \
    #     --disable-shared  --enable-static    \
    #     --enable-debug   CFLAGS="${cFlags}" 
    # 
    #     #CFLAGS="-fPIC -DSQLITE_OMIT_LOAD_EXTENSION=1 "  
    # echo "sqlite...........make -j......................."
    # make   -j$(nproc)  ## -d
    # echo "sqlite...........make install.................."
    # make   install   ##  -d
    # 
    # -- 把 FindSQLite3.cmake 放到 ${INSTALL_PREFIX_sqlite}/lib/cmake/SQLite3 ???   
    # ------------------------------------------------------------------
    # ${SrcDIR_3rd}/sqlite3cmake 代码来自于官网 https://sqlite.org，**cmake脚本是自定义的**
    cmkPrefixPath=${INSTALL_PREFIX_zlib}

    cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib} --debug-find \
            "${cmakeCommonParams[@]}"  \
            -DCMAKE_PREFIX_PATH=${cmkPrefixPath} \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_sqlite}  \
            -DSQLITE_ENABLE_COLUMN_METADATA=ON \
            -DSQLITE_OMIT_DEPRECATED=ON \
            -DSQLITE_SECURE_DELETE=ON      
 
    cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v

    cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -v

    #################################################################### 
    echo "========== finished building sqlite 4 ubuntu ========== " &&  sleep 1 
fi

 

# -------------------------------------------------
# proj
# ------------------------------------------------- 
INSTALL_PREFIX_proj=${INSTALL_PREFIX_ubt}/proj

if [ "${isFinished_build_proj}" != "true" ] ; then 
    echo "========== building proj 4 ubuntu========== " &&  sleep 1 && set -x

    SrcDIR_lib=${SrcDIR_3rd}/proj
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/proj 
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_proj} ${isRebuild} 
                    
    #################################################################### 
    # libssl_path=${INSTALL_PREFIX_openssl}/lib64/libssl.a 
    # libcrypto_path=${INSTALL_PREFIX_openssl}/lib64/libcrypto.a    
    # 检查并拼接路径
    # cmk_prefixPath=${INSTALL_PREFIX_zlib};${INSTALL_PREFIX_xz}; \
    #                ${INSTALL_PREFIX_jpegTurbo}
    cmk_prefixPath=$(check_concat_paths  "${INSTALL_PREFIX_zlib}" \
                "${INSTALL_PREFIX_xz}" \
                "${INSTALL_PREFIX_jpegTurbo}" "${INSTALL_PREFIX_openssl}" \
                "${INSTALL_PREFIX_curl}" "${INSTALL_PREFIX_sqlite}")  
    echo "ubt...building proj,cmk_prefixPath=${cmk_prefixPath}"    
    
    
    #  CC=musl-gcc cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib}     
    cmake -S ${SrcDIR_lib}  -B ${BuildDIR_lib} --debug-find \
            "${cmakeCommonParams[@]}"  \
            -DCMAKE_PREFIX_PATH="${cmk_prefixPath}"                     \
            -DCMAKE_MODULE_PATH="${INSTALL_PREFIX_zlib}/lib/cmake/zlib"  \
            -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX_proj}"               \
            -DBUILD_TESTING=OFF  -DBUILD_EXAMPLES=ON  \
            -DCMAKE_CXX_FLAGS="-fPIC" \
            -DCMAKE_C_FLAGS="-fPIC"    \
            -DENABLE_CURL=ON  \
            -DENABLE_TIFF=OFF  \
            -DSQLite3_DISABLE_DYNAMIC_EXTENSIONS=ON \
            -DCURL_DISABLE_ARES=ON  \
            -DZLIB_ROOT="${INSTALL_PREFIX_zlib}"             \
            -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a  \
            -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include  \
            -DOpenSSL_DIR="${INSTALL_PREFIX_openssl}/lib64/cmake/OpenSSL"     \
            -DOpenSSL_INCLUDE_DIR=${INSTALL_PREFIX_openssl}/include            \
            -DOpenSSL_SSL_LIBRARY=${INSTALL_PREFIX_openssl}/lib64/libssl.a      \
            -DOpenSSL_CRYPTO_LIBRARY=${INSTALL_PREFIX_openssl}/lib64/libcrypto.a \
            -DCURL_DIR="${INSTALL_PREFIX_curl}/lib/cmake/CURL"   \
            -DCURL_LIBRARY=${INSTALL_PREFIX_curl}/lib/libcurl-d.a \
            -DCURL_INCLUDE_DIR=${INSTALL_PREFIX_curl}/include      \
            -DSQLite3_LIBRARY=${INSTALL_PREFIX_sqlite}/lib/libsqlite3.a \
            -DSQLite3_INCLUDE_DIR=${INSTALL_PREFIX_sqlite}/include                
 
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
 

            # # -DCMAKE_SHARED_LINKER_FLAGS="-L${INSTALL_PREFIX_tiff}/lib -ltiff -ljpeg -llzma -lz -L${lib64_dir} -lssl -lcrypto" \
            # # -DCMAKE_EXE_LINKER_FLAGS="-L${lib_dir} -ltiff -ljpeg -llzma -lz -L${lib64_dir} -lssl -lcrypto" \
            # -DCMAKE_EXE_LINKER_FLAGS="-static" \  

            # -DOPENSSL_ROOT_DIR=${INSTALL_PREFIX_openssl} \
            # -DOPENSSL_LIBRARIES="${libssl_path};${libcrypto_path}" \
            # -DCURL_ROOT=${INSTALL_PREFIX_curl} \

            # -DTIFF_LIBRARY=${INSTALL_PREFIX_tiff}/lib/libtiff.a \
            # -DTIFF_INCLUDE_DIR=${INSTALL_PREFIX_tiff}/include \              

    cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v 
    
    cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}
    #################################################################### 
    echo "========== finished building proj 4 ubuntu ========== "   && set -x
fi



# -------------------------------------------------
# libexpat
# ------------------------------------------------- 
INSTALL_PREFIX_expat=${INSTALL_PREFIX_ubt}/libexpat

if [ "${isFinished_build_libexpat}" != "true" ] ; then 
    echo "========== building libexpat 4 ubuntu========== " &&  sleep 5

    SrcDIR_lib=${SrcDIR_3rd}/libexpat/expat
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/libexpat 
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_expat} ${isRebuild} 
        
    ####################################################################
    cmk_prefixPath="${INSTALL_PREFIX_zlib};${INSTALL_PREFIX_xz}"
    
    cmake -S ${SrcDIR_lib}  -B ${BuildDIR_lib} --debug-find \
            "${cmakeCommonParams[@]}"   \
            -DCMAKE_PREFIX_PATH=${cmk_prefixPath} \
            -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_expat}  \
            -DCMAKE_C_FLAGS="-fPIC"   \
            -DCMAKE_CXX_FLAGS="-fPIC" \
            -DEXPAT_BUILD_TESTS=OFF \
            -DEXPAT_BUILD_EXAMPLES=OFF \
            -DEXPAT_BUILD_DOCS=OFF \
            -DCMAKE_EXE_LINKER_FLAGS="-static"

        # if " -DEXPAT_BUILD_FUZZERS=ON (测试模式)", expat ->protobuf
    cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc)
    
    cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}     
    #################################################################### 
    echo "========== finished building libexpat 4 ubuntu ========== " &&  sleep 2
fi    

# -------------------------------------------------
# abseil-cpp  
# -------------------------------------------------
INSTALL_PREFIX_absl=${INSTALL_PREFIX_ubt}/abseil-cpp


if [ "${isFinished_build_absl}" != "true" ] ; then 
    echo "========== building abseil-cpp 4 ubuntu========== " &&  sleep 5

    SrcDIR_lib=${SrcDIR_3rd}/abseil-cpp
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/abseil-cpp 
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_absl} ${isRebuild}        
    ####################################################################
    cmk_prefixPath=“” 
    
    cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib} --debug-find \
            "${cmakeCommonParams[@]}"   \
            -DCMAKE_PREFIX_PATH="${cmk_prefixPath}" \
            -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_absl}  \
            -DCMAKE_CXX_FLAGS="-fPIC" \
            -DCMAKE_C_FLAGS="-fPIC"   

    cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v
    
    cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}     
    #################################################################### 
    echo "========== finished building abseil-cpp 4 ubuntu ========== " &&  sleep 2
fi    


# -------------------------------------------------
# protobuf  
# -------------------------------------------------
INSTALL_PREFIX_protobuf=${INSTALL_PREFIX_ubt}/protobuf

if [ "${isFinished_build_protobuf}" != "true" ] ; then 
    echo "========== building protobuf 4 ubuntu========== " &&  sleep 5

    SrcDIR_lib=${SrcDIR_3rd}/protobuf
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/protobuf 
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_protobuf} ${isRebuild}        
    ####################################################################
    cmk_prefixPath="${INSTALL_PREFIX_zlib};${INSTALL_PREFIX_absl}"
    protoc_path=/home/abner/programs/protoc-31.1-linux-x86_64/bin/protoc
    
    cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib}  --debug-find \
            "${cmakeCommonParams[@]}"  \
            -DCMAKE_PREFIX_PATH="${cmk_prefixPath}" \
            -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_protobuf}  \
            -DCMAKE_C_FLAGS="-fPIC"   \
            -DCMAKE_CXX_FLAGS="-fPIC" \
            -Dprotobuf_BUILD_TESTS=OFF \
            -Dprotobuf_BUILD_EXAMPLES=OFF \
            -Dprotobuf_BUILD_PROTOC_BINARIES=OFF \
            -Dprotobuf_PROTOC_EXE=${protoc_path}  \
            -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include \
            -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a   
                   

    cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v
    
    cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}     
    #################################################################### 
    echo "========== finished building protobuf 4 ubuntu ========== " &&  sleep 1
fi    

# -------------------------------------------------
# boost  
# -------------------------------------------------
INSTALL_PREFIX_boost=${INSTALL_PREFIX_ubt}/boost

if [ "${isFinished_build_boost}" != "true" ] ; then 
    echo "========== building boost 4 ubuntu========== " &&  sleep 1 && set -x

    SrcDIR_lib=${SrcDIR_3rd}/boost
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/boost
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_boost} ${isRebuild} 

    # 1. 进入 Boost 源码目录 
    cd ${SrcDIR_lib}  
    # 2. 删除 b2 生成的构建目录（存放编译中间产物，核心缓存位置）
    rm -rf bin.v2/

    # 3. 删除配置缓存文件（记录之前的编译参数，如是否启用 MPI）
    rm -f project-config.jam  # 若存在此文件，必须删除
    rm -f user-config.jam     # 若存在用户自定义配置，也删除

    # 4. （可选）若之前执行过 ./bootstrap.sh，重新生成干净的 b2 工具
    rm -f b2 bjam  # 删除旧的 b2 可执行文件

    ./bootstrap.sh  # 重新生成干净的 b2（此时无 MPI 相关配置）
 
    # 静态编译 Boost
    ${SrcDIR_lib}/b2 install --prefix="${INSTALL_PREFIX_boost}" \
        link=static runtime-link=static \
        --build-type=complete \
        --layout=versioned --layout=tagged  \
        --without-python --without-mpi \
        -j$(nproc)
  
    #   --without-mpi ### 最推荐的方案，因为 osgearth 通常不需要 Boost.MPI 组件，排除后可避免 MPI 相关的配置问题
     

    # (1) 仅编译特定库​​:   ./b2 install --with-thread --with-system --with-filesystem
    # ​​(2) 仅生成静态库​​:   ./b2 link=static
    # ​​(3) 仅生成动态库​​:   ./b2 link=shared
    # ​​(4) 指定 C++ 标准​​: ./b2 cxxflags="-std=c++17" 
    echo "========== Finished Building boost =========" &&  sleep 1 && set +x
fi

 
# -------------------------------------------------
# gdal , see 3rd/gdal/fuzzers/build.sh
# -------------------------------------------------
INSTALL_PREFIX_gdal=${INSTALL_PREFIX_ubt}/gdal

if [ "${isFinished_build_gdal}" != "true" ] ; then 
    echo "========== building gdal 4 ubuntu========== " &&  sleep 1 # && set -x

    SrcDIR_lib=${SrcDIR_3rd}/gdal
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/gdal 
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_gdal} ${isRebuild}   

    #################################################################### 
    cmk_prefixPath=$(check_concat_paths_1  "${INSTALL_PREFIX_zlib}" \
                "${INSTALL_PREFIX_xz}"     "${INSTALL_PREFIX_png}" \
                "${INSTALL_PREFIX_absl}"     \
                "${INSTALL_PREFIX_jpegTurbo}"  "${INSTALL_PREFIX_openssl}" \
                "${INSTALL_PREFIX_tiff}"   "${INSTALL_PREFIX_expat}" \
                "${INSTALL_PREFIX_geos}"   "${INSTALL_PREFIX_proj}"  \
                "${INSTALL_PREFIX_curl}"   "${INSTALL_PREFIX_sqlite}")

    echo "==========cmk_prefixPath=${cmk_prefixPath}" 

    cmake -S ${SrcDIR_lib}  -B ${BuildDIR_lib}  --debug-find \
            "${cmakeCommonParams[@]}"   \
            -DCMAKE_PREFIX_PATH=${cmk_prefixPath}       \
            -DCMAKE_MODULE_PATH="${INSTALL_PREFIX_zlib}/lib/cmake/zlib"  \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_gdal} \
            -DCMAKE_C_FLAGS="-fPIC  -DJPEG12_SUPPORTED=0"   \
            -DCMAKE_CXX_FLAGS="-fPIC  -DJPEG12_SUPPORTED=0" \
            -DBUILD_APPS=OFF   -DBUILD_TESTING=OFF -DSHOW_DEPS_PER_TARGET=ON \
            -DGDAL_USE_OPENSSL=ON \
            -DGDAL_USE_ZLIB=ON     \
            -DGDAL_USE_PNG=ON       \
            -DGDAL_USE_JPEG=ON       \
            -DGDAL_USE_CURL=ON        \
            -DGDAL_USE_SQLITE3=ON      \
            -DGDAL_USE_GEOS=ON          \
            -DGDAL_USE_PROJ=ON           \
            -DGDAL_USE_EXTERNAL_LIBS=ON   \
            -DGDAL_USE_JSONC_INTERNAL=ON   \
            -DOGR_BUILD_OPTIONAL_DRIVERS=ON \
            -DOGR_ENABLE_DRIVER_MVT=ON       \
            -DGDAL_USE_PROTOBUF=ON            \
            -DGDAL_USE_JPEG_INTERNAL=OFF       \
            -DHAVE_JPEGTURBO_DUAL_MODE_8_12=OFF \
            -DGDAL_ENABLE_DRIVER_HDF5=OFF    \
            -DGDAL_ENABLE_DRIVER_HDF4=OFF    \
            -DIconv_IS_BUILT_IN=OFF          \
            -DBUILD_LIBICONV=OFF             \
            -DGDAL_USE_LIBXML2=OFF           \
            -DGDAL_USE_EXPAT=OFF             \
            -DGDAL_USE_XERCESC=OFF           \
            -DGDAL_USE_DEFLATE=OFF           \
            -DGDAL_USE_CRYPTOPP=OFF          \
            -DGDAL_USE_ZSTD=OFF              \
            -DCURL_LIBRARY=${INSTALL_PREFIX_curl}/lib/libcurl-d.a \
            -DCURL_INCLUDE_DIR=${INSTALL_PREFIX_curl}/include \
            -DGEOS_INCLUDE_DIR=${INSTALL_PREFIX_geos}/include \
            -DGEOS_LIBRARY=${INSTALL_PREFIX_geos}/lib/libgeos.a \
            -DPROJ_INCLUDE_DIR=${INSTALL_PREFIX_proj}/include \
            -DPROJ_LIBRARY=${INSTALL_PREFIX_proj}/lib/libproj.a \
            -DSQLite3_HAS_COLUMN_METADATA=ON \
            -DSQLite3_HAS_MUTEX_ALLOC=ON      \
            -DSQLite3_HAS_RTREE=ON             \
            -DSQLite3_INCLUDE_DIR=${INSTALL_PREFIX_sqlite}/include     \
            -DSQLite3_LIBRARY=${INSTALL_PREFIX_sqlite}/lib/libsqlite3.a \
            -DPNG_INCLUDE_DIR=${INSTALL_PREFIX_png}/include \
            -DPNG_LIBRARY=${INSTALL_PREFIX_png}/lib/libpng.a \
            -DJPEG_INCLUDE_DIR=${INSTALL_PREFIX_jpegTurbo}/include/libjpeg \
            -DJPEG_LIBRARY=${INSTALL_PREFIX_jpegTurbo}/lib/libjpeg.a        \
            -DOpenSSL_DIR="${INSTALL_PREFIX_openssl}/lib64/cmake/OpenSSL/"   \
            -DOPENSSL_ROOT_DIR=${INSTALL_PREFIX_openssl}                  \
            -DOPENSSL_INCLUDE_DIR=${INSTALL_PREFIX_openssl}/include        \
            -DOPENSSL_SSL_LIBRARY=${INSTALL_PREFIX_openssl}/lib64/libssl.a      \
            -DOPENSSL_CRYPTO_LIBRARY=${INSTALL_PREFIX_openssl}/lib64/libcrypto.a \
            -DZLIB_ROOT=${INSTALL_PREFIX_zlib} \
            -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include \
            -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a  

            # (1) -DGDAL_ENABLE_DRIVER_HDF5 ## hdf5 support             
            #  gdal/lib/cmake/gdal/GDALConfig.cmake ： find_dependency(HDF5 COMPONENTS C)
            # (2)依赖关系 
            #      gdal -> EXPAT 
            #      EXPAT的测试代码部分 -> protobuf -> absl

    cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v
    
    cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}     
    #################################################################### 
    echo "========== finished building gdal 4 ubuntu ========== " # && set +x
fi    

 


# -------------------------------------------------
# osg 
# -----
# (1) before building osg,
#    sudo apt-get install libgl1-mesa-dev  libglu1-mesa-dev  libxext-dev 
# (2) 3rd/osg/CMakeModules里有很多FindXxx.cmake,osg的编译因此优先使用 3rd/osg/CMakeLists.txt里的 
#           SET(CMAKE_MODULE_PATH "${OpenSceneGraph_SOURCE_DIR}/CMakeModules;${CMAKE_MODULE_PATH}")
#     其次用-DCMAKE_PREFIX_PATH="${cmk_prefixPath}"
# (3)3rd/osg/examples/osgstaticviewer
# -------------------------------------------------
INSTALL_PREFIX_osg=${INSTALL_PREFIX_ubt}/osg

if [ "${isFinished_build_osg}" != "true" ] ; then 
    echo "========== building osg 4 ubuntu========== " &&  sleep 1

    SrcDIR_lib=${SrcDIR_3rd}/osg
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/osg
    echo "gg====         SrcDIR_lib=${SrcDIR_lib}" 
    echo "gg====       BuildDIR_lib=${BuildDIR_lib}" 
    echo "gg==== INSTALL_PREFIX_osg=${INSTALL_PREFIX_osg}" 
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_osg} ${isRebuild}  

    #################################################################### 
    # lib_dir=${INSTALL_PREFIX_src}/lib
    # lib64_dir=${INSTALL_PREFIX_src}/lib64 
    # _LINKER_FLAGS="-L${lib_dir} -lcurl -ltiff -ljpeg -lsqlite3 -lprotobuf -lpng -llzma -lz"
    # _LINKER_FLAGS="${_LINKER_FLAGS} -L${lib64_dir} -lssl -lcrypto" 
    # --------------
    #
    cmk_prefixPath=$(check_concat_paths_1  "${INSTALL_PREFIX_xz}" \
            "${INSTALL_PREFIX_absl}" "${INSTALL_PREFIX_zstd}"\
            "${INSTALL_PREFIX_png}"  "${INSTALL_PREFIX_jpegTurbo}"  \
            "${INSTALL_PREFIX_openssl}" "${INSTALL_PREFIX_tiff}" \
            "${INSTALL_PREFIX_geos}"  "${INSTALL_PREFIX_psl}"\
            "${INSTALL_PREFIX_proj}"  "${INSTALL_PREFIX_expat}"  \
            "${INSTALL_PREFIX_curl}" "${INSTALL_PREFIX_sqlite}"  \
            "${INSTALL_PREFIX_boost}" ) 
    echo "==========cmk_prefixPath=${cmk_prefixPath}"   
    # <<osg的间接依赖库>>
    # 依赖关系：osg -->gdal-->curl-->libpsl， 所以OSG 的 CMake 配置需要确保在
    # target_link_libraries 时包含所有 cURL 所依赖的库(osg的间接依赖库)。
    # 这通常在 CMakeLists.txt中通过 find_package(CURL)返回的导入型目标CURL::libCurl获得或直接在
    # CMake -S -B命令中加 -DCMAKE_EXE_LINKER_FLAGS或CMAKE_SHARED_LINKER_FLAGS来添加缺失的库。​ 
    # 
    _curlLibs="${INSTALL_PREFIX_curl}/lib/libcurl-d.a;"
    _curlLibs="${_curlLibs} ${INSTALL_PREFIX_openssl}/lib64/libssl.a;"
    _curlLibs="${_curlLibs} ${INSTALL_PREFIX_openssl}/lib64/libcrypto.a;"
    _curlLibs="${_curlLibs} ${INSTALL_PREFIX_psl}/lib/libpsl.a;"
    _curlLibs="${_curlLibs} ${INSTALL_PREFIX_zstd}/lib/libzstd.a"
    _curlLibs="${_curlLibs} ${INSTALL_PREFIX_zlib}/lib/libz.a"
    echo "gg==========_curlLibs=${_curlLibs}" 
 
    #  zlib // freetype // gdal 的搜索优先使用 3rd/osg/CMakeLists.txt里的 CMAKE_MODULE_PATH
    osg_MODULE_PATH=""
    # ------
    libstdcxx_a_path=$(find /usr/lib/gcc/x86_64-linux-gnu -name libstdc++.a)
    # ------
    cmakeParams_osg=( 
    # "-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH" 
    # "-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH" # BOTH ：先查根路径，再查系统路径    
    # "-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH" # 头文件仍只查根路径 
    # 是否访问 /usr/include/、/usr/lib/ 等 系统路径   
    "-DCMAKE_FIND_USE_CMAKE_SYSTEM_PATH=ON"
    # 是否访问PATH\LD_LIBRARY_PATH等环境变量
    "-DCMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH=ON" 
    )

    # ------
    echo "=== cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib}  --debug-find ......"
    # --debug-find    --debug-output   --trace-expand 
    Freetype_DIR=${SrcDIR_lib}/CMakeModules  \
    cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib}  --debug-find  \
            "${cmakeCommonParams[@]}"  "${cmakeParams_osg[@]}" \
            -DCMAKE_FIND_LIBRARY_SUFFIXES=".a"     \
            -DCMAKE_PREFIX_PATH="${cmk_prefixPath}" \
            -DCMAKE_MODULE_PATH="${osg_MODULE_PATH}" \
            -DCMAKE_FIND_LIBRARY_SUFFIXES=".a"        \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_osg}    \
            -DCMAKE_C_FLAGS="-fPIC  -DOSG_GL3_AVAILABLE=1"   \
            -DCMAKE_CXX_FLAGS="-fPIC -std=c++14  -DOSG_GL3_AVAILABLE=1" \
            -DCMAKE_LIBRARY_PATH="/usr/lib/gcc/x86_64-linux-gnu/" \
            -DCMAKE_INCLUDE_PATH="/usr/include/"                   \
            -DCMAKE_DEBUG_POSTFIX=""   \
        -DDYNAMIC_OPENTHREADS=OFF   \
        -DDYNAMIC_OPENSCENEGRAPH=OFF \
        -DANDROID=OFF                 \
        -DOSG_GL1_AVAILABLE=OFF   \
        -DOSG_GL2_AVAILABLE=OFF   \
        -DOSG_GL3_AVAILABLE=ON    \
        -DOSG_GLES1_AVAILABLE=OFF \
        -DOSG_GLES2_AVAILABLE=OFF \
        -DOSG_GLES3_AVAILABLE=OFF \
        -DOSG_GL_LIBRARY_STATIC=OFF        \
        -DOSG_GL_DISPLAYLISTS_AVAILABLE=OFF \
        -DOSG_GL_MATRICES_AVAILABLE=OFF      \
        -DOSG_GL_VERTEX_FUNCS_AVAILABLE=OFF   \
        -DOSG_GL_VERTEX_ARRAY_FUNCS_AVAILABLE=OFF \
        -DOSG_GL_FIXED_FUNCTION_AVAILABLE=OFF      \
        -DOPENGL_PROFILE="GL3" \
        -DEGL_INCLUDE_DIR=/usr/include/EGL                    \
        -DEGL_LIBRARY=/usr/lib/x86_64-linux-gnu/libEGL.so      \
        -DOPENGL_EGL_INCLUDE_DIR=/usr/include/EGL               \
        -DOPENGL_INCLUDE_DIR=/usr/include/                       \
        -DOPENGL_gl_LIBRARY=/usr/lib/x86_64-linux-gnu/libGL.so    \
        -DOPENGL_glu_LIBRARY="/usr/lib/x86_64-linux-gnu/libGLU.so" \
        -DPKG_CONFIG_EXECUTABLE=/usr/bin/pkg-config   \
        -DOSG_FIND_3RD_PARTY_DEPS=ON  \
        -DZLIB_USE_STATIC_LIBS=ON \
        -DZLIB_DIR=${SrcDIR_lib}/CMakeModules             \
        -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include  \
        -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a    \
        -DZLIB_LIBRARIES="${INSTALL_PREFIX_zlib}/lib/libz.a" \
        -DJPEG_DIR=${INSTALL_PREFIX_jpegTurbo}/lib/cmake/libjpeg-turbo \
        -DJPEG_INCLUDE_DIR=${INSTALL_PREFIX_jpegTurbo}/include/libjpeg  \
        -DJPEG_LIBRARY=${INSTALL_PREFIX_jpegTurbo}/lib/libjpeg.a         \
        -DJPEG_LIBRARIES=${INSTALL_PREFIX_jpegTurbo}/lib/libjpeg.a        \
        -DPNG_INCLUDE_DIR=${INSTALL_PREFIX_png}/include/libpng16 \
        -DPNG_LIBRARY=${INSTALL_PREFIX_png}/lib/libpng.a          \
        -DPNG_LIBRARIES=${INSTALL_PREFIX_png}/lib/libpng.a         \
        -DOpenSSL_DIR="${INSTALL_PREFIX_openssl}/lib64/cmake/OpenSSL"  \
        -DOpenSSL_ROOT="${INSTALL_PREFIX_openssl}"                      \
        -DOpenSSL_USE_STATIC_LIBS=ON                                     \
        -DOPENSSL_INCLUDE_DIR=${INSTALL_PREFIX_openssl}/include            \
        -DOPENSSL_SSL_LIBRARY=${INSTALL_PREFIX_openssl}/lib64/libssl.a      \
        -DOPENSSL_CRYPTO_LIBRARY=${INSTALL_PREFIX_openssl}/lib64/libcrypto.a \
        -DPROJ_INCLUDE_DIR=${INSTALL_PREFIX_proj}/include \
        -DPROJ_LIBRARY=${INSTALL_PREFIX_proj}/lib/libproj.a \
        -DTIFF_INCLUDE_DIR=${INSTALL_PREFIX_tiff}/include   \
        -DTIFF_LIBRARY=${INSTALL_PREFIX_tiff}/lib/libtiff.a  \
        -DTIFF_LIBRARIES=${INSTALL_PREFIX_tiff}/lib/libtiff.a \
        -DFreetype_DIR=${SrcDIR_lib}/CMakeModules                          \
        -DFREETYPE_INCLUDE_DIR=${INSTALL_PREFIX_freetype}/include           \
        -DFREETYPE_INCLUDE_DIRS=${INSTALL_PREFIX_freetype}/include/freetype2 \
        -DFREETYPE_LIBRARY=${INSTALL_PREFIX_freetype}/lib/libfreetyped.a      \
        -DFREETYPE_LIBRARIES=${INSTALL_PREFIX_freetype}/lib/libfreetyped.a     \
        -DSQLite3_INCLUDE_DIR=${INSTALL_PREFIX_sqlite}/include       \
        -DSQLite3_LIBRARY=${INSTALL_PREFIX_sqlite}/lib/libsqlite3.a   \
        -DSQLite3_LIBRARIES=${INSTALL_PREFIX_sqlite}/lib/libsqlite3.a  \
        -DGEOS_DIR="${INSTALL_PREFIX_geos}/lib/cmake/GEOS/"  \
        -Dgeos_DIR="${INSTALL_PREFIX_geos}/lib/cmake/GEOS/"  \
        -DGEOS_INCLUDE_DIR=${INSTALL_PREFIX_geos}/include  \
        -DGEOS_LIBRARY="${INSTALL_PREFIX_geos}/lib/libgeos_c.a;${INSTALL_PREFIX_geos}/lib/libgeos.a" \
        -DGEOS_CXX_LIBRARY="${INSTALL_PREFIX_geos}/lib/libgeos.a" \
        -DCURL_DIR="${INSTALL_PREFIX_curl}/lib/cmake/CURL" \
        -DCURL_LIBRARY=CURL::libcurl   \
        -DCURL_LIBRARIES="${_curlLibs}" \
        -DGDAL_DIR=${SrcDIR_lib}/CMakeModules               \
        -DGDAL_INCLUDE_DIR=${INSTALL_PREFIX_gdal}/include    \
        -DGDAL_LIBRARY=${INSTALL_PREFIX_gdal}/lib/libgdal.a   \
        -DGDAL_LIBRARIES=${INSTALL_PREFIX_gdal}/lib/libgdal.a  \
        -DNO_DEFAULT_PATH=ON \
        -DCMAKE_EXE_LINKER_FLAGS=" \
            -Wl,-Bdynamic -lm -lc -lGL -lGLU -ldl \
            -Wl,--no-as-needed -lX11 -lXext"
        

        # (1)关于-DCURL_LIBRARY="CURL::libcurl" ：
        #  -DCURL_LIBRARY="${INSTALL_PREFIX_curl}/lib/libcurl-d.a"  ## 根据一般的规则，ok
        #  -DCURL_LIBRARIES="CURL::libcurl" ## 根据一般的规则，ok
        #  -DCURL_LIBRARY="CURL::libcurl" ##  特定于osg项目，是ok的，因为osg/src/osgPlugins/curl/CMakeLists.txt中
        #     ## SET(TARGET_LIBRARIES_VARS   CURL_LIBRARY     ZLIB_LIBRARIES)用的是CURL_LIBRARY而不是CURL_LIBRARIES

        # -DCMAKE_EXE_LINKER_FLAGS="${_exeLinkerFlags}" 
        # (2) -Wl,--whole-archive /usr/lib/gcc/x86_64-linux-gnu/11/libstdc++.a -Wl,--no-whole-archive
        #    等价于 -static-libstdc++
        # (3)Glibc 的某些函数（如网络相关）在静态链接时需要动态库支持,使用libc.a和libm.a会导致 collect2: error: ld returned 1 exit status
        #     
        # (4) *****修改 3rd/osg/packaging/cmake/OpenSceneGraphConfig.cmake.in *****：
        # ```
        # if(TARGET @PKG_NAMESPACE@::${component})
        #     # This component has already been found, so we'll skip it
        #     set(OpenSceneGraph_${component}_FOUND TRUE)
        #     set(OPENSCENEGRAPH_${component}_FOUND TRUE)
        #     # continue() ## ************************** 注掉这一行 ***********************
        # endif()
        # ```        
        #  
        # (5) osg/src/osgPlugins/png/CMakeLists.txt中强制 SET(TARGET_LIBRARIES_VARS PNG_LIBRARY ZLIB_LIBRARIES )
        #    而 lib/cmake/PNG/PNGConfig.cmake 中 没提供PNG_LIBRARY
        #    所以 cmake -S -B 必须添加 -DPNG_LIBRARY=${INSTALL_PREFIX_png}/lib/libpng.a
        # (6)针对cmakeCommonParams，特化设置：
        #    -DEGL_LIBRARY=  -DEGL_INCLUDE_DIR=  -DEGL_LIBRARY= 
        #    -DOPENGL_EGL_INCLUDE_DIR=  -DOPENGL_INCLUDE_DIR=  -DOPENGL_gl_LIBRARY=
        #    -DPKG_CONFIG_EXECUTABLE= 

        # -DBoost_ROOT=${INSTALL_PREFIX_boost}  \ ## 现代CMake（>=3.12）官方标准
        # -DBOOST_ROOT=${INSTALL_PREFIX_boost}  \ ## 旧版兼容（FindBoost.cmake传统方式）
        
        #
        # -DCMAKE_STATIC_LINKER_FLAGS=${_LINKER_FLAGS}  
 
    echo "=== cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v"
    cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v
    
    echo "=== cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE} --verbose"
    cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}   --verbose  
    #################################################################### 
    echo "========== finished building osg 4 ubuntu ========== " &&  sleep 1 

fi    

# -------------------------------------------------
# osg-DLL 
# ----- 
# only for debug
# -------------------------------------------------
INSTALL_PREFIX_osgdll=${INSTALL_PREFIX_ubt}/osgdll

if [ "${isFinished_build_osgdll}" != "true" ] ; then 
    echo "========== building osgdll 4 ubuntu========== " &&  sleep 1

    SrcDIR_lib=${SrcDIR_3rd}/osg
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/osgdll
    echo "gg====         SrcDIR_lib=${SrcDIR_lib}" 
    echo "gg====       BuildDIR_lib=${BuildDIR_lib}" 
    echo "gg==== INSTALL_PREFIX_osgdll=${INSTALL_PREFIX_osgdll}" 
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_osgdll} ${isRebuild}  

    #################################################################### 
    cmk_prefixPath=$(check_concat_paths_1  "${INSTALL_PREFIX_xz}" \
            "${INSTALL_PREFIX_absl}" "${INSTALL_PREFIX_zstd}"\
            "${INSTALL_PREFIX_png}"  "${INSTALL_PREFIX_jpegTurbo}"  \
            "${INSTALL_PREFIX_openssl}" "${INSTALL_PREFIX_tiff}" \
            "${INSTALL_PREFIX_geos}"  "${INSTALL_PREFIX_psl}"\
            "${INSTALL_PREFIX_proj}"  "${INSTALL_PREFIX_expat}"  \
            "${INSTALL_PREFIX_curl}" "${INSTALL_PREFIX_sqlite}"  \
            "${INSTALL_PREFIX_boost}" ) 
    echo "==========cmk_prefixPath=${cmk_prefixPath}"   
    # <<osg的间接依赖库>> osg -->gdal-->curl-->libpsl 
    _curlLibs="${INSTALL_PREFIX_curl}/lib/libcurl-d.a;"
    _curlLibs="${_curlLibs} ${INSTALL_PREFIX_openssl}/lib64/libssl.a;"
    _curlLibs="${_curlLibs} ${INSTALL_PREFIX_openssl}/lib64/libcrypto.a;"
    _curlLibs="${_curlLibs} ${INSTALL_PREFIX_psl}/lib/libpsl.a;"
    _curlLibs="${_curlLibs} ${INSTALL_PREFIX_zstd}/lib/libzstd.a"
    _curlLibs="${_curlLibs} ${INSTALL_PREFIX_zlib}/lib/libz.a"
    echo "gg==========_curlLibs=${_curlLibs}" 
 
    #  zlib // freetype // gdal 的搜索优先使用 3rd/osg/CMakeLists.txt里的 CMAKE_MODULE_PATH
    osg_MODULE_PATH=""
    # ------
    libstdcxx_a_path=$(find /usr/lib/gcc/x86_64-linux-gnu -name libstdc++.a)
    # ------
    cmakeParams_osg=( 
    # "-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH" 
    # "-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH" # BOTH ：先查根路径，再查系统路径    
    # "-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH" # 头文件仍只查根路径 
    # 是否访问 /usr/include/、/usr/lib/ 等 系统路径   
    "-DCMAKE_FIND_USE_CMAKE_SYSTEM_PATH=ON"
    # 是否访问PATH\LD_LIBRARY_PATH等环境变量
    "-DCMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH=ON" 
    )

    # ------
    echo "=== cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib}  --debug-find ......"
    # --debug-find    --debug-output   --trace-expand 
    Freetype_DIR=${SrcDIR_lib}/CMakeModules  \
    cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib}  --debug-find  \
            "${cmakeCommonParams[@]}"  "${cmakeParams_osg[@]}" \
            -DCMAKE_FIND_LIBRARY_SUFFIXES=".a;.so"     \
            -DCMAKE_PREFIX_PATH="${cmk_prefixPath}" \
            -DCMAKE_MODULE_PATH="${osg_MODULE_PATH}" \
            -DCMAKE_FIND_LIBRARY_SUFFIXES=".a;.so"        \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_osgdll}    \
            -DCMAKE_C_FLAGS="-fPIC  -DOSG_GL3_AVAILABLE=1"   \
            -DCMAKE_CXX_FLAGS="-fPIC -std=c++14  -DOSG_GL3_AVAILABLE=1" \
            -DCMAKE_LIBRARY_PATH="/usr/lib/gcc/x86_64-linux-gnu/" \
            -DCMAKE_INCLUDE_PATH="/usr/include/"                   \
            -DCMAKE_DEBUG_POSTFIX=""   \
        -DBUILD_SHARED_LIBS=ON  \
        -DDYNAMIC_OPENTHREADS=ON    -DDYNAMIC_OPENSCENEGRAPH=ON \
        -DANDROID=OFF                 \
        -DOSG_GL1_AVAILABLE=OFF   \
        -DOSG_GL2_AVAILABLE=OFF   \
        -DOSG_GL3_AVAILABLE=ON    \
        -DOSG_GLES1_AVAILABLE=OFF \
        -DOSG_GLES2_AVAILABLE=OFF \
        -DOSG_GLES3_AVAILABLE=OFF \
        -DOSG_GL_LIBRARY_STATIC=OFF        \
        -DOSG_GL_DISPLAYLISTS_AVAILABLE=OFF \
        -DOSG_GL_MATRICES_AVAILABLE=OFF      \
        -DOSG_GL_VERTEX_FUNCS_AVAILABLE=OFF   \
        -DOSG_GL_VERTEX_ARRAY_FUNCS_AVAILABLE=OFF \
        -DOSG_GL_FIXED_FUNCTION_AVAILABLE=OFF      \
        -DOPENGL_PROFILE="GL3" \
        -DEGL_INCLUDE_DIR=/usr/include/EGL                    \
        -DEGL_LIBRARY=/usr/lib/x86_64-linux-gnu/libEGL.so      \
        -DOPENGL_EGL_INCLUDE_DIR=/usr/include/EGL               \
        -DOPENGL_INCLUDE_DIR=/usr/include/                       \
        -DOPENGL_gl_LIBRARY=/usr/lib/x86_64-linux-gnu/libGL.so    \
        -DOPENGL_glu_LIBRARY="/usr/lib/x86_64-linux-gnu/libGLU.so" \
        -DPKG_CONFIG_EXECUTABLE=/usr/bin/pkg-config   \
        -DOSG_FIND_3RD_PARTY_DEPS=ON  \
        -DZLIB_USE_STATIC_LIBS=ON \
        -DZLIB_DIR=${SrcDIR_lib}/CMakeModules             \
        -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include  \
        -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a    \
        -DZLIB_LIBRARIES="${INSTALL_PREFIX_zlib}/lib/libz.a" \
        -DJPEG_DIR=${INSTALL_PREFIX_jpegTurbo}/lib/cmake/libjpeg-turbo \
        -DJPEG_INCLUDE_DIR=${INSTALL_PREFIX_jpegTurbo}/include/libjpeg  \
        -DJPEG_LIBRARY=${INSTALL_PREFIX_jpegTurbo}/lib/libjpeg.a         \
        -DJPEG_LIBRARIES=${INSTALL_PREFIX_jpegTurbo}/lib/libjpeg.a        \
        -DPNG_INCLUDE_DIR=${INSTALL_PREFIX_png}/include/libpng16 \
        -DPNG_LIBRARY=${INSTALL_PREFIX_png}/lib/libpng.a          \
        -DPNG_LIBRARIES=${INSTALL_PREFIX_png}/lib/libpng.a         \
        -DOpenSSL_DIR="${INSTALL_PREFIX_openssl}/lib64/cmake/OpenSSL"  \
        -DOpenSSL_ROOT="${INSTALL_PREFIX_openssl}"                      \
        -DOpenSSL_USE_STATIC_LIBS=ON                                     \
        -DOPENSSL_INCLUDE_DIR=${INSTALL_PREFIX_openssl}/include            \
        -DOPENSSL_SSL_LIBRARY=${INSTALL_PREFIX_openssl}/lib64/libssl.a      \
        -DOPENSSL_CRYPTO_LIBRARY=${INSTALL_PREFIX_openssl}/lib64/libcrypto.a \
        -DPROJ_INCLUDE_DIR=${INSTALL_PREFIX_proj}/include \
        -DPROJ_LIBRARY=${INSTALL_PREFIX_proj}/lib/libproj.a \
        -DTIFF_INCLUDE_DIR=${INSTALL_PREFIX_tiff}/include   \
        -DTIFF_LIBRARY=${INSTALL_PREFIX_tiff}/lib/libtiff.a  \
        -DTIFF_LIBRARIES=${INSTALL_PREFIX_tiff}/lib/libtiff.a \
        -DFreetype_DIR=${SrcDIR_lib}/CMakeModules                          \
        -DFREETYPE_INCLUDE_DIR=${INSTALL_PREFIX_freetype}/include           \
        -DFREETYPE_INCLUDE_DIRS=${INSTALL_PREFIX_freetype}/include/freetype2 \
        -DFREETYPE_LIBRARY=${INSTALL_PREFIX_freetype}/lib/libfreetyped.a      \
        -DFREETYPE_LIBRARIES=${INSTALL_PREFIX_freetype}/lib/libfreetyped.a     \
        -DSQLite3_INCLUDE_DIR=${INSTALL_PREFIX_sqlite}/include       \
        -DSQLite3_LIBRARY=${INSTALL_PREFIX_sqlite}/lib/libsqlite3.a   \
        -DSQLite3_LIBRARIES=${INSTALL_PREFIX_sqlite}/lib/libsqlite3.a  \
        -DGEOS_DIR="${INSTALL_PREFIX_geos}/lib/cmake/GEOS/"  \
        -Dgeos_DIR="${INSTALL_PREFIX_geos}/lib/cmake/GEOS/"  \
        -DGEOS_INCLUDE_DIR=${INSTALL_PREFIX_geos}/include  \
        -DGEOS_LIBRARY="${INSTALL_PREFIX_geos}/lib/libgeos_c.a;${INSTALL_PREFIX_geos}/lib/libgeos.a" \
        -DGEOS_CXX_LIBRARY="${INSTALL_PREFIX_geos}/lib/libgeos.a" \
        -DCURL_DIR="${INSTALL_PREFIX_curl}/lib/cmake/CURL" \
        -DCURL_LIBRARY=CURL::libcurl   \
        -DCURL_LIBRARIES="${_curlLibs}" \
        -DGDAL_DIR=${SrcDIR_lib}/CMakeModules               \
        -DGDAL_INCLUDE_DIR=${INSTALL_PREFIX_gdal}/include    \
        -DGDAL_LIBRARY=${INSTALL_PREFIX_gdal}/lib/libgdal.a   \
        -DGDAL_LIBRARIES=${INSTALL_PREFIX_gdal}/lib/libgdal.a  \
        -DNO_DEFAULT_PATH=ON \
        -DCMAKE_EXE_LINKER_FLAGS=" \
            -Wl,-Bdynamic -lm -lc -lGL -lGLU -ldl \
            -Wl,--no-as-needed -lX11 -lXext"
        
  
    echo "=== cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v"
    cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v
    
    echo "=== cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE} --verbose"
    cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}   --verbose  
    #################################################################### 
    echo "========== finished building osgdll 4 ubuntu ========== " &&  sleep 1 

fi    

 
# -------------------------------------------------
# libzip 
# ------------------------------------------------- 
INSTALL_PREFIX_zip=${INSTALL_PREFIX_ubt}/libzip

if [ "${isFinished_build_zip}" != "true" ]; then 
    echo "========== building libzip 4 ubuntu========== " &&  sleep 3
    SrcDIR_lib=${SrcDIR_3rd}/libzip 
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/libzip     
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_zip} ${isRebuild} 
 
    ####################################################################  
    # "${INSTALL_PREFIX_xz}" "${INSTALL_PREFIX_zstd}" "${INSTALL_PREFIX_openssl}" 
    cmk_prefixPath="${INSTALL_PREFIX_zlib}"  
    echo "==========cmk_prefixPath=${cmk_prefixPath}"   

    cmake -S ${SrcDIR_lib}  -B ${BuildDIR_lib} --debug-find \
            -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
            -DCMAKE_PREFIX_PATH="${cmk_prefixPath}" \
            -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
            -DCMAKE_FIND_PACKAGE_PREFER_CONFIG=ON \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_zip}  \
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}   \
            -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}    \
            -DCMAKE_C_FLAGS="-fPIC"  \
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
    echo "========== finished building libzip 4 ubuntu ========== " &&  sleep 2
fi
 
 
# -------------------------------------------------
# osgearth 
# -------------------------------------------------
INSTALL_PREFIX_osgearth=${INSTALL_PREFIX_ubt}/osgearth

if [ "${isFinished_build_osgearth}" != "true" ] ; then 
    echo "========== building osgearth 4 ubuntu========== " &&  sleep 1  && set -x

    SrcDIR_lib=${SrcDIR_3rd}/osgearth
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/osgearth
    echo "gg====             SrcDIR_lib=${SrcDIR_lib}" 
    echo "gg====           BuildDIR_lib=${BuildDIR_lib}" 
    echo "gg====INSTALL_PREFIX_osgearth=${INSTALL_PREFIX_osgearth}" 
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_osgearth} ${isRebuild}  

    #################################################################### 
    export PKG_CONFIG_PATH="${INSTALL_PREFIX_osg}/lib/pkgconfig:$PKG_CONFIG_PATH"

    #---- osgEarth -> Protobuf -> (absl + utf8_range)
    #  
    cmk_prefixPath=$(check_concat_paths_1  ${INSTALL_PREFIX_zlib} \
            "${INSTALL_PREFIX_zip}"      "${INSTALL_PREFIX_xz}"   \
            "${INSTALL_PREFIX_absl}"     "${INSTALL_PREFIX_zstd}" \
            "${INSTALL_PREFIX_png}"      "${INSTALL_PREFIX_jpegTurbo}"   \
            "${INSTALL_PREFIX_protobuf}" "${INSTALL_PREFIX_openssl}"     \
            "${INSTALL_PREFIX_tiff}"     "${INSTALL_PREFIX_geos}"      \
            "${INSTALL_PREFIX_psl}"      "${INSTALL_PREFIX_proj}"        \
            "${INSTALL_PREFIX_expat}"    "${INSTALL_PREFIX_freetype}"    \
            "${INSTALL_PREFIX_curl}"     "${INSTALL_PREFIX_sqlite}"      \
            "${INSTALL_PREFIX_gdal}"     "${INSTALL_PREFIX_osg}" )
    echo "oearth...cmk_prefixPath=${cmk_prefixPath}"   
    
    # ----
    osgearth_MODULE_PATH="${INSTALL_PREFIX_zlib}/lib/cmake/zlib"  
    echo "oearth...osgearth_MODULE_PATH=${osgearth_MODULE_PATH}"    

    # ----
    cmakeParams_osgearth=(  
    "-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH" # BOTH：先查根路径，再查系统路径    
    "-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH"  
    # "-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER"
    # 是否访问 /usr/include/、/usr/lib/ 等 系统路径   
    "-DCMAKE_FIND_USE_CMAKE_SYSTEM_PATH=ON" 
  
#   "-DCMAKE_FIND_PACKAGE_PREFER_CONFIG=OFF"        
    )
    # 2. 清理环境
    unset LD_LIBRARY_PATH
    unset LIBRARY_PATH
    # (1)/usr/share/cmake-3.28/Modules/FindGLEW.cmake中需要用 ENV GLEW_ROOT。
    # (2)在 CMake 命令行中临时设置环境变量（一次性生效），格式为 
    #   GLEW_ROOT=/path/to/GLEW cmake ...  ，无需提前 export。 

                # "${cmakeCommonParams[@]}"  

    # --debug-find    --debug-output 
    GLEW_ROOT="/usr/lib/x86_64-linux-gnu/" \
    cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib}  --debug-find   \
            "${cmakeCommonParams[@]}"  "${cmakeParams_osgearth[@]}" \
            -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
            -DCMAKE_PREFIX_PATH="${cmk_prefixPath}" \
            -DCMAKE_MODULE_PATH=${osgearth_MODULE_PATH} \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_osgearth}  \
            -DCMAKE_C_FLAGS="-fPIC -fdiagnostics-show-option -DOSG_GL3_AVAILABLE=1 -U GDAL_DEBUG -DOSGEARTH_LIBRARY=1"   \
            -DCMAKE_CXX_FLAGS="-fPIC -fdiagnostics-show-option -DOSG_GL3_AVAILABLE=1 -U GDAL_DEBUG -DOSGEARTH_LIBRARY=1" \
            -DBUILD_SHARED_LIBS=OFF   \
        -DNRL_STATIC_LIBRARIES=ON  -DOSGEARTH_BUILD_SHARED_LIBS=OFF \
        -DCMAKE_SKIP_RPATH=ON  \
        -DANDROID=OFF \
        -DDYNAMIC_OPENTHREADS=OFF     -DDYNAMIC_OPENSCENEGRAPH=OFF \
        -DOSGEARTH_ENABLE_FASTDXT=OFF \
        -DOSGEARTH_BUILD_TOOLS=ON    -DOSGEARTH_BUILD_EXAMPLES=ON   \
        -DOSGEARTH_BUILD_IMGUI_NODEKIT=OFF \
        -DOSG_GL1_AVAILABLE=OFF \
        -DOSG_GL2_AVAILABLE=OFF  \
        -DOSG_GL3_AVAILABLE=ON    \
        -DOSG_GLES1_AVAILABLE=OFF  \
        -DOSG_GLES2_AVAILABLE=OFF   \
        -DOSG_GLES3_AVAILABLE=OFF    \
        -DOSG_GL_LIBRARY_STATIC=OFF        \
        -DOSG_GL_DISPLAYLISTS_AVAILABLE=OFF \
        -DOSG_GL_MATRICES_AVAILABLE=OFF      \
        -DOSG_GL_VERTEX_FUNCS_AVAILABLE=OFF   \
        -DOSG_GL_VERTEX_ARRAY_FUNCS_AVAILABLE=OFF \
        -DOSG_GL_FIXED_FUNCTION_AVAILABLE=OFF      \
        -DOPENGL_PROFILE="GL3" \
        -DGLEW_USE_STATIC_LIBS=OFF \
        -DMATH_LIBRARY="/usr/lib/x86_64-linux-gnu/libm.so" \
        -DEGL_LIBRARY=/usr/lib/x86_64-linux-gnu/libEGL.so   \
        -DEGL_INCLUDE_DIR=/usr/include/EGL                   \
        -DEGL_LIBRARY=/usr/lib/x86_64-linux-gnu/libEGL.so     \
        -DOPENGL_EGL_INCLUDE_DIR=/usr/include/EGL              \
        -DOPENGL_INCLUDE_DIR=/usr/include/GL                    \
        -DOPENGL_gl_LIBRARY=/usr/lib/x86_64-linux-gnu/libGL.so   \
        -DPKG_CONFIG_EXECUTABLE=/usr/bin/pkg-config               \
        -DOpenSceneGraph_FIND_QUIETLY=OFF  \
        -DOSG_DIR=${INSTALL_PREFIX_osg}     \
        -DOPENSCENEGRAPH_INCLUDE_DIR=${INSTALL_PREFIX_osg}/include \
        -DZLIB_ROOT_DIR="${INSTALL_PREFIX_zlib}"  \
        -DZSTD_LIBRARY="${INSTALL_PREFIX_zstd}/lib/libzstd.a"  \
        -DZLIB_INCLUDE_DIR="${INSTALL_PREFIX_zlib}/include" \
        -DZLIB_LIBRARY="${INSTALL_PREFIX_zlib}/lib/libz.a"   \
        -DPNG_INCLUDE_DIR="${INSTALL_PREFIX_png}/include/"   \
        -DPNG_LIBRARY="${INSTALL_PREFIX_png}/lib/libpng.a"   \
        -DJPEG_INCLUDE_DIR=${INSTALL_PREFIX_jpegTurbo}/include  \
        -DJPEG_LIBRARY=${INSTALL_PREFIX_jpegTurbo}/lib/libjpeg.a \
        -DTIFF_INCLUDE_DIR=${INSTALL_PREFIX_tiff}/include  \
        -DTIFF_LIBRARY=${INSTALL_PREFIX_tiff}/lib/libtiff.a \
        -DFREETYPE_ROOT=${INSTALL_PREFIX_freetype}                    \
        -DFREETYPE_INCLUDE_DIR=${INSTALL_PREFIX_freetype}/include      \
        -DFREETYPE_LIBRARY=${INSTALL_PREFIX_freetype}/lib/libfreetyped.a \
        -DCURL_ROOT=${INSTALL_PREFIX_curl}                  \
        -DCURL_INCLUDE_DIR=${INSTALL_PREFIX_curl}/include    \
        -DCURL_LIBRARY=${INSTALL_PREFIX_curl}/lib/libcurl-d.a \
        -DSQLite3_INCLUDE_DIR=${INSTALL_PREFIX_sqlite}/include     \
        -DSQLite3_LIBRARIES=${INSTALL_PREFIX_sqlite}/lib/libsqlite3.a \
        -DGEOS_DIR="${INSTALL_PREFIX_geos}/lib/cmake/GEOS/"  \
        -Dgeos_DIR="${INSTALL_PREFIX_geos}/lib/cmake/GEOS/"  \
        -DGEOS_INCLUDE_DIR=${INSTALL_PREFIX_geos}/include  \
        -DPROJ_INCLUDE_DIR=${INSTALL_PREFIX_proj}/include  \
        -DPROJ_LIBRARY=${INSTALL_PREFIX_proj}/lib/libproj.a \
        -DPROJ4_LIBRARY=${INSTALL_PREFIX_proj}/lib/libproj.a \
        -DGDAL_ROOT=${INSTALL_PREFIX_gdal}                \
        -DGDAL_INCLUDE_DIR=${INSTALL_PREFIX_gdal}/include  \
        -DGDAL_LIBRARY=${INSTALL_PREFIX_gdal}/lib/libgdal.a \
        -DOpenSSL_DIR="${INSTALL_PREFIX_openssl}/lib64/cmake/OpenSSL"     \
        -DOPENSSL_SSL_LIBRARY=${INSTALL_PREFIX_openssl}/lib64/libssl.a     \
        -DSSL_EAY_RELEASE=${INSTALL_PREFIX_openssl}/lib64/libssl.a          \
        -DOPENSSL_CRYPTO_LIBRARY=${INSTALL_PREFIX_openssl}/lib64/libcrypto.a \
        -Dabsl_DIR="${INSTALL_PREFIX_protobuf}/lib/cmake/absl/"           \
        -Dutf8_range_DIR="${INSTALL_PREFIX_protobuf}/lib/cmake/utf8_range" \
        -Dprotobuf_DIR="${INSTALL_PREFIX_protobuf}/lib/cmake/protobuf/"     \
        -DLIB_EAY_RELEASE=""  \
        -DCMAKE_EXE_LINKER_FLAGS=" \
          -Wl,--whole-archive  -fvisibility=hidden   -Wl,--no-whole-archive   \
          -Wl,-Bdynamic -lstdc++  -lGL -lGLU -ldl -lm -lc -lpthread -lrt     \
          -Wl,--no-as-needed -lX11 -lXext "  
 
 
        # -DGEOS_DIR=${INSTALL_PREFIX_geos}/lib/cmake/GEOS  \
        # (0) osgearth 编译时发生 类型转换错误​​（invalid conversion from 'void*' to 'OGRLayerH'）,
        #     用-DCMAKE_C_FLAGS="-U GDAL_DEBUG" 解决

        # (1)   GDAL -->|依赖| GEOS_C[libgeos_c.a] -->|依赖| GEOS[libgeos.a] -->|依赖| stdc++[libstdc++]
        #  osgearth ->GEOS::geos_c ; osgearth -> gdal -> GEOS::GEOS
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
        # (4)
        #  -DPROTOBUF_LIBRARY=${INSTALL_PREFIX_protobuf}/lib/libprotobuf.a \
        #  -DPROTOBUF_INCLUDE_DIR=${INSTALL_PREFIX_protobuf}/include        \
    echo "ee====cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v" 
    cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v
    
    echo "cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}" 
    cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}     
    #################################################################### 
    echo "========== finished building osgearth 4 ubuntu ========== "   && set +x

fi    


# -------------------------------------------------
# oearthdll
# -------------------------------------------------
INSTALL_PREFIX_oearthdll=${INSTALL_PREFIX_ubt}/osgearthdll

if [ "${isFinished_build_oearthdll}" != "true" ] ; then 
    echo "========== building oearthdll 4 ubuntu========== " &&  sleep 1  && set -x

    SrcDIR_lib=${SrcDIR_3rd}/osgearth
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/osgearthdll
    echo "gg====             SrcDIR_lib=${SrcDIR_lib}" 
    echo "gg====            BuildDIR_lib=${BuildDIR_lib}" 
    echo "gg==== INSTALL_PREFIX_oearthdll=${INSTALL_PREFIX_oearthdll}" 
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_oearthdll} ${isRebuild}  

    #################################################################### 
    export PKG_CONFIG_PATH="${INSTALL_PREFIX_osgdll}/lib/pkgconfig:$PKG_CONFIG_PATH"

    #---- osgEarth -> Protobuf -> (absl + utf8_range)
    #  
    cmk_prefixPath=$(check_concat_paths_1  ${INSTALL_PREFIX_zlib} \
            "${INSTALL_PREFIX_zip}"      "${INSTALL_PREFIX_xz}"   \
            "${INSTALL_PREFIX_absl}"     "${INSTALL_PREFIX_zstd}" \
            "${INSTALL_PREFIX_png}"      "${INSTALL_PREFIX_jpegTurbo}"   \
            "${INSTALL_PREFIX_protobuf}" "${INSTALL_PREFIX_openssl}"     \
            "${INSTALL_PREFIX_tiff}"     "${INSTALL_PREFIX_geos}"      \
            "${INSTALL_PREFIX_psl}"      "${INSTALL_PREFIX_proj}"        \
            "${INSTALL_PREFIX_expat}"    "${INSTALL_PREFIX_freetype}"    \
            "${INSTALL_PREFIX_curl}"     "${INSTALL_PREFIX_sqlite}"      \
            "${INSTALL_PREFIX_gdal}"     "${INSTALL_PREFIX_osgdll}" )
    echo "oearth...cmk_prefixPath=${cmk_prefixPath}"   
    
    # ----
    osgearth_MODULE_PATH="${INSTALL_PREFIX_zlib}/lib/cmake/zlib"  
    echo "oearth...osgearth_MODULE_PATH=${osgearth_MODULE_PATH}"    

    # ----
    cmakeParams_osgearth=(  
    "-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH" # BOTH：先查根路径，再查系统路径    
    "-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH"  
    # "-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER"
    # 是否访问 /usr/include/、/usr/lib/ 等 系统路径   
    "-DCMAKE_FIND_USE_CMAKE_SYSTEM_PATH=ON"     
    )
    # 2. 清理环境
    unset LD_LIBRARY_PATH
    unset LIBRARY_PATH 
 

    # --debug-find    --debug-output 
    GLEW_ROOT="/usr/lib/x86_64-linux-gnu/" \
    cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib}  --debug-find   \
            "${cmakeCommonParams[@]}"  "${cmakeParams_osgearth[@]}" \
            -DCMAKE_FIND_LIBRARY_SUFFIXES=".a;.so" \
            -DCMAKE_PREFIX_PATH="${cmk_prefixPath}" \
            -DCMAKE_MODULE_PATH=${osgearth_MODULE_PATH} \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_oearthdll}  \
            -DCMAKE_C_FLAGS="-fPIC -fdiagnostics-show-option -DOSG_GL3_AVAILABLE=1 -U GDAL_DEBUG -DOSGEARTH_LIBRARY=1"   \
            -DCMAKE_CXX_FLAGS="-fPIC -fdiagnostics-show-option -DOSG_GL3_AVAILABLE=1 -U GDAL_DEBUG -DOSGEARTH_LIBRARY=1" \
            -DBUILD_SHARED_LIBS=ON   \
        -DNRL_STATIC_LIBRARIES=ON  -DOSGEARTH_BUILD_SHARED_LIBS=ON \
        -DCMAKE_SKIP_RPATH=ON  \
        -DANDROID=OFF \
        -DDYNAMIC_OPENTHREADS=ON     -DDYNAMIC_OPENSCENEGRAPH=ON \
        -DOSGEARTH_ENABLE_FASTDXT=OFF \
        -DOSGEARTH_BUILD_TOOLS=ON    -DOSGEARTH_BUILD_EXAMPLES=ON   \
        -DOSGEARTH_BUILD_IMGUI_NODEKIT=OFF \
        -DOSG_GL1_AVAILABLE=OFF \
        -DOSG_GL2_AVAILABLE=OFF  \
        -DOSG_GL3_AVAILABLE=ON    \
        -DOSG_GLES1_AVAILABLE=OFF  \
        -DOSG_GLES2_AVAILABLE=OFF   \
        -DOSG_GLES3_AVAILABLE=OFF    \
        -DOSG_GL_LIBRARY_STATIC=OFF        \
        -DOSG_GL_DISPLAYLISTS_AVAILABLE=OFF \
        -DOSG_GL_MATRICES_AVAILABLE=OFF      \
        -DOSG_GL_VERTEX_FUNCS_AVAILABLE=OFF   \
        -DOSG_GL_VERTEX_ARRAY_FUNCS_AVAILABLE=OFF \
        -DOSG_GL_FIXED_FUNCTION_AVAILABLE=OFF      \
        -DOPENGL_PROFILE="GL3" \
        -DGLEW_USE_STATIC_LIBS=OFF \
        -DMATH_LIBRARY="/usr/lib/x86_64-linux-gnu/libm.so" \
        -DEGL_LIBRARY=/usr/lib/x86_64-linux-gnu/libEGL.so   \
        -DEGL_INCLUDE_DIR=/usr/include/EGL                   \
        -DEGL_LIBRARY=/usr/lib/x86_64-linux-gnu/libEGL.so     \
        -DOPENGL_EGL_INCLUDE_DIR=/usr/include/EGL              \
        -DOPENGL_INCLUDE_DIR=/usr/include/GL                    \
        -DOPENGL_gl_LIBRARY=/usr/lib/x86_64-linux-gnu/libGL.so   \
        -DPKG_CONFIG_EXECUTABLE=/usr/bin/pkg-config               \
        -DOpenSceneGraph_FIND_QUIETLY=OFF  \
        -DOSG_DIR=${INSTALL_PREFIX_osgdll}     \
        -DOPENSCENEGRAPH_INCLUDE_DIR=${INSTALL_PREFIX_osgdll}/include \
        -DZLIB_ROOT_DIR="${INSTALL_PREFIX_zlib}"  \
        -DZSTD_LIBRARY="${INSTALL_PREFIX_zstd}/lib/libzstd.a"  \
        -DZLIB_INCLUDE_DIR="${INSTALL_PREFIX_zlib}/include" \
        -DZLIB_LIBRARY="${INSTALL_PREFIX_zlib}/lib/libz.a"   \
        -DPNG_INCLUDE_DIR="${INSTALL_PREFIX_png}/include/"   \
        -DPNG_LIBRARY="${INSTALL_PREFIX_png}/lib/libpng.a"   \
        -DJPEG_INCLUDE_DIR=${INSTALL_PREFIX_jpegTurbo}/include  \
        -DJPEG_LIBRARY=${INSTALL_PREFIX_jpegTurbo}/lib/libjpeg.a \
        -DTIFF_INCLUDE_DIR=${INSTALL_PREFIX_tiff}/include  \
        -DTIFF_LIBRARY=${INSTALL_PREFIX_tiff}/lib/libtiff.a \
        -DFREETYPE_ROOT=${INSTALL_PREFIX_freetype}                    \
        -DFREETYPE_INCLUDE_DIR=${INSTALL_PREFIX_freetype}/include      \
        -DFREETYPE_LIBRARY=${INSTALL_PREFIX_freetype}/lib/libfreetyped.a \
        -DCURL_ROOT=${INSTALL_PREFIX_curl}                  \
        -DCURL_INCLUDE_DIR=${INSTALL_PREFIX_curl}/include    \
        -DCURL_LIBRARY=${INSTALL_PREFIX_curl}/lib/libcurl-d.a \
        -DSQLite3_INCLUDE_DIR=${INSTALL_PREFIX_sqlite}/include     \
        -DSQLite3_LIBRARIES=${INSTALL_PREFIX_sqlite}/lib/libsqlite3.a \
        -DGEOS_DIR="${INSTALL_PREFIX_geos}/lib/cmake/GEOS/"  \
        -Dgeos_DIR="${INSTALL_PREFIX_geos}/lib/cmake/GEOS/"  \
        -DGEOS_INCLUDE_DIR=${INSTALL_PREFIX_geos}/include  \
        -DPROJ_INCLUDE_DIR=${INSTALL_PREFIX_proj}/include  \
        -DPROJ_LIBRARY=${INSTALL_PREFIX_proj}/lib/libproj.a \
        -DPROJ4_LIBRARY=${INSTALL_PREFIX_proj}/lib/libproj.a \
        -DGDAL_ROOT=${INSTALL_PREFIX_gdal}                \
        -DGDAL_INCLUDE_DIR=${INSTALL_PREFIX_gdal}/include  \
        -DGDAL_LIBRARY=${INSTALL_PREFIX_gdal}/lib/libgdal.a \
        -DOpenSSL_DIR="${INSTALL_PREFIX_openssl}/lib64/cmake/OpenSSL"     \
        -DOPENSSL_SSL_LIBRARY=${INSTALL_PREFIX_openssl}/lib64/libssl.a     \
        -DSSL_EAY_RELEASE=${INSTALL_PREFIX_openssl}/lib64/libssl.a          \
        -DOPENSSL_CRYPTO_LIBRARY=${INSTALL_PREFIX_openssl}/lib64/libcrypto.a \
        -Dabsl_DIR="${INSTALL_PREFIX_protobuf}/lib/cmake/absl/"           \
        -Dutf8_range_DIR="${INSTALL_PREFIX_protobuf}/lib/cmake/utf8_range" \
        -Dprotobuf_DIR="${INSTALL_PREFIX_protobuf}/lib/cmake/protobuf/"     \
        -DLIB_EAY_RELEASE=""  \
        -DCMAKE_EXE_LINKER_FLAGS=" \
          -Wl,--whole-archive  -fvisibility=hidden   -Wl,--no-whole-archive   \
          -Wl,-Bdynamic -lstdc++  -lGL -lGLU -ldl -lm -lc -lpthread -lrt     \
          -Wl,--no-as-needed -lX11 -lXext "  
  
    echo "ee====cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v" 
    cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v
    
    echo "cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}" 
    cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}     
    #################################################################### 
    echo "========== finished building oearthdll 4 ubuntu ========== "   && set +x

fi    

 
# **************************************************************************
# **************************************************************************
#  src/
# ************************************************************************** 
SrcDIR_src=${Repo_ROOT}/src 
echo "in mk4ubuntu.sh....SrcDIR_src=${SrcDIR_src}"
 