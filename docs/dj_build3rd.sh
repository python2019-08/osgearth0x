export ANDROID_NDK_HOME=/home/x12/work/ndk/android-ndk-r26d
export PATH=$ANDROID_NDK_HOME:$PATH


#1 zlib

git clone https://github.com/madler/zlib.git
cd zlib
mkdir build && cd build

Release:
cmake .. -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
         -DANDROID_ABI=armeabi-v7a \
         -DANDROID_NATIVE_API_LEVEL=24 \
         -DBUILD_SHARED_LIBS=OFF \
         -DCMAKE_INSTALL_PREFIX=/home/x12/work/3rd/zlib

Debug:

cmake .. -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
         -DANDROID_ABI=armeabi-v7a \
         -DANDROID_NATIVE_API_LEVEL=24 \
         -DBUILD_SHARED_LIBS=OFF \
         -DCMAKE_BUILD_TYPE=Debug \
         -DCMAKE_INSTALL_PREFIX=/home/x12/work/3rd/zlib


sudo make -j$(nproc)
sudo make install

#2 openssl

wget https://www.openssl.org/source/openssl-1.1.1w.tar.gz
tar -xzf openssl-1.1.1w.tar.gz
cd openssl-1.1.1w

mkdir build && cd build

#export ANDROID_NDK_ROOT=/home/x12/work/ndk/android-ndk-r26d
export ANDROID_NDK_HOME=/home/x12/work/ndk/android-ndk-r26d
export PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH


../Configure android-arm no-shared -D__ANDROID_API__=24 --prefix=/home/x12/work/3rd/openssl

make -j$(nproc)
sudo make install

../Configure android-arm -D__ANDROID_API__=24 \
  --prefix=/home/x12/work/3rd/openssl \
  --openssldir=/home/x12/work/3rd/openssl/ssl \
  no-shared

#3 curl

export ANDROID_NDK_HOME=/home/x12/work/ndk/android-ndk-r26d
export PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH
export CC=armv7a-linux-androideabi24-clang
export CXX=armv7a-linux-androideabi24-clang++
export CFLAGS="-D__ANDROID_API__=24"
export LDFLAGS="-L/home/x12/work/3rd/zlib/lib -L/home/x12/work/3rd/openssl/lib"
export CPPFLAGS="-I/home/x12/work/3rd/zlib/include -I/home/x12/work/3rd/openssl/include"

 ./buildconf
 cd build/
 ../configure --host=arm-linux-androideabi --prefix=/home/x12/work/3rd/curl --disable-shared --enable-static --with-openssl=/home/x12/work/3rd/openssl --with-zlib=/home/x12/work/3rd/zlib --with-libpsl=/home/x12/work/3rd/libpsl


debug:
../configure --host=arm-linux-androideabi --prefix=/home/x12/work/3rd/curl --disable-shared --enable-static --enable-debug --with-openssl=/home/x12/work/3rd/openssl --with-zlib=/home/x12/work/3rd/zlib --with-libpsl=/home/x12/work/3rd/libpsl


make -j$(nproc)
make install


git clone https://gitee.com/mirrors/curl.git

cd curl
mkdir build && cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
         -DANDROID_ABI=armeabi-v7a \
         -DANDROID_NATIVE_API_LEVEL=24 \
         -DBUILD_SHARED_LIBS=OFF \
         -DCMAKE_INSTALL_PREFIX=/home/x12/work/3rd/curl \
         -DCURL_USE_OPENSSL=ON \
         -DOPENSSL_ROOT_DIR=/home/x12/work/3rd/openssl \
         -DOPENSSL_LIBRARIES=/home/x12/work/3rd/openssl/lib \
         -DOPENSSL_INCLUDE_DIR=/home/x12/work/3rd/openssl/include \
         -DCMAKE_PREFIX_PATH=/home/x12/work/3rd/zlib
sudo make -j$(nproc)
sudo make install

#4 sqlite

#https://blog.csdn.net/weixin_38184741/article/details/93114720

echo "export ANDROID_NDK_HOME=/home/x12/work/ndk/android-ndk-r26d" >> ~/.bashrc  
echo "export PATH=\$PATH:\$ANDROID_NDK_HOME" >> ~/.bashrc  
source ~/.bashrc

export PATH=$PATH:$ANDROID_NDK_HOME

wget https://sqlite.org/2025/sqlite-autoconf-xxxxxxx.tar.gz  # 替换为实际版本链接:ml-citation{ref="1" data="citationList"}
tar -zxvf sqlite-autoconf-xxxxxxx.tar.gz
cd sqlite-autoconf-xxxxxxx


#ndk-build NDK_PROJECT_PATH=. APP_BUILD_SCRIPT=Android.mk NDK_APPLICATION_MK=Application.mk

ndk-build clean NDK_PROJECT_PATH=. APP_BUILD_SCRIPT=./Android.mk NDK_APPLICATION_MK=Application.mk

ndk-build NDK_PROJECT_PATH=. APP_BUILD_SCRIPT=./Android.mk NDK_APPLICATION_MK=Application.mk




#tiff

git clone https://gitlab.com/libtiff/libtiff.git

cd /home/fd/work/android/libtiff
mkdir build-android
cd build-android
cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=armeabi-v7a \
  -DANDROID_PLATFORM=android-24 \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_INSTALL_PREFIX=/home/x12/work/3rd/tiff \
  -DZLIB_ROOT=/home/x12/work/3rd/zlib \
  -DZLIB_LIBRARY=/home/x12/work/3rd/zlib/lib/libz.a \
  -DZLIB_INCLUDE_DIR=/home/x12/work/3rd/zlib/include \
  -DJPEG_LIBRARY=/home/x12/work/3rd/jpeg/lib/libjpeg.a \
  -DJPEG_INCLUDE_DIR=/home/x12/work/3rd/jpeg/include \
  -Djbig=OFF \
  -Dlzma=OFF \
  -Dwebp=OFF \
  -Dzstd=OFF

debug:

cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=armeabi-v7a \
  -DANDROID_PLATFORM=android-24 \
  -DCMAKE_BUILD_TYPE=Debug \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_INSTALL_PREFIX=/home/x12/work/3rd/tiff \
  -DZLIB_ROOT=/home/x12/work/3rd/zlib \
  -DZLIB_LIBRARY=/home/x12/work/3rd/zlib/lib/libz.a \
  -DZLIB_INCLUDE_DIR=/home/x12/work/3rd/zlib/include \
  -DJPEG_LIBRARY=/home/x12/work/3rd/jpeg/lib/libjpeg.a \
  -DJPEG_INCLUDE_DIR=/home/x12/work/3rd/jpeg/include \
  -Djbig=OFF \
  -Dlzma=OFF \
  -Dwebp=OFF \
  -Dzstd=OFF

make -j$(nproc)
make install


#5 proj

cd ~/work/android/proj
mkdir build && cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
         -DANDROID_ABI=armeabi-v7a \
         -DANDROID_NATIVE_API_LEVEL=24 \
         -DBUILD_SHARED_LIBS=OFF \
         -DCMAKE_INSTALL_PREFIX=/home/x12/work/3rd/proj \
         -DCURL_LIBRARY=/home/x12/work/3rd/curl/lib/libcurl.a \
         -DCURL_INCLUDE_DIR=/home/x12/work/3rd/curl/include \
	 -DSQLite3_LIBRARY=/home/x12/work/3rd/sqlite/lib/libsqlite3.a \
         -DSQLite3_INCLUDE_DIR=/home/x12/work/3rd/sqlite/include \
	 -DEXE_SQLITE3=/usr/bin/sqlite3 \
         -DBUILD_TESTING=OFF \
         -DBUILD_EXAMPLES=oFF \
         -DENABLE_TIFF=OFF \
         -DENABLE_CURL=ON \
	 -DCMAKE_HAVE_PTHREAD_H=ON \
  	 -DCMAKE_HAVE_LIBC_PTHREAD=ON \
  	 -DCMAKE_USE_PTHREADS_INIT=ON \
         -DCMAKE_PREFIX_PATH=/home/x12/work/3rd/sqlite:/home/x12/work/3rd/curl:/home/x12/work/3rd/openssl \
         -DCMAKE_VERBOSE_MAKEFILE=ON

#debug:

cmake .. -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
         -DANDROID_ABI=armeabi-v7a \
         -DANDROID_NATIVE_API_LEVEL=24 \
         -DBUILD_SHARED_LIBS=OFF \
         -DCMAKE_BUILD_TYPE=Debug \
         -DCMAKE_INSTALL_PREFIX=/home/x12/work/3rd/proj \
         -DCURL_LIBRARY=/home/x12/work/3rd/curl/lib/libcurl.a \
         -DCURL_INCLUDE_DIR=/home/x12/work/3rd/curl/include \
	 -DSQLite3_LIBRARY=/home/x12/work/3rd/sqlite/lib/libsqlite3.a \
         -DSQLite3_INCLUDE_DIR=/home/x12/work/3rd/sqlite/include \
	 -DEXE_SQLITE3=/usr/bin/sqlite3 \
         -DBUILD_TESTING=OFF \
         -DBUILD_EXAMPLES=OFF \
         -DENABLE_TIFF=OFF \
         -DENABLE_CURL=ON \
	 -DCMAKE_HAVE_PTHREAD_H=ON \
  	 -DCMAKE_HAVE_LIBC_PTHREAD=ON \
  	 -DCMAKE_USE_PTHREADS_INIT=ON \
         -DCMAKE_PREFIX_PATH=/home/x12/work/3rd/sqlite:/home/x12/work/3rd/curl:/home/x12/work/3rd/openssl \
         -DCMAKE_VERBOSE_MAKEFILE=ON



#shared
cmake .. -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
         -DANDROID_ABI=armeabi-v7a \
         -DANDROID_NATIVE_API_LEVEL=24 \
         -DBUILD_SHARED_LIBS=ON \
         -DCMAKE_INSTALL_PREFIX=/home/x12/work/3rd/proj \
         -DCURL_LIBRARY=/home/x12/work/3rd/curl/lib/libcurl.a \
         -DCURL_INCLUDE_DIR=/home/x12/work/3rd/curl/include \
	 -DSQLite3_LIBRARY=/home/x12/work/3rd/sqlite/lib/libsqlite3.a \
         -DSQLite3_INCLUDE_DIR=/home/x12/work/3rd/sqlite/include \
	 -DEXE_SQLITE3=/usr/bin/sqlite3 \
         -DBUILD_TESTING=OFF \
         -DBUILD_EXAMPLES=OFF \
         -DENABLE_TIFF=OFF \
         -DENABLE_CURL=ON \
	 -DCMAKE_HAVE_PTHREAD_H=ON \
  	 -DCMAKE_HAVE_LIBC_PTHREAD=ON \
  	 -DCMAKE_USE_PTHREADS_INIT=ON \
         -DCMAKE_PREFIX_PATH=/home/x12/work/3rd/sqlite:/home/x12/work/3rd/curl:/home/x12/work/3rd/openssl \
         -DCMAKE_VERBOSE_MAKEFILE=ON


cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=armeabi-v7a \
  -DANDROID_NATIVE_API_LEVEL=24 \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_INSTALL_PREFIX=/home/x12/work/3rd/curl \
  -DCURL_USE_OPENSSL=ON \
  -DOPENSSL_ROOT_DIR=/home/x12/work/3rd/openssl/armeabi-v7a \
  -DOPENSSL_LIBRARIES=/home/x12/work/3rd/openssl/lib/libcrypto.a\;/home/x12/work/3rd/openssl/lib/libssl.a \
  -DOPENSSL_INCLUDE_DIR=/home/x12/work/3rd/openssl/armeabi-v7a/include \
  -DCMAKE_PREFIX_PATH=/home/x12/work/3rd/zlib \
  -DSQLITE3_EXECUTABLE=/home/x12/work/3rd/sqlite/bin/sqlite3


make -j$(nproc)
make install


CFLAGS="-mthumb" CXXFLAGS="-mthumb" LIBS="-lstdc++" ../configure --prefix=/home/x12/work/3rd/proj --host=arm-linux-androideabi --enable-shared=no





#6 gdal

git clone https://github.com/OSGeo/gdal.git
cd gdal
mkdir build && cd build

rm -rf *  # Clear previous configuration
cmake .. -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
         -DANDROID_ABI=armeabi-v7a \
         -DANDROID_NATIVE_API_LEVEL=24 \
         -DBUILD_SHARED_LIBS=OFF \
         -DCMAKE_INSTALL_PREFIX=/home/x12/work/3rd/gdal \
         -DCMAKE_C_FLAGS="-fPIC" \
  	 -DCMAKE_CXX_FLAGS="-fPIC" \
         -DCMAKE_BUILD_TYPE=Release \
         -DZLIB_ROOT=/home/x12/work/3rd/zlib \
         -DOPENSSL_ROOT_DIR=/home/x12/work/3rd/openssl \
         -DOPENSSL_INCLUDE_DIR=/home/x12/work/3rd/openssl/include \
         -DOPENSSL_CRYPTO_LIBRARY=/home/x12/work/3rd/openssl/lib/libcrypto.a \
         -DOPENSSL_SSL_LIBRARY=/home/x12/work/3rd/openssl/lib/libssl.a \
         -DCURL_USE_OPENSSL=ON \
         -DCURL_LIBRARY=/home/x12/work/3rd/curl/lib/libcurl.a \
         -DCURL_INCLUDE_DIR=/home/x12/work/3rd/curl/include \
	 -DSQLITE3_LIBRARY=/home/x12/work/3rd/sqlite/lib/libsqlite3.a \
         -DSQLITE3_INCLUDE_DIR=/home/x12/work/3rd/sqlite/include \
         -DPROJ_LIBRARY=/home/x12/work/3rd/proj/lib/libproj.a \
         -DPROJ_INCLUDE_DIR=/home/x12/work/3rd/proj/include \
         -DProtobuf_LIBRARY=/home/x12/work/3rd/protobuf/lib/libprotobufd.a \
	 -DProtobuf_INCLUDE_DIR=/home/x12/work/3rd/protobuf/include \
	 -DGDAL_USE_PROTOBUF=ON \
         -DIconv_IS_BUILT_IN=OFF \
         -DBUILD_LIBICONV=OFF \
         -DGDAL_USE_LIBXML2=OFF \
         -DGDAL_USE_EXPAT=OFF \
         -DGDAL_USE_XERCESC=OFF \
         -DGDAL_USE_DEFLATE=OFF \
         -DGDAL_USE_CRYPTOPP=OFF \
         -DCMAKE_PREFIX_PATH=/home/x12/work/3rd/zlib:/home/x12/work/3rd/openssl:/home/x12/work/3rd/curl:/home/x12/work/3rd/sqlite:/home/x12/work/3rd/protobuf


#debug
cmake .. -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
         -DANDROID_ABI=armeabi-v7a \
         -DANDROID_NATIVE_API_LEVEL=24 \
         -DBUILD_SHARED_LIBS=OFF \
         -DCMAKE_INSTALL_PREFIX=/home/x12/work/3rd/gdal \
         -DCMAKE_C_FLAGS="-fPIC" \
         -DCMAKE_CXX_FLAGS="-fPIC" \
         -DCMAKE_BUILD_TYPE=Debug \
         -DZLIB_ROOT=/home/x12/work/3rd/zlib \
         -DOPENSSL_ROOT_DIR=/home/x12/work/3rd/openssl \
         -DOPENSSL_INCLUDE_DIR=/home/x12/work/3rd/openssl/include \
         -DOPENSSL_CRYPTO_LIBRARY=/home/x12/work/3rd/openssl/lib/libcrypto.a \
         -DOPENSSL_SSL_LIBRARY=/home/x12/work/3rd/openssl/lib/libssl.a \
         -DCURL_USE_OPENSSL=ON \
         -DCURL_LIBRARY=/home/x12/work/3rd/curl/lib/libcurl.a \
         -DCURL_INCLUDE_DIR=/home/x12/work/3rd/curl/include \
         -DSQLITE3_LIBRARY=/home/x12/work/3rd/sqlite/lib/libsqlite3.a \
         -DSQLITE3_INCLUDE_DIR=/home/x12/work/3rd/sqlite/include \
         -DPROJ_LIBRARY=/home/x12/work/3rd/proj/lib/libproj.a \
         -DPROJ_INCLUDE_DIR=/home/x12/work/3rd/proj/include \
         -DIconv_IS_BUILT_IN=OFF \
         -DBUILD_LIBICONV=OFF \
         -DGDAL_USE_LIBXML2=OFF \
         -DGDAL_USE_EXPAT=OFF \
         -DGDAL_USE_XERCESC=OFF \
         -DGDAL_USE_DEFLATE=OFF \
         -DGDAL_USE_CRYPTOPP=OFF \
         -DGDAL_USE_PROTOBUF=ON \
         -DPROTOBUF_LIBRARY=/home/x12/work/3rd/protobuf/lib/libprotobufd.a \
         -DPROTOBUF_INCLUDE_DIR=/home/x12/work/3rd/protobuf/include \
         -DCMAKE_PREFIX_PATH=/home/x12/work/3rd/zlib:/home/x12/work/3rd/openssl:/home/x12/work/3rd/curl:/home/x12/work/3rd/sqlite:/home/x12/work/3rd/protobuf


make -j8
make install

#png 

export ANDROID_NDK_HOME=/home/x12/work/ndk/android-ndk-r26d
export PATH=$ANDROID_NDK_HOME:$PATH

wget https://download.sourceforge.net/libpng/libpng-1.6.44.tar.gz
tar -xzf libpng-1.6.44.tar.gz
cd libpng-1.6.44


mkdir build && cd build
cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=armeabi-v7a \
  -DANDROID_NATIVE_API_LEVEL=24 \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/home/x12/work/3rd/png \
  -DBUILD_SHARED_LIBS=OFF \
  -DZLIB_ROOT=/home/x12/work/3rd/zlib \
  -DZLIB_INCLUDE_DIR=/home/x12/work/3rd/zlib/include \
  -DZLIB_LIBRARY=/home/x12/work/3rd/zlib/lib/libz.a\

#debug

cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=armeabi-v7a \
  -DANDROID_NATIVE_API_LEVEL=24 \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_INSTALL_PREFIX=/home/x12/work/3rd/png \
  -DBUILD_SHARED_LIBS=OFF \
  -DZLIB_ROOT=/home/x12/work/3rd/zlib \
  -DZLIB_INCLUDE_DIR=/home/x12/work/3rd/zlib/include \
  -DZLIB_LIBRARY=/home/x12/work/3rd/zlib/lib/libz.a

make -j8
make install

#jpeg

git clone https://github.com/libjpeg-turbo/libjpeg-turbo


cmake -G"Unix Makefiles" \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=armeabi-v7a \
  -DANDROID_ARM_MODE=arm \
  -DANDROID_PLATFORM=android-24 \
  -DCMAKE_ASM_FLAGS="--target=arm-linux-androideabi24" \
  -DENABLE_SHARED=OFF \
  -DENABLE_STATIC=ON \
  -DWITH_TURBOJPEG=ON \
  -DWITH_JPEG7=ON \
  -DCMAKE_INSTALL_PREFIX=/home/x12/work/3rd/jpeg \
  -DCMAKE_BUILD_TYPE=Release \
  ..


#debug

cmake -G"Unix Makefiles" \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=armeabi-v7a \
  -DANDROID_ARM_MODE=arm \
  -DANDROID_PLATFORM=android-24 \
  -DCMAKE_ASM_FLAGS="--target=arm-linux-androideabi24" \
  -DENABLE_SHARED=OFF \
  -DENABLE_STATIC=ON \
  -DWITH_TURBOJPEG=ON \
  -DWITH_JPEG7=ON \
  -DCMAKE_INSTALL_PREFIX=/home/x12/work/3rd/jpeg \
  -DCMAKE_BUILD_TYPE=Debug \
  ..

make
make install


#freetype

wget https://download.savannah.gnu.org/releases/freetype/freetype-2.13.3.tar.gz
tar -xzf freetype-2.13.3.tar.gz
cd freetype-2.13.3


../configure \
    --host=armv7a-linux-androideabi \
    --prefix=/home/x12/work/3rd/freetype \
    --enable-static=yes \
    --enable-shared=no \
    --with-zlib=no \
    --with-bzip2=no \
    --with-png=no \
    --with-harfbuzz=no \
    CC=/home/x12/work/ndk/android-ndk-r26d/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi24-clang \
    CFLAGS="-fPIC" \
    --with-sysroot=/home/x12/work/ndk/android-ndk-r26d/toolchains/llvm/prebuilt/linux-x86_64/sysroot

#freetype debug

export ANDROID_NDK_HOME=/home/x12/work/ndk/android-ndk-r26d
export PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH
export CC=armv7a-linux-androideabi24-clang
export CFLAGS="-fPIC -g -O0 -DDEBUG"
export CXXFLAGS="-g -O0 -DDEBUG"

../configure \
    --host=armv7a-linux-androideabi \
    --prefix=/home/x12/work/3rd/freetype \
    --enable-static=yes \
    --enable-shared=no \
    --with-zlib=no \
    --with-bzip2=no \
    --with-png=no \
    --with-harfbuzz=no \
    --with-sysroot=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot

make
make install


#geos

mkdir build && cd build

#Release

cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=armeabi-v7a \
  -DANDROID_NATIVE_API_LEVEL=24 \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/home/x12/work/3rd/geos \
  -DBUILD_SHARED_LIBS=OFF

#Debug
cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=armeabi-v7a \
  -DANDROID_NATIVE_API_LEVEL=24 \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_INSTALL_PREFIX=/home/x12/work/3rd/geos \
  -DBUILD_SHARED_LIBS=OFF

make -j$(nproc)
make install


#gdal
cd ~/osg-android
wget https://github.com/OSGeo/gdal/releases/download/v3.8.5/gdal-3.8.5.tar.gz
tar -xzf gdal-3.8.5.tar.gz
cd gdal-3.8.5

mkdir build && cd build
cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=armeabi-v7a \
  -DANDROID_NATIVE_API_LEVEL=24 \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/home/x12/work/3rd/gdal \
  -DBUILD_SHARED_LIBS=OFF \
  -DBUILD_APPS=OFF \
  -DCMAKE_C_FLAGS="-fPIC" \
  -DCMAKE_CXX_FLAGS="-fPIC" \
  -DZLIB_ROOT=/home/x12/work/3rd/zlib \
  -DZLIB_INCLUDE_DIR=/home/x12/work/3rd/zlib/include \
  -DZLIB_LIBRARY=/home/x12/work/3rd/zlib/lib/libz.a \
  -DPNG_PNG_INCLUDE_DIR=/home/x12/work/3rd/png/include/libpng16 \
  -DPNG_LIBRARY=/home/x12/work/3rd/png/lib/libpng.a \
  -DJPEG_INCLUDE_DIR=/home/x12/work/3rd/jpeg/include \
  -DJPEG_LIBRARY=/home/x12/work/3rd/jpeg/lib/libjpeg.a \
  -DCURL_INCLUDE_DIR=/home/x12/work/3rd/curl/include \
  -DCURL_LIBRARY=/home/x12/work/3rd/curl/lib/libcurl.a \
  -DSQLITE3_INCLUDE_DIR=/home/x12/work/3rd/sqlite/include \
  -DSQLITE3_LIBRARY=/home/x12/work/3rd/sqlite/lib/libsqlite3.a \
  -DGEOS_INCLUDE_DIR=/home/x12/work/3rd/geos/include \
  -DGEOS_LIBRARY=/home/x12/work/3rd/geos/lib/libgeos.a \
  -DPROJ_INCLUDE_DIR=/home/x12/work/3rd/proj/include \
  -DPROJ_LIBRARY=/home/x12/work/3rd/proj/lib/libproj.a \
  -DOPENSSL_ROOT_DIR=/home/x12/work/3rd/openssl \
  -DOPENSSL_INCLUDE_DIR=/home/x12/work/3rd/openssl/include \
  -DOPENSSL_CRYPTO_LIBRARY=/home/x12/work/3rd/openssl/lib/libcrypto.a \
  -DOPENSSL_SSL_LIBRARY=/home/x12/work/3rd/openssl/lib/libssl.a \
  -DGDAL_USE_OPENSSL=ON \
  -DGDAL_USE_ZLIB=ON \
  -DGDAL_USE_PNG=ON \
  -DGDAL_USE_JPEG=ON \
  -DGDAL_USE_CURL=ON \
  -DGDAL_USE_SQLITE3=ON \
  -DGDAL_USE_GEOS=ON \
  -DGDAL_USE_PROJ=ON \
  -DGDAL_USE_EXTERNAL_LIBS=ON \
  -DOGR_BUILD_OPTIONAL_DRIVERS=ON \
  -DOGR_ENABLE_DRIVER_MVT=ON


#Debug
cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=armeabi-v7a \
  -DANDROID_NATIVE_API_LEVEL=24 \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_INSTALL_PREFIX=/home/x12/work/3rd/gdal \
  -DBUILD_SHARED_LIBS=OFF \
  -DBUILD_APPS=OFF \
  -DBUILD_TESTING=OFF \
  -DCMAKE_C_FLAGS="-fPIC" \
  -DCMAKE_CXX_FLAGS="-fPIC" \
  -DZLIB_ROOT=/home/x12/work/3rd/zlib \
  -DZLIB_INCLUDE_DIR=/home/x12/work/3rd/zlib/include \
  -DZLIB_LIBRARY=/home/x12/work/3rd/zlib/lib/libz.a \
  -DPNG_PNG_INCLUDE_DIR=/home/x12/work/3rd/png/include/libpng16 \
  -DPNG_LIBRARY=/home/x12/work/3rd/png/lib/libpng.a \
  -DJPEG_INCLUDE_DIR=/home/x12/work/3rd/jpeg/include \
  -DJPEG_LIBRARY=/home/x12/work/3rd/jpeg/lib/libjpeg.a \
  -DCURL_INCLUDE_DIR=/home/x12/work/3rd/curl/include \
  -DCURL_LIBRARY=/home/x12/work/3rd/curl/lib/libcurl.a \
  -DSQLITE3_INCLUDE_DIR=/home/x12/work/3rd/sqlite/include \
  -DSQLITE3_LIBRARY=/home/x12/work/3rd/sqlite/lib/libsqlite3.a \
  -DGEOS_INCLUDE_DIR=/home/x12/work/3rd/geos/include \
  -DGEOS_LIBRARY=/home/x12/work/3rd/geos/lib/libgeos.a \
  -DPROJ_INCLUDE_DIR=/home/x12/work/3rd/proj/include \
  -DPROJ_LIBRARY=/home/x12/work/3rd/proj/lib/libproj.a \
  -DOPENSSL_ROOT_DIR=/home/x12/work/3rd/openssl \
  -DOPENSSL_INCLUDE_DIR=/home/x12/work/3rd/openssl/include \
  -DOPENSSL_CRYPTO_LIBRARY=/home/x12/work/3rd/openssl/lib/libcrypto.a \
  -DOPENSSL_SSL_LIBRARY=/home/x12/work/3rd/openssl/lib/libssl.a \
  -DPROTOBUF_LIBRARY=/home/x12/work/3rd/protobuf/lib/libprotobuf.a \
  -DPROTOBUF_INCLUDE_DIR=/home/x12/work/3rd/protobuf/include \
  -DGDAL_USE_OPENSSL=ON \
  -DGDAL_USE_ZLIB=ON \
  -DGDAL_USE_PNG=ON \
  -DGDAL_USE_JPEG=ON \
  -DGDAL_USE_CURL=ON \
  -DGDAL_USE_SQLITE3=ON \
  -DGDAL_USE_GEOS=ON \
  -DGDAL_USE_PROJ=ON \
  -DGDAL_USE_EXTERNAL_LIBS=ON \
  -DGDAL_USE_PROTOBUF=ON \
  -DOGR_BUILD_OPTIONAL_DRIVERS=ON \
  -DOGR_ENABLE_DRIVER_MVT=ON \
  -DCMAKE_PREFIX_PATH=/home/x12/work/3rd/zlib:/home/x12/work/3rd/openssl:/home/x12/work/3rd/curl:/home/x12/work/3rd/sqlite:/home/x12/work/3rd/protobuf


make -j8
make install


#osg

#git clone --recursive https://github.com/openscenegraph/OpenSceneGraph.git

git clone --recursive http://115.190.95.129/lidejun/osg.git

cd OpenSceneGraph
git checkout master

export ANDROID_NDK_HOME=/home/x12/work/ndk/android-ndk-r26d
export PATH=$ANDROID_NDK_HOME:$PATH

mkdir build && cd build

cd ~/osg-android/OpenSceneGraph/build_android_static_gles2
rm -rf *  # Clean previous configuration

cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=armeabi-v7a \
  -DANDROID_PLATFORM=24 \
  -DANDROID_STL=c++_static \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/home/x12/work/3rd/osg \
  -DDYNAMIC_OPENTHREADS=OFF \
  -DDYNAMIC_OPENSCENEGRAPH=OFF \
  -DOSG_GL1_AVAILABLE=OFF \
  -DOSG_GL2_AVAILABLE=OFF \
  -DOSG_GL3_AVAILABLE=OFF \
  -DOSG_GLES1_AVAILABLE=OFF \
  -DOSG_GLES2_AVAILABLE=OFF \
  -DOSG_GLES3_AVAILABLE=ON \
  -DOSG_GL_LIBRARY_STATIC=OFF \
  -DOSG_GL_DISPLAYLISTS_AVAILABLE=OFF \
  -DOSG_GL_MATRICES_AVAILABLE=OFF \
  -DOSG_GL_VERTEX_FUNCS_AVAILABLE=OFF \
  -DOSG_GL_VERTEX_ARRAY_FUNCS_AVAILABLE=OFF \
  -DOSG_GL_FIXED_FUNCTION_AVAILABLE=OFF \
  -DOPENGL_PROFILE="GLES3" \
  -DANDROID=ON \
  -DOSG_FIND_3RD_PARTY_DEPS=ON \
  -DCMAKE_C_FLAGS="-march=armv7-a -mfpu=neon  -DGLES32=1 -DGL_GLEXT_PROTOTYPES=1" \
  -DCMAKE_CXX_FLAGS="-std=c++14 -march=armv7-a -mfpu=neon  -DGL_GLEXT_PROTOTYPES=1" \
  -DZLIB_DIR=/home/x12/work/3rd/zlib \
  -DZLIB_INCLUDE_DIR=/home/x12/work/3rd/zlib/include \
  -DZLIB_LIBRARY=/home/x12/work/3rd/zlib/lib/libz.a \
  -DPNG_INCLUDE_DIR=/home/x12/work/3rd/png/include/libpng16 \
  -DPNG_LIBRARY=/home/x12/work/3rd/png/lib/libpng.a \
  -DJPEG_INCLUDE_DIR=/home/x12/work/3rd/jpeg/include \
  -DJPEG_LIBRARY=/home/x12/work/3rd/jpeg/lib/libjpeg.a \
  -DTIFF_INCLUDE_DIR=/home/x12/work/3rd/tiff/include \
  -DTIFF_LIBRARY=/home/x12/work/3rd/tiff/lib/libtiff.a \
  -DFREETYPE_DIR=/home/x12/work/3rd/freetype \
  -DFREETYPE_INCLUDE_DIRS=/home/x12/work/3rd/freetype/include/freetype2 \
  -DFREETYPE_LIBRARY=/home/x12/work/3rd/freetype/lib/libfreetype.a \
  -DCURL_DIR=/home/x12/work/3rd/curl \
  -DCURL_INCLUDE_DIR=/home/x12/work/3rd/curl/include \
  -DCURL_LIBRARY=/home/x12/work/3rd/curl/lib/libcurl.a \
  -DGDAL_DIR=/home/x12/work/3rd/gdal \
  -DGDAL_INCLUDE_DIR=/home/x12/work/3rd/gdal/include \
  -DGDAL_LIBRARY=/home/x12/work/3rd/gdal/lib/libgdal.a \
  -DCMAKE_EXE_LINKER_FLAGS="-llog -landroid" \
  -DCMAKE_FIND_ROOT_PATH=/home/x12/work/3rd \
  -DGDAL_DIR:PATH="/home/x12/work/3rd/gdal/include"


#osgearth

git clone --recurse-submodules https://github.com/gwaldron/osgearth.git

git clone --recurse-submodules http://115.190.95.129/lidejun/osgearth.git

cd ~/osg-android/osgearth
mkdir build && cd build

cmake .. \
  -DANDROID_NDK=$ANDROID_NDK_HOME \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
  -DOPENGL_PROFILE="GLES2" \
  -DDYNAMIC_OPENTHREADS=OFF \
  -DDYNAMIC_OPENSCENEGRAPH=OFF \
  -DANDROID_NATIVE_API_LEVEL=24 \
  -DANDROID_ABI=armeabi-v7a \
  -DOSGEARTH_ENABLE_FASTDXT=OFF \
  -DOSG_DIR=/home/x12/work/3rd/osg \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/home/x12/work/3rd/osgearth


mkdir build && cd build
cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=armeabi-v7a \
  -DANDROID_PLATFORM=24 \
  -DANDROID_STL=c++_static \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/home/x12/work/3rd/osgearth \
  -DDYNAMIC_OPENTHREADS=OFF \
  -DDYNAMIC_OPENSCENEGRAPH=OFF \
  -DOSGEARTH_ENABLE_FASTDXT=OFF \
  -DOSG_GL1_AVAILABLE=OFF \
  -DOSG_GL2_AVAILABLE=OFF \
  -DOSG_GL3_AVAILABLE=OFF \
  -DOSG_GLES1_AVAILABLE=OFF \
  -DOSG_GLES2_AVAILABLE=OFF \
  -DOSG_GLES3_AVAILABLE=ON \
  -DOSG_GL_LIBRARY_STATIC=OFF \
  -DOSG_GL_DISPLAYLISTS_AVAILABLE=OFF \
  -DOSG_GL_MATRICES_AVAILABLE=OFF \
  -DOSG_GL_VERTEX_FUNCS_AVAILABLE=OFF \
  -DOSG_GL_VERTEX_ARRAY_FUNCS_AVAILABLE=OFF \
  -DOSG_GL_FIXED_FUNCTION_AVAILABLE=OFF \
  -DOPENGL_PROFILE="GLES3" \
  -DANDROID=ON \
  -DOSG_DIR=/home/x12/work/3rd/osg \
  -DZLIB_ROOT=/home/x12/work/3rd/zlib \
  -DZLIB_INCLUDE_DIRS=/home/x12/work/3rd/zlib/include \
  -DZLIB_LIBRARIES=/home/x12/work/3rd/zlib/lib/libz.a \
  -DPNG_INCLUDE_DIRS=/home/x12/work/3rd/png/include/libpng16 \
  -DPNG_LIBRARIES=/home/x12/work/3rd/png/lib/libpng.a \
  -DJPEG_INCLUDE_DIRS=/home/x12/work/3rd/jpeg/include \
  -DJPEG_LIBRARIES=/home/x12/work/3rd/jpeg/lib/libjpeg.a \
  -DTIFF_INCLUDE_DIR=/home/x12/work/3rd/tiff/include \
  -DTIFF_LIBRARY=/home/x12/work/3rd/tiff/lib/libtiff.a \
  -DFREETYPE_ROOT=/home/x12/work/3rd/freetype \
  -DFREETYPE_INCLUDE_DIRS=/home/x12/work/3rd/freetype/include \
  -DFREETYPE_LIBRARIES=/home/x12/work/3rd/freetype/lib/libfreetype.a \
  -DCURL_ROOT=/home/x12/work/3rd/curl \
  -DCURL_INCLUDE_DIRS=/home/x12/work/3rd/curl/include \
  -DCURL_LIBRARIES=/home/x12/work/3rd/curl/lib/libcurl.a \
  -DSQLite3_INCLUDE_DIR=/home/x12/work/3rd/sqlite/include \
  -DSQLite3_LIBRARY=/home/x12/work/3rd/sqlite/lib/libsqlite3.a \
  -DGEOS_INCLUDE_DIR=/home/x12/work/3rd/geos/include \
  -DGEOS_LIBRARY=/home/x12/work/3rd/geos/lib/libgeos.a \
  -DPROJ_INCLUDE_DIR=/home/x12/work/3rd/proj/include \
  -DPROJ_LIBRARY=/home/x12/work/3rd/proj/lib/libproj.a \
  -DGDAL_ROOT=/home/x12/work/3rd/gdal \
  -DGDAL_INCLUDE_DIR=/home/x12/work/3rd/gdal/include \
  -DGDAL_LIBRARY=/home/x12/work/3rd/gdal/lib/libgdal.a \
  -DCMAKE_C_FLAGS="-march=armv7-a -mfpu=neon -DOSG_GLES3_AVAILABLE=1" \
  -DCMAKE_CXX_FLAGS="-march=armv7-a -mfpu=neon -DOSG_GLES3_AVAILABLE=1 -Wno-unused-but-set-variable" \
  -DCMAKE_EXE_LINKER_FLAGS="-llog -landroid" \
  -DCMAKE_FIND_ROOT_PATH=/home/x12/work/3rd

make -j8
make install

export ANDROID_NDK_HOME=/home/x12/work/ndk/android-ndk-r26d
export PATH=$ANDROID_NDK_HOME:$PATH


cd /home/fd/work/android/osgearth/build
rm -rf *  # Clean previous configuration

cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=armeabi-v7a \
  -DANDROID_PLATFORM=android-24 \
  -DANDROID_STL=c++_static \
  -DCMAKE_BUILD_TYPE=Release \
  -DOSGEARTH_BUILD_SHARED_LIBS=OFF \
  -DOSGEARTH_ENABLE_FASTDXT=OFF \
  -DOSGEARTH_BUILD_TOOLS=OFF \
  -DOSGEARTH_BUILD_EXAMPLES=OFF \
  -DOSG_GL1_AVAILABLE=OFF \
  -DOSG_GL2_AVAILABLE=OFF \
  -DOSG_GL3_AVAILABLE=OFF \
  -DOSG_GLES1_AVAILABLE=OFF \
  -DOSG_GLES2_AVAILABLE=OFF \
  -DOSG_GLES3_AVAILABLE=ON \
  -DOSG_GL_LIBRARY_STATIC=OFF \
  -DOSG_GL_DISPLAYLISTS_AVAILABLE=OFF \
  -DOSG_GL_MATRICES_AVAILABLE=OFF \
  -DOSG_GL_VERTEX_FUNCS_AVAILABLE=OFF \
  -DOSG_GL_VERTEX_ARRAY_FUNCS_AVAILABLE=OFF \
  -DOSG_GL_FIXED_FUNCTION_AVAILABLE=OFF \
  -DOPENGL_PROFILE="GLES3" \
  -DANDROID=ON \
  -DCMAKE_PREFIX_PATH="/home/x12/work/3rd/libzip;/home/x12/work/3rd/osg;/home/x12/work/3rd/gdal;/home/x12/work/3rd/geos;/home/x12/work/3rd/curl" \
  -DCMAKE_INSTALL_PREFIX=/home/x12/work/3rd/osgearth \
  -DOPENGL_opengl_LIBRARY=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/arm-linux-androideabi/24/libGLESv3.so \
  -DOPENGL_glx_LIBRARY=NOTFOUND \
  -DOPENGL_EGL_LIBRARY=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/arm-linux-androideabi/24/libEGL.so \
  -DOPENGL_INCLUDE_DIR=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include \
  -DOSG_LIBRARY=/home/x12/work/3rd/osg/lib/libosg.a \
  -DOSGDB_LIBRARY=/home/x12/work/3rd/osg/lib/libosgDB.a \
  -DOSGTEXT_LIBRARY=/home/x12/work/3rd/osg/lib/libosgText.a \
  -DOSGUTIL_LIBRARY=/home/x12/work/3rd/osg/lib/libosgUtil.a \
  -DOSGGA_LIBRARY=/home/x12/work/3rd/osg/lib/libosgGA.a \
  -DOSGVIEWER_LIBRARY=/home/x12/work/3rd/osg/lib/libosgViewer.a \
  -DOSGSIM_LIBRARY=/home/x12/work/3rd/osg/lib/libosgSim.a \
  -DOSGSHADOW_LIBRARY=/home/x12/work/3rd/osg/lib/libosgShadow.a \
  -DOSGMANIPULATOR_LIBRARY=/home/x12/work/3rd/osg/lib/libosgManipulator.a \
  -DOPENTHREADS_LIBRARY=/home/x12/work/3rd/osg/lib/libOpenThreads.a \
  -DOSG_INCLUDE_DIR=/home/x12/work/3rd/osg/include \
  -DOSGDB_INCLUDE_DIR=/home/x12/work/3rd/osg/include \
  -DOSGTEXT_INCLUDE_DIR=/home/x12/work/3rd/osg/include \
  -DOSGUTIL_INCLUDE_DIR=/home/x12/work/3rd/osg/include \
  -DOSGGA_INCLUDE_DIR=/home/x12/work/3rd/osg/include \
  -DOSGVIEWER_INCLUDE_DIR=/home/x12/work/3rd/osg/include \
  -DOSGSIM_INCLUDE_DIR=/home/x12/work/3rd/osg/include \
  -DOSGSHADOW_INCLUDE_DIR=/home/x12/work/3rd/osg/include \
  -DOSGMANIPULATOR_INCLUDE_DIR=/home/x12/work/3rd/osg/include \
  -DOPENTHREADS_INCLUDE_DIR=/home/x12/work/3rd/osg/include \
  -DLIBZIP_DIR=/home/x12/work/3rd/libzip \
  -DLIBZIP_LIBRARY=/home/x12/work/3rd/libzip/lib/libzip.a \
  -DLIBZIP_INCLUDE_DIR=/home/x12/work/3rd/libzip/include \
  -DZLIB_ROOT=/home/x12/work/3rd/zlib \
  -DZLIB_INCLUDE_DIR=/home/x12/work/3rd/zlib/include \
  -DZLIB_LIBRARY=/home/x12/work/3rd/zlib/lib/libz.a \
  -DPNG_INCLUDE_DIRS=/home/x12/work/3rd/png/include/libpng16 \
  -DPNG_LIBRARY=/home/x12/work/3rd/png/lib/libpng.a \
  -DJPEG_INCLUDE_DIRS=/home/x12/work/3rd/jpeg/include \
  -DJPEG_LIBRARY=/home/x12/work/3rd/jpeg/lib/libjpeg.a \
  -DTIFF_INCLUDE_DIR=/home/x12/work/3rd/tiff/include \
  -DTIFF_LIBRARY=/home/x12/work/3rd/tiff/lib/libtiff.a \
  -DFREETYPE_ROOT=/home/x12/work/3rd/freetype \
  -DFREETYPE_INCLUDE_DIR=/home/x12/work/3rd/freetype/include \
  -DFREETYPE_LIBRARY=/home/x12/work/3rd/freetype/lib/libfreetype.a \
  -DCURL_ROOT=/home/x12/work/3rd/curl \
  -DCURL_INCLUDE_DIR=/home/x12/work/3rd/curl/include \
  -DCURL_LIBRARY=/home/x12/work/3rd/curl/lib/libcurl.a \
  -DSQLite3_INCLUDE_DIR=/home/x12/work/3rd/sqlite/include \
  -DSQLite3_LIBRARY=/home/x12/work/3rd/sqlite/lib/libsqlite3.a \
  -DGEOS_INCLUDE_DIR=/home/x12/work/3rd/geos/include \
  -DGEOS_LIBRARY=/home/x12/work/3rd/geos/lib/libgeos.a \
  -DPROJ_INCLUDE_DIR=/home/x12/work/3rd/proj/include \
  -DPROJ_LIBRARY=/home/x12/work/3rd/proj/lib/libproj.a \
  -DGDAL_ROOT=/home/x12/work/3rd/gdal \
  -DGDAL_INCLUDE_DIR=/home/x12/work/3rd/gdal/include \
  -DGDAL_LIBRARY=/home/x12/work/3rd/gdal/lib/libgdal.a



#libzip
git clone https://github.com/nih-at/libzip.git

mkdir build && cd build


cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=armeabi-v7a \
  -DANDROID_PLATFORM=android-24 \
  -DANDROID_STL=c++_static \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_INSTALL_PREFIX=/home/x12/work/3rd/libzip \
  -DZLIB_LIBRARY=/home/x12/work/3rd/zlib/lib/libz.a \
  -DZLIB_INCLUDE_DIR=/home/x12/work/3rd/zlib/include \
  -DENABLE_COMMONCRYPTO=OFF \
  -DENABLE_GNUTLS=OFF \
  -DENABLE_MBEDTLS=OFF \
  -DENABLE_OPENSSL=OFF \
  -DBUILD_TOOLS=OFF \
  -DBUILD_EXAMPLES=OFF

#Debug
cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=armeabi-v7a \
  -DANDROID_PLATFORM=android-24 \
  -DANDROID_STL=c++_static \
  -DCMAKE_BUILD_TYPE=Debug \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_INSTALL_PREFIX=/home/x12/work/3rd/libzip \
  -DZLIB_LIBRARY=/home/x12/work/3rd/zlib/lib/libz.a \
  -DZLIB_INCLUDE_DIR=/home/x12/work/3rd/zlib/include \
  -DENABLE_COMMONCRYPTO=OFF \
  -DENABLE_GNUTLS=OFF \
  -DENABLE_MBEDTLS=OFF \
  -DENABLE_OPENSSL=OFF \
  -DBUILD_TOOLS=OFF \
  -DBUILD_EXAMPLES=OFF


#protobuf

git clone https://github.com/protocolbuffers/protobuf.git

cmake .. \
    -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
    -DANDROID_ABI=armeabi-v7a \
    -DANDROID_PLATFORM=android-24 \
    -DANDROID_STL=c++_static \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_INSTALL_PREFIX=/home/x12/work/3rd/protobuf \
    -Dprotobuf_BUILD_TESTS=OFF \
    -Dprotobuf_BUILD_EXAMPLES=OFF \
    -Dprotobuf_BUILD_PROTOC_BINARIES=OFF \
    -Dprotobuf_PROTOC_EXE=/home/x12/work/3rd/protobuf_host/bin/protoc \
    -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY

#Configuring incomplete, errors occurred!
cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=armeabi-v7a \
  -DANDROID_NATIVE_API_LEVEL=24 \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_BUILD_TYPE=Debug \
  -CMAKE_INSTALL_PREFIX=/home/x12/work/3rd/protobuf \
  -Dprotobuf_BUILD_TESTS=OFF \
  -Dprotobuf_WITH_ZLIB=OFF \
  -Dprotobuf_BUILD_PROTOC_BINARIES=OFF












