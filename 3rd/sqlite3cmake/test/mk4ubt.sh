#!/bin/bash
# **************************************************************************
# false  ;;;   ./mk4ubt.sh  >bsqtest.txt 2>&1
isRebuild=true

CMAKE_BUILD_TYPE=Debug #RelWithDebInfo
CMAKE_MAKE_PROGRAM=/usr/bin/make
CMAKE_C_COMPILER=/usr/bin/gcc   # /usr/bin/musl-gcc   # /usr/bin/clang  # 
CMAKE_CXX_COMPILER=/usr/bin/g++ # /usr/bin/musl-gcc # /usr/bin/clang++  #   

# **************************************************************************
Repo_ROOT=/home/abner/abner2/zdev/nv/osgearth0x

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
  # 是否访问 /usr/include/、/usr/lib/ 等 系统路径   
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
    echo "aSubSrcDir= $aSubSrcDir"
    echo "aSubBuildDir=$aSubBuildDir"
    echo "aSubInstallDir=$aSubInstallDir" 
    echo "aIsRebuild=$aIsRebuild" 
	# ----------------------------------
    if [ ! -d "${aSubSrcDir}" ]; then
        echo "Folder ${aSubSrcDir}  NOT exist!"
        exit 1001
    fi    
 
	# ----------------------------------
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
SrcDIR_3rd=${Repo_ROOT}/3rd

# -------------------------------------------------
# sqlite
# ------------------------------------------------- 
echo "========== building sqlite 4 ubuntu========== " &&  sleep 1

SrcDIR_lib=${SrcDIR_3rd}/sqlite3cmake/test
BuildDIR_lib=${BuildDir_ubuntu}/3rd/sqlite/test
INSTALL_PREFIX_sqlitetest=${INSTALL_PREFIX_ubt}/sqlite/test
prepareBuilding  ${SrcDIR_lib} ${BuildDIR_lib} ${INSTALL_PREFIX_sqlitetest} ${isRebuild}   

INSTALL_PREFIX_sqlite=${INSTALL_PREFIX_ubt}/sqlite
INSTALL_PREFIX_zlib=${INSTALL_PREFIX_ubt}/zlib
cmkPrefixPath="${INSTALL_PREFIX_zlib};${INSTALL_PREFIX_sqlite}"


cmake -S ${SrcDIR_lib} -B ${BuildDIR_lib} --debug-find \
		"${cmakeCommonParams[@]}"  \
		-DCMAKE_PREFIX_PATH=${cmkPrefixPath} \
		-DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_sqlitetest}  \
		-DSQLITE_BUILD_TOOLS=ON

cmake --build ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v

cmake --install ${BuildDIR_lib} --config ${CMAKE_BUILD_TYPE}  -v

echo "========== finished building sqlite 4 ubuntu ========== " &&  sleep 1 
 
