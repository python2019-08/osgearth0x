# 1. how to build on ubuntu 24.04

## 1.1 use mk4ubuntu.sh to build 
```sh
$ git clone https://github.com/python2019-08/osgearth0x.git

$ cd osgearth0x

# $ git submodule update --init --recursive --progress -v
$ chmod 777 ./git_clone_modules.sh  && ./git_clone_modules.sh 

$   ./mk4ubuntu.sh  >b0sh.txt 2>&1
```

# 2. osg data url

osg data download url:
https://openscenegraph.github.io/OpenSceneGraphDotComBackup/OpenSceneGraph/www.openscenegraph.com/index.php/download-section/data.html

[OpenSceneGraph-Data ](https://github.com/openscenegraph/OpenSceneGraph-Data.git)


# 3. about cmake/FindZLIB.cmake && cmake/FindSQLite3.cmake

cmake/FindZLIB.cmake is copy from  /usr/share/cmake-3.28/Modules/FindZLIB.cmake of  ubuntu 24.04
```sh
#---- on ubuntu 24.04 
$ cp /usr/share/cmake-3.28/Modules/FindZLIB.cmake  ./cmake/
```
 
cmake/FindSQLite3.cmake is copy from  /usr/share/cmake-3.28/Modules/FindSQLite3.cmake of  ubuntu 24.04
```sh
#---- on ubuntu 24.04 
 cp /usr/share/cmake-3.28/Modules/FindSQLite3.cmake  ./cmake/
``` 