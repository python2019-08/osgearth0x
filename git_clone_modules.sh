#!/bin/bash
 

git submodule add https://github.com/madler/zlib.git    3rd/zlib  -b v1.3.1
if [ -f "./3rd/zlib/.gitmodules" ]; then
    cd 3rd/zlib
    git submodule update --init --recursive --progress -v
    cd ../../
fi

git submodule add https://github.com/facebook/zstd.git  3rd/zstd  -b v1.5.7
if [ -f "./3rd/zstd/.gitmodules" ]; then
    cd 3rd/zstd
    git submodule update --init --recursive --progress -v
    cd ../../
fi

git submodule add https://github.com/openssl/openssl.git 3rd/openssl -b openssl-3.5.2
if [ -f "./3rd/openssl/.gitmodules" ]; then
    cd 3rd/openssl
    git submodule update --init --recursive --progress -v
    cd ../../
fi


git submodule add https://github.com/rockdaboot/libpsl.git 3rd/libpsl -b libpsl-0.21.0
if [ -f "./3rd/libpsl/.gitmodules" ]; then
    cd 3rd/libpsl
    git submodule update --init --recursive --progress -v
    cd ../../
fi


git submodule add https://github.com/curl/curl.git   3rd/curl -b curl-8_15_0
if [ -f "./3rd/curl/.gitmodules" ]; then
    cd 3rd/curl
    git submodule update --init --recursive --progress -v
    cd ../../
fi


git submodule add https://github.com/libjpeg-turbo/libjpeg-turbo.git  3rd/libjpeg-turbo -b jpeg-9f
if [ -f "./3rd/libjpeg-turbo/.gitmodules" ]; then
    cd 3rd/libjpeg-turbo
    git submodule update --init --recursive --progress -v
    cd ../../
fi
