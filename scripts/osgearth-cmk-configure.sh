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


INSTALL_PREFIX_osgearth=${INSTALL_PREFIX_ubt}/osgearth


echo "========== building osgearth 4 ubuntu========== " &&  sleep 1  && set -x

SrcDIR_lib=${SrcDIR_3rd}/osgearth
BuildDIR_lib=${BuildDir_ubuntu}/3rd/osgearth
echo "gg====         SrcDIR_lib=${SrcDIR_lib}" 
echo "gg====       BuildDIR_lib=${BuildDIR_lib}" 
echo "gg==== INSTALL_PREFIX_osg=${INSTALL_PREFIX_osgearth}" 
# prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_osgearth} ${isRebuild}  

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
    -DFREETYPE_LIBRARY=${INSTALL_PREFIX_freetype}/lib/libfreetype.a \
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
 
# echo "ee====cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v" 
# cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v

# echo "cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}" 
# cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}     
#################################################################### 
echo "========== finished building osgearth 4 ubuntu ========== "   && set +x
