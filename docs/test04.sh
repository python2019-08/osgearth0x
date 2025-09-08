CMAKE_BUILD_TYPE=Debug #RelWithDebInfo
CMAKE_MAKE_PROGRAM=/usr/bin/make
CMAKE_C_COMPILER=/usr/bin/gcc   # /usr/bin/musl-gcc   # /usr/bin/clang  # 
CMAKE_CXX_COMPILER=/usr/bin/g++ # /usr/bin/musl-gcc # /usr/bin/clang++  #   
INSTALL_PREFIX_ubt=./
cmakeCommonParams1="-DCMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}  \
                   -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}       \
                   -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}    \
                   -DCMAKE_FIND_ROOT_PATH=${INSTALL_PREFIX_ubt}   \
                   -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY        \
                   -DCMAKE_FIND_PACKAGE_PREFER_CONFIG=ON            \
                   -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY          \
                   -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY           \
                   -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER           \
                   -DCMAKE_FIND_USE_CMAKE_SYSTEM_PATH=OFF               \
                   -DCMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH=OFF          \
                   -DCMAKE_FIND_LIBRARY_SUFFIXES=.a   "

echo "cmakeCommonParams1=${cmakeCommonParams1}"
echo "----------------------------------------"
# 用数组形式定义 CMake 参数（避免解析错误）
cmakeCommonParams2=(
  "-DCMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}"
  "-DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}"
  "-DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}"
  "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
  "-DCMAKE_FIND_ROOT_PATH=${INSTALL_PREFIX_ubt}"
  "-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY"
  "-DCMAKE_FIND_PACKAGE_PREFER_CONFIG=ON"
  "-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY"
  "-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY"
  "-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER"
  "-DCMAKE_FIND_USE_CMAKE_SYSTEM_PATH=OFF"
  "-DCMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH=OFF"
  "-DCMAKE_FIND_LIBRARY_SUFFIXES=.a"
  "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"  ## = -fPIC
) 

cmakeCommonParams2+=(
  "-DAppend01=${CMAKE_C_COMPILER}"
  "-DAppend02=22"
)

echo "cmakeCommonParams2=${cmakeCommonParams2[@]}"
exit 11
echo "----------------------------------------"
INSTALL_PREFIX_zlib=11
INSTALL_PREFIX_xz=22
INSTALL_PREFIX_jpegTurbo=33
INSTALL_PREFIX_openssl=44
INSTALL_PREFIX_curl=55
INSTALL_PREFIX_sqlite=66
cmk_prefixPath=( "${INSTALL_PREFIX_zlib};" 
            "${INSTALL_PREFIX_xz};"
            "${INSTALL_PREFIX_jpegTurbo};"
            "${INSTALL_PREFIX_openssl};"
            "${INSTALL_PREFIX_curl};"
            "${INSTALL_PREFIX_sqlite}" 
            )


echo "cmk_prefixPath=${cmk_prefixPath[*]}"
echo "----------------------------------------"

cmk_prefixPath1="${INSTALL_PREFIX_zlib};${INSTALL_PREFIX_xz};${INSTALL_PREFIX_jpegTurbo}; \
                 ${INSTALL_PREFIX_openssl};${INSTALL_PREFIX_curl};${INSTALL_PREFIX_sqlite}"

echo "cmk_prefixPath1=${cmk_prefixPath1}"


echo "----------------------------------------"
set -x

if [ -n "${PKG_CONFIG_PATH}" ]; then
export PKG_CONFIG_PATH="/home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/pkgconfig:$PKG_CONFIG_PATH"
else
export PKG_CONFIG_PATH="/home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/pkgconfig"
fi

echo $PKG_CONFIG_PATH
pkg-config --libs  openscenegraph-osg

set +x