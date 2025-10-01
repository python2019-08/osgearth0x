#!/bin/bash
 
# (base) abner@abner-XPS:/mnt/disk2/abner/zdev/nv/osgearth0x$ ls 3rd/
# abseil-cpp  CMakeLists.txt  curl  freetype  gdal  geos  
# json-c  libexpat libjpeg-turbo  libpng  libpsl  libtiff 
# libzip  openssl  osgdraco  proj protobuf  sqlite  xz  zlib  zstd

if [ ! -f "./3rd/zlib/CMakeLists.txt" ]; then
    # git submodule add -f -b v1.3.1 https://github.com/madler/zlib.git    3rd/zlib   
    git clone  https://github.com/madler/zlib.git    3rd/zlib   
    cd ./3rd/zlib 
    git checkout -b my-v1.3.1 tags/v1.3.1 
    cd ../../   
fi


if [ ! -f "./3rd/zstd/build/cmake/CMakeLists.txt" ]; then
    git clone https://github.com/facebook/zstd.git  3rd/zstd  
    cd ./3rd/zstd 
    git checkout -b my-v1.5.7 tags/v1.5.7
    cd ../../   
fi
  

if [ ! -f "./3rd/openssl/Configure" ]; then  
    #  git clone --recursive https://github.com/openssl/openssl.git  3rd/openssl   
    git clone https://github.com/openssl/openssl.git   3rd/openssl   
    cd ./3rd/openssl 
    #  git submodule update --init --recursive --progress -v
    git checkout -b my-openssl-3.5.2  tags/openssl-3.5.2
    cd ../../   
fi


# git clone  https://github.com/unicode-org/icu.git  3rd/icu  

# git clone  https://github.com/libidn/libidn2.git  3rd/libidn2  


if [ ! -f "./3rd/libpsl/configure" ]; then  
    git clone  https://github.com/rockdaboot/libpsl.git  3rd/libpsl  
    cd ./3rd/libpsl 
    git checkout -b my-libpsl-0.21.0  tags/libpsl-0.21.0
    cd ../../    
fi


if [ ! -f "./3rd/curl/CMakeLists.txt" ]; then  
    git clone  https://github.com/curl/curl.git    3rd/curl   
    cd ./3rd/curl 
    git checkout -b my-curl-8_15_0  tags/curl-8_15_0
    cd ../../    
fi


if [ ! -f "./3rd/libjpeg-turbo/CMakeLists.txt" ]; then  
    git clone  https://github.com/libjpeg-turbo/libjpeg-turbo.git  3rd/libjpeg-turbo  
    cd ./3rd/libjpeg-turbo  
    git checkout -b my-jpeg-9f tags/jpeg-9f
    cd ../../    
fi


if [ ! -f "./3rd/libpng/CMakeLists.txt" ]; then  
    git clone  https://github.com/glennrp/libpng.git  3rd/libpng
    cd ./3rd/libpng 
    git checkout -b my-libpng-1.6.31-signed tags/libpng-1.6.31-signed
    cd ../../    
fi


if [ ! -f "./3rd/xz/CMakeLists.txt" ]; then  
    git clone  https://github.com/tukaani-project/xz.git  3rd/xz
    cd ./3rd/xz 
    git checkout -b my-v5.8.1 tags/v5.8.1
    cd ../../    
fi


if [ ! -f "./3rd/libtiff/CMakeLists.txt" ]; then  
    git clone  https://github.com/vadz/libtiff.git   3rd/libtiff
    cd ./3rd/libtiff 
    git checkout -b my-Release-v4-0-9  tags/Release-v4-0-9
    cd ../../    
fi


if [ ! -f "./3rd/freetype/CMakeLists.txt" ]; then  
    git clone  https://github.com/freetype/freetype.git   3rd/freetype
    cd ./3rd/freetype 
    git checkout -b my-VER-2-13-3  tags/VER-2-13-3
    cd ../../    
fi


if [ ! -f "./3rd/geos/CMakeLists.txt" ]; then  
    git clone  https://github.com/libgeos/geos.git   3rd/geos
    cd ./3rd/geos 
    git checkout -b my-3.13.1 tags/3.13.1
    cd ../../    
fi
# --------------------------------------------------------------
# git clone  https://github.com/sqlite/sqlite.git    3rd/sqlite
# cd ./3rd/sqlite 
# git checkout -b my-version-3.50.4 tags/version-3.50.4
# cd ../../    
# ------------
# wget  https://sqlite.org/2025/sqlite-amalgamation-3500400.zip
# cd ./3rd/sqlite3cmake
# cd ../../   


if [ ! -f "./3rd/proj/CMakeLists.txt" ]; then  
    git clone  https://github.com/OSGeo/PROJ.git    3rd/proj
    cd ./3rd/proj 
    git checkout -b my-9.6.2 tags/9.6.2
    cd ../../    
fi

# git clone  https://github.com/libexpat/libexpat.git    3rd/libexpat


if [ ! -f "./3rd/abseil-cpp/CMakeLists.txt" ]; then  
    git clone  https://github.com/abseil/abseil-cpp.git   3rd/abseil-cpp
    cd ./3rd/abseil-cpp
    git checkout -b my-20250512.1   tags/20250512.1  
    cd ../../
fi

if [ ! -f "./3rd/protobuf/CMakeLists.txt" ]; then  
    git clone  https://github.com/protocolbuffers/protobuf.git   3rd/protobuf
    cd ./3rd/protobuf 
    # git checkout  v32.0
    git checkout -b my-v32.0 tags/v32.0
    cd ../../
fi


if false; then  
# git clone  https://github.com/json-c/json-c.git  3rd/json-c
fi

if [ ! -f "./3rd/gdal/CMakeLists.txt" ]; then  
    git clone  https://github.com/OSGeo/gdal.git   3rd/gdal
    cd ./3rd/gdal  
    git checkout -b my-v3.9.3  tags/v3.9.3
    cd ../../
fi


if false; then  
# git clone  https://github.com/google/draco.git  3rd/osgdraco
fi

if [ ! -f "./3rd/boost/bootstrap.sh" ]; then  
    # #---- boost github:
    # git clone  https://github.com/boostorg/boost.git 3rd/boost
    # cd ./3rd/boost 
    # git submodule update --init --recursive
    # git checkout -b my-boost_1_88_0    tags/boost_1_88_0
    # cd ../../
    cd ./3rd 
    # wget https://github.com/boostorg/boost/archive/refs/tags/boost-1.88.0.zip
    wget https://sourceforge.net/projects/boost/files/boost/1.88.0/boost_1_88_0.zip
    unzip boost_1_88_0.zip
    mv boost_1_88_0  boost
    cd ..
fi


if false; then  
    git clone https://github.com/chriskohlhoff/asio.git   3rd/asio
    cd ./3rd/asio 
    # git checkout -b my-boost_1_88_0    tags/boost_1_88_0
    cd ../../
fi


if [ ! -f "./3rd/osg/CMakeLists.txt" ]; then  
    git clone https://github.com/openscenegraph/OpenSceneGraph.git  3rd/osg
    cd ./3rd/osg 
    # git checkout -b my-OpenSceneGraph-3.6.5 tags/OpenSceneGraph-3.6.5
    # 
    # ~/abner2/zdev/nv/osgearth0x/3rd/osg$     git log
    # commit 2e4ae2ea94595995c1fc56860051410b0c0be605 (HEAD -> master, origin/master, origin/HEAD)
    # Author: Robert Osfield <robert@openscenegraph.com>
    # Date:   Thu Dec 1 18:17:31 2022 +0000
    #     Removed indentation to avoid github MD mark up from loosing link.
    # 
    git checkout -b  my-2022-dec01-181731  2e4ae2ea94595995c1fc56860051410b0c0be605
    cd ../../
fi


if [ ! -f "./3rd/libzip/CMakeLists.txt" ]; then  
    git clone https://github.com/nih-at/libzip.git 3rd/libzip
    cd ./3rd/libzip 
    git checkout  v1.11.4
    cd ../../
fi


if false; then  
    git clone https://github.com/gabime/spdlog.git  3rd/spdlog
    cd 3rd/spdlog
    git checkout  v1.11.4
    cd ../../
    # # 编译并安装
    # cmake .. -DSPDLOG_BUILD_EXAMPLE=OFF  # 禁用示例程序
    # make -j$(nproc)
    # sudo make install
fi


if [ ! -f "./3rd/osgearth/CMakeLists.txt" ]; then  
    git clone https://github.com/gwaldron/osgearth.git   3rd/osgearth
    cd ./3rd/osgearth 
    git submodule update --init --recursive
    # git checkout -b my-osgearth-3.7.2   tags/osgearth-3.7.2
    git checkout  -b my-2025Sep12-093115    928195eb74d85eac21c0c727af0fafc6d01be87c  # master
    cd ../../
fi