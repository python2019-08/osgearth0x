#!/bin/bash
CMAKE_BUILD_TYPE=Debug #RelWithDebInfo
CMAKE_MAKE_PROGRAM=/usr/bin/make
CMAKE_C_COMPILER=/usr/bin/gcc   # /usr/bin/musl-gcc   # /usr/bin/clang  # 
CMAKE_CXX_COMPILER=/usr/bin/g++ # /usr/bin/musl-gcc # /usr/bin/clang++  #   

# **************************************************************************
Repo_ROOT=/home/abner/abner2/zdev/nv/osgearth0x
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


# =======================================================
SrcDIR_3rd=${Repo_ROOT}/3rd

# =======================================================
INSTALL_PREFIX_zlib="${INSTALL_PREFIX_ubt}/zlib"  
INSTALL_PREFIX_zstd=${INSTALL_PREFIX_ubt}/zstd
INSTALL_PREFIX_zip="${INSTALL_PREFIX_ubt}/libzip"
INSTALL_PREFIX_xz="${INSTALL_PREFIX_ubt}/xz" 
INSTALL_PREFIX_png="${INSTALL_PREFIX_ubt}/libpng" 
INSTALL_PREFIX_absl="${INSTALL_PREFIX_ubt}/abseil-cpp" 
INSTALL_PREFIX_protobuf="${INSTALL_PREFIX_ubt}/protobuf" 
INSTALL_PREFIX_expat="${INSTALL_PREFIX_ubt}/libexpat"
INSTALL_PREFIX_jpegTurbo="${INSTALL_PREFIX_ubt}/libjpeg-turbo" 
INSTALL_PREFIX_openssl="${INSTALL_PREFIX_ubt}/openssl"
INSTALL_PREFIX_tiff="${INSTALL_PREFIX_ubt}/libtiff"   
INSTALL_PREFIX_geos="${INSTALL_PREFIX_ubt}/geos"
INSTALL_PREFIX_psl=${INSTALL_PREFIX_ubt}/libpsl
INSTALL_PREFIX_proj="${INSTALL_PREFIX_ubt}/proj"
INSTALL_PREFIX_curl="${INSTALL_PREFIX_ubt}/curl"  
INSTALL_PREFIX_sqlite="${INSTALL_PREFIX_ubt}/sqlite"
INSTALL_PREFIX_freetype="${INSTALL_PREFIX_ubt}/freetype" 
INSTALL_PREFIX_gdal="${INSTALL_PREFIX_ubt}/gdal"    
INSTALL_PREFIX_boost="${INSTALL_PREFIX_ubt}/boost"
INSTALL_PREFIX_osg="${INSTALL_PREFIX_ubt}/osg"


echo "========== building osg 4 ubuntu========== " &&  sleep 1  && set -x

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
# 
cmk_prefixPath=$(check_concat_paths_1  ${INSTALL_PREFIX_zlib} \
        "${INSTALL_PREFIX_xz}"  "${INSTALL_PREFIX_absl}" "${INSTALL_PREFIX_zstd}"\
        "${INSTALL_PREFIX_png}"  "${INSTALL_PREFIX_jpegTurbo}"  \
        "${INSTALL_PREFIX_openssl}" \
        "${INSTALL_PREFIX_tiff}" "${INSTALL_PREFIX_geos}"  "${INSTALL_PREFIX_psl}"\
        "${INSTALL_PREFIX_proj}"  "${INSTALL_PREFIX_expat}" "${INSTALL_PREFIX_freetype}" \
        "${INSTALL_PREFIX_curl}" "${INSTALL_PREFIX_sqlite}" "${INSTALL_PREFIX_gdal}" \
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

osg_MODULE_PATH="${INSTALL_PREFIX_zlib}/lib/cmake/zlib" 
# ------
libstdcxx_a_path=$(find /usr/lib/gcc/x86_64-linux-gnu -name libstdc++.a)
# ------
cmakeParams_osg=( 
# "-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH" 
# "-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH" # BOTH ：先查根路径，再查系统路径    
"-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH" # 头文件仍只查根路径 
# 是否访问 /usr/include/、/usr/lib/ 等 系统路径   
"-DCMAKE_FIND_USE_CMAKE_SYSTEM_PATH=ON"
# 是否访问PATH\LD_LIBRARY_PATH等环境变量
"-DCMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH=ON" 
)

# ------
echo "=== cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib}  --debug-find ......"
# --debug-find    --debug-output 
cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib}  --debug-find --trace-expand  \
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
    -DGDAL_DIR=${INSTALL_PREFIX_gdal}                   \
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

# echo "=== cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v"
# cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v
 