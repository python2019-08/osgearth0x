#!/bin/bash
 

# git submodule add -f -b v1.3.1 https://github.com/madler/zlib.git    3rd/zlib   
git clone  https://github.com/madler/zlib.git    3rd/zlib   
 

git clone https://github.com/facebook/zstd.git  3rd/zstd  
 
  
git clone https://github.com/openssl/openssl.git   3rd/openssl   
#  git clone --recursive https://github.com/openssl/openssl.git  3rd/openssl 
# if [ -f "./3rd/openssl/.gitmodules" ]; then
#     cd 3rd/openssl
#     git submodule update --init --recursive --progress -v
#     cd ../../
# fi


# git clone  https://github.com/unicode-org/icu.git  3rd/icu  

# git clone  https://github.com/libidn/libidn2.git  3rd/libidn2  

git clone  https://github.com/rockdaboot/libpsl.git  3rd/libpsl  
 

git clone  https://github.com/curl/curl.git    3rd/curl   
 

git clone  https://github.com/libjpeg-turbo/libjpeg-turbo.git  3rd/libjpeg-turbo  


git clone  https://github.com/glennrp/libpng.git  3rd/libpng


git clone  https://github.com/tukaani-project/xz.git  3rd/xz


git clone  https://github.com/vadz/libtiff.git   3rd/libtiff


git clone  https://github.com/freetype/freetype.git   3rd/freetype


git clone  https://github.com/libgeos/geos.git   3rd/geos


git clone  https://github.com/sqlite/sqlite.git    3rd/sqlite

git clone  https://github.com/OSGeo/PROJ.git    3rd/proj

# git clone  https://github.com/libexpat/libexpat.git    3rd/libexpat

git clone  https://github.com/protocolbuffers/protobuf.git   3rd/protobuf

# git clone  https://github.com/json-c/json-c.git  3rd/json-c

git clone  https://github.com/OSGeo/gdal.git   3rd/gdal

# git clone  https://github.com/google/draco.git  3rd/osgdraco
