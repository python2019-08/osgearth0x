#!/bin/bash
# **************************************************************************
# false  ;;;   ./mk4ubuntu.sh  >b0sh.txt 2>&1
isRebuild=true

isFinished_build_zlib=true
isFinished_build_zstd=true
isFinished_build_openssl=true  
# isFinished_build_icu=true  
# isFinished_build_libidn2=true 
isFinished_build_libpsl=true  
isFinished_build_curl=true   # false
# isFinished_build_jpeg9f=true  
isFinished_build_libjpegTurbo=true  
isFinished_build_libpng=true 
isFinished_build_xz=true  
isFinished_build_libtiff=true 
isFinished_build_freetype=true  
isFinished_build_geos=true     # false
isFinished_build_sqlite=true  
isFinished_build_proj=true 
isFinished_build_libexpat=true  
isFinished_build_absl=true
isFinished_build_protobuf=true
isFinished_build_gdal=true
isFinished_build_osg=false


CMAKE_BUILD_TYPE=Debug #RelWithDebInfo
CMAKE_C_COMPILER=/usr/bin/gcc   # /usr/bin/musl-gcc   # /usr/bin/clang  # 
CMAKE_CXX_COMPILER=/usr/bin/g++ # /usr/bin/musl-gcc # /usr/bin/clang++  #     
# **************************************************************************
Repo_ROOT=/home/abner/abner2/zdev/nv/osgearth0x

# rm -fr ./build_by_sh   
BuildDir_ubuntu=${Repo_ROOT}/build_by_sh/ubuntu

# INSTALL_PREFIX_root
INSTALL_PREFIX_ubt=${BuildDir_ubuntu}/install
mkdir -p ${INSTALL_PREFIX_ubt} 

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
SrcDir_3rd=${Repo_ROOT}/3rd

# -------------------------------------------------
# zlib
# -------------------------------------------------
INSTALL_PREFIX_zlib=${INSTALL_PREFIX_ubt}/zlib

if [ "${isFinished_build_zlib}" != "true" ]; then 
    echo "========== building zlib 4 ubuntu========== " &&  sleep 3
    SrcDir_lib=${SrcDir_3rd}/zlib 
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/zlib     
    prepareBuilding  ${SrcDir_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_zlib} ${isRebuild} 
 
    #################################################################### 
    # remark: zlib的 CMakeLists.txt中 未通过 target_compile_definitions 显式指定 ZLIB_DEBUG 宏,
    #    可以用cmake_c_flags="-DZLIB_DEBUG=1"指定 :
    # 编译时查看详细命令
    # cmake ... -DCMAKE_C_FLAGS="-fPIC -DZLIB_DEBUG=1"
    # make -C ${BuildDIR_lib} VERBOSE=1 
    # 若输出的编译命令中包含 -DZLIB_DEBUG=1，则说明宏已成功定义。
    #----------------------------------------------------        
    cmake -S ${SrcDir_3rd}/zlib -B ${BuildDIR_lib} \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_zlib}  \
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}   \
            -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}    \
            -DCMAKE_C_FLAGS="-fPIC -DZLIB_DEBUG=1"  \
            -DCMAKE_EXE_LINKER_FLAGS="-static"   \
            -DBUILD_SHARED_LIBS=OFF     \
            -DZLIB_BUILD_SHARED=OFF \
            -DZLIB_BUILD_STATIC=ON 
             
    cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v 

    cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}
    #################################################################### 
    # cd ${BuildDIR_lib}
    # ####  --enable-debug  会自动添加 -DZLIB_DEBUG 宏）
    # CFLAGS="-fPIC" \
    # ${SrcDir_3rd}/zlib/configure \
    #             --prefix=${INSTALL_PREFIX_zlib} \
    #             --enable-debug  --static
    # 
    # make  -j$(nproc)  
    # make install
    echo "========== finished building zlib 4 ubuntu ========== " &&  sleep 2
fi
 

# -------------------------------------------------
# zstd
# -------------------------------------------------
INSTALL_PREFIX_zstd=${INSTALL_PREFIX_ubt}/zstd

if [ "${isFinished_build_zstd}" != "true" ]; then 
    echo "========== building zstd 4 ubuntu========== " &&  sleep 3
    SrcDir_lib=${SrcDir_3rd}/zstd
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/zstd
    prepareBuilding  ${SrcDir_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_zstd} ${isRebuild} 
  

    cmake -S${SrcDir_3rd}/zstd/build/cmake -B ${BuildDIR_lib} \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_zstd}  \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}   \
            -DBUILD_SHARED_LIBS=OFF     \
            -DCMAKE_C_FLAGS="-fPIC" \
            -DCMAKE_CXX_FLAGS="-fPIC" 

    cmake --build ${BuildDIR_lib} -j$(nproc)

    cmake --build ${BuildDIR_lib} --target install    

    echo "========== finished building zstd 4 ubuntu ========== " &&  sleep 2
fi    
 

# -------------------------------------------------
# openssl
# -------------------------------------------------
INSTALL_PREFIX_openssl=${INSTALL_PREFIX_ubt}/openssl

if [ "${isFinished_build_openssl}" != "true" ]; then 
    echo "========== Building openssl 4 ubuntu ========== " &&  sleep 3

    SrcDir_openssl=${SrcDir_3rd}/openssl
    BuildDIR_openssl=${BuildDir_ubuntu}/3rd/openssl
    prepareBuilding  ${SrcDir_openssl} ${BuildDIR_openssl} ${INSTALL_PREFIX_openssl} ${isRebuild}
 

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
    ${SrcDir_openssl}/Configure linux-x86_64 -d \
                --prefix=${INSTALL_PREFIX_openssl} \
                --openssldir=${INSTALL_PREFIX_openssl}/ssl  \
                no-shared \
                no-zlib \
                no-module  no-dso 

    make build_sw -j$(nproc)  V=1

    make install_sw  
    echo "========== finished building openssl 4 ubuntu ========== " &&  sleep 2
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
# -------------------------------------------------
# INSTALL_PREFIX_icu=${INSTALL_PREFIX_ubt}/icu
# 
# if [ "${isFinished_build_icu}" != "true" ] ; then 
#     echo "========== building icu 4 ubuntu==========do nothing " &&  sleep 3
# 
#     SrcDIR_lib=${SrcDir_3rd}/icu/icu4c/source/
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
#     ${SrcDir_3rd}/icu/icu4c/source/configure   \
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
#     SrcDIR_lib=${SrcDir_3rd}/libidn2
#     BuildDIR_lib=${BuildDir_ubuntu}/3rd/libidn2
#     prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_idn2} ${isRebuild}    
#  
#     cd ${SrcDIR_lib}/libidn2  && ./bootstrap
#     if [ "$?" != "0" ]; then
#         echo "libidn2/bootstrap failed. exit!!" &&  exit 1002
#     fi
# 
#     # 在构建目录中运行configure
#     cd ${BuildDIR_lib}
#  
#     CFLAGS="-fPIC" \
#     ${SrcDir_3rd}/libidn2/configure \
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

    SrcDIR_lib=${SrcDir_3rd}/libpsl
    BuildDIR_libpsl=${BuildDir_ubuntu}/3rd/libpsl 
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_libpsl} ${INSTALL_PREFIX_psl} ${isRebuild}

    cd ${SrcDir_3rd}/libpsl  && ./autogen.sh

    # 在构建目录中运行configure
    cd ${BuildDIR_libpsl} 

    # CFLAGS="-I${INSTALL_PREFIX_icu}/include/icu" \
    # LDFLAGS="-L${INSTALL_PREFIX_icu}/lib" \

    CFLAGS="-fPIC" \
    ${SrcDir_3rd}/libpsl/configure \
                --prefix=${INSTALL_PREFIX_psl} --enable-debug \
                --disable-shared \
                --enable-static  \
                --disable-runtime --enable-builtin
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
    echo "======== Building curl =========" &&  sleep 3
    SrcDIR_lib=${SrcDir_3rd}/curl
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/curl 
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_curl} ${isRebuild}              
    # ---------------------
    
    cmk_prefixPath=$(check_concat_paths  "${INSTALL_PREFIX_openssl}" \
                "${INSTALL_PREFIX_psl}" \
                "${INSTALL_PREFIX_zlib}"  "${INSTALL_PREFIX_zstd}" )
 
    cmake -S ${SrcDir_3rd}/curl -B ${BuildDIR_lib} --debug-find \
            -DCMAKE_PREFIX_PATH="${cmk_prefixPath}" \
            -DCMAKE_FIND_PACKAGE_PREFER_CONFIG=OFF \
            -DCMAKE_FIND_USE_CMAKE_SYSTEM_PATH=OFF \
            -DCMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH=ON \
            -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_curl}  \
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}   \
            -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}    \
            -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_C_FLAGS="-fPIC" \
            -DCMAKE_CXX_FLAGS="-fPIC" \
            -DBUILD_SHARED_LIBS=OFF \
            -DCURL_DISABLE_LDAP=ON     \
            -DCURL_DISABLE_FTP=ON       \
            -DCURL_DISABLE_TELNET=ON      \
            -DCURL_DISABLE_DICT=ON       \
            -DCURL_DISABLE_FILE=ON      \
            -DCURL_DISABLE_TFTP=ON      \
            -DCURL_BROTLI=OFF  -DCURL_USE_LIBSSH2=OFF \
            -DUSE_LIBIDN2=OFF  -DUSE_NGHTTP2=OFF \
            -DCURL_ZLIB=ON  -DZLIB_USE_STATIC_LIBS=ON   -DCURL_ZSTD=ON \
            -DBUILD_DOCS=OFF \
            -DCMAKE_INSTALL_DOCDIR=OFF \
            -DCURL_USE_PKGCONFIG=OFF \
            -DOPENSSL_USE_STATIC_LIBS=ON  \
            -DZstd_LIBRARY="${INSTALL_PREFIX_zstd}/lib/libzstd.a" \
            -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a  \
            -DOPENSSL_LIBRARIES=${INSTALL_PREFIX_openssl}/lib64/libssl.a; ${INSTALL_PREFIX_openssl}/lib64/libcrypto.a \
            -DOPENSSL_SSL_LIBRARY=${INSTALL_PREFIX_openssl}/lib64/libssl.a \
            -DPENSSL_CRYPTO_LIBRARY=${INSTALL_PREFIX_openssl}/lib64/libcrypto.a \
            -DLIBPSL_LIBRARY=${INSTALL_PREFIX_psl}/lib/libpsl.a            

            # -DCMAKE_FIND_ROOT_PATH="${INSTALL_PREFIX_ubt}" \
            # -DCMAKE_PREFIX_PATH="${cmk_prefixPath}" \
            # -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
            # -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
            # -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
            # -DCMAKE_FIND_USE_CMAKE_SYSTEM_PATH=OFF \
            # -DCMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH=ON \
            # -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \

            # -DOPENSSL_ROOT_DIR=${INSTALL_PREFIX_openssl}   \
            # -DOPENSSL_INCLUDE_DIR=${INSTALL_PREFIX_openssl}/include  \
            # -DOPENSSL_LIBRARIES=${INSTALL_PREFIX_openssl}/lib64/libssl.a; ${INSTALL_PREFIX_openssl}/lib64/libcrypto.a \
            # -DOPENSSL_SSL_LIBRARY=${INSTALL_PREFIX_openssl}/lib64/libssl.a \
            # -DPENSSL_CRYPTO_LIBRARY=${INSTALL_PREFIX_openssl}/lib64/libcrypto.a \
            # -DLIBPSL_INCLUDE_DIR=${INSTALL_PREFIX_psl}/include   \
            # -DLIBPSL_LIBRARY=${INSTALL_PREFIX_psl}/lib/libpsl.a   \
            # -DZLIB_ROOT=${INSTALL_PREFIX_zlib} \
            # -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include \
            # -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a  \
            # -DZSTD_ROOT=${INSTALL_PREFIX_zstd} \
            # -DZSTD_LIBRARY=${INSTALL_PREFIX_zstd}/lib/libzstd.a 

        # -- hi..OPENSSL_LIBRARIES=/home/osg0/install/openssl/lib64/libssl.a;/home/osg0/install/openssl/lib64/libcrypto.a;dl
        # -- hi..OpenSSL::SSL library path: /home/osg0/install/openssl/lib64/libssl.a
        # -- hi..OpenSSL::Crypto library path: /home/osg0/install/openssl/lib64/libcrypto.a

 
            # -DCMAKE_EXE_LINKER_FLAGS="-licuuc -licudata -licuio"  # 链接ICU相关静态库
            
            # -DUSE_NGHTTP2=ON 
            # -DCURL_ZLIB=OFF  
            # -DCURL_ZSTD=OFF \ 
            # -DENABLE_IPV6=OFF

    cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc)

    cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}
    echo "========== Finished Building curl =========" &&  sleep 2
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
#     SrcDIR_lib=${SrcDir_3rd}/jpeg-9f
#     BuildDIR_Jpeg9f=${BuildDir_ubuntu}/3rd/jpeg9f
#     prepareBuilding  ${SrcDIR_lib} ${BuildDIR_Jpeg9f} ${INSTALL_PREFIX_jpeg9f} ${isRebuild}              
# 
#     # 在构建目录中运行configure
#     cd ${BuildDIR_Jpeg9f} 
#       
#     CFLAGS="-fPIC" \ 
#     ${SrcDir_3rd}/jpeg-9f/configure --prefix=${INSTALL_PREFIX_jpeg9f}\
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

    SrcDIR_lib=${SrcDir_3rd}/libjpeg-turbo
    BuildDIR_libjpeg=${BuildDir_ubuntu}/3rd/libjpeg-turbo
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_libjpeg} ${INSTALL_PREFIX_jpegTurbo} ${isRebuild}  

    cmake -S${SrcDIR_lib}  -B ${BuildDIR_libjpeg} \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_jpegTurbo}  \
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
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

INSTALL_PREFIX_png=${INSTALL_PREFIX_ubt}/libpng
 
if [ "${isFinished_build_libpng}" != "true" ] ; then 
    echo "========== Building libpng 4 Ubuntu==========" && sleep 3

    SrcDIR_lib=${SrcDir_3rd}/libpng
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/libpng
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_png} ${isRebuild}  
         

    cmake -S${SrcDir_3rd}/libpng -B ${BuildDIR_lib} \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_png} \
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_C_FLAGS="-fPIC" \
            -DCMAKE_CXX_FLAGS="-fPIC" \
            -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a \
            -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include \
            -DPNG_SHARED=ON \
            -DPNG_STATIC=ON   

    cmake --build ${BuildDIR_lib} -j$(nproc)

    cmake --build ${BuildDIR_lib} --target install
    echo "========== Finished Building libpng for Ubuntu ==========" && sleep 2    
fi    


# -------------------------------------------------
# xz : xz generates liblzma.a which is needed by libtiff
# -------------------------------------------------
INSTALL_PREFIX_xz=${INSTALL_PREFIX_ubt}/xz
 
if [ "${isFinished_build_xz}" != "true" ]  ; then 
    echo "========== Building xz 4 Ubuntu==========" && sleep 5
    SrcDIR_lib=${SrcDir_3rd}/xz
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/xz
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_xz} ${isRebuild}     

    cmake -S${SrcDir_3rd}/xz -B ${BuildDIR_lib} \
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_xz} \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_C_FLAGS="-fPIC" \
            -DCMAKE_CXX_FLAGS="-fPIC" \
            -DBUILD_SHARED_LIBS=OFF 

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
# -------------------------------------------------
INSTALL_PREFIX_tiff=${INSTALL_PREFIX_ubt}/libtiff
 
if [ "${isFinished_build_libtiff}" != "true" ] ; then 
    echo "========== Building libtiff 4 Ubuntu==========" && sleep 3
    SrcDIR_lib=${SrcDir_3rd}/libtiff
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/libtiff
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_tiff} ${isRebuild}     

    cmake -S${SrcDir_3rd}/libtiff -B ${BuildDIR_lib} \
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_C_FLAGS="-fPIC" \
            -DCMAKE_CXX_FLAGS="-fPIC" \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_tiff}  \
            -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a \
            -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include \
            -DJPEG_LIBRARY=${INSTALL_PREFIX_jpegTurbo}/lib/libjpeg.a \
            -DJPEG_INCLUDE_DIR=${INSTALL_PREFIX_jpegTurbo}/include \
            -DLIBLZMA_LIBRARY=${INSTALL_PREFIX_xz}/lib/liblzma.a \
            -DLIBLZMA_INCLUDE_DIR=${INSTALL_PREFIX_xz}/include \
            -DBUILD_SHARED_LIBS=OFF \
            -DCMAKE_EXE_LINKER_FLAGS="-static"  \
            -Djbig=OFF \
            -Dtiff-tools=OFF   

            # -Dtiff-tools=OFF    # 可选：禁用工具构建
            #  -DCMAKE_EXE_LINKER_FLAGS="-static"  # 强制静态链接所有库
    cmake --build ${BuildDIR_lib} -j$(nproc)

    cmake --build ${BuildDIR_lib} --target install
    echo "========== Finished Building libtiff for Ubuntu ==========" && sleep 2    
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
# -------------------------------------------------
INSTALL_PREFIX_freetype=${INSTALL_PREFIX_ubt}/freetype
 
if [ "${isFinished_build_freetype}" != "true" ] ; then 
    echo "========== Building freetype 4 Ubuntu==========" && sleep 3
    SrcDIR_lib=${SrcDir_3rd}/freetype
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/freetype
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_freetype} ${isRebuild}       

    cmake -S${SrcDir_3rd}/freetype -B ${BuildDIR_lib} \
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_freetype} \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_C_FLAGS="-fPIC" \
            -DCMAKE_CXX_FLAGS="-fPIC" \
            -DFT_DISABLE_BZIP2=ON \
            -DFT_DISABLE_BROTLI=ON \
            -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a  \
            -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include \
            -DPNG_LIBRARY=${INSTALL_PREFIX_png}/lib/libpng.a \
            -DPNG_PNG_INCLUDE_DIR=${INSTALL_PREFIX_png}/include \
            -DFT_REQUIRE_ZLIB=ON \
            -DFT_REQUIRE_PNG=ON  \
            -DCMAKE_EXE_LINKER_FLAGS="-static"

    cmake --build ${BuildDIR_lib} -j$(nproc)

    cmake --build ${BuildDIR_lib} --target install

    echo "========== Finished Building freetype for Ubuntu ==========" && sleep 2    
fi


# -------------------------------------------------
# geos
# ------------------------------------------------- 

INSTALL_PREFIX_geos=${INSTALL_PREFIX_ubt}/geos

if [ "${isFinished_build_geos}" != "true" ] ; then 
    echo "========== building geos 4 ubuntu========== " &&  sleep 3

    SrcDIR_lib=${SrcDir_3rd}/geos
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/geos 
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_geos} ${isRebuild} 
     
    #################################################################### 
    # 在顶层 CMakeLists.txt 中全局启用 PIC: set(CMAKE_POSITION_INDEPENDENT_CODE ON)  
    cmake -S ${SrcDir_3rd}/geos -B ${BuildDIR_lib} \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_C_FLAGS="-fPIC" \
            -DCMAKE_CXX_FLAGS="-fPIC" \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_geos}  \
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
    echo "========== finished building geos 4 ubuntu ========== " &&  sleep 2
fi


# -------------------------------------------------
# sqlite
# ------------------------------------------------- 
INSTALL_PREFIX_sqlite=${INSTALL_PREFIX_ubt}/sqlite

if [ "${isFinished_build_sqlite}" != "true" ] ; then 
    echo "========== building sqlite 4 ubuntu========== " &&  sleep 3
    SrcDIR_lib=${SrcDir_3rd}/sqlite
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/sqlite
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_sqlite} ${isRebuild}   

    #################################################################### 
    # 在构建目录中运行configure
    cd ${BuildDIR_lib} 
    # /usr/bin/musl-gcc
    # CFLAGS="-I${INSTALL_PREFIX_icu}/include/icu" \
    # LDFLAGS="-L${INSTALL_PREFIX_icu}/lib" \ 
    CC=/usr/bin/gcc \
    ${SrcDir_3rd}/sqlite/configure  --prefix=${INSTALL_PREFIX_sqlite} \
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
INSTALL_PREFIX_proj=${INSTALL_PREFIX_ubt}/proj

if [ "${isFinished_build_proj}" != "true" ] ; then 
    echo "========== building proj 4 ubuntu========== " &&  sleep 5

    SrcDIR_lib=${SrcDir_3rd}/proj
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/proj 
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_proj} ${isRebuild} 
                    
    #################################################################### 
    # libssl_path=${INSTALL_PREFIX_openssl}/lib64/libssl.a 
    # libcrypto_path=${INSTALL_PREFIX_openssl}/lib64/libcrypto.a    
    echo "DEBUG: INSTALL_PREFIX_ubt = '${INSTALL_PREFIX_ubt}'"
    echo "DEBUG: INSTALL_PREFIX_zlib = '${INSTALL_PREFIX_zlib}'"
    echo "DEBUG: INSTALL_PREFIX_xz = '${INSTALL_PREFIX_xz}'"
    echo "DEBUG: INSTALL_PREFIX_jpegTurbo = '${INSTALL_PREFIX_jpegTurbo}'"
    echo "DEBUG: INSTALL_PREFIX_openssl = '${INSTALL_PREFIX_openssl}'"
    echo "DEBUG: INSTALL_PREFIX_curl = '${INSTALL_PREFIX_curl}'"
    echo "DEBUG: INSTALL_PREFIX_sqlite = '${INSTALL_PREFIX_sqlite}'"
#     cmk_prefixPath=${INSTALL_PREFIX_zlib};${INSTALL_PREFIX_xz};${INSTALL_PREFIX_jpegTurbo};\
#${INSTALL_PREFIX_openssl};${INSTALL_PREFIX_curl};${INSTALL_PREFIX_sqlite}
    # 检查并拼接路径
    cmk_prefixPath=$(check_concat_paths  "${INSTALL_PREFIX_zlib}" \
                "${INSTALL_PREFIX_xz}" \
                "${INSTALL_PREFIX_jpegTurbo}" "${INSTALL_PREFIX_openssl}" \
                "${INSTALL_PREFIX_curl}" "${INSTALL_PREFIX_sqlite}")     

    #  CC=musl-gcc cmake -S ${SrcDir_3rd}/proj -B ${BuildDIR_lib}     
    cmake -S ${SrcDir_3rd}/proj -B ${BuildDIR_lib} --debug-find \
            -DCMAKE_FIND_ROOT_PATH="${INSTALL_PREFIX_ubt}" \
            -DCMAKE_PREFIX_PATH="${cmk_prefixPath}" \
            -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
            -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
            -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
            -DCMAKE_FIND_USE_CMAKE_SYSTEM_PATH=OFF \
            -DCMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH=ON \
            -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_proj}  \
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}   \
            -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}    \
            -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} \
            -DBUILD_SHARED_LIBS=OFF     \
            -DBUILD_TESTING=OFF \
            -DBUILD_EXAMPLES=OFF \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_CXX_FLAGS="-fPIC" \
            -DCMAKE_C_FLAGS="-fPIC"  \
            -DENABLE_CURL=ON  \
            -DENABLE_TIFF=OFF  \
            -DSQLite3_DISABLE_DYNAMIC_EXTENSIONS=ON \
            -DCURL_DISABLE_ARES=ON  \
            -DZLIB_LIBRARY_RELEASE="${INSTALL_PREFIX_zlib}/lib/libz.a"

 
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
            
            # -DOPENSSL_ROOT_DIR=${INSTALL_PREFIX_openssl} \
            # -DOPENSSL_LIBRARIES="${libssl_path};${libcrypto_path}" \
            # -DCURL_ROOT=${INSTALL_PREFIX_curl} \
            # -DCURL_LIBRARY=${INSTALL_PREFIX_curl}/lib/libcurl-d.a \
            # -DCURL_INCLUDE_DIR=${INSTALL_PREFIX_curl}/include \
            # -DSQLite3_LIBRARY=${INSTALL_PREFIX_sqlite}/lib/libsqlite3.a \
            # -DSQLite3_INCLUDE_DIR=${INSTALL_PREFIX_sqlite}/include \
            # -DTIFF_LIBRARY=${INSTALL_PREFIX_tiff}/lib/libtiff.a \
            # -DTIFF_INCLUDE_DIR=${INSTALL_PREFIX_tiff}/include \
            # -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a  \
            # -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include \            

            # -DCMAKE_EXE_LINKER_FLAGS="-static" \

        

    cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j15 # -j$(nproc)
    
    cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}
    #################################################################### 
    echo "========== finished building proj 4 ubuntu ========== " &&  sleep 2
fi


# -------------------------------------------------
# libexpat
# ------------------------------------------------- 
INSTALL_PREFIX_expat=${INSTALL_PREFIX_ubt}/libexpat

if [ "${isFinished_build_libexpat}" != "true" ] ; then 
    echo "========== building libexpat 4 ubuntu========== " &&  sleep 5

    SrcDIR_lib=${SrcDir_3rd}/libexpat/expat
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/libexpat 
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_expat} ${isRebuild} 
        
    ####################################################################
    cmk_prefixPath="${INSTALL_PREFIX_zlib};${INSTALL_PREFIX_xz}"
    
    cmake -S ${SrcDir_3rd}/libexpat/expat -B ${BuildDIR_lib} \
            -DCMAKE_FIND_ROOT_PATH=${INSTALL_PREFIX_ubt} \
            -DCMAKE_PREFIX_PATH=${cmk_prefixPath} \
            -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
            -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
            -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
            -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_expat}  \
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}   \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_C_FLAGS="-fPIC"   \
            -DCMAKE_CXX_FLAGS="-fPIC" \
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
# abseil-cpp  
# -------------------------------------------------
INSTALL_PREFIX_absl=${INSTALL_PREFIX_ubt}/abseil-cpp


if [ "${isFinished_build_absl}" != "true" ] ; then 
    echo "========== building abseil-cpp 4 ubuntu========== " &&  sleep 5

    SrcDIR_lib=${SrcDir_3rd}/abseil-cpp
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/abseil-cpp 
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_absl} ${isRebuild}        
    ####################################################################
    cmk_prefixPath=“” 
    
    cmake -S ${SrcDir_3rd}/protobuf -B ${BuildDIR_lib} \
            -DCMAKE_FIND_ROOT_PATH="${INSTALL_PREFIX_ubt}" \
            -DCMAKE_PREFIX_PATH="${cmk_prefixPath}" \
            -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
            -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
            -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
            -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_absl}  \
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}   \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_CXX_FLAGS="-fPIC" \
            -DCMAKE_C_FLAGS="-fPIC"   \
            -DBUILD_SHARED_LIBS=OFF    
            

            # -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a  \
            # -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include           

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

    SrcDIR_lib=${SrcDir_3rd}/protobuf
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/protobuf 
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_protobuf} ${isRebuild}        
    ####################################################################
    cmk_prefixPath="${INSTALL_PREFIX_zlib};${INSTALL_PREFIX_absl}"
    protoc_path=/home/abner/programs/protoc-31.1-linux-x86_64/bin/protoc
    
    cmake -S ${SrcDir_3rd}/protobuf -B ${BuildDIR_lib}  --debug-find \
            -DCMAKE_FIND_ROOT_PATH="${INSTALL_PREFIX_ubt}" \
            -DCMAKE_PREFIX_PATH="${cmk_prefixPath}" \
            -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
            -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
            -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
            -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_protobuf}  \
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}   \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_CXX_FLAGS="-fPIC" \
            -DCMAKE_C_FLAGS="-fPIC"   \
            -DBUILD_SHARED_LIBS=OFF   \
            -Dprotobuf_BUILD_TESTS=OFF \
            -Dprotobuf_BUILD_EXAMPLES=OFF \
            -Dprotobuf_BUILD_PROTOC_BINARIES=OFF \
            -Dprotobuf_PROTOC_EXE=${protoc_path}
            

            # -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a  \
            # -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include           

    cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) 
    
    cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}     
    #################################################################### 
    echo "========== finished building protobuf 4 ubuntu ========== " &&  sleep 2
fi    
 
 
# -------------------------------------------------
# gdal , see 3rd/gdal/fuzzers/build.sh
# -------------------------------------------------
INSTALL_PREFIX_gdal=${INSTALL_PREFIX_ubt}/gdal

if [ "${isFinished_build_gdal}" != "true" ] ; then 
    echo "========== building gdal 4 ubuntu========== " &&  sleep 3

    SrcDIR_lib=${SrcDir_3rd}/gdal
    BuildDIR_lib=${BuildDir_ubuntu}/3rd/gdal 
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_gdal} ${isRebuild}   

    #################################################################### 
    cmk_prefixPath=$(check_concat_paths_1  "${INSTALL_PREFIX_zlib}" \
                "${INSTALL_PREFIX_xz}"     "${INSTALL_PREFIX_png}" \
                "${INSTALL_PREFIX_absl}"   "${INSTALL_PREFIX_protobuf}" \
                "${INSTALL_PREFIX_jpegTurbo}"  "${INSTALL_PREFIX_openssl}" \ 
                "${INSTALL_PREFIX_tiff}"   "${INSTALL_PREFIX_expat}" \
                "${INSTALL_PREFIX_geos}"   "${INSTALL_PREFIX_proj}"  \
                "${INSTALL_PREFIX_curl}"   "${INSTALL_PREFIX_sqlite}")

    echo "==========cmk_prefixPath=${cmk_prefixPath}"
    #  
    cmake -S ${SrcDir_3rd}/gdal -B ${BuildDIR_lib}  --debug-find \
            -DCMAKE_FIND_ROOT_PATH=${INSTALL_PREFIX_ubt} \
            -DCMAKE_PREFIX_PATH=${cmk_prefixPath} \
            -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
            -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
            -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
            -DCMAKE_FIND_USE_CMAKE_SYSTEM_PATH=OFF \
            -DCMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH=ON \
            -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_gdal}  \
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}   \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
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
            -DJPEG_INCLUDE_DIR=${INSTALL_PREFIX_jpegTurbo}/include/libjpeg  \
            -DJPEG_LIBRARY=${INSTALL_PREFIX_jpegTurbo}/lib/libjpeg.a 


            
            # -DCURL_LIBRARY=${INSTALL_PREFIX_curl}/lib/libcurl.a \
            # -DCURL_INCLUDE_DIR=${INSTALL_PREFIX_curl}/include \
            # -DGEOS_INCLUDE_DIR=${INSTALL_PREFIX_geos}/include \
            # -DGEOS_LIBRARY=${INSTALL_PREFIX_geos}/lib/libgeos.a \
            # -DPROJ_INCLUDE_DIR=${INSTALL_PREFIX_proj}/include \
            # -DPROJ_LIBRARY=${INSTALL_PREFIX_proj}/lib/libproj.a \
            # -DSQLITE3_INCLUDE_DIR=${INSTALL_PREFIX_sqlite}/include \
            # -DPNG_INCLUDE_DIR=${INSTALL_PREFIX_png}/include \
            # -DPNG_LIBRARY=${INSTALL_PREFIX_png}/lib/libpng.a \
            # -DJPEG_INCLUDE_DIR=${INSTALL_PREFIX_jpegTurbo}/include \
            # -DJPEG_LIBRARY=${INSTALL_PREFIX_jpegTurbo}/lib/libjpeg.a \            
            # -DSQLITE3_LIBRARY=${INSTALL_PREFIX_sqlite}/lib/libsqlite3.a \
            # -DOPENSSL_DIR=${INSTALL_PREFIX_openssl}/lib64/cmake/OpenSSL/ \
            # -DOPENSSL_ROOT_DIR=${INSTALL_PREFIX_openssl} \
            # -DOPENSSL_INCLUDE_DIR=${INSTALL_PREFIX_openssl}/include \
            # -DOPENSSL_SSL_LIBRARY=${INSTALL_PREFIX_openssl}/lib64/libssl.a \
            # -DOPENSSL_CRYPTO_LIBRARY=${INSTALL_PREFIX_openssl}/lib64/libcrypto.a \
            # -DPROTOBUF_LIBRARY=${INSTALL_PREFIX_protobuf}/lib/libprotobuf.a \
            # -DPROTOBUF_INCLUDE_DIR=${INSTALL_PREFIX_protobuf}/include  \
            # -DZLIB_ROOT=${INSTALL_PREFIX_zlib} \
            # -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include \
            # -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a \
      
 
    cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc)
    
    cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}     
    #################################################################### 
    echo "========== finished building gdal 4 ubuntu ========== " &&  sleep 2
fi    

 
# **************************************************************************
# **************************************************************************
#  src/
# ************************************************************************** 
SrcDir_src=${Repo_ROOT}/src
 
# -------------------------------------------------
# osg 
# -------------------------------------------------
INSTALL_PREFIX_osg=${INSTALL_PREFIX_ubt}/src/osg

if [ "${isFinished_build_osg}" != "true" ] ; then 
    echo "========== building osg 4 ubuntu========== " &&  sleep 1

    SrcDIR_lib=${SrcDir_src}/osg
    BuildDIR_lib=${BuildDir_ubuntu}/src/osg
    echo "gg====         SrcDIR_lib=${SrcDIR_lib}" 
    echo "gg====       BuildDIR_lib=${BuildDIR_lib}" 
    echo "gg==== INSTALL_PREFIX_osg=${INSTALL_PREFIX_osg}" 
    prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_osg} ${isRebuild}  

    #################################################################### 
    # lib_dir=${INSTALL_PREFIX_src}/lib
    # lib64_dir=${INSTALL_PREFIX_src}/lib64 
    # _LINKER_FLAGS="-L${lib_dir} -lcurl -ltiff -ljpeg -lsqlite3 -lprotobuf -lpng -llzma -lz"
    # _LINKER_FLAGS="${_LINKER_FLAGS} -L${lib64_dir} -lssl -lcrypto" 
    #  "${INSTALL_PREFIX_zlib}"
    cmk_prefixPath=$(check_concat_paths_1  \
            "${INSTALL_PREFIX_xz}"  "${INSTALL_PREFIX_absl}" "${INSTALL_PREFIX_zstd}"\
            "${INSTALL_PREFIX_png}"  "${INSTALL_PREFIX_jpegTurbo}"  \
            "${INSTALL_PREFIX_protobuf}" "${INSTALL_PREFIX_openssl}" \
            "${INSTALL_PREFIX_tiff}" "${INSTALL_PREFIX_geos}"  "${INSTALL_PREFIX_psl}"\
            "${INSTALL_PREFIX_proj}"  "${INSTALL_PREFIX_expat}" "${INSTALL_PREFIX_freetype}" \
            "${INSTALL_PREFIX_curl}" "${INSTALL_PREFIX_sqlite}" "${INSTALL_PREFIX_gdal}")
    echo "==========cmk_prefixPath=${cmk_prefixPath}"   
    # <<osg的间接依赖库>>
    # 依赖关系：osg -->gdal-->curl-->libpsl， 所以OSG 的 CMake 配置需要确保在链接时
    # （target_link_libraries）包含所有 cURL 所依赖的库(osg的间接依赖库)。
    # 需要告诉 CMake，链接 libcurl-d.a时还需要哪些其他库。这通常在 CMakeLists.txt中通过 
    # find_package(CURL)或直接修改链接标志来完成。​    ​最直接的方法是在您的 CMake 命令中，
    # 通过CMAKE_EXE_LINKER_FLAGS 或 CMAKE_SHARED_LINKER_FLAGS 添加缺失的库。​ 
    _exeLinkerFlags="${INSTALL_PREFIX_zlib}/lib/libz.a"
    _exeLinkerFlags="${_exeLinkerFlags} ${INSTALL_PREFIX_zstd}/lib/libzstd.a"
    _exeLinkerFlags="${_exeLinkerFlags} ${INSTALL_PREFIX_openssl}/lib64/libcrypto.a"
    _exeLinkerFlags="${_exeLinkerFlags} ${INSTALL_PREFIX_openssl}/lib64/libssl.a"
    _exeLinkerFlags="${_exeLinkerFlags} ${INSTALL_PREFIX_psl}/lib/libpsl.a"
    _exeLinkerFlags="${_exeLinkerFlags} ${INSTALL_PREFIX_curl}/lib/libcurl-d.a"
    _exeLinkerFlags="${_exeLinkerFlags} -ldl -lpthread -lX11 -lGL"
    echo "gg==========_exeLinkerFlags=${_exeLinkerFlags}" 

    _curlLibs="${INSTALL_PREFIX_curl}/lib/libcurl-d.a;"
    _curlLibs="${_curlLibs} ${INSTALL_PREFIX_openssl}/lib64/libssl.a;"
    _curlLibs="${_curlLibs} ${INSTALL_PREFIX_openssl}/lib64/libcrypto.a;"
    _curlLibs="${_curlLibs} ${INSTALL_PREFIX_psl}/lib/libpsl.a;"
    _curlLibs="${_curlLibs} ${INSTALL_PREFIX_zstd}/lib/libzstd.a"
    _curlLibs="${_curlLibs} ${INSTALL_PREFIX_zlib}/lib/libz.a"
    echo "gg==========_curlLibs=${_curlLibs}" 

    # --debug-find    --debug-output 
    cmake -S ${SrcDir_src}/osg -B ${BuildDIR_lib}  --debug-find   \
            -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
            -DCMAKE_PREFIX_PATH="${cmk_prefixPath}" \
            -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
            -DCMAKE_FIND_PACKAGE_PREFER_CONFIG=ON \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_osg}  \
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}   \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_C_FLAGS="-fPIC  -DOSG_GL3_AVAILABLE=1"   \
            -DCMAKE_CXX_FLAGS="-fPIC -std=c++14  -DOSG_GL3_AVAILABLE=1" \
            -DBUILD_SHARED_LIBS=OFF   \
        -DDYNAMIC_OPENTHREADS=OFF \
        -DDYNAMIC_OPENSCENEGRAPH=OFF \
        -DOSG_GL1_AVAILABLE=OFF \
        -DOSG_GL2_AVAILABLE=OFF \
        -DOSG_GL3_AVAILABLE=ON \
        -DOSG_GLES1_AVAILABLE=OFF \
        -DOSG_GLES2_AVAILABLE=OFF \
        -DOSG_GLES3_AVAILABLE=OF \
        -DOSG_GL_LIBRARY_STATIC=OFF \
        -DOSG_GL_DISPLAYLISTS_AVAILABLE=OFF \
        -DOSG_GL_MATRICES_AVAILABLE=OFF \
        -DOSG_GL_VERTEX_FUNCS_AVAILABLE=OFF \
        -DOSG_GL_VERTEX_ARRAY_FUNCS_AVAILABLE=OFF \
        -DOSG_GL_FIXED_FUNCTION_AVAILABLE=OFF \
        -DOPENGL_PROFILE="GL3" \
        -DANDROID=OFF \
        -DOSG_FIND_3RD_PARTY_DEPS=ON  \
        -DZLIB_USE_STATIC_LIBS=ON \
        -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX_zlib}/include \
        -DZLIB_LIBRARY=${INSTALL_PREFIX_zlib}/lib/libz.a \
        -DZLIB_LIBRARIES="${INSTALL_PREFIX_zlib}/lib/libz.a" \
        -DPNG_INCLUDE_DIR=${INSTALL_PREFIX_png}/include/libpng16 \
        -DPNG_LIBRARY=${INSTALL_PREFIX_png}/lib/libpng.a \
        -DPNG_LIBRARIES=${INSTALL_PREFIX_png}/lib/libpng.a \
        -DJPEG_INCLUDE_DIR=${INSTALL_PREFIX_jpegTurbo}/include/libjpeg \
        -DJPEG_LIBRARY=${INSTALL_PREFIX_jpegTurbo}/lib/libjpeg.a \
        -DJPEG_LIBRARIES=${INSTALL_PREFIX_jpegTurbo}/lib/libjpeg.a \
        -DOpenSSL_DIR="${INSTALL_PREFIX_openssl}/lib64/cmake/OpenSSL"  \
        -DOpenSSL_ROOT="${INSTALL_PREFIX_openssl}" \
        -DOpenSSL_USE_STATIC_LIBS=ON \
        -DOpenSSL_SSL_LIBRARY="${INSTALL_PREFIX_openssl}/lib64/libssl.a" \
        -DOpenSSL_CRYPTO_LIBRARY="${INSTALL_PREFIX_openssl}/lib64/libcrypto.a" \
        -DOpenSSL_INCLUDE_DIR="${INSTALL_PREFIX_openssl}/include" \
        -DOpenSSL_LIBRARIES="${INSTALL_PREFIX_openssl}/lib64/libssl.a;${INSTALL_PREFIX_openssl}/lib64/libcrypto.a;" \
        -DTIFF_INCLUDE_DIR=${INSTALL_PREFIX_tiff}/include \
        -DTIFF_LIBRARY=${INSTALL_PREFIX_tiff}/lib/libtiff.a \
        -DTIFF_LIBRARIES=${INSTALL_PREFIX_tiff}/lib/libtiff.a \
        -DFREETYPE_DIR=${INSTALL_PREFIX_freetype} \
        -DFREETYPE_INCLUDE_DIRS=${INSTALL_PREFIX_freetype}/include/freetype2 \
        -DFREETYPE_LIBRARY=${INSTALL_PREFIX_freetype}/lib/libfreetyped.a \
        -DFREETYPE_LIBRARIES=${INSTALL_PREFIX_freetype}/lib/libfreetyped.a \
        -DCURL_DIR="${INSTALL_PREFIX_curl}/lib/cmake/CURL" \
        -DCURL_LIBRARY=CURL::libcurl \
        -DCURL_LIBRARIES="_curlLibs" \
        -DCURL_INCLUDE_DIR="${INSTALL_PREFIX_curl}/include" \
        -DGDAL_DIR=${INSTALL_PREFIX_gdal}l \
        -DGDAL_INCLUDE_DIR=${INSTALL_PREFIX_gdal}/include \
        -DGDAL_LIBRARY=${INSTALL_PREFIX_gdal}/lib/libgdal.a    \
        -DGDAL_LIBRARIES=${INSTALL_PREFIX_gdal}/lib/libgdal.a  
        
        # （1）关于-DCURL_LIBRARY="CURL::libcurl" ：
        #  -DCURL_LIBRARY="${INSTALL_PREFIX_curl}/lib/libcurl-d.a" \
        #  -DCURL_LIBRARIES="CURL::libcurl" ## 根据一般的规则，ok
        #  -DCURL_LIBRARY="CURL::libcurl" ##  特定于osg项目，是ok的，因为osg/src/osgPlugins/curl/CMakeLists.txt中
        #     SET(TARGET_LIBRARIES_VARS   CURL_LIBRARY     ZLIB_LIBRARIES)用的是CURL_LIBRARY而不是CURL_LIBRARIES

        # remark: ${INSTALL_PREFIX_zlib}/lib/cmake/zlib/ZLIBConfig.cmake只提供了 ZLIB::ZLIBstatic
        #        /usr/share/cmake-3.28/Modules/FindZLIB.cmake 提供了 ZLIB::ZLIB
        #       所以作为workaround，这里使用/usr/share/cmake-3.28/Modules/FindZLIB.cmake
        # -DCMAKE_EXE_LINKER_FLAGS="${_exeLinkerFlags}" 
        
        # -DZLIB_ROOT=${INSTALL_PREFIX_zlib} \

        # -DOpenSSL_LIBRARY="${INSTALL_PREFIX_openssl}/lib64" \
        # -DOpenSSL_INCLUDE_DIR="${INSTALL_PREFIX_openssl}/include"  \
        # -DOpenSSL_SSL_LIBRARY="${INSTALL_PREFIX_openssl}/lib64/libssl.a" \
        # -DOpenSSL_CRYPTO_LIBRARY="${INSTALL_PREFIX_openssl}/lib64/libcrypto.a" \
        # -DOpenSSL_ROOT_DIR="${INSTALL_PREFIX_openssl}" \
        # -DOpenSSL_LIBRARIES="${INSTALL_PREFIX_openssl}/lib64/libssl.a; ${INSTALL_PREFIX_openssl}/lib64/libcrypto.a" \
        # -DCURL_LIBRARIES="${_curlLibs}" \

        # -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
        # -DCMAKE_FIND_ROOT_PATH="${INSTALL_PREFIX_ubt}" \
        # -DCMAKE_PREFIX_PATH="${cmk_prefixPath}" \
        # -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH \
        # -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH \
        # -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \

        #  
        # -DCMAKE_STATIC_LINKER_FLAGS=${_LINKER_FLAGS}  
 
 
    cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v
    
    cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}     
    #################################################################### 
    echo "========== finished building osg 4 ubuntu ========== " &&  sleep 1 

fi    

exit 11