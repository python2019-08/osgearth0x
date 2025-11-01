#!/bin/bash
# **************************************************************************
# false  ;;;   ./mk4ubt.sh  >bu.txt 2>&1
echo "mk4ubuntu.sh: param 0=$0"
startTm=$(date +%Y/%m/%d--%H:%M:%S) 

# 获取脚本的物理绝对路径（解析软链接）
SCRIPT_PATH=$(readlink -f "$0")
echo "sh-path: $SCRIPT_PATH"

# 额外：获取脚本所在目录的绝对路径
# Repo_ROOT=$(dirname "$SCRIPT_PATH")
#--当/home/abner/abner2 是 实际路径/mnt/disk2/abner/ 的软链接时，Repo_ROOT应该是 软链接目录下的路径，
#--否则，cmake 在使用CMAKE_PREFIX_PATH查找 xxxConfig.cmake 时有歧义、混淆，从而编译失败。
#--所以这里强制指定为：
Repo_ROOT=/home/abner/abner2/zdev/nv/osgearth0x
echo "Repo_ROOT=${Repo_ROOT}"
# 验证路径是否存在
if [ ! -d "$Repo_ROOT" ]; then
    echo "Error: Repo_ROOT does not exist: $Repo_ROOT"
    exit 1
fi
 
# echo "============================================================="
isRebuild=true
# ------ 
isFinished_build_lnx8sky=false  # false
# ------
CMAKE_BUILD_TYPE=Debug #RelWithDebInfo
CMAKE_MAKE_PROGRAM=/usr/bin/make
CMAKE_C_COMPILER=/usr/bin/gcc   # /usr/bin/musl-gcc   # /usr/bin/clang  # 
CMAKE_CXX_COMPILER=/usr/bin/g++ # /usr/bin/musl-gcc # /usr/bin/clang++  #   

# echo "============================================================="
# rm -fr ./build_by_sh   
BuildROOT=${Repo_ROOT}/build_by_sh
# rm -fr ./build_by_sh 
BuildROOT_ubuntu=${BuildROOT}/build/ubuntu
InstallROOT_ubuntu=${BuildROOT}/install/ubuntu

if [ ! -d "${BuildROOT_ubuntu}" ]; then
    mkdir -p ${BuildROOT_ubuntu} 
fi


if [ ! -d "${InstallROOT_ubuntu}" ]; then
    mkdir -p ${InstallROOT_ubuntu} 
fi

 
# echo "============================================================="

cmakeCommonParams=(
  "-DCMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}"
  "-DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}"
  "-DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}"
  "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
  "-DPKG_CONFIG_EXECUTABLE=/usr/bin/pkg-config"
  "-DCMAKE_FIND_ROOT_PATH=${InstallROOT_ubuntu}"
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

# echo "============================================================="
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
            echo "mkdir -p ${aSubBuildDir}失败！";
            exit 1002;
        } 
    fi    

     
    if  [ ! -d "${aSubInstallDir}" ]; then
        mkdir -p ${aSubInstallDir} || { 
            echo "mkdir -p ${aSubInstallDir}失败！";
            exit 1002;
        } 
    fi    
 

    return 0
}
echo "============================================================="
# **************************************************************************
#  3rd/
# **************************************************************************
InstallDIR_3rd=${InstallROOT_ubuntu}/3rd

# **************************************************************************
# **************************************************************************
#  platform/
# **************************************************************************
SrcDIR_platform=${Repo_ROOT}/platform

BuildDIR_platform=${BuildROOT_ubuntu}/platform
InstallDIR_platform=${InstallROOT_ubuntu}/platform
# -------------------------------------------------
# lnx8sky 
# -------------------------------------------------
INSTALL_PREFIX_lnx8sky=${InstallDIR_platform}/lnx8sky
 
if [ "${isFinished_build_lnx8sky}" != "true" ] ; then 
    echo "========== building lnx8sky 4 ubuntu========== " &&  sleep 1  && set -x

    SrcDIR_this=${SrcDIR_platform}/lnx8sky
    BuildDIR_this=${BuildDIR_platform}/lnx8sky 
 
    prepareBuilding  ${SrcDIR_this} ${BuildDIR_this} ${INSTALL_PREFIX_lnx8sky} ${isRebuild}  

    #################################################################### 
    export PKG_CONFIG_PATH="${INSTALL_PREFIX_osg}/lib/pkgconfig:$PKG_CONFIG_PATH"

    # ----
    # osgearth_MODULE_PATH="${INSTALL_PREFIX_zlib}/lib/cmake/zlib"  
    # echo "oearth...osgearth_MODULE_PATH=${osgearth_MODULE_PATH}"    

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
    cmake -S ${SrcDIR_this} -B ${BuildDIR_this}  --debug-find   \
            "${cmakeCommonParams[@]}"  "${cmakeParams_osgearth[@]}" \
            -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
            -DCMAKE_PREFIX_PATH="${cmk_prefixPath}" \
            -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_lnx8sky}  \
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
        -DLIB_EAY_RELEASE=""  \
        -DInstallRoot_3rd="${InstallDIR_3rd}"  \
        -DCMAKE_EXE_LINKER_FLAGS=" \
          -Wl,--whole-archive  -fvisibility=hidden   -Wl,--no-whole-archive   \
          -Wl,-Bdynamic -lstdc++  -lGL -lGLU -ldl -lm -lc -lpthread -lrt     \
          -Wl,--no-as-needed -lX11 -lXext "  

        # -DCMAKE_MODULE_PATH=${osgearth_MODULE_PATH} \
    echo "ee====cmake --build ${BuildDIR_this} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v" 
    cmake --build ${BuildDIR_this} --config ${CMAKE_BUILD_TYPE}  -j$(nproc) -v
    
    echo "cmake --install ${BuildDIR_this} --config ${CMAKE_BUILD_TYPE}" 
    cmake --install ${BuildDIR_this} --config ${CMAKE_BUILD_TYPE}     
    #################################################################### 
    echo "========== finished building lnx8sky 4 ubuntu ========== "   && set +x

fi    
 

# **************************************************************************
endTm=$(date +%Y/%m/%d--%H:%M:%S)
printf "${startTm}----${endTm}\n"  