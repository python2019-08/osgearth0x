#!/bin/bash
 
# (base) abner@abner-XPS:/mnt/disk2/abner/zdev/nv/osgearth0x$ ls 3rd/
# abseil-cpp  CMakeLists.txt  curl  freetype  gdal  geos  
# json-c  libexpat libjpeg-turbo  libpng  libpsl  libtiff 
# libzip  openssl  osgdraco  proj protobuf  sqlite  xz  zlib  zstd

# git submodule add -f -b v1.3.1 https://github.com/madler/zlib.git    3rd/zlib   
git clone  https://github.com/madler/zlib.git    3rd/zlib   
cd ./3rd/zlib 
git checkout -b my-v1.3.1 v1.3.1 # v1.3.1 is a tag
cd ../../  

git clone https://github.com/facebook/zstd.git  3rd/zstd  
cd ./3rd/zstd 
git checkout -b my-v1.5.7 v1.5.7
cd ../../   
  
#  git clone --recursive https://github.com/openssl/openssl.git  3rd/openssl   
git clone https://github.com/openssl/openssl.git   3rd/openssl   
cd ./3rd/openssl 
git checkout -b my-openssl-3.5.2  openssl-3.5.2
cd ../../   
# if [ -f "./3rd/openssl/.gitmodules" ]; then
#     cd 3rd/openssl
#     git submodule update --init --recursive --progress -v
#     cd ../../
# fi


# git clone  https://github.com/unicode-org/icu.git  3rd/icu  

# git clone  https://github.com/libidn/libidn2.git  3rd/libidn2  

git clone  https://github.com/rockdaboot/libpsl.git  3rd/libpsl  
cd ./3rd/libpsl 
git checkout -b my-libpsl-0.21.0  libpsl-0.21.0
cd ../../    

git clone  https://github.com/curl/curl.git    3rd/curl   
cd ./3rd/curl 
git checkout -b my-curl-8_15_0  curl-8_15_0
cd ../../    


git clone  https://github.com/libjpeg-turbo/libjpeg-turbo.git  3rd/libjpeg-turbo  
cd ./3rd/libjpeg-turbo  
git checkout -b my-jpeg-9f jpeg-9f
cd ../../    


git clone  https://github.com/glennrp/libpng.git  3rd/libpng
cd ./3rd/libpng 
git checkout -b my-libpng-1.6.31-signed libpng-1.6.31-signed
cd ../../    



git clone  https://github.com/tukaani-project/xz.git  3rd/xz
cd ./3rd/xz 
git checkout -b my-v5.8.1 v5.8.1
cd ../../    

git clone  https://github.com/vadz/libtiff.git   3rd/libtiff
cd ./3rd/libtiff 
git checkout -b my-Release-v4-0-9  Release-v4-0-9
cd ../../    

git clone  https://github.com/freetype/freetype.git   3rd/freetype
cd ./3rd/freetype 
git checkout -b my-VER-2-13-3  VER-2-13-3
cd ../../    


git clone  https://github.com/libgeos/geos.git   3rd/geos
cd ./3rd/geos 
git checkout -b my-3.13.1 3.13.1
cd ../../    

git clone  https://github.com/sqlite/sqlite.git    3rd/sqlite
cd ./3rd/sqlite 
git checkout -b my-version-3.50.4 version-3.50.4
cd ../../    


git clone  https://github.com/OSGeo/PROJ.git    3rd/proj
cd ./3rd/proj 
git checkout -b my-9.6.2 9.6.2
cd ../../    


# git clone  https://github.com/libexpat/libexpat.git    3rd/libexpat

git clone  https://github.com/abseil/abseil-cpp.git   3rd/abseil-cpp
cd ./3rd/abseil-cpp
git checkout -b my-20250512.1   20250512.1 # 20250512.1 is a tag
cd ../../


git clone  https://github.com/protocolbuffers/protobuf.git   3rd/protobuf
cd ./3rd/protobuf 
git checkout  v32.0
git checkout -b my-v32.0 v32.0
cd ../../

# git clone  https://github.com/json-c/json-c.git  3rd/json-c

git clone  https://github.com/OSGeo/gdal.git   3rd/gdal
cd ./3rd/gdal  
git checkout -b my-v3.8.5 v3.8.5
cd ../../

# git clone  https://github.com/google/draco.git  3rd/osgdraco


# wget https://sourceforge.net/projects/boost/files/boost/1.88.0/boost_1_88_0.zip
# boost github:
git clone  https://github.com/boostorg/boost.git 3rd/boost
cd ./src/boost 
git checkout -b my-boost-1.70.0    boost-1.70.0
cd ../../

git clone https://github.com/openscenegraph/OpenSceneGraph.git  src/osg
cd ./src/osg 
git checkout -b my-OpenSceneGraph-3.6.5 tags/OpenSceneGraph-3.6.5
cd ../../


git clone https://github.com/nih-at/libzip.git 3rd/libzip
cd ./3rd/libzip 
git checkout  v1.11.4
cd ../../


# git clone https://github.com/gabime/spdlog.git  3rd/spdlog
# cd 3rd/spdlog
# git checkout  v1.11.4
# cd ../../
# # 编译并安装
# cmake .. -DSPDLOG_BUILD_EXAMPLE=OFF  # 禁用示例程序
# make -j$(nproc)
# sudo make install


git clone https://github.com/gwaldron/osgearth.git src/osgearth
cd ./src/osgearth 
git submodule update --init --recursive
git checkout  osgearth-3.1
cd ../../
