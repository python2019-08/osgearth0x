# 1.osgEarth渲染过程
原创 于 2023-04-26 17:02:35 发布  
原文链接：https://blog.csdn.net/Yilian9990/article/details/130389964


本文详细追踪了osgEarth3.3的渲染过程，从viewer.setSceneData()设置场景数据开始，经过ViewerBase::frame()触发渲染，深入到Renderer的cull_draw()和draw()方法，以及Drawable的绘制阶段。文章旨在帮助读者理解osgEarth的渲染原理，从而减少学习曲线。

本人对osgEarth3.3渲染过程进行了跟踪，跟踪结果显示渲染过程，有助于兄弟们认识osgEarth渲染原理，减少学习时间。

```cpp
viewer.setSceneData(mRoot);// 想必大家了解这一行，设置viewer的场景数据，才有下面的帧显示

viewer.frame();  // 主程序从这里开启渲染：

ViewerBase::frame() // 调用从这里开始，逐步向下传递调用，中间有循环

ViewerBase::renderingTraversals()

GraphicsContext::runOperations(){if (camera->getRenderer()) (*(camera->getRenderer()))(this);}

void Renderer::operator () (osg::GraphicsContext* /*context*/)
{

    if (_graphicsThreadDoesCull)
    {
        cull_draw();
    }
    else
    {
        draw();
    }
}

Renderer::cull_draw()

SceneView::draw(){_renderStage->draw(_renderInfo,previous);}

Drawable::draw

Drawable::createVertexArrayState

SharedGeometry::createVertexArrayState

RenderStage::draw

RenderStage::drawInner

RenderBin::draw

RenderStage::drawImplementation

RenderBin::drawImplementation

RenderLeaf::render

LayerDrawableGL3::drawImplementation(osg::RenderInfo& ri) const

DrawTileCommand::draw(osg::RenderInfo& ri) const

LayerDrawable::drawImplementation(ri)

Drawable::draw

Drawable::inline void drawInner(RenderInfo& renderInfo) const

SharedGeometry::drawImplementation
``` 

# 2.三维场景中的渲染机制

https://www.osgchina.cn/show.php?id=294

三维渲染的基本流程：

首先，我们通过计算公式或者实测数据，形成地表电磁数据。由于高度不同，所以数据是三维数据。这些数据，包括各个点数据（即三维中的顶点数据），颜色数据。但是为了显示效果，我们可能会附加上纹理数据（例如地表图片）和法线数据（为了形成真实美观的阴影效果）。

顶点数据可以直接传递给显存，也可以通过顶点数组和显示列表传给显存。这些传入的数据，基本上就是本地坐标（如果直接整体传入，也可以认为是一个整体，并且以0为基点。）。

数据有了，要想把它显示出来，必须是被摄像机捕获到。这里可以理解成人眼，只有到了人的视野之内，人才可能是看到物体。如下图所图，摄像机会形成一个梯形空间，只有物体进到这个空间之中后，才能被识别。如果我们有1万个测试点数据，但是只有100个在这个空间之中，即只有这一百个会显示，其它的就可以不用显示了，因为即使显示了，也看不到。

当然，如果用梯形空间去进行裁剪，计算量太大，我们经常是把裁剪体做成一个立方体，和梯形视锥可能不太一样，但是计算量会小很多。

裁剪完后，我们的可视空间里就只有需要显示的数据了，这时就可以把这些数据投影到远平面上了。这里我们可以把远平面上的图像，这样就可以形成二维坐标了。也可以想象成二维的图片。

形成远平面上的图像后，我们就可以把整个物体的显示轮廓画出来了。这个阶段就是根据索引将顶点链接到一起，组成线、面单元，然后进行裁剪，如果一个三角形超出屏幕以外，例如两个顶点在屏幕内，一个顶点在屏幕外，这时我们在屏幕上看到的就是一个四边形，然后把这个四边形切成两个小的三角形。现在我们得到了一堆在屏幕坐标上的三角形面片，这些面片是用于光栅化的。

这时，我们就可以把坐标、深度、颜色、纹理坐标等属性综合起来，在图型上上色了。这里我们不但要进行颜色的融合，还需要进行消除遮挡面和雾化等过程。

最后把得到的图像直接输送出去，就可以贴到显示器上了。

以上过程一般称做三维固定管线的渲染过程。但是，由于固定管线不会考虑到特殊情况，（举个例子，我们如果要显示的区域是一半在房间里，一半在房间外，房间里还有黄色的灯，直接用固定管线颜色直接插值可能满足不了。）所以我们为了显示效果更加真实，就可能会改变这个过程中的一些步骤。这种通过程序的方法，改变管线渲染过程的方法，被称为shader。

固定管线的渲染过程的八个步骤，并不是所有都可以改变的，一般我们能改变的只有三个：
```cpp
Vertex Shader(顶点着色器) // 替换顶点处理阶段

Fragment Shader(片元着色器，又叫像素着色器) // 替换片元处理阶段

Geometry Shader(几何着色器) // 替换图元组装阶段.
```

另外，由于opengl对顶点数据输入的要求，我们可能对同一数据传入多次，这样，内存与显存的交互太频繁，这样可能会影响效率，这时，我们可以一次性传入多个。比方，原来画一百架飞机，需要传一百次，画一百次，现在可以把一百架飞机一次性传入，做好相对坐标，直接画出。

===========================================================
# 3.osgearth瓦片渲染
原创 已于 2023-12-25 16:18:17 修改 
原文链接：https://blog.csdn.net/kasteluo/article/details/135202549

osgearth瓦片渲染
相关类：

## TileNode

```cpp
/**
     * TileNode represents a single tile. TileNode has 5 children:
     * one SurfaceNode that renders the actual tile content under a MatrixTransform;
     * and four TileNodes representing the LOD+1 quadtree tiles under this tile.
     */
```
## TileDrawable: 只是瓦片的一个外壳，持有内部的SharedGeomtry进行最后渲染

```cpp
 /**
     * TileDrawable is an osg::Drawable that represents an individual terrain tile
     * for the purposes of scene graph operations (like intersections, bounds
     * computation, statistics, etc.)
     * 
     * NOTE: TileDrawable does not actually render anything!
     * The TerrainRenderData object does all the rendering of tiles.
     *
     * Instead, it exposes various osg::Drawable Functors for traversing
     * the terrain's geometry. It also hold a pointer to the tile's elevation
     * raster so it can properly reflect the elevation data in the texture.
     */
```

## SharedGeometry： 瓦片渲染的最小单元，由GeometryPool::createGeometry创建

## SurfaceNode： the node to house the tile drawable:TtileDrawable的持有者

## RexTerrainEngine:派生自TerrainEngine，用于生成瓦片
 
```cpp
 * TerrainEngineNode is the base class and interface for map engine implementations.
     *
     * A map engine lives under a MapNode and is responsible for generating the
     * actual geometry representing the Earth.
     * /
```

RexTerrainEngine有个创建tile的接口：

一个是创建heightmap的瓦片，一个是创建地球瓦片
```cpp
    //! for standalone tile creation outside of a terrain
    osg::Node* createTile(const TileKey& key);

    //! Create a standalone tile from a tile model (experimental)
    osg::Node* createTile(
        const TerrainTileModel* model,
        int createTileFlags,
        unsigned referenceLOD);
```

## LayerDrawable:作为一个layer所拥有的DrawTileCommand，统一进行渲染

```cpp
/**
     * Drawable for single "Layer" i.e. rendering pass. 
     * It is important that LayerDrawables be rendered in the order in which
     * they appear. Since all LayerDrawables share a common bounds, this 
     * should happen automatically, but let's keep an eye out for trouble.
     */
```
