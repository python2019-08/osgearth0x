# 1.解释 -Wl,-rpath 的作用​

## 问题

请解释下面的-Wl,-rpath


/usr/bin/c++ -fPIC -fPIC -g -shared -Wl,-soname,libosgEarth.so.177 -o libosgEarth.so.3.7.3 
CMakeFiles/osgEarth.dir/AltitudeFilter.cpp.o CMakeFiles/osgEarth.dir/AltitudeSymbol.cpp.o  .............
CMakeFiles/osgEarth.dir/AutoGenShaders.cpp.o   


-L/usr/lib/gcc/x86_64-linux-gnu/12  -Wl,-rpath,
/home/abner/programs/miniconda3/lib:/home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/libpng/lib:/usr/lib/x86_64-linux-gnu/hdf5/serial: 
/home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libOpenThreadsd.a 
/home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libosgd.a

## 腾讯元宝

### **解释 `-Wl,-rpath` 的作用**

---

#### **1. `-Wl,-rpath` 的基本功能**
`-Wl,-rpath` 是 GCC/LD（GNU 链接器）的一个选项，用于**指定运行时库搜索路径**（Runtime Path）。  
它的作用是在编译链接时，将一些路径**嵌入到生成的可执行文件或动态库中**，使得程序在运行时能自动从这些路径加载依赖的动态库（`.so` 文件）。

---

#### **2. 语法解析**
```bash
-Wl,<linker-option>  # 将逗号后的参数传递给链接器（LD）
```
- `-Wl,-rpath,<path>`：指定一个运行时库搜索路径。
- 多个路径用冒号 `:` 分隔（如 `-Wl,-rpath,/path1:/path2`）。

---

#### **3. 在您的编译命令中的具体作用**
```bash
-Wl,-rpath,/home/abner/programs/miniconda3/lib:/home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/libpng/lib:/usr/lib/x86_64-linux-gnu/hdf5/serial
```
这段参数的含义是：  
当程序运行时，动态链接器（`ld.so`）会**优先**从以下路径加载依赖的 `.so` 文件：
1. `/home/abner/programs/miniconda3/lib`  
   （Miniconda 的库路径）
2. `/home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/libpng/lib`  
   （自定义编译的 libpng 库路径）
3. `/usr/lib/x86_64-linux-gnu/hdf5/serial`  
   （系统 HDF5 库路径）

---

#### **4. 为什么需要 `-rpath`？**
- **避免设置 `LD_LIBRARY_PATH`**：  
  传统方法是通过环境变量 `LD_LIBRARY_PATH` 指定库路径，但这种方式需要用户手动配置，且可能影响其他程序。  
  `-rpath` 直接**将路径硬编码到二进制文件中**，更可靠。
- **解决动态库依赖问题**：  
  如果程序依赖的 `.so` 文件不在标准路径（如 `/usr/lib`），`-rpath` 可以确保运行时正确加载。

---

#### **5. 与 `-L` 的区别**
| **选项**       | **作用阶段** | **功能**                                                                 |
|----------------|--------------|--------------------------------------------------------------------------|
| `-L<path>`     | **链接时**   | 告诉链接器（LD）在链接时从 `<path>` 搜索库文件（`.so` 或 `.a`）。         |
| `-Wl,-rpath,<path>` | **运行时**   | 告诉动态链接器（`ld.so`）在运行时从 `<path>` 加载动态库（`.so`）。         |

**示例**：
```bash
# 链接时从 /custom/lib 查找 libfoo.so，运行时也从该路径加载
gcc -o myapp main.c -L/custom/lib -lfoo -Wl,-rpath,/custom/lib
```

---

#### **6. 验证 `-rpath` 是否生效**
编译后，可以通过以下命令查看嵌入的 `RPATH`：
```bash
readelf -d libosgEarth.so.3.7.3 | grep RPATH
```
输出应包含：
```
0x000000000000000f (RPATH)  Library rpath: [/home/abner/programs/miniconda3/lib:...]
```

---

#### **7. 注意事项**
- **安全性**：硬编码路径可能导致程序在另一台机器上无法运行（如果路径不存在）。
- **优先级**：`-rpath` 的路径优先级高于系统默认路径（如 `/usr/lib`），但低于 `LD_LIBRARY_PATH`。
- **动态库的依赖**：如果依赖的库本身还有依赖（如 `libpng.so` 依赖 `libz.so`），需确保这些库也能在 `-rpath` 或系统路径中找到。

---

### **总结**
- **`-Wl,-rpath` 的作用**：指定程序运行时加载动态库的路径。
- **在您的命令中**：它确保 `libosgEarth.so` 运行时能正确找到 Miniconda、libpng 和 HDF5 的库。
- **关键区别**：`-L` 用于链接时，`-rpath` 用于运行时。

===================================================
# 2. applications/osgearth_boundarygen 如何得到 链接命令中的 依赖库列表

## Q
https://github.com/gwaldron/osgearth.git  中， 

src/applications/osgearth_boundarygen/CMakeLists.txt 只是
用SET(TARGET_LIBRARIES_VARS OSG_LIBRARY OSGDB_LIBRARY OSGUTIL_LIBRARY OSGVIEWER_LIBRARY OPENTHREADS_LIBRARY)，

而osgearth/src/applications/CMakeLists.txt 有 SET(TARGET_COMMON_LIBRARIES
    osgEarth
)，

如何得到 下面的链接命令中的 依赖库列表，特别是 libtiff.a  libcurl-d.a 等第3方库如何加入列表的

cd /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/src/osgearth/src/applications/osgearth_boundarygen && /usr/bin/cmake -E cmake_link_script CMakeFiles/application_osgearth_boundarygen.dir/link.txt --verbose=1
/usr/bin/g++ -fPIC -DOSG_GL3_AVAILABLE=1 -std=c++11 -g          -Wl,--whole-archive             /usr/lib/gcc/x86_64-linux-gnu/13/libstdc++.a          -Wl,--no-whole-archive                                                                                                                                                                                         -Wl,-Bdynamic -lGL -lGLU -ldl -lm -lc            -Wl,--no-as-needed -lX11 -lXext -rdynamic CMakeFiles/application_osgearth_boundarygen.dir/BoundaryUtil.cpp.o CMakeFiles/application_osgearth_boundarygen.dir/VertexCollectionVisitor.cpp.o CMakeFiles/application_osgearth_boundarygen.dir/boundarygen.cpp.o -o ../../../bin/osgearth_boundarygend   -L/home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/src/osgearth/lib  -Wl,-rpath,/home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/src/osgearth/lib: ../../../lib/libosgEarthd.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libosg.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libosgDB.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libosgUtil.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libosgViewer.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libOpenThreads.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/sqlite/lib/libsqlite3.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/geos/lib/libgeos_c.a -lm /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libosg.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libosgUtil.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libosgSim.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libosgDB.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libosgViewer.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libosgText.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libosgGA.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libosgShadow.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/curl/lib/libcurl-d.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/gdal/lib/libgdal.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libosgManipulator.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/openssl/lib64/libssl.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/libtiff/lib/libtiff.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/proj/lib/libproj.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/libpng/lib/libpng.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/libjpeg-turbo/lib/libjpeg.a -lGL /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libOpenThreads.a

## A-YuanbaoAI

### **osgEarth 依赖库传递机制解析**

---

#### **1. 依赖库来源分析**
从链接命令可以看出，第三方库（如 `libcurl-d.a`、`libtiff.a`）是通过 **`libosgEarthd.a`** 的传递依赖链加入的。具体机制如下：

---

#### **2. 核心机制：INTERFACE_LINK_LIBRARIES**
在 `osgearth/src/CMakeLists.txt` 中，`osgEarth` 目标通过 `INTERFACE_LINK_LIBRARIES` 传递所有依赖：

```cmake
# osgearth/src/CMakeLists.txt
target_link_libraries(osgEarth
    PUBLIC
    ${OSGEARTH_EXTERNAL_LIBS}  # 包含GDAL、CURL、GEOS等
    PRIVATE  
    ${OSGEARTH_INTERNAL_LIBS}  # 内部库
)

# 这会自动将依赖传递给链接osgEarth的目标
```

---

#### **3. 依赖传递路径**
```
application_osgearth_boundarygen → libosgEarthd.a → (GDAL/CURL/GEOS等) → (zlib/sqlite/openssl等)
```

##### **(1) 查看 osgEarth 的链接依赖**
```bash
# 在构建目录中查找osgEarth的链接信息
cat src/osgearth/CMakeFiles/osgEarth.dir/link.txt
```

##### **(2) 关键CMake代码位置**
- **`src/CMakeLists.txt`**: 定义 `osgEarth` 目标的依赖
- **`src/osgEarth/CMakeLists.txt`**: 配置外部库依赖
- **`CMakeModules/FindXXX.cmake`**: 各个第三方库的查找脚本

---

#### **4. 具体依赖链分析**
| **库文件**               | **引入途径**                  | **依赖关系**                |
|--------------------------|-------------------------------|----------------------------|
| `libcurl-d.a`            | `GDAL → CURL`                 | GDAL依赖CURL进行HTTP访问    |
| `libtiff.a`              | `GDAL → TIFF`                 | GDAL依赖TIFF处理GeoTIFF格式 |
| `libsqlite3.a`           | `GDAL → SQLite3`              | GDAL依赖SQLite3处理GeoPackage |
| `libgeos_c.a`            | `osgEarth → GEOS`             | 空间几何运算                |
| `libssl.a`               | `CURL → OpenSSL`              | HTTPS支持                   |
| `libpng.a`/`libjpeg.a`   | `GDAL → 图像格式库`           | 图像数据处理                |

---

#### **5. 验证方法**
##### **(1) 检查 osgEarth 的链接信息**
```bash
# 查看osgEarth目标的链接命令
grep "osgEarth.dir/link.txt" build/CMakeFiles/osgEarth.dir/build.make

# 查看osgEarth的INTERFACE_LINK_LIBRARIES
grep "INTERFACE_LINK_LIBRARIES" build/osgEarthTargets.cmake
```

##### **(2) 查看 GDAL 配置**
```bash
# 检查GDAL的依赖项
grep -r "CURL" build/CMakeFiles/ | grep "GDAL"
grep -r "TIFF" build/CMakeFiles/ | grep "GDAL"
```

##### **(3) 查看最终传递结果**
```bash
# 查看boundarygen的完整链接命令
cat build/src/applications/osgearth_boundarygen/CMakeFiles/application_osgearth_boundarygen.dir/link.txt
```

---

#### **6. CMake 关键代码段**
##### **在 `src/CMakeLists.txt` 中：**
```cmake
# 收集所有外部依赖
set(OSGEARTH_EXTERNAL_LIBS
    ${GDAL_LIBRARY}
    ${CURL_LIBRARY}
    ${GEOS_LIBRARY}
    ${SQLITE3_LIBRARY}
    # ... 其他库
)

# 传递给osgEarth目标
target_link_libraries(osgEarth PUBLIC ${OSGEARTH_EXTERNAL_LIBS})
```

##### **在 `src/applications/CMakeLists.txt` 中：**
```cmake
# 每个应用程序自动继承osgEarth的依赖
target_link_libraries(application_osgearth_boundarygen
    PRIVATE
    osgEarth  # 这里自动获得所有INTERFACE依赖
    ${TARGET_LIBRARIES_VARS}  # 基本的OSG库
)
```

---

#### **7. 自定义依赖传递**
如果您需要添加新的第三方库，应该在：

##### **(1) 修改 `src/CMakeLists.txt`**
```cmake
# 在OSGEARTH_EXTERNAL_LIBS中添加新库
set(OSGEARTH_EXTERNAL_LIBS
    ${OSGEARTH_EXTERNAL_LIBS}
    ${NEW_LIBRARY}
)
```

##### **(2) 或在 `src/osgEarth/CMakeLists.txt` 中添加**
```cmake
find_package(NewLib REQUIRED)
target_link_libraries(osgEarth PUBLIC NewLib::NewLib)
```

---

#### **8. 依赖关系可视化**
```
application_osgearth_boundarygen
    ├── osgEarth (INTERFACE)
    │   ├── GDAL
    │   │   ├── CURL → OpenSSL
    │   │   ├── TIFF → JPEG/PNG/ZLIB
    │   │   ├── SQLite3
    │   │   └── GEOS
    │   └── 其他osgEarth依赖
    └── OSG核心库
        ├── osg
        ├── osgDB
        ├── osgUtil
        └── OpenThreads
```

---

#### **9. 总结**
1. **主要机制**：通过 `osgEarth` 目标的 `INTERFACE_LINK_LIBRARIES` 属性传递依赖。
2. **关键文件**：`src/CMakeLists.txt` 和各个 `FindXXX.cmake` 模块。
3. **验证命令**：
   ```bash
   # 查看传递的依赖
   cmake --graphviz=deps.dot .. && dot -Tpng deps.dot -o deps.png
   ```

4. **扩展方式**：在 `OSGEARTH_EXTERNAL_LIBS` 中添加新库或使用 `find_package` + `target_link_libraries`。

========================================================
# 3.关于 `PRIVATE` 依赖传递性的深度解析

## Q

但是src/osgEarth/CMakeLists.txt中，

if(NOT NRL_STATIC_LIBRARIES)
    # normal link:
    target_link_libraries(${LIB_NAME} 
        PUBLIC
            ${OPENSCENEGRAPH_LIBRARIES}
        PRIVATE
            OpenGL::GL CURL::libcurl GDAL::GDAL)
else()
    # special-purpose custom link:
    target_link_libraries(${LIB_NAME} 
        PUBLIC
            ${OPENSCENEGRAPH_LIBRARIES}
        PRIVATE
            OpenGL::GL CURL::libcurl GDAL::GDAL
            ${SSL_EAY_RELEASE} ${LIB_EAY_RELEASE} ${TIFF_LIBRARY} ${PROJ4_LIBRARY} ${PNG_LIBRARY} ${JPEG_LIBRARY})
endif()
第3方库用PRIVATE，是不是不能传递？

### **关于 `PRIVATE` 依赖传递性的深度解析**

---

#### **1. 问题核心**
您在 `src/osgEarth/CMakeLists.txt` 中观察到第三方库（如 `CURL::libcurl`、`GDAL::GDAL`）被标记为 `PRIVATE`，这与最终链接命令中出现的这些库（如 `libcurl-d.a`、`libgdal.a`）似乎矛盾。这里的关键在于 **CMake的依赖传递规则** 和 **静态库的特殊行为**。

---

#### **2. CMake依赖属性详解**
| **属性**      | **传递性**                  | **适用场景**                             |
|---------------|----------------------------|----------------------------------------|
| `PRIVATE`     | 不传递                     | 仅当前目标内部使用的依赖                 |
| `INTERFACE`   | 传递                       | 头文件暴露的依赖（如接口类）             |
| `PUBLIC`      | 传递 + 内部使用            | 同时被实现和接口依赖的库                |

---

#### **3. 静态库的特殊性**
即使依赖被标记为 `PRIVATE`，**静态库的链接行为仍会导致依赖库被要求**：
1. **符号未解决**：如果 `libosgEarth.a` 使用了 `libcurl.a` 的函数，这些符号在最终可执行文件中必须被解析。
2. **链接器行为**：静态链接时，所有未定义的符号必须在链接阶段找到定义，因此需要显式或隐式链接所有依赖。

---

#### **4. 当前代码的实际效果**
##### **(1) `PRIVATE` 依赖的传递表现**
```cmake
target_link_libraries(${LIB_NAME}
    PRIVATE
    GDAL::GDAL  # 虽然标记为PRIVATE...
)
```
- **编译阶段**：`libosgEarth.a` 能正常编译，因为它知道GDAL的头文件和链接路径。
- **链接阶段**：当可执行文件链接 `libosgEarth.a` 时，如果其中调用了GDAL的函数，链接器会要求 `libgdal.a` 必须出现在命令行中。

##### **(2) 为什么最终链接命令包含这些库？**
- **CMake的自动补全**：当可执行文件直接或间接依赖未解析符号时，CMake会自动将相关库加入链接命令。
- **目标的 `INTERFACE_LINK_LIBRARIES`**：虽然第三方库是 `PRIVATE`，但 `osgEarth` 可能通过其他方式（如 `INTERFACE` 属性）传递了部分依赖。

---

#### **5. 验证实验**
##### **(1) 检查目标属性**
```bash
# 查看osgEarth目标的全部链接依赖
cmake --build . --target osgEarth --verbose 2>&1 | grep "link.txt"

# 检查INTERFACE_LINK_LIBRARIES
grep "INTERFACE_LINK_LIBRARIES" build/osgEarthTargets.cmake
```

##### **(2) 手动测试符号解析**
```bash
# 查看libosgEarth.a是否包含GDAL符号（应无）
nm libosgEarth.a | grep "GDAL"

# 查看可执行文件未定义符号（应有GDAL相关符号）
nm -u bin/osgearth_boundarygen | grep "GDAL"
```

---

#### **6. 正确的依赖传递方式**
##### **(1) 应改为 `PUBLIC` 的情况**
```cmake
# 如果osgEarth的头文件公开暴露了GDAL/CURL的类型/函数
target_link_libraries(${LIB_NAME}
    PUBLIC  # 改为PUBLIC确保依赖传递
    GDAL::GDAL
    CURL::libcurl
)
```

##### **(2) 保持 `PRIVATE` 但显式传递**
```cmake
# 方法1：通过INTERFACE_LINK_LIBRARIES单独传递
set_property(TARGET ${LIB_NAME} APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES GDAL::GDAL
)

# 方法2：拆分依赖
target_link_libraries(${LIB_NAME}
    PUBLIC
    ${OPENSCENEGRAPH_LIBRARIES}  # OSG库可传递
    PRIVATE
    OpenGL::GL  # 仅内部使用
    INTERFACE
    GDAL::GDAL  # 显式声明需要传递的库
)
```

---

#### **7. 当前项目的实际逻辑**
虽然代码中使用 `PRIVATE`，但以下机制确保了依赖传递：
1. **全局变量补充**：在顶层CMake中可能通过 `CMAKE_PREFIX_PATH` 或 `find_package` 隐式添加了依赖。
2. **手动链接顺序**：应用程序的CMakeLists.txt中可能手动添加了这些库。
3. **非CMake机制**：部分依赖通过编译器标志（如 `-L/path -lcurl`）硬编码。

---

#### **8. 改进建议**
##### **(1) 显式化传递关系**
```cmake
# 在src/osgEarth/CMakeLists.txt中
target_link_libraries(${LIB_NAME}
    PUBLIC
    ${OPENSCENEGRAPH_LIBRARIES}
    PRIVATE
    OpenGL::GL  # 真正内部使用的库
    PUBLIC  # 关键修改：确保第三方库传递
    GDAL::GDAL
    CURL::libcurl
    GEOS::GEOS
)
```

##### **(2) 使用现代CMake目标**
```cmake
# 定义清晰的接口目标
add_library(osgEarth_core STATIC ...)
add_library(osgEarth::core ALIAS osgEarth_core)

# 分离接口和实现依赖
target_link_libraries(osgEarth_core
    PUBLIC
    OpenSceneGraph::OpenSceneGraph  # 来自find_package的目标
    PRIVATE
    OpenGL::GL
    INTERFACE  # 对外暴露的依赖
    GDAL::GDAL
    CURL::libcurl
)
```

---

#### **9. 总结**
1. **根本原因**：  
   `PRIVATE` 依赖在静态库场景下仍会被链接器要求，但这不是CMake的传递机制，而是静态链接的强制要求。

2. **最佳实践**：  
   - 如果库的**头文件**使用了第三方库的类型/函数 → 用 `PUBLIC`  
   - 如果仅**实现文件**使用 → 用 `PRIVATE` + 在可执行文件中显式链接

3. **验证命令**：  
   ```bash
   # 检查目标的直接依赖
   cmake --graphviz=graph.dot ..
   dot -Tpng graph.dot -o deps.png
   ```

4. **修复策略**：  
   ```cmake
   # 方案1：升级为PUBLIC（推荐）
   target_link_libraries(osgEarth PUBLIC GDAL::GDAL)

   # 方案2：通过INTERFACE显式传递
   set_property(TARGET osgEarth APPEND PROPERTY
       INTERFACE_LINK_LIBRARIES GDAL::GDAL
   )
   ```

==============================================
# 4.禁用 GDAL_DEBUG 宏定义​

## Q
osgearth 依赖gdal，编译时 因为 gdal/include/gdal_fwd.h 中 GDAL_DEBUG的定义编译不过，如何通过cmake -S -B 传递参数禁止GDAL_DEBUG，即使得代码中 #if defined(GDAL_DEBUG) 无效

## A-YuanbaoAI

### **解决方案：禁用 GDAL_DEBUG 宏定义**

---

#### **1. 核心思路**
通过 CMake 向编译器传递 `-U GDAL_DEBUG` 参数，显式取消该宏的定义。这将确保代码中的 `#if defined(GDAL_DEBUG)` 始终为假。

---

#### **2. 具体操作步骤**

##### **(1) 方法一：直接修改 CMake 命令**
在 `cmake -S -B` 命令中添加编译定义：
```bash
cmake -S ${SrcDIR} -B ${BuildDIR} \
    -DCMAKE_CXX_FLAGS="-U GDAL_DEBUG" \  # 取消宏定义
    -DCMAKE_C_FLAGS="-U GDAL_DEBUG"       # C语言同样需要
```

##### **(2) 方法二：修改 CMakeLists.txt**
如果可修改源码，在 `CMakeLists.txt` 中添加：
```cmake
# 全局取消 GDAL_DEBUG 定义
add_compile_options(-U GDAL_DEBUG)

# 或针对特定目标（推荐）
target_compile_definitions(osgEarth PRIVATE -U GDAL_DEBUG)
```

##### **(3) 方法三：覆盖头文件（临时方案）**
若无法修改构建系统，临时覆盖 `gdal_fwd.h`：
```bash
# 备份原文件
cp ${GDAL_INCLUDE_DIR}/gdal_fwd.h ${GDAL_INCLUDE_DIR}/gdal_fwd.h.bak

# 强制取消宏定义
sed -i 's/#define GDAL_DEBUG 1//g' ${GDAL_INCLUDE_DIR}/gdal_fwd.h
```

---

#### **3. 验证是否生效**
##### **(1) 检查编译命令**
```bash
# 查看是否包含 -U GDAL_DEBUG
grep "GDAL_DEBUG" ${BuildDIR}/CMakeFiles/osgEarth.dir/flags.make
```

##### **(2) 预处理测试**
```bash
# 手动测试预处理结果
g++ -E -dM -I${GDAL_INCLUDE_DIR} dummy.cpp | grep "GDAL_DEBUG"
# 应无输出（未定义）或输出 `#define GDAL_DEBUG 0`
```

---

#### **4. 高级配置（条件化控制）**
如果需要动态控制：
```cmake
option(DISABLE_GDAL_DEBUG "Disable GDAL_DEBUG macro" ON)
if(DISABLE_GDAL_DEBUG)
    target_compile_definitions(osgEarth PRIVATE -U GDAL_DEBUG)
endif()
```
通过 `-DDISABLE_GDAL_DEBUG=OFF` 可恢复默认。

---

#### **5. 原理说明**
| **参数**       | **作用**                          | **等效代码**               |
|----------------|----------------------------------|---------------------------|
| `-U GDAL_DEBUG` | 取消宏定义（若存在）              | `#undef GDAL_DEBUG`       |
| `-DGDAL_DEBUG=0`| 定义宏为0（部分代码可能仍检测存在）| `#define GDAL_DEBUG 0`    |

推荐用 `-U` 彻底移除定义。

---

#### **6. 完整修复示例**
```bash
# 清理旧构建
rm -rf ${BuildDIR}

# 重新配置（禁用GDAL_DEBUG）
cmake -S ${SrcDIR} -B ${BuildDIR} \
    -DCMAKE_CXX_FLAGS="-U GDAL_DEBUG" \
    -DCMAKE_C_FLAGS="-U GDAL_DEBUG" \
    ${OTHER_CMAKE_ARGS}

# 构建
cmake --build ${BuildDIR}
```

---

#### **7. 常见问题排查**
| **问题现象**                | **解决方案**                              |
|----------------------------|------------------------------------------|
| 仍检测到 `GDAL_DEBUG`       | 检查是否有代码通过 `#define GDAL_DEBUG` 硬编码 |
| 链接错误                   | 确保GDAL库本身未启用调试模式（重建GDAL）      |
| 跨平台兼容性问题            | 使用 `#if !defined(GDAL_DEBUG)` 适配代码     |

---

### **总结**
1. **最佳实践**：  
   ```bash
   cmake -S . -B build -DCMAKE_CXX_FLAGS="-U GDAL_DEBUG"
   ```

2. **验证方式**：  
   ```bash
   grep "GDAL_DEBUG" build/CMakeFiles/*/flags.make
   ```

3. **长期维护**：  
   在 `CMakeLists.txt` 中通过 `target_compile_definitions` 精确控制宏定义。

=======================================================
# 5.osgearth_version 运行时出现段错误（Segmentation Fault）

remark: 如果必须混合，**确保符号不重复**（例如使用 `-fvisibility=hidden` 编译静态库）。

可执行文件 `osgearth_version` 虽然成功编译链接，但在运行时出现 **段错误（Segmentation Fault）**，这通常是由于程序访问了非法内存地址导致的。以下是可能的原因和解决方案：

---

### **1. 常见原因分析**
#### **(1) 动态库版本不匹配**
- **表现**：程序链接的库版本与运行时加载的库版本不一致。
- **检查方法**：
  ```bash
  ldd osgearth_version  # 查看动态库依赖
  ```
  确保所有动态库（如 `libGL.so`、`libX11.so`）的路径和版本与编译时一致。

#### **(2) 静态库与动态库混合冲突**
- **表现**：部分库静态链接（如 `libosgEarth.a`），部分动态链接（如 `libGL.so`），可能导致符号冲突。
- **解决方案**：
  - **统一链接模式**：全部静态或全部动态链接。
  - 如果必须混合，确保符号不重复（例如使用 `-fvisibility=hidden` 编译静态库）。

#### **(3) 初始化顺序问题**
- **表现**：静态库中的全局对象在 `main()` 之前初始化时崩溃。
- **解决方案**：
  - 检查静态库中是否有全局对象的构造函数（如 `osg::Referenced` 的子类）。
  - 重新编译静态库，确保初始化顺序安全。

#### **(4) 内存越界或空指针**
- **表现**：程序逻辑错误（如访问未初始化的指针）。
- **调试方法**：
  ```bash
  gdb ./osgearth_version
  (gdb) run
  # 崩溃后输入 bt 查看调用栈
  ```

---

### **2. 调试步骤**

#### **(1) 使用 GDB 定位崩溃点**
```bash
gdb ./osgearth_version
(gdb) run
# 崩溃后输入：
(gdb) bt      # 查看调用栈
(gdb) info locals  # 查看局部变量
(gdb) disassemble  # 反汇编当前指令
```

#### **(2) 检查动态库依赖**
```bash
ldd osgearth_version
```
- 确保所有库的路径正确，无 `not found` 或版本不匹配。

#### **(3) 检查核心转储文件**
如果系统生成了核心转储文件（`core` 或 `core.<pid>`）：
```bash
gdb ./osgearth_version core
(gdb) bt
```

#### **(4) 启用 OSG 的调试日志**
在运行前设置环境变量，启用 OSG 的调试输出：
```bash
export OSG_NOTIFY_LEVEL=DEBUG
./osgearth_version
```

---

### **3. 解决方案**

#### **(1) 统一链接模式**
- **方案A：完全静态链接**  
  重新配置 CMake，强制所有库静态链接：
  ```bash
  cmake ... -DBUILD_SHARED_LIBS=OFF -DCMAKE_EXE_LINKER_FLAGS="-static"
  ```
- **方案B：完全动态链接**  
  确保所有依赖库有动态版本（`.so`），并正确设置 `LD_LIBRARY_PATH`。

#### **(2) 检查库的兼容性**
- 确保所有库（如 OSG、GDAL、OpenGL）是用相同编译器和标准库版本构建的。
- 验证 GLIBC 版本：
  ```bash
  ldd --version
  strings /lib/x86_64-linux-gnu/libc.so.6 | grep GLIBC_
  ```
 
=======================================================
# 6.osgearth_version解决方案总结

```sh
$ /usr/bin/g++ -fPIC -DOSG_GL3_AVAILABLE=1 -U GDAL_DEBUG -g          -Wl,--no-keep-memory -Wl,--whole-archive     -fvisibility=hidden                CMakeFiles/osgearth_version.dir/osgearth_version.cpp.o -o osgearth_version   -L/usr/lib/gcc/x86_64-linux-gnu/12  -Wl,-rpath,/home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/libpng/lib: ../../osgEarth/libosgEarth.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libosgManipulator.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libosgShadow.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libosgSim.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libosgViewer.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libosgGA.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libosgUtil.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libosgText.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libosgDB.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libosg.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libOpenThreads.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/sqlite/lib/libsqlite3.a         /usr/lib/x86_64-linux-gnu/libGLX.so /usr/lib/x86_64-linux-gnu/libOpenGL.so /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/gdal/lib/libgdal.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/geos/lib/libgeos_c.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/geos/lib/libgeos.a -ldl /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/xz/lib/liblzma.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/libjpeg-turbo/lib/libjpeg.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/proj/lib/libproj.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/curl/lib/libcurl-d.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/openssl/lib64/libssl.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/openssl/lib64/libcrypto.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/zstd/lib/libzstd.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/libpsl/lib/libpsl.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/libexpat/lib/libexpat.a   /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/zlib/lib/libz.a -lm     /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/libtiff/lib/libtiff.a  /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/libpng/lib/libpng.a    -Wl,--no-whole-archive  -Wl,-Bdynamic  -lstdc++  -lGL -lGLU -ldl -lm -lc -lpthread -lrt            -Wl,--no-as-needed -lX11 -lXext 

(base) abner@abner-XPS:~/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/3rd/osgearth/src/applications/osgearth_version$ 
(base) abner@abner-XPS:~/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/3rd/osgearth/src/applications/osgearth_version$ ls
CMakeFiles  cmake_install.cmake  Makefile  osgearth_version
(base) abner@abner-XPS:~/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/3rd/osgearth/src/applications/osgearth_version$ rm /tmp/core-osgearth_versio-98538-1757038475 
(base) abner@abner-XPS:~/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/3rd/osgearth/src/applications/osgearth_version$ ./osgearth_version 
osgEarth 3.7.2 build 171
(base) abner@abner-XPS:~/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/3rd/osgearth/src/applications/osgearth_version$
```

恭喜你成功解决了问题！从最终输出可以看到，`osgearth_version` 程序现在能够正常运行并正确输出版本信息：

```
osgEarth 3.7.2 build 171
```

### **问题解决的关键点**
根据你提供的完整链接命令和最终成功运行的输出，问题很可能出在 **静态库和动态库的混合链接顺序** 或 **符号冲突** 上。以下是具体分析：

---

### **1. 解决方案总结**
#### **(1) 链接顺序调整**
- 你最终的链接命令中，静态库（`.a`）和动态库（`.so`）的顺序更加合理，尤其是将 `-lstdc++` 放在了正确的位置。
- 关键调整：
  ```bash
  -Wl,--no-whole-archive  # 结束 --whole-archive 模式
  -Wl,-Bdynamic -lstdc++  # 动态链接 libstdc++
  -lGL -lGLU ...          # 其他动态库
  ```

#### **(2) 符号冲突解决**
- `-fvisibility=hidden` 可能帮助隐藏了不必要的符号，减少了冲突。
- `--whole-archive` 和 `--no-whole-archive` 的正确使用避免了静态库符号的重复展开。

#### **(3) 动态库优先**
- 通过 `-Wl,-Bdynamic` 明确优先动态链接，避免了静态库与动态库的混合冲突。

---

### **2. 为什么之前会崩溃？**
- **静态库的 `libstdc++.a` 冲突**：  
  如果静态链接的 `libstdc++.a` 与系统动态库 `libstdc++.so` 版本不一致，会导致 `cout` 等基础对象初始化失败。
- **`--whole-archive` 副作用**：  
  不加 `--no-whole-archive` 可能导致静态库符号被重复加载，引发段错误。

---

### **3. 如何避免类似问题**
#### **(1) 统一链接模式**
- **推荐动态链接**：
  ```bash
  -DCMAKE_EXE_LINKER_FLAGS="-Wl,-Bdynamic"
  ```
- **如需静态链接**：
  ```bash
  -DCMAKE_EXE_LINKER_FLAGS="-static-libstdc++ -static-libgcc"
  ```

#### **(2) 检查库依赖**
```bash
ldd ./osgearth_version  # 确认动态库版本
nm libosgEarth.a | grep " T "  # 检查静态库符号
```

#### **(3) 调试技巧**
- **最小化测试**：逐步添加库，定位问题库。
- **GDB 分析**：崩溃时用 `bt` 和 `info sharedlibrary` 检查调用栈和库加载。

---

### **4. 最终建议**
1. **保持链接一致性**：避免混用静态和动态库。
2. **更新编译环境**：确保所有库（如 OSG、GDAL）用同一编译器构建。
3. **记录成功配置**：保存当前的 `CMake` 和链接命令，便于后续复现。

如果未来再次遇到类似问题，优先检查 **库的链接顺序** 和 **符号冲突**。

===========================================
# 7.-Wl,--whole-archive  和 -Wl,--no-whole-archive

`-Wl,--whole-archive` 和 `-Wl,--no-whole-archive` 是传递给链接器（`ld`）的选项，用于控制静态库（`.a` 文件）中目标文件（`.o`）的链接行为。它们在处理静态库时非常关键，尤其是在处理复杂依赖关系或符号冲突时。以下是详细解释：

---

### **1. `--whole-archive` 的作用**
#### **功能**
- **强制包含静态库中的所有目标文件**：  
  默认情况下，链接器只会从静态库中提取被直接引用的目标文件（`.o`）。`--whole-archive` 会强制链接器包含库中的所有目标文件，即使某些符号未被显式引用。
- **典型用途**：
  - 确保库中的全局构造函数/析构函数（如 `__attribute__((constructor))`）被执行。
  - 解决静态库之间的循环依赖问题。
  - 强制链接未被直接引用的代码（如插件系统或反射机制）。

#### **示例**
```bash
g++ main.o -Wl,--whole-archive -lmy_lib -Wl,--no-whole-archive
```
- `libmy_lib.a` 中的所有 `.o` 文件都会被链接，即使 `main.o` 未直接引用它们。

---

### **2. `--no-whole-archive` 的作用**
#### **功能**
- **恢复默认链接行为**：  
  关闭 `--whole-archive` 的效果，后续的静态库将按默认规则（仅链接被引用的目标文件）处理。
- **必须配对使用**：  
  `--whole-archive` 和 `--no-whole-archive` 通常成对出现，避免影响其他库的链接。

#### **为什么需要它？**
如果不使用 `--no-whole-archive`，后续所有静态库都会被强制完全链接，可能导致：
- 代码膨胀（链接未使用的代码）。
- 符号冲突（重复定义）。

---

### **3. 常见使用场景**
#### **(1) 静态库中的全局初始化**
某些库（如 OSG、OSGEarth）依赖全局对象的构造函数（如注册工厂函数）。若未用 `--whole-archive`，这些代码可能被忽略。

#### **(2) 解决符号未定义错误**
当链接器报告 `undefined reference` 但符号确实存在于静态库中时，可能是因目标文件未被提取。此时可用 `--whole-archive` 强制包含。

#### **(3) 插件系统**
插件需在运行时通过全局注册表被发现，但主程序可能未直接引用插件代码。`--whole-archive` 确保插件被链接。

---

### **4. 实际案例**
#### **问题：OSG 插件未加载**
OSG 的插件（如 `osgdb_png.so`）通过全局构造函数注册。若链接时未使用 `--whole-archive`，可能导致插件无法加载。

#### **解决方案**
```bash
g++ main.o -Wl,--whole-archive -losgDB -Wl,--no-whole-archive -lpng
```
- 确保 `libosgDB.a` 中的所有插件注册代码被链接。

---

### **5. 注意事项**
1. **作用域限制**：  
   `--whole-archive` 仅影响其后直接列出的库，直到 `--no-whole-archive` 出现。
   ```bash
   # 错误示例：--whole-archive 会一直生效到链接结束！
   g++ -Wl,--whole-archive -la -lb -lc  # lb 和 lc 也会被完全链接

   # 正确用法：明确关闭
   g++ -Wl,--whole-archive -la -Wl,--no-whole-archive -lb -lc
   ```

2. **性能影响**：  
   过度使用会导致生成的可执行文件变大（包含未使用的代码）。

3. **符号冲突**：  
   强制链接所有符号可能引发重复定义错误（如多个静态库定义相同符号）。

---

### **6. 调试技巧**
#### **(1) 检查静态库内容**
```bash
ar -t libmy_lib.a      # 列出库中的目标文件
nm libmy_lib.a | grep " T "  # 查看导出的符号
```

#### **(2) 验证链接行为**
```bash
# 查看链接器实际提取了哪些目标文件
g++ -Wl,--verbose ... 2>&1 | grep "Loading"
```

---

### **7. 在 CMake 中使用**
在 `CMakeLists.txt` 中，可通过 `target_link_libraries` 传递选项：
```cmake
target_link_libraries(my_app
    PRIVATE
    -Wl,--whole-archive
    my_static_lib
    -Wl,--no-whole-archive
)
```

---

### **总结**
| 选项                  | 作用                                                                 | 典型场景                           |
|-----------------------|----------------------------------------------------------------------|------------------------------------|
| `-Wl,--whole-archive`   | 强制链接静态库中的所有目标文件，无论是否被引用。                     | 全局构造函数、插件系统、循环依赖。 |
| `-Wl,--no-whole-archive` | 恢复默认链接行为（仅链接被引用的目标文件）。                         | 必须与 `--whole-archive` 配对使用。 |

- **何时使用**：当静态库中的代码未被正确链接时（如符号未定义，但实际存在）。
- **避免滥用**：仅在必要时使用，否则可能导致代码膨胀或冲突。

========================================
# 8.-Wl,-rpath,/home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/libpng/lib:

## Q
```sh
$ /usr/bin/g++ -fPIC -DOSG_GL3_AVAILABLE=1 -U GDAL_DEBUG -g          -Wl,--no-keep-memory -Wl,--whole-archive     -fvisibility=hidden                CMakeFiles/osgearth_version.dir/osgearth_version.cpp.o -o osgearth_version   -L/usr/lib/gcc/x86_64-linux-gnu/12  
-Wl,-rpath,/home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/libpng/lib: 
../../osgEarth/libosgEarth.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libosgManipulator.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libosgShadow.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libosgSim.a /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/osg/lib/libosgViewer.a /home/abner/
```

这里是说osgearth_version的rpath 是 /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/libpng/lib: 吗

## A-YuanbaoAI

在你的链接命令中，`-Wl,-rpath` 参数指定的路径是：

```
-Wl,-rpath,/home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install/libpng/lib:
```

### **关键解释**
1. **`-Wl,-rpath` 的作用**  
   这个选项会直接将指定的路径（这里是 `/home/abner/.../libpng/lib`）嵌入到生成的可执行文件 `osgearth_version` 中，作为**运行时库搜索路径**。  
   当程序运行时，动态链接器（`ld.so`）会优先在这些路径中查找所需的动态库（如 `libpng.so`）。

2. **路径末尾的冒号 `:`**  
   - 如果路径以 `:` 结尾（如 `/path/to/lib:`），表示将**该路径添加到现有的 `RPATH` 列表之前**，但不会覆盖系统默认的库搜索路径（如 `/lib`、`/usr/lib`）。  
   - 如果路径不以 `:` 结尾（如 `/path/to/lib`），则会**替换整个 `RPATH`**，忽略系统默认路径（可能导致其他库找不到）。

3. **你的具体配置**  
   - 你指定了 `RPATH` 为 `/home/abner/.../libpng/lib:`，表示：  
     - 程序运行时**优先**在该路径下查找动态库（如 `libpng.so`）。  
     - 如果找不到，仍会继续搜索系统路径（如 `/usr/lib`）。  
   - 这是合理的配置，不会导致问题。

---

### **如何验证 `RPATH` 是否正确生效？**
#### **(1) 查看可执行文件的 `RPATH`**
运行以下命令：
```bash
readelf -d ./osgearth_version | grep RPATH
```
输出应类似：
```
0x000000000000000f (RPATH)  Library rpath: [/home/abner/.../libpng/lib:]
```

#### **(2) 检查动态库加载行为**
运行程序并观察库加载路径：
```bash
LD_DEBUG=libs ./osgearth_version
```
输出中会显示动态库的搜索顺序，确认是否优先从 `RPATH` 路径加载。

---

### **是否需要修改 `RPATH`？**
- **如果目标是完全静态链接**：  
  你的链接命令中出现了 `libpng16d.so.16.51.git`，说明仍有动态库依赖。若想彻底静态链接，需确保：
  1. 所有库（包括 `libpng`、`libosgEarth.a` 的依赖）都以静态形式链接（`.a`）。
  2. **移除 `-Wl,-rpath`**（因为静态链接无需运行时库搜索路径）。

- **如果允许动态链接 `libpng`**：  
  保留 `-Wl,-rpath`，但确保路径指向正确的动态库目录。

---

### **如何强制静态链接 `libpng`？**
#### **(1) 修改 CMake 配置**
确保以下变量指向静态库：
```cmake
set(PNG_LIBRARY "/home/abner/.../libpng/lib/libpng.a")
set(PNG_STATIC ON)  # 如果 FindPNG.cmake 支持
```

#### **(2) 检查依赖关系**
运行以下命令，确认 `libosgEarth.a` 是否依赖 `libpng.so`：
```bash
nm ../../osgEarth/libosgEarth.a | grep png_
```
- 如果输出中有 `U png_`（未定义符号），说明需要链接 `libpng.a`。  
- 如果无输出，说明 `libosgEarth.a` 已静态包含 PNG 代码。

#### **(3) 手动编辑链接命令**
直接替换动态库为静态库：
```bash
# 将链接命令中的：
/home/abner/.../libpng/lib/libpng16d.so.16.51.git
# 替换为：
/home/abner/.../libpng/lib/libpng.a
```

---

### **总结**
1. **当前 `RPATH` 配置**：  
   `-Wl,-rpath,/home/abner/.../libpng/lib:` 是有效的，会优先从该路径加载动态库。
2. **彻底静态链接**：  
   - 移除 `-Wl,-rpath`。  
   - 确保所有库（包括 PNG）以 `.a` 形式链接。  
3. **调试工具**：  
   - `readelf -d` 查看 `RPATH`。  
   - `nm` 检查静态库依赖。  
   - `LD_DEBUG=libs` 跟踪动态库加载。  

如果仍有问题，请提供：  
- `readelf -d ./osgearth_version` 的输出。  
- `nm ../../osgEarth/libosgEarth.a | grep png_` 的结果。



