#  0.绘制4.4MB mbtiles mvt矢量瓦片数据库，内存瞬间增长到1G-1.6G
现在碰到一个内存瓶颈问题，绘制4.4MB  mbtiles   mvt  矢量瓦片数据库，内存瞬间增长到1G-1.6G,  导致崩溃.

你需要看 mbtiles插件的 代码了吧? 那个看了，就是一个简单的查询sqlite, 和解析pbf  mvt 瓦片数据,这个很固定的,没法改.


为什么看起来“无限增长”? 随着摄像机在高 LOD范国内漫游，DatabasePager 以“加载快、回收慢"为策略:新瓦片源源不断进入内存，老瓦片要等到 GC 触发或离开可视范围很久后才回收。若 12Cachesize、targetMaximumNumberOfPageL0D 过大，再叠加文本、feature 索引，就会出现内存持续上升甚至耗尽。


osg里是怎么合批的? 有个选项和可以合并几何,mergeGeometry.

我把线宽设置成米为单位，就不暴涨内存了，这个很奇怪. 像素单位的线宽就暴涨.  按理说应该复用mesh，线宽通过变量传给shader.mesh 尽量少变。 我看了它的LineDrawable.glsl, 好像他不是通过法向量*线宽的方式。 

# 1. compileShader(osg::State& state)

/home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Shader.cpp:582:  Shader::PerContextShader::compileShader(osg::State& state)

/home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Drawable.cpp557: virtual void drawElements(GLenum,GLsizei count,const GLushort* indices) 
/home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/TemplatePrimitiveIndexFunctor:246:  virtual void drawElements(GLenum mode,GLsizei count,const GLushort* indices)

/home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgViewer/Renderer.cpp:   Renderer::cull_draw()

#if defined(OSG_GLES1_AVAILABLE) || defined(OSG_GLES2_AVAILABLE) || defined(OSG_GLES3_AVAILABLE)
  OE_WARN << "no glTexImage1D() in GLES \n";
#else

#endif

```sh
#   /data/user/0/com.example.androioearthdemo/files/readymap.earth
~/osgearth0x$ adb devices
List of devices attached
3054854792003E9	device
emulator-5554	device


(base) ~/osgearth0x$ adb -s 3054854792003E9 shell
PD2106:/ $  
PD2106:/ $ run-as com.example.androioearthdemo
PD2106:/data/user/0/com.example.androioearthdemo $ ls
cache  code_cache  files  lldb
PD2106:/data/user/0/com.example.androioearthdemo $ cd  files/  
PD2106:/data/user/0/com.example.androioearthdemo/files $ ls
readymap.earth

# Q2：如何修改 readymap.earth？​​
# 在电脑上编辑文件后，通过 adb push传回手机：
adb push ~/Desktop/readymap.earth /sdcard/
adb shell
run-as com.example.androioearthdemo
cp /sdcard/readymap.earth /data/user/0/com.example.androioearthdemo/files/
```


```sh 
# adb  logcat
adb -s 3054854792003E9 logcat | grep -E "osgEarth|OSG|OpenGL|EGL|Failed"
adb -s 3054854792003E9 logcat | grep -E "GL_ERROR"

adb -s emulator-5554 logcat | grep -E "osgEarth|OSG|OpenGL|EGL|Failed"
```

======================================================================
# 2.crash bug ---因为 Atomic::operator++()最后一个else, 就是普通变量; 没有C++的原子操作

 定义宏 OPENTHREADS_ATOMIC_USE_MUTEX ，可解决这个bug。 

_OSG_REFERENCED_USE_ATOMIC_OPERATIONS
_OPENTHREADS_ATOMIC_USE_MUTEX

```cpp
class OSG_EXPORT Referenced // object  的基类
{

    public:


        Referenced();

        /** Deprecated, Referenced is now always uses thread safe ref/unref, use default Referenced() constructor instead */
        explicit Referenced(bool threadSafeRefUnref);

        Referenced(const Referenced&);

        inline Referenced& operator = (const Referenced&) { return *this; }

        /** Deprecated, Referenced is always theadsafe so there method now has no effect and does not need to be called.*/
        virtual void setThreadSafeRefUnref(bool /*threadSafe*/) {}

        /** Get whether a mutex is used to ensure ref() and unref() are thread safe.*/
#if defined(_OSG_REFERENCED_USE_ATOMIC_OPERATIONS)
        bool getThreadSafeRefUnref() const { return true; }
#else
        bool getThreadSafeRefUnref() const { return _refMutex!=0; }
#endif

        /** Get the mutex used to ensure thread safety of ref()/unref(). */
#if defined(_OSG_REFERENCED_USE_ATOMIC_OPERATIONS)
        OpenThreads::Mutex* getRefMutex() const { return getGlobalReferencedMutex(); }
#else
        OpenThreads::Mutex* getRefMutex() const { return _refMutex; }
#endif

        /** Get the optional global Referenced mutex, this can be shared between all osg::Referenced.*/
        static OpenThreads::Mutex* getGlobalReferencedMutex();

        /** Increment the reference count by one, indicating that
            this object has another pointer which is referencing it.*/
        inline int ref() const;

        /** Decrement the reference count by one, indicating that
            a pointer to this object is no longer referencing it.  If the
            reference count goes to zero, it is assumed that this object
            is no longer referenced and is automatically deleted.*/
        inline int unref() const;

        /** Decrement the reference count by one, indicating that
            a pointer to this object is no longer referencing it.  However, do
            not delete it, even if ref count goes to 0.  Warning, unref_nodelete()
            should only be called if the user knows exactly who will
            be responsible for, one should prefer unref() over unref_nodelete()
            as the latter can lead to memory leaks.*/
        int unref_nodelete() const;

        /** Return the number of pointers currently referencing this object. */
        inline int referenceCount() const { return _refCount; }


        /** Get the ObserverSet if one is attached, otherwise return NULL.*/
        ObserverSet* getObserverSet() const
        {
            #if defined(_OSG_REFERENCED_USE_ATOMIC_OPERATIONS)
                return static_cast<ObserverSet*>(_observerSet.get());
            #else
                return static_cast<ObserverSet*>(_observerSet);
            #endif
        }

        /** Get the ObserverSet if one is attached, otherwise create an ObserverSet, attach it, then return this newly created ObserverSet.*/
        ObserverSet* getOrCreateObserverSet() const;

        /** Add a Observer that is observing this object, notify the Observer when this object gets deleted.*/
        void addObserver(Observer* observer) const;

        /** Remove Observer that is observing this object.*/
        void removeObserver(Observer* observer) const;
#if 0
         /** Resize any per context GLObject buffers to specified size. */
        virtual void resizeGLObjectBuffers(unsigned int /*maxSize*/) {}

        /** If State is non-zero, this function releases any associated OpenGL objects for
           * the specified graphics context. Otherwise, releases OpenGL objects
           * for all graphics contexts. */
        virtual void releaseGLObjects(osg::State* = 0) const {}
#endif
public:

        friend class DeleteHandler;

        /** Set a DeleteHandler to which deletion of all referenced counted objects
          * will be delegated.*/
        static void setDeleteHandler(DeleteHandler* handler);

        /** Get a DeleteHandler.*/
        static DeleteHandler* getDeleteHandler();


    protected:

        virtual ~Referenced();

        void signalObserversAndDelete(bool signalDelete, bool doDelete) const;

        void deleteUsingDeleteHandler() const;

#if defined(_OSG_REFERENCED_USE_ATOMIC_OPERATIONS)
        mutable OpenThreads::AtomicPtr  _observerSet;

        mutable OpenThreads::Atomic     _refCount;
#else

        mutable OpenThreads::Mutex*     _refMutex;

        mutable int                     _refCount;

        mutable void*                   _observerSet;
#endif
};

 Referenced::~Referenced()
{
#ifdef DEBUG_OBJECT_ALLOCATION_DESTRUCTION
    {
        OpenThreads::ScopedLock<OpenThreads::Mutex> lock(getNumObjectMutex());
        --s_numObjects;
        printf("Object created, total num=%d\n",s_numObjects);
    }
#endif

    if (_refCount>0)
    {
        OSG_WARN<<"Warning: deleting still referenced object "<<this<<" of type '"<<typeid(this).name()<<"'"<<std::endl;
        OSG_WARN<<"         the final reference count was "<<_refCount<<", memory corruption possible."<<std::endl;
    }

    // signal observers that we are being deleted.
    signalObserversAndDelete(true, false);

    // delete the ObserverSet
#if defined(_OSG_REFERENCED_USE_ATOMIC_OPERATIONS)
    if (_observerSet.get()) static_cast<ObserverSet*>(_observerSet.get())->unref();
#else
    if (_observerSet) static_cast<ObserverSet*>(_observerSet)->unref();
#endif

#if !defined(_OSG_REFERENCED_USE_ATOMIC_OPERATIONS)
    if (_refMutex) delete _refMutex;
#endif
}
 
mutable OpenThreads::Atomic     _refCount;//能后这个里面默认的宏，在android环境下就是变成普通变量 

Atomic::operator++()
{
#if defined(_OPENTHREADS_ATOMIC_USE_GCC_BUILTINS)
    return __sync_add_and_fetch(&_value, 1);
#elif defined(_OPENTHREADS_ATOMIC_USE_MIPOSPRO_BUILTINS)
    return __add_and_fetch(&_value, 1);
#elif defined(_OPENTHREADS_ATOMIC_USE_SUN)
    return atomic_inc_uint_nv(&_value);
#elif defined(_OPENTHREADS_ATOMIC_USE_MUTEX)
    ScopedLock<Mutex> lock(_mutex);
    return ++_value;
#else
    return ++_value; // 最后一个else, 就是普通变量; 没有C++的原子操作
#endif
} 
``` 

=============================================================
# 3. crash callstacks

## 3.1 crash callstack 1
```sh

2025-10-30 23:44:28.093 18127-18168 AndroiOearth01com.oearth.androioearth01  D  State::convertShaderSourceToOsgBuiltIns()
2025-10-30 23:44:28.490 18127-18127 libc     com.oearth.androioearth01  A  Fatal signal 11 (SIGSEGV), code 1 (SEGV_MAPERR), fault addr 0x0 in tid 18127 (.androioearth01), pid 18127 (.androioearth01)
2025-10-30 23:44:28.580 18364-18364 DEBUG    pid-18364   A  pid: 18127, tid: 18127, name: .androioearth01  >>> com.oearth.androioearth01 <<<


#00 pc 39e17f0  (osgEarth::REX::TileDrawable::accept(osg::PrimitiveFunctor&) const+112) 
#01 pc 3d9c784  (osgUtil::LineSegmentIntersector::intersect(osgUtil::IntersectionVisitor&, osg::Drawable*, osg::Vec3d const&, osg::Vec3d const&)+636) 
#02 pc 3d9b460  (osgUtil::LineSegmentIntersector::intersect(osgUtil::IntersectionVisitor&, osg::Drawable*)+204) 
#03 pc 3d8a0bc  (osgUtil::IntersectionVisitor::intersect(osg::Drawable*)+56) 
#04 pc 3d8a074  (osgUtil::IntersectionVisitor::apply(osg::Drawable&)+28) 
#05 pc 37cf9d4  (osg::Drawable::accept(osg::NodeVisitor&)+72) 
#06 pc 3b1acc4  (osg::Group::traverse(osg::NodeVisitor&)+120) 
#07 pc 31504b8  (osg::NodeVisitor::traverse(osg::Node&)+100) 
#08 pc 3d8b178  (osgUtil::IntersectionVisitor::apply(osg::Transform&)+580) 
#09 pc 3b537f8  (osg::NodeVisitor::apply(osg::MatrixTransform&)+36) 
#10 pc 39c21d4  (osg::MatrixTransform::accept(osg::NodeVisitor&)+72) 
#11 pc 39ea064  (osgEarth::REX::TileNode::traverse(osg::NodeVisitor&)+684) 
#12 pc 31504b8  (osg::NodeVisitor::traverse(osg::Node&)+100) 
#13 pc 3d8a03c  (osgUtil::IntersectionVisitor::apply(osg::Group&)+56) 
#14 pc 317e398  (osg::Group::accept(osg::NodeVisitor&)+72) 
#15 pc 39ea018  (osgEarth::REX::TileNode::traverse(osg::NodeVisitor&)+608) 
#16 pc 31504b8  (osg::NodeVisitor::traverse(osg::Node&)+100) 
#17 pc 3d8a03c  (osgUtil::IntersectionVisitor::apply(osg::Group&)+56) 
#18 pc 317e398  (osg::Group::accept(osg::NodeVisitor&)+72) 
#19 pc 39ea018  (osgEarth::REX::TileNode::traverse(osg::NodeVisitor&)+608) 
#20 pc 31504b8  (osg::NodeVisitor::traverse(osg::Node&)+100) 
#21 pc 3d8a03c  (osgUtil::IntersectionVisitor::apply(osg::Group&)+56) 
#22 pc 317e398  (osg::Group::accept(osg::NodeVisitor&)+72) 
#23 pc 3b1acc4  (osg::Group::traverse(osg::NodeVisitor&)+120) 
#24 pc 31504b8  (osg::NodeVisitor::traverse(osg::Node&)+100) 
#25 pc 3d8a03c  (osgUtil::IntersectionVisitor::apply(osg::Group&)+56) 
#26 pc 317e398  (osg::Group::accept(osg::NodeVisitor&)+72) 
#27 pc 3b1acc4  (osg::Group::traverse(osg::NodeVisitor&)+120) 
#28 pc 378ac68  (osgEarth::TerrainEngineNode::traverse(osg::NodeVisitor&)+440) 
#29 pc 39752ac  (osgEarth::REX::RexTerrainEngineNode::traverse(osg::NodeVisitor&)+204) 
#30 pc 31504b8  (osg::NodeVisitor::traverse(osg::Node&)+100) 
#31 pc 3d8a03c  (osgUtil::IntersectionVisitor::apply(osg::Group&)+56) 
#32 pc 3b5368c  (osg::NodeVisitor::apply(osg::CoordinateSystemNode&)+36) 
#33 pc 397747c  (osgEarth::REX::RexTerrainEngineNode::accept(osg::NodeVisitor&)+72) 
#34 pc 31cb51c  (osgEarth::Util::EarthManipulator::intersectLookVector(osg::Vec3d&, osg::Vec3d&, osg::Vec3d&) const+624) 
#35 pc 31c5bbc  (osgEarth::Util::EarthManipulator::recalculateCenterFromLookVector()+92) 
#36 pc 31d39a8  (osgEarth::Util::EarthManipulator::zoom(double, double, osg::View*)+1512) 
#37 pc 3142e28  (OsgMainApp::touchZoomEvent(double)+200) 
#38 pc 3145264  (Java_com_oearth_androioearth01_osgNativeLib_touchZoomEvent+36) 
#39 pc 0020b58  oat/arm64/base.odex (art_jni_trampoline+152)
#40 pc 200bd20  /memfd:jit-cache (deleted) (offset 0x2000000) (com.oearth.androioearth01.EGLview$1.onTouch+1920)
```

## 3.2 crash callstack 2

```sh
2025-10-31 00:22:10.174 32033-32033 DEBUG    pid-32033   A  pid: 31714, tid: 31752, name: GLThread 11004  >>> com.oearth.androioearth01 <<<
2025-10-31 00:22:10.320 31714-31842 AndroiOearth01com.oearth.androioearth01  D  
2025-10-31 00:22:10.320 31714-31842 AndroiOearth01com.oearth.androioearth01  I  get_orientation()


#00 pc 328f88c  (osg::PrimitiveSet::getMode() const+12) 
#01 pc 39c4670  (osgEarth::REX::DrawTileCommand::draw(osg::RenderInfo&) const+712) 
#02 pc 39d77bc  (osgEarth::REX::LayerDrawableGL3::drawImplementation(osg::RenderInfo&) const+836) 
#03 pc 34f6188  (osg::Drawable::drawInner(osg::RenderInfo&) const+96) 
#04 pc 34ead40  (osg::Drawable::draw(osg::RenderInfo&) const+372) 
#05 pc 3e6fd14  (osgUtil::RenderLeaf::render(osg::RenderInfo&, osgUtil::RenderLeaf*)+352) 
#06 pc 3e5ce8c  (osgUtil::RenderBin::drawImplementation(osg::RenderInfo&, osgUtil::RenderLeaf*&)+724) 
#07 pc 3e77194  (osgUtil::RenderStage::drawImplementation(osg::RenderInfo&, osgUtil::RenderLeaf*&)+788) 
#08 pc 3e5cae0  (osgUtil::RenderBin::draw(osg::RenderInfo&, osgUtil::RenderLeaf*&)+120) 
#09 pc 3e75090  (osgUtil::RenderStage::drawInner(osg::RenderInfo&, osgUtil::RenderLeaf*&, bool&)+304) 
#10 pc 3e76370  (osgUtil::RenderStage::draw(osg::RenderInfo&, osgUtil::RenderLeaf*&)+1396) 
#11 pc 3ef4308  (osgUtil::SceneView::draw()+5152) 
#12 pc 3ee898c  (osgViewer::Renderer::cull_draw()+1184) 
#13 pc 3ee8f68  (osgViewer::Renderer::operator()(osg::GraphicsContext*)+52) 
#14 pc 3b0bb7c  (osg::GraphicsContext::runOperations()+328) 
#15 pc 3f45724  (osgViewer::ViewerBase::renderingTraversals()+4272) 
#16 pc 3f44660  (osgViewer::ViewerBase::frame(double)+196) 
#17 pc 3135db8  (DemoScene::frame()+44) 
#18 pc 3142854  (OsgMainApp::draw()+28) 
#19 pc 31451a8  (Java_com_oearth_androioearth01_osgNativeLib_step+28) 
#20 pc 0020710  oat/arm64/base.odex (art_jni_trampoline+144)
#21 pc 2015858  /memfd:jit-cache (deleted) (offset 0x2000000) (com.oearth.androioearth01.EGLview$Renderer.onDrawFrame+40)
```

## 3.3 crash callstack 3

```sh
2025-10-31 00:56:32.088  8095-8234  AndroiOearth01com.oearth.androioearth01  D  -------- Converted source 
2025-10-31 00:56:32.255  8095-8234  libc     com.oearth.androioearth01  A  Fatal signal 11 (SIGSEGV), code 2 (SEGV_ACCERR), fault addr 0x77e8421208 in tid 8234 (GLThread 11114), pid 8095 (.androioearth01)
2025-10-31 00:56:32.345  8635-8635  DEBUG    pid-8635    A  pid: 8095, tid: 8234, name: GLThread 11114  >>> com.oearth.androioearth01 <<<

#00 pc 0001208  base.apk (offset 0x135000)
#01 pc 3824a10  (osgEarth::TileLayer::isKeyInVisualRange(osgEarth::TileKey const&) const+136) 
#02 pc 39e73a4  (osgEarth::REX::TileNode::passInLegalRange(osgEarth::REX::RenderingPass const&) const+100) 
#03 pc 39e6fb0  (osgEarth::REX::TileNode::initializeData()+208) 
#04 pc 39e9634  (osgEarth::REX::TileNode::createChildren()+1096) 
#05 pc 39e8fd4  (osgEarth::REX::TileNode::cull(osgEarth::REX::TerrainCuller*)+436) 
#06 pc 39ea034  (osgEarth::REX::TileNode::traverse(osg::NodeVisitor&)+460) 
#07 pc 3150568  (osg::NodeVisitor::traverse(osg::Node&)+100) 
#08 pc 39b93d4  (osgEarth::REX::TerrainCuller::apply(osg::Node&)+324) 
#09 pc 3b536a0  (osg::NodeVisitor::apply(osg::Group&)+36) 
#10 pc 317e448  (osg::Group::accept(osg::NodeVisitor&)+72) 
#11 pc 39e9050  (osgEarth::REX::TileNode::cull(osgEarth::REX::TerrainCuller*)+560) 
#12 pc 39ea034  (osgEarth::REX::TileNode::traverse(osg::NodeVisitor&)+460) 
#13 pc 3150568  (osg::NodeVisitor::traverse(osg::Node&)+100) 
#14 pc 39b93d4  (osgEarth::REX::TerrainCuller::apply(osg::Node&)+324) 
#15 pc 3b536a0  (osg::NodeVisitor::apply(osg::Group&)+36) 
#16 pc 317e448  (osg::Group::accept(osg::NodeVisitor&)+72) 
#17 pc 39e9050  (osgEarth::REX::TileNode::cull(osgEarth::REX::TerrainCuller*)+560) 
#18 pc 39ea034  (osgEarth::REX::TileNode::traverse(osg::NodeVisitor&)+460) 
#19 pc 3150568  (osg::NodeVisitor::traverse(osg::Node&)+100) 

#20 pc 39b93d4  (osgEarth::REX::TerrainCuller::apply(osg::Node&)+324) 
#21 pc 3b536a0  (osg::NodeVisitor::apply(osg::Group&)+36) 
#22 pc 317e448  (osg::Group::accept(osg::NodeVisitor&)+72) 
#23 pc 3b1ad74  (osg::Group::traverse(osg::NodeVisitor&)+120) 
#24 pc 3150568  (osg::NodeVisitor::traverse(osg::Node&)+100) 
#25 pc 39b93d4  (osgEarth::REX::TerrainCuller::apply(osg::Node&)+324) 
#26 pc 3b536a0  (osg::NodeVisitor::apply(osg::Group&)+36) 
#27 pc 317e448  (osg::Group::accept(osg::NodeVisitor&)+72) 
#28 pc 3973734  (osgEarth::REX::RexTerrainEngineNode::cull_traverse(osg::NodeVisitor&)+240) 
#29 pc 397534c  (osgEarth::REX::RexTerrainEngineNode::traverse(osg::NodeVisitor&)+188) 
#30 pc 3150568  (osg::NodeVisitor::traverse(osg::Node&)+100) 
#31 pc 3d6cb2c  (osgUtil::CullVisitor::handle_cull_callbacks_and_traverse(osg::Node&)+100) 
#32 pc 3d6db88  (osgUtil::CullVisitor::apply(osg::Group&)+112) 
#33 pc 3b5373c  (osg::NodeVisitor::apply(osg::CoordinateSystemNode&)+36) 
#34 pc 397752c  (osgEarth::REX::RexTerrainEngineNode::accept(osg::NodeVisitor&)+72) 
#35 pc 3b1ad74  (osg::Group::traverse(osg::NodeVisitor&)+120) 
#36 pc 35aae5c  (osgEarth::Util::OverlayDecorator::traverse(osg::NodeVisitor&)+672) 
#37 pc 3150568  (osg::NodeVisitor::traverse(osg::Node&)+100) 
#38 pc 3d6cb2c  (osgUtil::CullVisitor::handle_cull_callbacks_and_traverse(osg::Node&)+100) 
#39 pc 3d6db88  (osgUtil::CullVisitor::apply(osg::Group&)+112) 
#40 pc 317e448  (osg::Group::accept(osg::NodeVisitor&)+72) 
#41 pc 3b1ad74  (osg::Group::traverse(osg::NodeVisitor&)+120) 
#42 pc 3150568  (osg::NodeVisitor::traverse(osg::Node&)+100) 
#43 pc 3d6cb2c  (osgUtil::CullVisitor::handle_cull_callbacks_and_traverse(osg::Node&)+100) 
#44 pc 3d6db88  (osgUtil::CullVisitor::apply(osg::Group&)+112) 
#45 pc 317e448  (osg::Group::accept(osg::NodeVisitor&)+72) 
#46 pc 351aea8  (osgEarth::MapNode::traverse(osg::NodeVisitor&)+1484) 
#47 pc 3150568  (osg::NodeVisitor::traverse(osg::Node&)+100) 
#48 pc 3a9c0ec  (osg::Callback::traverse(osg::Object*, osg::Object*)+240) 
#49 pc 35548c8  (osgEarth::HorizonClipPlane::operator()(osg::Node*, osg::NodeVisitor*)+1324) 
#50 pc 3a9c54c  (osg::NodeCallback::run(osg::Object*, osg::Object*)+188) 
#51 pc 3a9c048  (osg::Callback::traverse(osg::Object*, osg::Object*)+76) 
#52 pc 317d32c  (osgEarth::Util::InstallCameraUniform::operator()(osg::Node*, osg::NodeVisitor*)+800) 
#53 pc 3a9c54c  (osg::NodeCallback::run(osg::Object*, osg::Object*)+188) 
#54 pc 3d6cb1c  (osgUtil::CullVisitor::handle_cull_callbacks_and_traverse(osg::Node&)+84) 
#55 pc 3d6db88  (osgUtil::CullVisitor::apply(osg::Group&)+112) 
#56 pc 317e448  (osg::Group::accept(osg::NodeVisitor&)+72) 
#57 pc 3b1ad74  (osg::Group::traverse(osg::NodeVisitor&)+120) 
#58 pc 3a23c44  (osgEarth::SkyNode::traverse(osg::NodeVisitor&)+468) 
#59 pc 3a36eb4  (osgEarth::SimpleSky::SimpleSkyNode::traverse(osg::NodeVisitor&)+1256) 
#60 pc 3150568  (osg::NodeVisitor::traverse(osg::Node&)+100) 
#61 pc 3d6cb2c  (osgUtil::CullVisitor::handle_cull_callbacks_and_traverse(osg::Node&)+100) 
#62 pc 3d6db88  (osgUtil::CullVisitor::apply(osg::Group&)+112) 
#63 pc 317e448  (osg::Group::accept(osg::NodeVisitor&)+72) 
#64 pc 3b1ad74  (osg::Group::traverse(osg::NodeVisitor&)+120) 
#65 pc 3150568  (osg::NodeVisitor::traverse(osg::Node&)+100) 
#66 pc 3d6cb2c  (osgUtil::CullVisitor::handle_cull_callbacks_and_traverse(osg::Node&)+100) 
#67 pc 3d6db88  (osgUtil::CullVisitor::apply(osg::Group&)+112) 
#68 pc 317e448  (osg::Group::accept(osg::NodeVisitor&)+72) 
#69 pc 3b1ad74  (osg::Group::traverse(osg::NodeVisitor&)+120) 
#70 pc 3150568  (osg::NodeVisitor::traverse(osg::Node&)+100) 
#71 pc 3ef2400  (osgUtil::SceneView::cullStage(osg::Matrixd const&, osg::Matrixd const&, osgUtil::CullVisitor*, osgUtil::StateGraph*, osgUtil::RenderStage*, osg::Viewport*)+2656) 
#72 pc 3ef13ec  (osgUtil::SceneView::cull()+3360) 
#73 pc 3ee8874  (osgViewer::Renderer::cull_draw()+728) 
#74 pc 3ee9018  (osgViewer::Renderer::operator()(osg::GraphicsContext*)+52) 
#75 pc 3b0bc2c  (osg::GraphicsContext::runOperations()+328) 
#76 pc 3f457d4  (osgViewer::ViewerBase::renderingTraversals()+4272) 
#77 pc 3f44710  (osgViewer::ViewerBase::frame(double)+196) 
#78 pc 3135e58  (DemoScene::frame()+44) 
#79 pc 3142904  (OsgMainApp::draw()+28) 
#80 pc 3145258  (Java_com_oearth_androioearth01_osgNativeLib_step+28) 
#88 pc 0001864  [anon:dalvik-classes3.dex extracted in memory from base.apk!classes3.dex] (com.oearth.androioearth01.EGLview$Renderer.onDrawFrame)
```

## 3.4 callstack 4

```sh
2025-11-04 18:39:25.071 11053-11204 AndroiOearth01          com.oearth.androioearth01            D  
2025-11-04 18:39:25.071 11053-11204 AndroiOearth01          com.oearth.androioearth01            I  Warning: detected OpenGL error 'invalid enumerant' at after RenderBin::draw(..)
2025-11-04 18:39:25.071 11053-11204 AndroiOearth01          com.oearth.androioearth01            I  
2025-11-04 18:39:25.071 11053-11204 AndroiOearth01          com.oearth.androioearth01            D  end cull_draw() 0xb400007ea4411840
2025-11-04 18:39:25.072 11053-11204 AndroiOearth01          com.oearth.androioearth01            D  cull_draw() 0xb400007ea4411840
2025-11-04 18:39:25.073 11053-11204 AndroiOearth01          com.oearth.androioearth01            D  
2025-11-04 18:39:25.073 11053-11204 AndroiOearth01          com.oearth.androioearth01            V  Uniform Adding parent
2025-11-04 18:39:25.073 11053-11204 AndroiOearth01          com.oearth.androioearth01            V  
2025-11-04 18:39:25.073 11053-11204 AndroiOearth01          com.oearth.androioearth01            I  CullSettings::readEnvironmentalVariables()
2025-11-04 18:39:25.078 11053-11053 androioearth01          com.oearth.androioearth01            I  rotationDegreesDelta=0.5968991826172948;zoomDelta=0.006879463185144319
2025-11-04 18:39:25.080 11053-11204 AndroiOearth01          com.oearth.androioearth01            I  
2025-11-04 18:39:25.080 11053-11204 AndroiOearth01          com.oearth.androioearth01            I  Warning: PointSprite::apply(State&) - not supported.
2025-11-04 18:39:25.080 11053-11204 AndroiOearth01          com.oearth.androioearth01            I  
2025-11-04 18:39:25.080 11053-11204 AndroiOearth01          com.oearth.androioearth01            D  State::convertShaderSourceToOsgBuiltIns()
2025-11-04 18:39:25.080 11053-11204 AndroiOearth01          com.oearth.androioearth01            D  ++Before Converted source 
2025-11-04 18:39:25.080 11053-11204 AndroiOearth01          com.oearth.androioearth01            D  
2025-11-04 18:39:25.080 11053-11204 AndroiOearth01          com.oearth.androioearth01            D  ++++++++
2025-11-04 18:39:25.081 11053-11204 AndroiOearth01          com.oearth.androioearth01            D  -------- Converted source 
2025-11-04 18:39:25.081 11053-11204 AndroiOearth01          com.oearth.androioearth01            D  
2025-11-04 18:39:25.081 11053-11204 AndroiOearth01          com.oearth.androioearth01            D  ----------------
--------- beginning of crash
Fatal signal 11 (SIGSEGV), code 1 (SEGV_MAPERR), fault addr 0x218 in tid 11204 (GLThread 4428), pid 11053 (.androioearth01)
pid: 11053, tid: 11204, name: GLThread 4428  >>> com.oearth.androioearth01 <<<

#00 34f6388  (osg::Drawable::drawInner(osg::RenderInfo&) const+92) 
#01 34eaf44  (osg::Drawable::draw(osg::RenderInfo&) const+372) 
#02 39c4958  (osgEarth::REX::DrawTileCommand::draw(osg::RenderInfo&) const+816) 
#03 39d7a5c  (osgEarth::REX::LayerDrawableGL3::drawImplementation(osg::RenderInfo&) const+836) 
#04 34f638c  (osg::Drawable::drawInner(osg::RenderInfo&) const+96) 
#05 34eaf44  (osg::Drawable::draw(osg::RenderInfo&) const+372) 
#06 3e70078  (osgUtil::RenderLeaf::render(osg::RenderInfo&, osgUtil::RenderLeaf*)+352) 
#07 3e5d1f0  (osgUtil::RenderBin::drawImplementation(osg::RenderInfo&, osgUtil::RenderLeaf*&)+724) 
#08 3e774f8  (osgUtil::RenderStage::drawImplementation(osg::RenderInfo&, osgUtil::RenderLeaf*&)+788) 
#09 3e5ce44  (osgUtil::RenderBin::draw(osg::RenderInfo&, osgUtil::RenderLeaf*&)+120) 
#10 3e753f4  (osgUtil::RenderStage::drawInner(osg::RenderInfo&, osgUtil::RenderLeaf*&, bool&)+304) 
#11 3e766d4  (osgUtil::RenderStage::draw(osg::RenderInfo&, osgUtil::RenderLeaf*&)+1396) 
#12 3ef4608  (osgUtil::SceneView::draw()+5152) 
#13 3ee8c8c  (osgViewer::Renderer::cull_draw()+1184) 
#14 3ee9268  (osgViewer::Renderer::operator()(osg::GraphicsContext*)+52) 
#15 3b0be1c  (osg::GraphicsContext::runOperations()+328) 
#16 3f45a24  (osgViewer::ViewerBase::renderingTraversals()+4272) 
#17 3f44960  (osgViewer::ViewerBase::frame(double)+196) 
#18 3135ed8  (DemoScene::frame()+44) 
#19 3142984  (OsgMainApp::draw()+28) 
#20 3145378  (Java_com_oearth_androioearth01_osgNativeLib_step+28) 
#28 000162c [anon:dalvik-classes3.dex extracted in memory from /data/app/~~ObHIo7I0jK108PaI1qQcQQ==/com.oearth.androioearth01-KFrSv7-13E4-oEETUYo-VA==/base.apk!classes3.dex] (com.oearth.androioearth01.EGLview$Renderer.onDrawFrame)

2025-11-04 18:39:26.010 11053-11053 ratelimit               com.oearth.androioearth01            W  Single process limit 250/s drop 1378 lines.
2025-11-04 18:39:26.010 11053-11053 androioearth01          com.oearth.androioearth01            I  rotationDegreesDelta=0.4389229126597818;zoomDelta=-0.0044404099917078055
2025-11-04 18:39:26.015 11053-11236 AndroiOearth01          com.oearth.androioearth01            I  get_orientation()
2025-11-04 18:39:26.015 11053-11236 AndroiOearth01          com.oearth.androioearth01            I  exif_marker not found 
2025-11-04 18:39:26.022 11053-11239 AndroiOearth01          com.oearth.androioearth01            I  get_orientation()
2025-11-04 18:39:26.022 11053-11239 AndroiOearth01          com.oearth.androioearth01            I  exif_marker not found 
```

#  4. callstack 5

```sh
2025-11-07 21:40:38.070  8026-8196  AndroiOearth01          com.oearth.androioearth01            D  BufferObject::releaseGLObjects(0x0)
2025-11-07 21:40:38.070  8026-8196  AndroiOearth01          com.oearth.androioearth01            D  cull_draw() 0xb400007ea4411340
2025-11-07 21:40:38.071  8026-8196  AndroiOearth01          com.oearth.androioearth01            D  
2025-11-07 21:40:38.071  8026-8196  AndroiOearth01          com.oearth.androioearth01            V  Uniform Adding parent
2025-11-07 21:40:38.071  8026-8196  AndroiOearth01          com.oearth.androioearth01            V  
2025-11-07 21:40:38.071  8026-8196  AndroiOearth01          com.oearth.androioearth01            I  CullSettings::readEnvironmentalVariables()
2025-11-07 21:40:38.074  8026-8196  AndroiOearth01          com.oearth.androioearth01            I  _parent->getCurrGLBufferObjectPoolSize()=880856 _parent->getMaxGLBufferObjectPoolSize()=0
2025-11-07 21:40:38.074  8026-8196  AndroiOearth01          com.oearth.androioearth01            I  Looking to reclaim 880856, going to look to remove 51 from 2 orphans
2025-11-07 21:40:38.074  8026-8196  AndroiOearth01          com.oearth.androioearth01            I  
2025-11-07 21:40:38.074  8026-8196  AndroiOearth01          com.oearth.androioearth01            D  GLBufferObject::deleteGLObject() 70
2025-11-07 21:40:38.074  8026-8196  AndroiOearth01          com.oearth.androioearth01            D  GLBufferObject::deleteGLObject() 71
2025-11-07 21:40:38.074  8026-8196  AndroiOearth01          com.oearth.androioearth01            D  
2025-11-07 21:40:38.074  8026-8196  AndroiOearth01          com.oearth.androioearth01            I  _parent->getCurrTexturePoolSize()=8388128 _parent->getMaxTexturePoolSize()=0
2025-11-07 21:40:38.074  8026-8196  AndroiOearth01          com.oearth.androioearth01            I  Looking to reclaim 8388128, going to look to remove 33 from 4 orphans
2025-11-07 21:40:38.075  8026-8196  AndroiOearth01          com.oearth.androioearth01            I  
2025-11-07 21:40:38.075  8026-8196  AndroiOearth01          com.oearth.androioearth01            I  Warning: PointSprite::apply(State&) - not supported.
2025-11-07 21:40:38.076  8026-8196  AndroiOearth01          com.oearth.androioearth01            I  
2025-11-07 21:40:38.076  8026-8196  AndroiOearth01          com.oearth.androioearth01            D  State::convertShaderSourceToOsgBuiltIns()
2025-11-07 21:40:38.076  8026-8196  AndroiOearth01          com.oearth.androioearth01            D  ++Before Converted source 
2025-11-07 21:40:38.568  8026-8479  libc                    com.oearth.androioearth01            A  Fatal signal 11 (SIGSEGV), code 1 (SEGV_MAPERR), fault addr 0x10 in tid 8479 (GLThread 13993), pid 8026 (.androioearth01)
2025-11-07 21:40:38.673  9295-9295  DEBUG  pid-9295   A  pid: 8026, tid: 8479, name: GLThread 13993  >>> com.oearth.androioearth01 <<<
#00 pc 0000000003b84f2c   (offset 0x748000) (osg::Referenced::signalObserversAndDelete(bool, bool) const+244)
#01 pc 000000000312cb20   (offset 0x748000) (osg::Referenced::unref() const+80)
#02 pc 0000000003997ad0   (offset 0x748000) (osg::ref_ptr<osgEarth::REX::SharedGeometry>::~ref_ptr()+44)
#03 pc 00000000039e6b28   (offset 0x748000) (osgEarth::REX::TileNode::createGeometry(jobs::cancelable*)+992)
#04 pc 00000000039e5fd0   (offset 0x748000) (osgEarth::REX::TileNode::TileNode(osgEarth::TileKey const&, osgEarth::REX::TileNode*, osgEarth::REX::EngineContext*, jobs::cancelable*)+732)
#05 pc 00000000039eae8c   (offset 0x748000) (osgEarth::REX::TileNode::createChild(osgEarth::TileKey const&, jobs::cancelable*)+112)
#06 pc 00000000039f8890   (offset 0x748000)
#07 pc 00000000039f8654   (offset 0x748000)
#08 pc 00000000039f85cc   (offset 0x748000)
#09 pc 00000000039f8580   (offset 0x748000)
#10 pc 00000000039f8558   (offset 0x748000)
#11 pc 00000000039f7570   (offset 0x748000)
#12 pc 000000000336fa88   (offset 0x748000)
#13 pc 000000000336e664   (offset 0x748000)
#14 pc 000000000336de58   (offset 0x748000) (jobs::jobpool::run()+564)
#15 pc 000000000336db94   (offset 0x748000) (jobs::jobpool::start_threads()::'lambda'()::operator()() const+92)
#16 pc 000000000336db00   (offset 0x748000)
#17 pc 000000000336da9c   (offset 0x748000)
#18 pc 000000000336d594   (offset 0x748000)
---------------------------- PROCESS STARTED (9297) for package com.oearth.androioearth01 ----------------------------
2025-11-07 21:40:39.224  8026-8236  ratelimit               com.oearth.androioearth01            W  Single process limit 250/s drop 1817 lines.
2025-11-07 21:40:39.224  8026-8236  AndroiOearth01          com.oearth.androioearth01            I  get_orientation()
2025-11-07 21:40:39.224  8026-8236  AndroiOearth01          com.oearth.androioearth01            I  exif_marker not found 
2025-11-07 21:40:39.257  8026-8233  AndroiOearth01          com.oearth.androioearth01            I  get_orientation()
2025-11-07 21:40:39.257  8026-8233  AndroiOearth01          com.oearth.androioearth01            I  exif_marker not found 
---------------------------- PROCESS ENDED (8026) for package com.oearth.androioearth01 ----------------------------
```
这是一个典型的 **Native 崩溃（NDK 崩溃）**，发生在 **osgEarth** 3D 地图引擎中。让我详细分析这个错误：

## 🚨 错误分析

### 崩溃基本信息
```
Fatal signal 11 (SIGSEGV), code 1 (SEGV_MAPERR), fault addr 0x10
```
- **信号**：SIGSEGV（段错误）
- **错误码**：SEGV_MAPERR（内存映射错误）
- **故障地址**：0x10（空指针偏移）

### 崩溃调用栈解读
```
#00 osg::Referenced::signalObserversAndDelete()  # 对象删除时通知观察者
#01 osg::Referenced::unref()                     # 引用计数减1
#02 osg::ref_ptr<...>::~ref_ptr()               # 智能指针析构
#03 osgEarth::REX::TileNode::createGeometry()   # 创建几何体
#04 osgEarth::REX::TileNode::TileNode()         # 瓦片节点构造函数
#05 osgEarth::REX::TileNode::createChild()       # 创建子瓦片
```

## 🔍 根本原因分析

### 问题定位：**空指针解引用**
故障地址 `0x10` 表明程序试图访问 `nullptr + 0x10` 的内存地址。这通常发生在：

```cpp
// 类似这样的代码出现了问题
SomeClass* obj = nullptr;
obj->someMemberFunction();  // 访问 nullptr->vtable 或成员变量
```

### 具体场景分析
在 osgEarth 的瓦片渲染系统中：
1. **创建地形瓦片几何体**时出现内存管理问题
2. **引用计数机制**在对象删除过程中访问了已释放的内存
3. **多线程环境**下可能出现了竞态条件

## 🛠️ 解决方案

### 方案1：检查内存管理代码
```cpp
// 错误的示例：可能造成悬空指针
osg::ref_ptr<osgEarth::REX::SharedGeometry> geometry = getSharedGeometry();
// ... 其他操作中 geometry 可能被意外释放

// 正确的做法：确保引用有效性
osg::ref_ptr<osgEarth::REX::SharedGeometry> geometry = getSharedGeometry();
if (!geometry) {
    // 处理空指针情况
    return;
}
// 使用 geometry...
```

### 方案2：检查多线程同步
```cpp
class TileNode {
private:
    std::mutex geometryMutex_;
    osg::ref_ptr<SharedGeometry> sharedGeometry_;
    
public:
    osg::ref_ptr<SharedGeometry> getSharedGeometry() {
        std::lock_guard<std::mutex> lock(geometryMutex_);
        return sharedGeometry_;
    }
    
    void setSharedGeometry(osg::ref_ptr<SharedGeometry> geometry) {
        std::lock_guard<std::mutex> lock(geometryMutex_);
        sharedGeometry_ = geometry;
    }
};
```

### 方案3：更新 osgEarth 版本
如果使用的是旧版本，可能存在已知的bug：

```gradle
// build.gradle
dependencies {
    // 检查并更新到最新稳定版
    implementation 'org.osgeo:osgearth:3.1.0'  // 或更新版本
}
```

### 方案4：添加崩溃防护
```cpp
// 在可能崩溃的地方添加异常捕获
try {
    tileNode->createChild(tileKey, cancelable);
} catch (const std::exception& e) {
    LOG_ERROR("Tile creation failed: %s", e.what());
    // 优雅降级处理
    return nullptr;
}
```

## 📱 Android 端的特定处理

### 检查 JNI 交互
```java
public class OsgEarthView extends GLSurfaceView {
    private long nativePtr;  // Native 对象指针
    
    @Override
    protected void finalize() throws Throwable {
        // 确保在销毁时正确清理 Native 资源
        if (nativePtr != 0) {
            nativeDestroy(nativePtr);
            nativePtr = 0;
        }
        super.finalize();
    }
    
    private static native void nativeDestroy(long ptr);
}
```

### 内存泄漏检测
在 `app/build.gradle` 中启用内存检测：
```gradle
android {
    buildTypes {
        debug {
            debuggable true
            jniDebuggable true
            packagingOptions {
                doNotStrip '**/*.so'  // 保留调试符号
            }
        }
    }
}
```

## 🔧 调试步骤

### 1. 启用详细日志
```cpp
// 在 Native 代码中添加调试日志
#define LOG_TAG "OsgEarth"
#define ALOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

void createGeometry() {
    ALOGE("Creating geometry for tile...");
    // ... 具体实现
    ALOGE("Geometry creation completed");
}
```

### 2. 使用 AddressSanitizer
在 `CMakeLists.txt` 中：
```cmake
if(ANDROID_NDK)
    target_compile_options(native-lib PRIVATE -fsanitize=address)
    target_link_options(native-lib PRIVATE -fsanitize=address)
endif()
```

### 3. 检查堆栈跟踪的完整上下文
需要更完整的堆栈跟踪来定位问题：
```bash
# 使用 addr2line 定位具体代码行
$ ndk-stack -sym /path/to/symbols < crash_log.txt
```

## 🎯 立即行动方案

1. **检查最近代码变更**：是否修改了地图相关的代码
2. **简化重现步骤**：尝试在最小化场景下重现问题
3. **添加防护代码**：在可疑的地方添加空指针检查
4. **更新依赖库**：确保使用最新稳定版本的 osgEarth

这个崩溃通常与**内存管理**和**多线程同步**相关，建议从这两个方向入手排查。



======================================================================
# 5. 启用了ASAN的osgEarth linux app在关闭时发生了段错误（SEGV）
运行 基于ASAN的osgearth app "platform/lnx8sky"后，在app关闭时出错
```sh
==2184645==ERROR: AddressSanitizer: SEGV on unknown address 0x000000000068 (pc 0x597be205d055 bp 0x77577b00a5f0 sp 0x77577b00a5e0 T6)
==2184645==The signal is caused by a READ memory access.
==2184645==Hint: address points to the zero page.
og...include/osg/Referenced(02): _refCount=7
AddressSanitizer:DEADLYSIGNAL 
AddressSanitizer:DEADLYSIGNAL

    #0 0x597be205d055 in osg::DisplaySettings::getMaxNumberOfGraphicsContexts() const /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/DisplaySettings.cpp:284
    #1 0x597be233fc97 in osg::buffered_object<osg::ref_ptr<osg::Texture::TextureObject> >::buffered_object() /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/buffered_value:89
    #2 0x597be2331d85 in osg::Texture::Texture() /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Texture.cpp:1344
    #3 0x597be231cf62 in osg::Texture2D::Texture2D(osg::Image*) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Texture2D.cpp:33
    #4 0x597be0cf686e in createTexture2D /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/TerrainTileModelFactory.cpp:660
    #5 0x597be0cf6ce2 in osgEarth::TerrainTileModelFactory::createImageTexture(osg::Image const*, osgEarth::ImageLayer const*) const /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/TerrainTileModelFactory.cpp:709
    #6 0x597be0cf1b84 in osgEarth::TerrainTileModelFactory::addImageLayer(osgEarth::TerrainTileModel*, osgEarth::ImageLayer*, osgEarth::TileKey const&, osgEarth::Util::TerrainEngineRequirements const&, osgEarth::ProgressCallback*) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/TerrainTileModelFactory.cpp:259
    #7 0x597be0cf3464 in osgEarth::TerrainTileModelFactory::addColorLayers(osgEarth::TerrainTileModel*, osgEarth::Map const*, osgEarth::Util::TerrainEngineRequirements const&, osgEarth::TileKey const&, osgEarth::CreateTileManifest const&, osgEarth::ProgressCallback*, bool) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/TerrainTileModelFactory.cpp:387
    #8 0x597be0cf0842 in osgEarth::TerrainTileModelFactory::createTileModel(osgEarth::Map const*, osgEarth::TileKey const&, osgEarth::CreateTileManifest const&, osgEarth::Util::TerrainEngineRequirements const&, osgEarth::ProgressCallback*) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/TerrainTileModelFactory.cpp:147
    #9 0x597be0cc0322 in osgEarth::TerrainEngineNode::createTileModel(osgEarth::Map const*, osgEarth::TileKey const&, osgEarth::CreateTileManifest const&, osgEarth::ProgressCallback*) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/TerrainEngineNode.cpp:229
    #10 0x597be03919c9 in operator() /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/LoadTileData.cpp:84
    #11 0x597be039336f in operator() /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/weejobs.h:814
    #12 0x597be0394607 in __invoke_impl<bool, jobs::dispatch<osgEarth::REX::LoadTileDataOperation::dispatch(bool)::<lambda(osgEarth::Cancelable&)> >(osgEarth::REX::LoadTileDataOperation::dispatch(bool)::<lambda(osgEarth::Cancelable&)>, const context&)::<lambda()>&> /usr/include/c++/13/bits/invoke.h:61
    #13 0x597be03943df in __invoke_r<bool, jobs::dispatch<osgEarth::REX::LoadTileDataOperation::dispatch(bool)::<lambda(osgEarth::Cancelable&)> >(osgEarth::REX::LoadTileDataOperation::dispatch(bool)::<lambda(osgEarth::Cancelable&)>, const context&)::<lambda()>&> /usr/include/c++/13/bits/invoke.h:114
    #14 0x597be0393dfd in _M_invoke /usr/include/c++/13/bits/std_function.h:290
    #15 0x597be0258f6d in std::function<bool ()>::operator()() const /usr/include/c++/13/bits/std_function.h:591
    #16 0x597be0252c39 in jobs::jobpool::run() /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/weejobs.h:956
    #17 0x597be0253127 in jobs::jobpool::start_threads()::{lambda()#1}::operator()() const /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/weejobs.h:1001
    #18 0x597be026f00f in void std::__invoke_impl<void, jobs::jobpool::start_threads()::{lambda()#1}>(std::__invoke_other, jobs::jobpool::start_threads()::{lambda()#1}&&) /usr/include/c++/13/bits/invoke.h:61
    #19 0x597be026efca in std::__invoke_result<jobs::jobpool::start_threads()::{lambda()#1}>::type std::__invoke<jobs::jobpool::start_threads()::{lambda()#1}>(jobs::jobpool::start_threads()::{lambda()#1}&&) /usr/include/c++/13/bits/invoke.h:96
    #20 0x597be026ef6b in void std::thread::_Invoker<std::tuple<jobs::jobpool::start_threads()::{lambda()#1}> >::_M_invoke<0ul>(std::_Index_tuple<0ul>) /usr/include/c++/13/bits/std_thread.h:292
    #21 0x597be026ef3b in std::thread::_Invoker<std::tuple<jobs::jobpool::start_threads()::{lambda()#1}> >::operator()() /usr/include/c++/13/bits/std_thread.h:299
    #22 0x597be026eebf in std::thread::_State_impl<std::thread::_Invoker<std::tuple<jobs::jobpool::start_threads()::{lambda()#1}> > >::_M_run() /usr/include/c++/13/bits/std_thread.h:244
    #23 0x77579b2ecdb3  (/lib/x86_64-linux-gnu/libstdc++.so.6+0xecdb3) (BuildId: ca77dae775ec87540acd7218fa990c40d1c94ab1)
    #24 0x77579b65ea41 in asan_thread_start ../../../../src/libsanitizer/asan/asan_interceptors.cpp:234
    #25 0x77579ac9caa3 in start_thread nptl/pthread_create.c:447
    #26 0x77579ad29c6b in clone3 ../sysdeps/unix/sysv/linux/x86_64/clone3.S:78

AddressSanitizer can not provide additional info.
SUMMARY: AddressSanitizer: SEGV /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/DisplaySettings.cpp:284 in osg::DisplaySettings::getMaxNumberOfGraphicsContexts() const
Thread T6 created by T0 here:
    #0 0x77579b6f51f9 in pthread_create ../../../../src/libsanitizer/asan/asan_interceptors.cpp:245
    #1 0x77579b2eceb0 in std::thread::_M_start_thread(std::unique_ptr<std::thread::_State, std::default_delete<std::thread::_State> >, void (*)()) (/lib/x86_64-linux-gnu/libstdc++.so.6+0xeceb0) (BuildId: ca77dae775ec87540acd7218fa990c40d1c94ab1)
    #2 0x597be025af9f in std::thread::thread<jobs::jobpool::start_threads()::{lambda()#1}, , void>(jobs::jobpool::start_threads()::{lambda()#1}&&) (/mnt/disk2/abner/zdev/nv/osgearth0x/build_by_sh/build/ubuntu/platform/lnx8sky/Lnx8SkyDemo+0x1a8bf9f) (BuildId: 8ea7cac884c28e8ced2ed9aa1c8a252d6a2e0a1a)
    #3 0x597be02532ac in jobs::jobpool::start_threads() /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/weejobs.h:995
    #4 0x597be0251ca7 in jobs::get_pool(std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > const&, unsigned int) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/weejobs.h:760
    #5 0x597be0326134 in osgEarth::REX::Merger::Merger() /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/Loader.cpp:30
    #6 0x597be0274bb7 in osgEarth::REX::RexTerrainEngineNode::onSetMap() /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/RexTerrainEngineNode.cpp:281
    #7 0x597be0cbfa91 in osgEarth::TerrainEngineNode::setMap(osgEarth::Map const*, osgEarth::TerrainOptions const&) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/TerrainEngineNode.cpp:181
    #8 0x597be0a2997a in osgEarth::MapNode::open() /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/MapNode.cpp:326
    #9 0x597be0a2f189 in osgEarth::MapNode::traverse(osg::NodeVisitor&) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/MapNode.cpp:830
    #10 0x597be0286b71 in osg::NodeVisitor::traverse(osg::Node&) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/NodeVisitor:277
    #11 0x597be1fb375b in osgUtil::UpdateVisitor::handle_callbacks_and_traverse(osg::Node&) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osgUtil/UpdateVisitor:111
    #12 0x597be1fb3502 in osgUtil::UpdateVisitor::apply(osg::Group&) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osgUtil/UpdateVisitor:81
    #13 0x597be02f5d94 in osg::Group::accept(osg::NodeVisitor&) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/Group:38
    #14 0x597be1994fde in osgViewer::Scene::updateSceneGraph(osg::NodeVisitor&) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgViewer/Scene.cpp:149
    #15 0x597be18d6fc3 in osgViewer::Viewer::updateTraversal() /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgViewer/Viewer.cpp:1152
    #16 0x597be190217c in osgViewer::ViewerBase::frame(double) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgViewer/ViewerBase.cpp:747
    #17 0x597be1901be3 in osgViewer::ViewerBase::run() /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgViewer/ViewerBase.cpp:703
    #18 0x597be18cea6d in osgViewer::Viewer::run() /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgViewer/Viewer.cpp:445
    #19 0x597be0a466a0 in osgEarth::Util::Metrics::run(osgViewer::ViewerBase&) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/Metrics.cpp:156
    #20 0x597be0219d39 in main /home/abner/abner2/zdev/nv/osgearth0x/platform/lnx8sky/demo_simple_sky.cpp:84
    #21 0x77579ac2a1c9 in __libc_start_call_main ../sysdeps/nptl/libc_start_call_main.h:58
    #22 0x77579ac2a28a in __libc_start_main_impl ../csu/libc-start.c:360
    #23 0x597be0218d64 in _start (/mnt/disk2/abner/zdev/nv/osgearth0x/build_by_sh/build/ubuntu/platform/lnx8sky/Lnx8SkyDemo+0x1a49d64) (BuildId: 8ea7cac884c28e8ced2ed9aa1c8a252d6a2e0a1a)

==2184645==ABORTING
```

这个错误表明你的 osgEarth 应用程序在关闭时发生了段错误（SEGV），具体是在尝试读取 `osg::DisplaySettings::getMaxNumberOfGraphicsContexts()` 时访问了无效的内存地址（0x000000000068）。这通常是由于对象已被销毁但仍然被访问导致的。

### 问题分析

1. **错误位置**：
   - 崩溃发生在 `osg::DisplaySettings::getMaxNumberOfGraphicsContexts()`，位于 `DisplaySettings.cpp:284`
   - 调用栈显示这是在纹理对象（`osg::Texture`）的析构过程中发生的

2. **可能原因**：
   - **线程安全问题**：工作线程（T6）在应用程序关闭时仍在运行，尝试访问已被销毁的 `DisplaySettings` 对象
   - **对象生命周期问题**：`DisplaySettings` 对象被提前销毁，但某些资源（如纹理）仍在引用它
   - **OSG/OSGEarth 的析构顺序问题**：关闭时的资源清理顺序不正确

---

### 解决方案

#### 1. **确保正确关闭线程池**
osgEarth 使用了工作线程（如 `jobs::jobpool`），在关闭时需要确保所有线程任务已完成。

**修改你的关闭逻辑**：
```cpp
// 在关闭 viewer 前，停止所有工作线程
osgEarth::JobArena::setConcurrency(0); // 停止所有线程池
```

或更彻底的方式：
```cpp
// 在 main() 退出前，确保所有资源释放完毕
viewer->setDone(true);
while (!viewer->done()) {
    viewer->frame();
}
```

---

#### 2. **检查 DisplaySettings 的生命周期**
确保全局的 `DisplaySettings` 对象在程序退出前不被销毁。

**检查是否有代码修改了全局 DisplaySettings**：
```cpp
osg::DisplaySettings* ds = osg::DisplaySettings::instance().get();
// 确保这个对象在整个程序生命周期内有效
```

---

#### 3. **修复 OSG/OSGEarth 的资源释放顺序**
在关闭时，确保正确的资源释放顺序：
1. 停止所有渲染和更新
2. 停止工作线程
3. 释放场景图（`Viewer::setSceneData(nullptr)`）
4. 释放 `Viewer` 本身

**示例代码**：
```cpp
viewer->setDone(true);
viewer->stopThreading(); // 停止渲染线程

// 确保所有工作线程完成
osgEarth::JobArena::setConcurrency(0);

// 清除场景数据
viewer->setSceneData(nullptr);

// 确保所有资源释放
while (!viewer->done()) {
    viewer->frame();
}
```

---

#### 4. **检查自定义的析构逻辑**
如果你在代码中手动管理了某些资源（如纹理、线程池等），确保它们在 `Viewer` 销毁前被正确释放。

---

#### 5. **尝试禁用 ASAN 的某些检查**
如果问题仅在 ASAN 下出现，可能是 ASAN 对析构顺序更敏感。可以尝试调整 ASAN 选项：
```bash
export ASAN_OPTIONS="detect_leaks=0:halt_on_error=0"
./your_application
```

---

#### 6. **升级 OSG/OSGEarth**
如果这是已知问题，可能在新版本中已修复。尝试升级到最新版本：
```bash
git pull origin master  # 更新 osgEarth
```

---

### 调试建议
1. **在崩溃点检查对象状态**：
   ```cpp
   // 在 osg::DisplaySettings::getMaxNumberOfGraphicsContexts() 添加调试代码
   if (!this) {
       std::cerr << "DisplaySettings object is null!" << std::endl;
       return 0;
   }
   ```

2. **捕获更多 ASAN 信息**：
   ```bash
   export ASAN_OPTIONS="verbosity=2:log_path=asan.log"
   ./your_application
   ```

3. **使用 GDB 调试**：
   ```bash
   gdb --args ./your_application
   (gdb) run
   ```

---

### 总结
这个问题很可能是由于工作线程在程序关闭时仍在访问已销毁的资源导致的。重点检查：
1. 线程池的正确关闭
2. `DisplaySettings` 对象的生命周期
3. OSG/OSGEarth 的资源释放顺序

如果问题仍然存在，建议在 osgEarth 的 GitHub 仓库提交 issue，并提供完整的复现步骤和调用栈。

===========================================================
# 6.启用了asan的ndk 程序

```sh
2025-11-10 21:06:30.072 24430-24430 chatty                  logwrapper                           I  uid=10437(com.oearth.androioearth01) /system/bin/logwrapper identical 30 lines
2025-11-10 21:06:30.127 24430-24430 wrap.sh                 logwrapper                           I      #0 0x724b3397a0  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x55da7a0) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.127 24430-24430 wrap.sh                 logwrapper                           I      #1 0x724b84835c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5ae935c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.127 24430-24430 wrap.sh                 logwrapper                           I      #2 0x724b847954  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5ae8954) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.127 24430-24430 wrap.sh                 logwrapper                           I      #3 0x724b84d468  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5aee468) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.127 24430-24430 wrap.sh                 logwrapper                           I      #4 0x724b84c32c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5aed32c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.127 24430-24430 wrap.sh                 logwrapper                           I      #5 0x724b84eaf0  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5aefaf0) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.127 24430-24430 wrap.sh                 logwrapper                           I      #6 0x7249ef20c8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x41930c8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.127 24430-24430 wrap.sh                 logwrapper                           I      #7 0x724b7ba7b8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5a5b7b8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.127 24430-24430 wrap.sh                 logwrapper                           I      #8 0x724bc75408  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5f16408) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.127 24430-24430 wrap.sh                 logwrapper                           I      #9 0x7249f72b7c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4213b7c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.127 24430-24430 wrap.sh                 logwrapper                           I      #10 0x724b84c4a4  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5aed4a4) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.127 24430-24430 wrap.sh                 logwrapper                           I      #11 0x724b84eaf0  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5aefaf0) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.127 24430-24430 wrap.sh                 logwrapper                           I      #12 0x7249ef20c8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x41930c8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.127 24430-24430 wrap.sh                 logwrapper                           I      #13 0x724b7ba7b8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5a5b7b8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.127 24430-24430 wrap.sh                 logwrapper                           I      #14 0x724bc75408  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5f16408) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.127 24430-24430 wrap.sh                 logwrapper                           I      #15 0x7249f72b7c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4213b7c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.127 24430-24430 wrap.sh                 logwrapper                           I      #16 0x724b84c4a4  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5aed4a4) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.127 24430-24430 wrap.sh                 logwrapper                           I      #17 0x724b84eaf0  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5aefaf0) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.127 24430-24430 wrap.sh                 logwrapper                           I      #18 0x7249ef20c8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x41930c8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.127 24430-24430 wrap.sh                 logwrapper                           I      #19 0x724b7ba7b8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5a5b7b8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.127 24430-24430 wrap.sh                 logwrapper                           I      #20 0x724bc75408  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5f16408) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.127 24430-24430 wrap.sh                 logwrapper                           I      #21 0x7249f72b7c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4213b7c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.127 24430-24430 wrap.sh                 logwrapper                           I      #22 0x724bbb8254  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5e59254) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.127 24430-24430 wrap.sh                 logwrapper                           I      #23 0x7249ef20c8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x41930c8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.127 24430-24430 wrap.sh                 logwrapper                           I      #24 0x724b7ba7b8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5a5b7b8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.127 24430-24430 wrap.sh                 logwrapper                           I      #25 0x724bc75408  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5f16408) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.127 24430-24430 wrap.sh                 logwrapper                           I      #26 0x7249f72b7c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4213b7c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.127 24430-24430 wrap.sh                 logwrapper                           I      #27 0x724b6e10e0  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x59820e0) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.127 24430-24430 wrap.sh                 logwrapper                           I      #28 0x724b6e64c0  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x59874c0) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #29 0x7249ef20c8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x41930c8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #30 0x724c27ef84  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x651ff84) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #31 0x724c281488  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x6522488) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #32 0x724bc755c4  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5f165c4) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #33 0x724b6eb9a8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x598c9a8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #34 0x724bbb8254  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5e59254) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #35 0x724abdfbb8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4e80bb8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #36 0x7249ef20c8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x41930c8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #37 0x724c27ef84  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x651ff84) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #38 0x724c281488  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x6522488) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #39 0x7249f72b7c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4213b7c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #40 0x724bbb8254  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5e59254) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #41 0x7249ef20c8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x41930c8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #42 0x724c27ef84  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x651ff84) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #43 0x724c281488  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x6522488) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #44 0x7249f72b7c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4213b7c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #45 0x724aa3e2cc  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4cdf2cc) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #46 0x7249ef20c8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x41930c8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #47 0x724ba3e718  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5cdf718) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #48 0x724aadadf8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4d7bdf8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #49 0x724ba3f3d4  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5ce03d4) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #50 0x724ba3e5c4  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5cdf5c4) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #51 0x7249f702bc  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x42112bc) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #52 0x724ba3f3d4  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5ce03d4) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #53 0x724c27ef74  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x651ff74) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #54 0x724c281488  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x6522488) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #55 0x7249f72b7c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4213b7c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #56 0x724bbb8254  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5e59254) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #57 0x724b8fae90  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5b9be90) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #58 0x724b92cd40  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5bcdd40) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #59 0x7249ef20c8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x41930c8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #60 0x724c27ef84  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x651ff84) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #61 0x724c281488  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x6522488) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #62 0x7249f72b7c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4213b7c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #63 0x724bbb8254  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5e59254) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #64 0x7249ef20c8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x41930c8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #65 0x724c27ef84  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x651ff84) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #66 0x724c281488  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x6522488) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #67 0x7249f72b7c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4213b7c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #68 0x724bbb8254  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5e59254) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #69 0x7249ef20c8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x41930c8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #70 0x724c786d6c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x6a27d6c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #71 0x724c785114  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x6a26114) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #72 0x724c7702e8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x6a112e8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #73 0x724c771390  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x6a12390) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #74 0x724bb858f4  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5e268f4) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #75 0x724c871884  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x6b12884) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #76 0x724c86ea40  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x6b0fa40) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #77 0x7249ea8c00  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4149c00) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #78 0x7249ecc368  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x416d368) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.128 24430-24430 wrap.sh                 logwrapper                           I      #79 0x7249ed19b8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x41729b8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.129 24430-24430 wrap.sh                 logwrapper                           I      #0 0x734aab6ba4  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libclang_rt.asan-aarch64-android.so+0xf2ba4) (BuildId: d2089f24857cf6bfee934a5c1e8395bab0e414b6)
2025-11-10 21:06:30.129 24430-24430 wrap.sh                 logwrapper                           I      #1 0x724ae36408  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x50d7408) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #2 0x724bd077c4  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5fa87c4) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #3 0x724bd078d0  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5fa88d0) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #4 0x7249e838f4  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x41248f4) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #5 0x7249e96b28  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4137b28) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #6 0x724a0e7cac  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4388cac) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #7 0x724a0e7c14  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4388c14) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #8 0x724a0e7b94  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4388b94) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #9 0x724a0e7924  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4388924) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #10 0x724a0e77d0  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x43887d0) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #11 0x724a0d8d2c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4379d2c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #12 0x724a8151a0  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4ab61a0) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #13 0x724a810740  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4ab1740) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #14 0x724a80e6e0  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4aaf6e0) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #15 0x724b1be414  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x545f414) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #16 0x724b1c1500  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5462500) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #17 0x724b1bcc04  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x545dc04) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #18 0x724b177b0c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5418b0c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #19 0x724b88e5f4  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5b2f5f4) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #20 0x724b8a1df8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5b42df8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #21 0x724b8a1c24  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5b42c24) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #22 0x724b8a1bd8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5b42bd8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #23 0x724b8a1bb0  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5b42bb0) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #24 0x724b89c39c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5b3d39c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #25 0x724a557834  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x47f8834) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #26 0x724a55328c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x47f428c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #27 0x724a551cd0  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x47f2cd0) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #28 0x724a551390  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x47f2390) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #29 0x724a5512d4  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x47f22d4) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #0 0x734aab62fc  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libclang_rt.asan-aarch64-android.so+0xf22fc) (BuildId: d2089f24857cf6bfee934a5c1e8395bab0e414b6)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #1 0x724ae2bf70  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x50ccf70) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #2 0x724ae2bd98  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x50ccd98) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #3 0x724ae2e640  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x50cf640) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #4 0x724ae2d5a8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x50ce5a8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #5 0x724b333f7c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x55d4f7c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #6 0x724a80b198  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4aac198) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #7 0x724b534244  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x57d5244) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #8 0x724a968878  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4c09878) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #9 0x724a9f8b18  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4c99b18) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #10 0x7249ea67b8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x41477b8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #11 0x7249ea5908  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4146908) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #12 0x7249ecbe18  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x416ce18) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.130 24430-24430 wrap.sh                 logwrapper                           I      #13 0x7249ed198c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x417298c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.131 24430-24430 wrap.sh                 logwrapper                           I  Thread T20 (GLThread 16) created by T0 (.androioearth01) here:
2025-11-10 21:06:30.163 24430-24430 wrap.sh                 logwrapper                           I      #0 0x734aa95d5c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libclang_rt.asan-aarch64-android.so+0xd1d5c) (BuildId: d2089f24857cf6bfee934a5c1e8395bab0e414b6)
2025-11-10 21:06:30.164 24430-24430 wrap.sh                 logwrapper                           I      #0 0x734aa95d5c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libclang_rt.asan-aarch64-android.so+0xd1d5c) (BuildId: d2089f24857cf6bfee934a5c1e8395bab0e414b6)
2025-11-10 21:06:30.164 24430-24430 wrap.sh                 logwrapper                           I      #1 0x724a54fbcc  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x47f0bcc) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.164 24430-24430 wrap.sh                 logwrapper                           I      #2 0x724a54ad44  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x47ebd44) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.164 24430-24430 wrap.sh                 logwrapper                           I      #3 0x724a538eec  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x47d9eec) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.164 24430-24430 wrap.sh                 logwrapper                           I      #4 0x724a52b31c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x47cc31c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.164 24430-24430 wrap.sh                 logwrapper                           I      #5 0x724b8d895c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5b7995c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.164 24430-24430 wrap.sh                 logwrapper                           I      #6 0x724b6d7c88  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5978c88) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.164 24430-24430 wrap.sh                 logwrapper                           I      #7 0x724b176f6c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5417f6c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.164 24430-24430 wrap.sh                 logwrapper                           I      #8 0x724aa34b14  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4cd5b14) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.164 24430-24430 wrap.sh                 logwrapper                           I      #9 0x724aa3d724  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4cde724) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.164 24430-24430 wrap.sh                 logwrapper                           I      #10 0x7249ef20c8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x41930c8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.164 24430-24430 wrap.sh                 logwrapper                           I      #11 0x724c7990dc  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x6a3a0dc) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.164 24430-24430 wrap.sh                 logwrapper                           I      #12 0x724c798d1c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x6a39d1c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.164 24430-24430 wrap.sh                 logwrapper                           I      #13 0x7249f72b7c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4213b7c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.164 24430-24430 wrap.sh                 logwrapper                           I      #14 0x724bbb8254  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5e59254) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.164 24430-24430 wrap.sh                 logwrapper                           I      #15 0x7249ef20c8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x41930c8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.164 24430-24430 wrap.sh                 logwrapper                           I      #16 0x724c7990dc  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x6a3a0dc) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.164 24430-24430 wrap.sh                 logwrapper                           I      #17 0x724c798d1c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x6a39d1c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.164 24430-24430 wrap.sh                 logwrapper                           I      #18 0x7249f72b7c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4213b7c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.164 24430-24430 wrap.sh                 logwrapper                           I      #19 0x724c721a64  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x69c2a64) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.164 24430-24430 wrap.sh                 logwrapper                           I      #20 0x724c7e3d4c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x6a84d4c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.164 24430-24430 wrap.sh                 logwrapper                           I      #21 0x724c86e9dc  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x6b0f9dc) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.164 24430-24430 wrap.sh                 logwrapper                           I      #22 0x7249ea8c00  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4149c00) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.164 24430-24430 wrap.sh                 logwrapper                           I      #23 0x7249ecc368  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x416d368) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
2025-11-10 21:06:30.164 24430-24430 wrap.sh                 logwrapper                           I      #24 0x7249ed19b8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x41729b8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
--------- beginning of crash
2025-11-10 21:06:30.164 24430-24430 wrap.sh                 logwrapper                           I  SUMMARY: AddressSanitizer: heap-use-after-free (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x55da7a0) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556) 
2025-11-10 21:06:30.165 24436-24696 libc                    sh                                   A  Fatal signal 6 (SIGABRT), code -1 (SI_QUEUE) in tid 24696 (GLThread 16), pid 24436 (.androioearth01)
2025-11-10 21:06:30.266 24857-24857 DEBUG                   pid-24857                            A  pid: 24436, tid: 24696, name: GLThread 16  >>> com.oearth.androioearth01 <<<
2025-11-10 21:06:30.266 24857-24857 DEBUG                   pid-24857                            A  Abort message: '=================================================================
==24436==ERROR: AddressSanitizer: heap-use-after-free on address 0x004b2aabf1c0 at pc 0x00724b3397a4 bp 0x0072537f9e50 sp 0x0072537f9e48
READ of size 8 at 0x004b2aabf1c0 thread T20 (GLThread 16)
    #0 0x724b3397a0  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x55da7a0) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
    #1 0x724b84835c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5ae935c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
    #2 0x724b847954  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5ae8954) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
    #3 0x724b84d468  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5aee468) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
    #4 0x724b84c32c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5aed32c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
    #5 0x724b84eaf0  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5aefaf0) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
    #6 0x7249ef20c8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x41930c8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
    #7 0x724b7ba7b8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5a5b7b8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
    #8 0x724bc75408  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5f16408) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
    #9 0x7249f72b7c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4213b7c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
    #10 0x724b84c4a4  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5aed4a4) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
    #11 0x724b84eaf0  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5aefaf0) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
    #12 0x7249ef20c8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x41930c8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
    #13 0x724b7ba7b8  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5a5b7b8) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
    #14 0x724bc75408  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x5f16408) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
    #15 0x7249f72b7c  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x4213b7c) (BuildId: 73fdf18df610a01fcb4be7d97e5c3f31b1151556)
    #16 0x724b84c4a4  (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLO
```

从日志来看，你的应用在运行过程中触发了 **AddressSanitizer (ASan)** 检测到的 **heap-use-after-free** 错误。这意味着你的代码在释放内存后仍然尝试访问该内存，导致崩溃。

---

## 🔍 **问题分析**
### **错误信息**
```
SUMMARY: AddressSanitizer: heap-use-after-free (/data/app/~~l82VxMShwt7_onUDFtOyWw==/com.oearth.androioearth01-YkGOTHy_l-DyLOwCqK9cLQ==/lib/arm64/libandroioearth01.so+0x55da7a0)
```
- **错误类型**：`heap-use-after-free`（释放后继续访问堆内存）
- **发生位置**：`libandroioearth01.so` 的某个函数（偏移 `0x55da7a0`）
- **线程**：`T20 (GLThread 16)`（可能是 OpenGL 渲染线程）

---

## 🛠️ **解决方案**
### **1. 检查日志中的调用栈**
日志中包含了调用栈信息，可以帮助定位问题：
```
READ of size 8 at 0x004b2aabf1c0 thread T20 (GLThread 16)
    #0 0x724b3397a0  (/data/app/.../libandroioearth01.so+0x55da7a0)
    #1 0x724b84835c  (/data/app/.../libandroioearth01.so+0x5ae935c)
    #2 0x724b847954  (/data/app/.../libandroioearth01.so+0x5ae8954)
    #3 0x724b84d468  (/data/app/.../libandroioearth01.so+0x5aee468)
    ...
```
你需要：
- **使用 `addr2line` 工具解析调用栈**：
  ```bash
  aarch64-linux-android-addr2line -e libandroioearth01.so 0x55da7a0
  ```
  这将告诉你具体是哪一行代码触发了问题。

- **检查 OpenGL 相关代码**：由于错误发生在 `GLThread 16`，可能是 OpenGL 资源（如纹理、缓冲区）被释放后仍然被使用。

---

### **2. 常见导致 `heap-use-after-free` 的原因**
1. **指针未置空**：
   - 释放内存后，指针未设置为 `nullptr`，后续代码仍然尝试访问。
   ```cpp
   int* ptr = new int(42);
   delete ptr;  // 释放内存
   *ptr = 100;  // 错误：释放后访问
   ```

2. **双重释放**：
   - 同一块内存被释放两次。
   ```cpp
   int* ptr = new int(42);
   delete ptr;
   delete ptr;  // 错误：双重释放
   ```

3. **多线程竞争**：
   - 一个线程释放内存，另一个线程仍在访问（如 OpenGL 资源管理不当）。

4. **STL 容器或智能指针误用**：
   - 使用 `std::vector`、`std::shared_ptr` 等容器时，迭代器或指针失效。

---

### **3. 调试步骤**
#### **(1) 启用更详细的 ASan 日志**
在 `wrap.sh` 中增加 ASan 选项：
```bash
export ASAN_OPTIONS="log_path=/data/local/tmp/asan.log:help=1:verbosity=2:detect_leaks=1"
```
然后检查 `/data/local/tmp/asan.log` 获取更详细的错误信息。

#### **(2) 检查 OpenGL 资源生命周期**
- 确保 OpenGL 资源（如纹理、缓冲区）在渲染线程停止后再释放。
- 使用 RAII（资源获取即初始化）管理 OpenGL 资源：
  ```cpp
  class GLTexture {
  public:
      GLTexture() { glGenTextures(1, &id); }
      ~GLTexture() { glDeleteTextures(1, &id); }
      GLuint id;
  };
  ```

#### **(3) 使用 `AddressSanitizer` 编译所有依赖库**
如果 `libandroioearth01.so` 依赖其他库（如 `libb.so`、`libc.so`），确保它们也使用 ASan 编译：
```cmake
target_compile_options(libb PRIVATE -fsanitize=address)
target_link_options(libb PRIVATE -fsanitize=address)
```

#### **(4) 检查多线程同步**
如果问题发生在多线程环境（如 `GLThread 16`），确保使用锁或原子操作保护共享资源：
```cpp
std::mutex mtx;
void threadSafeFunction() {
    std::lock_guard<std::mutex> lock(mtx);
    // 访问共享资源
}
```

---

### **4. 验证修复**
1. 修改代码后重新编译：
   ```bash
   ./gradlew clean assembleDebug
   ```
2. 重新安装 APK：
   ```bash
   adb install -r app-debug.apk
   ```
3. 检查是否仍触发 ASan 错误。

---

## 📌 **总结**
- **根本问题**：你的代码在释放内存后仍然尝试访问它（`heap-use-after-free`）。
- **解决方案**：
  1. 使用 `addr2line` 解析调用栈，定位问题代码。
  2. 检查 OpenGL 资源管理，确保释放后不再使用。
  3. 确保所有依赖库都启用 ASan。
  4. 修复多线程竞争问题。

如果仍有疑问，请提供调用栈解析结果或相关代码片段，以便进一步分析！

====================================================
# 7.在ubuntu上，想在 DisplaySettings::~DisplaySettings()中输出调用堆栈，如何做

在 Ubuntu 上为 C++ 类的析构函数 `DisplaySettings::~DisplaySettings()` 输出调用堆栈，核心是借助 **栈回溯库（如 `libbacktrace` 或 `libunwind`）** + 调试信息（编译时加 `-g`），结合日志输出实现。以下是两种常用且可靠的方案，从简单到灵活逐步说明：


### 前置准备：编译时开启调试信息
无论哪种方案，都需要确保编译时保留调试符号（否则堆栈会只有内存地址，无法显示文件名/行号）：
- 编译选项添加 `-g`（保留完整调试信息），禁用优化（避免编译器重排代码导致堆栈错乱，可选 `-O0`）；
- 示例 CMake 配置（若用 CMake）：
  ```cmake
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g -O0") # 调试信息 + 无优化
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -rdynamic") # 导出符号，确保栈回溯能识别函数名
  ```
- 若直接用 g++ 编译：
  ```bash
  g++ -g -O0 -rdynamic your_code.cpp -o your_program -lbacktrace # 后面方案1需链接 libbacktrace
  ```


## 方案1：使用 `libbacktrace`（推荐，轻量且原生）
`libbacktrace` 是 GCC 自带的轻量级栈回溯库，无需额外安装（Ubuntu 系统默认预装），支持 C++ 析构函数、多线程场景，输出信息清晰。

### 步骤1：代码中集成栈回溯逻辑
在 `DisplaySettings` 类的头文件或实现文件中，添加栈回溯函数，在析构函数中调用：
```cpp
#include <iostream>
#include <backtrace.h> // 包含 libbacktrace 头文件
#include <cstdlib>

// 全局回调函数：用于处理栈回溯的每一层信息
static void backtrace_callback(void* data, const char* file, int line, const char* func) {
    // 输出：层级 + 函数名 + 文件名:行号
    std::cerr << "  [" << *(int*)data << "] " << func << "() at " << file << ":" << line << std::endl;
    (*(int*)data)++; // 层级递增
}

// 错误回调函数：栈回溯失败时调用
static void backtrace_error_callback(void* data, const char* msg, int errnum) {
    std::cerr << "栈回溯失败：" << msg << " (错误码：" << errnum << ")" << std::endl;
}

// 你的 DisplaySettings 类
class DisplaySettings {
public:
    ~DisplaySettings() {
        std::cerr << "=== DisplaySettings::~DisplaySettings() 被调用，调用堆栈如下 ===" << std::endl;
        
        int level = 0;
        // 初始化栈回溯：参数分别为（程序路径，是否支持符号重定位，错误回调，回调数据，回溯回调）
        backtrace_state* state = backtrace_create_state(nullptr, true, backtrace_error_callback, nullptr);
        if (state) {
            // 开始栈回溯：跳过前 1 层（当前析构函数本身），最多回溯 10 层
            backtrace_full(state, 1, backtrace_callback, backtrace_error_callback, &level);
        }
        
        std::cerr << "=== 栈回溯结束 ===" << std::endl;
    }
};

// 测试代码
int main() {
    DisplaySettings settings;
    return 0;
}
```

### 步骤2：编译与运行
编译时链接 `libbacktrace`（无需额外安装，系统自带）：
```bash
g++ -g -O0 -rdynamic display_settings.cpp -o test_stack -lbacktrace
```
运行程序，输出效果如下（清晰显示调用层级、函数名、文件名和行号）：
```
=== DisplaySettings::~DisplaySettings() 被调用，调用堆栈如下 ===
  [0] main() at display_settings.cpp:35
  [1] __libc_start_main() at ../csu/libc-start.c:310
  [2] _start() at ../sysdeps/x86_64/start.S:115
=== 栈回溯结束 ===
```


## 方案2：使用 `libunwind`（更灵活，支持复杂场景）
`libunwind` 是更强大的跨平台栈回溯库，支持更多架构和复杂场景（如信号处理、动态库栈回溯），需手动安装。

### 步骤1：安装 `libunwind`
```bash
sudo apt update && sudo apt install libunwind-dev
```

### 步骤2：代码中集成栈回溯逻辑
```cpp
#include <iostream>
#include <unwind.h> // 包含 libunwind 头文件
#include <cstdio>

// 栈回溯回调函数：libunwind 会逐帧调用此函数
static _Unwind_Reason_Code backtrace_callback(_Unwind_Context* context, void* arg) {
    int* level = (int*)arg;
    uintptr_t ip = _Unwind_GetIP(context); // 获取当前指令地址
    if (ip == 0) {
        return _URC_END_OF_STACK; // 栈回溯结束
    }

    // 通过 addr2line 命令解析地址对应的函数名、文件名、行号（借助系统命令）
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "addr2line -f -e test_stack_unwind %lx", (unsigned long)ip);
    std::cerr << "  [" << *level << "] ";
    system(cmd); // 执行 addr2line 并输出结果

    (*level)++;
    if (*level >= 10) { // 最多回溯 10 层
        return _URC_END_OF_STACK;
    }
    return _URC_NO_REASON; // 继续回溯下一层
}

// 触发栈回溯的函数
void print_backtrace() {
    int level = 0;
    _Unwind_Backtrace(backtrace_callback, &level); // 启动栈回溯
}

// 你的 DisplaySettings 类
class DisplaySettings {
public:
    ~DisplaySettings() {
        std::cerr << "=== DisplaySettings::~DisplaySettings() 被调用，调用堆栈如下 ===" << std::endl;
        print_backtrace(); // 调用栈回溯函数
        std::cerr << "=== 栈回溯结束 ===" << std::endl;
    }
};

// 测试代码
void func1() {
    DisplaySettings settings;
}

void func2() {
    func1();
}

int main() {
    func2();
    return 0;
}
```

### 步骤3：编译与运行
编译时链接 `libunwind`：
```bash
g++ -g -O0 -rdynamic display_settings.cpp -o test_stack_unwind -lunwind
```
运行程序，输出效果如下（借助 `addr2line` 解析地址，信息更详细）：
```
=== DisplaySettings::~DisplaySettings() 被调用，调用堆栈如下 ===
  [0] _Unwind_Backtrace
  [1] print_backtrace()
  at /home/user/display_settings.cpp:26
  [2] DisplaySettings::~DisplaySettings()
  at /home/user/display_settings.cpp:36
  [3] func1()
  at /home/user/display_settings.cpp:42
  [4] func2()
  at /home/user/display_settings.cpp:46
  [5] main()
  at /home/user/display_settings.cpp:50
  [6] __libc_start_main
  at ../csu/libc-start.c:310
  [7] _start
  at ../sysdeps/x86_64/start.S:115
=== 栈回溯结束 ===
```


## 关键注意事项（避免踩坑）
1. **必须保留调试信息**：编译时 `-g` 不能少，否则 `addr2line` 或 `libbacktrace` 无法解析文件名和行号，只能显示内存地址。
2. **禁用过度优化**：避免使用 `-O2` 及以上优化等级（推荐 `-O0`），否则编译器可能会内联函数、重排代码，导致栈回溯错乱（析构函数可能被优化合并）。
3. **`-rdynamic` 选项**：导出程序的符号表，确保栈回溯能识别用户自定义函数名（否则可能只显示 `func()` 等模糊名称）。
4. **析构函数的特殊性**：若析构函数是虚函数（`virtual ~DisplaySettings()`），栈回溯可能会多一层虚函数表调用，但两种方案都能正确处理，无需额外修改。
5. **多线程场景**：若 `DisplaySettings` 在多线程中析构，两种方案均支持（`libbacktrace` 和 `libunwind` 都是线程安全的），直接使用即可。


## 方案对比与选择
| 特性                | libbacktrace                | libunwind                   |
|---------------------|-----------------------------|-----------------------------|
| 安装成本            | 系统自带，无需安装          | 需手动 `apt install`        |
| 易用性              | 简单，直接调用 API          | 需配合 `addr2line`，稍复杂  |
| 功能灵活性          | 基础栈回溯，满足大部分需求  | 支持复杂场景（信号、动态库）|
| 输出清晰度          | 直接输出函数名/行号         | 需借助外部命令，信息更全    |

- 日常开发推荐 **方案1（libbacktrace）**：简单、轻量，无需额外依赖，满足析构函数栈回溯的核心需求；
- 若涉及动态库、多线程复杂调用或信号处理，推荐 **方案2（libunwind）**：功能更强大，兼容性更好。

===============================================================
# 8. ubuntu app error when exiting 

## 8.1
```sh
AddressSanitizer:DEADLYSIGNAL
=================================================================
==780958==ERROR: AddressSanitizer: SEGV on unknown address 0x000000000479 (pc 0x5d1b3eafb21f bp 0x7c3e633449f0 sp 0x7c3e63344760 T7)
==780958==The signal is caused by a READ memory access.
==780958==Hint: address points to the zero page.
    #0 0x5d1b3eafb21f in osgEarth::TerrainTileModelFactory::createImageTexture(osg::Image const*, osgEarth::ImageLayer const*) const /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/TerrainTileModelFactory.cpp:775
    #1 0x5d1b3eaf57c0 in osgEarth::TerrainTileModelFactory::addImageLayer(osgEarth::TerrainTileModel*, osgEarth::ImageLayer*, osgEarth::TileKey const&, osgEarth::Util::TerrainEngineRequirements const&, osgEarth::ProgressCallback*) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/TerrainTileModelFactory.cpp:259
    #2 0x5d1b3eaf70a0 in osgEarth::TerrainTileModelFactory::addColorLayers(osgEarth::TerrainTileModel*, osgEarth::Map const*, osgEarth::Util::TerrainEngineRequirements const&, osgEarth::TileKey const&, osgEarth::CreateTileManifest const&, osgEarth::ProgressCallback*, bool) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/TerrainTileModelFactory.cpp:387
    #3 0x5d1b3eaf447e in osgEarth::TerrainTileModelFactory::createTileModel(osgEarth::Map const*, osgEarth::TileKey const&, osgEarth::CreateTileManifest const&, osgEarth::Util::TerrainEngineRequirements const&, osgEarth::ProgressCallback*) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/TerrainTileModelFactory.cpp:147
    #4 0x5d1b3eac3f5e in osgEarth::TerrainEngineNode::createTileModel(osgEarth::Map const*, osgEarth::TileKey const&, osgEarth::CreateTileManifest const&, osgEarth::ProgressCallback*) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/TerrainEngineNode.cpp:229
    #5 0x5d1b3e1959c9 in operator() /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/LoadTileData.cpp:84
    #6 0x5d1b3e19736f in operator() /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/weejobs.h:814
    #7 0x5d1b3e198607 in __invoke_impl<bool, jobs::dispatch<osgEarth::REX::LoadTileDataOperation::dispatch(bool)::<lambda(osgEarth::Cancelable&)> >(osgEarth::REX::LoadTileDataOperation::dispatch(bool)::<lambda(osgEarth::Cancelable&)>, const context&)::<lambda()>&> /usr/include/c++/13/bits/invoke.h:61
    #8 0x5d1b3e1983df in __invoke_r<bool, jobs::dispatch<osgEarth::REX::LoadTileDataOperation::dispatch(bool)::<lambda(osgEarth::Cancelable&)> >(osgEarth::REX::LoadTileDataOperation::dispatch(bool)::<lambda(osgEarth::Cancelable&)>, const context&)::<lambda()>&> /usr/include/c++/13/bits/invoke.h:114
    #9 0x5d1b3e197dfd in _M_invoke /usr/include/c++/13/bits/std_function.h:290
    #10 0x5d1b3e05cf6d in std::function<bool ()>::operator()() const /usr/include/c++/13/bits/std_function.h:591
    #11 0x5d1b3e056c39 in jobs::jobpool::run() /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/weejobs.h:956
    #12 0x5d1b3e057127 in jobs::jobpool::start_threads()::{lambda()#1}::operator()() const /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/weejobs.h:1001
    #13 0x5d1b3e07300f in void std::__invoke_impl<void, jobs::jobpool::start_threads()::{lambda()#1}>(std::__invoke_other, jobs::jobpool::start_threads()::{lambda()#1}&&) /usr/include/c++/13/bits/invoke.h:61
    #14 0x5d1b3e072fca in std::__invoke_result<jobs::jobpool::start_threads()::{lambda()#1}>::type std::__invoke<jobs::jobpool::start_threads()::{lambda()#1}>(jobs::jobpool::start_threads()::{lambda()#1}&&) /usr/include/c++/13/bits/invoke.h:96
    #15 0x5d1b3e072f6b in void std::thread::_Invoker<std::tuple<jobs::jobpool::start_threads()::{lambda()#1}> >::_M_invoke<0ul>(std::_Index_tuple<0ul>) /usr/include/c++/13/bits/std_thread.h:292
    #16 0x5d1b3e072f3b in std::thread::_Invoker<std::tuple<jobs::jobpool::start_threads()::{lambda()#1}> >::operator()() /usr/include/c++/13/bits/std_thread.h:299
    #17 0x5d1b3e072ebf in std::thread::_State_impl<std::thread::_Invoker<std::tuple<jobs::jobpool::start_threads()::{lambda()#1}> > >::_M_run() /usr/include/c++/13/bits/std_thread.h:244
    #18 0x7c3e83aecdb3  (/lib/x86_64-linux-gnu/libstdc++.so.6+0xecdb3) (BuildId: ca77dae775ec87540acd7218fa990c40d1c94ab1)
    #19 0x7c3e83e5ea41 in asan_thread_start ../../../../src/libsanitizer/asan/asan_interceptors.cpp:234
    #20 0x7c3e8369caa3 in start_thread nptl/pthread_create.c:447
    #21 0x7c3e83729c6b in clone3 ../sysdeps/unix/sysv/linux/x86_64/clone3.S:78

AddressSanitizer can not provide additional info.
SUMMARY: AddressSanitizer: SEGV /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/TerrainTileModelFactory.cpp:775 in osgEarth::TerrainTileModelFactory::createImageTexture(osg::Image const*, osgEarth::ImageLayer const*) const
Thread T7 created by T0 here:
    #0 0x7c3e83ef51f9 in pthread_create ../../../../src/libsanitizer/asan/asan_interceptors.cpp:245
    #1 0x7c3e83aeceb0 in std::thread::_M_start_thread(std::unique_ptr<std::thread::_State, std::default_delete<std::thread::_State> >, void (*)()) (/lib/x86_64-linux-gnu/libstdc++.so.6+0xeceb0) (BuildId: ca77dae775ec87540acd7218fa990c40d1c94ab1)
    #2 0x5d1b3e05ef9f in std::thread::thread<jobs::jobpool::start_threads()::{lambda()#1}, , void>(jobs::jobpool::start_threads()::{lambda()#1}&&) (/mnt/disk2/abner/zdev/nv/osgearth0x/build_by_sh/build/ubuntu/platform/lnx8sky/Lnx8SkyDemo+0x1a8bf9f) (BuildId: 03abd6c70eb155697ff742a71960642f44260dd6)
    #3 0x5d1b3e0572ac in jobs::jobpool::start_threads() /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/weejobs.h:995
    #4 0x5d1b3e055ca7 in jobs::get_pool(std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > const&, unsigned int) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/weejobs.h:760
    #5 0x5d1b3e12a134 in osgEarth::REX::Merger::Merger() /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/Loader.cpp:30
    #6 0x5d1b3e078bb7 in osgEarth::REX::RexTerrainEngineNode::onSetMap() /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/RexTerrainEngineNode.cpp:281
    #7 0x5d1b3eac36cd in osgEarth::TerrainEngineNode::setMap(osgEarth::Map const*, osgEarth::TerrainOptions const&) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/TerrainEngineNode.cpp:181
    #8 0x5d1b3e82d97a in osgEarth::MapNode::open() /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/MapNode.cpp:326
    #9 0x5d1b3e833189 in osgEarth::MapNode::traverse(osg::NodeVisitor&) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/MapNode.cpp:830
    #10 0x5d1b3e08ab71 in osg::NodeVisitor::traverse(osg::Node&) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/NodeVisitor:277
    #11 0x5d1b3fdb72f3 in osgUtil::UpdateVisitor::handle_callbacks_and_traverse(osg::Node&) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osgUtil/UpdateVisitor:111
    #12 0x5d1b3fdb709a in osgUtil::UpdateVisitor::apply(osg::Group&) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osgUtil/UpdateVisitor:81
    #13 0x5d1b3e0f9d94 in osg::Group::accept(osg::NodeVisitor&) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/Group:38
    #14 0x5d1b3f798f1c in osgViewer::Scene::updateSceneGraph(osg::NodeVisitor&) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgViewer/Scene.cpp:149
    #15 0x5d1b3f6daf01 in osgViewer::Viewer::updateTraversal() /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgViewer/Viewer.cpp:1155
    #16 0x5d1b3f7060ba in osgViewer::ViewerBase::frame(double) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgViewer/ViewerBase.cpp:747
    #17 0x5d1b3f705b21 in osgViewer::ViewerBase::run() /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgViewer/ViewerBase.cpp:703
    #18 0x5d1b3f6d29ab in osgViewer::Viewer::run() /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgViewer/Viewer.cpp:445
    #19 0x5d1b3e84a6a0 in osgEarth::Util::Metrics::run(osgViewer::ViewerBase&) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/Metrics.cpp:156
    #20 0x5d1b3e01dd39 in main /home/abner/abner2/zdev/nv/osgearth0x/platform/lnx8sky/demo_simple_sky.cpp:84
    #21 0x7c3e8362a1c9 in __libc_start_call_main ../sysdeps/nptl/libc_start_call_main.h:58
    #22 0x7c3e8362a28a in __libc_start_main_impl ../csu/libc-start.c:360
    #23 0x5d1b3e01cd64 in _start (/mnt/disk2/abner/zdev/nv/osgearth0x/build_by_sh/build/ubuntu/platform/lnx8sky/Lnx8SkyDemo+0x1a49d64) (BuildId: 03abd6c70eb155697ff742a71960642f44260dd6)

==780958==ABORTING
```
## 8.2
```sh
=================================================================
==811441==ERROR: AddressSanitizer: heap-use-after-free on address 0x50c000000230 at pc 0x63b569552e58 bp 0x7ffff55a4d00 sp 0x7ffff55a4cf0
READ of size 4 at 0x50c000000230 thread T0
    #0 0x63b569552e57 in osg::NotifyStreamBuffer::setCurrentSeverity(osg::NotifySeverity) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Notify.cpp:76
    #1 0x63b56955333c in osg::NotifyStream::setCurrentSeverity(osg::NotifySeverity) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Notify.cpp:111
    #2 0x63b569552209 in osg::notify(osg::NotifySeverity) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Notify.cpp:230
    #3 0x63b5695c9000 in osg::Referenced::unref() const /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Referenced.cpp:329
    #4 0x63b5690234af in osg::ref_ptr<osgDB::ReaderWriter>& osg::ref_ptr<osgDB::ReaderWriter>::operator=<osgDB::ReaderWriter>(osg::ref_ptr<osgDB::ReaderWriter>&&) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/ref_ptr:84
    #5 0x63b569020ba9 in osg::ref_ptr<osgDB::ReaderWriter>* std::__copy_move<true, false, std::random_access_iterator_tag>::__copy_m<osg::ref_ptr<osgDB::ReaderWriter>*, osg::ref_ptr<osgDB::ReaderWriter>*>(osg::ref_ptr<osgDB::ReaderWriter>*, osg::ref_ptr<osgDB::ReaderWriter>*, osg::ref_ptr<osgDB::ReaderWriter>*) /usr/include/c++/13/bits/stl_algobase.h:413
    #6 0x63b56901cef3 in osg::ref_ptr<osgDB::ReaderWriter>* std::__copy_move_a2<true, osg::ref_ptr<osgDB::ReaderWriter>*, osg::ref_ptr<osgDB::ReaderWriter>*>(osg::ref_ptr<osgDB::ReaderWriter>*, osg::ref_ptr<osgDB::ReaderWriter>*, osg::ref_ptr<osgDB::ReaderWriter>*) /usr/include/c++/13/bits/stl_algobase.h:506
    #7 0x63b5690184ea in osg::ref_ptr<osgDB::ReaderWriter>* std::__copy_move_a1<true, osg::ref_ptr<osgDB::ReaderWriter>*, osg::ref_ptr<osgDB::ReaderWriter>*>(osg::ref_ptr<osgDB::ReaderWriter>*, osg::ref_ptr<osgDB::ReaderWriter>*, osg::ref_ptr<osgDB::ReaderWriter>*) /usr/include/c++/13/bits/stl_algobase.h:533
    #8 0x63b569012c4a in __gnu_cxx::__normal_iterator<osg::ref_ptr<osgDB::ReaderWriter>*, std::vector<osg::ref_ptr<osgDB::ReaderWriter>, std::allocator<osg::ref_ptr<osgDB::ReaderWriter> > > > std::__copy_move_a<true, __gnu_cxx::__normal_iterator<osg::ref_ptr<osgDB::ReaderWriter>*, std::vector<osg::ref_ptr<osgDB::ReaderWriter>, std::allocator<osg::ref_ptr<osgDB::ReaderWriter> > > >, __gnu_cxx::__normal_iterator<osg::ref_ptr<osgDB::ReaderWriter>*, std::vector<osg::ref_ptr<osgDB::ReaderWriter>, std::allocator<osg::ref_ptr<osgDB::ReaderWriter> > > > >(__gnu_cxx::__normal_iterator<osg::ref_ptr<osgDB::ReaderWriter>*, std::vector<osg::ref_ptr<osgDB::ReaderWriter>, std::allocator<osg::ref_ptr<osgDB::ReaderWriter> > > >, __gnu_cxx::__normal_iterator<osg::ref_ptr<osgDB::ReaderWriter>*, std::vector<osg::ref_ptr<osgDB::ReaderWriter>, std::allocator<osg::ref_ptr<osgDB::ReaderWriter> > > >, __gnu_cxx::__normal_iterator<osg::ref_ptr<osgDB::ReaderWriter>*, std::vector<osg::ref_ptr<osgDB::ReaderWriter>, std::allocator<osg::ref_ptr<osgDB::ReaderWriter> > > >) /usr/include/c++/13/bits/stl_algobase.h:540
    #9 0x63b56900bb5c in __gnu_cxx::__normal_iterator<osg::ref_ptr<osgDB::ReaderWriter>*, std::vector<osg::ref_ptr<osgDB::ReaderWriter>, std::allocator<osg::ref_ptr<osgDB::ReaderWriter> > > > std::move<__gnu_cxx::__normal_iterator<osg::ref_ptr<osgDB::ReaderWriter>*, std::vector<osg::ref_ptr<osgDB::ReaderWriter>, std::allocator<osg::ref_ptr<osgDB::ReaderWriter> > > >, __gnu_cxx::__normal_iterator<osg::ref_ptr<osgDB::ReaderWriter>*, std::vector<osg::ref_ptr<osgDB::ReaderWriter>, std::allocator<osg::ref_ptr<osgDB::ReaderWriter> > > > >(__gnu_cxx::__normal_iterator<osg::ref_ptr<osgDB::ReaderWriter>*, std::vector<osg::ref_ptr<osgDB::ReaderWriter>, std::allocator<osg::ref_ptr<osgDB::ReaderWriter> > > >, __gnu_cxx::__normal_iterator<osg::ref_ptr<osgDB::ReaderWriter>*, std::vector<osg::ref_ptr<osgDB::ReaderWriter>, std::allocator<osg::ref_ptr<osgDB::ReaderWriter> > > >, __gnu_cxx::__normal_iterator<osg::ref_ptr<osgDB::ReaderWriter>*, std::vector<osg::ref_ptr<osgDB::ReaderWriter>, std::allocator<osg::ref_ptr<osgDB::ReaderWriter> > > >) /usr/include/c++/13/bits/stl_algobase.h:665
    #10 0x63b569000c88 in std::vector<osg::ref_ptr<osgDB::ReaderWriter>, std::allocator<osg::ref_ptr<osgDB::ReaderWriter> > >::_M_erase(__gnu_cxx::__normal_iterator<osg::ref_ptr<osgDB::ReaderWriter>*, std::vector<osg::ref_ptr<osgDB::ReaderWriter>, std::allocator<osg::ref_ptr<osgDB::ReaderWriter> > > >) /usr/include/c++/13/bits/vector.tcc:185
    #11 0x63b568ff9f35 in std::vector<osg::ref_ptr<osgDB::ReaderWriter>, std::allocator<osg::ref_ptr<osgDB::ReaderWriter> > >::erase(__gnu_cxx::__normal_iterator<osg::ref_ptr<osgDB::ReaderWriter> const*, std::vector<osg::ref_ptr<osgDB::ReaderWriter>, std::allocator<osg::ref_ptr<osgDB::ReaderWriter> > > >) /usr/include/c++/13/bits/stl_vector.h:1535
    #12 0x63b568fe4586 in osgDB::Registry::removeReaderWriter(osgDB::ReaderWriter*) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgDB/Registry.cpp:668
    #13 0x63b5677ffc56 in osgDB::RegisterReaderWriterProxy<ReaderWriterKML>::~RegisterReaderWriterProxy() /home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/install/ubuntu/3rd/osg/include/osgDB/Registry:875
    #14 0x772f35a47a75 in __run_exit_handlers stdlib/exit.c:108
    #15 0x772f35a47bbd in __GI_exit stdlib/exit.c:138
    #16 0x772f35a2a1d0 in __libc_start_call_main ../sysdeps/nptl/libc_start_call_main.h:74
    #17 0x772f35a2a28a in __libc_start_main_impl ../csu/libc-start.c:360
    #18 0x63b567592d64 in _start (/mnt/disk2/abner/zdev/nv/osgearth0x/build_by_sh/build/ubuntu/platform/lnx8sky/Lnx8SkyDemo+0x1a49d64) (BuildId: 03abd6c70eb155697ff742a71960642f44260dd6)

0x50c000000230 is located 112 bytes inside of 120-byte region [0x50c0000001c0,0x50c000000238)
freed by thread T0 here:
    #0 0x772f364ff5e8 in operator delete(void*, unsigned long) ../../../../src/libsanitizer/asan/asan_new_delete.cpp:164
    #1 0x63b5695533ce in osg::NotifyStreamBuffer::~NotifyStreamBuffer() /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Notify.cpp:61
    #2 0x63b5695534e2 in osg::NotifyStream::~NotifyStream() /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Notify.cpp:122
    #3 0x63b569553ee7 in NotifySingleton::~NotifySingleton() /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Notify.cpp:135
    #4 0x772f35a47a75 in __run_exit_handlers stdlib/exit.c:108
    #5 0x772f35a47bbd in __GI_exit stdlib/exit.c:138
    #6 0x772f35a2a1d0 in __libc_start_call_main ../sysdeps/nptl/libc_start_call_main.h:74
    #7 0x772f35a2a28a in __libc_start_main_impl ../csu/libc-start.c:360
    #8 0x63b567592d64 in _start (/mnt/disk2/abner/zdev/nv/osgearth0x/build_by_sh/build/ubuntu/platform/lnx8sky/Lnx8SkyDemo+0x1a49d64) (BuildId: 03abd6c70eb155697ff742a71960642f44260dd6)

previously allocated by thread T0 here:
    #0 0x772f364fe548 in operator new(unsigned long) ../../../../src/libsanitizer/asan/asan_new_delete.cpp:95
    #1 0x63b5695531c8 in osg::NotifyStream::NotifyStream() /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Notify.cpp:104
    #2 0x63b5695536c8 in NotifySingleton::NotifySingleton() /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Notify.cpp:138
    #3 0x63b569551fef in getNotifySingleton /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Notify.cpp:183
    #4 0x63b569552193 in osg::isNotifyEnabled(osg::NotifySeverity) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Notify.cpp:222
    #5 0x63b56903f9d2 in osgDB::DynamicLibrary::loadLibrary(std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > const&) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgDB/DynamicLibrary.cpp:80
    #6 0x63b568fe7965 in osgDB::Registry::loadLibrary(std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > const&) /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgDB/Registry.cpp:867
    #7 0x63b567879c95 in ReaderWriterEarth::ReaderWriterEarth() /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/earth/ReaderWriterOsgEarth.cpp:81
    #8 0x63b56787daaf in osgDB::RegisterReaderWriterProxy<ReaderWriterEarth>::RegisterReaderWriterProxy() (/mnt/disk2/abner/zdev/nv/osgearth0x/build_by_sh/build/ubuntu/platform/lnx8sky/Lnx8SkyDemo+0x1d34aaf) (BuildId: 03abd6c70eb155697ff742a71960642f44260dd6)
    #9 0x63b5678797a0 in __static_initialization_and_destruction_0 /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/earth/ReaderWriterOsgEarth.cpp:294
    #10 0x63b567879870 in _GLOBAL__sub_I_ReaderWriterOsgEarth.cpp /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/earth/ReaderWriterOsgEarth.cpp:294
    #11 0x772f35a2a303 in call_init ../csu/libc-start.c:145
    #12 0x772f35a2a303 in __libc_start_main_impl ../csu/libc-start.c:347
    #13 0x63b567592d64 in _start (/mnt/disk2/abner/zdev/nv/osgearth0x/build_by_sh/build/ubuntu/platform/lnx8sky/Lnx8SkyDemo+0x1a49d64) (BuildId: 03abd6c70eb155697ff742a71960642f44260dd6)

SUMMARY: AddressSanitizer: heap-use-after-free /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Notify.cpp:76 in osg::NotifyStreamBuffer::setCurrentSeverity(osg::NotifySeverity)
Shadow bytes around the buggy address:
  0x50bfffffff80: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x50c000000000: fa fa fa fa fa fa fa fa 00 00 00 00 00 00 00 00
  0x50c000000080: 00 00 00 00 00 00 00 00 fa fa fa fa fa fa fa fa
  0x50c000000100: fd fd fd fd fd fd fd fd fd fd fd fd fd fd fd fd
  0x50c000000180: fa fa fa fa fa fa fa fa fd fd fd fd fd fd fd fd
=>0x50c000000200: fd fd fd fd fd fd[fd]fa fa fa fa fa fa fa fa fa
  0x50c000000280: fd fd fd fd fd fd fd fd fd fd fd fd fd fd fd fa
  0x50c000000300: fa fa fa fa fa fa fa fa fd fd fd fd fd fd fd fd
  0x50c000000380: fd fd fd fd fd fd fd fd fa fa fa fa fa fa fa fa
  0x50c000000400: fd fd fd fd fd fd fd fd fd fd fd fd fd fd fd fd
  0x50c000000480: fa fa fa fa fa fa fa fa fd fd fd fd fd fd fd fd
Shadow byte legend (one shadow byte represents 8 application bytes):
  Addressable:           00
  Partially addressable: 01 02 03 04 05 06 07 
  Heap left redzone:       fa
  Freed heap region:       fd
  Stack left redzone:      f1
  Stack mid redzone:       f2
  Stack right redzone:     f3
  Stack after return:      f5
  Stack use after scope:   f8
  Global redzone:          f9
  Global init order:       f6
  Poisoned by user:        f7
  Container overflow:      fc
  Array cookie:            ac
  Intra object redzone:    bb
  ASan internal:           fe
  Left alloca redzone:     ca
  Right alloca redzone:    cb
==811441==ABORTING
```
==========================================================
# 9.静态对象销毁顺序问题 的应对方案

静态对象销毁顺序问题是 C++ 中一个经典且棘手的问题。以下是完整的应对方案：

## 1. 设计模式解决方案

### A. 单例模式（Meyer's Singleton） - **推荐**
```cpp
class ResourceManager {
public:
    static ResourceManager& instance() {
        static ResourceManager instance;  // C++11 保证线程安全
        return instance;
    }
    
    // 禁用拷贝和移动
    ResourceManager(const ResourceManager&) = delete;
    ResourceManager& operator=(const ResourceManager&) = delete;
    
private:
    ResourceManager() = default;
    ~ResourceManager() = default;
};
```

### B. 依赖注入模式
```cpp
class Logger {
public:
    virtual ~Logger() = default;
    virtual void log(const std::string& message) = 0;
};

class FileLogger : public Logger {
    // 实现
};

class Application {
    std::shared_ptr<Logger> logger_;
public:
    explicit Application(std::shared_ptr<Logger> logger) : logger_(logger) {}
};
```

## 2. 生命周期管理策略

### A. 显式初始化和清理
```cpp
class GlobalResources {
    static bool initialized_;
    static std::mutex init_mutex_;
    
public:
    static void initialize() {
        std::lock_guard<std::mutex> lock(init_mutex_);
        if (!initialized_) {
            // 初始化代码
            initialized_ = true;
        }
    }
    
    static void shutdown() {
        std::lock_guard<std::mutex> lock(init_mutex_);
        if (initialized_) {
            // 清理代码
            initialized_ = false;
        }
    }
    
    static bool isInitialized() { return initialized_; }
};

// 在 main 中显式控制
int main() {
    GlobalResources::initialize();
    // ... 应用逻辑
    GlobalResources::shutdown();
    return 0;
}
```

### B. 引用计数管理
```cpp
class SharedResource {
    static std::atomic<int> ref_count_;
    static std::shared_ptr<SharedResource> instance_;
    static std::mutex mutex_;
    
public:
    static std::shared_ptr<SharedResource> acquire() {
        std::lock_guard<std::mutex> lock(mutex_);
        if (!instance_) {
            instance_ = std::shared_ptr<SharedResource>(new SharedResource());
        }
        ref_count_++;
        return instance_;
    }
    
    static void release() {
        std::lock_guard<std::mutex> lock(mutex_);
        if (--ref_count_ == 0) {
            instance_.reset();
        }
    }
    
private:
    SharedResource() = default;
    ~SharedResource() = default;
};
```

## 3. 特定场景解决方案

### A. 日志系统 - 使用 Nifty Counter 惯用法
```cpp
// LogStream.h
class LogStream {
public:
    static LogStream& instance();
    void write(const std::string& message);
    
private:
    LogStream();
    ~LogStream();
};

// LogStream.cpp
namespace {
    // Nifty Counter
    struct LogStreamInitializer {
        LogStreamInitializer();
        ~LogStreamInitializer();
    };
    
    LogStreamInitializer::LogStreamInitializer() {
        // 在静态初始化时构造
        LogStream::instance();
    }
    
    LogStreamInitializer::~LogStreamInitializer() {
        // 在静态析构时清理
    }
    
    // 确保在 main 之前初始化
    LogStreamInitializer log_stream_initializer;
}

LogStream& LogStream::instance() {
    static LogStream instance;
    return instance;
}
```

### B. 数据库连接池
```cpp
class DatabasePool {
    static std::atomic<DatabasePool*> instance_;
    static std::mutex mutex_;
    
    std::vector<Connection*> connections_;
    
public:
    static DatabasePool& instance() {
        DatabasePool* pool = instance_.load(std::memory_order_acquire);
        if (!pool) {
            std::lock_guard<std::mutex> lock(mutex_);
            pool = instance_.load(std::memory_order_relaxed);
            if (!pool) {
                pool = new DatabasePool();
                instance_.store(pool, std::memory_order_release);
                
                // 注册清理函数
                std::atexit( {
                    delete instance_.load();
                    instance_.store(nullptr);
                });
            }
        }
        return *pool;
    }
    
private:
    DatabasePool() {
        // 初始化连接池
    }
    
    ~DatabasePool() {
        // 清理连接
        for (auto conn : connections_) {
            delete conn;
        }
    }
};
```

## 4. OSG/OSGEarth 特定解决方案

### A. 资源管理器包装器
```cpp
class SafeOSGResourceManager {
    static std::atomic<bool> shutdown_initiated_;
    static std::mutex resource_mutex_;
    static std::vector<osg::ref_ptr<osg::Object>> managed_resources_;
    
public:
    static void registerResource(osg::Object* resource) {
        if (shutdown_initiated_) {
            OSG_WARN << "Attempting to register resource during shutdown" << std::endl;
            return;
        }
        
        std::lock_guard<std::mutex> lock(resource_mutex_);
        managed_resources_.push_back(resource);
    }
    
    static void preShutdownCleanup() {
        shutdown_initiated_ = true;
        
        std::lock_guard<std::mutex> lock(resource_mutex_);
        
        // 1. 停止所有异步操作
        osgDB::Registry::instance()->setKillDatabasePager(true);
        
        // 2. 按正确顺序释放资源
        std::reverse(managed_resources_.begin(), managed_resources_.end());
        managed_resources_.clear();
        
        // 3. 等待所有操作完成
        osgDB::Registry::instance()->getDatabasePager()->cancel();
    }
    
    // 注册清理函数
    struct ShutdownRegistrar {
        ShutdownRegistrar() {
            std::atexit(&SafeOSGResourceManager::preShutdownCleanup);
        }
    };
    
    static ShutdownRegistrar registrar_;
};
```

### B. 线程安全的纹理管理器
```cpp
class ThreadSafeTextureManager {
    static std::atomic<ThreadSafeTextureManager*> instance_;
    static std::mutex instance_mutex_;
    static std::atomic<int> active_textures_;
    
    std::unordered_map<std::string, osg::ref_ptr<osg::Texture>> texture_cache_;
    std::mutex cache_mutex_;
    
public:
    static ThreadSafeTextureManager& instance() {
        auto* instance = instance_.load(std::memory_order_acquire);
        if (!instance) {
            std::lock_guard<std::mutex> lock(instance_mutex_);
            instance = instance_.load(std::memory_order_relaxed);
            if (!instance) {
                instance = new ThreadSafeTextureManager();
                instance_.store(instance, std::memory_order_release);
                
                // 确保在 OSG 通知系统之前销毁
                struct Destroyer {
                    ~Destroyer() {
                        delete instance_.load();
                        instance_.store(nullptr);
                    }
                };
                static Destroyer destroyer;
            }
        }
        return *instance;
    }
    
    osg::Texture* getTexture(const std::string& filename) {
        if (active_textures_.load() == 0) {
            return nullptr; // 正在关闭
        }
        
        std::lock_guard<std::mutex> lock(cache_mutex_);
        auto it = texture_cache_.find(filename);
        if (it != texture_cache_.end()) {
            return it->second.get();
        }
        return nullptr;
    }
    
    void shutdown() {
        active_textures_.store(0);
        std::lock_guard<std::mutex> lock(cache_mutex_);
        texture_cache_.clear();
    }
    
private:
    ThreadSafeTextureManager() : active_textures_(1) {}
    ~ThreadSafeTextureManager() = default;
};
```

## 5. 构建系统和编译时解决方案

### A. 编译时控制初始化顺序
```cpp
// 使用优先级控制初始化顺序
template<int Priority>
class Initializable {
protected:
    Initializable() {
        // 确保依赖的系统已初始化
        Initializable<Priority - 1>::ensureInitialized();
    }
};

template<>
class Initializable<0> {
protected:
    static void ensureInitialized() {
        static bool initialized = {
            // 最低优先级的初始化
            return true;
        }();
    }
};

class HighPriorityResource : public Initializable<100> {
    // 高优先级资源
};

class LowPriorityResource : public Initializable<0> {
    // 低优先级资源
};
```

### B. 链接顺序控制
```cmake
# CMakeLists.txt - 显式控制链接顺序
add_library(core_lib STATIC core1.cpp core2.cpp)
add_library(utils_lib STATIC utils1.cpp utils2.cpp)

# 确保 core_lib 在 utils_lib 之前初始化
target_link_libraries(utils_lib core_lib)
target_link_libraries(main_app utils_lib core_lib)
```

## 6. 最佳实践总结

1. **优先使用 Meyer's Singleton**（C++11 线程安全）
2. **避免复杂的静态对象依赖**
3. **使用 RAII 和智能指针**
4. **显式控制初始化和关闭顺序**
5. **为关键资源实现引用计数**
6. **在 main 函数中显式管理生命周期**
7. **使用 `std::atexit` 注册清理函数**
8. **实现优雅关闭机制**

## 7. 针对你的错误的特定修复

```cpp
// 修复 OSG Notify 系统的销毁问题
class SafeNotifySystem {
    static std::atomic<bool> notify_available_;
    
public:
    static bool isNotifyAvailable() {
        return notify_available_.load(std::memory_order_acquire);
    }
    
    static void notifyShutdown() {
        notify_available_.store(false, std::memory_order_release);
    }
    
    // 包装 OSG 的 notify 函数
    static void safeNotify(osg::NotifySeverity severity, const std::string& message) {
        if (!isNotifyAvailable()) return;
        
        try {
            osg::notify(severity) << message << std::endl;
        } catch (...) {
            // 忽略通知系统的异常
        }
    }
};

// 在程序退出时调用
void gracefulShutdown() {
    SafeNotifySystem::notifyShutdown();
    
    // 按正确顺序关闭各个子系统
    // 1. 停止渲染线程
    // 2. 清理场景图
    // 3. 释放纹理资源
    // 4. 最后关闭通知系统
}
```

这些方案可以根据你的具体需求组合使用，有效解决静态对象销毁顺序问题。
===============================================
# 10.单例模式（Meyer's Singleton） 是如何解决静态对象销毁顺序问题的
**Meyer's Singleton** 通过 C++ 标准保证的**静态局部变量的初始化顺序**来解决静态对象销毁顺序问题。让我详细解释其工作原理：

## 1. 核心机制

### A. 初始化时机控制
```cpp
class ResourceManager {
public:
    static ResourceManager& instance() {
        static ResourceManager instance;  // 关键：局部静态变量
        return instance;
    }
    
private:
    ResourceManager() { 
        std::cout << "ResourceManager constructed" << std::endl; 
    }
    ~ResourceManager() { 
        std::cout << "ResourceManager destroyed" << std::endl; 
    }
};
```

**初始化时机**：
- **首次调用时**：第一次调用 `instance()` 时构造
- **线程安全**：C++11 保证局部静态变量初始化是线程安全的
- **按需构造**：只有真正使用时才构造

### B. 销毁顺序保证
```cpp
class Logger {
public:
    static Logger& instance() {
        static Logger instance;
        return instance;
    }
    
    void log(const std::string& msg) {
        // 使用 ResourceManager
        ResourceManager::instance().someMethod();
        std::cout << msg << std::endl;
    }
};

class Database {
public:
    static Database& instance() {
        static Database instance;
        return instance;
    }
    
    void query() {
        // 使用 Logger
        Logger::instance().log("Database query");
    }
};
```

## 2. 解决销毁顺序问题的原理

### A. 依赖关系自动管理
```cpp
// 示例：三个相互依赖的单例
class Config {
public:
    static Config& instance() {
        static Config instance;
        return instance;
    }
    
    Config() { std::cout << "Config created" << std::endl; }
    ~Config() { std::cout << "Config destroyed" << std::endl; }
};

class Logger {
public:
    static Logger& instance() {
        static Logger instance;
        return instance;
    }
    
    Logger() { 
        std::cout << "Logger created" << std::endl;
        // 使用 Config
        Config::instance();
    }
    ~Logger() { std::cout << "Logger destroyed" << std::endl; }
};

class Database {
public:
    static Database& instance() {
        static Database instance;
        return instance;
    }
    
    Database() { 
        std::cout << "Database created" << std::endl;
        // 使用 Logger
        Logger::instance();
    }
    ~Database() { std::cout << "Database destroyed" << std::endl; }
};
```

**执行结果**：
```
Config created     ← 第一次调用 Config::instance()
Logger created     ← 第一次调用 Logger::instance()，自动先创建 Config
Database created   ← 第一次调用 Database::instance()，自动先创建 Logger 和 Config

Database destroyed ← 销毁顺序与构造顺序相反
Logger destroyed
Config destroyed
```

### B. 与全局静态变量的对比

**问题代码（全局静态变量）**：
```cpp
// 头文件中
Config g_config;           // 全局静态，构造顺序不确定
Logger g_logger;           // 可能先于 g_config 构造，导致崩溃
Database g_database;       // 构造顺序完全不可控

// 不同编译单元中的全局变量构造顺序是未定义的
```

**Meyer's Singleton 解决方案**：
```cpp
// 使用时才构造，自动管理依赖
void someFunction() {
    Database::instance().query();  // 自动按需构造 Config → Logger → Database
}
```

## 3. 实际应用示例

### A. 解决 OSG 的通知系统问题
```cpp
class SafeNotifySystem {
public:
    static SafeNotifySystem& instance() {
        static SafeNotifySystem instance;
        return instance;
    }
    
    void log(const std::string& message) {
        if (!isAvailable()) return;
        
        // 安全地使用 OSG 通知系统
        osg::notify(osg::NOTICE) << message << std::endl;
    }
    
    bool isAvailable() const { 
        return !destroyed_.load(std::memory_order_acquire); 
    }
    
private:
    SafeNotifySystem() {
        std::cout << "SafeNotifySystem initialized" << std::endl;
        destroyed_.store(false, std::memory_order_release);
    }
    
    ~SafeNotifySystem() {
        destroyed_.store(true, std::memory_order_release);
        std::cout << "SafeNotifySystem destroyed" << std::endl;
    }
    
    std::atomic<bool> destroyed_;
};

// 其他单例可以安全地使用通知系统
class TextureManager {
public:
    static TextureManager& instance() {
        static TextureManager instance;
        return instance;
    }
    
    void loadTexture(const std::string& filename) {
        // 安全地记录日志
        SafeNotifySystem::instance().log("Loading texture: " + filename);
        // ... 加载纹理逻辑
    }
    
private:
    TextureManager() {
        // 在构造时记录日志
        SafeNotifySystem::instance().log("TextureManager initialized");
    }
    
    ~TextureManager() {
        // 在析构时记录日志（如果通知系统还在）
        SafeNotifySystem::instance().log("TextureManager destroyed");
    }
};
```

### B. 复杂依赖关系管理
```cpp
class ResourceA {
public:
    static ResourceA& instance() {
        static ResourceA instance;
        return instance;
    }
    
    void use() { 
        SafeNotifySystem::instance().log("ResourceA used");
    }
    
private:
    ResourceA() {
        SafeNotifySystem::instance().log("ResourceA created");
    }
    ~ResourceA() {
        SafeNotifySystem::instance().log("ResourceA destroyed");
    }
};

class ResourceB {
public:
    static ResourceB& instance() {
        static ResourceB instance;
        return instance;
    }
    
    void use() {
        ResourceA::instance().use();  // 依赖 ResourceA
        SafeNotifySystem::instance().log("ResourceB used");
    }
    
private:
    ResourceB() {
        ResourceA::instance();  // 确保 ResourceA 先初始化
        SafeNotifySystem::instance().log("ResourceB created");
    }
    ~ResourceB() {
        SafeNotifySystem::instance().log("ResourceB destroyed");
        // ResourceA 会自动在之后销毁
    }
};
```

## 4. 优势总结

### A. 自动依赖解析
- **按需构造**：只有实际使用时才初始化
- **依赖链自动管理**：A→B→C 的依赖自动按正确顺序构造
- **反向销毁**：销毁顺序与构造顺序严格相反

### B. 线程安全
```cpp
// C++11 标准保证的线程安全
static ResourceManager& instance() {
    static ResourceManager instance;  // 线程安全的初始化
    return instance;
}
```

### C. 避免常见问题
```cpp
// 问题：静态初始化顺序问题
// struct A { A() { B::instance(); } };  // 可能崩溃
// struct B { B() { } };
// A a;  // 全局变量，构造顺序不确定

// 解决方案：Meyer's Singleton
struct A { 
    static A& instance() { static A a; return a; }
    A() { B::instance(); }  // 安全：第一次调用时 B 已可用
};
struct B { 
    static B& instance() { static B b; return b; } 
};
```

## 5. 局限性及注意事项

### A. 不适用场景
```cpp
// 不适合需要在 main 之前初始化的系统
// 比如：在静态构造函数中就需要使用的低层组件

class EarlySystem {
    // 如果其他全局变量的构造函数中就需要使用这个系统
    // Meyer's Singleton 可能太晚
};
```

### B. 循环依赖问题
```cpp
class A {
public:
    static A& instance() {
        static A instance;
        return instance;
    }
    
    void use() { B::instance().use(); }  // 依赖 B
};

class B {
public:
    static B& instance() {
        static B instance;
        return instance;
    }
    
    void use() { A::instance().use(); }  // 依赖 A → 循环依赖！
};
```

## 6. 在你的 OSG 场景中的应用

对于你的 heap-use-after-free 问题，可以这样修复：

```cpp
// 修复 OSG Notify 系统的单例包装
class SafeOSGNotify {
public:
    static SafeOSGNotify& instance() {
        static SafeOSGNotify instance;
        return instance;
    }
    
    // 包装 OSG 的 notify 功能，添加安全检查
    void notify(osg::NotifySeverity severity, const std::string& msg) {
        if (isShuttingDown_) return;
        
        try {
            osg::notify(severity) << msg << std::endl;
        } catch (...) {
            // 忽略通知系统的异常
        }
    }
    
    // 在程序退出时调用
    static void initiateShutdown() {
        instance().isShuttingDown_ = true;
    }
    
private:
    SafeOSGNotify() : isShuttingDown_(false) {}
    ~SafeOSGNotify() = default;
    
    std::atomic<bool> isShuttingDown_;
    
    // 注册清理函数
    struct ShutdownRegistrar {
        ShutdownRegistrar() {
            std::atexit(&SafeOSGNotify::initiateShutdown);
        }
    };
    static ShutdownRegistrar registrar_;
};
```

**Meyer's Singleton 通过"首次使用时构造 + 反向销毁"的机制，完美解决了静态对象的销毁顺序问题，是处理复杂依赖关系的首选方案。**