# 1. ./build/ubuntu-dbg-static/bin/osgearth_viewer 依赖的osg 相关的库都是.a

<!-- 腾讯元宝答案 -->

如果 `osgearth_viewer` 依赖的 OSG（OpenSceneGraph）相关库都是静态库（`.a` 文件），说明你的构建配置可能启用了静态链接（`BUILD_SHARED_LIBS=OFF`）。以下是针对此情况的解决方案和注意事项：

---

### **1. 确认依赖库状态**
运行以下命令检查 `osgearth_viewer` 的链接方式：
```bash
ldd ./build/ubuntu-dbg-static/bin/osgearth_viewer
```
- 如果输出显示 **`not a dynamic executable`**，说明程序是静态链接的。
- 如果显示动态库（`.so`），则实际为动态链接。

---

### **2. 静态链接的常见问题**
#### **(1) 缺少静态依赖库**
静态链接要求所有依赖库（如 GDAL、libcurl、zlib 等）也必须提供静态版本（`.a`）。若缺少某个静态库，链接会失败。

**解决方法**：
- 安装缺失的静态库（Ubuntu 示例）：
  ```bash
  sudo apt install libgdal-dev libcurl4-openssl-dev zlib1g-dev libpng-dev
  ```
- 手动编译依赖库并生成 `.a` 文件。

#### **(2) 符号冲突**
多个静态库可能包含相同符号（如不同版本的 OpenGL 或 STL），导致链接错误。

**解决方法**：
- 确保所有静态库使用相同的编译选项（如 `-fPIC`）。
- 统一依赖库的版本（如全部从源码编译）。

#### **(3) 运行时初始化问题**
静态库的全局变量初始化顺序可能导致崩溃（如 OSG 插件未注册）。

**解决方法**：
- 显式加载插件（在代码中调用 `osgDB::Registry::instance()->loadLibrary()`）。

---

### **3. 静态链接的构建配置**
#### **(1) 检查 CMake 构建选项**
在构建 osgEarth 时，以下选项影响链接方式：
```bash
cmake \
  -DBUILD_SHARED_LIBS=OFF \          # 强制静态链接
  -DOSG_BUILD_TYPE=Static \          # OSG 静态构建
  -DCMAKE_FIND_LIBRARY_SUFFIXES=.a \ # 优先查找 .a 文件
  ..
```

#### **(2) 确保依赖库被正确找到**
检查 CMake 日志，确认以下库被找到并是静态版本：
```bash
-- Found GDAL: /usr/lib/libgdal.a
-- Found CURL: /usr/lib/x86_64-linux-gnu/libcurl.a
-- Found OpenSceneGraph: /usr/local/lib/libosg.a
```

---

### **4. 解决动态库与静态库混合问题**
如果部分库是动态链接的（如系统自带的 `libGL.so`），需确保兼容性：
#### **(1) 强制静态链接 GL**
在 CMake 中指定 GL 的静态库路径：
```cmake
find_package(OpenGL REQUIRED)
target_link_libraries(osgearth_viewer ${OPENGL_gl_LIBRARY})
```

#### **(2) 处理插件加载**
静态链接时，OSG 插件需直接编译到程序中：
```cmake
# 将插件代码直接链接到主程序
add_library(osgdb_osg STATIC IMPORTED)
target_link_libraries(osgearth_viewer osgdb_osg)
```

---

### **5. 调试静态链接问题**
#### **(1) 查看链接符号**
使用 `nm` 检查静态库中的符号：
```bash
nm ./build/ubuntu-dbg-static/lib/libosgEarth.a | grep "MapNode"
```

#### **(2) 检查未定义符号**
如果运行时崩溃，可能是某些符号未链接：
```bash
nm ./build/ubuntu-dbg-static/bin/osgearth_viewer | grep "undefined"
```

#### **(3) 加载核心转储**
如果程序崩溃，分析核心转储：
```bash
gdb ./build/ubuntu-dbg-static/bin/osgearth_viewer core
(gdb) bt
```

---

### **6. 示例：静态链接的完整构建流程**
```bash
# 1. 安装依赖（静态库）
sudo apt install libgdal-dev libcurl4-openssl-dev zlib1g-dev libpng-dev

# 2. 编译 OSG（静态）
git clone https://github.com/openscenegraph/OpenSceneGraph
cd OpenSceneGraph
cmake -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=/usr/local/osg-static ..
make -j8
sudo make install

# 3. 编译 osgEarth（静态）
cd /path/to/osgearth
cmake \
  -DBUILD_SHARED_LIBS=OFF \
  -DOSG_DIR=/usr/local/osg-static \
  -DCMAKE_PREFIX_PATH=/usr/local/osg-static ..
make -j8
```

---

### **7. 常见错误与解决**
| 错误现象                          | 可能原因                  | 解决方案                          |
|-----------------------------------|--------------------------|----------------------------------|
| `undefined reference to symbol`   | 缺少静态依赖库            | 安装对应的 `-dev` 包或源码编译    |
| `GLIBCXX_3.4.29 not found`        | 静态库与编译器版本不兼容    | 统一使用相同版本的 GCC 和库       |
| 运行时崩溃                        | 插件未加载或初始化顺序错误  | 显式调用 `osgDB::Registry::loadLibrary()` |

---

### **总结**
- **静态链接的优势**：部署简单（单文件）、版本控制一致。  
- **静态链接的代价**：构建复杂、二进制体积大、内存占用高。  
- **关键检查点**：  
  1. 所有依赖库必须提供 `.a` 文件。  
  2. 避免符号冲突（统一编译环境）。  
  3. 显式处理插件和全局初始化。  

如果仍有问题，请提供：  
- `cmake` 构建日志。  
- `nm` 或 `ldd` 的输出。  
- 崩溃时的调用栈（`bt`）。

==============================================
# 2.但是 ./build/ubuntu-dbg-static/bin/osgearth_viewer依赖的osg相关库都是静态库，为何gdb 调试时用到动态库

```sh
# ./build/ubuntu-dbg-static/bin/osgearth_viewer依赖的osg相关库都是静态库，为何gdb 调试时用到动态库
$ ldd ./build/ubuntu-dbg-static/bin/osgearth_viewer
	linux-vdso.so.1 (0x00007d9e70a5c000)
	libspdlog.so.1.11 => /home/abner/programs/miniconda3/lib/libspdlog.so.1.11 (0x00007d9e6f784000)
	libgeos_c.so.1 => /lib/x86_64-linux-gnu/libgeos_c.so.1 (0x00007d9e6f73b000)
	libOpenGL.so.0 => /lib/x86_64-linux-gnu/libOpenGL.so.0 (0x00007d9e70a2b000)
	libcurl.so.4 => /lib/x86_64-linux-gnu/libcurl.so.4 (0x00007d9e6f67a000)
	libgdal.so.34 => /lib/x86_64-linux-gnu/libgdal.so.34 (0x00007d9e6de00000)
	libstdc++.so.6 => /lib/x86_64-linux-gnu/libstdc++.so.6 (0x00007d9e6da00000)
	libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007d9e6dd17000)
	libgcc_s.so.1 => /lib/x86_64-linux-gnu/libgcc_s.so.1 (0x00007d9e6f64c000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007d9e6d600000)
	libfmt.so.9 => /home/abner/programs/miniconda3/lib/./libfmt.so.9 (0x00007d9e6f627000)
	libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007d9e70a22000)
	/lib64/ld-linux-x86-64.so.2 (0x00007d9e70a5e000)
	libgeos.so.3.12.1 => /lib/x86_64-linux-gnu/libgeos.so.3.12.1 (0x00007d9e6d200000)
	libGLdispatch.so.0 => /lib/x86_64-linux-gnu/libGLdispatch.so.0 (0x00007d9e6d948000)
	libnghttp2.so.14 => /lib/x86_64-linux-gnu/libnghttp2.so.14 (0x00007d9e6f5fc000)
	libidn2.so.0 => /lib/x86_64-linux-gnu/libidn2.so.0 (0x00007d9e6f5da000)
	librtmp.so.1 => /lib/x86_64-linux-gnu/librtmp.so.1 (0x00007d9e6dcf9000)
	libssh.so.4 => /lib/x86_64-linux-gnu/libssh.so.4 (0x00007d9e6dc88000)
	libpsl.so.5 => /lib/x86_64-linux-gnu/libpsl.so.5 (0x00007d9e6d934000)
	libssl.so.3 => /lib/x86_64-linux-gnu/libssl.so.3 (0x00007d9e6d88a000)
	libcrypto.so.3 => /lib/x86_64-linux-gnu/libcrypto.so.3 (0x00007d9e6cc00000)
	libgssapi_krb5.so.2 => /lib/x86_64-linux-gnu/libgssapi_krb5.so.2 (0x00007d9e6d836000)
	libldap.so.2 => /lib/x86_64-linux-gnu/libldap.so.2 (0x00007d9e6d5a2000)
	liblber.so.2 => /lib/x86_64-linux-gnu/liblber.so.2 (0x00007d9e6d826000)
	libzstd.so.1 => /lib/x86_64-linux-gnu/libzstd.so.1 (0x00007d9e6d4e8000)
	libbrotlidec.so.1 => /lib/x86_64-linux-gnu/libbrotlidec.so.1 (0x00007d9e6d818000)
	libz.so.1 => /lib/x86_64-linux-gnu/libz.so.1 (0x00007d9e6d4cc000)
	libodbc.so.2 => /lib/x86_64-linux-gnu/libodbc.so.2 (0x00007d9e6d190000)
	libodbcinst.so.2 => /lib/x86_64-linux-gnu/libodbcinst.so.2 (0x00007d9e6d4b8000)
	libxml2.so.2 => /lib/x86_64-linux-gnu/libxml2.so.2 (0x00007d9e6ca1e000)
	liblzma.so.5 => /lib/x86_64-linux-gnu/liblzma.so.5 (0x00007d9e6d486000)
	libdeflate.so.0 => /lib/x86_64-linux-gnu/libdeflate.so.0 (0x00007d9e6d473000)
	liblz4.so.1 => /lib/x86_64-linux-gnu/liblz4.so.1 (0x00007d9e6d16e000)
	libblosc.so.1 => /lib/x86_64-linux-gnu/libblosc.so.1 (0x00007d9e6d15e000)
	libarmadillo.so.12 => /lib/libarmadillo.so.12 (0x00007d9e6d12d000)
	libqhull_r.so.8.0 => /lib/x86_64-linux-gnu/libqhull_r.so.8.0 (0x00007d9e6c9ae000)
	libxerces-c-3.2.so => /lib/x86_64-linux-gnu/libxerces-c-3.2.so (0x00007d9e6c600000)
	libjpeg.so.8 => /lib/x86_64-linux-gnu/libjpeg.so.8 (0x00007d9e6c57d000)
	libtiff.so.6 => /lib/x86_64-linux-gnu/libtiff.so.6 (0x00007d9e6c4f0000)
	libgeotiff.so.5 => /lib/x86_64-linux-gnu/libgeotiff.so.5 (0x00007d9e6c978000)
	libheif.so.1 => /lib/x86_64-linux-gnu/libheif.so.1 (0x00007d9e6c430000)
	libpng16.so.16 => /lib/x86_64-linux-gnu/libpng16.so.16 (0x00007d9e6c3f8000)
	libaec.so.0 => /lib/x86_64-linux-gnu/libaec.so.0 (0x00007d9e6dc7f000)
	libpoppler.so.134 => /lib/x86_64-linux-gnu/libpoppler.so.134 (0x00007d9e6c000000)
	libgif.so.7 => /lib/x86_64-linux-gnu/libgif.so.7 (0x00007d9e6d468000)
	libnetcdf.so.19 => /lib/x86_64-linux-gnu/libnetcdf.so.19 (0x00007d9e6be15000)
	libcfitsio.so.10 => /lib/x86_64-linux-gnu/libcfitsio.so.10 (0x00007d9e6ba00000)
	libhdf5_serial.so.103 => /lib/x86_64-linux-gnu/libhdf5_serial.so.103 (0x00007d9e6b600000)
	libwebp.so.7 => /lib/x86_64-linux-gnu/libwebp.so.7 (0x00007d9e6c37d000)
	libsqlite3.so.0 => /lib/x86_64-linux-gnu/libsqlite3.so.0 (0x00007d9e6b498000)
	libpq.so.5 => /lib/x86_64-linux-gnu/libpq.so.5 (0x00007d9e6bdbd000)
	libopenjp2.so.7 => /lib/x86_64-linux-gnu/libopenjp2.so.7 (0x00007d9e6bd5c000)
	libkmlbase.so.1 => /lib/x86_64-linux-gnu/libkmlbase.so.1 (0x00007d9e6c95b000)
	libkmldom.so.1 => /lib/x86_64-linux-gnu/libkmldom.so.1 (0x00007d9e6b406000)
	libkmlengine.so.1 => /lib/x86_64-linux-gnu/libkmlengine.so.1 (0x00007d9e6bd2e000)
	libfyba.so.0 => /lib/x86_64-linux-gnu/libfyba.so.0 (0x00007d9e6b9aa000)
	libpcre2-8.so.0 => /lib/x86_64-linux-gnu/libpcre2-8.so.0 (0x00007d9e6b36c000)
	libspatialite.so.8 => /lib/x86_64-linux-gnu/libspatialite.so.8 (0x00007d9e6ac00000)
	libmysqlclient.so.21 => /lib/x86_64-linux-gnu/libmysqlclient.so.21 (0x00007d9e6a400000)
	libfreexl.so.1 => /lib/x86_64-linux-gnu/libfreexl.so.1 (0x00007d9e6d11c000)
	libogdi.so.4.1 => /lib/x86_64-linux-gnu/libogdi.so.4.1 (0x00007d9e6bd13000)
	libexpat.so.1 => /lib/x86_64-linux-gnu/libexpat.so.1 (0x00007d9e6b97e000)
	libproj.so.25 => /lib/x86_64-linux-gnu/libproj.so.25 (0x00007d9e6a000000)
	libjson-c.so.5 => /lib/x86_64-linux-gnu/libjson-c.so.5 (0x00007d9e6abec000)
	libdfalt.so.0 => /lib/x86_64-linux-gnu/libdfalt.so.0 (0x00007d9e6ab48000)
	libmfhdfalt.so.0 => /lib/x86_64-linux-gnu/libmfhdfalt.so.0 (0x00007d9e6ab1f000)
	libunistring.so.5 => /lib/x86_64-linux-gnu/libunistring.so.5 (0x00007d9e69e53000)
	libgnutls.so.30 => /lib/x86_64-linux-gnu/libgnutls.so.30 (0x00007d9e69c59000)
	libhogweed.so.6 => /lib/x86_64-linux-gnu/libhogweed.so.6 (0x00007d9e6aad7000)
	libnettle.so.8 => /lib/x86_64-linux-gnu/libnettle.so.8 (0x00007d9e6aa82000)
	libgmp.so.10 => /lib/x86_64-linux-gnu/libgmp.so.10 (0x00007d9e69bd5000)
	libkrb5.so.3 => /lib/x86_64-linux-gnu/libkrb5.so.3 (0x00007d9e69b0c000)
	libk5crypto.so.3 => /lib/x86_64-linux-gnu/libk5crypto.so.3 (0x00007d9e6a3d4000)
	libcom_err.so.2 => /lib/x86_64-linux-gnu/libcom_err.so.2 (0x00007d9e6d114000)
	libkrb5support.so.0 => /lib/x86_64-linux-gnu/libkrb5support.so.0 (0x00007d9e6a3c7000)
	libsasl2.so.2 => /lib/x86_64-linux-gnu/libsasl2.so.2 (0x00007d9e69af2000)
	libbrotlicommon.so.1 => /lib/x86_64-linux-gnu/libbrotlicommon.so.1 (0x00007d9e69acf000)
	libltdl.so.7 => /lib/x86_64-linux-gnu/libltdl.so.7 (0x00007d9e6bd08000)
	libicuuc.so.74 => /lib/x86_64-linux-gnu/libicuuc.so.74 (0x00007d9e69800000)
	libsnappy.so.1 => /lib/x86_64-linux-gnu/libsnappy.so.1 (0x00007d9e69ac4000)
	libblas.so.3 => /lib/x86_64-linux-gnu/libblas.so.3 (0x00007d9e69a1d000)
	liblapack.so.3 => /lib/x86_64-linux-gnu/liblapack.so.3 (0x00007d9e69000000)
	libarpack.so.2 => /lib/x86_64-linux-gnu/libarpack.so.2 (0x00007d9e697b6000)
	libsuperlu.so.6 => /lib/x86_64-linux-gnu/libsuperlu.so.6 (0x00007d9e69746000)
	libcurl-gnutls.so.4 => /lib/x86_64-linux-gnu/libcurl-gnutls.so.4 (0x00007d9e68f45000)
	libLerc.so.4 => /lib/x86_64-linux-gnu/libLerc.so.4 (0x00007d9e68ebe000)
	libjbig.so.0 => /lib/x86_64-linux-gnu/libjbig.so.0 (0x00007d9e69a0d000)
	libsharpyuv.so.0 => /lib/x86_64-linux-gnu/libsharpyuv.so.0 (0x00007d9e6c375000)
	libfreetype.so.6 => /lib/x86_64-linux-gnu/libfreetype.so.6 (0x00007d9e68df2000)
	libfontconfig.so.1 => /lib/x86_64-linux-gnu/libfontconfig.so.1 (0x00007d9e696f5000)
	liblcms2.so.2 => /lib/x86_64-linux-gnu/liblcms2.so.2 (0x00007d9e68d90000)
	libnss3.so => /lib/x86_64-linux-gnu/libnss3.so (0x00007d9e68c61000)
	libsmime3.so => /lib/x86_64-linux-gnu/libsmime3.so (0x00007d9e68c38000)
	libplc4.so => /lib/x86_64-linux-gnu/libplc4.so (0x00007d9e6b977000)
	libnspr4.so => /lib/x86_64-linux-gnu/libnspr4.so (0x00007d9e68bf9000)
	libhdf5_serial_hl.so.100 => /lib/x86_64-linux-gnu/libhdf5_serial_hl.so.100 (0x00007d9e68bd4000)
	libbz2.so.1.0 => /lib/x86_64-linux-gnu/libbz2.so.1.0 (0x00007d9e68bc0000)
	libsz.so.2 => /lib/x86_64-linux-gnu/libsz.so.2 (0x00007d9e6a3c2000)
	libminizip.so.1 => /lib/x86_64-linux-gnu/libminizip.so.1 (0x00007d9e68bb3000)
	liburiparser.so.1 => /lib/x86_64-linux-gnu/liburiparser.so.1 (0x00007d9e68b9c000)
	libfyut.so.0 => /lib/x86_64-linux-gnu/libfyut.so.0 (0x00007d9e68b91000)
	libfygm.so.0 => /lib/x86_64-linux-gnu/libfygm.so.0 (0x00007d9e68b88000)
	librttopo.so.1 => /lib/x86_64-linux-gnu/librttopo.so.1 (0x00007d9e68b18000)
	libresolv.so.2 => /lib/x86_64-linux-gnu/libresolv.so.2 (0x00007d9e68b05000)
	libtirpc.so.3 => /lib/x86_64-linux-gnu/libtirpc.so.3 (0x00007d9e68ad8000)
	libp11-kit.so.0 => /lib/x86_64-linux-gnu/libp11-kit.so.0 (0x00007d9e68934000)
	libtasn1.so.6 => /lib/x86_64-linux-gnu/libtasn1.so.6 (0x00007d9e6891e000)
	libkeyutils.so.1 => /lib/x86_64-linux-gnu/libkeyutils.so.1 (0x00007d9e68917000)
	libicudata.so.74 => /lib/x86_64-linux-gnu/libicudata.so.74 (0x00007d9e66a00000)
	libgfortran.so.5 => /lib/x86_64-linux-gnu/libgfortran.so.5 (0x00007d9e66600000)
	libnssutil3.so => /lib/x86_64-linux-gnu/libnssutil3.so (0x00007d9e688e5000)
	libplds4.so => /lib/x86_64-linux-gnu/libplds4.so (0x00007d9e688e0000)
	libffi.so.8 => /lib/x86_64-linux-gnu/libffi.so.8 (0x00007d9e688d4000)
```    

从你的 `ldd` 输出和 GDB 调试信息来看，`osgearth_viewer` **名义上是静态链接的（依赖 `.a` 库），但实际上仍动态链接了部分系统库**。以下是详细分析和解决方案：

---

### **1. 现象解释**
#### **(1) 静态与动态库混合使用**
- **静态库（`.a`）**：  
  OSG 和 osgEarth 的核心库（如 `libosg.a`、`libosgEarth.a`）可能是静态链接的。
- **动态库（`.so`）**：  
  系统级依赖（如 `libOpenGL.so`、`libcurl.so`、`libgdal.so`）和运行时组件（如 `libstdc++.so`、`libc.so`）仍为动态链接。

#### **(2) 为何 GDB 加载动态库**
- **动态链接的系统依赖**：  
  即使主程序静态链接了部分库，但以下内容通常仍需动态链接：
  - C/C++ 标准库（`libc.so`、`libstdc++.so`）。
  - 显卡驱动相关库（`libOpenGL.so`、`libGLX.so`）。
  - 系统工具库（如 `libpthread.so`、`libm.so`）。
- **插件机制**：  
  OSG 的插件系统（如 `osgdb_osg.so`）默认以动态库形式加载，即使主程序是静态编译的。

---

### **2. 根本原因**
#### **(1) 不完全的静态链接**
- **CMake 配置问题**：  
  构建时可能未完全禁用共享库（如 `BUILD_SHARED_LIBS=ON` 或部分依赖未强制静态链接）。
- **依赖库的传递性**：  
  即使 OSG 是静态库，它可能依赖的动态库（如 GDAL、CURL）会被动态链接。

#### **(2) 系统限制**
- **部分库无法静态链接**：  
  某些系统库（如 `libGL.so`、`libnss3.so`）可能没有静态版本，或静态链接会导致兼容性问题。

---

### **3. 解决方案**
#### **(1) 强制完全静态链接**
修改 CMake 构建配置，确保所有依赖静态链接：
```bash
cmake \
  -DBUILD_SHARED_LIBS=OFF \
  -DOSG_BUILD_TYPE=Static \
  -DCMAKE_EXE_LINKER_FLAGS="-static" \  # 强制静态链接所有库
  -DCURL_LIBRARY=/path/to/libcurl.a \   # 显式指定静态库路径
  -DGDAL_LIBRARY=/path/to/libgdal.a \
  ..
```
**注意**：  
- `-static` 可能导致链接失败（如缺少静态版的 `libGL.a`）。  
- 需手动安装所有依赖的静态库（如 `sudo apt install libcurl4-openssl-dev libgdal-dev`）。

#### **(2) 检查构建日志**
确认以下关键点：
1. **所有依赖库是否为 `.a`**：  
  在 CMake 生成的 `CMakeCache.txt` 中搜索 `_LIBRARY`，确保路径指向 `.a` 文件。
2. **插件是否被静态编译**：  
  检查 `osgPlugins` 目录是否生成 `.a` 文件而非 `.so`。

#### **(3) 运行时处理动态库**
如果无法完全静态链接，需确保动态库路径正确：
```bash
export LD_LIBRARY_PATH=/path/to/osg_libs:$LD_LIBRARY_PATH
./osgearth_viewer
```

---

### **4. 验证静态链接**
#### **(1) 检查二进制文件类型**
```bash
file ./build/ubuntu-dbg-static/bin/osgearth_viewer
```
- 如果输出包含 **`statically linked`**，则为完全静态。  
- 如果显示 **`dynamically linked`**，则仍有动态依赖。

#### **(2) 查看符号表**
```bash
nm ./osgearth_viewer | grep " U "  # 查看未定义的符号（动态依赖）
```
- 如果输出大量未定义符号（如 `glBegin`、`curl_easy_init`），说明依赖动态库。

---

### **5. 常见问题处理**
| 问题                                | 解决方案                                                                 |
|-------------------------------------|--------------------------------------------------------------------------|
| **链接失败：缺少静态库**            | 安装 `-dev` 包并确保生成 `.a` 文件（如 `libgdal-dev`）。                 |
| **运行时崩溃：GL 符号未定义**       | 静态链接时需替换 GL 调用（如使用 https://docs.opengl.org/。    |
| **插件加载失败**                    | 将插件代码直接编译到主程序（CMake 中 `add_library(plugin STATIC)`）。   |

---

### **6. 动态库列表分析**
从你的 `ldd` 输出中，以下库通常 **无法静态链接**：
| 库名                  | 原因                                                                 |
|-----------------------|----------------------------------------------------------------------|
| `libOpenGL.so`       | 显卡驱动接口，无静态版本。                                           |
| `libc.so`/`libm.so`  | GNU C 库通常不静态链接（可能导致线程安全问题）。                     |
| `libnss3.so`         | 网络安全服务库，依赖复杂。                                           |

---

### **总结**
- **混合链接是正常现象**：大多数“静态编译”程序仍会动态链接系统核心库。  
- **完全静态需特殊处理**：需手动指定所有依赖的静态库，并解决兼容性问题。  
- **推荐方案**：  
  - 接受部分动态链接，通过 `LD_LIBRARY_PATH` 管理依赖。  
  - 使用容器（如 Docker）封装所有依赖，避免环境差异。  

如果需要完全静态二进制，建议参考 **https://github.com/openscenegraph/OpenSceneGraph/tree/master#static-builds**。


===================================
# 3.osgdb插件注册模式 改成 静态库

在 **OpenSceneGraph (OSG)** 中，将插件（`osgdb_*.so`）的注册模式从动态库（`.so` 或 `.dll`）改为静态库（`.a` 或 `.lib`），需要修改 **CMake 配置** 和 **插件注册逻辑**。以下是具体步骤：

![andro-mk-3rd.png]( osgearth-ldj/andro-mk-3rd.png)
![folder-struct.png](osgearth-ldj/folder-struct.png)
![USE_OSGPLUGIN.png](osgearth-ldj/USE_OSGPLUGIN.png)
     
 
> 	-DBUILD_SHARED_LIBS=OFF \
> 	-DDYNAMIC_OPENSCENEGRAPH=OFF \
> 	-DDYNAMIC_OPENTHREADS=OFF 
 
 
| **步骤**               | **关键操作**                                |
|------------------------|--------------------------------------------|
| 1. 修改 CMake 配置     | `set(BUILD_SHARED_LIBS OFF)`               |
| 2. 替换动态注册宏      | 改为显式静态注册函数                       |
| 3. 主程序手动注册       | 调用 `USE_OSGPLUGIN(png)`               |
| 4. 解决冲突与优化      | 统一依赖、控制初始化顺序、裁剪未使用代码   |

 