# 1. how to build on ubuntu 24.04
<!-- 
(1)
3rd/osg/**/*.txt*,3rd/osg/**/*.cmake

(2)gdal 的cmake脚本 需要改
(3)osg、osgearth 的cmake脚本需要改
--> 
```sh
# ------安装编译工具
sudo apt update
# osg compiling need "libgl1-mesa-dev  libglu1-mesa-dev  libxext-dev "
sudo apt-get install -y   build-essential autoconf  automake   libtool \
    pkg-config   gettext gettext-base  autopoint gtk-doc-tools \
    cmake  ninja-build   git  wget  unzip  python3  openjdk-11-jdk  \
    openjdk-11-jdk  libgl1-mesa-dev  libglu1-mesa-dev  libxext-dev 

# 注：我用的cmake 版本3.28.3；如果在其他地方用的cmake版本最好大于等于这个版本，否则可能编译出错
$ cmake --version
cmake version 3.28.3


# ------下载代码
$ git clone https://github.com/python2019-08/osgearth0x.git

$ cd osgearth0x

# $ git submodule update --init --recursive --progress -v
$ chmod 777 ./download_submodules.sh  && ./download_submodules.sh 

# ------编译Ubuntu版
$   ./mk4ubuntu.sh  >bu.txt 2>&1
# 在bu.txt中查询"cmake error" 或“error:” 以确定有无错误

# ------编译Android版
# build 3rd *.a for android
$   ./mk4android.sh  >ba.txt 2>&1
```

# 2. osg data url

osg data download url:
https://openscenegraph.github.io/OpenSceneGraphDotComBackup/OpenSceneGraph/www.openscenegraph.com/index.php/download-section/data.html

[OpenSceneGraph-Data ](https://github.com/openscenegraph/OpenSceneGraph-Data.git)


# 3. about cmake/FindZLIB.cmake  
cmake/FindZLIB.cmake is copy from  /usr/share/cmake-3.28/Modules/FindZLIB.cmake of  ubuntu 24.04
```sh
#---- on ubuntu 24.04 
$ cp /usr/share/cmake-3.28/Modules/FindZLIB.cmake  ./cmake/
```
 
 <!-- /usr/share/cmake-3.28/Modules/FindSQLite3.cmake   -->

# 4. 如何处理 静态库的依赖顺序

https://github.com/python2019-08/a-md01.git 

"md_CMake/professional-cmake/20libraries-append.md"  /  "# 3.静态库的依赖顺序问题"
