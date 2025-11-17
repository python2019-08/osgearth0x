# 1.ubuntu上要编译 基于 configure的代码，需要安装的工具

在 Ubuntu 上编译基于 `configure` 的代码（通常是使用 Autotools 工具链构建的项目，包含 `configure` 脚本、`Makefile.in` 等文件），需要安装以下基础工具和依赖：


### 一、核心编译工具链
这是编译任何 C/C++ 代码的基础，必须安装：
```bash
sudo apt update
sudo apt install build-essential
```
`build-essential` 是一个元包，会自动安装以下关键工具：
- **gcc/g++**：GNU C/C++ 编译器
- **make**：用于解析 `Makefile` 并执行编译命令
- **libc6-dev**：C 标准库的开发文件（包含头文件等）
- **dpkg-dev**：Debian 包开发工具（提供编译相关的辅助工具）


### 二、Autotools 相关工具（针对 `configure` 脚本）
`configure` 脚本通常由 Autotools 工具链生成，编译前可能需要以下工具处理配置过程：
```bash
sudo apt install autoconf automake libtool
```
- **autoconf**：生成 `configure` 脚本的工具
- **automake**：生成 `Makefile.in`（`configure` 脚本会根据它生成 `Makefile`）
- **libtool**：用于管理共享库的编译和链接（部分项目依赖）


### 三、其他可能需要的工具
根据项目特性，可能还需要安装：
1. **pkg-config**：用于查找系统中已安装的库的头文件和链接路径（很多项目依赖）
   ```bash
   sudo apt install pkg-config
   ```

2. **依赖库的开发包**：  
   项目可能依赖特定的库（如 `libssl`、`libxml2` 等），需要安装对应的 **开发包**（通常以 `-dev` 或 `-devel` 结尾）。  
   例如：
   - 若依赖 OpenSSL：`sudo apt install libssl-dev`
   - 若依赖 XML 解析：`sudo apt install libxml2-dev`
   - 若依赖图形库（如 GTK）：`sudo apt install libgtk-3-dev`

   提示：若编译时出现 `xxx.h: No such file or directory` 错误，通常是缺少对应的 `-dev` 包，可通过 `apt search` 查找并安装（如搜索 `xml2` 相关开发包：`apt search xml2 | grep dev`）。


### 四、编译流程（以 `configure` 项目为例）
安装上述工具后，典型的编译步骤为：
1. 解压源码包（如 `.tar.gz` 或 `.tar.bz2`）：
   ```bash
   tar -zxvf project.tar.gz  # 解压 gzip 格式
   cd project/  # 进入源码目录
   ```

2. （可选）若源码中没有 `configure` 脚本，需先用 Autotools 生成：
   ```bash
   autoreconf -i  # 生成 configure 脚本（依赖 autoconf、automake 等）
   ```

3. 运行 `configure` 配置编译参数（可通过 `--prefix` 指定安装路径）：
   ```bash
   ./configure --prefix=/usr/local  # 配置安装到 /usr/local 目录
   ```
   若有依赖库找不到，可通过 `PKG_CONFIG_PATH` 指定库路径，例如：
   ```bash
   PKG_CONFIG_PATH=/path/to/custom/lib/pkgconfig ./configure
   ```

4. 编译并安装：
   ```bash
   make  # 编译（可加 -j4 启用 4 线程加速）
   sudo make install  # 安装到指定目录
   ```


### 总结
核心工具是 `build-essential`（编译基础） + `autoconf automake libtool`（处理 `configure`），再根据项目依赖安装对应的 `-dev` 包即可。遇到缺失文件的错误时，通过 `apt search` 查找相关开发包是快速解决的关键。

======================================
# 2.ubuntu安装opengl开发包

在 Ubuntu 上安装 OpenGL 开发包，主要需要安装包含 OpenGL 头文件、链接库以及相关依赖的开发包。以下是具体步骤：

### 1. 安装核心开发包
OpenGL 的核心开发文件（头文件和库）通常包含在 `libgl1-mesa-dev` 中，这是 Mesa 3D 开源实现的一部分，适用于大多数场景：
```bash
sudo apt-get update
sudo apt-get install libgl1-mesa-dev
```

### 2. 安装 GLU（OpenGL 实用库）
如果需要使用 GLU（OpenGL Utility Library），需额外安装：
```bash
sudo apt-get install libglu1-mesa-dev
```
GLU 提供了曲面、多边形分割等高级功能，许多传统 OpenGL 程序依赖它。

### 3. 安装开发工具（可选）
如果需要编译 OpenGL 程序，可能还需要基础编译工具：
```bash
sudo apt-get install build-essential cmake
```

### 4. 验证安装
安装完成后，可以通过检查头文件和库文件是否存在来验证：
- 头文件路径：`/usr/include/GL/gl.h`（核心 OpenGL）、`/usr/include/GL/glu.h`（GLU）
- 库文件路径：`/usr/lib/x86_64-linux-gnu/libGL.so`（OpenGL 库）、`/usr/lib/x86_64-linux-gnu/libGLU.so`（GLU 库）


以上步骤适用于大多数基于 Mesa 的 OpenGL 开发场景。如果需要特定厂商的闭源驱动（如 NVIDIA 或 AMD），可根据显卡型号安装对应驱动，以获得更好的性能支持。
