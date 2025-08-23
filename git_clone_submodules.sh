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


git clone  https://github.com/rockdaboot/libpsl.git  3rd/libpsl  
 

git clone  https://github.com/curl/curl.git    3rd/curl   
 

git clone  https://github.com/libjpeg-turbo/libjpeg-turbo.git  3rd/libjpeg-turbo  



