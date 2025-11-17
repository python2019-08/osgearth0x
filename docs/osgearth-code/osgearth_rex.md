# 1.osgearth_engine_rex 是干啥用的

**osgearth_engine_rex** 是 osgEarth 中的一个 **核心渲染引擎实现**，全称为 **Rendering Engine (REX)**。它是 osgEarth 用于高效渲染大规模地理空间数据（尤其是地形和影像）的关键技术模块。以下是它的核心作用和技术细节：

---

### **1. 核心功能**
| 功能 | 说明 |
|------|------|
| **地形分块渲染** | 将全球地形分割为多层级瓦片（Quadtree），动态加载可见区域 |
| **GPU 优化** | 使用 GLSL 着色器和 GPU 计算（如细分着色器）提升渲染效率 |
| **多数据源融合** | 支持混合加载高程（DEM）、影像（卫星图）、矢量数据 |
| **LOD 管理** | 根据视距动态切换地形细节级别（Level of Detail） |
| **异步加载** | 后台线程预加载相邻区域瓦片，减少卡顿 |

---

### **2. 技术特点**
#### **(1) 动态瓦片调度**
- **四叉树分割**：将地球表面递归划分为 `TileKey`（瓦片键），每个瓦片包含几何和纹理。
- **视锥剔除**：只渲染当前视角可见的瓦片。
- **优先级队列**：根据相机距离和屏幕空间误差（SSE）决定加载顺序。

#### **(2) 高效渲染管线**
```cpp
osgEarth::REX::EngineDriver {
    void render(osg::RenderInfo&) {
        updateTileNodes();  // 更新可见瓦片
        dispatchGPUJobs();  // 提交地形细分/纹理混合任务
    }
}
```
- **GPU 地形细分**：使用 `GL_TESS_CONTROL_SHADER` 动态增加几何细节。
- **纹理混合**：支持多图层透明叠加（如道路叠加到卫星图）。

#### **(3) 内存管理**
- **LRU 缓存**：自动释放不可见瓦片的 GPU 资源。
- **智能预加载**：预测相机移动方向，提前加载潜在可见瓦片。

---

### **3. 配置与使用**
#### **启用 REX 引擎**
在 `earth` 配置文件中指定：
```xml
<map>
    <options>
        <terrain engine="rex">  <!-- 显式启用REX -->
            <tilesize>257</tilesize>  <!-- 瓦片网格尺寸 -->
        </terrain>
    </options>
</map>
```

#### **关键参数**
| 参数 | 作用 | 典型值 |
|------|------|--------|
| `tilesize` | 单个瓦片的顶点网格大小 | 17/65/257 |
| `min_level` | 最粗层级（全球视图） | 0 |
| `max_level` | 最细层级（地面细节） | 20 |
| `lod_scale` | LOD 切换灵敏度 | 1.0（默认） |

---

### **4. 性能优化技巧**
#### **(1) 减少瓦片加载延迟**
```cpp
viewer->getDatabasePager()->setDoPreCompile(true);  // 预编译GL对象
```

#### **(2) 控制显存占用**
```xml
<terrain>
    <texture_compression>dxt5</texture_compression>  <!-- 压缩纹理 -->
    <max_texture_size>4096</max_texture_size>        <!-- 限制纹理大小 -->
</terrain>
```

#### **(3) 调试工具**
```bash
# 查看REX瓦片加载状态
osgearth_viewer --rex-debug
```

---

### **5. 对比其他引擎**
| 引擎 | 适用场景 | 特点 |
|------|----------|------|
| **REX** | 大规模动态地形 | GPU加速、支持全球数据 |
| **MP** (Mapbox) | 小范围高精度 | 适合离线地图 |
| **Simple** | 测试/原型开发 | 无LOD，性能低 |

---

### **6. 典型问题解决**
#### **问题：瓦片边界裂缝**
**原因**：相邻瓦片高程数据不匹配。  
**解决**：
```xml
<terrain>
    <skirt_ratio>0.025</skirt_ratio>  <!-- 添加“裙边”遮盖接缝 -->
</terrain>
```

#### **问题：GPU内存不足**
**解决**：
```cpp
osgEarth::Registry::instance()->setMinMaxTexturePoolSize(0, 2048);  // 限制纹理池
```

---

### **总结**
- **osgearth_engine_rex** 是 osgEarth 的默认地形渲染引擎，专为 **大规模、动态、多源地理数据** 设计。
- 核心优势：**智能瓦片调度 + GPU 加速渲染**，平衡性能与视觉效果。
- 适用场景：数字地球、飞行模拟、GIS 可视化等需要全球高精度地形的应用。