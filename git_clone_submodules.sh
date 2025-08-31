#!/bin/bash
 

# git submodule add -f -b v1.3.1 https://github.com/madler/zlib.git    3rd/zlib   
git clone  https://github.com/madler/zlib.git    3rd/zlib   
cd ./3rd/zlib 
git switch -c  v1.3.1  # git checkout  v1.3.1
cd ../../  

git clone https://github.com/facebook/zstd.git  3rd/zstd  
cd ./3rd/zstd 
git switch -c  v1.5.7
cd ../../   
  
#  git clone --recursive https://github.com/openssl/openssl.git  3rd/openssl   
git clone https://github.com/openssl/openssl.git   3rd/openssl   
cd ./3rd/openssl 
git switch -c  openssl-3.5.2
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
git switch -c  libpsl-0.21.0
cd ../../    

git clone  https://github.com/curl/curl.git    3rd/curl   
cd ./3rd/curl 
git switch -c  curl-8_15_0
cd ../../    


git clone  https://github.com/libjpeg-turbo/libjpeg-turbo.git  3rd/libjpeg-turbo  
cd ./3rd/libjpeg-turbo  
git switch -c  jpeg-9f
cd ../../    


git clone  https://github.com/glennrp/libpng.git  3rd/libpng
cd ./3rd/libpng 
git switch -c  libpng-1.6.31-signed
cd ../../    



git clone  https://github.com/tukaani-project/xz.git  3rd/xz
cd ./3rd/xz 
git switch -c  v5.8.1
cd ../../    

git clone  https://github.com/vadz/libtiff.git   3rd/libtiff
cd ./3rd/libtiff 
git switch -c  Release-v4-0-9
cd ../../    

git clone  https://github.com/freetype/freetype.git   3rd/freetype
cd ./3rd/freetype 
git switch -c  VER-2-13-3
cd ../../    


git clone  https://github.com/libgeos/geos.git   3rd/geos
cd ./3rd/geos 
git switch -c  3.13.1
cd ../../    

git clone  https://github.com/sqlite/sqlite.git    3rd/sqlite
cd ./3rd/sqlite 
git switch -c  version-3.50.4
cd ../../    


git clone  https://github.com/OSGeo/PROJ.git    3rd/proj
cd ./3rd/proj 
git switch -c  9.6.2
cd ../../    


# git clone  https://github.com/libexpat/libexpat.git    3rd/libexpat

git clone  https://github.com/abseil/abseil-cpp.git   3rd/abseil-cpp
cd ./3rd/zstd 
git switch -c  20250512.1
cd ../../


git clone  https://github.com/protocolbuffers/protobuf.git   3rd/protobuf
cd ./3rd/protobuf 
git switch -c  v32.0
cd ../../

# git clone  https://github.com/json-c/json-c.git  3rd/json-c

git clone  https://github.com/OSGeo/gdal.git   3rd/gdal
cd ./3rd/gdal 
git switch -c  v3.8.5
cd ../../

# git clone  https://github.com/google/draco.git  3rd/osgdraco


git clone https://github.com/openscenegraph/OpenSceneGraph.git  src/osg
# cd ./src/osg 
# git switch -c  v3.8.5-???
# cd ../../


git clone https://github.com/nih-at/libzip.git 3rd/libzip
cd ./3rd/libzip 
git switch -c  v1.11.4
cd ../../


# git clone https://github.com/gabime/spdlog.git  3rd/spdlog
# cd 3rd/spdlog
# git switch -c  v1.11.4
# cd ../../
# # 编译并安装
# cmake .. -DSPDLOG_BUILD_EXAMPLE=OFF  # 禁用示例程序
# make -j$(nproc)
# sudo make install


git clone https://github.com/gwaldron/osgearth.git src/osgearth
cd ./src/osgearth 
git submodule update --init --recursive
# git switch -c  v3.8.5-???
# cd ../../
