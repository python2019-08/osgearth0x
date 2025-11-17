=== AddressSanitizer 调用栈解析 ===
库文件: /home/abner/abner2/zdev/nv/osgearth0x/platform/AndroiOearth01//app/build/intermediates/cxx/Debug/446nj3h3/obj/libandroioearth01.so
====================================
2025-11-12 18:04:26.136 13284-13284 DEBUG     pid-13284   A  pid: 12978, tid: 12978, name: .androioearth01  >>> com.oearth.androioearth01 <<<
2025-11-12 18:04:26.137 13284-13284 DEBUG     pid-13284   A  Abort message: '=================================================================
    ==12978==ERROR: AddressSanitizer: heap-use-after-free on address 0x0055c8c4a218 at pc 0x0070f5047464 bp 0x007fc4a8f330 sp 0x007fc4a8f328
    READ of size 4 at 0x0055c8c4a218 thread T0 (.androioearth01)

地址: 0x65b4460
void osg::KdTree::intersect<osg::TemplatePrimitiveFunctor<LineSegmentIntersectorUtils::IntersectFunctor<osg::Vec3d, double>>>(osg::TemplatePrimitiveFunctor<LineSegmentIntersectorUtils::IntersectFunctor<osg::Vec3d, double>>&, osg::KdTree::KdNode const&) const at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/KdTree:152

地址: 0x65b31fc
osgUtil::LineSegmentIntersector::intersect(osgUtil::IntersectionVisitor&, osg::Drawable*, osg::Vec3d const&, osg::Vec3d const&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgUtil/LineSegmentIntersector.cpp:598

地址: 0x65ae218
osgUtil::LineSegmentIntersector::intersect(osgUtil::IntersectionVisitor&, osg::Drawable*) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgUtil/LineSegmentIntersector.cpp:562

地址: 0x657b134
osgUtil::IntersectionVisitor::intersect(osg::Drawable*) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osgUtil/IntersectionVisitor:386

地址: 0x657b08c
osgUtil::IntersectionVisitor::apply(osg::Drawable&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgUtil/IntersectionVisitor.cpp:226

地址: 0x54f3620
osg::Drawable::accept(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/Drawable:97

地址: 0x5e61ad8
osg::Group::traverse(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Group.cpp:63

地址: 0x419c088
osg::NodeVisitor::traverse(osg::Node&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/NodeVisitor:277

地址: 0x657b054
osgUtil::IntersectionVisitor::apply(osg::Group&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgUtil/IntersectionVisitor.cpp:219

地址: 0x421cb24
osg::Group::accept(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/Group:38

地址: 0x5af8e0c
osgEarth::REX::TileNode::traverse(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/TileNode.cpp:572

地址: 0x419c088
osg::NodeVisitor::traverse(osg::Node&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/NodeVisitor:277

地址: 0x657b054
osgUtil::IntersectionVisitor::apply(osg::Group&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgUtil/IntersectionVisitor.cpp:219

地址: 0x421cb24
osg::Group::accept(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/Group:38

地址: 0x5af8d50
osgEarth::REX::TileNode::traverse(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/TileNode.cpp:565

地址: 0x419c088
osg::NodeVisitor::traverse(osg::Node&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/NodeVisitor:277

地址: 0x657b054
osgUtil::IntersectionVisitor::apply(osg::Group&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgUtil/IntersectionVisitor.cpp:219

地址: 0x421cb24
osg::Group::accept(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/Group:38

地址: 0x5af8d50
osgEarth::REX::TileNode::traverse(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/TileNode.cpp:565

地址: 0x419c088
osg::NodeVisitor::traverse(osg::Node&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/NodeVisitor:277

地址: 0x657b054
osgUtil::IntersectionVisitor::apply(osg::Group&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgUtil/IntersectionVisitor.cpp:219

地址: 0x421cb24
osg::Group::accept(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/Group:38

地址: 0x5e61ad8
osg::Group::traverse(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Group.cpp:63

地址: 0x419c088
osg::NodeVisitor::traverse(osg::Node&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/NodeVisitor:277

地址: 0x657b054
osgUtil::IntersectionVisitor::apply(osg::Group&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgUtil/IntersectionVisitor.cpp:219

地址: 0x421cb24
osg::Group::accept(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/Group:38

地址: 0x5e61ad8
osg::Group::traverse(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Group.cpp:63

地址: 0x54249c8
osgEarth::TerrainEngineNode::traverse(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/TerrainEngineNode.cpp:325

地址: 0x5990604
osgEarth::REX::RexTerrainEngineNode::traverse(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/RexTerrainEngineNode.cpp:1011

地址: 0x419c088
osg::NodeVisitor::traverse(osg::Node&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/NodeVisitor:277

地址: 0x657b054
osgUtil::IntersectionVisitor::apply(osg::Group&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgUtil/IntersectionVisitor.cpp:219

地址: 0x5f1ee40
osg::NodeVisitor::apply(osg::CoordinateSystemNode&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/NodeVisitor.cpp:122

地址: 0x5995aa8
osgEarth::REX::RexTerrainEngineNode::accept(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/RexTerrainEngineNode:37

地址: 0x4308ee0
osgEarth::Util::EarthManipulator::intersectLookVector(osg::Vec3d&, osg::Vec3d&, osg::Vec3d&) const at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/EarthManipulator.cpp:1405

地址: 0x42f7d88
osgEarth::Util::EarthManipulator::recalculateCenterFromLookVector() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/EarthManipulator.cpp:2465

地址: 0x43224bc
osgEarth::Util::EarthManipulator::zoom(double, double, osg::View*) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/EarthManipulator.cpp:2752

地址: 0x4176b78
OsgMainApp::touchZoomEvent(double) at /mnt/disk2/abner/zdev/nv/osgearth0x/platform/AndroiOearth01/app/src/main/jni/OsgMainApp.cpp:68

地址: 0x417ba00
Java_com_oearth_androioearth01_osgNativeLib_touchZoomEvent at /mnt/disk2/abner/zdev/nv/osgearth0x/platform/AndroiOearth01/app/src/main/jni/osgNativeLib.cpp:82

===================================================================================
  0x0055c8c4a218 is located 24 bytes inside of 23040-byte region [0x0055c8c4a200,0x0055c8c4fc00)
  freed by thread T21 (GLThread 17) here:


地址: 0x4134b88
void std::__ndk1::__libcpp_operator_delete[abi:ne180000]<void*>(void*) at /home/abner/Android/Sdk/ndk/27.0.12077973/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/new:280

地址: 0x4134b38
void std::__ndk1::__do_deallocate_handle_size[abi:ne180000]<>(void*, unsigned long) at /home/abner/Android/Sdk/ndk/27.0.12077973/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/new:302

地址: 0x4134adc
std::__ndk1::__libcpp_deallocate[abi:ne180000](void*, unsigned long, unsigned long) at /home/abner/Android/Sdk/ndk/27.0.12077973/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/new:317

地址: 0x5eb1f08
std::__ndk1::allocator<osg::KdTree::KdNode>::deallocate[abi:ne180000](osg::KdTree::KdNode*, unsigned long) at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/__memory/allocator.h:131

地址: 0x5eb1988
std::__ndk1::allocator_traits<std::__ndk1::allocator<osg::KdTree::KdNode>>::deallocate[abi:ne180000](std::__ndk1::allocator<osg::KdTree::KdNode>&, osg::KdTree::KdNode*, unsigned long) at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/__memory/allocator_traits.h:289

地址: 0x5eb24b8
std::__ndk1::vector<osg::KdTree::KdNode, std::__ndk1::allocator<osg::KdTree::KdNode>>::__destroy_vector::operator()[abi:ne180000]() at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/vector:492

地址: 0x5eb221c
std::__ndk1::vector<osg::KdTree::KdNode, std::__ndk1::allocator<osg::KdTree::KdNode>>::~vector[abi:ne180000]() at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/vector:501

地址: 0x5eac148
osg::KdTree::~KdTree() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/KdTree:26

地址: 0x5eac19c
osg::KdTree::~KdTree() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/KdTree:26

地址: 0x5fb0550
osg::Referenced::signalObserversAndDelete(bool, bool) const at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Referenced.cpp:292

地址: 0x5fb0970
osg::Referenced::unref() const at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Referenced.cpp:348

地址: 0x5d912f0
osg::ref_ptr<osg::Shape>::~ref_ptr() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/ref_ptr:61

地址: 0x5d91edc
osg::Drawable::~Drawable() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Drawable.cpp:281

地址: 0x5ae1a2c
osgEarth::REX::TileDrawable::~TileDrawable() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/TileDrawable.cpp:75

地址: 0x5ae1a54
osgEarth::REX::TileDrawable::~TileDrawable() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/TileDrawable.cpp:73

地址: 0x5fb0550
osg::Referenced::signalObserversAndDelete(bool, bool) const at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Referenced.cpp:292

地址: 0x5fb0970
osg::Referenced::unref() const at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Referenced.cpp:348

地址: 0x4295a2c
osg::ref_ptr<osg::Node>::~ref_ptr() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/ref_ptr:61

地址: 0x467417c
std::__ndk1::allocator<osg::ref_ptr<osg::Node>>::destroy[abi:ne180000](osg::ref_ptr<osg::Node>*) at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/__memory/allocator.h:168

地址: 0x4674140
void std::__ndk1::allocator_traits<std::__ndk1::allocator<osg::ref_ptr<osg::Node>>>::destroy[abi:ne180000]<osg::ref_ptr<osg::Node>, void>(std::__ndk1::allocator<osg::ref_ptr<osg::Node>>&, osg::ref_ptr<osg::Node>*) at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/__memory/allocator_traits.h:311

地址: 0x46740c0
std::__ndk1::vector<osg::ref_ptr<osg::Node>, std::__ndk1::allocator<osg::ref_ptr<osg::Node>>>::__base_destruct_at_end[abi:ne180000](osg::ref_ptr<osg::Node>*) at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/vector:926

地址: 0x4673e6c
std::__ndk1::vector<osg::ref_ptr<osg::Node>, std::__ndk1::allocator<osg::ref_ptr<osg::Node>>>::__clear[abi:ne180000]() at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/vector:920

地址: 0x4673d18
std::__ndk1::vector<osg::ref_ptr<osg::Node>, std::__ndk1::allocator<osg::ref_ptr<osg::Node>>>::__destroy_vector::operator()[abi:ne180000]() at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/vector:490

地址: 0x4660138
std::__ndk1::vector<osg::ref_ptr<osg::Node>, std::__ndk1::allocator<osg::ref_ptr<osg::Node>>>::~vector[abi:ne180000]() at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/vector:501

地址: 0x5e6178c
osg::Group::~Group() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Group.cpp:54

地址: 0x61476c8
osg::Transform::~Transform() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Transform.cpp:143

地址: 0x5f0b114
osg::MatrixTransform::~MatrixTransform() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/MatrixTransform.cpp:41

地址: 0x5a83748
osgEarth::REX::SurfaceNode::~SurfaceNode() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/SurfaceNode:27

地址: 0x5a83770
osgEarth::REX::SurfaceNode::~SurfaceNode() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/SurfaceNode:27
===================================================================================
                                                                               
previously allocated by thread T36 here:
===============================================
#0 0x71f173a2fc  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libclang_rt.asan-aarch64-android.so+0xf22fc) (BuildId: d2089f24857cf6bfee934a5c1e8395bab0e414b6)

地址: 0x413252c
void* std::__ndk1::__libcpp_operator_new[abi:ne180000]<unsigned long>(unsigned long) at /home/abner/Android/Sdk/ndk/27.0.12077973/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/new:271

地址: 0x41324b4
std::__ndk1::__libcpp_allocate[abi:ne180000](unsigned long, unsigned long) at /home/abner/Android/Sdk/ndk/27.0.12077973/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/new:295

地址: 0x5eae8e0
std::__ndk1::allocator<osg::KdTree::KdNode>::allocate[abi:ne180000](unsigned long) at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/__memory/allocator.h:117

地址: 0x5eae658
std::__ndk1::__allocation_result<std::__ndk1::allocator_traits<std::__ndk1::allocator<osg::KdTree::KdNode>>::pointer> std::__ndk1::__allocate_at_least[abi:ne180000]<std::__ndk1::allocator<osg::KdTree::KdNode>>(std::__ndk1::allocator<osg::KdTree::KdNode>&, unsigned long) at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/__memory/allocate_at_least.h:55

地址: 0x5ead958
std::__ndk1::__split_buffer<osg::KdTree::KdNode, std::__ndk1::allocator<osg::KdTree::KdNode>&>::__split_buffer(unsigned long, unsigned long, std::__ndk1::allocator<osg::KdTree::KdNode>&) at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/__split_buffer:343

地址: 0x5ea6ca4
std::__ndk1::vector<osg::KdTree::KdNode, std::__ndk1::allocator<osg::KdTree::KdNode>>::reserve(unsigned long) at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/vector:1425

地址: 0x5ea633c
BuildKdTree::build(osg::KdTree::BuildOptions&, osg::Geometry*) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/KdTree.cpp:189

地址: 0x5eaa52c
osg::KdTree::build(osg::KdTree::BuildOptions&, osg::Geometry*) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/KdTree.cpp:504

地址: 0x5eab664
osg::KdTreeBuilder::apply(osg::Geometry&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/KdTree.cpp:531

地址: 0x5dc1cb0
osg::Geometry::accept(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/Geometry:39

地址: 0x5ae16bc
osgEarth::REX::TileDrawable::setElevationRaster(std::__ndk1::shared_ptr<osgEarth::Texture>, osg::Matrixf const&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/TileDrawable.cpp:162

地址: 0x5a7e278
osgEarth::REX::SurfaceNode::setElevationRaster(std::__ndk1::shared_ptr<osgEarth::Texture>, osg::Matrixf const&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/SurfaceNode.cpp:101

地址: 0x5a7d9f0
osgEarth::REX::SurfaceNode::SurfaceNode(osgEarth::TileKey const&, osgEarth::REX::TileDrawable*) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/SurfaceNode.cpp:78

地址: 0x5af0bf4
osgEarth::REX::TileNode::createGeometry(jobs::cancelable*) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/TileNode.cpp:129

地址: 0x5aef930
osgEarth::REX::TileNode::TileNode(osgEarth::TileKey const&, osgEarth::REX::TileNode*, osgEarth::REX::EngineContext*, jobs::cancelable*) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/TileNode.cpp:48

地址: 0x5afa72c
osgEarth::REX::TileNode::createChild(osgEarth::TileKey const&, jobs::cancelable*) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/TileNode.cpp:789

地址: 0x5b239a0
_ZZN8osgEarth3REX8TileNode14createChildrenEvENK3$_0clIN4jobs6futureINSt6__ndk15arrayIN3osg7ref_ptrIS1_EELm4EEEEEEEDaRT_ at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/TileNode.cpp:679

地址: 0x5b23410
jobs::future<std::__ndk1::array<osg::ref_ptr<osgEarth::REX::TileNode>, 4ul>> jobs::dispatch<osgEarth::REX::TileNode::createChildren()::$_0, std::__ndk1::array<osg::ref_ptr<osgEarth::REX::TileNode>, 4ul>>(osgEarth::REX::TileNode::createChildren()::$_0, jobs::context const&)::'lambda'()::operator()() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/weejobs.h:814

地址: 0x5b2322c
decltype(std::declval<osgEarth::REX::TileNode::createChildren()::$_0>()()) std::__ndk1::__invoke[abi:ne180000]<jobs::future<std::__ndk1::array<osg::ref_ptr<osgEarth::REX::TileNode>, 4ul>> jobs::dispatch<osgEarth::REX::TileNode::createChildren()::$_0, std::__ndk1::array<osg::ref_ptr<osgEarth::REX::TileNode>, 4ul>>(osgEarth::REX::TileNode::createChildren()::$_0, jobs::context const&)::'lambda'()&>(osgEarth::REX::TileNode::createChildren()::$_0&&) at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/__type_traits/invoke.h:344

地址: 0x5b231e0
bool std::__ndk1::__invoke_void_return_wrapper<bool, false>::__call[abi:ne180000]<jobs::future<std::__ndk1::array<osg::ref_ptr<osgEarth::REX::TileNode>, 4ul>> jobs::dispatch<osgEarth::REX::TileNode::createChildren()::$_0, std::__ndk1::array<osg::ref_ptr<osgEarth::REX::TileNode>, 4ul>>(osgEarth::REX::TileNode::createChildren()::$_0, jobs::context const&)::'lambda'()&>(jobs::future<std::__ndk1::array<osg::ref_ptr<osgEarth::REX::TileNode>, 4ul>> jobs::dispatch<osgEarth::REX::TileNode::createChildren()::$_0, std::__ndk1::array<osg::ref_ptr<osgEarth::REX::TileNode>, 4ul>>(osgEarth::REX::TileNode::createChildren()::$_0, jobs::context const&)::'lambda'()&) at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/__type_traits/invoke.h:411

地址: 0x5b231b8
std::__ndk1::__function::__alloc_func<jobs::future<std::__ndk1::array<osg::ref_ptr<osgEarth::REX::TileNode>, 4ul>> jobs::dispatch<osgEarth::REX::TileNode::createChildren()::$_0, std::__ndk1::array<osg::ref_ptr<osgEarth::REX::TileNode>, 4ul>>(osgEarth::REX::TileNode::createChildren()::$_0, jobs::context const&)::'lambda'(), std::__ndk1::allocator<jobs::future<std::__ndk1::array<osg::ref_ptr<osgEarth::REX::TileNode>, 4ul>> jobs::dispatch<osgEarth::REX::TileNode::createChildren()::$_0, std::__ndk1::array<osg::ref_ptr<osgEarth::REX::TileNode>, 4ul>>(osgEarth::REX::TileNode::createChildren()::$_0, jobs::context const&)::'lambda'()>, bool ()>::operator()[abi:ne180000]() at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/__functional/function.h:166

地址: 0x5b1e150
std::__ndk1::__function::__func<jobs::future<std::__ndk1::array<osg::ref_ptr<osgEarth::REX::TileNode>, 4ul>> jobs::dispatch<osgEarth::REX::TileNode::createChildren()::$_0, std::__ndk1::array<osg::ref_ptr<osgEarth::REX::TileNode>, 4ul>>(osgEarth::REX::TileNode::createChildren()::$_0, jobs::context const&)::'lambda'(), std::__ndk1::allocator<jobs::future<std::__ndk1::array<osg::ref_ptr<osgEarth::REX::TileNode>, 4ul>> jobs::dispatch<osgEarth::REX::TileNode::createChildren()::$_0, std::__ndk1::array<osg::ref_ptr<osgEarth::REX::TileNode>, 4ul>>(osgEarth::REX::TileNode::createChildren()::$_0, jobs::context const&)::'lambda'()>, bool ()>::operator()() at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/__functional/function.h:308

地址: 0x48018d8
std::__ndk1::__function::__value_func<bool ()>::operator()[abi:ne180000]() const at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/__functional/function.h:425

地址: 0x47fd330
std::__ndk1::function<bool ()>::operator()() const at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/__functional/function.h:978

地址: 0x47fbd74
jobs::jobpool::run() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/weejobs.h:956

地址: 0x47fb434
jobs::jobpool::start_threads()::'lambda'()::operator()() const at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/weejobs.h:1001

地址: 0x47fb378
decltype(std::declval<jobs::jobpool::start_threads()::'lambda'()>()()) std::__ndk1::__invoke[abi:ne180000]<jobs::jobpool::start_threads()::'lambda'()>(jobs::jobpool::start_threads()::'lambda'()&&) at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/__type_traits/invoke.h:344

地址: 0x47fb2a4
void std::__ndk1::__thread_execute[abi:ne180000]<std::__ndk1::unique_ptr<std::__ndk1::__thread_struct, std::__ndk1::default_delete<std::__ndk1::__thread_struct>>, jobs::jobpool::start_threads()::'lambda'()>(std::__ndk1::tuple<std::__ndk1::unique_ptr<std::__ndk1::__thread_struct, std::__ndk1::default_delete<std::__ndk1::__thread_struct>>, jobs::jobpool::start_threads()::'lambda'()>&, std::__ndk1::__tuple_indices<...>) at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/__thread/thread.h:190

地址: 0x47f9e28
void* std::__ndk1::__thread_proxy[abi:ne180000]<std::__ndk1::tuple<std::__ndk1::unique_ptr<std::__ndk1::__thread_struct, std::__ndk1::default_delete<std::__ndk1::__thread_struct>>, jobs::jobpool::start_threads()::'lambda'()>>(void*) at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/__thread/thread.h:199

================================================================
                                                                                              
 Thread T36 created by T21 (GLThread 17) here: 
#0 0x71f1719d5c  (/data/app/~~3QrtIKoPDF4GtUx1XCV7iQ==/com.oearth.androioearth01-ImkxW78cPciuloBTzZVbQw==/lib/arm64/libclang_rt.asan-aarch64-android.so+0xd1d5c) (BuildId: d2089f24857cf6bfee934a5c1e8395bab0e414b6)


地址: 0x47f9c70
std::__ndk1::__libcpp_thread_create[abi:ne180000](long*, void* (*)(void*), void*) at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/__threading_support:317

地址: 0x47f4de8
std::__ndk1::thread::thread<jobs::jobpool::start_threads()::'lambda'(), void>(jobs::jobpool::start_threads()::'lambda'()&&) at /home/abner/Android/Sdk/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1/__thread/thread.h:209

地址: 0x47e2f90
jobs::jobpool::start_threads() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/weejobs.h:995

地址: 0x47d53c0
jobs::get_pool(std::__ndk1::basic_string<char, std::__ndk1::char_traits<char>, std::__ndk1::allocator<char>> const&, unsigned int) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/weejobs.h:760

地址: 0x5af71c0
osgEarth::REX::TileNode::createChildren() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/TileNode.cpp:693

地址: 0x5af6424
osgEarth::REX::TileNode::cull(osgEarth::REX::TerrainCuller*) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/TileNode.cpp:467

地址: 0x5af8be8
osgEarth::REX::TileNode::traverse(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/TileNode.cpp:550

地址: 0x419c088
osg::NodeVisitor::traverse(osg::Node&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/NodeVisitor:277

地址: 0x5a648b0
osgEarth::REX::TerrainCuller::apply(osg::Node&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/TerrainCuller.cpp:195

地址: 0x5f1ec84
osg::NodeVisitor::apply(osg::Group&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/NodeVisitor.cpp:107

地址: 0x421cb24
osg::Group::accept(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/Group:38

地址: 0x5e61ad8
osg::Group::traverse(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Group.cpp:63

地址: 0x419c088
osg::NodeVisitor::traverse(osg::Node&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/NodeVisitor:277

地址: 0x5a648b0
osgEarth::REX::TerrainCuller::apply(osg::Node&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/TerrainCuller.cpp:195

地址: 0x5f1ec84
osg::NodeVisitor::apply(osg::Group&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/NodeVisitor.cpp:107

地址: 0x421cb24
osg::Group::accept(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/Group:38

地址: 0x598b228
osgEarth::REX::RexTerrainEngineNode::cull_traverse(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/RexTerrainEngineNode.cpp:750

地址: 0x59905f4
osgEarth::REX::RexTerrainEngineNode::traverse(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/RexTerrainEngineNode.cpp:1006

地址: 0x419c088
osg::NodeVisitor::traverse(osg::Node&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/NodeVisitor:277

地址: 0x65276fc
osgUtil::CullVisitor::handle_cull_callbacks_and_traverse(osg::Node&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osgUtil/CullVisitor:340

地址: 0x6529c00
osgUtil::CullVisitor::apply(osg::Group&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgUtil/CullVisitor.cpp:1148

地址: 0x5f1ee40
osg::NodeVisitor::apply(osg::CoordinateSystemNode&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/NodeVisitor.cpp:122

地址: 0x5995aa8
osgEarth::REX::RexTerrainEngineNode::accept(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/RexTerrainEngineNode:37

地址: 0x5e61ad8
osg::Group::traverse(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Group.cpp:63

地址: 0x4e892c4
osgEarth::Util::OverlayDecorator::traverse(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/OverlayDecorator.cpp:857

地址: 0x419c088
osg::NodeVisitor::traverse(osg::Node&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/NodeVisitor:277

地址: 0x65276fc
osgUtil::CullVisitor::handle_cull_callbacks_and_traverse(osg::Node&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osgUtil/CullVisitor:340

地址: 0x6529c00
osgUtil::CullVisitor::apply(osg::Group&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgUtil/CullVisitor.cpp:1148

地址: 0x421cb24
osg::Group::accept(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/Group:38

地址: 0x5e61ad8
osg::Group::traverse(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Group.cpp:63

地址: 0x419c088
osg::NodeVisitor::traverse(osg::Node&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/NodeVisitor:277

地址: 0x65276fc
osgUtil::CullVisitor::handle_cull_callbacks_and_traverse(osg::Node&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osgUtil/CullVisitor:340

地址: 0x6529c00
osgUtil::CullVisitor::apply(osg::Group&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgUtil/CullVisitor.cpp:1148

地址: 0x421cb24
osg::Group::accept(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/Group:38

地址: 0x4ce79bc
osgEarth::MapNode::traverse(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/MapNode.cpp:892

地址: 0x419c088
osg::NodeVisitor::traverse(osg::Node&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/NodeVisitor:277

地址: 0x5ce8668
osg::Callback::traverse(osg::Object*, osg::Object*) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Callback.cpp:35

地址: 0x4d844c0
osgEarth::HorizonClipPlane::operator()(osg::Node*, osg::NodeVisitor*) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/HorizonClipPlane.cpp:91

地址: 0x5ce9324
osg::NodeCallback::run(osg::Object*, osg::Object*) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Callback.cpp:75

地址: 0x5ce8514
osg::Callback::traverse(osg::Object*, osg::Object*) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Callback.cpp:28

地址: 0x421a264
osgEarth::Util::InstallCameraUniform::operator()(osg::Node*, osg::NodeVisitor*) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/CullingUtils.cpp:1119

地址: 0x5ce9324
osg::NodeCallback::run(osg::Object*, osg::Object*) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Callback.cpp:75

地址: 0x65276ec
osgUtil::CullVisitor::handle_cull_callbacks_and_traverse(osg::Node&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osgUtil/CullVisitor:339

地址: 0x6529c00
osgUtil::CullVisitor::apply(osg::Group&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgUtil/CullVisitor.cpp:1148

地址: 0x421cb24
osg::Group::accept(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/Group:38

地址: 0x5e61ad8
osg::Group::traverse(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Group.cpp:63

地址: 0x5ba4f88
osgEarth::SkyNode::traverse(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/Sky.cpp:163

地址: 0x5bd6e38
osgEarth::SimpleSky::SimpleSkyNode::traverse(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/sky_simple/SimpleSkyNode.cpp:404

地址: 0x419c088
osg::NodeVisitor::traverse(osg::Node&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/NodeVisitor:277

地址: 0x65276fc
osgUtil::CullVisitor::handle_cull_callbacks_and_traverse(osg::Node&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osgUtil/CullVisitor:340

地址: 0x6529c00
osgUtil::CullVisitor::apply(osg::Group&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgUtil/CullVisitor.cpp:1148

地址: 0x421cb24
osg::Group::accept(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/Group:38

地址: 0x5e61ad8
osg::Group::traverse(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Group.cpp:63

地址: 0x419c088
osg::NodeVisitor::traverse(osg::Node&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/NodeVisitor:277

地址: 0x65276fc
osgUtil::CullVisitor::handle_cull_callbacks_and_traverse(osg::Node&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osgUtil/CullVisitor:340

地址: 0x6529c00
osgUtil::CullVisitor::apply(osg::Group&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgUtil/CullVisitor.cpp:1148

地址: 0x421cb24
osg::Group::accept(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/Group:38

地址: 0x5e61ad8
osg::Group::traverse(osg::NodeVisitor&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Group.cpp:63

地址: 0x419c088
osg::NodeVisitor::traverse(osg::Node&) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/NodeVisitor:277

地址: 0x6a2f9a8
osgUtil::SceneView::cullStage(osg::Matrixd const&, osg::Matrixd const&, osgUtil::CullVisitor*, osgUtil::StateGraph*, osgUtil::RenderStage*, osg::Viewport*) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgUtil/SceneView.cpp:893

地址: 0x6a2dd50
osgUtil::SceneView::cull() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgUtil/SceneView.cpp:758

地址: 0x6a18f24
osgViewer::Renderer::cull_draw() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgViewer/Renderer.cpp:891

地址: 0x6a19fcc
osgViewer::Renderer::operator()(osg::GraphicsContext*) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgViewer/Renderer.cpp:976

地址: 0x5e2f178
osg::GraphicsContext::runOperations() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/GraphicsContext.cpp:696

地址: 0x6b1a524
osgViewer::ViewerBase::renderingTraversals() at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgViewer/ViewerBase.cpp:892

地址: 0x6b176cc
osgViewer::ViewerBase::frame(double) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osgViewer/ViewerBase.cpp:748

地址: 0x4152780
DemoScene::frame() at /mnt/disk2/abner/zdev/nv/osgearth0x/platform/AndroiOearth01/app/src/main/jni/OsgDemoScene.cpp:148

地址: 0x41762f4
OsgMainApp::draw() at /mnt/disk2/abner/zdev/nv/osgearth0x/platform/AndroiOearth01/app/src/main/jni/OsgMainApp.cpp:22

地址: 0x417b944
Java_com_oearth_androioearth01_osgNativeLib_step at /mnt/disk2/abner/zdev/nv/osgearth0x/platform/AndroiOearth01/app/src/main/jni/osgNativeLib.cpp:60
