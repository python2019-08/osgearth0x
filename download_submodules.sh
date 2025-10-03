#!/bin/bash
startTm=$(date +%Y/%m/%d--%H:%M:%S) 
echo "download_submodules.sh: param 0=$0"
# Repo_ROOT=/home/abner/abner2/zdev/nv/osgearth0x
# 获取脚本的绝对路径（处理符号链接）
SCRIPT_PATH=$(readlink -f "$0")
echo "sh-path: $SCRIPT_PATH"

# 额外：获取脚本所在目录的绝对路径
Repo_ROOT=$(dirname "$SCRIPT_PATH")
echo "Repo_ROOT=${Repo_ROOT}"
# (base) abner@abner-XPS:/mnt/disk2/abner/zdev/nv/osgearth0x$ ls 3rd/
# abseil-cpp  CMakeLists.txt  curl  freetype  gdal  geos  
# json-c  libexpat libjpeg-turbo  libpng  libpsl  libtiff 
# libzip  openssl  osgdraco  proj protobuf  sqlite  xz  zlib  zstd


# 脚本开头添加代理配置开关（1=启用，0=禁用）
USE_PROXY=0
if [ $USE_PROXY -eq 1 ]; then
    # export http_proxy=socks5://127.0.0.1:1080
    # export https_proxy=socks5://127.0.0.1:1080
    # export HTTP_PROXY=socks5://127.0.0.1:1080
    # export HTTPS_PROXY=socks5://127.0.0.1:1080    
    export http_proxy=http://127.0.0.1:1081
    export https_proxy=http://127.0.0.1:1081
    # export HTTP_PROXY=http://127.0.0.1:1081
    # export HTTPS_PROXY=http://127.0.0.1:1081      
else
    # should only use  http_proxy https_proxy 
    unset http_proxy https_proxy # HTTP_PROXY  HTTPS_PROXY
fi

echo "----------------------------------------------------"
if [ ! -f "${Repo_ROOT}/3rd/zlib/CMakeLists.txt" ]; then
    # git submodule add -f -b v1.3.1 https://github.com/madler/zlib.git    3rd/zlib   
    git clone  https://github.com/madler/zlib.git    3rd/zlib  || { echo "zlib 克隆失败！"; exit 1; }  
    cd ${Repo_ROOT}/3rd/zlib 
    # git checkout -b my-v1.3.1 tags/v1.3.1 
    git checkout  -b my-2025Feb18-084758   5a82f71ed1dfc0bec044d9702463dbdf84ea3b71
    cd ${Repo_ROOT}  
fi

echo "----------------------------------------------------"
if [ ! -f "${Repo_ROOT}/3rd/zstd/build/cmake/CMakeLists.txt" ]; then
    git clone https://github.com/facebook/zstd.git  3rd/zstd   || { echo "zstd 克隆失败！"; exit 1; }
    cd ${Repo_ROOT}/3rd/zstd 
    # git checkout -b my-v1.5.7 tags/v1.5.7
    git checkout -b my-2025Aug18-091013 cfeb29e39713dadcb5f6735a129289ac06b3de73
    cd ${Repo_ROOT}   
fi
  
echo "----------------------------------------------------"
if [ ! -f "${Repo_ROOT}/3rd/openssl/Configure" ]; then  
    #  git clone --recursive https://github.com/openssl/openssl.git  3rd/openssl   
    git clone https://github.com/openssl/openssl.git   3rd/openssl    || { echo " 克隆失败！"; exit 1; }
    cd ${Repo_ROOT}/3rd/openssl 
    #  git submodule update --init --recursive --progress -v
    git checkout -b my-openssl-3.5.2  tags/openssl-3.5.2
    cd ${Repo_ROOT}   
fi

echo "----------------------------------------------------"
# git clone  https://github.com/unicode-org/icu.git  3rd/icu  

echo "----------------------------------------------------"
# git clone  https://github.com/libidn/libidn2.git  3rd/libidn2  

echo "----------------------------------------------------"
if [ ! -f "${Repo_ROOT}/3rd/libpsl/configure" ]; then  
    git clone  https://github.com/rockdaboot/libpsl.git  3rd/libpsl   || { echo " 克隆失败！"; exit 1; }
    cd ${Repo_ROOT}/3rd/libpsl 
    git checkout -b my-libpsl-0.21.0  tags/libpsl-0.21.0
    cd ${Repo_ROOT}    
fi

echo "----------------------------------------------------"
if [ ! -f "${Repo_ROOT}/3rd/curl/CMakeLists.txt" ]; then  
    git clone  https://github.com/curl/curl.git    3rd/curl    || { echo " 克隆失败！"; exit 1; }
    cd ${Repo_ROOT}/3rd/curl 
    git checkout -b my-curl-8_15_0  tags/curl-8_15_0
    cd ${Repo_ROOT}    
fi

echo "----------------------------------------------------"
if [ ! -f "${Repo_ROOT}/3rd/libjpeg-turbo/CMakeLists.txt" ]; then  
    git clone  https://github.com/libjpeg-turbo/libjpeg-turbo.git  3rd/libjpeg-turbo   || { echo " 克隆失败！"; exit 1; }
    cd ${Repo_ROOT}/3rd/libjpeg-turbo  
    # git checkout -b my-jpeg-9f tags/jpeg-9f
    git checkout -b my-3.1.2   tags/3.1.2
    cd ${Repo_ROOT}    
fi

echo "----------------------------------------------------"
if [ ! -f "${Repo_ROOT}/3rd/libpng/CMakeLists.txt" ]; then  
    git clone  https://github.com/glennrp/libpng.git  3rd/libpng  || { echo " 克隆失败！"; exit 1; }
    cd ${Repo_ROOT}/3rd/libpng 
    git checkout -b my-libpng-1.6.31-signed tags/libpng-1.6.31-signed
    cd ${Repo_ROOT}    
fi

echo "----------------------------------------------------"
if [ ! -f "${Repo_ROOT}/3rd/xz/CMakeLists.txt" ]; then  
    git clone  https://github.com/tukaani-project/xz.git  3rd/xz  || { echo " 克隆失败！"; exit 1; }
    cd ${Repo_ROOT}/3rd/xz 
    git checkout -b my-v5.8.1 tags/v5.8.1
    cd ${Repo_ROOT}    
fi

echo "----------------------------------------------------"
if [ ! -f "${Repo_ROOT}/3rd/libtiff/CMakeLists.txt" ]; then  
    git clone  https://github.com/vadz/libtiff.git   3rd/libtiff  || { echo " 克隆失败！"; exit 1; }
    cd ${Repo_ROOT}/3rd/libtiff 
    git checkout -b my-Release-v4-0-9  tags/Release-v4-0-9
    cd ${Repo_ROOT}    
fi

echo "----------------------------------------------------"
if [ ! -f "${Repo_ROOT}/3rd/freetype/CMakeLists.txt" ]; then  
    git clone  https://github.com/freetype/freetype.git   3rd/freetype  || { echo " 克隆失败！"; exit 1; }
    cd ${Repo_ROOT}/3rd/freetype 
    git checkout -b my-VER-2-13-3  tags/VER-2-13-3
    cd ${Repo_ROOT}    
fi

echo "----------------------------------------------------"
if [ ! -f "${Repo_ROOT}/3rd/geos/CMakeLists.txt" ]; then  
    git clone  https://github.com/libgeos/geos.git   3rd/geos  || { echo " 克隆失败！"; exit 1; }
    cd ${Repo_ROOT}/3rd/geos 
    git checkout -b my-3.13.1 tags/3.13.1
    cd ${Repo_ROOT}    
fi

echo "----------------------------------------------------" 
# git clone  https://github.com/sqlite/sqlite.git    3rd/sqlite
# cd ${Repo_ROOT}/3rd/sqlite 
# git checkout -b my-version-3.50.4 tags/version-3.50.4
# cd ${Repo_ROOT}    
# ------------
# wget  https://sqlite.org/2025/sqlite-amalgamation-3500400.zip
# cd ${Repo_ROOT}/3rd/sqlite3cmake
# cd ${Repo_ROOT}   


echo "----------------------------------------------------"
if [ ! -f "${Repo_ROOT}/3rd/proj/CMakeLists.txt" ]; then  
    git clone  https://github.com/OSGeo/PROJ.git    3rd/proj  || { echo " 克隆失败！"; exit 1; }
    cd ${Repo_ROOT}/3rd/proj 
    git checkout -b my-9.6.2 tags/9.6.2
    cd ${Repo_ROOT}    
fi

echo "----------------------------------------------------"
# git clone  https://github.com/libexpat/libexpat.git    3rd/libexpat  || { echo " 克隆失败！"; exit 1; }


echo "----------------------------------------------------"
if [ ! -f "${Repo_ROOT}/3rd/abseil-cpp/CMakeLists.txt" ]; then  
    git clone  https://github.com/abseil/abseil-cpp.git   3rd/abseil-cpp  || { echo " 克隆失败！"; exit 1; }
    cd ${Repo_ROOT}/3rd/abseil-cpp
    git checkout -b my-20250512.1   tags/20250512.1  
    cd ${Repo_ROOT}
fi

echo "----------------------------------------------------"
if [ ! -f "${Repo_ROOT}/3rd/protobuf/CMakeLists.txt" ]; then  
    git clone  https://github.com/protocolbuffers/protobuf.git   3rd/protobuf  || { echo " 克隆失败！"; exit 1; }
    cd ${Repo_ROOT}/3rd/protobuf 
    # git checkout  v32.0
    git checkout -b my-v32.0 tags/v32.0
    cd ${Repo_ROOT}
fi

echo "----------------------------------------------------"
if false; then  
    git clone  https://github.com/json-c/json-c.git  3rd/json-c  || { 
        echo " 克隆失败！"; exit 1; 
    }
fi

echo "----------------------------------------------------"
if [ ! -f "${Repo_ROOT}/3rd/gdal/CMakeLists.txt" ]; then  
    git clone  https://github.com/OSGeo/gdal.git   3rd/gdal  || { 
        echo " 克隆失败！"; exit 1; 
    }
    
    cd ${Repo_ROOT}/3rd/gdal  
    git checkout -b my-v3.9.3  tags/v3.9.3
    cd ${Repo_ROOT}
fi

echo "----------------------------------------------------"
if false; then  
git clone  https://github.com/google/draco.git  3rd/osgdraco  || { echo " 克隆失败！"; exit 1; }
fi


echo "----------------------------------------------------"
if [ ! -f "${Repo_ROOT}/3rd/boost/bootstrap.sh" ]; then  
    # #---- boost github:
    # git clone  https://github.com/boostorg/boost.git 3rd/boost
    # cd ${Repo_ROOT}/3rd/boost 
    # git submodule update --init --recursive
    # git checkout -b my-boost_1_88_0    tags/boost_1_88_0
    # cd ${Repo_ROOT}
    cd ${Repo_ROOT}/3rd 
    # curl -L -f -o boost_1_88_0.zip -C - https://github.com/boostorg/boost/archive/refs/tags/boost-1.88.0.zip
    # wget https://sourceforge.net/projects/boost/files/boost/1.88.0/boost_1_88_0.zip
    # unzip boost_1_88_0.zip
    # mv boost_1_88_0  boost
    # 1. 下载 Boost（带重定向和错误处理）
    rm -f boost_1_88_0.zip  # 清除旧文件
    echo "正在下载 Boost 1.88.0..."
    curl -L -f -o boost_1_88_0.zip -C - https://github.com/boostorg/boost/archive/refs/tags/boost-1.88.0.zip || {
        echo "Boost 下载失败！请检查网络或代理。"
        exit 1  # 下载失败则退出脚本，避免后续错误
    }

    # 2. 解压（先检查文件是否为有效 zip）
    echo "正在解压 Boost 1.88.0..."
    unzip boost_1_88_0.zip || {
        echo "Boost 解压失败！文件可能损坏，请重新下载。"
        exit 1
    }

    # 3. 重命名（先确认解压后的文件夹名，再移动）
    # 注意：GitHub 标签压缩包解压后，文件夹名是 "boost-1.88.0"（与标签名一致）
    UNZIPPED_FOLDER="boost-1.88.0"  # 解压后的真实文件夹名
    if [ -d "$UNZIPPED_FOLDER" ]; then
        mv "$UNZIPPED_FOLDER" boost  # 重命名为脚本需要的 "boost"
        echo "Boost 文件夹重命名完成（$UNZIPPED_FOLDER → boost）"
    else
        echo "解压后未找到文件夹 $UNZIPPED_FOLDER！请检查解压结果。"
        exit 1
    fi


    cd ${Repo_ROOT}
fi

echo "----------------------------------------------------"
if false; then  
    git clone https://github.com/chriskohlhoff/asio.git   3rd/asio  || { echo " 克隆失败！"; exit 1; }
    cd ${Repo_ROOT}/3rd/asio 
    # git checkout -b my-boost_1_88_0    tags/boost_1_88_0
    cd ${Repo_ROOT}
fi

echo "----------------------------------------------------"
if [ ! -f "${Repo_ROOT}/3rd/osg/CMakeLists.txt" ]; then  
    git clone https://github.com/openscenegraph/OpenSceneGraph.git  3rd/osg  || { echo " 克隆失败！"; exit 1; }
    cd ${Repo_ROOT}/3rd/osg 
    # git checkout -b my-OpenSceneGraph-3.6.5 tags/OpenSceneGraph-3.6.5
    # 
    # ~/abner2/zdev/nv/osgearth0x/3rd/osg$     git log
    # commit 2e4ae2ea94595995c1fc56860051410b0c0be605 (HEAD -> master, origin/master, origin/HEAD)
    # Author: Robert Osfield <robert@openscenegraph.com>
    # Date:   Thu Dec 1 18:17:31 2022 +0000
    #     Removed indentation to avoid github MD mark up from loosing link.
    # 
    git checkout -b  my-2022-dec01-181731  2e4ae2ea94595995c1fc56860051410b0c0be605
    cd ${Repo_ROOT}
fi

echo "----------------------------------------------------"
if [ ! -f "${Repo_ROOT}/3rd/libzip/CMakeLists.txt" ]; then  
    git clone https://github.com/nih-at/libzip.git 3rd/libzip  || { echo " 克隆失败！"; exit 1; }
    cd ${Repo_ROOT}/3rd/libzip 
    git checkout  v1.11.4
    cd ${Repo_ROOT}
fi

echo "----------------------------------------------------"
if false; then  
    git clone https://github.com/gabime/spdlog.git  3rd/spdlog  || { echo " 克隆失败！"; exit 1; }
    cd 3rd/spdlog
    git checkout  v1.11.4
    cd ${Repo_ROOT}
    # # 编译并安装
    # cmake .. -DSPDLOG_BUILD_EXAMPLE=OFF  # 禁用示例程序
    # make -j$(nproc)
    # sudo make install
fi

echo "----------------------------------------------------"
if [ ! -f "${Repo_ROOT}/3rd/osgearth/CMakeLists.txt" ]; then  
    git clone https://github.com/gwaldron/osgearth.git   3rd/osgearth  || { echo " 克隆失败！"; exit 1; }
    cd ${Repo_ROOT}/3rd/osgearth 
    git submodule update --init --recursive
    # git checkout -b my-osgearth-3.7.2   tags/osgearth-3.7.2
    git checkout  -b my-2025Sep12-093115    928195eb74d85eac21c0c727af0fafc6d01be87c  # master
    cd ${Repo_ROOT}
fi

endTm=$(date +%Y/%m/%d--%H:%M:%S)
printf "${startTm}----${endTm}\n"  