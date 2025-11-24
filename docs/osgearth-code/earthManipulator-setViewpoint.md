# 1.如何用EarthManipulator::setViewpoint实现地球的平移、旋转、缩放操作

使用 `EarthManipulator::setViewpoint()` 可以实现地球的平移、旋转和缩放操作，主要通过设置不同的 `Viewpoint` 参数来实现。

## s1. 基本设置

```cpp
#include <osgEarth/Viewpoint>
#include <osgEarthUtil/EarthManipulator>

osgEarth::Util::EarthManipulator* manip = dynamic_cast<osgEarth::Util::EarthManipulator*>(viewer->getCameraManipulator());
if (!manip) {
    manip = new osgEarth::Util::EarthManipulator();
    viewer->setCameraManipulator(manip);
}
```

## s2. 平移操作（改变焦点位置）

### 平移到指定经纬度：
```cpp
// 平移到北京天安门
osgEarth::Viewpoint vp;
vp.setFocalPoint(osgEarth::GeoPoint(
    osgEarth::SpatialReference::get("wgs84"),
    116.3974, 39.9093, 1000.0  // 经度, 纬度, 高程(米)
));
vp.setHeading(0.0);     // 朝向(0=北)
vp.setPitch(-45.0);     // 俯仰角(-90=垂直向下)
vp.setRange(5000.0);    // 视距(米)

manip->setViewpoint(vp, 2.0);  // 2秒动画过渡
```

### 相对平移（基于当前位置）：
```cpp
osgEarth::Viewpoint currentVP = manip->getViewpoint();
osgEarth::GeoPoint currentPos = currentVP.focalPoint();

// 向东移动0.1度，向北移动0.1度
osgEarth::GeoPoint newPos(
    currentPos.getSRS(),
    currentPos.x() + 0.1,  // 经度+
    currentPos.y() + 0.1,  // 纬度+
    currentPos.z()        // 保持高程
);

osgEarth::Viewpoint newVP;
newVP.setFocalPoint(newPos);
newVP.setHeading(currentVP.getHeading());
newVP.setPitch(currentVP.getPitch());
newVP.setRange(currentVP.getRange());

manip->setViewpoint(newVP, 1.0);
```

## s3. 旋转操作

### 水平旋转（改变朝向）：
```cpp
osgEarth::Viewpoint vp = manip->getViewpoint();

// 顺时针旋转45度
vp.setHeading(vp.getHeading() + 45.0);

// 限制角度在0-360度范围内
if (vp.getHeading() >= 360.0) vp.setHeading(vp.getHeading() - 360.0);
if (vp.getHeading() < 0.0) vp.setHeading(vp.getHeading() + 360.0);

manip->setViewpoint(vp, 0.5);  // 0.5秒旋转动画
```

### 俯仰旋转（改变视角倾斜）：
```cpp
osgEarth::Viewpoint vp = manip->getViewpoint();

// 抬高视角（更接近水平）
vp.setPitch(vp.getPitch() + 15.0);

// 限制俯仰角在-90到0度之间
vp.setPitch(osg::clampBetween(vp.getPitch(), -90.0, 0.0));

manip->setViewpoint(vp, 0.5);
```

## s4. 缩放操作（改变视距）

### 缩放到指定高度：
```cpp
osgEarth::Viewpoint vp = manip->getViewpoint();

// 缩放到1000米高度
vp.setRange(1000.0);

manip->setViewpoint(vp, 1.0);
```

### 相对缩放：
```cpp
osgEarth::Viewpoint vp = manip->getViewpoint();

// 放大2倍（距离减半）
vp.setRange(vp.getRange() * 0.5);

// 缩小2倍（距离加倍）
vp.setRange(vp.getRange() * 2.0);

// 限制缩放范围（最小100米，最大10000公里）
vp.setRange(osg::clampBetween(vp.getRange(), 100.0, 10000000.0));

manip->setViewpoint(vp, 0.3);
```

## s5. 组合操作（同时平移+旋转+缩放）

```cpp
// 创建新的视角，同时改变多个参数
osgEarth::Viewpoint newVP;

// 平移：到上海
newVP.setFocalPoint(osgEarth::GeoPoint(
    osgEarth::SpatialReference::get("wgs84"),
    121.4737, 31.2304, 500.0  // 上海坐标
));

// 旋转：朝向东南方
newVP.setHeading(135.0);  // 135度 = 东南方向

// 缩放：中等高度
newVP.setRange(10000.0);  // 10公里高度

// 俯仰：中等倾斜
newVP.setPitch(-60.0);    // 60度俯角

// 平滑过渡（3秒动画）
manip->setViewpoint(newVP, 3.0);
```

## s6. 实用工具函数

```cpp
class EarthController {
public:
    static void panTo(EarthManipulator* manip, double lon, double lat, double duration = 2.0) {
        osgEarth::Viewpoint vp = manip->getViewpoint();
        vp.setFocalPoint(osgEarth::GeoPoint(vp.getSRS(), lon, lat, vp.focalPoint().z()));
        manip->setViewpoint(vp, duration);
    }
    
    static void zoomTo(EarthManipulator* manip, double range, double duration = 1.0) {
        osgEarth::Viewpoint vp = manip->getViewpoint();
        vp.setRange(range);
        manip->setViewpoint(vp, duration);
    }
    
    static void rotateTo(EarthManipulator* manip, double heading, double pitch, double duration = 1.0) {
        osgEarth::Viewpoint vp = manip->getViewpoint();
        vp.setHeading(heading);
        vp.setPitch(osg::clampBetween(pitch, -90.0, 0.0));
        manip->setViewpoint(vp, duration);
    }
    
    static void flyTo(EarthManipulator* manip, double lon, double lat, double range, 
                     double heading = 0.0, double pitch = -45.0, double duration = 3.0) {
        osgEarth::Viewpoint vp;
        vp.setFocalPoint(osgEarth::GeoPoint(
            osgEarth::SpatialReference::get("wgs84"), lon, lat, 0.0
        ));
        vp.setHeading(heading);
        vp.setPitch(pitch);
        vp.setRange(range);
        manip->setViewpoint(vp, duration);
    }
};

// 使用示例
EarthController::flyTo(manip, 116.3974, 39.9093, 5000.0, 45.0, -60.0, 4.0);
```

## s7. 动画回调（实现平滑路径）

```cpp
class CameraAnimation : public osg::NodeCallback {
public:
    CameraAnimation(EarthManipulator* manip) : _manip(manip), _currentTime(0.0) {}
    
    virtual void operator()(osg::Node* node, osg::NodeVisitor* nv) {
        _currentTime += nv->getFrameStamp()->getReferenceTime();
        
        if (_currentTime < _animationDuration) {
            double progress = _currentTime / _animationDuration;
            
            // 插值计算当前视角
            osgEarth::Viewpoint currentVP = interpolateViewpoints(_startVP, _endVP, progress);
            _manip->setViewpoint(currentVP, 0.0);  // 立即设置，无动画
        }
        
        traverse(node, nv);
    }
    
    void startAnimation(const osgEarth::Viewpoint& start, const osgEarth::Viewpoint& end, double duration) {
        _startVP = start;
        _endVP = end;
        _animationDuration = duration;
        _currentTime = 0.0;
    }
    
private:
    EarthManipulator* _manip;
    osgEarth::Viewpoint _startVP, _endVP;
    double _animationDuration, _currentTime;
    
    osgEarth::Viewpoint interpolateViewpoints(const osgEarth::Viewpoint& vp1, 
                                             const osgEarth::Viewpoint& vp2, 
                                             double t) {
        osgEarth::Viewpoint result;
        // 实现插值逻辑...
        return result;
    }
};
```

## s8. 关键参数说明

| 参数 | 作用 | 典型范围 |
|------|------|----------|
| `setFocalPoint()` | 设置焦点（平移） | 经纬度坐标 |
| `setHeading()` | 设置朝向（旋转） | 0-360度（0=北，90=东） |
| `setPitch()` | 设置俯仰角（倾斜） | -90到0度（-90=垂直向下） |
| `setRange()` | 设置视距（缩放） | 100米-10000公里 |
| 动画时间 | 过渡时间 | 0.0（立即）到10.0秒 |

## 使用技巧

1. **短动画**（0.5-1.0秒）：用户交互响应
2. **长动画**（2.0-5.0秒）：场景切换展示  
3. **立即切换**（0.0秒）：编程控制需要精确位置时

这样设计可以实现流畅的地球浏览体验！