# 0.contents

> 1.osgearth 如何控制camera的



========================================================
# 1.osgearth 如何控制camera的

我来详细解释OSG Earth如何控制相机（Camera）的。让我先搜索相关的相机控制代码。

Search files...
Search files...
Read file: src/osgEarth/EarthManipulator
基于对OSG Earth相机控制代码的深入分析，我来详细解释OSG Earth如何控制相机：

## OSG Earth 相机控制系统

### 1. 核心组件架构

#### **EarthManipulator - 主要相机控制器**
```cpp
class EarthManipulator : public osgGA::CameraManipulator
{
    // 相机状态参数
    osg::Vec3d _center;           // 焦点位置
    osg::Quat _rotation;          // 相机旋转
    osg::Quat _centerRotation;    // 中心点旋转
    double _distance;             // 距离
    osg::Vec3d _posOffset;        // 位置偏移
    osg::Vec2d _viewOffset;       // 视图偏移
};
```

### 2. 相机矩阵构建

#### **相机变换矩阵计算**
```cpp
osg::Matrixd EarthManipulator::getMatrix() const
{
    // 构建相机矩阵的四个组成部分：
    // 1. 距离变换
    // 2. 视图偏移
    // 3. 相机旋转
    // 4. 中心点变换
    
    return osg::Matrixd::translate(_viewOffset.x(), _viewOffset.y(), -_distance) *
           osg::Matrixd::rotate(_rotation) *
           osg::Matrixd::rotate(_centerRotation) *
           osg::Matrixd::translate(_center);
}
```

### 3. 相机更新机制

#### **updateCamera 方法**
```cpp
void EarthManipulator::updateCamera(osg::Camera& camera)
{
    double now = osg::Timer::instance()->time_s();
    double t = 1.0;

    // 1. 处理视点过渡动画
    if (isSettingViewpoint())
    {
        t = setViewpointFrame(now);
    }

    // 2. 处理相机绑定（Tethering）
    if (isTethering())
    {
        updateTether(t);
    }

    // 3. 更新投影矩阵
    updateProjection(&camera);

    // 4. 调用基类更新
    osgGA::CameraManipulator::updateCamera(camera);

    // 5. 执行回调
    if (_updateCameraCallback.valid())
    {
        _updateCameraCallback->onUpdateCamera(&camera);
    }
}
```

### 4. 投影矩阵控制

#### **透视/正交投影切换**
```cpp
void EarthManipulator::updateProjection(osg::Camera* camera)
{
    const osg::Matrixd& proj = camera->getProjectionMatrix();
    bool isOrtho = osg::equivalent(proj(3,3), 1.0);

    if (!isOrtho) {
        // 透视相机：记录VFOV
        double vfov, ar, zn, zf;
        if (camera->getProjectionMatrixAsPerspective(vfov, ar, zn, zf))
        {
            _lastKnownVFOV = vfov;
        }
    }
    else if (_settings->getOrthoTracksPerspective()) {
        // 正交相机：根据距离调整视口
        double ar = vp->width()/vp->height();
        double y = _distance * tan(0.5*osg::DegreesToRadians(_lastKnownVFOV));
        double x = y * ar;
        
        osg::Matrix orthoProj;
        ProjectionMatrix::setOrtho(orthoProj, -x, +x, -y, +y, N, F);
        camera->setProjectionMatrix(orthoProj);
    }
}
```

### 5. 用户交互控制

#### **鼠标操作处理**
```cpp
bool EarthManipulator::handleMouseAction(const Action& action, osg::View* view)
{
    double dx = _ga_t0->getXnormalized() - _ga_t1->getXnormalized();
    double dy = _ga_t0->getYnormalized() - _ga_t1->getYnormalized();

    // 应用灵敏度设置
    dx *= _settings->getMouseSensitivity();
    dy *= _settings->getMouseSensitivity();

    // 处理连续模式
    if (_continuous) {
        _continuous_dx += dx * 0.01;
        _continuous_dy += dy * 0.01;
    }
    else {
        _dx = dx;
        _dy = dy;
        handleMovementAction(action._type, dx, dy, view);
    }

    return true;
}
```

### 6. 相机操作类型

#### **平移操作 (Pan)**
```cpp
void EarthManipulator::pan(double dx, double dy)
{
    if (isTethering()) {
        // 绑定模式下调整距离
        double scale = 1.0f + dy;
        setDistance(_distance * scale);
    }
    else {
        // 自由模式下移动焦点
        recalculateCenterFromLookVector();
        // 计算新的中心点位置
    }
}
```

#### **旋转操作 (Rotate)**
```cpp
void EarthManipulator::rotate(double dx, double dy)
{
    // dx: 方位角变化
    // dy: 俯仰角变化
    
    osg::Quat newRotation = _rotation * 
        osg::Quat(dx, osg::Vec3d(0,0,1)) *  // 方位角旋转
        osg::Quat(dy, osg::Vec3d(1,0,0));   // 俯仰角旋转
    
    _rotation = newRotation;
}
```

#### **缩放操作 (Zoom)**
```cpp
void EarthManipulator::zoom(double dx, double dy, osg::View* view)
{
    if (_settings->getZoomToMouse()) {
        // 缩放到鼠标位置
        osg::Vec3d target;
        if (screenToWorld(x, y, view, target)) {
            // 计算新的相机位置
            osg::Vec3d eyeToTarget = target - eye;
            double scale = 1.0f + dy;
            osg::Vec3d newEye = eye + eyeToTarget * (1.0 - scale);
            setByLookAt(newEye, target, up);
        }
    }
    else {
        // 缩放到中心点
        double scale = 1.0f + dy;
        setDistance(_distance * scale);
    }
}
```

### 7. 地球拖拽操作

#### **地球表面拖拽**
```cpp
void EarthManipulator::drag(double dx, double dy, osg::View* view)
{
    // 1. 获取拖拽起始点
    osg::Vec3d worldStartDrag;
    bool onEarth = screenToWorld(_ga_t1->getX(), _ga_t1->getY(), view, worldStartDrag);
    
    // 2. 计算拖拽结束点
    osg::Vec3d worldEndDrag;
    bool endOnEarth = screenToWorld(x, y, view, worldEndDrag);
    
    // 3. 计算旋转
    if (_srs->isGeographic()) {
        osg::Quat worldRot;
        worldRot.makeRotate(worldStartDrag, worldEndDrag);
        
        // 相机应用逆旋转
        osg::Quat cameraRot = worldRot.conj();
        // 更新相机矩阵
    }
}
```

### 8. 视点管理

#### **视点设置和过渡**
```cpp
void EarthManipulator::setViewpoint(const Viewpoint& vp, double duration_s)
{
    if (duration_s > 0.0) {
        // 创建过渡动画
        _setVP0 = getViewpoint();
        _setVP1 = vp;
        _setVPStartTime = osg::Timer::instance()->time_s();
        _setVPDuration = duration_s;
    }
    else {
        // 立即设置
        setLookAt(vp.focalPoint(), vp.heading(), vp.pitch(), vp.range());
    }
}
```

### 9. 地形碰撞检测

#### **防止相机穿透地形**
```cpp
void EarthManipulator::collisionDetect()
{
    if (!getSettings()->getTerrainAvoidanceEnabled())
        return;

    osg::Vec3d eye = getWorldMatrix().getTrans();
    
    // 向下射线检测地形
    osg::Vec3d ip, normal;
    if (intersect(eye, eye - up * r, ip, normal)) {
        double minHeight = ip.length() + _settings->getTerrainAvoidanceMinimumDistance();
        if (eye.length() < minHeight) {
            // 调整相机高度
            setDistance(_distance + (minHeight - eye.length()));
        }
    }
}
```

### 10. 相机绑定系统

#### **Tethering - 相机跟随节点**
```cpp
void EarthManipulator::updateTether(double t)
{
    if (_setVP1->nodeIsSet()) {
        osg::Node* node = _setVP1->getNode();
        osg::Matrix nodeMatrix = osg::computeLocalToWorld(node->getParentalNodePaths()[0]);
        
        // 根据绑定模式更新相机
        switch (_settings->getTetherMode()) {
            case TETHER_CENTER:
                setCenter(nodeMatrix.getTrans());
                break;
            case TETHER_CENTER_AND_ROTATION:
                setCenter(nodeMatrix.getTrans());
                _tetherRotation = nodeMatrix.getRotate();
                break;
        }
    }
}
```

### 11. 性能优化特性

- **视锥体剔除**: 自动计算和更新视锥体
- **LOD系统**: 基于屏幕空间误差的细节层次控制
- **多线程更新**: 支持多线程相机更新
- **缓存机制**: 缓存计算结果避免重复计算

这个相机控制系统提供了完整的地球导航功能，包括平移、旋转、缩放、视点管理、地形碰撞检测等，同时支持各种交互设备和自定义配置。

========================================================