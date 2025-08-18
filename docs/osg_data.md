# 1. osg data download url

osg data download url:
https://openscenegraph.github.io/OpenSceneGraphDotComBackup/OpenSceneGraph/www.openscenegraph.com/index.php/download-section/data.html

[OpenSceneGraph-Data ](https://github.com/openscenegraph/OpenSceneGraph-Data.git)

=======================================================
# 2. osgDraco

# 2. osgdraco是什么，osgearth编译时必需它吗

### **osgDraco 是什么？**

由于 Draco 是 Google 开发的开源 3D 几何压缩库，以高压缩率和快速解压为特点，osgdraco 扩展让 OSG 应用（如三维可视化、游戏、仿真系统等）能够更高效地处理大型 3D 模型，尤其适合需要传输或加载海量几何数据的场景。

`osgDraco` 是一个基于 **OpenSceneGraph (OSG)** 的插件，用于加载和渲染 **Draco 压缩格式**的 3D 几何数据。

#### **核心信息：**
1. **Draco 压缩格式**：  
   - 由 Google 开发的开源 3D 网格和点云压缩格式，可显著减小文件体积（通常压缩率为 20-50%）。
   - 支持保留几何精度、纹理坐标、法线等属性。

2. **osgDraco 的作用**：  
   - 作为 OSG 的插件（`.osgPlugins-<版本号>/osgdb_draco.so`），允许 OSG 直接加载 `.drc` 文件。
   - 实现 Draco 数据的实时解压缩和渲染，无需预处理。

3. **应用场景**：  
   - 大规模 3D 地形、点云数据的传输和加载（如数字孪生、地理信息系统）。
   - 减少网络带宽需求，提升渲染性能。


### **osgEarth 编译时是否必需 osgDraco？**

**答案：不是必需的，但推荐安装。**

#### **具体说明：**
1. **非必需性**：  
   - osgEarth 本身支持多种地形数据格式（如 GeoTIFF、JPEG、PNG、TIN 等）。
   - 即使不安装 osgDraco，osgEarth 仍能正常编译和运行。

2. **推荐安装的原因**：  
   - **性能优化**：  
     - 若地形数据采用 Draco 压缩（如 Cesium 提供的 3D Tiles 中的 `.b3dm` 或 `.pnts` 可能内嵌 Draco 数据），osgDraco 可加速加载和解压。
   - **格式兼容性**：  
     - 某些高级地形数据源（如大规模点云或高精度网格）可能仅提供 Draco 格式。
   - **未来趋势**：  
     - 随着 WebGL 和 WebGPU 对 Draco 的支持增加，osgDraco 可能成为处理压缩 3D 数据的标准插件。


### **osgEarth 与 osgDraco 的集成步骤**

若需在 osgEarth 中使用 osgDraco，需按以下步骤操作：

1. **安装依赖**：  
   ```bash
   # Ubuntu/Debian
   sudo apt-get install libdraco-dev

   # 或从源码编译 Draco
   git clone https://github.com/google/draco.git
   cd draco && mkdir build && cd build
   cmake .. && make -j8 && sudo make install
   ```

2. **编译 osgDraco**：  
   ```bash
   git clone https://github.com/OpenMW/osgDraco.git
   cd osgDraco && mkdir build && cd build
   cmake -DOSG_DIR=/path/to/osg ..
   make -j8 && sudo make install
   ```

3. **配置 osgEarth**：  
   - 编译 osgEarth 时，确保 CMake 能找到 Draco 和 osgDraco：  
     ```bash
     cmake -DOPENSCENEGRAPH_INCLUDE_DIR=/path/to/osg/include \
           -DOPENSCENEGRAPH_LIBRARY_DIR=/path/to/osg/lib \
           -DDraco_DIR=/path/to/draco/cmake ..
     ```

4. **验证安装**：  
   - 检查 OSG 插件目录是否存在 `osgdb_draco.so`（Linux）或 `osgdb_draco.dll`（Windows）。
   - 测试命令：  
     ```bash
     osgviewer your_model.drc
     ```


### **总结**
- **osgDraco** 是 OSG 的 Draco 格式加载插件，用于优化 3D 数据的压缩和渲染。
- **osgEarth 编译时不需要 osgDraco**，但安装后可增强对 Draco 格式地形数据的支持，提升性能。
- 若项目涉及大规模压缩 3D 数据，建议集成 osgDraco；否则可跳过此依赖。